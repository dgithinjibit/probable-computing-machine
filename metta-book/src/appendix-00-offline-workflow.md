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
- The installed `metta` command successfully ran all 16 solution files in
  `exercises/metta-course-exercises/solutions/`; the starter files are intentionally
  incomplete.
- mdBook 0.5.4 is installed locally. From the `ex` directory,
  `./serve-site.sh` builds both book sites and serves the course portal at
  <http://127.0.0.1:8000>.

If a runtime command is missing on another machine, install or provide that
runtime before attempting to execute the examples. This bundle's offline
setup script adjusts paths; it does not install the MeTTa runtime.