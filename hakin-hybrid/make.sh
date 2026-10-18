#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
python3 build_course.py inventory --library "$1"
python3 build_course.py build
if [ -x ../../tools/mdbook/bin/mdbook ]; then ../../tools/mdbook/bin/mdbook build; fi
