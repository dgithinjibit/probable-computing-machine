# L1 · Unit 5 — Types and errors

Types in MeTTa are not a safety net you opt into; they are the dial that decides
when things get evaluated, and they are checked at call time by a function you
can read in the spec. Errors are atoms, not exceptions — which means an error can
be stored, matched, returned, and asserted on like anything else. That reframing
is the last piece of L1: after this unit you can read the interpreter's own
rejection letters.

Friday artifact: `types.metta` — a typed mini-library (rover sensor readings)
where every function has a `(: …)` line, plus a table of the four errors you
caused on purpose and what each message taught you.

## Syntax

Type assignment and function types come straight from the spec's special
expressions:

```
(: <atom> <type>)
(-> arg1_type arg2_type ... argN_type ret_type)
```

```metta
(: double (-> Number Number))
(: at (-> Symbol Symbol Bool))
(: List (-> Type Type))
(: Cons (-> $t (List $t) (List $t)))
(: Nil (List $t))
```

`$t` in a signature is a pattern variable: it must be the same type in every
occurrence of that one signature, which is how polymorphism is written. Never
write `$t#`-style names; `#` is reserved for the interpreter's generated
variables.

The elementary types are a closed list — `Type`, `%Undefined%`, `Atom`,
`Symbol`, `Variable`, `Expression`, `Grounded` — and the spec says of them: "All
of them except the `Type` affect the order of the expression evaluation." Read
that sentence once more, then read it a third time after the Semantics section,
because it is the reason a typed program and an untyped program of identical
text produce different output.

`get-type` asks the space what it knows:

```metta
!(get-type 3)        ; Number
!(get-type three)    ; %Undefined%
!(get-type match)    ; (-> SpaceType Atom Atom %Undefined%)
```

`%Undefined%` means "this atom has no `(: …)` atom in scope", not "wrong". An
untyped MeTTa program is legal and runs; you simply do not get argument checks.

Errors are built with the `Error` constructor, and the spec lists exactly which
shapes exist:

```metta
(Error <atom with error> <error message>)
```

with messages `StackOverflow`, `NoReturn`, `IncorrectNumberOfArguments`,
`(BadArgType <pos> <expected> <actual>)`, `(BadType <expected> <actual>)` — and
`ErrorType` available as an ordinary symbol if you want your own error
constructors.

## Semantics

**Type checking happens in `check_if_function_type_is_applicable`, before the
body runs.** Follow the spec's pseudocode with a concrete call
(`!(double "six")`): `interpret_expression` takes the head's types, filters to
valid function types, then for each argument index calls `check_argument_type`,
which looks up the argument's actual types from the space and tries
`match_types`. A miss produces `(Error $atom (BadArgType ($idx - 1) expected
actual))`. Verified on this build:

```metta
(: double (-> Number Number))
(= (double $x) (* 2 $x))
; !(double "six")
; (Error (double "six") (BadArgType 1 Number String))
```

So the `1` in `BadArgType 1 Number String` is the **zero-based argument index**,
`Number` what the signature demanded, `String` what the space said the argument
was. Read those errors right-to-left against the pseudocode and they stop being
gibberish. (Keep live errors commented out in listings: a bare `Error (` in a
file both trips `verify-offline.sh`'s grep and appears to suppress later prints.)

**`match_types` is generous in two specific ways.** The spec returns the bindings
unchanged when either side is `%Undefined%` *or* when either side is `Atom`.
Consequences: an untyped argument never fails a check (`%Undefined%` matches
anything), and an `Atom`-typed parameter never fails and never gets evaluated —
which is [Unit 4](./ch05-00-evaluation-and-results.md)'s `hold` example. Typing
a parameter `Atom` is therefore not "accept anything", it is "accept anything
*as source text*". That distinction is the whole reason quote-style metaprogramming
at [L5](./ch11-l5-interop-and-export.md) is possible.

**Return type is checked too, and it is a cast.** The last lines of
`check_if_function_type_is_applicable` compare the expected type against the
function's declared return type and emit `(BadType expected actual)` if they
disagree. Since a top-level `!` evaluation asks with expected type
`%Undefined%` ("we don't have the syntax for specifying it" — spec), you will
rarely see `BadType` from the CLI. You will see it when a *rule body* calls a
typed function where the caller's signature demands something else. This is why
rover code that grows `(: …)` lines late starts failing in places far from the
change: the cast checks only exist once the signatures do.

**Type is data, so you can query it.** `(: at (-> Symbol Symbol Bool))` is a
stored atom; `!(match &self (: double $t) $t)` returns `(-> Number Number)`.
Programs reading their own types is the mechanism behind generic dispatch, and
at [L3](./ch09-l3-modules-and-search.md) behind enumerating candidate
programs by type. It also means a typo'd `(: …)` line is a *fact* that misleads
every later call — types are not verified against bodies. `(: double (->
Number Atom))` still runs `!(double 4)` → `8`; the signature simply stops
protecting the return.

**Errors are values all the way up.** The spec's `metta` early-returns
`(Error …)` results, and `interpret_expression` separates successes from errors:
if any non-error result exists, errors are dropped; otherwise the errors come
back. That asymmetry explains a real confusion: a nondeterministic call can
*hide* an error among its good results. If one branch of your rover decision
throws `BadArgType` and another succeeds, you will see only the success and
conclude the bad branch never ran. Force the issue with `!(collapse (…))` and
look for an `Error` child in the tuple.

**Grounded types come from the tokenizer and the host.** `Number` and `String`
exist because a tokenizer pair turned `3` and `"six"` into grounded atoms with
those types. Nothing stops a grounded module registering more — `py-atom` at
[L5](./ch11-l5-interop-and-export.md) is exactly that, and `(: rng …)`-style
signatures on Python-backed atoms are how you get a checked `random-int` call.

## Exercises

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | `!(get-type "six")` | | `String` |
| 2 | `!(get-type (double 4))` with no `(: double …)` | | `%Undefined%` |
| 3 | typed `double`, then `!(double 4)` | | `8` |
| 4 | typed `double`, then `!(double "six")` *(comment in file, run alone)* | | `BadArgType 1 Number String` |
| 5 | `!(double 4 5)` with `(-> Number Number)` | | `IncorrectNumberOfArguments` |
| 6 | `(: hold (-> Atom Atom))`, `!(hold (+ 1 2))` | | unevaluated |
| 7 | `!(match &self (: double $t) $t)` | | the function type |
| 8 | `(= (bad $x) (double $x))` `(: bad (-> Number Atom))`, `!(bad "s")` | | read it twice |

Tasks:

1. Give every function in `arith.metta` ([Unit 3](./ch04-00-functions-and-pattern-matching.md))
   a `(: …)` line, then run it. Any new error is a lie your code was telling —
   write down which signature was wrong and why the untyped version hid it.
2. Model rover readings: `(: reading (-> Symbol Number))`, facts like
   `(reading ultrasonic-front)`, plus a `danger` function typed
   `(-> Number Bool)` that guards on `(< d 30)`. Call it on a string and on a
   float and record both messages.
3. Write a polymorphic `head` using `$t`: `(: head (-> (List $t) $t))` over your
   `::` lists. Then show that calling it on a non-list still fails *somewhere*,
   and name the function in the spec pseudocode that decided that.
4. Deliberately mismatch a signature and a body (`(: lie (-> Number Atom))`
   returning `42`) and show nothing complains. Then make the *caller* demand
   `Number` and watch `BadType` appear. Explain in three sentences who checks
   what, and when.
5. Write a rule that nondeterministically succeeds on some inputs and errors on
   others (use `(bin)` from [Unit 4](./ch05-00-evaluation-and-results.md) with
   `(double (bin))` where one branch is a string). Show the plain call hiding
   the error, then `collapse` it into evidence.
6. Self-test errors as data: `!(assertEqualToResult (lie-checked "x")
   ((Error … )))` — construct the exact expected atom from your observed output.

Recall cards:

- Which spec function checks arguments, and what are the three items in
  `BadArgType`?
- Two types that make `match_types` pass immediately.
- Are errors thrown or returned? Where does an error go when a sibling branch
  succeeds?
- Why can a wrong signature never be caught by the interpreter?
- `Atom` in a parameter position means ____ , not ____.

## Ship it

Friday: `types.metta` with the eight-row table filled from your own terminal,
`(: …)` on every function of the week's work, and the four caused-on-purpose
errors written as comments with their messages quoted. At this point L1 is
complete — store, query, define, call, cast — and you should be able to read any
listing in `listings/` and predict its output. Next:
[L2 Unit 1 — lists, recursion and `map`](./ch07-00-lists-and-recursion.md), where
the cons-list vs tuple distinction stops being trivia and starts being your data
model for sensor streams.
