# Appendix: Offline Workflow

The examples in this book are local files. Once the MeTTa runtime is installed
on the machine, running them does not need a blockchain, RPC endpoint, web
service, or package download.

From the bundle root:

```bash
source ./offline-env.sh
bash exercises/metta-book/verify-offline.sh
```

The verification script runs every `.metta` file in this book's `listings/`
directory and stops on a failing command. Existing practice files are in
`exercises/metta-course-exercises/` and can be run the same way, including filenames
with spaces by quoting the path.

## What is local on this machine

- The `metta` executable resolves to `~/.local/bin/metta`.
- The current bundle setup sets `CARGO_NET_OFFLINE=true` for Rust/Cargo work.
- The installed `metta` command runs all 33 files in
  `exercises/metta-course-exercises/solutions/` and all 17 in this book's
  `listings/` without an `Error (` line (swept 2026-10-19); the starter files are
  intentionally incomplete, so they are not expected to pass.
- `check-solutions.sh` stops at the first failure, which is what you want in a
  gate and not what you want in a survey. To see *every* failure at once, loop
  over the files yourself and keep going:

  ```bash
  cd ~/Desktop/ex/exercises
  for f in $(find metta-course-exercises/solutions metta-book/listings -name '*.metta' | sort); do
    out=$(timeout 20s metta "$f" 2>&1)
    grep -qF 'Error (' <<<"$out" && { echo "FAIL $f"; grep -F 'Error (' <<<"$out" | head -2; }
  done
  ```

  That loop is how this appendix's fact sheet got its corrections: the gate had
  been passing on the first file for an hour while nine later files were wrong.

- mdBook 0.5.4 is installed locally. From the `ex` directory,
  `./serve-site.sh` builds both book sites and serves the course portal at
  <http://127.0.0.1:8000>.

## PeTTa: a second MeTTa, for when hyperon surprises you

`~/Desktop/ex/exercises/peTTa` is a vendored clone of
`trueagi-io/PeTTa` (MIT) — an efficient MeTTa implementation *written in Prolog*,
maintained and active as of this month. It is not a debugger and it is not a drop-in
replacement: it is a second opinion. Three things make it worth the 4 MB:

- It typechecks `(: f (-> A B))` **at compile time**, and its `--strict` mode
  rejects overlapping clauses for a deterministic function. That is exactly the
  bug class this book found in its own lowering exercise (one program, fourteen
  answers), and PeTTa refuses to compile it rather than printing fourteen.
- It ships `examples/repl.metta`; the hyperon wheel on this machine has no REPL,
  so this is the closest thing to one.
- Load order is semantic in it, and it errors when a later file cannot
  retroactively inform an earlier one — a sharper statement of the
  module-resolution trap in [L3](./ch09-l3-modules-and-search.md).

Running it needs SWI-Prolog ≥ 9.3, which is not installed here. The privileged
step belongs in your terminal, not in an agent:

```bash
sudo apt install swipl          # or the portable build from swi-prolog.org
```

Then run one small example at a time — and do **not** run its `test.sh` on a 4 GB
laptop, it fans out eight SWI instances with 3 GB stacks by design:

```bash
cd ~/Desktop/ex/exercises/peTTa
PETTA_STACK_LIMIT=512m sh run.sh ./examples/nars_tuffy.metta
```

If a PeTTa answer disagrees with a hyperon answer, one of them is a bug, and the
disagreement is a reportable artifact — check the spec section in
[Appendix: the verified fact sheet](./appendix-01-verified-facts.md) first, then
file it against whichever side is wrong.

If a runtime command is missing on another machine, install or provide that
runtime before attempting to execute the examples. This bundle's offline
setup script adjusts paths; it does not install the MeTTa runtime.