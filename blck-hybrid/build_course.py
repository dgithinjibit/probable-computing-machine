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

    def handle_endtag(self, tag):
        if tag in self.SKIP and self.skip_depth:
            self.skip_depth -= 1

    def handle_data(self, data):
        if not self.skip_depth:
            self.parts.append(data)


def epub_sections(path: Path) -> list[dict]:
    """EPUB chapters as {title, index} sections (no physical pages)."""
    with zipfile.ZipFile(path) as archive:
        names = [n for n in archive.namelist()
                 if n.lower().endswith((".xhtml", ".html", ".htm"))]
        sections = []
        for name in sorted(names):
            try:
                raw = archive.read(name).decode("utf-8", "replace")
            except Exception:
                continue
            parser = _TextExtractor()
            try:
                parser.feed(raw)
            except Exception:
                continue
            text = re.sub(r"[ \t]+", " ", "".join(parser.parts))
            text = "\n".join(line.strip() for line in text.splitlines() if line.strip())
            if len(text.split()) < 30:
                continue
            title = Path(name).stem.replace("_", " ")
            m = re.search(r"<title[^>]*>(.*?)</title>", raw, re.S | re.I)
            if m:
                title = re.sub(r"\s+", " ", m.group(1)).strip()[:80] or title
            sections.append({"title": title, "file": name, "words": len(text.split())})
    return sections


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
    if book["kind"] == "epub":
        sections = epub_sections(path)
        if section is None or not (1 <= section <= len(sections)):
            return ""
        with zipfile.ZipFile(path) as archive:
            raw = archive.read(sections[section - 1]["file"]).decode("utf-8", "replace")
        parser = _TextExtractor()
        parser.feed(raw)
        text = re.sub(r"[ \t]+", " ", "".join(parser.parts))
        return "\n".join(line.strip() for line in text.splitlines() if line.strip())
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
        if words and words + n > max_words:
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
                    if p.suffix.lower() in {".pdf", ".epub", ".docx"}])
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
            sections = epub_sections(path)
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
    elif path.suffix.lower() == ".epub":
        for i, section in enumerate(epub_sections(path)[:args.scan_pages], start=1):
            print(f"§{i:<4} {section['title'][:70]}")
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
    for d in curriculum["days"]:
        summary.append(f"- [Day {d['day']}: {d['title']}](days/day-{d['day']:03d}.md)")
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
