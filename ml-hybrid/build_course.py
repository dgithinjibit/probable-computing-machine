#!/usr/bin/env python3
"""Build a hybrid course: split local books into day-sized mdBook lessons.

Stdlib + poppler (pdftotext/pdfinfo) only, so it runs offline on this laptop.

    ./build_course.py inventory              # chapter maps for every book in a library
    ./build_course.py plan                   # show the spine, sources and gaps
    ./build_course.py build                  # emit src/days/*.md + guided-course data
    ./build_course.py build --from-day 1 --to-day 10

Sources of truth:
  hybrid-curriculum.json  books registry + ordered days (hand-curated)
  hybrid-course.js        the generic mark-complete + spaced-repetition engine

Generated (never edit by hand):
  src/days/day-NN.md, src/SUMMARY.md, src/maps/*.md, hybrid-course-data.json
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import struct
import subprocess
import sys
import zipfile
from html.parser import HTMLParser
from pathlib import Path

HERE = Path(__file__).resolve().parent
LAB = HERE.parent  # exercises/
CURRICULUM_FILE = HERE / "hybrid-curriculum.json"
DATA_FILE = HERE / "hybrid-course-data.json"
SRC = HERE / "src"
DAYS_DIR = SRC / "days"
MAPS_DIR = SRC / "maps"

# A lesson body aims for the author's own words at bite size.
MIN_BITE_WORDS = 180
MAX_BITE_WORDS = 520
MAX_RANGE_PAGES = 15
# Spaced-repetition look-backs, in completed lessons.
RECALL_OFFSETS = (1, 3, 7, 21)


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug[:60] or "book"


def have(executable: str) -> bool:
    return shutil.which(executable) is not None


def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    if result.returncode != 0:
        raise RuntimeError(f"{cmd[0]} failed: {result.stderr.strip()[:200]}")
    return result.stdout


# --------------------------------------------------------------------------
# text sources
# --------------------------------------------------------------------------


def pdf_page_count(path: Path) -> int:
    out = run(["pdfinfo", str(path)])
    for line in out.splitlines():
        if line.startswith("Pages:"):
            return int(line.split()[1])
    return 0


def pdf_pages(path: Path, first: int | None = None, last: int | None = None,
              layout: bool = True) -> list[str]:
    """Physical pages of a PDF as text, 1-indexed list.

    layout=True keeps columns aligned (good for headings); layout=False gives
    prose paragraphs (good for lesson bodies).
    """
    cmd = ["pdftotext"] + (["-layout"] if layout else [])
    if first:
        cmd += ["-f", str(first)]
    if last:
        cmd += ["-l", str(last)]
    cmd += [str(path), "-"]
    return run(cmd).split("\f")


def is_toc_line(line: str) -> bool:
    if re.search(r"\.{4,}", line) or re.search(r"·{3,}", line):
        return True
    if re.search(r"[\s.·]\d{1,4}\s*$", line):  # trailing page number
        return True
    return False


HEADING_RES = [
    re.compile(r"^(?:chapter|chap(?:iter)?|part)\s+([IVXLC\d]{1,5})[\s:.\-–—]+(.{3,70})$", re.I),
    re.compile(r"^(\d{1,2})\s*[.]\s+([A-Z][A-Za-z][A-Za-z ,\-–':&()]{2,60})$"),
    re.compile(r"^(\d{1,2})\s+([A-Z][A-Za-z][A-Za-z ,\-–':&()]{3,60})$"),
]


def find_chapters(pages: list[str], total_hint: int = 0) -> list[dict]:
    """Locate chapter openings: heading at the top of a page, no dot leaders."""
    found: list[dict] = []
    seen: set[str] = set()
    for index, page in enumerate(pages, start=1):
        lines = [line.strip() for line in page.splitlines()]
        body = [line for line in lines if line]
        if not body or len(body) < 4:
            continue
        candidate = body[0]
        if len(candidate) < 4 or len(candidate) > 74 or is_toc_line(candidate):
            continue
        number = title = None
        for rx in HEADING_RES:
            m = rx.match(candidate)
            if m:
                number, title = m.group(1), m.group(2).strip()
                break
        if not title:
            continue
        key = re.sub(r"\W+", "", title.lower())[:28]
        if key in seen:
            continue
        # a real chapter opening owns most of its page
        if sum(len(line.split()) for line in body) < 40:
            continue
        seen.add(key)
        found.append({"number": number, "title": title, "page": index})
    found.sort(key=lambda c: c["page"])
    for i, chapter in enumerate(found):
        start = chapter["page"]
        end = found[i + 1]["page"] - 1 if i + 1 < len(found) else (total_hint or start + 20)
        chapter["end"] = max(start, min(end, start + MAX_RANGE_PAGES * 4))
    return found


HEAD_MARK = "\x01"  # sentinel inserted before a heading so blobs can be split


class _TextExtractor(HTMLParser):
    SKIP = {"script", "style", "head"}

    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []
        self.skip_depth = 0

    def handle_starttag(self, tag, attrs):
        if tag in self.SKIP:
            self.skip_depth += 1
        if tag in {"p", "div", "h1", "h2", "h3", "li", "br"}:
            self.parts.append("\n")
        if tag in {"h1", "h2", "h3"}:
            self.parts.append(HEAD_MARK)

    def handle_endtag(self, tag):
        if tag in self.SKIP and self.skip_depth:
            self.skip_depth -= 1

    def handle_data(self, data):
        if not self.skip_depth:
            self.parts.append(data)


def html_to_text(raw: str) -> str:
    """Strip markup, keeping line breaks and heading markers."""
    parser = _TextExtractor()
    try:
        parser.feed(raw)
    except Exception:  # a truncated chapter still has usable text
        pass
    text = re.sub(r"[ \t]+", " ", "".join(parser.parts))
    return "\n".join(line.strip() for line in text.splitlines() if line.strip())


def split_units(text: str, hint: str = "", min_words: int = 120) -> list[dict]:
    """Turn one long blob into chapter-sized units at its heading markers.

    A single-file EPUB or MOBI has no section boundaries to point a day at, so the
    headings are the only honest address. Fragments under `min_words` fold back into
    the unit they came from, which keeps a stray `<h3>` from becoming a lesson.
    """
    chunks = [c.strip() for c in text.split(HEAD_MARK) if c.strip()]
    units: list[dict] = []
    for chunk in chunks:
        words = len(chunk.split())
        first = chunk.splitlines()[0][:70]
        title = first if (words < min_words or len(first.split()) <= 9) else hint
        if units and words < min_words:
            units[-1]["text"] += "\n\n" + chunk
            units[-1]["words"] += words
        else:
            units.append({"title": (title or hint or "chapter"), "text": chunk,
                          "words": words})
    return units


def mobi_decompress(block: bytes, out: bytearray, shift: bool = False) -> None:
    """PalmDOC LZ77 into a shared buffer.

    The back-reference window deliberately spans records, because a 4096-byte text
    record may point at text that ended in the record before it. Decompressing each
    record on its own is what turns a book into question marks.

    `shift` selects between the two documented readings of bytes 0x09-0x7F: the strict
    PalmDOC rule (the byte minus 8) and the reading this library's file actually uses
    (literal). `mobi_html` tries both and keeps whichever produced real text.
    """
    i = 0
    while i < len(block):
        c = block[i]
        i += 1
        if c == 0:
            out.append(c)
        elif c <= 8:
            out += block[i:i + c]
            i += c
        elif c <= 0x7F:
            out.append(c - 8 if shift else c)
        elif c <= 0xBF:
            if i >= len(block):
                break
            d = block[i]
            i += 1
            # Only the low 6 bits of the control byte belong to the pair, so the
            # combined value is 14 bits: 11 for the distance, 3 for the length.
            pair = ((c & 0x3F) << 8) | d
            distance = (pair >> 3) & 0x7FF
            length = (pair & 0x07) + 3
            if distance == 0 or distance > len(out):
                out += b" " * length
                continue
            start = len(out) - distance
            for _ in range(length):
                out.append(out[start])
                start += 1
        else:
            # 0xC0-0xFF means "a space plus this byte with its high bit cleared",
            # which is how a book full of `<p class=" gets to compress at all.
            out.append(0x20)
            out.append(c & 0x7F)


def _text_score(body: bytes) -> float:
    """Rough 'is this readable prose' score, used to pick a MOBI decoding."""
    sample = body[:4000].decode("latin-1", "replace")
    if not sample:
        return 0.0
    good = sum(1 for ch in sample if ch.isalnum() or ch in " \n<>/=\"'.,;:()!?-")
    return good / len(sample)


def mobi_html(path: Path) -> str:
    """Decompressed XHTML text of a PalmDOC/MOBI book."""
    data = path.read_bytes()
    if data[60:68] != b"BOOKMOBI":
        raise RuntimeError("not a BOOKMOBI file")
    records = struct.unpack(">H", data[76:78])[0]
    offsets = [struct.unpack(">I", data[78 + 8 * i:82 + 8 * i])[0] for i in range(records)]
    ends = offsets[1:] + [len(data)]
    head = data[offsets[0]:offsets[0] + 256]
    compression = struct.unpack(">H", head[0:2])[0]
    text_length = struct.unpack(">I", head[4:8])[0]
    text_count = struct.unpack(">H", head[8:10])[0]
    encoding = struct.unpack(">I", head[28:32])[0] if head[16:20] == b"MOBI" else 1252
    body = bytearray()
    for index in range(1, min(1 + text_count, records)):
        block = data[offsets[index]:ends[index]].rstrip(b"\x00")
        if compression == 2:
            mobi_decompress(block, body)
        else:
            body += block
    if compression == 2:
        shifted = bytearray()
        for index in range(1, min(1 + text_count, records)):
            block = data[offsets[index]:ends[index]].rstrip(b"\x00")
            mobi_decompress(block, shifted, shift=True)
        if _text_score(shifted) > _text_score(body):
            body = shifted
    body = body[:text_length] if text_length else bytes(body)
    return body.decode("utf-8" if encoding == 65001 else "cp1252", "replace")


def epub_spine(archive: zipfile.ZipFile) -> list[str]:
    """Reading order from the OPF spine, falling back to sorted file names.

    Attribute order in `<item>` is not guaranteed, and some Packt files use UUID
    names where alphabetical order is meaningless, so the spine is worth parsing
    properly rather than guessing.
    """
    opf = [n for n in archive.namelist() if n.lower().endswith(".opf")]
    if not opf:
        return []
    raw = archive.read(opf[0]).decode("utf-8", "replace")
    base = opf[0].rsplit("/", 1)[0] + "/" if "/" in opf[0] else ""
    hrefs = {}
    for tag in re.findall(r"<item\b[^>]*>", raw):
        item = re.search(r'id="([^"]+)"', tag)
        href = re.search(r'href="([^"]+)"', tag)
        if item and href:
            hrefs[item.group(1)] = href.group(1)
    candidates = {n.split("/")[-1].lower(): n for n in archive.namelist()
                  if n.lower().endswith((".xhtml", ".html", ".htm"))}
    order = []
    for item in re.findall(r'<itemref[^>]*idref="([^"]+)"', raw):
        href = hrefs.get(item)
        if not href:
            continue
        match = candidates.get((base + href).split("/")[-1].lower())
        if match:
            order.append(match)
    return order


def epub_sections(path: Path) -> list[dict]:
    """EPUB units a day can point at: one per chapter, split again if huge.

    Returns {title, words, file, frag}. `frag` matters because a single-file EPUB
    (common for self-published books) is one HTML part holding every chapter, so the
    part name alone is not an address a lesson can cite.
    """
    units: list[dict] = []
    with zipfile.ZipFile(path) as archive:
        names = [n for n in archive.namelist()
                 if n.lower().endswith((".xhtml", ".html", ".htm"))]
        spine = [n for n in epub_spine(archive) if n in names]
        for name in (spine or sorted(names)):
            try:
                raw = archive.read(name).decode("utf-8", "replace")
            except Exception:
                continue
            title = Path(name).stem.replace("_", " ")
            m = re.search(r"<title[^>]*>(.*?)</title>", raw, re.S | re.I)
            if m:
                title = re.sub(r"\s+", " ", m.group(1)).strip()[:80] or title
            text = html_to_text(raw)
            if title.lower() in {"unknown", "untitled", "epub", ""} or len(title) < 3:
                heads = re.findall(HEAD_MARK + r"([^\n]{3,70})", text)
                if heads:
                    title = heads[0].strip()
                else:
                    first = text.replace(HEAD_MARK, "").splitlines()
                    lead = next((line.strip() for line in first if len(line.split()) >= 2), "")
                    if 2 < len(lead) < 72:
                        title = lead
            words = len(re.sub(HEAD_MARK, " ", text).split())
            if words < 30:
                continue
            if words > 4000:  # a whole book in one part: use its headings
                for chunk in split_units(text, title):
                    units.append({**chunk, "file": name})
                continue
            first = text.split(HEAD_MARK)
            heading = re.sub(HEAD_MARK, "", first[1] if len(first) > 1 else "").splitlines()
            units.append({"title": (heading[0][:70] if heading and len(heading[0]) < 71 else title),
                          "text": text.replace(HEAD_MARK, "\n"),
                          "file": name})
    for index, unit in enumerate(units, start=1):
        unit["frag"] = index
        unit.setdefault("words", len(unit.get("text", "").split()))
    return units


def text_units(book: dict) -> list[dict]:
    """Addressable units for a non-paginated source (EPUB part or MOBI heading)."""
    path = Path(book["path"])
    if not path.exists():
        return []
    if book["kind"] == "mobi":
        raw = mobi_html(path)
        # Many Mobipocket books mark a chapter with a bold paragraph instead of an
        # <h1>, and those are the only headings worth splitting on here.
        raw = re.sub(r'(<p[^>]*>)(\s*<b>\s*[^<]{3,70}?</b>)', r"\1" + HEAD_MARK + r"\2", raw)
        units = split_units(html_to_text(raw), book.get("short", "chapter"))
        for index, unit in enumerate(units, start=1):
            unit["frag"] = index
            unit.setdefault("words", len(unit["text"].split()))
        return units
    return epub_sections(path)


def docx_paragraphs(path: Path) -> list[str]:
    with zipfile.ZipFile(path) as archive:
        raw = archive.read("word/document.xml").decode("utf-8", "replace")
    raw = raw.replace("</w:p>", "</w:p>\n")
    parser = _TextExtractor()
    parser.feed(raw)
    text = re.sub(r"[ \t]+", " ", "".join(parser.parts))
    return [line.strip() for line in text.splitlines() if line.strip()]


def read_source_text(book: dict, first: int | None, last: int | None,
                    section: int | None = None) -> str:
    path = Path(book["path"])
    if not path.exists():
        return ""
    if book["kind"] == "docx":
        paras = docx_paragraphs(path)
        start = max(1, first or 1)
        stop = min(len(paras), last or start + 5)
        return "\n\n".join(paras[start - 1:stop])
    if book["kind"] in {"epub", "mobi"}:
        units = text_units(book)
        if section is None or not (1 <= section <= len(units)):
            return ""
        return units[section - 1]["text"]
    pages = pdf_pages(path, first, last, layout=False)
    return "\n".join(pages)


# --------------------------------------------------------------------------
# bite sizing
# --------------------------------------------------------------------------


def noise(line: str) -> bool:
    if not line:
        return True
    if re.fullmatch(r"[\s\d.\-–—©]+", line):
        return True
    if re.search(r"(all rights reserved|publisher|isbn|doi:|library of congress)", line, re.I):
        return True
    # Publisher boilerplate wraps across lines, so each fragment needs its own rule:
    # a line that starts with the copyright glyph or says "no part of this book" is
    # never the author's argument, and it must not leak into a study bite.
    if re.search(r"(©\s*copyright|copyright\s*©|no part of this (book|work)|prior written permission|reproduced in any form|posted, or reproduced)", line, re.I):
        return True
    if len(line.split()) <= 1 and re.search(r"\d", line):
        return True
    # Figure and table captions are the publisher's layout, not the author's argument.
    if re.match(r"^(figure|table|listing|exhibit)\s+[\divx]+([-.–]\d+)*\s*[:.\s]", line, re.I):
        return True
    return False


def make_bite(text: str, min_words: int = MIN_BITE_WORDS,
              max_words: int = MAX_BITE_WORDS) -> tuple[str, int]:
    """Take whole paragraphs until the bite size is met; keep the author's order."""
    blocks: list[str] = []
    for chunk in re.split(r"\n\s*\n", text):
        lines = [line.strip() for line in chunk.splitlines() if not noise(line.strip())]
        if not lines:
            continue
        block = " ".join(re.sub(r"\s+", " ", " ".join(lines)).split())
        if len(block.split()) < 12:  # stray captions
            continue
        blocks.append(block)
    if not blocks:
        # The range is mostly lists or short lines (a worked-example page, a
        # contents page). Fall back to smaller units rather than emitting an
        # empty lesson.
        for line in (ln.strip() for ln in text.splitlines()):
            if noise(line) or len(line.split()) < 5 or is_toc_line(line):
                continue
            blocks.append(line)
    out: list[str] = []
    words = 0
    for block in blocks:
        n = len(block.split())
        if not out and n > max_words:
            # Some EPUB chapters arrive as one unbroken block; trim by sentence.
            tail, taken = [], 0
            for sent in re.split(r"(?<=[.!?…])\s+", block):
                if taken and words + taken + len(sent.split()) > max_words:
                    break
                tail.append(sent)
                taken += len(sent.split())
            return " ".join(tail) + " […continues in the full section]", taken
        if words and words + n > max_words:
            # A whole section can be longer than a sitting. Keep the author's
            # sentences and stop at a sentence boundary instead of a paragraph.
            if words >= min_words:
                tail, taken = [], 0
                for sent in re.split(r"(?<=[.!?…])\s+", block):
                    k = len(sent.split())
                    if taken and words + taken + k > max_words:
                        break
                    tail.append(sent)
                    taken += k
                if taken:
                    out.append(" ".join(tail))
                    words += taken
            break
        out.append(block)
        words += n
        if words >= min_words and n > 60:
            break
    bite = "\n\n".join(out)
    if out and not re.search(r"[.!?…»]$", out[-1]):
        bite += " […continues in the full page]"
    return bite, words


# --------------------------------------------------------------------------
# commands
# --------------------------------------------------------------------------


def load_curriculum() -> dict:
    return json.loads(CURRICULUM_FILE.read_text(encoding="utf-8"))


def book_by_id(curriculum: dict, book_id: str) -> dict:
    for book in curriculum["books"]:
        if book["id"] == book_id:
            return book
    raise SystemExit(f"curriculum references unknown book id: {book_id}")


def cmd_inventory(args: argparse.Namespace) -> None:
    library = Path(args.library).expanduser()
    if not have("pdftotext") or not have("pdfinfo"):
        raise SystemExit("pdftotext/pdfinfo (poppler) are required and were not found on PATH.")
    MAPS_DIR.mkdir(parents=True, exist_ok=True)
    skip = re.compile(args.skip or r"$^", re.I)
    keep = re.compile(args.filter, re.I) if args.filter else None
    files = sorted([p for p in library.iterdir()
                    if p.suffix.lower() in {".pdf", ".epub", ".docx", ".mobi"}])
    index = []
    for path in files:
        if skip.search(path.name) or (keep and not keep.search(path.name)):
            continue
        if path.suffix.lower() == ".pdf":
            try:
                total = pdf_page_count(path)
                pages = pdf_pages(path)
                chapters = find_chapters(pages, total)
            except Exception as error:  # keep the run alive for the other books
                print(f"  ! {path.name}: {error}", file=sys.stderr)
                continue
            words = sum(len(p.split()) for p in pages)
        elif path.suffix.lower() == ".docx":
            with zipfile.ZipFile(path) as archive:
                raw = archive.read("word/document.xml").decode("utf-8", "replace")
            raw = raw.replace("</w:p>", "</w:p>\n")
            parser = _TextExtractor()
            parser.feed(raw)
            text = re.sub(r"[ \t]+", " ", "".join(parser.parts))
            paras = [line.strip() for line in text.splitlines() if len(line.split()) > 2]
            words = sum(len(x.split()) for x in paras)
            total, chapters = len(paras), []
            for i, para in enumerate(paras, start=1):
                if re.match(r"^(Chapter\s+\d+|\d{1,2}[.\)]?\s+[A-Z][A-Za-z ]{3,50})$", para[:60]):
                    chapters.append({"number": None, "title": para[:70], "page": i, "end": i})
        else:
            probe = {"path": str(path),
                     "kind": path.suffix.lower().lstrip("."),
                     "short": path.stem[:40]}
            sections = text_units(probe)
            total = len(sections)
            chapters = [{"number": str(i), "title": s["title"], "page": i, "end": i}
                        for i, s in enumerate(sections, start=1)][:60]
            words = sum(s["words"] for s in sections)
        unit = {"pdf": "pages", "docx": "paragraphs"}.get(path.suffix.lower().strip("."), "sections")
        slug = slugify(path.stem)
        lines = [f"# {path.name}", "",
                 f"- file: `{path}`",
                 f"- extent: {total} {unit}, ~{words:,} words",
                 "", f"## Chapter map (detected openings, {unit})", ""]
        if not chapters:
            lines.append(f"_No chapter openings detected; treat as a reference text and point days at {unit} ranges by hand._")
        for c in chapters:
            label = f"{c['number']}. " if c.get("number") else ""
            span = c["page"] if c["page"] == c["end"] else f"{c['page']}–{c['end']}"
            lines.append(f"- **{label}{c['title']}** — {unit[:-1]}s {span}")
        lines += ["", "## Opening bite", "",
                  "> _Run `build` to pull the author's words for a specific range._", ""]
        (MAPS_DIR / f"{slug}.md").write_text("\n".join(lines), encoding="utf-8")
        index.append({"slug": slug, "name": path.stem, "path": str(path), "pages": total,
                      "words": words, "chapters": chapters, "unit": unit})
        print(f"  {path.suffix[1:]:<5}{total:5d}{unit[:2]:<3} {len(chapters):3d} ch  {path.name[:66]}")
    merged = {entry["path"]: entry for entry in index}
    if (HERE / "inventory.json").exists():
        try:
            previous = json.loads((HERE / "inventory.json").read_text(encoding="utf-8"))
            merged = {entry["path"]: entry for entry in previous} | merged
        except Exception:
            pass
    combined = sorted(merged.values(), key=lambda e: e["name"].lower())
    (HERE / "inventory.json").write_text(json.dumps(combined, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\n{len(index)} books mapped this run; {len(combined)} in the index total")
    print(f"\n{len(index)} books mapped into {MAPS_DIR}")


def cmd_locate(args: argparse.Namespace) -> None:
    """Where does each named heading actually start? Prints physical pages.

    Curating a spine needs real page anchors, and many books print their
    contents list only in the ToC or use styled headings the detector misses.
    Give it titles (or '-' separated chapter names from a ToC) and it reports
    the first page where each appears near the top of a page.
    """
    path = Path(args.book).expanduser()
    titles = [s.strip() for s in args.titles.split("|") if s.strip()]
    if path.suffix.lower() == ".pdf":
        pages = pdf_pages(path)
        for title in titles:
            key = re.sub(r"[^a-z0-9 ]+", " ", title.lower())
            hits = []
            for i, page in enumerate(pages[:args.scan_pages], start=1):
                head = " ".join(re.sub(r"[^a-z0-9 ]+", " ", line.lower())
                                for line in [l.strip() for l in page.splitlines()][:6])
                if key and key in head:
                    hits.append(i)
                    if len(hits) >= 2:
                        break
            print(f"{title[:52]:<54} -> {hits or 'not found near page tops'}")
    elif path.suffix.lower() in {".epub", ".mobi"}:
        probe = {"path": str(path), "kind": path.suffix.lower().lstrip("."),
                 "short": path.stem[:40]}
        for i, unit in enumerate(text_units(probe)[:args.scan_pages], start=1):
            print(f"§{i:<4} {unit['title'][:64]:<66} {unit['words']:>6}w")
    else:
        paras = docx_paragraphs(path)
        for i, para in enumerate(paras[:args.scan_pages], start=1):
            if len(para) < 70 and re.match(r"^(\d{1,2}[.)]?\s+[A-Z]|[A-Z][A-Za-z ]{4,50}$)", para):
                print(f"¶{i:<5}{para[:70]}")


def cmd_plan(args: argparse.Namespace) -> None:
    curriculum = load_curriculum()
    print(f"{curriculum['course']['title']} — {len(curriculum['days'])} days\n")
    for day in curriculum["days"]:
        book = book_by_id(curriculum, day["book"])
        loc = (f"§{day['section']}" if "section" in day
               else f"{day['from']}-{day['to']}")
        print(f"Day {day['day']:>3}  {book['short']:<26} {loc:<12} {day['title']}")


def build_day_page(curriculum: dict, day: dict, by_number: dict[int, dict]) -> str:
    book = book_by_id(curriculum, day["book"])
    text = read_source_text(book, day.get("from"), day.get("to"), day.get("section"))
    if not text.strip():
        body = ["_The source could not be read. Check the path and page range in `hybrid-curriculum.json`._"]
        words = 0
    else:
        bite, words = make_bite(text)
        body = [bite] if bite else ["_No body text found in that range._"]
    unit = "¶" if book["kind"] == "docx" else ("§" if "section" in day else "pp.")
    if "section" in day:
        loc = f"§{day['section']}"
    elif book["kind"] in {"epub", "mobi"}:
        loc = "whole file"
    else:
        loc = f"{unit} {day['from']}–{day['to']}" if unit == "¶" else f"pp. {day['from']}–{day['to']}"
    recalled = [n for n in (day["day"] - o for o in RECALL_OFFSETS) if n >= 1]
    parts = [
        f"# Day {day['day']}: {day['title']}",
        "",
        f"**Track:** {day.get('track', curriculum['course']['title'])} · "
        f"**Source:** {loc} of _{book['short']}_ ({book['author']})",
        "",
        "## 1. Recall first (5 minutes)",
        "",
        day.get("recall") or "Close this page and write down the key idea from your last lesson from memory.",
        "",
    ]
    if recalled:
        parts += ["> Auto-spaced review of what you already completed:", ""]
        for n in recalled:
            prev = by_number.get(n)
            gap = day["day"] - n
            if prev:
                parts.append(f"- **Day {n}** ({gap}d ago) — {prev['title']}: "
                             f"{(prev.get('idea') or prev['title']).rstrip('. ')}.")
        parts.append("")
    parts += [
        "## 2. Read the author (10–15 minutes)",
        "",
        *body,
        "",
    ]
    if day.get("misconception"):
        parts += [f"**Watch for the mistake:** {day['misconception']}", ""]
    parts += [
        "## 3. Practice (20–30 minutes)",
        "",
        day.get("practice") or "Reproduce the idea in your own small program before checking anything.",
        "",
        "## 4. Check (5 minutes)",
        "",
        day.get("check") or "Run the exercise, read every failure, and record the correction in your log.",
        "",
        "## Mastery gate",
        "",
        day.get("gate") or "Explain the key idea without looking, then handle one changed or edge-case input.",
        "",
        f"<sub>Extracted locally from `{Path(book['path']).name}` with `build_course.py` "
        f"({loc} of the author's text). Words are the book's own; for personal study. "
        f"Chapter map: [{book['short']}]({Path('../') / book['map']}).</sub>",
        "",
    ]
    return ("\n".join(parts) + f"<!-- words:{words} -->\n"), {
        "source": f"{loc} of {book['short']} ({book['author']})",
        "bite": body[0] if len(body) == 1 else "\n\n".join(body),
        "recall": day.get("recall", ""),
        "idea": day.get("idea") or day["title"],
        "practice": day.get("practice", ""),
        "check": day.get("check", ""),
        "gate": day.get("gate", ""),
        "misconception": day.get("misconception", ""),
        "book": book["short"],
        "map": book["map"],
    }


def cmd_build(args: argparse.Namespace) -> None:
    curriculum = load_curriculum()
    course = curriculum["course"]
    days = [d for d in curriculum["days"] if args.from_day <= d["day"] <= args.to_day]
    all_days = {d["day"]: d for d in curriculum["days"]}
    DAYS_DIR.mkdir(parents=True, exist_ok=True)
    SRC.mkdir(parents=True, exist_ok=True)
    metas: dict[int, dict] = {}
    for day in days:
        page, meta = build_day_page(curriculum, day, all_days)
        metas[day["day"]] = meta
        out = DAYS_DIR / f"day-{day['day']:03d}.md"
        out.write_text(page, encoding="utf-8")
        bite_words = int(re.search(r"words:(\d+)", page).group(1))
        print(f"  day {day['day']:>3} -> {out.name} ({bite_words} extracted words)")

    summary = ["# Summary", "",
               f"> Guided course page (mark complete + spaced review): "
               f"`http://127.0.0.1:8000/{HERE.name}/hybrid-course.html`, served by "
               f"`./exercises/serve-site.sh`. It sits outside `src/`, so mdBook cannot link it.",
               "", f"- [Start here](index.md)", ""]
    last_track = None
    for d in curriculum["days"]:
        track = d.get("track")
        if track and track != last_track:
            summary += ["", f"## {track}", ""]
            last_track = track
        summary.append(f"- [Day {d['day']}: {d['title']}](days/day-{d['day']:03d}.md)")
    for section, folder, blurb in (
            ("Reference shelf", "shelf",
             "One-page handles on the material that is not a book: cheat sheets, loose "
             "notes, lab lists, and the code already sitting in the library."),
            # src/visuals is gitignored (third-party card images and their transcriptions
            # stay on this machine), so it must not be linked from SUMMARY.md - mdBook
            # would fail to build on a clone where the file does not exist.
    ):
        pages = sorted((SRC / folder).glob("*.md")) if (SRC / folder).is_dir() else []
        if pages:
            # mdBook's SUMMARY grammar accepts only headings and list items, so the
            # blurb is an HTML comment rather than an italic paragraph.
            summary += ["", f"## {section}", "", f"<!-- {blurb} -->", ""]
            labels = []
            for p in pages:
                first = p.read_text(encoding="utf-8").lstrip().splitlines()
                title = first[0][1:].strip() if first and first[0].startswith("# ") \
                    else p.stem.replace("-", " ")
                labels.append(f"- [{title}]({folder}/{p.name})")
            summary += labels
    summary += ["", "## Book maps", ""]
    for book in curriculum["books"]:
        if Path(book["path"]).exists():
            summary.append(f"- [{book['short']}]({book['map']})")
    (SRC / "SUMMARY.md").write_text("\n".join(summary) + "\n", encoding="utf-8")

    index = [f"# {course['title']}", "", course["lead"], "",
             "## How this course works", "", course.get("method", ""), "",
             "## Spine order", ""]
    for i, book in enumerate(curriculum["books"], start=1):
        index.append(f"{i}. _{book['short']}_ — {book['author']}. "
                     f"See [map]({book['map']}).")
    index += ["", "Start with the guided course page at "
              f"`http://127.0.0.1:8000/{HERE.name}/hybrid-course.html` "
              "(run `./exercises/serve-site.sh` first); it opens on the first day you "
              "have not completed.", ""]
    (SRC / "index.md").write_text("\n".join(index), encoding="utf-8")

    all_metas: dict[int, dict] = dict(metas)
    for day in curriculum["days"]:
        if day["day"] not in all_metas:
            _, all_metas[day["day"]] = build_day_page(curriculum, day, all_days)

    lessons = []
    for d in curriculum["days"]:
        meta = all_metas[d["day"]]
        lessons.append({
            "day": d["day"], "title": d["title"], "kind": d.get("kind", "lesson"),
            "track": d.get("track", ""),
            "page": f"src/days/day-{d['day']:03d}.md",
            "href": f"book/days/day-{d['day']:03d}.html",
            "idea": meta["idea"], "source": meta["source"], "bite": meta["bite"],
            "recall": meta["recall"], "practice": meta["practice"],
            "check": meta["check"], "gate": meta["gate"],
            "misconception": meta["misconception"], "book": meta["book"],
            "map": f"src/{meta['map']}",
        })
    DATA_FILE.write_text(json.dumps({
        "course": course,
        "storageKey": f"local-learning-lab.{course['id']}.v1",
        "recallOffsets": list(RECALL_OFFSETS),
        "lessons": lessons,
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nwrote {len(days)} lesson pages, SUMMARY.md, index.md, {DATA_FILE.name}")
    print(f"total spine days: {len(curriculum['days'])}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    inv = sub.add_parser("inventory")
    inv.add_argument("--library", default=str(Path.home() / "Desktop" / "ML"))
    inv.add_argument("--filter", help="only files whose name matches this regex")
    inv.add_argument("--skip", help="skip files whose name matches this regex")
    pl = sub.add_parser("plan")
    pl.set_defaults(func=cmd_plan)
    lo = sub.add_parser("locate")
    lo.add_argument("--book", required=True)
    lo.add_argument("--titles", required=True, help="pipe-separated heading names from a ToC")
    lo.add_argument("--scan-pages", type=int, default=400)
    lo.set_defaults(func=cmd_locate)
    bd = sub.add_parser("build")
    bd.add_argument("--from-day", type=int, default=1)
    bd.add_argument("--to-day", type=int, default=10_000)
    bd.set_defaults(func=cmd_build)
    inv.set_defaults(func=cmd_inventory)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
