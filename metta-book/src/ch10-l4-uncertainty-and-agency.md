# L4 — Uncertainty and agency

L3 let you enumerate candidates and filter them. L4 is where the filter stops
answering True/False and starts answering *how much* — and where a MeTTa program
stops being a query engine and becomes something with states it wants. This is
the level the rover actually lives at: sensors that are probably right, a world
model that is partly stale, and a decision that has to pick one action anyway.

Two research traditions supply the vocabulary, and MeTTa gives you the mechanism
for both without special-casing either: PLN's strength/confidence pairs, and
Psi/OpenPsi's demands and actions. Neither is in the stdlib. You will write both,
in MeTTa, as data and rules — which is precisely the point.

Friday artifact: `decide.metta` — a drive-strength space, a small set of actions
with `(stv strength confidence)` atoms, and a `(choose)` that returns one action
and prints the scores that made it pick.

## Syntax

Uncertainty is an ordinary grounded tail on an ordinary relation. The shape your
own project notes ask for is a triple-with-stv, so treat that as the spec:

```metta
(Inheritance (Concept "off-line") (Concept "danger") (stv 0.7 0.8))
(Similarity  (Concept "dark")      (Concept "off-line") (stv 0.55 0.9))
```

Reading them as MeTTa data: `Inheritance` is a symbol-headed expression whose
third child is a grounded pair. Nothing special happens because of the `stv` —
it is your business, and it stays your business all the way down, which is the
good news: no hidden semantics to fight.

To get at the numbers, decompose. The direct way is pattern matching:

```metta
(= (strength-of $link)
    (match &kb (Inheritance $a $b (stv $s $c)) $s))
```

and the arithmetic you write yourself, because the helpers you would expect are
not in this build (`abs`, `sqrt`, `!=` absent; `min-atom`/`max-atom` return
floats — fact sheet):

```metta
(= (my-abs $x) (if (< $x 0.0) (- 0.0 $x) $x))
(= (and-stv $s1 $c1 $s2 $c2)
    (stv (* $s1 $s2) (min-f $c1 $c2)))
(= (min-f $a $b) (if (< $a $b) $a $b))
```

Agency is the same two mechanisms you already own — a named space for beliefs and
*state* for drives:

```metta
!(bind! &drives (new-space))
!(add-atom &drives (demand energy 0.35))
!(bind! &last-action (new-state none))
```

Selection over a nondeterministic candidate set, which is L3's search with a
score bolted on:

```metta
(= (action) (superpose (explore recharge wait)))
(= (score $a) (match &drives (utility $a $u) $u))
(= (scores) (collapse (score (action))))
(= (max-of $t) (foldl-atom $t 0 $acc $e (if (< $acc $e) $e $acc)))
!(max-of (scores))
```

`collapse` gives you the tuple; `foldl-atom` over tuple children picks the winner.
Two disciplines that are not optional on 0.2.10, both verified the hard way in
[L1 Unit 4](./ch05-00-evaluation-and-results.md): `collapse` is one-argument (it
packs a result set, it does not bind a variable — `let` binds), and the tuple you
hand to `foldl-atom` must arrive as a *bound variable*, because that parameter is
`Atom`-typed and is passed un-evaluated. `(foldl-atom (collapse (score (action)))
0 $acc $e …)` folds the call, not the hours, and answers with a `BadArgType`.
Remember `foldl-atom` folds tuple children, not `::` lists, and takes
five arguments (tuple, init, acc-var, elem-var, body).

## Semantics

**There is no uncertainty in the interpreter, and that is a design choice you get
to exploit.** `metta.md` lists what the interpreter recognises: `=`, `:`, `->`,
the elementary types, `Empty`/`NotReducible`/`Error`, and the minimal MeTTa
instructions. No `stv`, no probability, no belief revision. Everything at this
level is a library you write on top of rule lookup — which means (a) nothing will
stop you writing it wrong, and (b) the same code serves PLN-style links and
Psi-style demands because both are just atoms in a space. Keep that in the front
of your mind when you read `trueagi-io/PLN` and `pln-experimental`: they are the
same three functions you are about to write, with years of accumulated argument
about the constants.

**Nondeterminism is a candidate generator, not a distribution.** `(action)` above
returns *all* actions; it does not sample one. That is a category difference from
a probabilistic program and the single most common way people go wrong here. If
you want a sample, get one from the `random` module (`new-random-generator`,
`random-int`, `flip` — all verified present) and drive it with weights you compute;
if you want the whole set, `collapse` it. Do not confuse "the interpreter tried
both rules" with "there is a 50% chance". The 50% is something you must write.

**Confidence and strength compose differently and your `and-stv` is a claim.**
PLN's deduction/evaluation rules define how `(stv s c)` pairs combine, and the
naive `(* s1 s2)` with `min c` is an approximation you should label as such in
your own file. The honest way to build this on a laptop with no reference
implementation: write the arithmetic, then write the *properties* you believe as
assertions — identity with a certain link, monotonicity, order independence:

```metta
!(assertEqual (strength-of (Inheritance a b (stv 0.7 0.8))) 0.7)
!(assertEqualToResult (and-stv 0.5 0.9 1.0 1.0) (stv 0.5 0.9))
```

If a property fails, your composition rule is wrong, not the interpreter.

**Type errors and float coercion are your main failure modes.** `0.7` is a
grounded `Number` and the arithmetic is host arithmetic, so `(/ 1 3)` (integer
truncation → `0`) next to `(/ 1.0 3.0)` in the same file is a real hazard in
scoring code. When a score comes out `0` and you are sure it shouldn't, look for
an integer literal. This is the same cliff that made `min-atom` answer `1.0`.

**Drives belong in state, beliefs belong in a space.** The distinction is
semantic, not stylistic: a demand *changes value* and has no identity to query
(`(get-state &x)`), while a belief *is* an atom, can coexist with other beliefs,
and is found by matching. OpenPsi's layout (a `demand` module, an `emotion`
module, a `modulator`, and `action-planner` variants such as `aStar` and
`thompson-sampling`) encodes exactly this split, which is why it is the reading
target for this level. Two caveats to keep you honest: that repo pins
`hyperon==0.2.3`, so its code will not run unmodified on your 0.2.10 wheel, and
its file layout is one team's opinion about the boundary between `&self` and
imported spaces — see [L3](./ch09-l3-modules-and-search.md)'s upward-dependency
rule for why an emotion module has to be *given* the drives rather than reaching
for them.

**Motive selection is a fold over scores, and folds are where the bug is.** The
canonical shape you want is: enumerate actions, compute a utility for each,
fold to a winner, mutate `&last-action`, return the winner. Read stepwise, the
failure is that `(score $a)` with no matching utility returns *silence* rather
than a number, so the fold sees fewer elements than the enumeration — and you
get a winner chosen from a subset without ever being told. Verified behaviour:
`match` with no results prints nothing; a rule body that evaluates to nothing
contributes no result to a nondeterministic set. Always give the missing case a
value:

```metta
(= (score $a) (match &drives (utility $a $u) $u))
(= (score $a) 0.0)
```

Now `(score $a)` is total. (And now you have two rules for one head, so read
[L1 Unit 3](./ch04-00-functions-and-pattern-matching.md) again: on the days the
`match` succeeds, do you get one result or two? Answer that before you run it.
The answer is what makes "totality" a design problem rather than a typo.)

**Errors are data all the way up, including here.** `(Error <atom> <message>)` is
a legitimate result an action's score can carry, and the spec's
`interpret_expression` drops errors when any success exists. Which means a
decision layer can *silently* discard the failing option instead of reporting it.
If your rover goes quiet about a broken sensor, that is the mechanism. Surface it
by folding over a `collapse`d tuple — errors survive as tuple children — rather
than letting the result-set filter them out.

## Exercises

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | `!(strength-of (Inheritance a b (stv 0.7 0.8)))` | | `0.7` |
| 2 | `!(and-stv 0.5 0.9 1.0 1.0)` | | `stv 0.5 0.9` |
| 3 | `!(/ 1 3)` vs `!(/ 1.0 3.0)` | | `0` vs a float |
| 4 | `!(collapse (score (action)))` with 3 actions, 2 utilities | | 3 or 2 elements? |
| 5 | `!(min-atom 1.0 2.0)` | | `1.0` |
| 6 | `!(my-abs -0.4)` | | `0.4` |
| 7 | `!(random-int 1 6 &rng)` after `new-random-generator` | | one integer |
| 8 | `!(flip &rng)` | | `True` or `False` |

Tasks:

1. Write `and-stv`, `or-stv`, `not-stv` and `deduce-stv` over `(stv s c)` pairs
   using only `if`, `<`, `*`, `min-f`, and your own `my-abs`. For each, write two
   property assertions: one boundary case and one commutativity/idempotence case.
2. Build the KB: ≥8 `Inheritance`/`Similarity` links about the rover's world
   (off-line, danger, battery-low, dark, obstacle-near, charged, mapped, lost),
   stored in `&kb`, and a `(believe $concept)` that returns the link's strength
   for a named concept.
3. Drives: `&drives` space with `demand` atoms; a `modulator` rule that lowers
   `energy` per tick and raises `danger-avoidance` when
   `(believe "off-line")` is high. Use state for the counters and a space for the
   beliefs, and write one sentence justifying each choice.
4. Selection: enumerate `(action)`, score each, `collapse`, `foldl-atom` to an
   argmax, mutate `&last-action`, return the winner. Then break it on purpose —
   delete one `utility` fact — and diagnose it from the element count, exactly as
   the Semantics section predicts. Then make `score` total.
5. Write `(choose-weighted &rng)` that samples with the weights instead of taking
   the max, using `random-int`. Run it 20 times and tally. Say out loud whether
   the tally matches the weights, and if it doesn't, whether the bug is your
   sampling or your arithmetic (it is usually integer truncation).
6. Redo [L3](./ch09-l3-modules-and-search.md) task 3 (find expressions equal to
   `7`) as a *soft* search: score each candidate by how close it gets, and return
   the best rather than the exact. Write one paragraph on what you gained and
   lost versus the exact filter.

Recall cards (1/3/7/21):

- Name three things the interpreter recognises and two it does not.
- Nondeterminism is a ____ generator, not a ____.
- Which three arithmetic helpers are absent on 0.2.10?
- Why does a missing `utility` fact shrink the fold instead of raising?
- Which lives in state, which in a space, and why?

## Ship it

Friday: `decide.metta` with the KB, the drives, a total `score`, the argmax fold,
`choose-weighted`, and every property assertion passing. Add a header comment
naming the two reading targets (`trueagi-io/PLN`, `iCog-Labs-Dev/hyperon-openpsi`)
and the one thing each taught you that this file now implements in your own words.
Next: [L5 — interop and the export bridge](./ch11-l5-interop-and-export.md), where
MeTTa stops being an island: grounded Python, `json` and `fileio` out, and minimal
MeTTa as the assembly layer you need before you can honestly claim a
MeTTa→THRML path exists.
