# The course contract

This is a zero-to-hero course in MeTTa, the symbolic language Hyperon runs. It
is not a university course with a MeTTa label on it. A university course ends
with you answering questions about the language. This one ends with artifacts
other people can run and a number they can reproduce, because that is the only
currency in the field you are aiming at.

Seven levels, each defined by one artifact and one gate:

| Level | Name | The artifact you finish with |
|---|---|---|
| L0 | Imitation | Five programs typed cold from memory, all assertions passing |
| L1 | The five verbs | A self-testing program that stores, matches, rewrites, evaluates and types |
| L2 | Data and spaces | A layered AtomSpace for one robot: percepts, world model, plan |
| L3 | Search | A candidate enumerator that scores programs against your own tape data |
| L4 | Uncertainty and agency | STV reasoning over beliefs, plus demand-driven motive selection |
| L5 | The bridge | An AtomSpace in, another representation out: JSON export, and a MeTTa interpreter written in MeTTa |
| L6 | Public proof | `rover.metta` that runs offline, a logged hour count, and a claim with a measurement |

Every unit inside L1-L6 has the same three parts, in this order.

**Syntax** — what the grammar permits you to write, and what it refuses. Short,
mechanical, checkable.

**Semantics** — what the interpreter actually does with it. This is where MeTTa
punishes guessing, so every semantic claim in this book is a claim about a
program that was run on this machine, with the output printed underneath.

**Exercises** — a predict-the-output table first (write the answer, then run),
then a program to write, then a gate you can only pass by pointing at output.

## Why the order is like this

MeTTa failures are almost never grammar failures. They are evaluation-strategy
failures: you expected one result and got none, or two, or an un-reduced
expression, or the interpreter stopped answering entirely. Three examples you
will meet in the first two levels, all real, all from listings in this book:

A recursive function written as two rules, a base case and a general case, can
never terminate, because both rules match the same call and the interpreter
explores both. The fix is one rule with the stop written inside it as a guard
(L0, card 3).

Two rules with the same head do not override each other. There is no
first-match-wins and no specificity ranking. Adding a stricter rule alongside a
looser one gets you the answer twice (L0, card 6).

`match` searches stored atoms. A rule head is not a fact, so a derived relation
has to be *called*, not queried, and a comma conjunction only has meaning inside
a `match` pattern — putting `(, ...)` in the body of a rule produces a data
structure, not a test (L0, card 6 and L1).

A university course would put those in a footnote. Here they are the curriculum,
because they are what costs you a Saturday.

## How to work through it

One unit per sitting, never two. Type the listing rather than copying it; the
finger-memory is the point of L0 and it is how the spaced review in
[L6](./ch12-l6-capstone.md) stays cheap. Predict before you run. When output
surprises you, cut the file down to one rule and one query, which is the only
debugging loop that works in this language.

Friday, ship something: a clip of the rover, a repo commit, a thread. The
shipping chain is the load-bearing part of your two-year plan, not the daily
hour count.

## What this book is built on

The language is implemented by
[`trueagi-io/hyperon-experimental`](https://github.com/trueagi-io/hyperon-experimental).
A copy sits in [`../hyperon-experimental/`](../hyperon-experimental/) and it is
version-matched to the runtime on this machine (0.2.10), so its
`docs/metta.md` specification and its `python/tests/scripts/` suite are used
here as primary sources rather than as references. Other public material is
catalogued per level in the
[sources appendix](./appendix-10-sources.md); the short version is that the
teaching corpus is real and thin, and this book leans on
`trueagi-io/metta-examples`, `trueagi-io/chaining`, `trueagi-io/hyperon-moses`,
`iCog-Labs-Dev/hyperon-openpsi`, `eyuuab/MeTTa-lang-stdlib-documentation` and
`logicmoo/metta-testsuite`.

Everything runnable is in [`listings/`](../listings/), named by level
(`l1-04-facts-matching.metta`). `bash verify-offline.sh` runs all of them and
fails on any error atom, so a chapter cannot silently drift from the machine.

The write-it-yourself problems and their solutions are in the neighbouring
[`metta-course-exercises/`](../metta-course-exercises/) track. The AGI reading that motivates
the PSI and PLN parts of L4 lives in the
[ML hybrid course](../ml-hybrid/hybrid-course.html), Days 39-51; this book is
the part where you implement it instead of reading about it.
