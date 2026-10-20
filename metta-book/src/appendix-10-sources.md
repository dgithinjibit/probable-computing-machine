# Appendix: the public MeTTa corpus, level by level

This book carries no third-party text. What it carries are pointers, chosen on
2026-10-19, with the level each one serves and the specific warning attached to
it. Star counts move, code drifts, and a snippet from the internet may target a
different MeTTa than the 0.2.10 wheel on this machine — so the rule for the whole
appendix is: read for shape, then re-check any construct you intend to use against
the local version-matched clone at
`~/Desktop/ex/exercises/hyperon-experimental` (tag v0.2.10), whose
`docs/metta.md`, `docs/minimal-metta.md`, `docs/modules_dev.md` and
`lib/src/metta/runner/stdlib/stdlib.metta` are the three sources this book's
Semantics sections are argued from.

**L0–L1 — the language itself.** `trueagi-io/hyperon-experimental` (282★) is the
implementation and the specification. The docs are the book; the stdlib is the
answer key; and `python/tests/scripts/a1…g1*.metta` is a set of small programs
guaranteed to parse on your exact version, which makes them the best first place
to look when you cannot tell whether your syntax is wrong or your expectation is.
`eyuuab/MeTTa-lang-stdlib-documentation` (22★) is worth a skim for its category
names — atomspace_interaction, equality_and_reduction, error_handling,
evaluation_control, expression_manipulation, list_manipulation,
mathematical_operations, non_deterministic_computation, quoting, console_output,
module — because that taxonomy is a fair description of what the language thinks
it contains, and it maps almost one-to-one onto this book's units. Caveat: it is
documentation of the *stdlib*, not of runtime behaviour, so where it disagrees
with what your interpreter prints, print wins and the fact sheet gets a new line.
`logicmoo/metta-testsuite` is the curious one: `.metta` files paired with
`.metta.answers` oracles. Use it as an answer key when you want to know whether a
construct is supposed to work at all, not as a teaching text.

**L1–L2 — small programs, written by people further along.**
`trueagi-io/metta-examples` (40★) is the single most useful repository in this
list for you, because it is teaching-shaped rather than research-shaped.
`SICP_book/` reworks SICP chapters 1–2 in MeTTa — read it as a demonstration of
how much of SICP's argument survives the change of language, and note the shape of
the recursion and the environment-model analogues; do not reproduce its text.
`aunt-kg/` is the kinship knowledge graph this book's L0 toy graph is modelled on,
including a `json_to_metta.py` loader, which is the honest version of the
[L5](./ch11-l5-interop-and-export.md) bridge: data comes in from JSON, relations
get derived by rules, and nothing pretends to be a database. `collatz/`,
`combinator-calculi/` and `deontic_logic/` are the "small but strange" shelf:
each one is a two-page proof that MeTTa can express a formal system it was not
designed for, which is the skill [L3](./ch09-l3-modules-and-search.md) is about.
`NullLabTests/metta-demo` offers seven guided demos — good for a Friday when you
want someone else's problem. `MesTTo/MeTTa-Examples` and `trueagi-io/metta-catalog`
are the overflow shelves; expect uneven versions.

**L3 — modules, search, and treating programs as data.**
`trueagi-io/chaining` (14★) names the strategies: backward, forward, iterative,
dependent-typed, and probabilistic chaining, plus a PLN prototype. Read the README
and the smallest example for the *shape* of a search written as rules, then come
back to your own `enumerate.metta` and decide which strategy yours actually is.
`trueagi-io/metta-wam` (25★, and `OzCog/metta-wam` for a sibling) implements a
Warren Abstract Machine in MeTTa — this is the strongest available evidence that
unification, the binding trail, and choice points are writable as MeTTa data, and
therefore the closest public thing to "a compiler front end exists in this
language". `trueagi-io/PeTTa` (31★, MIT) is a MeTTa *implementation written in Prolog* — not
Prolog embedded in MeTTa — and it is the most useful thing on this list for
debugging by proxy: when hyperon prints something you cannot explain, a second
implementation of the same spec either agrees or disagrees, and disagreement is a
bug report. It needs a Prolog runtime (SWI-Prolog) to run, its October-2026 issue
tracker is about `import!` and type registration, and its reduction semantics are
close enough to `metta-wam` that reading both is the fastest way to see which
behaviours are language and which are interpreter choice. `trueagi-io/hyperon-moses` matters for one document:
`docs/metta-port-highlevel-guide`, which describes porting a genetic-programming
search engine into MeTTa. Your Q1 goal is "MOSES from scratch", so read that guide
before designing, and note which parts of the port are search policy versus
representation. `MesTTo/LeaTTa` is the theory spine — a Lean 4 operational
semantics for MeTTa with a Verso book — and it is where you go when the spec's
pseudocode leaves you unsure whether behaviour is specified or incidental.

**L4 — uncertainty, and agency with a shape.** `trueagi-io/PLN` (15★) and
`trueagi-io/pln-experimental` (11★) are the Probabilistic Logic Network
tradition: inheritance, implication and similarity links with strength and
confidence, and the composition rules that [L4](./ch10-l4-uncertainty-and-agency.md)
had you write approximately. The warning is that this literature carries decades
of argument about constants and inference formulas; take the *link grammar* from
it and treat the arithmetic as contested. `trueagi-io/MORK` (62★) is a knowledge
reconciliation system with an AtomSpace lineage behind it — useful for how a real
system keeps facts from multiple sources consistent, which your Distributed
AtomSpace phase needs before it needs anything clever.
`iCog-Labs-Dev/hyperon-openpsi` (8★) is the OpenPsi layout in MeTTa: `main/demand`,
`main/emotion`, `main/modulator`, `mind-agents/action-planner/` with an `aStar`
variant and a `thompson-sampling` variant, and `use-cases/curious-agent`. Read it
for the module boundaries — it is the clearest public answer to "how do I split
drives from beliefs from planners in files?" — and note the hard caveat: it pins
`hyperon==0.2.3`, so its code will not run unmodified on 0.2.10 and its stdlib
calls may reference names that have moved. `trueagi-io/MettaWamJam` is the
playground for the same ideas when you want less structure.

**L5 — interop and the transpiler genre.** `trueagi-io/metta-morph` is MeTTa →
Chicken Scheme: the one public example of a real lowering with a target language
someone else maintains, and therefore the best calibration for your MeTTa→THRML
hopes. Study where it stops. `MesTTo/MeTTaScript` and `MesTTo/MeTTa-LSP` show the
tooling side — a surface-syntax layer and a language server — which is what you
need before anyone else can read your files. `trueagi-io/protobuf-metta` is a
concrete answer to "how does MeTTa data get to another process?" and it pairs well
with the `json`/`fileio` bridge in this book. The learner projects in this folder
(`metta_2_py.metta`, and `Amanuel-1/metta-language-support-pack` for VSCode
editing) are local, small, and honest about their age.

**L6, and the shape of "hero".** Three learner projects worth skimming for
structure rather than content: `ekrama040-byte/metta_knapsack_geneticAlgorithm-`,
`Myk72/metta-flight-route-optimizer`, and
`SnitTeshome/Symbolic_ai_medical_diagnosis`. Each is a person who took a domain
problem, wrote spaces and rules, and shipped an answer — and each has the same
weakness: almost no self-tests. Your capstone's `assert*` section is what puts you
a level above the corpus you have just read, which is the actual point of the
level ordering in this book.

**L7 — program search, and what the MOSES literature actually hands you.** Read
`trueagi-io/hyperon-moses`'s `docs/metta-port-highlevel-guide` first; it is four
tricks and a vocabulary (Elegant Normal Form, deme, plateau, `GoodFit`) rather than a
tutorial, and [L7](./ch13-l7-moses.md) is the chapter that turns it into a running
file. Then its `boolean-reduction/rules.metta` — **AGPL-3.0, read it, paste none of
it** — where you will find the portability wall recorded in the
[fact sheet](./appendix-01-verified-facts.md): those rules call `member`, `case` and
`get-metatype`, and on 0.2.10 `member` does not exist, so upstream's rule list is a
design to imitate, not a file to import. For the dependent-typed framing of the same
search, `trueagi-io/chaining` → `experimental/evolutionary-programming` represents a
fit program as an inhabitant of `(Σ (-> Bool Bool Bool) (Fit 0.7))` and uses DeBruijn
indices plus unicode-quoted operators to stop spontaneous reduction — the two
problems [L7](./ch13-l7-moses.md)'s tagged constructors solve a duller way. For
"someone my level shipped this", `ekrama040-byte/metta_knapsack_geneticAlgorithm-`
(from the L6 list) is the closest public analogue: a GA in MeTTa, search over encoded
candidates, same fitness questions, no normal form.

## What the ecosystem is actually asking for (checked 2026-10-19)

Read this before you plan a job hunt around it, because the honest finding is a
negative one: **there are no public MeTTa/Hyperon job postings to map against.**
SingularityNET has no careers page; Fetch.ai's lists zero open roles; Extropic's
listing widget never renders; the ASI Alliance page could not be fetched at all.
TrueAGI's Addis Ababa line runs through iCog Labs, and the only public artifact
found there is an April 2024 partnership announcement — over two years old, and not
a hiring call. So treat "apply in Ethiopia" as a conversation you start, not a form
you fill.

What does exist is a hiring-shaped contribution surface, and it has three cores:

1. **Interpreter core (Rust).** Open `hyperon-experimental` issues as of this
   month are about substitution and the evaluated-expression flag, TrieKey
   decoding, `import!` token export, and non-deterministic `match` — that last one
   being precisely the semantics this book's fact sheet documents from the
   *behaviour* side. `CONTRIBUTING.md` demands tests, minimal `unsafe`, and pinned
   dependency versions. `MORK` and `FabricPC` carry the `good first issue` labels
   right now.
2. **Language, stdlib and tooling.** `PeTTa` (active this month, `import!` and type
   registration), `metta-wam`, `metta-catalog`, and the question-shaped issues in
   `metta-examples` — "most idiomatic filtering of tuples", "transitive closure
   with `match`/`add-atom`" — which are MeTTa-language questions that a careful
   learner can answer better than the book's own L1-L2 material currently does in
   public. Tooling is the gap with the least competition and the clearest evidence
   value: the most recent hire-visible artifact from an apparently Ethiopia-based
   contributor is a VS Code "MeTTa Language Support" extension (Feb 2026), not a
   research system.
3. **Applied AGI.** `PLN`/`pln-experimental`, `chaining`, `hyperon-moses`,
   `iCog-Labs-Dev/hyperon-openpsi`, and the embodied work. Money here moves through
   grants rather than salaries: the August 2025 Deep Funding round for Hyperon
   asked for six things — novel hardware architectures, neural-symbolic DNNs,
   theoretical quantum models, concept blending in MeTTa, AGI motivation systems,
   knowledge-graph tooling — and paid $20k–$175k for demos. The 2026 round keeps
   MeTTa/Hyperon tracks at up to $100k per project. Check
   [deep-projects.ai](https://deep-projects.ai/all-rfps/) for the live text; an
   aggregator's copy is not the RFP.

The bridge target itself, for the record:
[extropic-ai/thrml](https://github.com/extropic-ai/thrml) (Apache-2.0) is the
JAX-native Thermodynamic Hypergraphical Model Library — `SpinNode`, `Block`,
`IsingEBM(nodes, edges, biases, weights, beta)`, `IsingSamplingProgram`,
`SamplingSchedule`, `sample_states` — and
[Extropic's own write-up](https://extropic.ai/writing/from-one-to-one-billion/)
describes the hardware path as Torx kernels → Thermalizers → a graph of THRML
models on silicon, with a GPU simulator API reachable today and Z1 hardware access
scheduled for 2027. Its "up to 10,000× over GPUs" figure is theirs, from their
papers and their simulations; cite it, do not repeat it as a measurement.
