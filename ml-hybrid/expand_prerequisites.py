"""One-time spine expansion: prerequisite Phase 0 + the Géron traditional-ML block.

Run once from `ml-hybrid/`. It renumbers the existing 63 days, rewrites every
authored day cross-reference with the same map, inserts 17 prerequisite days at
the front (8 Python-from-zero, 9 mathematics-from-zero) and 5 Hands-On ML days
after the old consolidation day, then records the old->new table in
`course.day_shift` so the learner UI can move stored tick marks with their days.

    old 1-16  -> +17   (Days 18-33)
    old 17-63 -> +22   (Days 39-85)
    new       -> Days 1-17 (prerequisites) and Days 34-38 (Géron)

Total after the run: 85 days. Page anchors were verified against the engine's own
`make_bite`, so each new day lands inside the 180-560 word sitting.
"""
import json
import re

SRC = "hybrid-curriculum.json"

PY = "Python from zero"
MATH = "Mathematics for ML"
CLASSIC = "Traditional ML, in code"


def day(n, track, book, first, last, title, idea, recall, misc, practice, check, gate):
    return {"day": n, "track": track, "book": book, "from": first, "to": last,
            "title": title, "idea": idea, "recall": recall, "misconception": misc,
            "practice": practice, "check": check, "gate": gate}


PRE = [
    day(1, PY, "pyqinst", 15, 24,
        "Why Python is chapter one of this course",
        "Python is the machine you will think in for the next 84 days: an interpreter you can type "
        "at, a standard library that already contains most of what you need, and no compile step "
        "between an idea and a result.",
        "From memory: name three things Python is used for in the books on this laptop, and one "
        "thing it is not good at.",
        "Believing you must finish a whole Python book before touching machine learning. You need "
        "eight days of it, not eight weeks - and the rest you learn against a real exercise.",
        "Read `../python-exercises/README.md`, then run `python3 python-exercises/run_tests.py` from "
        "`~/Desktop/ex/exercises`. The exercises should fail with a TODO, not with an import error. "
        "That red board is your starting line, so write down which ones failed.",
        "Say out loud what an interpreter does with one line of code, and what `>>>` means. Both "
        "sentences go in your log before this day is complete.",
        "Run three lines at the Python prompt and explain what each one printed, including the one "
        "that printed nothing."),
    day(2, PY, "pyqinst", 25, 34,
        "Python as a calculator, then as a language",
        "Everything else grows out of expressions: values, operators, and the rule that a program is "
        "evaluated one statement at a time, top to bottom.",
        "From memory: the difference between an expression and a statement, and what `%` does.",
        "Believing `3 / 2` and `3 // 2` are the same, or that a large literal silently becomes a "
        "float. They are three different operators with three different answers.",
        "`../python-exercises/exercises/00_foundations/01_tip_total.py` - arithmetic, arguments and "
        "validation. Run it, make it fail, make it pass, and only then read the matching solution.",
        "Cold-write the one-sentence idea of today plus your own example of an expression that is "
        "not a statement.",
        "Compute an 18% tip on 47.35 to the cent without looking, then explain why you rounded the "
        "way you did instead of truncating."),
    day(3, PY, "pyqinst", 41, 50,
        "Variables, types, and what a name actually binds",
        "A variable is a name bound to an object that carries its own type; the four primitives "
        "(integer, float, boolean, string) cover almost all the arithmetic a model does before you "
        "reach for arrays.",
        "From memory: name the four primitive types, and one operation that changes type rather than "
        "raising an error.",
        "Thinking `x = 5` makes `x` an integer forever, or that `\"5\" + 2` is a bug in Python rather "
        "than a rule about what `+` means for strings.",
        "`../python-exercises/exercises/00_foundations/02_grade_band.py` - conditions and boundary "
        "cases. Write your own boundary table (0, 49, 50, 100) on paper before you code it.",
        "Explain in one sentence what `type()` would answer for each primitive, and why the boolean "
        "is the odd one out.",
        "Predict, then run, the type and value of six expressions you wrote yourself. Every wrong "
        "prediction becomes a repeat of this day, not a note."),
    day(4, PY, "pyqinst", 79, 88,
        "Choosing a container: list, tuple, dict, set",
        "Four built-in containers answer four different questions - order, immutability, lookup by "
        "key, membership - and most beginner bugs are a container chosen for the wrong question.",
        "From memory: which container keeps insertion order, which cannot be changed afterwards, and "
        "which one you would reach for to count words.",
        "Reaching for a list when the real question is 'have I seen this before?' - that is a set, "
        "and the list version is secretly quadratic.",
        "`../python-exercises/exercises/01_collections/04_word_counts.py`, then "
        "`05_median.py`. Both must pass on your own attempt before you open the solutions.",
        "Write the one-line rule for each of the four containers from memory, then check all four "
        "against the pages.",
        "Given a log of student scores, say which container you would use at each step and why, out "
        "loud, in under a minute."),
    day(5, PY, "pyqinst", 137, 146,
        "Control flow: the order the machine really runs things in",
        "Conditionals select, loops repeat, and the indentation *is* the block - Python has no "
        "braces, so the layout you can see is the structure that executes.",
        "From memory: what a `for` loop does on its last element, and when you would write `while` "
        "instead.",
        "Reading `if` and `for` as decoration. A loop meant to run 30 times that runs 29 is an "
        "off-by-one you can see, not bad luck.",
        "`../python-exercises/exercises/00_foundations/03_is_prime.py`, then "
        "`06_flatten.py` - recursion is control flow with a stack, and it belongs next to loops.",
        "Trace one loop by hand for n = 7, writing the value of the counter at every pass. The "
        "trace goes in your log with the code.",
        "Explain why testing divisors from 2 differs from testing from 1, and why both are still too "
        "slow past the square root."),
    day(6, PY, "pyqinst", 167, 176,
        "Functions: the unit of reusable thought",
        "A function names a piece of reasoning once so you can call it forever; parameters, a return "
        "value, and a one-line docstring are the whole interface you owe the future reader.",
        "From memory: the difference between printing inside a function and returning from it.",
        "Passing state through globals because it saves a keystroke, then finding you cannot run the "
        "same function twice and get the same answer.",
        "`../python-exercises/exercises/02_data/07_parse_scores.py` and `08_safe_int.py` - both are "
        "function-writing exercises about data you do not trust.",
        "Write the signature - name, parameters, return type - of the function you just wrote, "
        "before you look at its code again.",
        "Refactor one earlier exercise into a function that takes an argument and returns a value "
        "with no `print` inside it, and show that it still passes."),
    day(7, PY, "pyqinst", 195, 204,
        "NumPy: why machine-learning code does not use lists",
        "NumPy replaces a list of boxed Python objects with one flat typed buffer plus vectorised "
        "operations, which is why an entire column can be scaled in a single line.",
        "From memory: two things an array does that a list cannot, and one thing a list still does "
        "better.",
        "Believing you must have NumPy installed to understand the idea. It is **not** installed on "
        "this laptop and there is no pip here, so the concept is carried by the loop you write by "
        "hand - which is the point of the exercise.",
        "`../ml-exercises/exercises/00_fundamentals/02_standardize.py` - do the whole thing with "
        "plain lists first, then write the one-line vectorised version you wish you had as "
        "pseudocode in your log.",
        "Say in one sentence what 'vectorised' means, and name where the loop went.",
        "Explain to your Day 1 self why subtracting the mean works on a whole column at once."),
    day(8, PY, "pyqinst", 229, 238,
        "pandas: the table as an interface",
        "A DataFrame is a dictionary of equal-length columns with labels, and most of the "
        "data-cleaning vocabulary of machine learning - slice, join, group, fill - is a table "
        "operation rather than an algorithm.",
        "From memory: name three things you would do to a messy CSV before any model is allowed to "
        "see it.",
        "Thinking pandas is required for this course. It is not installed here; the standard-library "
        "`csv` path in `../ml-exercises` covers the same skills, and the consolidation day makes you "
        "do it that way on purpose.",
        "`../ml-exercises/exercises/00_fundamentals/01_split_data.py` - read a small CSV you write "
        "yourself with `csv.DictReader`, then split rows into train and test with a fixed seed so "
        "the split repeats.",
        "Write the three verbs (select, filter, aggregate) with one example of each taken from the "
        "code you just ran.",
        "Explain what an index is, and what goes wrong when two tables with different indexes are "
        "combined."),
    day(9, MATH, "mit42", 50, 57,
        "Logical formulas: reading a claim precisely",
        "A formula has truth values, not moods. And, or, not, implies and if-and-only-if let you "
        "write a claim once and check it mechanically - including the contrapositive you will need "
        "in every debugging session.",
        "From memory: write `p implies q` and its contrapositive, and say exactly when each is false.",
        "Reading 'if p then q' as 'if q then p'. Confusing an implication with its converse is the "
        "root of most arguments about metrics.",
        "Author a short standard-library script in your log folder that builds the truth tables for "
        "`p implies q`, `q implies p` and `not q implies not p`, then prints which columns agree. "
        "This exercise is yours, so it is the one thing on this day you may not skip.",
        "Cold-write the five connectives in symbols and in English, one line each.",
        "Take one claim from Day 8 - 'if a column is numeric then I can average it' - state its "
        "contrapositive and its converse, then say which of the two is true."),
    day(10, MATH, "mit42", 90, 97,
        "Mathematical data types: sets, sequences, functions, relations",
        "The same four objects carry all later maths: a set of cases, a sequence of measurements, a "
        "function from inputs to outputs, and a relation that may pair one input with many outputs.",
        "From memory: the difference between a function and a relation, and between a sequence and a "
        "set.",
        "Calling a model 'a function' while treating its output as a set of plausible answers. That "
        "slip is exactly what an evaluation metric exists to settle.",
        "`../ml-exercises/exercises/00_fundamentals/01_split_data.py` again, now read as a "
        "partition: show that the two sets are disjoint and that their union is the whole dataset.",
        "Write the domain, codomain and range of the splitting function you just tested.",
        "Describe your Day 6 safe-conversion function in domain-and-codomain terms, naming the input "
        "it must refuse."),
    day(11, MATH, "mit42", 124, 131,
        "Induction: why ten passing tests still prove nothing",
        "Induction proves an infinite family of cases with two steps - a base and an inductive step. "
        "It is the shape of every loop invariant, every recurrence, and every claim that a training "
        "loop decreases.",
        "From memory: name the two steps of induction, in the right order.",
        "Confusing mathematical induction with 'inductive' machine learning. One is a rule of proof; "
        "the other is fitting a pattern to data and hoping.",
        "Take the sum 1 + 2 + ... + n. Verify the closed form on the first fifty values in Python, "
        "then write the inductive step on paper. Both artefacts go in your log; the script alone is "
        "not the day.",
        "State the induction hypothesis in one sentence and point at the exact line where you are "
        "allowed to assume it.",
        "Prove on paper, in four lines or fewer, that the sum of the first n odd numbers is n "
        "squared."),
    day(12, MATH, "mit42", 182, 189,
        "Recursive data types: the structure writes the code",
        "A type defined in terms of itself - a list is empty or a head plus a list, a tree is a leaf "
        "or a node plus trees - dictates the shape of the function: one case per constructor.",
        "From memory: how many clauses a function over a recursive type needs, and what each clause "
        "corresponds to.",
        "Writing recursion from the inside out and forgetting the base case, then filing it as an "
        "infinite-loop bug instead of a missing clause.",
        "`../python-exercises/exercises/01_collections/06_flatten.py` - first count the "
        "constructors aloud, then write one clause for each.",
        "Say which clause is the base case, and why the argument is guaranteed to get smaller every "
        "call.",
        "Sketch a nested data type of your own and its depth function without opening the page."),
    day(13, MATH, "mit42", 512, 519,
        "Sums and asymptotics: the price of an algorithm",
        "Big-O is a claim about growth, not about today's speed. Sums give the total work of a loop "
        "nest, and a constant that looks harmless is usually the size of your dataset.",
        "From memory: order these by growth - n log n, 2 to the n, n squared, log n, n.",
        "Believing n squared means 'slow' on the laptop you actually have. A squared pass over thirty "
        "rows is free; a linear pass over thirty million is what will wake you up.",
        "Time two ways of answering 'have I seen this before?' - a list and a set - over 200,000 "
        "rows using `time.perf_counter`. Write down the ratio and which curve each followed.",
        "Cold-write the summation for a double loop over n items and evaluate it to a closed form.",
        "Estimate, then measure, the complexity of your own Day 4 word-count exercise."),
    day(14, MATH, "mit42", 676, 683,
        "Probability spaces: what can happen, what you ask, what weighs",
        "Before any arithmetic, three objects must be named: the sample space, the event you are "
        "asking about, and the distribution that assigns mass. Monty Hall trips most people because "
        "the sample space was written down wrong.",
        "From memory: define sample space and event, then say which Monty Hall strategy wins and "
        "why.",
        "Assuming the two remaining doors are equally likely after the host reveals one. The host's "
        "policy is part of the model, and changing it changes the answer.",
        "Simulate Monty Hall ten thousand times in standard-library Python for both strategies and "
        "print the two win rates. Predict the rates before you run it.",
        "Write out the four outcomes of the game before you look at the simulation's output.",
        "State the sample space of your Day 8 CSV: every possible train-test split, and which event "
        "you are conditioning on when you compare them."),
    day(15, MATH, "mit42", 706, 713,
        "Conditional probability and Bayes: updating on evidence",
        "P(A given B) is a different quantity from P(B given A). Bayes' rule converts one into the "
        "other, which is precisely what a classifier does when it turns a likelihood into a "
        "posterior.",
        "From memory: write Bayes' rule as words before symbols, and say which piece a trained model "
        "hands you and which piece you actually wanted.",
        "Base-rate neglect: believing a 99%-accurate test is conclusive for a condition one person in "
        "ten thousand has.",
        "`../ml-exercises/exercises/04_responsible_ai/12_group_rates.py` - group rates are "
        "conditional probabilities. State which conditioning direction the file reports, and what "
        "the other direction would say.",
        "Pick numbers you chose yourself, compute one base-rate example on paper, then check it in "
        "Python.",
        "Explain the difference between false-positive rate and positive predictive value to a Day 2 "
        "learner, using one example and no formulas."),
    day(16, MATH, "mit42", 760, 767,
        "Expectation: the value you should have before you roll",
        "Expectation is a weighted average over the sample space, and a loss function is an "
        "expectation - so a model fitted to the mean of your data is answering a question about the "
        "mean of your world.",
        "From memory: define expectation, and give the expectation of one fair die.",
        "Confusing the expected value with the most likely value. They part company badly in skewed "
        "cases, and error distributions are skewed.",
        "`../ml-exercises/exercises/00_fundamentals/03_regression_metrics.py` - mean absolute error "
        "and mean squared error are expectations of two different loss variables. Say which one "
        "punishes outliers harder, using the file's own numbers.",
        "Write the sum that defines the expectation for your own six-outcome example.",
        "Explain why squared error is the expectation of a square rather than the square of an "
        "expectation."),
    day(17, MATH, "mit42", 798, 805,
        "Deviation: variance, standard deviation, and the trade you are about to meet",
        "Variance measures spread around the mean and standard deviation puts the units back. Two "
        "datasets with identical means can disagree completely once spread enters, which is why an "
        "error bar is a claim rather than a decoration.",
        "From memory: define variance, and say what squaring does to a large deviation compared with "
        "a small one.",
        "Using raw errors as a spread measure. Positive and negative cancel, and the disagreement "
        "you were looking for disappears.",
        "`../ml-exercises/exercises/00_fundamentals/02_standardize.py` - recompute mean, standard "
        "deviation and z-scores by hand first, then confirm the transformed column has mean zero "
        "and standard deviation one.",
        "Cold-write the one-sentence idea of Days 9 to 16. This is the gate for the whole "
        "mathematics block; anything you cannot write goes back into your queue as its own day.",
        "Predict what one far-out point (1 part in 1000) does to a fitted line, then measure it. "
        "Name which metric you trusted and why."),
    day(34, CLASSIC, "homl", 25, 34,
        "The landscape again, this time in a practitioner's words",
        "Geron's opening moves the question from 'what is learning' to 'what is the task, what is "
        "the signal, what is the model'. Every project starts by naming those three, not by choosing "
        "a library.",
        "From memory, one sentence each: the Day 18 definition of machine learning, the Day 19 "
        "categories, and the Day 20 line about models being tools.",
        "Believing a state-of-the-art model can rescue a task that was never specified. It cannot, "
        "and the benchmark will not tell you that you skipped it.",
        "Take any one file from `../ml-exercises/exercises/00_fundamentals/` and write its task, "
        "signal and model as three labelled lines before you touch the code.",
        "State what the training signal is for each supervised family you met on Day 19, from "
        "memory.",
        "Explain to your Day 18 self why the model is the last of the three things you choose."),
    day(35, CLASSIC, "homl", 55, 64,
        "End to end, with real data and a numbered frame",
        "The project method is a sequence you can be taken to task for skipping: frame the problem, "
        "choose the measure, get the data, look at it, prepare it, fit, tune, present - and then "
        "automate the whole pipeline so the next run is a command.",
        "From memory: name the project steps in order, and say which two must happen before you "
        "download anything.",
        "Starting with the model because downloading data is boring. The boring step is where "
        "projects are won, and it is the one people re-do under deadline.",
        "`../ml-exercises/exercises/00_fundamentals/01_split_data.py` then `02_standardize.py` - "
        "write the frame and the metric sentence for one dataset you chose, and write the metric "
        "before the split, not after.",
        "Produce the metric sentence ('we measure X on Y in order to Z') before any code runs, and "
        "keep it in the log.",
        "Show the five numbers you would take to a first project review, without opening your "
        "notes."),
    day(36, CLASSIC, "homl", 101, 110,
        "Classification: the confusion matrix is the deliverable",
        "Classifiers are judged by a matrix, not by an accuracy. Which errors you can afford decides "
        "the metric, and the decision threshold is a business choice you can move without retraining "
        "anything.",
        "From memory: draw the two-by-two confusion matrix and write precision and recall out of it.",
        "Reporting accuracy on a problem with one positive in a hundred, then being surprised that a "
        "constant 'no' scores 99%.",
        "`../ml-exercises/exercises/01_models/05_confusion_counts.py` - compute true/false positives "
        "and negatives, then precision, recall and F1 on deliberately imbalanced data you build "
        "yourself.",
        "Name which cell of the matrix your most recent real project actually looked at, and which "
        "one it ignored.",
        "Set a threshold for a screening test given a cost per false alarm, and defend the trade in "
        "one sentence."),
    day(37, CLASSIC, "homl", 127, 136,
        "Training models: a loss surface, and walking downhill on it",
        "Every trainable model is parameters plus a loss, and training is a search downhill on that "
        "loss - so the learning rate, the shape of the surface, and the scale of your features "
        "decide whether you arrive or oscillate in place.",
        "From memory: in one clause each, what happens when the learning rate is too large and when "
        "it is too small.",
        "Treating gradient descent as a fact about the model instead of a search. A perfect model "
        "class can still fail to train, and unscaled features are the usual reason.",
        "`../ml-exercises/exercises/01_models/06_gradient_step.py` - do one step on paper first, "
        "then verify the code's numbers match your arithmetic digit for digit.",
        "Write the update rule from memory and label every symbol in it.",
        "Explain why the scaling you did on Day 17 changes the shape of the surface and not the "
        "optimum."),
    day(38, CLASSIC, "homl", 203, 212,
        "Ensembles: many weak, decorrelated guesses beat one strong one",
        "Averaging independent errors shrinks variance. Random forests buy that decorrelation by "
        "resampling rows and features, and bagging works even when each individual tree is "
        "deliberately kept weak.",
        "From memory: say why averaging helps, and name the two randomisations a random forest uses.",
        "Ensembling twenty copies of the same badly-specified model. Averaging removes variance; it "
        "does not average bias away.",
        "`../ml-exercises/exercises/01_models/04_fit_line.py` - fit three lines on three bootstrap "
        "samples of the same data, average their predictions, and report each single error against "
        "the ensemble's.",
        "Cold-write the bias-variance sentence from Day 25 in your own words.",
        "Predict which degrades first when you double the ensemble size - bias or variance - then "
        "measure it and say whether you were right."),
]

cur = json.load(open(SRC))


def shift(n: int) -> int:
    return n + (17 if n <= 16 else 22)


LIST = re.compile(
    r"\b(Days?)((?:\s+\d{1,3}(?:\s*[\u2013\u2014-]\s*\d{1,3}|[,\u2013\u2014]\s*(?:and\s+)?\d{1,3}"
    r"|\s+and\s+\d{1,3})*)+)"
)
FILE = re.compile(r"day-(\d{3})\.md")


def bump(text: str) -> str:
    def repl(m):
        nums = [int(x) for x in re.findall(r"\d{1,3}", m.group(2))]
        if not all(1 <= n <= 63 for n in nums):
            return m.group(0)
        out, last = [], 0
        for mm in re.finditer(r"\d{1,3}", m.group(2)):
            out.append(m.group(2)[last:mm.start()])
            out.append(str(shift(int(mm.group(0)))))
            last = mm.end()
        out.append(m.group(2)[last:])
        return m.group(1) + "".join(out)

    return FILE.sub(lambda m: "day-%03d.md" % shift(int(m.group(1))), LIST.sub(repl, text))


old = []
for d in cur["days"]:
    nd = {}
    for k, v in d.items():
        if k == "day":
            nd[k] = shift(v)
        elif isinstance(v, str):
            nd[k] = bump(v)
        else:
            nd[k] = v
    old.append(nd)

# Two spans that meant "the whole foundations block", not a mechanical pair of ends.
for d in old:
    if d["book"] == "pyweek" and d["day"] == 82:
        d["misconception"] = d["misconception"].replace("Days 18-25", "Days 18-33")

book = {
    "id": "pyqinst",
    "kind": "pdf",
    "short": "Python Complete Notes (QuantInsti)",
    "path": "/home/skware/Desktop/ML/Python complete notes\U0001f947.pdf",
    "author": "QuantInsti",
    "note": "Twelve-chapter Python course notes, 290 pages, clean text layer. The automatic chapter "
            "detector finds no openings here because the titles are set as 'Chapter N' on their own "
            "line, so src/maps/python-complete-notes.md records them by hand.",
    "map": "maps/python-complete-notes.md",
}
if not any(b["id"] == "pyqinst" for b in cur["books"]):
    cur["books"].append(book)

cur["days"] = sorted(old + PRE, key=lambda d: d["day"])
nums = [d["day"] for d in cur["days"]]
assert nums == list(range(1, 86)), (len(nums), nums[:5], nums[-5:])

by = {d["day"]: d for d in old}
print("cross-ref spot checks after the shift:")
print("  day 33 practice:", by[33]["practice"][by[33]["practice"].index("fits the line"):][:34])
print("  day 82 vocab  :", by[82]["misconception"][by[82]["misconception"].index("Days"):][:14])
print("  day 28 prereq :", by[28]["prerequisites"])
print("  day 51 list   :", by[51]["practice"][by[51]["practice"].index("Days"):][:24])
print("  day 54 list   :", by[54]["recall"][by[54]["recall"].index("Days"):][:22])
print("  day 73 list   :", by[73]["idea"][by[73]["idea"].index("Days"):][:20])
print("  day 84 file   :", [s for s in re.findall(r"day-\d{3}\.md", by[84]["practice"] + by[85]["practice"])])


cur["course"]["day_shift"] = {
    "applied": "2026-10-19",
    "note": "17 prerequisite days were added at the front and 5 Hands-On ML days after the old "
            "consolidation day, so stored progress for old day N lives at N+17 (N<=16) or N+22.",
    "map": {str(n): shift(n) for n in range(1, 64)},
}
cur["course"]["lead"] = (
    "One ordered path from an empty Python prompt to AGI arguments, built out of the books and notes "
    "already on this laptop and split into day-sized lessons. Days 1-8 teach Python from nothing, "
    "Days 9-17 teach the mathematics from nothing, Days 18-33 build classical machine learning, Days "
    "34-38 do it again in a practitioner's hands-on account, and Days 39-85 run the AGI track: "
    "Togelius on what generality even means, the OpenCog architecture survey, context engineering, "
    "agentic coding, edge deployment, a second pass on AGI theory, and a closing gate on governance "
    "as architecture. Each day names the book, the exact pages, the author's own words at bite size, "
    "one local exercise, and an automatic spaced review of the days you already completed. You never "
    "re-open a book from page one."
)
cur["course"]["method"] = (
    "Kumon-style rhythm, borrowed from the local developer path: **recall** (5 min, from memory) -> "
    "**read the author** (10-15 min, one bite) -> **practice** (20-30 min, one local exercise) -> "
    "**check** (5 min, run it and log the correction). Move on only when you can explain the idea "
    "without looking. Review re-tests earlier days at 1, 3, 7 and 21 lessons back, automatically. "
    "Structure grafted from the local SyncSenta teacher curriculum "
    "(`Sync-0.0.2/data/ai_curriculum.json`): every sub-strand carries learning outcomes, "
    "prerequisites, expected misconceptions and assessment evidence - those four fields are what the "
    "days below use as `idea`, `recall`, `misconception` and `check`. Not KICD/CBC-aligned; a "
    "personal adaptation."
)

json.dump(cur, open(SRC, "w"), ensure_ascii=False, indent=2)
print("wrote", len(cur["days"]), "days,", len(cur["books"]), "books")
