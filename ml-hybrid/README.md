# Hybrid book courses (build system)

One course on this laptop was **messy and thin**: too many books, no order, no
memory of where you stopped. This folder fixes that by turning owned PDFs and
EPUBs into an **ordered day path** — each day names the book, the exact pages,
the author's own words at bite size, one local exercise, and an automatic
spaced review of the days you already completed.

Currently built: **ML Hybrid Course** — 85 days from `~/Desktop/ML`, laid out as a
zero-to-hero spine (Days 1-8 Python from nothing, 9-17 mathematics from nothing, 18-33
ML foundations, 34-38 traditional ML in a practitioner's hands, 39-51 AGI, 52-85 the rest
of the folder);
**Hacking Hybrid Course** — 12 defensive days from `~/Desktop/Hakin`, in
[`../hakin-hybrid/`](../hakin-hybrid/); and **Blockchain Hybrid Course** — 14 days from
`~/Desktop/blck` wired into the Sui Move, Scrypto, Cairo and starklings courses, in
[`../blck-hybrid/`](../blck-hybrid/). Education and robotics already have their own
books, so the same engine is the only thing they would need to become day paths.

### The AGI track (Days 39-51)

Page anchors were located rather than guessed, because printed chapter numbers in these
files do not line up with physical pages: Togelius is printed + 12 (ch1 p.13, ch2 p.23,
ch3 p.43, ch4 p.63, ch5 p.79, ch6 p.93, ch7 p.113, ch8 p.139, ch9 p.155, ch10 p.165,
ch11 p.177), the OpenCog architecture survey opens at physical p.93 of _Building Better
Minds_, Rothman is printed + 27, and the Codex book opens its introduction at p.15.
Day 51 reads a 1,737-word DOCX through the paragraph mode of `read_source_text`.

### The second expansion (Days 52-85)

Fifteen more sources are registered, for 27 in the spine. The reason the remaining
`~/Desktop/ML` books could not be taught before is now fixed in `build_course.py`:
EPUBs are read in spine order and split into addressable units by their own headings,
and MOBI is decoded with a PalmDOC LZ77 reader that treats the book's bold headings as
section starts — so `§N` is a stable address in both formats, the way a page number is
in a PDF. Anchors for every new day were verified against the extracted text before the
day was written, and `make_bite` now trims at a sentence boundary, which is why the
whole 85-day spine sits inside the 180-560 word band.

Material that is not a book does not get a day, because the spine has to stay a path.
It gets a generated shelf page instead — Python references, the six Startup School lab
lists, the two study-craft worksheets, your own `codes/` folder, and the cross-branch
accounting — under [`src/shelf/`](src/shelf/). Every one of the 61 entries in
`~/Desktop/ML` is now either a scheduled day, a shelf reference, or a named leftover.

### The third expansion: the front of the spine (Days 1-17, 34-38)

The course was not zero-to-hero: two registered books carried no days, and nothing
taught Python or mathematics from nothing. `expand_prerequisites.py` ran once to fix
that — it registered `pyqinst` (*Python complete notes*, QuantInsti, 290pp), inserted 8
Python days and 9 mathematics days (MIT 6.042) ahead of the old Day 1, and placed 5
*Hands-On ML* days after the old consolidation day, taking the spine to 85 days.

Two things make that safe, and both are worth keeping if the spine grows again:

- **Every authored cross-reference moves with its day.** The script rewrites `Day N`,
  `Days A-B`, `Days A, B and C` and `day-NNN.md` filenames through the same old→new map
  it uses to renumber, so a lesson cannot end up pointing at a neighbour's day.
- **Stored progress follows the day, not the number.** The map is published as
  `course.day_shift` inside the curriculum, and `hybrid-course.js` translates
  `completed`, `blanked` and `lastOpened` through it exactly once (guarded by
  `progressShift`). Tick marks taken on the 63-day spine still mean the same lesson on
  the 85-day one.

Three chapter maps are now hand-authored (`python-complete-notes`, `mit6-042js15-textbook`,
`hands-on-machine-learning-…`) because the detector cannot see a title page that splits
`Chapter N` from its title, or a two-up banner page. Write `<!-- hand-authored -->` on the
second line of such a map and `inventory` will leave it alone instead of overwriting it with
"no chapter openings detected".

## Open it

```bash
cd ~/Desktop/ex
./exercises/serve-site.sh          # then http://127.0.0.1:8000/
```

Course page: <http://127.0.0.1:8000/ml-hybrid/hybrid-course.html>
Book pages (same content, mdBook form): `book/index.html` after a build.

## The two files that matter

| File | Role |
|---|---|
| `hybrid-curriculum.json` | The spine. Hand-curated order, page ranges, and the teaching fields per day. Everything else is generated from it. |
| `build_course.py` | Splits books into lessons. Stdlib + poppler only, so it runs offline. |

Generated, never hand-edited: `src/days/*.md`, `src/SUMMARY.md`, `src/index.md`,
`src/maps/*.md`, `hybrid-course-data.json`, `book/`.

## Commands

```bash
python3 build_course.py inventory --library ~/Desktop/ML     # chapter maps for every book
python3 build_course.py inventory --library ~/Desktop/Hakin --filter 'Kali|CEH'
python3 build_course.py plan                                 # show the spine, no writes
python3 build_course.py build                                # emit all lesson pages
python3 build_course.py build --from-day 1 --to-day 10
```

`inventory` writes `src/maps/<book>.md`: detected chapter openings with page
ranges, extent, and word count. That is the answer to "which book, which
chapter, where was I?" without reading anything.

## Adding a day

Append to `days` in `hybrid-curriculum.json`:

```json
{
  "day": 17, "track": "Sequencing", "book": "homl", "from": 30, "to": 42,
  "title": "…", "idea": "one-sentence learning outcome",
  "recall": "what to say from memory before reading",
  "misconception": "the predictable wrong belief this day breaks",
  "practice": "path to a local exercise",
  "check": "the evidence you must be able to point at",
  "gate": "the mastery test"
}
```

Then `python3 build_course.py build`. Marked-complete progress is keyed by day
number in the browser, so re-running the build never resets your progress.
Renumbering only stays honest if you do it through a `day_shift` map like the one in
`expand_prerequisites.py` — insert the map first, then rebuild; a bare renumber would
silently hand your old tick marks to different lessons.

## Where each field comes from

`idea` / `misconception` / `check` are the teacher fields of the local
SyncSenta curriculum schema (`Sync-0.0.2/data/ai_curriculum.json`: learning
outcomes, prerequisites, expected misconceptions, assessment evidence), applied
to an adult learner. The daily rhythm is the Kumon-style method already used by
`exercises/developer-path/src/study-method.md`. Nothing here is KICD/CBC-aligned
or officially endorsed; it is a personal adaptation.

## Spaced repetition

`RECALL_OFFSETS = (1, 3, 7, 21)` in `build_course.py`. Each lesson page lists
the one-sentence idea of the day that many lessons back, and the course page
turns those into buttons: **I remembered it** or **It went blank**. Blank ones
join a retry queue that stays visible until you re-answer them — that is the
mechanism that stops a new book from feeling like a restart.

## Other branches (same engine)

Already inventoried in `src/maps/`: every book in `~/Desktop/ML`, including
*Hands-On Deep Learning for IoT* (215 sections) and the blockchain titles.
For hacking, run `inventory --library ~/Desktop/Hakin`. For Rust, your GitHub
repos `teach-rs`, `RustTraining`, `rust-learning` and `teach-rs` exercises are
better sources than any PDF; `git clone --depth 1` the one you want and point
`inventory` at its markdown.

Suggested spine order for the next branch (hacking, 12 days): *The Basics of
Hacking and Penetration Testing* first four chapters → CEH study-guide domains →
Kali Linux Penetration Testing Bible labs → `exercises/security-exercises`
(`00_scope`, `01_detection`, `02_access`, `03_response`) as the practice arm →
*The Psychology of Cybersecurity* as the closing day.

## Publishing this folder

The git remote for this course is **public**, so `.gitignore` keeps the
generated extracts (`src/days/`, `hybrid-course-data.json`, `book/`) out of it —
those files hold other authors' paragraphs and are for personal study only.
What is published is the machinery, the syllabus and the chapter maps, which is
everything needed to rebuild the course against your own local books.

## Limits, honestly

- Text-layer PDFs only. A scanned book yields nothing until it is OCR'd; `plan`
  and `build` print `0 extracted words` for such a range instead of inventing text.
- Chapter detection reads the first line of a page. Books that set a heading across
  two lines (QuantInsti's Python notes), print two-up banner pages (MIT 6.042), or
  number their exercise lists like sections (Géron's *Hands-On ML*) map poorly to the
  detector, so those three maps are hand-authored from the title pages and their days
  cite ranges checked in `plan`.
- Page ranges are physical PDF pages, which drift between editions. The footer of
  every lesson names the file it came from, so a wrong range is checkable.
- Extracted passages are the authors' words, for your personal study. Do not
  publish this folder's `src/days/` contents as if they were yours.
