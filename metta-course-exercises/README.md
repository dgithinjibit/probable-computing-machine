# MeTTa exercises: zero to hero

Work through the numbered challenges in order. Each `exercises/` file is a
starter: read the task, implement the missing rule(s), and make its assertions
pass. The matching file under `solutions/` contains one complete answer.
Try the exercise before opening its solution.

The path connects to the book: read the listed chapter, run its
[`listings/`](../metta-book/listings/) example, then solve the challenge.
From this folder's parent (the `ex` directory), run an individual file with:

```bash
metta metta-course-exercises/exercises/00_foundations/01_double.metta
```

Run the complete solution check with:

```bash
bash metta-course-exercises/check-solutions.sh
```

Preview the companion book with
`mdbook serve metta-book --hostname 127.0.0.1 --port 3000`; open
[http://127.0.0.1:3000](http://127.0.0.1:3000). See the
[book guide](../metta-book/README.md) or the exercises-root [README](../README.md)
for the combined portal instructions.

## Learning path

| # | Exercise | Book connection | Skills |
| --- | --- | --- | --- |
| 01 | [Double a number](exercises/00_foundations/01_double.metta) | [Evaluation](../metta-book/src/ch05-00-evaluation-and-results.md) | Function rules, arithmetic |
| 02 | [Query family facts](exercises/00_foundations/02_family_facts.metta) | [Facts and queries](../metta-book/src/ch03-00-facts-spaces-queries.md) | Atoms, spaces, pattern queries |
| 03 | [Positive numbers](exercises/00_foundations/03_positive.metta) | [Types and errors](../metta-book/src/ch06-00-types-and-errors.md) | Signatures, booleans, comparisons |
| 04 | [Larger of two numbers](exercises/00_foundations/04_maximum.metta) | [Functions and patterns](../metta-book/src/ch04-00-functions-and-pattern-matching.md) | Branching, comparisons |
| 05 | [Factorial](exercises/01_recursion/05_factorial.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | Base cases, numeric recursion |
| 06 | [List length](exercises/01_recursion/06_length.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | Structural recursion |
| 07 | [List sum](exercises/01_recursion/07_sum.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | Recursive accumulation |
| 08 | [Append](exercises/01_recursion/08_append.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | List construction |
| 09 | [Reverse](exercises/02_lists/09_reverse.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | Helper functions, append |
| 10 | [Map](exercises/02_lists/10_map.metta) | [Functions and patterns](../metta-book/src/ch04-00-functions-and-pattern-matching.md) | Higher-order functions |
| 11 | [Filter positive values](exercises/02_lists/11_filter.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | Predicates, conditional list building |
| 12 | [Remove all matches](exercises/02_lists/12_remove.metta) | [Evaluation](../metta-book/src/ch05-00-evaluation-and-results.md) | Equality, branching, recursion |
| 13 | [Membership](exercises/02_lists/13_contains.metta) | [Functions and patterns](../metta-book/src/ch04-00-functions-and-pattern-matching.md) | Boolean recursion |
| 14 | [Minimum](exercises/03_algorithms/14_minimum.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | Recursive helper state |
| 15 | [Sort a list](exercises/03_algorithms/15_sort.metta) | [Build a small program](../metta-book/src/ch08-00-build-a-small-program.md) | Compose minimum, removal, recursion |
| 16 | [Positive total](exercises/03_algorithms/16_positive_total.metta) | [Build a small program](../metta-book/src/ch08-00-build-a-small-program.md) | Combine filter, map, and sum |
| 17 | [Count occurrences](exercises/04_challenges/17_count_occurrences.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | Recursive counting |
| 18 | [Fibonacci](exercises/04_challenges/18_fibonacci.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | Numeric recursion and base cases |
| 19 | [Two sum](exercises/04_challenges/19_two_sum.metta) | [Functions and pattern matching](../metta-book/src/ch04-00-functions-and-pattern-matching.md) | Search, complements, distinct elements |
| 20 | [Palindrome list](exercises/04_challenges/20_palindrome.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | List equality and reversal |
| 21 | [Remove duplicates](exercises/04_challenges/21_unique.metta) | [Lists and recursion](../metta-book/src/ch07-00-lists-and-recursion.md) | Accumulators and stable output |
| 22 | [Merge sorted lists](exercises/04_challenges/22_merge_sorted.metta) | [Build a small program](../metta-book/src/ch08-00-build-a-small-program.md) | Ordered recursion and merge |
| 23 | [Unlock the next lesson](exercises/05_applied/23_unlock_next_lesson.metta) | [Facts and queries](../metta-book/src/ch03-00-facts-spaces-queries.md) · [Functions and patterns](../metta-book/src/ch04-00-functions-and-pattern-matching.md) | Rule-based prerequisite lookup with synthetic course facts |
| 24 | [A space you can inspect](exercises/06_spaces_state/24_named_space.metta) | [Facts, spaces and queries](../metta-book/src/ch03-00-facts-spaces-queries.md) | `bind!`, `add-atom`, `get-atoms`, cross-space queries |
| 25 | [A counter that moves](exercises/06_spaces_state/25_state_counter.metta) | [Build a small program](../metta-book/src/ch08-00-build-a-small-program.md) | `new-state`, `change-state!`, one-rule discipline |
| 26 | [Two coins, four results](exercises/07_nondeterminism/26_coin_pair.metta) | [Evaluation and results](../metta-book/src/ch05-00-evaluation-and-results.md) | Same-head rules, multiplication of results, `collapse` |
| 27 | [Find the program by rules](exercises/07_nondeterminism/27_search_by_rules.metta) | [Modules and search](../metta-book/src/ch09-l3-modules-and-search.md) | Enumeration + guard + `Empty` as a search filter |
| 28 | [Modules, by hand](exercises/08_modules_search/README.md) | [Modules and search](../metta-book/src/ch09-l3-modules-and-search.md) | Manual lab: `import!`, module `&self`, no upward dependencies |
| 29 | [Cross-check with PeTTa](exercises/09_uncertainty/29_peTTa_crosscheck.metta) | [Appendix: Offline Workflow](../metta-book/src/appendix-00-offline-workflow.md) | Manual lab: same program, two implementations, is it language or build? |
| 30 | [Strength and confidence](exercises/09_uncertainty/30_stv_arithmetic.metta) | [Uncertainty and agency](../metta-book/src/ch10-l4-uncertainty-and-agency.md) | Writing `stv` composition yourself, property assertions || 31 | [A belief space with one hole](exercises/09_uncertainty/31_belief_space.metta) | [Uncertainty and agency](../metta-book/src/ch10-l4-uncertainty-and-agency.md) | `match` over grounded tails, `collapse` + `foldl-atom`, silent shrink |
| 32 | [Getting data in and out](exercises/10_interop_export/32_json_roundtrip.metta) | [Interop and the export bridge](../metta-book/src/ch11-l5-interop-and-export.md) | Bare `json`/`fileio` imports, string keys, round trip |
| 33 | [Lower a program](exercises/10_interop_export/33_lower_a_program.metta) | [Interop and the export bridge](../metta-book/src/ch11-l5-interop-and-export.md) | Programs as data, disjoint patterns, one answer per program, transducer vs compiler |
| 34 | [The hour log](exercises/11_capstone/34_hour_log.metta) | [The capstone](../metta-book/src/ch12-l6-capstone.md) | Facts vs rules (a rule-shaped log is invisible to `match`), tuple folds through `let`, integer truncation |
| 35 | [The review deck](exercises/11_capstone/35_review_deck.metta) | every level | Cards as atoms, 1/3/7/21 stepping, guarded gap arithmetic |

## Two manual labs: 28 and 29

Neither has a solution file, and neither is checked by `check-solutions.sh`, for
the same reason: what they teach cannot be verified from an arbitrary directory or
by one interpreter alone.

**28 — modules.** `import!` resolves a module name against the **current working
directory**, so a module exercise cannot be checked from wherever the script
happens to run — which is exactly the property the lab teaches. Follow
[`exercises/08_modules_search/README.md`](exercises/08_modules_search/README.md),
run it from inside that directory, then run it again from `/tmp` and read the
`Failed to resolve module top:world` error it gives you. (If you run
`user.metta` from this folder by accident, that error is the expected output, not a
bug in the exercise.)

**29 — a second implementation.** `exercises/09_uncertainty/29_peTTa_crosscheck.metta`
is a comparison lab between this build (hyperon 0.2.10) and
[`~/Desktop/ex/exercises/peTTa`](../peTTa), which is MeTTa written in Prolog. It
needs SWI-Prolog ≥ 9.3 before it can run, so it is a Friday-afternoon lab rather
than a Tuesday-evening one.

## Two kinds of red, and why both are fine

Run a starter file and you will see one of two things. Exercises 3–23 keep their
`assert*` calls **live**, so an unsolved file fails loudly with
`Got: (positive 4)` — the call, unreduced, because you have not written the rule
yet. That is the intended starting state: red before green, and the shape of the
failure is itself a lesson (an unmatched call is returned as data, not as an
error). Exercises 24–35 keep their assertions **commented**, so an unsolved file is
silent and the green arrives when you uncomment. Pick the style you are working in
before you decide whether a red is progress or a mistake.

The solutions, all 33 of them, are verified green on this build:
`bash metta-course-exercises/check-solutions.sh` → "All MeTTa exercise solutions
passed", most recently 2026-10-19, after nine of them were fixed.

## Challenge practice

The final six tasks use familiar coding-interview and Exercism-style problem
shapes: define behavior from examples, implement a function, and check boundary
cases with assertions. The files are original local exercises, not a published
Exercism track; sharing a track there would additionally require track
metadata, test-runner integration, and maintainers. Solutions are separate so
you can try each starter without seeing its implementation.

## Preparing problems for Exercism

The task statements and input/output examples in the exercise files are
designed to stand alone as problem prompts. They can be adapted into a
community MeTTa track, but these local files are not themselves an Exercism
track package: automated Exercism submissions also need track metadata and a
compatible test runner. The local assertions and solution checker provide a
working offline baseline first.

The applied lesson-unlocking exercise demonstrates a deterministic rule over
synthetic course facts. It is a programming exercise, not an endorsement of
automatically grading learners or making high-impact education decisions.
