# Appendix: the verified fact sheet

Every chapter in this book cites one of these lines. If a claim is not here and
not in `docs/metta.md`, it does not go in the book. Source of truth for
semantics is the vendored spec at
`~/Desktop/ex/exercises/hyperon-experimental/docs/metta.md` (tag v0.2.10), which
matches the installed wheel (`python3.12 -m hyperon.metta --version` → 0.2.10).

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
- `collapse` returns a tuple; `superpose` is the nondeterminism constructor;
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
