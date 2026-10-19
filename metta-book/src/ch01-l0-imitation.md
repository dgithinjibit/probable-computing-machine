# L0 — Imitation

You are not here to understand MeTTa yet. You are here to get your hands on it,
the way a Kumon sheet or a Suzuki piece works: imitate something that already
sounds right, and let the theory arrive afterwards, already familiar. Six cards,
typed cold, run, compared. No explanation is required to finish this unit, and
if you find yourself wanting one, that want is the point — it is what L1 runs on.

Two rules for the unit. Type the programs; do not open the listing and copy it.
And run after every card, not at the end, because a MeTTa file fails silently
more often than loudly.

## The six cards

The complete set is
[`l0-01-drills.metta`](../listings/l0-01-drills.metta) and
[`l0-02-toy-graph.metta`](../listings/l0-02-toy-graph.metta).

Card 1 is a rule and a call.

```metta
(= (double $x) (* 2 $x))
!(double 4)
```

Card 2 is facts and one query over them.

```metta
(parent Ada Bea)
(parent Bea Cy)
!(match &self (parent Ada $child) $child)
```

Card 3 is recursion that stops. Read the comment in the listing before you
write this one; it is the only card with a trap in it.

```metta
(= (factorial $n) (if (> $n 0) (* $n (factorial (- $n 1))) 1))
!(factorial 5)
!(factorial 0)
```

Card 4 is a list and a `map` over it, with the two rules a list function always
needs: the empty shape and the `head :: tail` shape.

```metta
(= (triple $x) (* 3 $x))
(= (mymap $f ()) ())
(= (mymap $f (:: $head $tail)) (:: ($f $head) (mymap $f $tail)))
!(mymap triple (:: 1 (:: 2 (:: 3 ()))))
```

Card 5 is a second AtomSpace, written into and read back.

```metta
!(bind! &scratch (new-space))
!(add-atom &scratch (sensor left black))
!(match &scratch (sensor left $lane) $lane)
```

Card 6 is the kinship graph that most published MeTTa material starts from, in
your own handwriting.

```metta
(child Dee Bea)
(sibling Cy Dee)
(female Cy)
(= (aunt? $x $y)
   (match &self (, (sibling $x $p) (child $p $y)) True))
!(aunt? Cy Bea)
```

## Predict, then run

Write the answer in the right column before you run each card. Then run the
whole file once and compare. These are the outputs this machine gives.

| Card | Query | Your prediction | Actual |
|---|---|---|---|
| 1 | `!(double 4)` | | `8` |
| 2 | `!(match &self (parent Ada $child) $child)` | | `Bea` |
| 3 | `!(factorial 5)` | | `120` |
| 3 | `!(factorial 0)` | | `1` |
| 4 | `!(mymap triple (:: 1 (:: 2 (:: 3 ()))))` | | `(:: 3 (:: 6 (:: 9 ())))` |
| 5 | `!(bind! &scratch (new-space))` | | `()` |
| 5 | `!(add-atom &scratch (sensor left black))` | | `()` |
| 5 | `!(match &scratch (sensor left $lane) $lane)` | | `black` |
| 6 | `!(aunt? Cy Bea)` | | `True` |
| checks | `!(assertEqual (double 4) 8)` | | `()` |

Two of those answers will feel wrong when you predict them. `bind!` and
`add-atom` both print `()`, because they do things rather than answer things —
the empty pair of parens is the unit atom, and it is also what a passing
assertion prints. Reading `()` correctly is a skill in this language: one line
means "done, nothing to show", while *no line at all* means "nothing matched",
which are opposite diagnoses.

## Semantics you absorbed without being told

After six cards you already know things a lecture would have to explain.

A file is a sequence of top-level atoms, and the `!` in front of one decides
whether it is stored or run. Cards 2 and 6 store facts without `!` and then use
`&self` to mean "the space this file has been building".

`$name` is a variable, and the same `$name` appearing twice in one rule means
the same value twice. That is what makes `(parent Ada $child)` a query and not
a template.

Patterns are matched against stored atoms, in the order the interpreter finds
them, and one matching atom gives one result.

## The gate

Close the book, delete your typed file, and write all six cards from memory in
one file. Run it. It passes when the output matches the table above exactly,
including the four `()` lines. If a card costs you more than two attempts, note
which one and move on; L1 will meet it again on purpose.

Then do the one exercise that is not a drill. Sibling is stored in one
direction only: `(sibling Cy Dee)` is a fact and `(sibling Dee Cy)` is not.

```metta
(sibling Cy Dee)
!(match &self (sibling Dee $other) $other)   ; no line prints
```

Write a rule `sibling-of` so that `!(sibling-of Dee $other)` answers `Cy`, even
though no such fact is stored. Two things make this the right first real
exercise. The derived relation must be *called*, because `match` searches
stored atoms and a rule head is not one of them — so `!(match &self (sibling-of
Dee $o) $o)` still prints nothing. And once your rule works, add a second rule
with the same head that answers the other direction, then call it with both
arguments free:

```metta
(sibling Cy Dee)
(= (sibling2 $a $b) (match &self (, (sibling $a $b)) ($a $b)))
(= (sibling2 $a $b) (match &self (, (sibling $b $a)) ($b $a)))
!(sibling2 $x $y)
```

This machine prints `(Cy Dee) (Cy Dee)`. Same answer twice, because both rules
have the same head and MeTTa explores every rule that matches rather than taking
the first or the most specific. Say in one sentence what that means for
`(aunt? Cy Bea)` in card 6 once you add a stricter aunt rule next to it.

## Ship it

Friday, one clip or one commit: the file running, output visible. This is the
smallest possible version of the habit your two-year plan depends on.

Next: [L1 Unit 1 — grammar and atoms](./ch02-00-atoms-and-expressions.md), where the syntax, the
semantics and the traps get names.
