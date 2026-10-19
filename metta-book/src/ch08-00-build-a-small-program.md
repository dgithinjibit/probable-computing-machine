# L2 · Unit 2 — Build a small program

Time to write one file that is actually a program: it holds data in named
spaces, mutates state, answers questions, checks itself, and survives being run
by a stranger. Everything from L1 and the previous unit gets used, and the gaps
you feel here are exactly the ones L3 fills in (modules) and L4 fills in
(uncertainty). This is also the first unit whose artifact is something you will
still be running in six months.

Friday artifact: `daylog.metta` — a driving day: percepts in, decisions out, a
trail, a summary, and a self-test section that fails loudly if you break it.

## Syntax

A program in MeTTa is a set of spaces plus rules that cross between them. The
skeleton you will reuse for the rover:

```metta
; --- spaces: one per concern ---
!(bind! &percepts (new-space))
!(bind! &world    (new-space))
!(bind! &log      (new-space))

; --- populate: facts go in as atoms ---
!(add-atom &world (room kitchen))
!(add-atom &world (connects kitchen hall))
!(add-atom &percepts (ultrasonic-front 120))

; --- state: the mutable bit ---
!(bind! &mode (new-state idle))

; --- rules that read across spaces ---
(= (danger?)
    (match &percepts (ultrasonic-front $d) (if (< $d 30) True False)))

; --- and mutate ---
(= (set-mode! $m) (change-state! &mode $m))
!(set-mode! driving)
!(get-mode)
```

Note the shape: `danger?` *queries a named space* rather than `&self`. That is
the difference between a script and a program — the data has an address, so it
can be reloaded, swapped, or shared later
([L3](./ch09-l3-modules-and-search.md) modules,
[L6](./ch12-l6-capstone.md) capstone).

List-shaped accumulation across steps, using the recursion from
[Unit 1](./ch07-00-lists-and-recursion.md):

```metta
(= (record-trail! $spot)
    (let $old (get-state &trail)
      (change-state! &trail (:: $spot $old))))
```

Self-tests at the bottom, always:

```metta
!(assertEqual (danger?) False)
!(assertEqualToResult (match &world (connects kitchen $r) $r) (hall))
```

## Semantics

**`add-atom` answers `()` and so does `bind!`.** From the fact sheet, verified on
this build: `!(bind! &kb (new-space))` → `()`, `add-atom` → `()`, `remove-atom`
→ `()`, `get-atoms &kb` → the atoms, `match &kb …` → data. The one exception
that will bite you: `!(get-atoms &self)` prints *nothing*. There is no way to
dump the top space through that call on 0.2.10, and `!&` (documented as
"evaluate and keep the result") is not parsed at all — the line comes back as
data. So if you want a space you can inspect, make it a named one. That is a
design constraint, not a preference: **named spaces are introspectable, the top
space isn't.**

**Atoms in a space are a multiset with set semantics you must respect.** Adding
the same atom twice does not create two rows for `match` to find, and it will
not warn you. Removing is by exact atom, not by key, so
`remove-atom &percepts (ultrasonic-front $x)` with a variable is not a delete
operation — variables in a stored *pattern* position get the
[bare-variable](./ch02-00-atoms-and-expressions.md) treatment. The rover idiom
for "one reading per sensor": `remove-atom` the exact old atom you remembered,
or keep the reading in *state* as a list and let `change-state!` replace it.

**`change-state!` inside a rule body is a side effect that ordering controls.**
Because the interpreter is atom-by-atom and each atom sees the previous atom's
effects, a rule whose body mutates can be evaluated more than once if it is
nondeterministic — [Unit 4](./ch05-00-evaluation-and-results.md)'s multiplication
rule applied to a mutation is a double-apply. Guard mutations behind a single
deterministic rule, and prefer the stdlib's own pattern of pairing the update
with `nop` when sequencing matters. If a counter is going up by two, the cause
is almost never `change-state!` and almost always two matching rules.

**Type discipline pays off exactly here.** A state created as `(new-state idle)`
holds symbols; `change-state!` with a list, or `get-state` after a type change,
produces a type error rather than a surprise value. Multi-space programs fail
mostly at these seams, and `(: …)` signatures on your crossing rules are what
catch it — see [Unit 5](./ch06-00-types-and-errors.md)'s "the caller checks the
return type".

**A program that can't be run twice isn't one.** Because loading a file stores
atoms, running `daylog.metta` twice in the same session doubles nothing (each run
gets a fresh top space) — but if you ever move the data into a module-level space
and `import!` it, re-import semantics start to matter, and the
`import!`-resolves-against-the-*current-working-directory* rule from
[Getting started](./ch00-getting-started.md) will decide whether your tests pass
from `/tmp` or only from the project root. Keep paths absolute or keep the CWD
honest. This is the trap that makes "works on my machine" literal in MeTTa.

**Errors should be data in your program, not console noise.** A rover that
meets an unknown sensor should return `(Error …)`, per the spec's sanctioned
constructor, so the decision layer can see the failure as a value:

```metta
(= (reading $s) (match &percepts ($s $v) $v))
(= (reading $s) (Error (reading $s) NoReading))
```

The second rule is the "no match" branch, written as a rule — since `match`
silence and `Error` are different things, and only one of them is reportable.
(Nondeterminism note from [Unit 3](./ch04-00-functions-and-pattern-matching.md):
if the first rule succeeds, both are still explored. Read the result set, don't
assume the first rule "wins" — or guard with a single rule that decides inside.)

## Exercises

Build `daylog.metta` in five increments. After each increment, run it and
compare against your written prediction before moving on.

1. **World.** Three spaces (`&world`, `&percepts`, `&log`), ≥6 rooms, ≥8
   connections, ≥5 sensor readings. Dump each with `!(get-atoms &…)` — and write
   one sentence on why the same call against `&self` printed nothing.
2. **Cross-space questions.** `danger?`, `(nearest-obstacle)`,
   `(rooms-from $start)` (one hop, via `match &world`), and `(route2 $a $c)`
   (two hops, accumulated as a `::` list — carry the path over from
   [Unit 1](./ch07-00-lists-and-recursion.md)'s task 6).
3. **Mode machine.** `&mode` state with `idle/driving/charging`, a
   `(tick!)` rule that reads `danger?`, sets mode, and appends to `&log`. Prove
   one `tick!` moves state exactly once (this is where double-matching rules
   reveal themselves).
4. **Summary.** A `(report)` that returns a tuple
   `(report $mode $readings $events)` and a recursive `events-of-type` over the
   trail. Add the integer-division average of ultrasonic readings and a comment
   stating what `(/ …)` did to the fraction.
5. **Self-test.** At least six `assertEqual`/`assertEqualToResult` lines: the
   `route2` path, the `danger?` verdict, one `get-atoms` shape, the mode after
   one `tick!`, the `Error` branch for an unknown sensor, and the average. Then
   break one fact deliberately and confirm the assertion catches it — and put the
   fact back.

Finally, the oral exam, in writing, five sentences:

- Why does a rule belong to a *space* and not to a *file*?
- What prints for a `match` with no results, and what prints for `add-atom`?
- Where does `danger?` get its value from, in spec terms? (`metta_call` →
  `query(space, (= atom $X))` → the body is a `match` on `&percepts`.)
- What breaks if the same `(= (tick!) …)` rule is written twice?
- What breaks if you run the file from `/tmp` after switching data into a module?

Recall cards (1/3/7/21):

- Three named spaces, one state — which is `get-atoms`-able?
- `remove-atom` matches by ____, not by key.
- How do you write a "no match" branch in MeTTa?
- What is the only introspection you get on the top space?
- Name the two assertion forms and what each compares.

## Ship it

Friday: `daylog.metta`, run from a clean shell, with all assertions passing and
the five-sentence oral exam answered in the file header as comments. Then read
`trueagi-io/metta-examples`' `aunt-kg/` (kinship graph with a `json_to_metta.py`
loader) purely to compare structure with yours — you are not copying it, you are
checking whether a mature example keeps its data in a named space too. It does,
which tells you the shape you picked is the shape the library expects.

Next is [L3 — modules and search](./ch09-l3-modules-and-search.md): splitting
`daylog.metta` into files that can be imported, and then using rule enumeration
to search over programs instead of writing one by hand.
