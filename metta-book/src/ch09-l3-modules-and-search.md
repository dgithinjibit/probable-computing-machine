# L3 — Modules and search

L1 and L2 taught you to write one file that answers questions. L3 is the level
where MeTTa stops being a scripting language and starts being what the Hyperon
people are actually building: a space of programs you can address, import, and
*search over*. Two new powers, one shared mechanism. A module is a space with a
name and a resource directory; a search is a space of candidate programs with a
rule that answers "is this one right?". Both are the same trick — the interpreter
queries the space for `=` rules — applied at different scales.

Friday artifact: `rover_pkg/`, a two-file MeTTa package you can import from a
sibling script, plus `enumerate.metta`, which finds arithmetic programs by
generating them instead of writing them.

## Syntax

A module is a file. `modules_dev.md` is blunt about what a module *is*:
"a module in MeTTa is a persistent encapsulation of a context within which MeTTa
code can run. Every module has a unique Space (and also a Tokenizer)". And: "For
MeTTa code running within the context of a module, the `&self` token will
resolve to the module's space." Read that twice. Inside a module, `&self` is not
your script — it is the module. That single sentence explains half the questions
people ask about `import!`.

Two file shapes are supported out of the box: a single `.metta` file
(`SingleFileModuleFmt`) and a directory containing `module.metta`
(`DirModuleFmt`). Legal module names are ASCII alphanumerics plus `_` and `-` —
no dots, no slashes, no spaces. Hierarchy uses `:`: the top module is always
`top`, and a nested one reads `top:mod1:sub_a`. `self` at the head of a path
means "the module currently running".

```metta
; world.metta  (a single-file module)
(extend!
    (= (room-named $name) (match &self (room $name) $name))
    (: room-named (-> Symbol Atom))
)
```

`extend!` is the stdlib's own wrapper: its body is evaluated in the module's
context, so `(match &self …)` inside it means the *module's* space, which is
exactly what a library function needs to be able to see its own data.

Importing, and the two other linking forms the docs name as
`import module as name`, `import * from module`,
`import item from module as name`:

```metta
!(import! &world world)             ; the whole module, into a bound space token
!(world room-named kitchen)         ; call through the module's space
```

Builtin modules import by *bare* name on this build — `!(import! &self json)`,
`random`, `fileio` — while the `@metta::json` form fails outright with "Invalid
module name format" (fact sheet). Where a module is looked for, in the order
`modules_dev.md` gives it: (1) already-loaded modules in the running context,
(2) the module's `PkgInfo` dependency entries, (3) the catalogs in priority
order — the module's own `resource` directory, then `hyperon/exts/`, then the
OS config directory, which on Linux is `~/.config/metta/`. Subdirectory paths
inside a package use the colon syntax: `pkg:inner` resolves to `pkg/inner.metta`.

The search side is ordinary rule-writing with one deliberate design choice: let
several rules match the same call.

```metta
(= (a-num) 1)
(= (a-num) 2)
(= (a-num) 3)
(= (fits? $p) (if (== (* $p $p) 9) True False))
(= (find) (let $p (a-num) (if (fits? $p) $p Empty)))
!(find)                              ; 3 — the search ran itself
```

`superpose` and `collapse` do the same job with fewer rules:

```metta
(= (candidates) (superpose (1 2 3)))
(= (search) (let $p (candidates) (if (fits? $p) $p Empty)))
!(collapse $r (search))
```

## Semantics

**Modules are resolved against the working directory, not the script's
directory.** This is the trap that will cost you a Saturday. Verified on this
build, `import!` failure reads `(Error (import! &m sibmod) Failed to resolve
module top:sibmod)`, and the fix is to `cd` into the directory that owns the
module. The `top:` prefix in that error string is the tell: the resolver built a
name path starting at the top module and walked the catalog list from the docs —
own resources, `hyperon/exts/`, `~/.config/metta/` — and never found a `sibmod`
file anywhere in *that* CWD-anchored search. Practical consequence for the rover
project: your `daylog.metta` will import cleanly from the repo root and fail from
`/tmp`, and nothing about the file itself changed. Write the run command into the
README with the directory in it.

**A module's space is where its facts live, and imports do not copy them into
yours.** Import links, it doesn't clone. So `!(match &self …)` in the importing
file still cannot see the module's facts — you call the module's *functions*
through the bound token, or query the imported space directly. This is
[L2](./ch08-00-build-a-small-program.md)'s named-space discipline promoted to a
packaging rule: if you want to query it, address it. It also means a module whose
rules reference `&self` is context-dependent in a good way (`&self` = the module)
and a confusing way when you paste the same rule text into a script.

**There are no upward dependencies.** The docs' note at the top is a real design
constraint, not a style preference: "a module can have sub-module dependencies,
aka 'downward' dependencies, but it cannot have 'upward' dependencies, ie.
dependencies on the client code importing the module." So a library cannot read
the rover's percepts. The pattern that satisfies it: the client *passes* the
space, and the library takes a `SpaceType` argument exactly the way `match` does
(`(-> SpaceType Atom Atom %Undefined%)`, from
[L1](./ch02-00-atoms-and-expressions.md)). A library function of type
`(-> SpaceType Symbol Atom)` is idiomatic MeTTa; a library function that quietly
reaches into the caller's space is not, and the module system will not let it.

**Tokenizer entries come along for the whole-module import only.** The docs flag
this as WIP and warn that it "may lead to unreachable Tokenizer entries". In
plain terms: if your module registers a grounded atom type, accessing it through
a selective import can leave you with a name the parser doesn't know. Import the
module as a space and call through it rather than trying to cherry-pick.

**Enumeration is just multi-match, and it scales.** From the spec's `metta_call`:
a call runs `query(space, (= atom $X))` and *every* matching binding is returned,
then each body is evaluated. So N rules whose templates all match `(a-num)` is a
search over N candidates, and the `let`/`if`/`Empty` chain above is a filter —
`Empty` meaning "this candidate is not a result", per the spec's
"the function doesn't return any result, it is different from the void or unit
result" note. Write it that way and the interpreter's rule-lookup *is* your
search engine. Multiply over several positions and you have Cartesian enumeration
(the 2×2→4 fact from [Unit 4](./ch05-00-evaluation-and-results.md)), which is
where a 3.7GB laptop tells you to stop: enumeration is exponential in the number
of positions, not in file size.

**Programs are atoms, so a space of programs is just a space.** This is the
level you needed for the transpiler goal. A candidate *program* is an atom like
`(+ (* 2 $x) 3)` with variables still in it; matching it against a spec pattern
is unification, and rewriting it is `cons-atom`/`decons-atom` work from
[L5](./ch11-l5-interop-and-export.md). The step from "search over numbers" to
"search over programs" is only a change of what the rules enumerate — nothing in
the machinery differs. Keep that in mind when L3 feels abstract; it is the most
concrete level in the book for your actual target.

**Same-head duplication is a *feature* here and a *bug* in arithmetic.** The
[L1](./ch03-00-facts-spaces-queries.md) complaint — two rules give two results —
reverses sign the moment the two results are two candidates. The discipline is to
know which mode a given symbol is in: pure functions get guards, search spaces
get multiple rules, and the type line `(: fits? (-> Number Bool))` is what keeps
the two from bleeding into each other.

## Exercises

Predict, then run, then write the reconciliation in the file.

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | the `a-num`/`fits?`/`find` block above | | `3` |
| 2 | `!(collapse $r (search))` | | a one-element tuple |
| 3 | `(= (a-num) 3)` added twice, then `!(a-num)` | | `3` repeated |
| 4 | `!(import! &m nonexistent)` | | `Failed to resolve module top:nonexistent` |
| 5 | `!(import! &m world)` from the wrong directory | | same error — this is the trap |
| 6 | `!(import! &self @metta::json)` | | Invalid module name format |

Tasks:

1. Turn `daylog.metta` into a package: `world.metta` holding the rooms and
   connections inside `(extend! …)`, `sensors.metta` holding readings and
   `danger?`, and `daylog.metta` importing both. Make the run command explicit in
   a comment, including the directory, and prove it fails from `/tmp`.
2. Write a library function that takes the client's space as an argument —
   `(= (objects-in $space $room) (match $space (at $o $room) $o))` — and call it
   with `&world` and with `&self`. Write three sentences on why the second call
   is the one that surprises you.
3. Search over two positions: enumerate `(a-op)` from `{+ - *}` against
   `(a-num1)` and `(a-num2)`, and find every expression that evaluates to `7`.
   Count before running; the count is 3 × 3 × 3 if you allow both operand
   searches to be independent, and it is the multiplication rule, not a bug.
4. Program enumeration: define `(= (a-expr $x) $x)`, `(= (a-expr $x) (+ $x 1))`,
   `(= (a-expr $x) (* 2 $x))`, `(= (a-expr $x) (- (/ $x 2) 1))`, then write
   `(= (solves $f $target) …)` that returns every `a-expr` body that satisfies
   `(== (f 6) $target)` for target `7`. Report how many of your candidates hit the
   integer-division cliff from the fact sheet (`(/ 6 2)` truncation is fine here;
   `(/ 7 2)` is where intuition dies).
5. Read `trueagi-io/chaining`'s README only for the *shape* of its search: it
   names backward, forward, iterative and dependent-typed chaining, plus a
   probabilistic variant. Pick one, and say in writing which of your four rules
   from task 4 you would replace to express it. (Reading target, not code to
   copy — the repo is a design document more than a library.)
6. Self-test everything: `!(assertEqual (find) 3)`,
   `!(assertEqualToResult (solves …) (…))`, and one assertion *about* the search
   space — `!(assertEqualToResult (a-num) (1 2 3))` pins the candidate set, which
   is the cheapest regression test you will ever write.

Recall cards (1/3/7/21):

- What does `&self` resolve to inside a module?
- Three catalog locations, in resolution order, on Linux.
- Why can't a library read the caller's space, and what do you do instead?
- `Empty` vs `()` in a search filter.
- What changes between searching numbers and searching programs?

## Ship it

Friday: `rover_pkg/` importing cleanly from the repo root, `enumerate.metta`
finding at least one arithmetic program by search, and the two error strings pasted
as comments where they happened. If `!(import! …)` still surprises you, do task 1
again from a different directory until it doesn't. Next is
[L4 — uncertainty and agency](./ch10-l4-uncertainty-and-agency.md): the search you
just wrote becomes a decision, because candidates get scores instead of verdicts.
