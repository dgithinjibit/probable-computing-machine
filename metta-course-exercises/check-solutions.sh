#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EX_ROOT="$(cd -- "$ROOT/.." && pwd)"

if ! command -v metta >/dev/null 2>&1; then
    printf 'metta command not found; install or provide the local runtime first.\n' >&2
    exit 127
fi

while IFS= read -r -d '' solution; do
    relative="${solution#"$EX_ROOT"/}"
    printf 'Checking %s\n' "$relative"
    if ! output="$(timeout --foreground 15s metta "$solution" 2>&1)"; then
        printf '%s\n' "$output" >&2
        exit 1
    fi
    if grep -Fq 'Error (' <<<"$output"; then
        printf '%s\n' "$output" >&2
        printf 'Assertion failed in %s\n' "$relative" >&2
        exit 1
    fi
done < <(find "$ROOT/solutions" -type f -name '*.metta' -print0 | sort -z)

printf 'All MeTTa exercise solutions passed.\n'
