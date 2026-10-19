# mit6_042js15_textbook.pdf
<!-- hand-authored -->

- file: `/home/skware/Desktop/ML/mit6_042js15_textbook.pdf`
- extent: 920 pages, ~284,299 words
- registered as: `mit42` — **Days 9-17** (Mathematics for ML)

## Chapter map (chapter openings, physical pages)

`find_chapters` reports nothing for this file: MIT's sheet is typeset two-up with the
chapter title on a banner page, and the printed page numbers restart from the course
front matter. Openings below were read off the pages. **physical = printed + 9**, so a
printed chapter page of 41 is physical 50.

| Ch | Title | Opens (physical) | Used by |
| --- | --- | --- | --- |
| 2 | Well Ordering Principles | 36 | not yet scheduled |
| 3 | Logical Formulas | 50 | Day 9 |
| 4 | Mathematical Data Types | 90 | Day 10 |
| 5 | Induction | 124 | Day 11 |
| 6 | Recursive Data Types | 182 | Day 12 |
| 7 | Infinite Sets | 214 | not yet scheduled |
| — | Number Theory (chapter number not confirmed from the contents) | 252 | reference shelf |
| 11 | Simple Graphs | 402 | not yet scheduled |
| 13 | Sums and Asymptotics | 512 | Day 13 |
| 14 | Cardinality Rules | 560 | not yet scheduled |
| 15 | Generating Functions | 636 | not yet scheduled |
| 16 | Events and Probability Spaces | 676 | Day 14 |
| 17 | Conditional Probability | 706 | Day 15 |
| 18 | Random Variables | 748 | Day 16 (its §18.4 opens near 760) |
| 19 | Deviation from the Mean | 798 | Day 17 |
| 20 | Random Walks | 848 | not yet scheduled |

Chapters 1 and 8-9 and 11 were not located to a page: their title banners do not appear
as a standalone line in the extracted text, so they are deliberately absent rather than
guessed. Find them by the same method (first page whose top lines carry the title) before
scheduling a day there.

## Reading notes

- The chapter banner page and the running head both repeat the title, so the *first*
  page on which a title appears is the opening; later repeats are inside the chapter.
- Every page carries the build stamp running head (`... page 115 - #1`) and most carry a
  trailing page number. Both are filtered by `noise()`, which is why a 8-page range reads
  as continuous prose rather than as typesetting.
- Chapters 16-20 are the half of this book that machine learning actually consumes:
  sample space, conditioning, expectation, variance. Days 14-17 stop there on purpose;
  Random Walks and Cardinality Rules belong to a later pass.
- A worked example in this book is worth more than its prose. Each of Days 9-17 pairs the
  bite with either a standard-library simulation or one of the `../../ml-exercises`
  files, because induction and expectation both have to be *run* to be believed.
