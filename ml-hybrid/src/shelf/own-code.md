# Your own code in `~/Desktop/ML/codes/`

_The folder is not reference material - it is the practice side of this course. Several
days name specific files in it, so this page records what is there and what each file
is currently good for._

| Path | What it is | Days that use it |
|---|---|---|
| `age.py` | Smallest working script in the folder. | Day 30 - the starting point for `spec_agents.py`. |
| `mean.py`, `mssing_data_filler_mean.py` | Mean-value imputation of missing data, done twice. | Day 34 - write the paragraph on what the data must look like for this to be correct. |
| `frame.py` | DataFrame loading. | Days 41, 47, 61 - the data source for the smallest network, the one-feature regression, and the four-step pipeline. |
| `data_visualization.py` | Plotting path. | Day 41 - read the loss curve before you trust the number. |
| `jup.py` | Notebook-derived script. | Day 45 - add the schema check, the warning line, and the log. |
| `mdlr/arithmetic.py` | Arithmetic rules encoded explicitly. | Day 54 - the toy version of symbolic inference. |
| `myvenv/` | Your local virtual environment. | Never a study object. Do not delete it; do not grow it. |
| `curriculum/README.md`, `curriculum/01-python-foundations.md` | The from-zero CS guide you already wrote, pointing at `dgithinjibit/computer-science` and OSSU. | Days 32, 36, 40, 51, 53, 59 - where the new days' notes and checklists go. |

## The rule that keeps this honest

Every practice field in the spine points at a file that exists. If a day asks for
something not listed here, that is a bug in the day, not in you - say so in the log
and use the nearest real file.

`run_tests.py` exists in `ml-exercises/`, `python-exercises/` and `security-exercises/`.
Running it at the end of a day is the cheapest possible proof that today's code did not
quietly break last week's.
