"""Run each defensive security exercise solution using only the standard library."""

from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parent
solutions = sorted((ROOT / "solutions").rglob("*.py"))
if not solutions:
    raise SystemExit("No solution files found.")

for solution in solutions:
    label = solution.relative_to(ROOT)
    print(f"Checking {label}", flush=True)
    try:
        subprocess.run([sys.executable, str(solution)], check=True, timeout=15)
    except subprocess.CalledProcessError as error:
        raise SystemExit(f"Solution failed: {label} (exit {error.returncode})") from error
    except subprocess.TimeoutExpired as error:
        raise SystemExit(f"Solution timed out: {label}") from error

print(f"All {len(solutions)} defensive security exercise solutions passed.")
