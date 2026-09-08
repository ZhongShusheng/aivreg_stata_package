"""Extract aivreg.ado from a git tag or commit so the suite can test it.

Usage:  python tests/get_version.py <tag-or-commit>
Writes  tests/.cache/<ref>/aivreg.ado  (folder is gitignored) and prints the
Stata command to run the suite against it.
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    ref = sys.argv[1]
    out_dir = ROOT / "tests" / ".cache" / ref.replace("/", "_")
    out_dir.mkdir(parents=True, exist_ok=True)
    blob = subprocess.run(["git", "show", f"{ref}:aivreg.ado"], cwd=ROOT,
                          capture_output=True, check=True).stdout
    (out_dir / "aivreg.ado").write_bytes(blob)
    rel = out_dir.relative_to(ROOT).as_posix()
    print(f"wrote {rel}/aivreg.ado")
    print(f"now run in Stata:  do tests/run_tests.do {ref} {rel}")


if __name__ == "__main__":
    main()
