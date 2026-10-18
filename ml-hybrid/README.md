# Hybrid book courses (build system)

One course on this laptop was **messy and thin**: too many books, no order, no
memory of where you stopped. This folder fixes that by turning owned PDFs and
EPUBs into an **ordered day path** — each day names the book, the exact pages,
the author's own words at bite size, one local exercise, and an automatic
spaced review of the days you already completed.

Currently built: **ML Hybrid Course** — 16 days from `~/Desktop/ML`;
**Hacking Hybrid Course** — 12 defensive days from `~/Desktop/Hakin`, in
[`../hakin-hybrid/`](../hakin-hybrid/); and **Blockchain Hybrid Course** — 14 days from
`~/Desktop/blck` wired into the Sui Move, Scrypto, Cairo and starklings courses, in
[`../blck-hybrid/`](../blck-hybrid/). Education and robotics already have their own
books, so the same engine is the only thing they would need to become day paths.

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
Deleting or renumbering a day does — append instead.

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
- Chapter detection reads the first line of a page; books that print headings as
  graphics (Géron's *Hands-On ML*) map poorly, so their days cite ranges you
  found in `plan` or the ToC by hand.
- Page ranges are physical PDF pages, which drift between editions. The footer of
  every lesson names the file it came from, so a wrong range is checkable.
- Extracted passages are the authors' words, for your personal study. Do not
  publish this folder's `src/days/` contents as if they were yours.
