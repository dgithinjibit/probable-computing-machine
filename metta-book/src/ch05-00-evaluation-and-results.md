# L1 · Unit 4 — Evaluation and results

Everything so far assumed one call gives one answer. It doesn't: a MeTTa call
returns a *list of results*, and this level is where that list becomes the
language's most useful feature rather than a source of surprise. The rover is
going to generate candidate actions and score them; that is literally this
mechanism, so nothing here is academic.

Friday artifact: `nondet.metta` that enumerates the truth table of a two-input
gate, `collapse`s a search into a tuple, and prints exactly the number of results
you predicted.

## Syntax

The prefix `!` is the only evaluation control you use daily. What it does, from
the spec's Interpretation section: evaluate the atom, hand the results to the
user, and do **not** store them. The absence of `!` stores. Two extra forms you
need to recognise but will mostly avoid:

```metta
!(let $x (superpose (1 2 3)) (* $x 10))   ; 10 20 30
!(collapse (superpose (1 2 3)))           ; (1 2 3) — results become a tuple
!(eval (+ 1 (* 2 3)))                     ; exactly one reduction step
```

`superpose` is the nondeterminism constructor: `(superpose (a b))` means "this
position may be `a` or `b`". `collapse` is its dual — run the inner expression
and pack every result into one tuple. Together they replace most of what other
languages call list comprehensions.

**`collapse` takes exactly one argument, and it is not a binder.** Verified on
0.2.10: `!(collapse $r (coin))` answers
`(Error (collapse $r (coin)) IncorrectNumberOfArguments)`. The thing that binds a
variable to each result in turn is `let`, and `let` is where the multiplicity
comes from — `(= (pair) (let $a (coin) (let $b (coin) (ab $a $b))))` gives four
results because the two nested `let`s each fork. Two-argument `collapse` is a
syntax you will see in older write-ups and in `collapse-bind` (the minimal MeTTa
instruction, [L5](./ch11-l5-interop-and-export.md)); it is not this build.

`query`-shaped reading of results: the CLI prints one line per non-empty result
list, with the atoms of a list joined by spaces. So `!(match &self (p $x) $x)`
over two matching facts prints one line containing both atoms, and
`!(match &self (p $x) (q $x))` prints one line per binding. Do not read the
line-breaks as data structure; read them as print formatting.

The metatypes are the third dial, from the spec's "Elementary types": `Atom`,
`Symbol`, `Variable`, `Expression`, `Grounded` all "affect the order of the
expression evaluation", and `Atom` matches anything. In practice you use `Atom`
in a signature when you want an argument left alone:

```metta
(: hold (-> Atom Atom))
(= (hold $x) $x)
!(hold (+ 1 2))    ; stays an expression, printed unevaluated
```

## Semantics

**A call's result is a set, and sets multiply.** The spec's
`interpret_tuple`/`interpret_args` loops are nested `for` loops over results. If
argument 1 has 2 values and argument 2 has 2 values, the call has 4 results.
Verified on this build: `(pair (bin) (bin))` where `(= (bin) 0) (= (bin) 1)`
produces four combinations. This is why "just add another rule" is a *search
strategy* at [L3](./ch09-l3-modules-and-search.md) and a *bug* in arithmetic.

**`eval` is one step, and only one.** `(eval (+ 1 (* 2 3)))` does not compute 7;
it performs a single reduction, giving `(+ 1 6)` — the multiplication is the
innermost redex. And a second `eval` on an atom the interpreter has already
marked evaluated does nothing, because the spec's `metta` short-circuits:
`elif $metatype == Expression and <$atom is evaluated already>: return
[($atom, $bindings)]`. That optimization is the reason `!(eval (eval x))` is not
the same as `!(eval x)` run twice on the same printed text. The honest mental
model: `eval` is the machine code of MeTTa (`minimal-metta.md` documents it as
the first minimal instruction), and the interpreter itself is written in it.

**`collapse` ends the multiplicity, `superpose` starts it.** If a call returns
three results and you print it, you get three things on the line. If you
`collapse` it you get one tuple, which you can then `foldl-atom` over —
remembering from the fact sheet that `foldl-atom` folds the **children of a
tuple**, not a `::` list:

```metta
!(foldl-atom (1 2 3) 0 $acc $e (+ $acc $e))   ; 6
```

**Bind the tuple before you fold it.** `(foldl-atom (collapse (all-hours)) 0
$acc $e (+ $acc $e))` does not fold the hours. `foldl-atom`'s first position is an
`Atom`-typed parameter, and the spec says a parameter typed `Atom` is passed
*without evaluation* — that is exactly what `Atom` is for, "used for changing the
order of evaluation". So the folder receives the un-reduced call and folds over
its two children, `collapse` and `(all-hours)`; the real answer, verified on
0.2.10, is `(Error (+ 0 collapse) (BadArgType 2 Number (-> Atom Atom)) ...)`.
Write it through a `let` instead:

```metta
(= (total) (let $t (collapse (all-hours))
              (foldl-atom $t 0 $acc $e (+ $acc $e))))
```

**A tuple's order is not a fact you can rely on.** The same four hour facts print
`14 9 0 12` when queried and collapse into `(12 0 9 14)`. Verified on 0.2.10. So
assert the *count* or the *sum* of a result set, or sort it, and never assert a
tuple's element order unless you have checked that build.

So the pipeline for "search, then aggregate" is
`superpose`/rule-nondeterminism → `collapse` → `let` → `foldl-atom`/`map-atom`.
That is the shape of every candidate-scoring rule you will write at
[L4](./ch10-l4-uncertainty-and-agency.md).

**Argument position vs body position.** The trap I hit in L0 and everyone hits
here: what gets evaluated depends on where the sub-expression sits relative to a
rule's template. `(= (complexion-of $s) $s)` called as
`!(complexion-of (colour left))` — the argument is reduced before the rule body
runs unless the signature protects it with `Atom`. So a rule whose body is
`(match &self …)` and whose argument is itself a `match` call can look "broken"
when it is just being strict. Rule of thumb, and it is genuinely a rule: if the
argument should stay a program rather than a value, type it `Atom` or wrap the
body in `noeval`/`quote` territory ([L5](./ch11-l5-interop-and-export.md)).

**`!` inside an expression is not a thing.** Prefix `!` is a top-level token per
the grammar. A symbol can *begin* with `!` (`!name` is one valid symbol), which
means a stray `!` in a body can silently become part of a symbol name instead of
an evaluation request. Keep the two roles separate: top level for asking, inside
for data. Verified consequence: `!&` is documented upstream as "evaluate and
keep", but this build does not parse it — the line comes back as data.

**Silence and `()` are different failures.** A query with no results prints
nothing; a rule that returns `()` prints `()`; a rule whose body evaluates to
`Empty` prints nothing but for a different reason (and `Empty` inside a branch is
what makes that branch vanish — verified: `(= (f $x) (if (== $x 1) Empty (:ok $x)))`
answers `(:ok 2)` for `2` and prints nothing for `1`). When your rover step prints
nothing you need to know which of these happened. Two moves, both verified on
0.2.10:

- wrap the call in `!(collapse …)` and look at the tuple. A query with no results
  collapses to `()` — one result, the empty tuple — while a query with four
  results collapses to a four-element tuple. Count children, do not read them.
- assert "no results" with `!(assertEqualToResult (call) ())`. Putting `Empty`
  there instead is itself an error on this build:
  `(Error … Atom is not an ExpressionAtom)`.

That second one is the trick that has saved me more time than any other in this
book, and it is the only place where `Empty` and `()` are not both acceptable
answers.

## Exercises

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | `(= (bin) 0)` `(= (bin) 1)` then `!(bin)` | | `0 1` |
| 2 | `!(pair (bin) (bin))` with `(= (pair $a $b) (ab $a $b))` | | 4 pairs |
| 3 | `!(collapse (superpose (1 2 3)))` | | `(1 2 3)` |
| 4 | `!(eval (+ 1 (* 2 3)))` | | one step, not 7 |
| 5 | `!(foldl-atom (1 2 3) 0 $acc $e (+ $acc $e))` | | `6` |
| 6 | `!(foldl-atom (:: 1 (:: 2 ())) 0 $acc $e (+ $acc $e))` | | wrong shape, see fact sheet |
| 7 | `!(map-atom (1 2 3) $x (* $x $x))` | | `(1 4 9)` |
| 8 | `(: hold (-> Atom Atom))` then `!(hold (+ 1 2))` | | unevaluated |

Tasks:

1. Enumerate the truth table of `and` over `(superpose (True False))` in both
   argument slots. Count the results, then `collapse` them into one tuple.
2. Write `(= (pick $list) …)` that nondeterministically returns one element of a
   `::` list, then use `collapse` to get them all as a tuple, bind that tuple with
   `let`, and `foldl-atom` to sum it. (No `sum-atom` in this build; write `+`
   folding yourself.)
3. Take your `map.metta` from [Unit 2](./ch03-00-facts-spaces-queries.md) and
   write `!(reachable $a $b)` so that it returns *all* rooms reachable in ≤2
   hops, using two rules rather than a guard. Explain when duplicating results
   is what you wanted and when it wasn't.
4. Predict-then-run, and this time be exact: for each of
   `!(eval (+ 1 2))`, `!(eval (eval (+ 1 2)))`, `!(+ 1 2)` write down how many
   result items you expect before running. Then explain any miss using the
   "already evaluated" short-circuit.
5. Re-answer the [L0](./ch01-l0-imitation.md) symmetry exercise as a
   `collapse`ed tuple so the duplicated `(Cy Dee)` becomes visible data you can
   count rather than two prints you have to notice.

Recall cards:

- `superpose` ____ nondeterminism; `collapse` ____ it.
- 2 results × 2 results = ? results.
- What does `eval` do, and why doesn't a second `eval` always advance?
- Three ways to print nothing, and the one wrapper that distinguishes them.
- Which type keeps an argument unevaluated?

## Ship it

Friday: `nondet.metta` — truth table, `pick`, the count assertions, and a
commented `; TRAP` block showing the `::`-vs-tuple `foldl-atom` mistake you made
this week. If the result counts match your written predictions for all eight
table rows, you have this level. Next:
[Unit 5 — types and errors](./ch06-00-types-and-errors.md), where the type
system shows up as the thing that decides evaluation order rather than as
decoration, and where you learn to read `BadArgType` backwards to the spec line
that produced it.
