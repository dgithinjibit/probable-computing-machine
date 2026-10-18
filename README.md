# Local offline developer path

This workspace is a self-paced, offline-first route toward five complementary
skills: JavaScript/web development, defensive source-code review, AI
engineering, IoT development, and Rust-based Web3. It uses small daily
assignments, mastery checks, and review before advancing. This is a personal
Kumon-inspired study routine, not an official Kumon program or credential.

## Run the course portal

From this folder, run:

```sh
./serve-site.sh
```

The homepage opens automatically at [http://127.0.0.1:8000](http://127.0.0.1:8000)
as soon as the local server is ready; book rebuilds continue afterward. Keep
that terminal open while studying. Press `Ctrl+C` there to stop the server.
The page link itself does not start the server.

The portal and guided-course lessons are served from this computer and do not
need an internet connection. Offline access still requires this script to be
running, and any optional external links or unavailable hosted services will
not work without internet.

## Start the developer path

The [421-session guided course](developer-path/guided-course.html) begins with
Python, then builds through web development, defensive code review, AI, IoT,
robotics, Rust/Web3, education technology, and a final project. Complete one
session at a time; the browser saves progress locally and unlocks the next
session. Open the [developer-path reference books](developer-path/book/index.html)
for deeper reading alongside the guided course.

For a live preview of only this mdBook, first run `source ../offline-env.sh`
from this folder, then:

```sh
mdbook serve developer-path --hostname 127.0.0.1 --port 3000 --open
```

The combined portal at port 8000 is recommended because it also exposes the
companion exercise folders. The bundled mdBook is used by `serve-site.sh`;
there is no need to install it separately.

This folder contains separate courses; start with a book, then solve its
matching exercises:

| Course | Learn | Practice | Check |
| --- | --- | --- | --- |
| Developer Path → Syncsenta | [421-session guided course](developer-path/guided-course.html) · [Full roadmap](developer-path/book/roadmap.html) | [Math foundations](developer-path/book/math-foundations.html) · [Quantum computing](developer-path/book/quantum-computing.html) · [Web4 systems](developer-path/book/web4-systems.html) · [Education leadership course](developer-path/book/education-leadership.html) · [Readiness hardening plan](developer-path/book/readiness-hardening.html) · [AI-track syllabus (draft)](developer-path/book/syncsenta-ai-syllabus.html) · [Final Syncsenta project](developer-path/book/syncsenta-capstone.html) · [Progress log](developer-path/src/progress-log.md) | `./serve-site.sh` |
| Education Leadership & Higher Education | [Course overview](developer-path/book/education-leadership.html) | [Full chapter-based book](education-book/book/index.html) | `mdbook build education-book` |
| Parallel project ladder | [Five project briefs](developer-path/book/project-ladder.html) | [Python, AI evaluation, defensive audit, MeTTa policy, Syncsenta rehearsal](project-labs/README.md) | See project-labs README |
| Game-style challenges and prompt engineering | [Challenge arena](developer-path/book/challenge-arena.html) and [prompt workshop](developer-path/book/prompt-engineering.html) | MeTTa/Scrypto analogies and solution map for local languages | `./serve-site.sh` |
| JavaScript / Web | [Track guide](javascript-exercises/README.md) | [Sum sensor readings](javascript-exercises/exercises/01_sum_readings.js) | `node javascript-exercises/run-tests.js solutions/01_sum_readings.js` |
| Rust | [Read the Rust Book](rust-book/book/index.html) | [`rustlings/exercises/`](rustlings/exercises/) | `cd rustlings && cargo run --offline -- run` (the first incomplete exercise should fail to compile until you solve it) |
| Rust / Web3 | [Track guide](rust-web3/README.md) | [Local transfer exercise](rust-web3/exercises/01_transfer.rs) | `rustc --edition=2021 --test rust-web3/solutions/01_transfer.rs -o /tmp/rust-web3-transfer && /tmp/rust-web3-transfer` |
| MeTTa | [Read the MeTTa Book](metta-book/book/index.html) | [`metta-exercises/exercises/`](metta-exercises/exercises/) | `bash metta-exercises/check-solutions.sh` |
| Python | [Python exercise guide](python-exercises/README.md) | [`python-exercises/exercises/`](python-exercises/exercises/) | `python3 python-exercises/run_tests.py` |
| AI engineering / ML | [AI/ML exercise guide](ml-exercises/README.md) | [`ml-exercises/exercises/`](ml-exercises/exercises/) | `python3 ml-exercises/run_tests.py` |
| HCyberSec / code review | [Code-review path](hcybersec/README.md) and [defensive security exercises](security-exercises/README.md) | [Review worksheet](hcybersec/review-template.md) | Review local code; record evidence and tests |
| IoT development | [IoT exercise guide](iot-exercises/README.md) | [Sensor-validation starter](iot-exercises/exercises/01_validate_sensor.py) | `python3 iot-exercises/run_tests.py` |
| Robotics | [Full robotics reference book](robotics-book/book/index.html) | Simulation-first projects in the book; physical hardware is optional | `mdbook build robotics-book` |
| Free offline resources | [Catalog and download notes](resources/README.md) | [Resource guide in mdBook](developer-path/book/free-resources.html) | Save official materials with source and license notes |
| Cairo | [Read the Cairo Book](cairo-book/book/html/index.html) | [`starklings/exercises/`](starklings/exercises/) | `scarb --version`; `cd cairo-book/listings/... && scarb build` |
| Move | [Read the Move Book](move-book/site/build/index.html) | [`sui-move-intro-course/README.md`](sui-move-intro-course/README.md) | Requires the Sui CLI for compiling Move packages |
| Scrypto | [`scrypto-challenges/README.md`](scrypto-challenges/README.md) | Historical Radix challenge archive | Legacy archive; not an active MeTTa exercise course |
| Wolfram Language | [Read the Wolfram course](wolfram-book/book/index.html) | [`wolfram-exercises/README.md`](wolfram-exercises/README.md) | Requires licensed Wolfram Engine/Mathematica and `wolframscript` |

See [exercise platform readiness](developer-path/book/exercise-platform-readiness.html)
for an honest Exercism/LeetCode status by track and the packaging work needed
before publishing there.

Read the practice folder's README for its learning path and solution policy.
Run MeTTa commands from this folder so local file paths are predictable. The
separate Scrypto challenge archive contains historical project submissions;
it is not a MeTTa exercise track. Python, JavaScript, ML/GenAI,
defensive-security, IoT, and Rust/Web3 tracks use original offline starter
exercises; they do not reproduce book text or require API credentials.
