# L1 · Unit 2 — Facts, spaces and queries

Store, query. That is two of the five verbs and most of what a Knowledge Graph
is. By the end of this unit you will know the difference between a fact and a
rule, why `match &self` cannot see your rules, and how to keep a second space
that you can inspect — the mechanism the rover's percept buffer and the later
AtomSpace work all sit on.

Friday artifact: a `map.metta` file holding a room-and-object graph of your own
flat, plus five queries against it whose outputs you have written down.

## Syntax

A fact is a stored expression. The head symbol names the relation; the children
are the arguments. No declaration, no schema, no semicolons:

```metta
(parent Ada Bea)
(parent Bea Cy)
(child Dee Bea)
(female Cy)
```

A query is the same shape with a variable in it, `!`-prefixed, pointed at a
space:

```metta
!(match &self (parent Ada $child) $child)   ; Bea
!(match &self (parent $p $c) (, $p $c))      ; pairs, one per fact
```

`&self` means "the space of the module currently executing" — for a script, the
top space where your `!`-less atoms went. The `,` in the second query is the
conjunction form: it puts *several bindings* into one result atom. It is only
meaningful inside a `match` pattern or template; used as a rule body it just
builds a data atom, which is a bug I will describe once and you will then meet
forever.

A second space is created, filled, read and emptied with four grounded calls:

```metta
!(bind! &kb (new-space))     ; ()
!(add-atom &kb (sensor left black))      ; ()
!(get-atoms &kb)             ; lists the atoms
!(match &kb (sensor left $lane) $lane)   ; black
!(remove-atom &kb (sensor left black))   ; ()
```

Note what those calls print. `bind!`, `add-atom` and `remove-atom` all answer
`()` — the unit-ish empty atom, "I did it, there is no value". `get-atoms` and
`match` answer data. Learning to read `()` as success rather than as failure
matters, because at [L4](./ch10-l4-uncertainty-and-agency.md) you will be
mutating spaces from inside rules and `()` is all you get back.

## Semantics

**A space is a set of atoms and nothing else.** No ordering, no indexes you
must maintain, no tables. `match` is a search over that set using the
`match_atoms` algorithm from [Unit 1](./ch02-00-atoms-and-expressions.md):
pattern and atom must be the same shape, variable-free parts must be equal.
That is the whole of it. It is why adding a fact is idempotent-ish and why
duplicates are possible.

**`match` sees atoms, not rules.** This is the trap with teeth. A definition

```metta
(= (aunt-of $x $y) ($x aunt-of $y))
```

is stored as an atom too — but it is an atom whose head is `=`, not a fact whose
head is `aunt-of`. So:

```metta
!(match &self (Cy aunt-of Bea) $x)     ; prints nothing
!(aunt-of Cy Bea)                      ; prints (Cy aunt-of Bea)
```

The first asks the space "is this stored?" and the honest answer is no. The
second asks the interpreter to evaluate the call, and evaluation follows the
spec's `metta_call` step: for a non-grounded head it runs
`query(space, (= <atom> $X))` — literally searching the space for an `=` rule
whose left side matches your call, then evaluating the right side. Facts and
rules live in the same space and are consulted by two different mechanisms.
Derived relations get **called**; stored facts get **matched**. When you forget
which one you are writing, `match` answers silence and no error appears.

**Two sides of a relation are two facts, unless you make them one rule.** The
`aunt-of` example above is why the L0 symmetry exercise prints
`(Cy Dee) (Cy Dee)`. From the spec: the query in `metta_call` collects *every*
binding that matches, and all same-head rules are tried. There is no
first-match-wins, no override, no "more specific rule wins". If two rules both
match, you get both results. That is not a defect — it is what makes
nondeterministic programming at [L3](./ch09-l3-modules-and-search.md) possible —
but it will surprise you the first time you "fix" a rule by adding a stricter
one and end up with duplicated output.

**Conjunction lives in patterns, not bodies.** To ask "who is Cy's sibling's
child?" you need two facts matched in one query. The `,` inside a `match`
pattern does exactly that:

```metta
(= (aunt? $x $y)
    (match &self (, (sibling $x $p) (child $p $y)) True))
!(aunt? Cy Bea)        ; True
```

Read the body as: in this space, find `$p` such that both `(sibling Cy $p)` and
`($p child Bea)`… no — such that both `(sibling $x $p)` and `(child $p $y)` are
stored, then answer `True`. Put the `(, …)` where a *pattern* goes and it means
AND. Put it where a *result* goes and you get a data atom nobody will match.
I made that mistake in the first draft of the L0 listing; the symptom was an
empty answer to a question whose facts were obviously present.

**Grounded atoms match by their own rules.** Numbers and strings are grounded,
so `match` against them calls the grounded matcher. That is why
`!(match &self (n $x) $x)` over `(n 3)` and `(n 3.0)` can behave differently
from symbols, and why `min-atom` and `max-atom` answer `1.0` where you expected
`1`. Custom matching is the mechanism the rover's distance and battery
comparisons will lean on.

## Exercises

Start from the L0 graph in `listings/l0-02-toy-graph.metta`. Predict, then run,
then reconcile in writing.

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | `(parent Ada Bea)` then `!(match &self (parent Ada $c) $c)` | | `Bea` |
| 2 | `!(match &self (parent Bea $c) $c)` | | `Cy` |
| 3 | `!(match &self (parent Ada $c) (parent $c $g))` | | one line: `(Bea Cy)` |
| 4 | `!(bind! &kb (new-space))` | | `()` |
| 5 | `!(add-atom &kb (room kitchen))` | | `()` |
| 6 | `!(get-atoms &kb)` | | `(room kitchen)` |
| 7 | `!(match &self (Ada parent-of $x) $x)` (fact says `parent`) | | nothing |
| 8 | `!(match &self (, (parent Ada $c) (parent $c $g)) (, $c $g))` | | your call |

Then:

1. Write `map.metta`: at least ten `(at <object> <room>)` facts and three
   `(connects <room> <room>)` facts. Query every object in a room, then every
   room reachable in one hop, then — with `,` — every object that is in a room
   connected to a named room.
2. Add a rule `(= (reachable $a $b) …)` for two-hop connectivity and prove to
   yourself it is *called*, not matched: run both
   `!(match &self (reachable kitchen $r) $r)` and `!(reachable kitchen $r)`.
   Write one sentence explaining the difference in terms of `metta_call`.
3. Duplicate a rule deliberately: give `aunt-of` a second same-head rule that
   adds a `(female $x)` condition, run `!(aunt-of Cy Bea)` and count the results.
   Now make the first rule stricter instead. Explain what changed and why.
4. Move your whole `map.metta` graph into a named space `&world` using only
   `add-atom`, then write three queries against `&world`. Explain why
   `!(get-atoms &self)` printed nothing while `!(get-atoms &world)` printed your
   atoms. (Verified fact: `get-atoms &self` prints nothing on this build; that
   is a build limitation, not your bug.)
5. Self-test what you wrote, in the file, so it fails loudly next week:
   ```metta
   !(assertEqualToResult (match &self (parent Ada $c) $c) (Bea))
   !(assertEqual (aunt? Cy Bea) True)
   ```
   `()` after each means your claim about your own graph is true.

Recall cards:

- Facts are matched, rules are ____. Why does `match &self (Cy aunt-of Bea)`
  print nothing when `!(aunt-of Cy Bea)` prints a pair?
- Where must `(, …)` appear to mean AND? What does it mean in a rule body?
- What prints for a query with no results, and for `add-atom`?
- Two same-head rules: how many results?
- Name the three calls that answer `()`.

## Ship it

Friday: `map.metta` with ten facts, three connects, five queries, the reachable
rule demonstrated as a call, and the two `assert*` lines at the bottom passing.
Then hand-write the "facts vs rules" paragraph on paper — if you can write it
without looking, you own this unit. Next:
[Unit 3 — functions and pattern matching](./ch04-00-functions-and-pattern-matching.md),
where `(= …)` becomes the real workhorse and the guarded-recursion trap arrives.
