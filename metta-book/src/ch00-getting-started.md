# Getting started on this machine

Open a terminal at the `ex` root and check the three things the course needs.

```bash
source ./offline-env.sh
command -v metta
metta --help
```

Expected, on this laptop:

```
/home/skware/.local/bin/metta
usage: metta_cli.py [-h] file [expression]

Run a MeTTa source file.
```

`metta` here is a small wrapper around the Hyperon **Python** runtime, version
0.2.10, installed into your user site-packages. Confirm the version with the
interpreter underneath the wrapper, because the wrapper itself has no
`--version` flag:

```bash
python3.12 -m hyperon.metta --version
```

## What the tooling can and cannot do

**There is no REPL.** The wrapper takes a file and, optionally, one extra
expression evaluated after it. So the workflow is edit-run-read, and the way to
stay fast at it is a small file and the shell's up-arrow, not a listener.

```bash
metta exercises/metta-book/listings/l1-01-first-steps.metta
metta exercises/metta-book/listings/l1-01-first-steps.metta "!(double 9)"
```

**`import!` resolves against your working directory, not the file's.** This is
the single most common way to lose an hour. A module file `sibmod.metta` sitting
next to the script that imports it will fail if you run the script from
somewhere else:

```bash
cd /tmp && metta /path/to/usesib.metta
# (Error (import! &m sibmod) Failed to resolve module top:sibmod)
```

Run from the directory that owns the module, or address a subdirectory with
colon syntax (`pkg:inner` for `pkg/inner.metta`). The `dir:sub:name` form is how
the upstream test suite organises multi-file examples.

**The `!` prefix is the whole difference between storing and running.** A
top-level atom with no `!` is added to the current space; with `!` it is
evaluated and its results are shown. No `!` inside an expression — `!` is only
meaningful at the start of a top-level atom, so `!(let $x 1 !(print))` is not
what you think it is.

**`!&` does not work in this build.** The upstream docs list `!&` as "evaluate
and keep the result in the space", but here the parser does not accept it as a
prefix: `!& (+ 1 2)` comes back echoed as the atom `!& (+ 1 2)` rather than
being run. `!(get-atoms &self)` likewise prints nothing. Verified 2026-10-19.
Use an explicit `!(bind! &s (new-space))` plus `add-atom` when you want a space
you can inspect later.

**Some things you will read about online are not in this build.** Verified
absent on 0.2.10 here: `!=`, `sqrt`, `abs`, `sum-atom`, `pr::println`, and
`filter-atom` (it is declared but never returns; write `filter` yourself, as
[L2 Unit 1](./ch07-00-lists-and-recursion.md) does). `min-atom` and `max-atom` exist but
answer as floats. `/` on two integers is integer division, so `(/ 7 2)` is `3`.

## Checking the whole course

From the `ex` root:

```bash
bash exercises/metta-book/verify-offline.sh
```

It runs every `.metta` file in `listings/`, stops at the first non-zero exit,
and additionally fails if any output contains an error atom. That is why several
listings show a bad call as a commented line instead of a live one: the file
must stay green, and the chapter text carries the broken output.

## Reading the book locally

```bash
./serve-site.sh
```

then <http://127.0.0.1:8000/>. mdBook 0.5.4 is vendored under `tools/`, so this
works with no network. The chapters are ordinary Markdown and read fine in VS
Code with no build step; the syntax highlighter is optional
(`Amanuel-1/metta-language-support-pack`).

## The habit that makes this work

Keep one scratch file, run it, and never trust an un-run line. When you want to
know what a construct does, ask the machine instead of reasoning about it: put
the experiment in `scratch.metta`, run it, read the output, delete it. The
wrapper will not read from a pipe or from standard input, so the file *is* the
REPL. `listings/l0-01-drills.metta` is that kind of file raised to a standard,
and it is the first thing you should type rather than open.
