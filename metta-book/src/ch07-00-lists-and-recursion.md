# L2 · Unit 1 — Lists, tuples and recursion

L1 gave you one atom in, one atom out. Real rover data is a *sequence* — a strip
of eight distance readings, a path of room names, a list of candidate actions —
and MeTTa has two completely different sequence kinds that beginners constantly
confuse. This unit is the data model: cons lists, tuples, the recursion you must
write yourself, and the stdlib functions that lie to you.

Friday artifact: `streams.metta` — a rolling sensor buffer as a `::` list with
`my-map`, `my-filter`, `my-fold`, `take`, `zip`, and a `median`-ish statistic
built only from functions you wrote.

## Syntax

There is no list literal. A cons list is built from two symbols and the empty
list `()`:

```metta
(:: 12 (:: 30 (:: 55 ())))
(= (readings) (:: 12 (:: 30 (:: 55 ()))))
```

The head `::` is a normal symbol with a normal arity-2 shape, so `(:: $h $t)` is
an ordinary pattern, and pattern matching on it is how you destructure:

```metta
(= (mylen ()) 0)
(= (mylen (:: $h $t)) (+ 1 (mylen $t)))
```

A **tuple** is any parenthesised expression with more than two children, or
really any expression used positionally: `(1 2 3)`, `(sensor left black)`.
Tuples are not lists. `(:: 1 (:: 2 ()))` is a list of two; `(1 2)` is a
two-child expression that will not match `(:: $h $t)`.

Tuple-level helpers exist and are the source of the confusion, because their
names say "atom list" while their behaviour says "children of one expression":

```metta
!(map-atom (1 2 3) $x (* $x $x))                 ; (1 4 9)
!(foldl-atom (1 2 3) 0 $acc $e (+ $acc $e))      ; 6
```

`foldl-atom` takes *five* arguments: the tuple, the initial accumulator, the
accumulator variable, the element variable, and the body template. Passing a `::`
list as the first argument does not fold the list; it iterates the top-level
children, which for `(:: 1 (:: 2 ()))` is `::`, `1`, and the nested tail. I wrote
that wrong first and got `(+ (:: 2 (:: 3 ())) (+ 1 (+ :: 0)))` — nonsense output
from a nonsense domain, and the only honest fix is to know the domain.

The typed list, if you want the stdlib's `List` to mean something:

```metta
(: List (-> $a Type))
(: Cons (-> $a (List $a) (List $a)))
(: Nil (List $a))
```

Note this is the spec's mechanism from [Unit 5](./ch06-00-types-and-errors.md) —
type as data — applied to a container. `Cons`/`Nil` are names you choose to
match; nothing in the interpreter insists on `::`.

State, for the "rolling buffer" case where a pure recursion is the wrong tool:

```metta
!(bind! &buf (new-state ()))
!(change-state! &buf (:: 12 (get-state &buf)))
!(get-state &buf)
```

`change-state!` returns `()`; pairing it with `!(nop …)` is how the stdlib tests
sequence it. A wrong-typed update is a type error, not a silent corruption.

## Semantics

**Recursion is the only iteration, and it is a rule pair.** There is no loop
form. `mylen`, `my-map`, `my-filter` are each two rules — one on `()`, one on
`(:: $h $t)` — and they are safe *because the templates are structurally
disjoint*: `()` cannot unify with `(:: $h $t)`. Contrast with the arithmetic case
from [Unit 3](./ch04-00-functions-and-pattern-matching.md), where `(fact 0)`
unified with both `(fact 0)` and `(fact $n)`. Two rules are fine when the shapes
exclude each other; guard when they don't.

**`filter-atom` does not work in this build.** It is declared in
`stdlib.metta`, and every shape I tried returned a `NoReturn` error — the
result the spec reserves for the minimal interpreter's `function`/`return`
mechanism, leaking out because the function never produces one. So: write
`my-filter` yourself. Three benefits: it always works, it teaches the recursion
you need anyway, and it is the first function you'll want to reuse at
[L4](./ch10-l4-uncertainty-and-agency.md) when scoring candidates.

**Other arithmetic holes on 0.2.10.** `!=`, `sqrt`, `abs`, `sum-atom` and
`pr::println` are absent; `min-atom`/`max-atom` answer floats (`1.0`); `/`
between integers is integer division, so `(/ 7 2)` is `3` and `(- 1 (/ 1 2))` is
`1`. Two consequences: any "average of readings" must be written as
`(foldl-atom …)`-over-a-tuple or your own recursive sum, and comparisons that
look like off-by-one bugs are usually integer truncation. For the rover's
`(= (hours day-342) 14)` log, average-per-week arithmetic is integer division
unless you make the operands floats deliberately.

**Lists are data, so they can be *stated* and *queried*.** `(parent Ada Bea)`
and `(:: 1 ())` are both atoms. That means a `::` list can come out of
`match &self (trail $t) $t`, which is how you keep a path in a named space
instead of threading it through every call. It also means a partially-instantiated
list (with a `$var` still in the tail) is a legal stored atom, and — see the
bare-variable trap in [Unit 1](./ch02-00-atoms-and-expressions.md) — a loose
variable in a space can match things you did not intend.

**Nondeterminism composes over lists.** `[Unit 4](./ch05-00-evaluation-and-results.md)`'s
multiplication rule applies inside recursion: a `my-map` whose template calls a
nondeterministic function returns a result per combination, not a list per
element. When you want the list, `collapse` first.

**`assertEqualToResult` is the list-aware test.** `assertEqual` compares single
values; `assertEqualToResult` compares the *whole result set*, so it is the
honest way to pin `my-map` and `my-filter` outputs:

```metta
!(assertEqualToResult (my-filter odd? (1 3 4)) (1 3))
```

Use it at the bottom of every file from now on. The verify script can only catch
what a file asserts about itself; a chapter claim that is never asserted is a
chapter claim that silently rots, which is exactly how this book got shallow.

## Exercises

Predict, run, reconcile. Write the reconciliation *in the file* as comments.

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | `!(mylen (:: 1 (:: 2 (:: 3 ()))))` | | `3` |
| 2 | `!(mymap triple (:: 1 (:: 2 (:: 3 ()))))` | | `(:: 3 (:: 6 (:: 9 ())))` |
| 3 | `!(map-atom (1 2 3) $x (* $x $x))` | | `(1 4 9)` |
| 4 | `!(foldl-atom (1 2 3) 0 $acc $e (+ $acc $e))` | | `6` |
| 5 | `!(foldl-atom (:: 1 (:: 2 ())) 0 $acc $e (+ $acc $e))` | | garbage — wrong domain |
| 6 | `!(sum-list (:: 1 (:: 2 (:: 3 ()))))` (yours) | | `6` |
| 7 | `!(/ 7 2)` | | `3` |
| 8 | `!(min-atom 1 2)` | | `1.0` |
| 9 | `!(take 2 (:: a (:: b (:: c ()))))` (yours) | | `(:: a (:: b ()))` |

Tasks:

1. Write `mylen`, `my-map`, `my-filter`, `my-fold`, `append-list`, `reverse-list`
   and `take` over `::` lists. Guard every base case on `()`.
2. Build the rolling buffer: `&buf` as state, a `(record $r)` rule that
   `change-state!`s a new reading in, and a `(window $n)` that returns the last
   `$n` readings. Prove with `assertEqualToResult` that recording three readings
   gives you those three in order.
3. Statistics without the stdlib: recursive `sum-list`, `count`, and `mean`
   returning a float sum over an integer count. Then `median` on a sorted list.
   Write the `(!=)`-free and `abs`-free version — you will need `(< a b)` and
   `(is-greater-than-or-equal-to)`-style forms, or your own `my-not-eq`.
4. Now the tuple path: read `&buf` into a tuple and use `foldl-atom` once.
   Explain out loud, in writing, which of tasks 2 and 3 is the idiomatic MeTTa
   solution and why you would still pick the other for the rover.
5. Port the L0 `mymap` exercise: same list, but make the mapped function
   nondeterministic (`(= (maybe-noisy $x) $x)` and `(= (maybe-noisy $x) (+ $x 1))`).
   Count the results before running. Then `collapse` to make the noise visible.
6. Re-do [Unit 2](./ch03-00-facts-spaces-queries.md)'s `map.metta` reachability
   so the path is *accumulated* as a `::` list — `(reachable-via $from $to $path)`
   — and print one two-hop path. This is the first time MeTTa is doing something
   a graph library would otherwise do for you.

Recall cards:

- Two sequence kinds in MeTTa, and the one `foldl-atom` accepts.
- `foldl-atom`'s five arguments, in order.
- Which stdlib function is declared but broken, and what error does it leak?
- Why are `()` / `(:: $h $t)` rules safe when `(fact 0)` / `(fact $n)` were not?
- Three arithmetic names absent on 0.2.10, and what `/` does to `7 2`.

## Ship it

Friday: `streams.metta` — the seven list functions, the state buffer, the
statistics block, all asserted with `assertEqual`/`assertEqualToResult`, and the
`foldl-atom` domain mistake written out as a `; TRAP` comment so next month's you
doesn't repeat it. Next:
[Unit 2 — build a small program](./ch08-00-build-a-small-program.md), where
spaces, state, lists and rules combine into something that answers questions
about a whole day of driving.
