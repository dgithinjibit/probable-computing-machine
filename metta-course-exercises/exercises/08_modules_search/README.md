# Exercise 28 — Modules, by hand (manual lab)

Book: `metta-book/src/ch09-l3-modules-and-search.md` (L3)

This is the one exercise in the set that `check-solutions.sh` cannot run, and the
reason is a real property of the runtime rather than a gap in the exercise:
`import!` resolves a module name against the **current working directory**, not
the directory of the file being run. From any other directory the call fails with

```
(Error (import! &m sibmod) Failed to resolve module top:sibmod)
```

So run it on purpose, and read the failure:

```bash
cd /home/skware/Desktop/ex/exercises/metta-course-exercises/exercises/08_modules_search
metta user.metta            # works
cd /tmp && metta /home/skware/Desktop/ex/exercises/metta-course-exercises/exercises/08_modules_search/user.metta   # fails
```

## What to build

1. Fill in `world.metta` so the module exports `(adjacent $a)` and `(rooms)`,
   with the facts living in the module's own space.
2. Make `user.metta` import it and call both, without re-declaring any fact.
3. Prove you understand `&self`: inside `world.metta`, `(match &self …)` means the
   *module's* space. In `user.metta`, `&self` means the script's. Add a query in
   each file that demonstrates the two are different, and write the output down.
4. Break it once, deliberately: reference a fact from the module that only exists
   in the client. Note the error, then fix it the way L3 says to — pass the space
   as an argument, because modules cannot have upward dependencies.

Expected `user.metta` output when run from its own directory: the room names, and
one line per `adjacent` answer. If you see silence, the import did not happen or
the head symbol of your pattern is wrong. Both are normal; only one is your fault.
