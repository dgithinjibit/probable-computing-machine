# Portal integration (what was changed outside this folder)

This course lives inside the local learning lab at `~/Desktop/ex`. Three files
outside the folder were touched; reproduce them if you re-apply this elsewhere.

## `exercises/serve-site.sh`

`ml-hybrid` added to the mdBook build loop, so `./exercises/serve-site.sh`
rebuilds it alongside the other books:

```bash
for book in developer-path ml-hybrid education-book robotics-book rust-book \
            metta-book wolfram-book cairo-book; do
```

## `exercises/developer-path/src/SUMMARY.md`

One line under Day 1:

```markdown
- [ML Hybrid Course (books split into days)](http://127.0.0.1:8000/ml-hybrid/hybrid-course.html)
```

## `exercises/developer-path/src/index.md`

A **Hybrid book courses** section before “Existing offline smart-contract
materials”, linking the course page and pointing at `build_course.py` for new
branches.

The 421-day developer path keeps its own storage key
(`local-learning-lab.developer-path.v1`) and its own progress. This course uses
`local-learning-lab.ml-hybrid.v1`, so neither can wipe the other.
