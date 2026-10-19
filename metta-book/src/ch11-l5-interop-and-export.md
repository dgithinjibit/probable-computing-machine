# L5 — Interop and the export bridge

Everything so far runs inside the MeTTa bubble. L5 pokes three holes in it, and
each one is a skill you need for a different part of the plan: grounded Python
when a library exists in the host and not in MeTTa; `json`, `fileio` and `random`
when the rover has to hand data to something that is not MeTTa; and minimal MeTTa
when you want to *control* evaluation instead of submitting to it — which is the
prerequisite for the thing you actually said you want to build: a compiler with a
MeTTa front end and a target back end.

Friday artifact: `bridge.metta` — reads a JSON world description from disk, runs
a Python-backed function over it, writes a THRML-shaped JSON file, and asserts
the round trip.

## Syntax

The three builtin modules import bare, into a space token, and their functions
are then callable — this is the verified form on 0.2.10 (`@metta::json` is
rejected as an invalid module name format):

```metta
!(import! &self json)
!(import! &self fileio)
!(import! &self random)

!(json-encode (dict "mode" "driving" "trail" (1 2 3)))
!(json-decode "[1, 2, 3]")            ; (1 2 3)
!(file-open! "/tmp/day.json" "wc")
!(json-decode (file-read-to-string! $h))
```

Grounded Python comes in through `py-eval!` / `py-file!` / `py-atom`, and
`py-atom` is the one you want because it carries a type:

```metta
!(py-atom py-sqrt (-> Number Number))
!(let $f py-sqrt ($f 9.0))
```

The `let` is not decoration. `!(py-atom …)` *returns the grounded atom*; calling
it directly in one expression is how I lost twenty minutes to a "function that
won't run". Bind it, then call the binding.

Minimal MeTTa is the second syntax layer, and the spec is explicit that it is not
a separate language — "Minimal MeTTa related atoms are listed here because while
they are not a part of the standard library they are still recognized and
evaluated by the MeTTa interpreter", and, more strikingly, "It is possible to
implement MeTTa interpreter in minimal MeTTa and HE interpreter is implemented in
this way." The instruction set you can use today, from the spec's list:

```metta
!(eval (+ 1 2))                         ; one reduction step
!(evalc (+ 1 2) &some-space)            ; one step, in a given space
!(chain (double 3) $r (+ $r 1))         ; run, bind result, run template
!(unify (p 1) (p $x) yes no)            ; unification as a value
!(cons-atom f (1 2))                    ; (f 1 2)
!(decons-atom (f 1 2))                  ; head and tail
!(car-atom (1 2 3))                     ; 1
!(cdr-atom (1 2 3))                     ; (2 3)
!(function (return 42))                 ; 42
!(collapse-bind (double $x))
!(metta (+ 1 2) %Undefined% &self)
!(context-space)
```

`call-native` completes the spec's list and is deliberately out of reach: it
"cannot be called from a MeTTa program, but it can be returned by a grounded
function for the further evaluation" — which is exactly how a grounded atom gets
to run Rust on your behalf.

## Semantics

**`eval` is one step and `chain` is one binding.** The spec describes `eval` as
"makes one step of the evaluation" and `chain` as "interpret `<atom>` and
substitute `<var>` in `<template>` by the result of the interpretation". Those
two sentences are the difference between a metacircular interpreter and a script.
The other half of the honesty is the optimization in `metta`: an expression
already marked evaluated returns unchanged, so `!(eval (eval x))` is not the same
program as `x` typed twice, and re-evaluating a printed result never advances it.
If you ever write a fixed-point loop with `eval`, this is what will bite; the
working loop shape is `chain`, because `chain` binds the value it just computed.

**`unify` turns matching into data.** Everything from
[L1](./ch02-00-atoms-and-expressions.md) onward used matching implicitly, in
`match` patterns and rule heads. `unify` exposes it as a function returning
bindings, which is what a type checker, a pattern-directed rewriter, or a
theorem-prover step needs. `collapse-bind` and `superpose-bind` do the same for
the result set: pack the continuations, and resume from where packing stopped.
You now have the primitives to write MeTTa that runs MeTTa — and the spec's
`metta` instruction ("evaluate `<atom>` in MeTTa interpreter using `<space>` as a
context and expecting result with `<type>`") is the last one, which means the
interpreter is *reachable* from inside the language.

**Atoms-as-data is the transpiler's front end.** `decons-atom`, `cons-atom`,
`car-atom`, `cdr-atom` and `atom-subst` let you take `(+ (* 2 $x) 3)` apart and
put it back different. Verified on this build: `!(cdr-atom (1 2 3))` → `(2 3)`,
`atom-subst` substitutes into a template and gives `3` for the toy case, and
`collapse-bind` on a definition returns the pattern-with-bindings form
(`((double $x) { })`). Add `noeval` and `quote`/`unquote` to that and you can
hold an unevaluated program in a variable — which is the one thing
[L1 Unit 4](./ch05-00-evaluation-and-results.md) told you the `Atom` type was for.
So the compiler front end is real and available today.

**What the front end does *not* give you is a back end.** This is the part of the
plan that deserves a straight answer rather than a chapter. MeTTa has no code
generator, no FFI-to-bytecode path, no `compile --target x`. What it has is:
programs as atoms, `unify` for pattern-directed rewriting, `json-encode` and
`file-write!` for emitting text, and `py-atom` for anything the host can do. A
"MeTTa→THRML compiler" on this stack is therefore a *defunctionalised
lowering*: match MeTTa shapes into THRML-shaped atoms, then `json-encode` them to
a file the simulator reads. That is a real, shippable thing — and it is a
transducer, not a compiler, and you should call it that in your README until the
day the target needs register allocation or scheduling, at which point the gap
between the two words becomes the project.

**What THRML actually is, as of today.** In Extropic's own repository the name
expands to *Thermodynamic Hypergraphical Model Library*, and the surface is Python
and JAX rather than assembly: `SpinNode` for one probabilistic bit, `Block` for a
group of them, `IsingEBM(nodes, edges, biases, weights, beta)` for the energy
function, `IsingSamplingProgram(model, free_blocks, clamped_blocks)` for what may
update together, and a `SamplingSchedule(n_warmup, n_samples, steps_per_sample)`
handed to `sample_states(...)` (Apache-2.0, `pip install thrml`, Python ≥ 3.10).
Execution is block-Gibbs sampling; the library's own "compile" step only folds
factor definitions into a compact global array form. Extropic's write-up on the
silicon path describes stochastic kernels (Torx) → Thermalizers → "a directed
graph of THRML models that maps directly onto our hardware", with a
GPU-simulation API available now and Z1 hardware access scheduled for 2027.

That changes what the bridge should emit: **not instructions, a graph
description** — node ids, `[node node weight]` edges, a bias per node, a `beta`, a
partition into free and clamped blocks, and a schedule. Every one of those is
naturally an atom, which is the whole reason MeTTa is a decent front end for it:

```metta
(node n-7)
(edge n-7 n-12 -1.0)
(bias n-7 0.0)
(block free (n-7 n-12))
(param beta 1.0)
```

`lower` enumerates them the way [L3](./ch09-l3-modules-and-search.md) enumerates
candidates, `json-encode` with deliberately *string* keys writes the file, and a
thirty-line Python emitter rebuilds `IsingEBM(...)` from that JSON and calls
`sample_states(...)`. MeTTa holds the model and the search; JAX holds the sampler.
Two limits belong in the same README, stated before anyone asks: every number you
can produce on your own machine is a *simulation* number, and the headline claim
you will read upstream ("up to 10,000× over GPUs") comes from their papers and
their own simulation comparisons, with the methodology not spelled out on the
page — you may cite it, you may not repeat it as your measurement.

**The genre exists, and it is small.** Public MeTTa transpilers to look at:
`trueagi-io/metta-morph` (MeTTa → Chicken Scheme), `MesTTo/MeTTaScript`,
`MesTTo/MeTTa-LSP`, and learner-grade Python emitters of the `metta_2_py` shape
(including one already in this folder). None of them targets a hardware IR. Read
`metta-morph` to see how someone else decided where to stop: it translates to an
existing Scheme rather than inventing a backend, which is the same economy that
makes JSON your target. Read `MesTTo/MeTTa-LSP` to see the parser-side work a
real toolchain needs.

**`json` is strict in ways MeTTa is not.** Verified here: `json-encode` of a
`dict` needs *string* keys, symbols encode with a suffix-ish form
(`"sym!:a"`), and `json-decode` of an object yields a `GroundingSpace-0x…` handle
rather than a literal structure. So an export path is: MeTTa atoms → tuples with
string keys → `json-encode` → `file-write!`. And an import path must decode into a
space you then `match`, not into a value you can destructure. Build the shape on
the MeTTa side first; `json` is the last mile, not the design.

**`fileio` gives you round-trip, and no structure.** `file-open!` with a mode
string (`"wc"` for write/create was verified), `file-write!`, and
`file-read-to-string!` round-trip a file cleanly. There is no directory walking,
no path joining, no "read a MeTTa file into this space" call in what you have.
Loading MeTTa *is* the module system — see [L3](./ch09-l3-modules-and-search.md)
and remember its working-directory rule when your bridge script starts importing.

## Exercises

| # | you type | your prediction | actually printed |
|---|---|---|---|
| 1 | `!(chain (double 3) $r (+ $r 1))` | | `7` |
| 2 | `!(eval (double 3))` | | one step |
| 3 | `!(unify (p 1) (p $x) yes no)` | | `yes` |
| 4 | `!(cdr-atom (1 2 3))` | | `(2 3)` |
| 5 | `!(cons-atom f (1 2))` | | `(f 1 2)` |
| 6 | `!(json-decode "[1, 2, 3]")` | | `(1 2 3)` |
| 7 | `!(json-encode (dict "k" 1))` | | `{"k":1}` |
| 8 | `!(json-encode (dict k 1))` *(symbol key)* | | an error or a mangled key |
| 9 | `!(py-atom py-sqrt (-> Number Number))` then `!(let $f py-sqrt ($f 9.0))` | | `3.0` |
| 10 | `!(metta (+ 1 2) %Undefined% &self)` | | `3` |

Tasks:

1. Write `(lower $x)` that pattern-matches a *tagged* arithmetic program into an
   instruction tree: `(num 2)` → `(:mov r0 2)`, `(var x)` → `(:ld x)`,
   `(mul $a $b)` → `(:mul (lower $a) (lower $b))`, same for `add`, over
   `(prog (add (mul (num 2) (var x)) (num 3)))`. One rule per shape and **no
   catch-all leaf rule**: a generic `(= (lower $x) …)` overlaps the op rules,
   calling is querying, every matching rule is explored, and the one program then
   answers with fourteen results (verified; this is exercise 33). Assert exactly
   one result, and find out what an op with no rule produces — it is neither an
   error nor silence.
2. Export it: `lower` → `json-encode` (with string keys, built deliberately) →
   `file-write!` to `/tmp/plan.json`. Then read it back with
   `file-read-to-string!` and `json-decode`, and assert whatever the decode
   actually returns rather than what you hoped.
3. Round-trip the [L4](./ch10-l4-uncertainty-and-agency.md) KB: dump
   `(Inheritance a b (stv 0.7 0.8))` atoms to JSON lines, reload them into a fresh
   `&kb` with `add-atom`, and prove `!(believe "off-line")` answers the same
   number. Write down the representation you chose for `stv` and why.
4. Write `(run-in $space $expr)` in terms of `!(metta …)` and `evalc`, and show a
   program that evaluates a candidate expression in the *rover's* space rather
   than the top one. This is the interpreter-as-library exercise; it is also the
   honest first draft of a test harness.
5. Read `metta-morph`'s README and one source file, then write five sentences:
   what it maps, where it had to invent, and what it would take to point the same
   machinery at your JSON target. Do not copy code.
6. Fix a number in `bridge.metta` on purpose — a `(:mov)` that should be `(:mul)`
   — and make your own assertion catch it. The point is that the *emitted file* is
   under test, because that is the artifact the simulator consumes.
7. Emit the **graph**, not the instructions. Store `(node …)`, `(edge a b w)`,
   `(bias a b)`, `(block free (…))` and `(param beta 1.0)` atoms in a space,
   enumerate them the L3 way, `json-encode` with string keys, and write
   `/tmp/ebm.json`. Then write the ~30-line Python side that reads that JSON and
   builds `IsingEBM(nodes, edges, biases, weights, beta)` plus an
   `IsingSamplingProgram` with your free/clamped split, and run one
   `sample_states(...)` call. Your deliverable is the round trip: atoms → JSON →
   JAX sampler → states back into a MeTTa space with `add-atom`. (Do not claim an
   energy number you did not measure; you are measuring a simulator.)

Recall cards (1/3/7/21):

- `eval` vs `chain`: what does each bind?
- Why does the interpreter's "already evaluated" optimization matter to a
  fixed-point loop?
- Which four atoms make a MeTTa program inspectable as data?
- The three verified `json-encode` constraints.
- Why is your MeTTa→THRML path a transducer, and what would make it a compiler?

## Ship it

Friday: `bridge.metta` plus the emitted `/tmp/plan.json`, the round-trip
assertions, and a README paragraph titled "why this is a transducer". Then stop
and reread [L0](./ch01-l0-imitation.md): you are now the person who can answer
its gate questions with mechanism instead of imitation, which is the point of the
order we went in. Next is [L6 — the capstone](./ch12-l6-capstone.md).
