# L1 · Unit 1 — Grammar and atoms

L1 is the level where you stop recognising MeTTa and start writing it. Five
verbs carry almost the whole language: store, query, define, call, cast. This
unit is about the paper they are written on — what the parser accepts, what it
means when it accepts it, and the three ways a legal atom can still be the wrong
atom.

Friday artifact: a one-page cheat sheet of your own handwriting listing every
atom form in the grammar and one example of each, plus the four traps at the
bottom. If you can produce that sheet from memory, the level is passed.

## Syntax

The spec (`hyperon-experimental/docs/metta.md`, tag v0.2.10 — the same version
as your installed wheel) gives the whole program grammar in eight lines:

```
MET ::= { [ '!' [DELIM] ], ATOM, [DELIM] } ;
ATOM ::= SYMBOL | VARIABLE | GROUNDED | EXPRESSION ;
SYMBOL ::= WORD ;
VARIABLE ::= '$', ( CHAR | '"' ), { CHAR | '"' } ;
GROUNDED ::= STRING | WORD ;
EXPRESSION ::= '(', { ATOM, [ DELIM ] }, ')' ;
STRING ::= '"', { CHAR | WHITESPACE | '#' | '(' | ')' | ';' }, '"' ;
COMMENT ::= ';' … end of line ;
```

Read the first line out loud, because it is the lesson: a MeTTa *program* is a
sequence of atoms, each optionally preceded by `!`. There is no file header, no
module declaration required, no function wrapper. Anything at the top level that
is not `!`-prefixed is stored. So all four of these are complete, legal programs:

```metta
plainSymbol
"a string atom"
(nested (deeper (deepest)) 42)
(symbol one)
```

Run that file and you get `Loaded n.metta (no query results).` — one line,
regardless of how many atoms you stored. Storing is silent. This is the single
most common reason a beginner thinks a file "did nothing".

Numbers look like symbols in the grammar (`GROUNDED ::= STRING | WORD`) and are
told apart only by the tokenizer:

```metta
!(get-type 3)      ; Number
!(get-type 3.5)    ; Number
!(get-type -2)     ; Number
!(get-type three)  ; %Undefined%
```

Three rules to memorise, all from the grammar block above:

`$` introduces a variable, and a variable name may not contain `#`. The spec
reserves `#` for the interpreter's own generated variables, which is why you
occasionally see names like `$t#138` in errors. Writing `$a#b` is not a variable
with a `#` in it; it is a parse you cannot make.

A symbol may begin with `!`. `!name` is one valid symbol. The spec apologises
for this in a footnote — "an artifact of the HE parser evolution process" — but
it means the prefix rule is genuinely ambiguous, which matters in
[Unit 4](./ch05-00-evaluation-and-results.md) when you try to get clever.

Strings can contain `(`, `)`, `;` and `#`. `"a (b; c#"` is one atom. The
parentheses inside quotes do not open an expression.

## Semantics

An atom is not a value; it is one of four kinds, and the kind is part of what
matching does. The spec's `match_atoms` pseudocode is worth reading in full, but
its opening branches are the ones that will save you hours:

- two symbols match only if they are the *same symbol*;
- a variable matches anything and takes a binding;
- two expressions match only if they have the same number of children and every
  child matches pairwise;
- two grounded atoms match unless one of them brings a custom matcher that
  disagrees.

There is no clause for "symbol matches string". A symbol is an id; a string is a
grounded value with a host representation. That is why the head of a pattern is
load-bearing:

```metta
(symbol one)
!(match &self (symbol one) found)   ; found
!(match &self (slot one) nope)       ; prints nothing at all
```

`match` searches stored atoms. It does not raise, it does not print `no match`,
it simply produces no result, and the CLI prints nothing for an empty result.
Silence is the answer. Get comfortable reading "no line" as a real result — this
habit pays off at every later level.

Second, `match` is not syntax sugar for something else. It is a grounded
function with a type you can ask for:

```metta
!(get-type match)
; (-> SpaceType Atom Atom %Undefined%)
```

Three arguments: a space, a pattern, a template. That signature *is* the
semantics. The first argument says matching always happens **in a space you name
explicitly** (`&self` when you mean "this file's atoms"). The second says the
pattern is an ordinary `Atom`, which is why `(match &self (slot one) nope)` is a
faithful question about a space that has no `slot` facts. The third says the
template is evaluated, so what you put there can be a call, not just a name.

Third trap: whitespace. It separates atoms and is otherwise meaningless, so
removing a space changes the atom count, not just the style:

```metta
!(get-type match)           ; (-> SpaceType Atom Atom %Undefined%)
; (match&self (slot $x) $x) ; ONE symbol whose name is "match&self"
```

The commented line above is legal MeTTa. It is stored as a single symbol, never
runs, and no error tells you so. I have written this bug. It costs about twenty
minutes the first time and thirty seconds of dread every time afterwards.

Fourth trap, and the one that cost me an afternoon: a bare variable at the top
level is not data. `$alone` on a line of its own is a `VARIABLE` atom, and the
grammar has no rule against storing one, so it goes into the space as a live,
unbound variable. Later, when something queries that space, `match_atoms` sees a
variable on one side and happily binds it:

```metta
$alone
!(match &self (symbol $x) $x)   ; answers $x — a phantom, not a fact
```

You meant "remember the name alone". Write `(name alone)` or `(alone)`. Variables
belong inside expressions, in patterns, and in rule bodies — never loose.

## Exercises

Type these into a scratch file. Do not copy-paste; typing is the exercise. Cover
the right column with your hand or a strip of paper and write a prediction
first; a wrong prediction that you wrote down before running is worth more than
a right one.

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | `(red ball)` then `!(match &self (red $c) $c)` | | `ball` (verified) |
| 2 | `!(get-type 42)` | | `Number` (verified) |
| 3 | `!(get-type "42")` | | `String` (verified) |
| 4 | `!(get-type 4+2)` | | your call — the tokenizer decides, not you |
| 5 | `!(match &self (red ball) yes)` with **no** fact stored | | nothing |
| 6 | `$loose` then `!(match &self (red $c) $c)` | | watch the phantom appear |

Then, in order:

1. Write a file of exactly five stored atoms — one bare symbol, one string, one
   nested expression, one integer, one expression whose children include a
   variable. Predict the number of result lines before running. It is one.
2. Take the [L0 toy-graph listing](../listings/l0-02-toy-graph.metta) and change
   one head symbol in one fact so that a query silently returns nothing. Confirm
   you can *see* nothing happening, and say out loud which line caused it.
3. Write `(match&self (red $c) $c)` as a stored atom, then `!(get-atoms &self)`
   and `!(get-type match&self)`. Explain in two sentences why the first prints
   nothing and the second prints a type.
4. Explain to yourself in writing why `3` and `three` have different types when
   the grammar says both are `WORD`. The answer is one sentence and it is in the
   Syntax section.

Recall cards for the spaced-repetition deck ([L6](./ch12-l6-capstone.md) has you
build the real thing; for now use paper, reviewed at 1, 3, 7 and 21 days):

- Name the four atom kinds. Which two look identical to the grammar?
- What are `match`'s three arguments, in order, and what does each do?
- What does the CLI print when a query has no results?
- Why can't a variable name contain `#`?
- Give the two-token difference between `(match &self …)` and `match&self`.

## Ship it

By Friday: `listings/l1-02-grammar.metta` runs green, your five-atom file runs
green, and the handwritten cheat sheet exists. The cheat sheet is the artifact —
the files are how you prove it isn't wishful thinking. Next unit:
[Atoms and expressions as data](./ch02-00-atoms-and-expressions.md) collapses
into this one, so the real next step is
[Unit 2 — facts, spaces and queries](./ch03-00-facts-spaces-queries.md).
