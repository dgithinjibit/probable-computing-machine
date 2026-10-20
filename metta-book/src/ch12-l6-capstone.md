# L6 — The capstone: a rover that reports

No new syntax in this chapter. That is the test: L0 through L5 were the parts, and
L6 asks whether you can hold the whole thing in your head at once, name the parts,
and defend a number about it. The artifact is the one your plan keeps pointing at
— a MeTTa program that models a rover, decides, remembers, exports, and *proves
itself* in a way a stranger can re-run — plus two smaller pieces of
infrastructure the plan also keeps pointing at: an hour log you can query, and a
spaced-repetition deck written in the language you are learning.

Friday artifact: `rover/` with `rover.metta`, `hours.metta`, `deck.metta`, and a
README where every claim is a command.

## Syntax

The project shape, using only constructs you already own:

```metta
; rover.metta
!(import! &self json)
!(import! &self fileio)
!(import! &self random)

!(bind! &world    (new-space))   ; rooms, connections, objects
!(bind! &percepts (new-space))   ; the last tick's sensor atoms
!(bind! &kb       (new-space))   ; (Inheritance … (stv s c)) beliefs
!(bind! &log      (new-space))   ; events, appended as atoms

!(bind! &mode       (new-state idle))
!(bind! &energy     (new-state 100))
!(bind! &last-move  (new-state none))

(= (tick!) …)          ; read percepts → update beliefs → choose → mutate → log
(= (report) (report-tuple (get-state &mode) (get-atoms &percepts) (get-atoms &log)))
```

The hour log, exactly as your notes specify it, plus the queries that make it
worth having:

```metta
; hours.metta
(= (hours day-342) 14)
(= (hours day-343) 9)
(= (total) (foldl-atom (14 9) 0 $a $e (+ $a $e)))     ; tuples, not :: lists
(= (days-count) (count-of (match &self (hours $d $h) 1)))
```

and the review deck, where cards are atoms and "due" is arithmetic:

```metta
; deck.metta
(card c-07 :topic "same-head rules" :level L1 :last 341 :step 1)
(= (due? $c $today)
    (let (:step $n) (match &self (card $c :step $n) $n)
      (let $gap (- $today (age-of $c))
        (if (>= $gap $n) True False))))
```

Offsets 1/3/7/21 are `:step` values you advance when a card is answered; `>=`
exists, `!=` and `abs` do not (fact sheet), so write the gap test with `>=` and a
guard against negative gaps rather than reaching for `abs`.

## Semantics

**Composition failures are address failures, not logic failures.** Nine out of
ten "the rover stopped working" bugs at this stage are one of: a rule reading
`&self` when it should have taken a space argument
([L3](./ch09-l3-modules-and-search.md)'s no-upward-dependency rule), a fact
written into the wrong space so `match` returns silence
([L1 Unit 2](./ch03-00-facts-spaces-queries.md)), or a mutation firing twice
because two rules share a head ([L4](./ch10-l4-uncertainty-and-agency.md)). The
diagnostic move is always the same: print the *count* of results you expect before
printing the results — `!(collapse (…))` and look at the tuple's size. Silence
is ambiguous; a size is not.

**State is a liability you should budget.** Every `new-state` in the file is a
place where re-running a query changes the answer, which is what makes a
self-test flaky. Keep the count small and name the reason for each one — mode,
energy, last-move — and keep everything else in spaces, where a test can be run
twice and mean the same thing. When you need history, append to `&log` as atoms
rather than accumulating in state: the log is queryable, and a state is not.

**`hours.metta` has an arithmetic cliff in it.** Integer division means
`(/ (total) (days-count))` truncates, so a "12 hours a day" average can print
`11`. Multiply by `1.0` somewhere honest, or keep the totals and report them as
`(list 23 11)`-style tuples and let the README do the division. Do not discover
this while defending a number in front of someone else — that is the failure mode
this level is designed to rehearse.

**`foldl-atom` over a tuple and recursion over a list are different tools, and
the choice must be defensible.** Your log is naturally a set of `(hours $d $h)`
atoms, so the sum needs either a `collapse` first (giving a tuple you can fold) or
a recursive fold over a `::` list you build yourself. Both are legitimate; the
book's preference is `collapse` + `foldl-atom` for one-shot sums and `::`
recursion when the accumulator is structural. Say which you used and why, in the
file.

**The deck is the only part that must be boring.** Spaced repetition works
because it is mechanical: `due?` returns cards, you answer, you write a new
`:last` and a stepped `:step`. If `deck.metta` gets clever, you will stop running
it. Keep it to four rules and one `match`, and put the eight recall cards from
L1–L5 into it verbatim so the review is testing *you* rather than the interpreter.

**A capstone is judged by whether the number survives contact.** The standard for
this and every later project: no claim in the README without a command under it,
and no command that depends on the working directory being wherever you happened
to be (see [Getting started](./ch00-getting-started.md) and the `import!` CWD
rule). "The rover chooses `recharge` when energy < 30" must be a line you can
paste, with its output pasted under it. That discipline is what the last three
levels were for — the interpreter will happily print nothing and call it a day,
and only an assertion tells you the difference between "no results" and "wrong
results".

## Exercises

Build in six increments; each ends with `metta rover.metta` printing only what you
predicted in writing.

1. **World + percepts.** `&world` loaded from a `world.metta` module
   ([L3](./ch09-l3-modules-and-search.md)), `&percepts` refreshed by a
   `(sense!)` rule. Assert one `get-atoms` shape and one `match`.
2. **Beliefs.** ≥8 `stv` links in `&kb`, `and-stv`/`deduce-stv` from
   [L4](./ch10-l4-uncertainty-and-agency.md), and `danger?` reading the derived
   strength rather than a raw sensor.
3. **Decision.** `choose` with a total `score`, an argmax fold over a `collapse`d
   tuple, and `!(set-mode! …)` / `&last-move` mutation that provably happens once
   — assert the state value after exactly one `tick!`.
4. **Export.** `(report)` → THRML-shaped tuples via `lower`
   ([L5](./ch11-l5-interop-and-export.md)) → `json-encode` →
   `file-write! /tmp/day.json`, plus the round-trip assertion.
5. **Log + deck.** `hours.metta` with `total`, `days-count`, and a truncated-vs
   true average demonstration (both printed, labelled). `deck.metta` with ≥12
   cards spanning L0–L5, `due?`, `answer!` (advances `:last` and steps `:step`),
   and a `(next)` that returns today's set.
6. **The gate.** Close the book. Re-answer [L0](./ch01-l0-imitation.md)'s gate
   from memory — the six cards retyped, the symmetry exercise, the `()`-versus-no
   line reading — on the keyboard, in a scratch file, with the interpreter as the
   only referee. Then write the README: what the rover does, the three design
   choices you defended above (state budget, fold mechanism, average arithmetic),
   and every command with its pasted output.

Then the oral exam, in the README, in your own sentences:

- Why is `&kb` a space and `&energy` a state?
- What does `!(match &kb (Inheritance a $b $s) …)` return for a *derived*
  belief, and what must you call instead?
- How many rules may fire in one `tick!`, and how did you make sure it is one?
- Where does integer arithmetic first lie to you in this project?
- What is in `/tmp/day.json`, and who reads it?

Recall cards (1/3/7/21) for the deck itself:

- The three failure classes at this level, one line each.
- The one diagnostic that disambiguates silence.
- Two fold mechanisms and the reason to pick each.
- What makes a claim publishable.

## Ship it

Friday: the `rover/` directory, `rover.metta` running from a clean shell with all
assertions green, `hours.metta` and `deck.metta` queryable, the README with
commands and outputs, and the L0 gate answered without looking. That is zero to
hero as this book defines it: not "knows everything", but "ships a thing that
proves its own claims and can explain, to a stranger, why each part is where it
is".

Then there is one more chapter, and it is not more syntax.
[L7 — Program search: the MOSES shape](./ch13-l7-moses.md) takes the enumeration
machinery from [L3](./ch09-l3-modules-and-search.md) and points it at a truth table:
normal forms, demes, per-row fitness, and a complexity penalty that makes a wrong
answer beat a right one. It is the first chapter in this book where the program you
are searching for is written in the same language as the search.

After that there is no next chapter, only the corpus in
[Appendix: the public MeTTa corpus](./appendix-10-sources.md) and the two things
your plan says matter more than reading — teaching it to someone, and defending a
number. Both are now testable with tools you wrote.
