#!/usr/bin/env bash
set -euo pipefail

BOOK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_ROOT="$(cd -- "$BOOK_DIR/../.." && pwd)"
source "$BUNDLE_ROOT/offline-env.sh"

if ! command -v metta >/dev/null 2>&1; then
    printf 'metta command not found; install or provide the local runtime first.\n' >&2
    exit 127
fi

for example in "$BOOK_DIR"/listings/*.metta; do
    printf '\n==> %s\n' "${example#"$BUNDLE_ROOT"/}"
    if ! output="$(metta "$example" 2>&1)"; then
        printf '%s\n' "$output" >&2
        exit 1
    fi
    printf '%s\n' "$output"
    if grep -Fq 'Error (' <<<"$output"; then
        printf 'MeTTa evaluation error in %s\n' "${example#"$BUNDLE_ROOT"/}" >&2
        exit 1
    fi
done

printf '\nAll MeTTa book listings completed successfully.\n'