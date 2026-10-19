# The MeTTa Language

A beginner-friendly, code-first book for learning MeTTa from local runnable
examples. The chapters cover syntax, atoms, facts and queries, functions,
evaluation, types, lists, recursion, and a small capstone program.

Start with [`src/SUMMARY.md`](src/SUMMARY.md). Runnable examples are in
[`listings/`](listings/), and `verify-offline.sh` runs every listing through
the local `metta` command.

After reading a chapter and running its listing, continue with the linked
[`MeTTa exercise track`](../metta-exercises/README.md) for write-it-yourself
problems and separate solutions.

## Preview the book locally

From the exercises root, run:

```sh
mdbook serve metta-book --hostname 127.0.0.1 --port 3000
```

Open [http://127.0.0.1:3000](http://127.0.0.1:3000); press `Ctrl+C` to stop.
For the combined portal and all generated course books, run
`./serve-site.sh` from the exercises root and open
[http://127.0.0.1:8000](http://127.0.0.1:8000).

See the offline appendix for runtime details and the
[`MeTTa exercise track`](../metta-exercises/README.md) for the complete
write-it-yourself sequence.