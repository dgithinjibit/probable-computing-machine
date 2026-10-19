# L1 · Unit 3 — Functions and pattern matching

A function in MeTTa is not a block of code with a name. It is a *rule* relating a
call shape to a body shape, stored in the same space as your facts, and it is
found by matching. Once that model replaces the "function = code" model, the two
bug classes of this level — silent non-termination and duplicated results — stop
being mysteries and become things you chose.

Friday artifact: `arith.metta` with guarded `factorial`, `fib` as a pair
accumulator, and a `safe-div` that returns an `Error` atom instead of hanging.

## Syntax

The definition form, from the spec's "Function expression" section:

```
(= <call recognition template> <body template>)
```

```metta
(= (double $x) (* 2 $x))
(= (sign $n) (if (< $n 0) -1 (if (> $n 0) 1 0)))
(= (mylen ()) 0)
(= (mylen (:: $h $t)) (+ 1 (mylen $t)))
```

Patterns nest arbitrarily, and a variable used twice in one pattern is the *same*
variable — the spec's `merge_bindings` refuses a binding that contradicts an
existing one:

```metta
(= (pair2 $a $a) both-same)      ; (pair2 3 3) → both-same
(= (pair2 $a $b) different)      ; (pair2 3 4) → different …and also both-same? see Semantics
```

`if` is not a keyword. It is a stdlib function defined exactly the way the spec
illustrates it:

```metta
(= (if True $then $else) $then)
(= (if False $then $else) $else)
```

So `if` is ordinary pattern matching, which means its condition must *evaluate to
the atom* `True` or `False`. `if` does not call a truthiness test on your behalf.

`let` binds a name for the rest of one template:

```metta
(= (area $r) (let $sqr (* $r $r) (* 3 $sqr)))
```

Type signatures are separate atoms, not part of the definition:

```metta
(: double (-> Number Number))
(= (double $x) (* 2 $x))
```

## Semantics

**Calling is querying.** The spec's `metta_call` says it plainly: if the head
isn't an executable grounded atom, run `query(space, (= $atom $X))` — search the
space for any `=` atom whose left side unifies with your call, bind `$X` to the
matching right side, and evaluate that. Three consequences you must internalise:

1. **All matching rules are used.** Two rules whose templates both match your
   call give two results. There is no ordering, no shadowing, no override.
   `(pair2 3 3)` in the snippet above prints `both-same different` — the second
   rule's `$a $b` unify with `3` and `3` happily, because two distinct pattern
   variables may take equal values. To specialize, you must *guard*, not add.
2. **No rule means no reduction.** `!(undefined-fn 7)` returns the call
   unchanged (the spec: `else: return [($atom, $bindings)]`). That is
   `NotReducible` behaviour and it prints the call back at you, which beginners
   read as "it returned a weird string". It is your call, unevaluated.
3. **Rules are data.** `(= (double $x) (* 2 $x))` without `!` is stored as an
   atom. `match` can see it — as an `=`-headed atom, never as a `double`-headed
   fact. This is [Unit 2](./ch03-00-facts-spaces-queries.md)'s
   called-vs-matched rule again, and it is the foundation of
   [L3](./ch09-l3-modules-and-search.md)'s "programs as data" move.

**The base case does not stop recursion by itself.** Here is the listing that
hung my interpreter for twenty-five seconds and then stalled the whole verify
run:

```metta
; HANGS — do not un-comment
;(= (fact 0) 1)
;(= (fact $n) (* $n (fact (- $n 1))))
```

Read it as the interpreter does. `(fact 0)` queries for `=` rules matching
`(fact 0)`. Rule 1 matches → `1`. Rule 2 *also* matches, because `$n` unifies
with `0` → `(* 0 (fact (- 0 1)))` → `(fact -1)` → rule 2 again → `(fact -2)` →
… The base case does not suppress the recursive case; both are alive. This is
consequence 1 with teeth. The working shape is one rule that decides inside:

```metta
(= (factorial $n) (if (> $n 0) (* $n (factorial (- $n 1))) 1))
!(factorial 5)     ; 120
!(factorial 0)     ; 1
```

Guarded recursion is the idiom. Split-rule recursion is only safe when the
templates are provably disjoint — e.g. matching on structure (`()` vs
`(:: $h $t)`), which is why `mylen` above is fine: `()` and `(:: $h $t)` cannot
both unify with the same atom.

**Argument evaluation happens before the rule body, unless the type says
otherwise.** The metatypes `Atom` and `Expression` change evaluation order
(`Atom` means "don't evaluate this"). That is what makes the following two rules
behave differently, and it is the single most under-appreciated paragraph of the
spec:

```metta
(= (always-42 $x) 42)
!(always-42 (double 3))      ; 42, and the argument was reduced on the way in
```

For the rover: a rule like `(= (colour-of $sensor) (match &self …))` in
argument position will try to evaluate the inner `match` *before* substituting,
which is why `complexion-of` needed an explicit shape in L0. The full treatment
is [Unit 4](./ch05-00-evaluation-and-results.md).

**`Empty` is not `()`.** From the spec's "Special function results": `Empty`
means "no result at all" — a query that produced nothing; `()` is an atom that
exists and can be returned and printed. A rule body that evaluates to no results
disappears from the output; one that evaluates to `()` prints `()`. When you
want "definitely nothing", say `Empty`; when you want "done, no value", say `()`.

## Exercises

Predict, then run, then write the reconciliation. One is deliberately dangerous
— do it last, in its own file, with the runner's 25-second timeout, because it
hangs.

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | `(= (sq $x) (* $x $x))` then `!(sq 6)` | | `36` |
| 2 | `!(sq (+ 1 2))` | | `9` — argument reduced first |
| 3 | the two `pair2` rules, then `!(pair2 3 3)` | | `both-same different` |
| 4 | `(= (g $x) small)` `(= (g 5) big)`, then `!(g 5)` | | two results |
| 5 | `!(undefined-fn 7)` | | the call echoed |
| 6 | `!(factorial 5)` (guarded) | | `120` |
| 7 | `!(factorial 0)` | | `1` |
| 8 | the un-guarded `fact` pair above | | **hang** |

Tasks:

1. Write `sign`, `clamp` and `safe-div` guarded with `if`. `safe-div` must
   return `(Error (safe-div $a 0) DivisionByZero)` for a zero divisor — the spec
   sanctions `Error` as a result constructor, and building your own error atoms
   is what the rover's fault handling will do.
2. Write `mylen` and `myreverse` over `::` lists. Then write `mylen` a second
   way with a structural base case that *could* hang, and explain in three
   sentences why yours doesn't.
3. Take the L0 `aunt-of` and rewrite it as a guarded single rule, then prove the
   two-rule version duplicates. Compare result counts out loud.
4. Fib the accumulator way, one rule only:
   ```metta
   (= (fib $n) (fib-loop $n 0 1))
   (= (fib-loop 0 $a $b) $a)
   (= (fib-loop $n $a $b) (fib-loop (- $n 1) $b (+ $a $b)))
   ```
   Explain why `fib-loop`'s three structural rules are safe when `fact`'s two
   were not. Then run `!(fib 10)` → `55`.
5. Add `(: factorial (-> Number Number))` and call `!(factorial "five")`. Read
   the `BadArgType` message aloud and map each of its three numbers/names to the
   spec's `check_argument_type`. This is [Unit 5](./ch06-00-types-and-errors.md).

Recall cards:

- What does the interpreter do for a call with no matching rule?
- Two matching rules: how many results? What is the fix — add or guard?
- Why does `(= (fact 0) 1)` fail to stop recursion?
- Which is a real atom, `Empty` or `()`?
- Write the guarded factorial from memory.

## Ship it

Friday: `arith.metta` with `factorial`, `fib` (accumulator), `sign`, `clamp`,
`safe-div`, and at least four `assertEqual` lines covering them — including one
asserting your own `Error` atom. Plus the handwritten "calling is querying"
sentence. Next:
[Unit 4 — evaluation and results](./ch05-00-evaluation-and-results.md), where
multiple results, `collapse`, `superpose` and one-step `eval` turn the
nondeterminism that bit you here into a tool you point deliberately.
