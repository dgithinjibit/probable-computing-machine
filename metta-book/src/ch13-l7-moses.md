# L7 — Program search: the MOSES shape

L6 ended with a rover that could defend its own numbers. L7 asks the other question:
given a pile of input/output pairs, can you *search for the program* that produces
them, using MeTTa as the language the candidates are written in and the language the
search is written in? That is the question MOSES answers, and it is the reason
`trueagi-io/hyperon-moses` exists — a Rust port of the c++ Analog Semantic MOSES with
MeTTa as the program representation.

Friday artifact: `listings/l7-01-moses.metta`, which runs green in the verifier, plus
exercises 36–38. This is the shape of MOSES, not a port of it. The distinction is not
modesty, it is licence and scope: `hyperon-moses` is **AGPL-3.0**, so you read its
source and write your own; and its real machinery — estimation-of-distribution
modelling inside a deme, Pareto plateau handling, a C++-backed evaluator — is
larger than one chapter. What you are building here is the part the port guide says
matters conceptually, in a form you can hold.

The guide names three tricks that made AS-MOSES competitive. Everything in this
chapter is in service of one of them.

1. **Reduce every candidate to normal form.** Two syntactically different programs
   with the same truth table are one candidate after normalization, which both
   shrinks the population and makes the fitness landscape "less deceptive".
2. **Locally vectorize the search space.** Search happens in a *deme* — a
   neighbourhood around one exemplar — because the statistics of one deme
   ("wisdom", in the guide's word) do not transfer to another.
3. **Vectorize the fitness.** Keep the per-data-point components, compare programs
   on the vector plus size, and expect the scalar to lie.

## Syntax

Candidates are **data**, not live code. Tags stop the interpreter from reducing a
program while you are still searching over it:

```metta
(= (eval-c (const-0) $a $b) 0)
(= (eval-c (var-x) $a $b) $a)
(= (eval-c (c-and $p $q) $a $b)
    (if (== (eval-c $p $a $b) 1)
        (if (== (eval-c $q $a $b) 1) 1 0)
        0))
```

The guide gets the same effect by renaming `and` to a unicode bold `𝐚𝐧𝐝` so MeTTa's
built-in cannot fire, and by replacing program variables with DeBruijn indices so
unification cannot accidentally bind two candidates together. Tagged constructors are
the boring version of the same trick and they are what runs in this chapter. Note too
that a leaf here is the *expression* `(var-x)`, not the symbol `var-x`: `(cand
(var-x))` stores an argument that is a one-element expression, and every rule,
pattern and assertion has to agree about that.

Truth-table rows are **facts**, so `match` can enumerate them:

```metta
(target 0 0 0)
(target 0 1 0)
(target 1 0 0)
(target 1 1 1)
```

Normal form: **one rule per operator head**, with the shape tests nested inside.

```metta
(= (nf (var-x)) (var-x))                     ; every leaf needs its rule
(= (neg-pair $x $y) (case $x (((c-not $r) (== $r $y)) ($other False))))
(= (nf (c-and $p $q))
    (let $a (nf $p)
        (let $b (nf $q)
            (if (== $a $b) $a
                (if (neg-pair $a $b) (const-0)
                    (if (neg-pair $b $a) (const-0)
                        (if (>= (rank $a) (rank $b)) (c-and $b $a)
                            (c-and $a $b))))))))
(= (nf (c-not $p)) (case (nf $p) (((c-not $r) (nf $r)) ($q (c-not $q)))))
```

`case` is the construct that makes this shape possible. Its clauses are grouped as
**one tuple** of `(pattern result)` pairs — `(case $x ((pat1 res1) (pat2 res2)))` —
and it is *first-match*, which is why it is safe where a second rule with the same
head would not be. Verified on this runtime, and worth memorising:

```metta
!(case (c-and 1 2) (((c-and $a $b) (plus $a $b)) ($o fallback)))   ; (plus 1 2)
!(case (zzz) (((c-and $a $b) (plus $a $b))))                        ; ()
!(case (c-and 1 2) ((c-and $a $b) (plus $a $b)))                   ; IncorrectNumberOfArguments
```

Mutation is a relation with **deliberately overlapping heads**:

```metta
(= (grow (c-and $p $q)) (c-not (c-and $p $q)))
(= (grow (c-and $p $q)) (c-and (c-not $p) $q))
(= (grow (c-and $p $q)) (c-or $p $q))
(= (grow $p) (c-and $p (var-x)))
(= (grow $p) (c-and $p (var-y)))
```

`(grow (c-and (var-x) (var-y)))` returns five neighbours: three from the structural
rules and two from the extension rules, because `$p` catches everything. That is
enumeration — the same productive head overlap [L3](./ch09-l3-modules-and-search.md)
uses to list candidates. Crossover needs subterms, so `subs` is built the same way,
while `replace` keeps one head and branches inside it with `case`:

```metta
(= (subs $p) $p)
(= (subs (c-and $p $q)) (subs $p))
(= (subs (c-and $p $q)) (subs $q))
(= (replace $p $old $new)
    (if (== $p $old) $new
        (case $p
          (((c-not $r) (c-not (replace $r $old $new)))
           ((c-and $a $b) (c-and (replace $a $old $new) (replace $b $old $new)))
           ((c-or $a $b) (c-or (replace $a $old $new) (replace $b $old $new)))
           ($o $p)))))
(= (cross $a $b) (let $s (subs $a) (let $t (subs $b) (nf (replace $a $s $t)))))
```

Deduplication needs a space, because a search that cannot remember what it has
already seen re-scores twins forever:

```metta
!(bind! &seen (new-space))
(= (seen-count $p)
    (let $t (collapse (match &seen (s $p) 1)) (foldl-atom $t 0 $a $e (+ $a $e))))
(= (note! $p) (if (== (seen-count $p) 0) (add-atom &seen (s $p)) Empty))
```

Fitness, per row, with `Empty` as the filter — see
[L1 Unit 2](./ch03-00-facts-spaces-queries.md) for why a rule-shaped log is invisible
to `match` and why data goes in as atoms:

```metta
(= (hit $p)
    (match &self (target $a $b $o)
        (if (== (eval-c $p $a $b) $o) 1 Empty)))
(= (hits $p) (let $t (collapse (hit $p)) (foldl-atom $t 0 $acc $e (+ $acc $e))))
```

## Semantics

**A missing leaf rule does not error; it poisons the comparison.** This is the bug
this chapter was written around. `(nf (var-y))` with no rule for `(var-y)` returns
the atom unchanged, and a `let` whose value does not reduce binds **the expression
itself**: `$a` becomes `(nf (var-y))`, not `(var-y)`. Then `(rank $a)` has no rule
either, `>=` never reduces, and the whole call comes back as an un-reduced `if` —
which is exactly what the first draft of the listing printed. Verified shape:
`(= (f $x) (let $y (leaf $x) (g $y)))` with no rule for `(leaf (foo))` gives
`(g (leaf (foo)))`, while `(leaf (var-x))` with a rule gives `(g (var-x))`. A
normal form must therefore cover every constructor in the language, including the
leaves, and the way to check that you did is one assertion per leaf.

**One head, many shapes: `case`. Many results on purpose: overlapping heads.** Say
it as a test you can apply to your own file. If the query should produce *one*
answer, overlapping heads is a bug — the listing's `nf` must not have two rules for
`c-and`, because then every `c-and` candidate returns twice, and the sort branch and
the idempotence branch disagree about which answer is the candidate. If the query
should produce *all* matches, overlapping heads is the mechanism — that is `grow`
and `subs`. The tell is whether you wrote a count assertion: `grow-count` of a
`c-and` is 5 and *that is the point*, so `nf` has no count assertion, it has an
`assertEqualToResult` with one atom inside.

**Order is not a property you may assert.** The fact sheet has said this since
[L1](./ch03-00-facts-spaces-queries.md) and L7 is where it bites, because a deme is a
set of five atoms and a first draft will assert them as a list. The interpreter gives
no order guarantee across `collapse`, so those assertions flake. Write the order-free
versions instead — count, sum of sizes, sum of hits, max of hits:

```metta
!(assertEqualToResult (deme-count (c-and (var-x) (var-y))) (5))
!(assertEqualToResult (deme-size  (c-and (var-x) (var-y))) (21))
!(assertEqualToResult (deme-best  (c-and (var-x) (var-y))) (4))
```

and print the deme when you want to *see* it. Related, and verified here: the
expected-value nesting in `assertEqualToResult` doubles when you wrap in `collapse`,
because `collapse` returns one tuple — `(nf X)` asserts as `((c-and (var-x) (var-y)))`
while `(collapse (nf X))` asserts as `(((c-and (var-x) (var-y))))`.

**`foldl-atom` needs its tuple `let`-bound, or it fails loudly here and silently
elsewhere.** `(foldl-atom (collapse Q) 0 $a $e (+ $a $e))` does not work: the first
argument is an unevaluated expression, and the interpreter answers
`BadArgType 2 Number (-> Atom Atom)`. `(let $t (collapse Q) (foldl-atom $t …))` does.
The listing has five folds in it and every one is let-bound for this reason.

**The complexity penalty is where the search starts lying.** With penalty 0 the AND
wins on the AND target: `hits` 4, and `score` is just `hits`. Set the penalty to 1 and
watch the ranking invert — this is asserted in the listing, with real numbers:

```
score1 (var-x)                     -> 2      ; wrong on one row, one node
score1 (const-0)                   -> 2      ; wrong on one row, one node
score1 (c-and (var-x) (var-y))     -> 1      ; correct on all four, three nodes
```

Two wrong one-node programs tie, and both beat the right three-node answer. That is
not a curiosity; it is the reason MOSES has a plateau rule and a whole discussion of
its penalty constant, and it is the reason `hits` alone is a bad fitness. Exercise 36
makes you meet the same phenomenon through Pareto dominance instead of a weighted
sum, and the verdict there is worse: under size-strict dominance the correct
majority program **dominates nothing and is dominated by nothing**, so the truth, the
near-miss and the one-node lie all sit on the same front and get sampled as equals.
A front is not a ranking. You need an error threshold, or a weighted score, *before*
the comparator gets clever.

**Normal form is a design decision with a completeness budget.** The listing's `nf`
sorts and collapses double negation and detects a literal contradiction in either
argument position. Exercise 37 adds absorption — `A ^ (A ^ B) = A` — which is what
turns `(c-and (var-x) (c-and (var-x) (var-y)))` from a five-node program into a
three-node one, and it must be added *inside* the single `c-and` rule, via two
`case`-branching helpers. It declines distribution and De Morgan on purpose: those
rewrite a node into a deeper tree, which can loop against a sorting rule, and a
search whose normalizer is not terminating is worse than one that is not complete.
So the exercise asserts the incompleteness too:
`(nf (c-and (c-or (var-x) (var-y)) (c-not (var-x))))` stays a mess. A normal form you
cannot prove idempotent — `(== (nf (nf p)) (nf p))` — is not a normal form, and one
that changes `hits` is a filter, not a normalizer. Both properties are asserted in
exercise 37's solution, and `hits` preservation is the one that catches a wrong
`const-1`/`const-0` swap.

**Fitness is a vector, and dedup only works if the guard filters.** `(bad $p)` emits
the *rows a candidate gets wrong*, so two programs with equal `hits` are distinguish-
able; `(c-and (var-x) (var-y))` and `(c-and (var-x) (var-z))` are both wrong twice on
the majority target, and each is right on a row the other misses, provable with four
`eval-c` calls. The dedup version of the same lesson is sharper: a `seen-count` that
matches `(s $q)` instead of `(s $p)` asks "have I stored anything at all", and the
first draft of it turned a five-program population into a one-survivor population —
no error, just a wrong count. Write the guard, then write the assertion that fails if
the guard does not filter. And when you query `&seen`, query it in *canonical* form:
`(seen-count (c-and (var-y) (var-x)))` is `0`, because the space holds the normalized
atom. That is tricks 1 and 2 meeting: normalization is what makes a deme-sized
population mean something.

**Local search is local, and the chapter should say so.** From `(var-x)` — wrong on
one row — one deme step finds the truth: `grow-best (var-x)` is 4. From
`(c-or (var-x) (var-y))`, one deme step reaches 3 and no further, because extending
an OR with a leaf simplifies back to a single variable: `grow-best` is 3, and
crossing that OR with `(var-x)` still gives 3. The neighbourhood around a wrong shape
cannot see the right shape, which is the guide's "wisdom is not transferable between
deme" made checkable in four atoms. The repairs, in cost order: more mutation
operators, restarts in fresh demes, crossover between demes. MOSES buys a fourth thing
you are not building here — it models the deme statistically (an estimation-of-
distribution / Bayesian network over the exemplar's neighbourhood) and samples new
candidates from the model instead of mutating one at a time, which is the part the
guide calls the second secret sauce and the part that has no MeTTa-side equivalent in
this chapter.

**What this runtime does not give you, and what upstream assumes.** Verified absent
on 0.2.10, each call returned unreduced rather than an answer: `bool-and`, `bool-or`,
`bool-not`, `member`. Verified present and useful: `case`, `get-metatype`, `foldl-atom`,
`collapse`, `add-atom`, `match` on named spaces, `new-space`. `println!` takes one
argument here — `!(println! "x" 1)` is `IncorrectNumberOfArguments`. This matters for
the port you are not doing: `hyperon-moses`'s own `boolean-reduction/rules.metta` uses
`case`, `get-metatype` **and** `member`, so it cannot run unmodified against this
interpreter. Read it for the rule list; expect to rewrite the helpers. The listing in
this chapter uses `if`/`==` for booleans, `case` for shape dispatch, and hand-rolled
`or-bool`/`not-bool`, so it is portable to the runtime you actually have.

**The guide's own shortcuts, and why they are not needed here.** Upstream eliminates
lambda abstraction during search entirely (introducing a binder mid-search multiplies
applications and every application is a new binder candidate, which the guide calls
out as unmanageable), adds the input variables to the environment before reasoning
begins, and quotes programs to stop spontaneous evaluation. You are doing a truth-table
search over a fixed arity, so the arity is fixed by `eval-c`'s signature and none of
that pressure appears. It reappears the moment you search over *functions* rather than
propositions — which is what the chaining prototype in
`trueagi-io/chaining/experimental/evolutionary-programming` is doing with the
dependent-typed `(Σ (-> Bool Bool Bool) (Fit 0.7))` framing: a fit program is an
inhabitant of a Sigma type, and the search is proof construction. That is the elegant
version of trick 3, it is genuinely a reasoning process rather than a loop, and it is
outside this book's runtime. Read it after this chapter, not before.

## Exercises

Predict, then run. Every "actually printed" column is what this machine said.

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | `!(eval-c (c-and (var-x) (var-y)) 1 0)` | | `0` |
| 2 | `!(nf (c-and (var-y) (var-x)))` | | `(c-and (var-x) (var-y))` |
| 3 | `!(nf (c-and (var-x) (c-not (var-x))))` | | `(const-0)` |
| 4 | `!(nf (c-not (c-not (c-not (var-x)))))` | | `(c-not (var-x))` |
| 5 | `!(hits (c-not (c-and (var-x) (var-y))))` | | `0` |
| 6 | `!(score1 (var-x))` *(penalty 1)* | | `2` |
| 7 | `!(score1 (c-and (var-x) (var-y)))` | | `1` |
| 8 | `!(deme-count (c-and (var-x) (var-y)))` | | `5` |
| 9 | `!(deme-best (c-or (var-x) (var-y)))` | | `3` |
| 10 | `!(case (zzz) (((c-and $a $b) hit)))` | | `()` |
| 11 | `!(bool-or True False)` | | the call, unreduced |
| 12 | `!(foldl-atom (collapse (hit (var-x))) 0 $a $e (+ $a $e))` | | a `BadArgType` error |

Then build, in `metta-course-exercises/exercises/12_program_search/`:

- **36 — Fitness is a vector** ([starter](../metta-course-exercises/exercises/12_program_search/36_fitness_vector.metta), [solution](../metta-course-exercises/solutions/12_program_search/36_fitness_vector.metta)).
  Majority-of-three as eight facts, three-input `eval-c`, per-row `bad`, `dominates`,
  `better`, and the discovery that a Pareto front under size-strict dominance puts
  the truth and a one-node lie on the same tier.
- **37 — Canonical shapes** ([starter](../metta-course-exercises/exercises/12_program_search/37_canonical_shapes.metta), [solution](../metta-course-exercises/solutions/12_program_search/37_canonical_shapes.metta)).
  Absorption without a second head, then proofs of idempotence and
  behaviour-preservation, then an assertion that the thing you declined to add
  (distribution) really is still broken.
- **38 — Grow, cross, dedup** ([starter](../metta-course-exercises/exercises/12_program_search/38_grow_cross_dedup.metta), [solution](../metta-course-exercises/solutions/12_program_search/38_grow_cross_dedup.metta)).
  `subs`, `replace`, `cross` with order-free counts, a `&seen` space that dedups
  seven candidates to five programs, and three assertions showing one deme step
  finds the truth from `var-x` and never finds it from `or`. Deliberately break the
  dedup guard once and watch the count go to 1.

Reading, in this order, licence caveat first: `hyperon-moses`'s
`docs/metta-port-highlevel-guide.md` for the three tricks and the vocabulary
(ENF, deme, plateau, `GoodFit`); then its `boolean-reduction/rules.metta` to see a
real rule list and to confirm the `member`/`case`/`get-metatype` portability problem
above; then `trueagi-io/chaining/experimental/evolutionary-programming` for the
dependent-typed framing. **AGPL-3.0 means you may read all of it and paste none of it**
into anything you publish. Write your own rules; that is also better learning.

Recall cards (1/3/7/21), for the deck from [L6](./ch12-l6-capstone.md):

- The three tricks, one line each, and which one your `nf` implements.
- Why every leaf needs a rule, in terms of what `let` binds.
- `case` versus two same-head rules: when each is correct.
- The three order-free assertions that replace asserting a deme as a list.
- Why `score1` with penalty 1 ranks a wrong answer above a right one.
- Under size-strict dominance, what does the correct majority program dominate?
- What does upstream MOSES do inside a deme that this chapter does not?

## Ship it

Friday: `l7-01-moses.metta` green under `bash verify-offline.sh`, exercises 36–38
attempted from the starters with their assertions passing, and `check-solutions.sh`
still reporting zero failures across the whole track. Then answer, out loud, in the
README of your own copy:

- Which constructor in your `nf` had no rule, and what did the interpreter print?
- How many results does `(grow (c-and (var-x) (var-y)))` return, and why is head
  overlap correct there and wrong in `nf`?
- What is the fitness of `(var-x)` on your target, and what is its penalty-adjusted
  score? Which one makes it look better than the truth?
- Which of your assertions would flake if result order changed, and what replaced it?
- What is in your `&seen` space that is not in your `cand` facts?

After that, the corpus is the syllabus: [Appendix: the public MeTTa
corpus](./appendix-10-sources.md) has `hyperon-moses`, `chaining`, `metta-examples`
and the rest, and you now have the runtime vocabulary to read them without a guide.
The two things your plan says matter more than reading — teaching this to someone, and
defending a number in front of them — are both still the gate, and a MOSES-shaped
search is the best number-defending artifact this language can produce, because its
whole subject is a claim you can check by hand on four rows.
