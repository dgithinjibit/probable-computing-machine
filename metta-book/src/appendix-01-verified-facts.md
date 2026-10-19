# Appendix: the verified fact sheet

Every chapter in this book cites one of these lines. If a claim is not here and
not in `docs/metta.md`, it does not go in the book. Source of truth for
semantics is the vendored spec at
`~/Desktop/ex/exercises/hyperon-experimental/docs/metta.md` (tag v0.2.10), which
matches the installed wheel (`python3.12 -m hyperon.metta --version` → 0.2.10).

**Status, 2026-10-19.** All 33 solutions and all 17 listings have been executed on
this build in one non-aborting sweep: 50 files, zero failures, zero `Error (` lines.
Nine of them were wrong before that pass — the `collapse` binder syntax, a
`foldl-atom` argument that was never evaluated, hour logs written as rules instead
of facts, an `or-stv` assertion whose arithmetic I had not done, a file handle read
back through the wrong mode, and a lowering that answered fourteen results for one
program. Each correction is a bullet below, and each is a trap this book now warns
you about with a real error message rather than a guess.

## Grammar (spec §Syntax)

- `MET ::= { [ '!' [DELIM] ], ATOM, [DELIM] }` — `!` is legal only in front of a
  top-level atom.
- `ATOM ::= SYMBOL | VARIABLE | GROUNDED | EXPRESSION`.
- A symbol may itself begin with `!` (`!name` is one valid symbol). Prefix
  parsing is therefore ambiguous by design; the spec calls it "an artifact of
  the HE parser evolution process".
- `#` is reserved for interpreter-generated variables (`$t#138`); it cannot
  appear in your variable names.
- Grounded atoms are produced by a *tokenizer* of `(regexp, constructor)` pairs,
  not by the grammar. That is why `3` is `Number` and `three` is `%Undefined%`.
- Comments run to end of line. Whitespace separates atoms and is otherwise
  meaningless — `(match&self …)` is one symbol, not a call.

## Interpretation (spec §Interpretation)

- Program is interpreted atom by atom; each atom sees the effects of the ones
  before it.
- No prefix → added to the top module's atomspace. `!` → evaluated, result
  returned to the user, **not** stored.
- Evaluating an atom is internally `metta(atom, type, space, bindings)` with
  `type = %Undefined%` and empty bindings.
- `metta` returns early for `Empty`, `(Error …)`, when the expected type is
  `Atom`/matching metatype, when the atom's metatype is `Variable`, or when the
  expression is already marked evaluated (the "one `eval` step does not
  re-advance" behaviour).
- `metta_call`: if the head is an executable grounded atom, call it natively;
  otherwise `query(space, (= <atom> $X))` — **a function call is a space query
  for an `=` rule**. No rule → the call is returned unchanged.
- `match_atoms` is two-way: `Variable` on either side binds; two symbols must be
  equal; expressions must have equal length and match child by child; two
  grounded atoms match if no custom matcher disagrees.

## Special atoms (spec §Special expressions)

- `(= <call template> <body template>)` defines a function. `(= …)` with three
  or more arguments is *not* a definition; it is just data in the space.
- `(: atom type)` assigns a type; `(-> a1 a2 … ret)` builds a function type.
- Elementary types: `Type`, `%Undefined%`, `Atom`, `Symbol`, `Variable`,
  `Expression`, `Grounded`. All but `Type` affect evaluation order; `Atom` is
  the "don't evaluate" meta-type.
- Results: `Empty` (no result — not void/unit), `NotReducible` (return the call
  unchanged), `Error`.
- `Error` shapes: `StackOverflow`, `NoReturn`, `IncorrectNumberOfArguments`,
  `(BadArgType <pos> <expected> <actual>)`, `(BadType <expected> <actual>)`.
  `ErrorType` is an ordinary symbol you can use for custom error constructors.

## Minimal MeTTa (spec §Minimal MeTTa instructions)

`eval`, `evalc`, `chain`, `unify`, `cons-atom`, `decons-atom`, `function`,
`return`, `collapse-bind`, `superpose-bind`, `metta`, `context-space`,
`call-native` (not callable from MeTTa; only returned by grounded functions).

## Confirmed on this build (2026-10-19, 0.2.10)

- `!(get-type 3)` → `Number`; `3.5` → `Number`; `-2` → `Number`; `three` →
  `%Undefined%`; `"six"` → `String`.
- `!(get-type match)` → `(-> SpaceType Atom Atom %Undefined%)`.
- `!(match &self (symbol one) found)` → `found`. A pattern whose head symbol
  differs (`(slot one)` against stored `(symbol one)`) answers nothing, and
  `match` prints nothing rather than "no match".
- Storing a bare `$var` at top level leaves a live variable in the space: a
  later `!(match &self (symbol $x) $x)` can unify against it and print `$x`.
- Two `(= …)` rules with the same head are **all** tried (spec: the query
  collects every binding). Adding a stricter duplicate rule duplicates results.
- Unguarded two-rule recursion (`(= (fact 0) 1)` + `(= (fact $n) …)`) never
  terminates here. The working shape is one guarded rule using `if`.
- `(, a b)` is only meaningful inside a `match` pattern; as a rule body it
  builds a data atom.
- Type errors are raised at call time: `(double "six")` → `(Error … (BadArgType
  1 Number String))`. `/` on integers is integer division (`(/ 7 2)` → `3`).
- Absent in this stdlib: `!=`, `sqrt`, `abs`, `sum-atom`, `pr::println`,
  `filter-atom` (declared, never returns). `min-atom`/`max-atom` answer floats.
- `foldl-atom`/`map-atom` fold the **children of a tuple**, not `::` lists:
  `!(foldl-atom (1 2 3) 0 $acc $e (+ $acc $e))` → `6`.
- `!(bind! &kb (new-space))` → `()`; `add-atom`/`remove-atom` → `()`;
  `!(get-atoms &kb)` lists atoms; `match &kb` works. `!(get-atoms &self)` prints
  nothing, and `!&` is not parsed (the line is echoed as data).
- `!(import! &m name)` resolves against the **current working directory**, not
  the script's directory; `pkg:inner` addresses `pkg/inner.metta`; failure reads
  `(Error (import! &m sibmod) Failed to resolve module top:sibmod)`.
- Builtin modules import bare: `!(import! &self json)`, `random`, `fileio`.
  `@metta::json` → "Invalid module name format".
- State: `!(bind! &counter (new-state 0))`, `get-state`, `change-state!`
  (paired with `!(nop …)`); a wrong-typed update is a type error.
- `collapse` takes **one** argument and is not a binder:
  `!(collapse $r (coin))` → `(Error … IncorrectNumberOfArguments)`; `let` is the
  binder and the source of multiplicity (`(let $a (coin) (let $b (coin) (ab $a $b)))`
  → 4 results, in heads-first order). `!(collapse (superpose (1 2 3)))` → `(1 2 3)`.
- `foldl-atom`'s first position is `Atom`-typed, so it is passed **un-evaluated**.
  `(foldl-atom (collapse (all-hours)) 0 $acc $e (+ $acc $e))` folds the *call* and
  answers `(Error (+ 0 collapse) (BadArgType 2 Number (-> Atom Atom)) …)`. Bind the
  tuple with `let` first.
- Result order is not stable across forms: four hour facts query as `14 9 0 12` and
  collapse to `(12 0 9 14)`. Assert sums, counts, or sorted tuples.
- A query with no results collapses to `()` — one result, the empty tuple — while
  the bare query prints nothing. "No results" is asserted with
  `!(assertEqualToResult (call) ())`; putting `Empty` there is itself an error
  (`Atom is not an ExpressionAtom`).
- `Empty` returned from a branch makes that branch vanish silently:
  `(= (f $x) (if (== $x 1) Empty (:ok $x)))` prints `(:ok 2)` for `2`, nothing for `1`.
- A call that matches **no** rule is returned unreduced, not as an error and not as
  silence. In a lowering this is the dangerous case: an op with no `lower` rule
  ships a live `(lower …)` atom inside the target tree.
- Data written as a rule is invisible to `match`: `(= (hours2 d) 11)` answers the
  call `(hours2 d)` but `(match &self (hours2 $d $h) $h)` finds nothing, because the
  stored atom's head is `=`. Write logs as facts (`(hours d 11)`) when something has
  to enumerate them.
- `fileio` has no `file-close!` on this build — the call is echoed unevaluated, not
  an error. You cannot read back through a handle opened `"wc"` (`Bad file
  descriptor`); open a second handle with `"r"` and read from that.
- Overlapping patterns are a correctness bug, not a style problem: one program plus
  a catch-all `lower` rule yields fourteen results where one was wanted
  (disjoint, tagged leaf shapes give exactly one).
- `superpose` is the nondeterminism constructor;
  multiple nondeterministic arguments combine (2 × 2 → 4 results).

## Published corpus (found 2026-10-19 via `gh`)

`trueagi-io/metta-examples` (SICP ch1-2, aunt-kg kinship graph, collatz,
combinators, deontic logic), `trueagi-io/chaining` (backward/forward/iterative/
dependent-typed/probabilistic chaining, PLN prototype),
`trueagi-io/metta-wam`, `trueagi-io/PeTTa`, `trueagi-io/hyperon-moses` (+ its
`docs/metta-port-highlevel-guide`), `iCog-Labs-Dev/hyperon-openpsi` (demand,
emotion, modulator, action-planner), `eyuuab/MeTTa-lang-stdlib-documentation`
(rst categories), `MesTTo/LeaTTa` (Lean 4 operational semantics),
`logicmoo/metta-testsuite` (`.metta.answers` oracles), `NullLabTests/metta-demo`.
