"""Compare two aivreg test-suite result CSVs test by test.

Usage:
  python tests/compare_results.py
      compares tests/expected/<latest tag>.csv  vs  tests/results/current_results.csv
  python tests/compare_results.py <expected.csv> <actual.csv>
      compares any two CSVs written by tests/run_tests.do

Exit code is 1 if any test differs, so it can gate a release.
"""
import csv
import math
import sys
from pathlib import Path

TESTS = Path(__file__).resolve().parent
NUMCOLS = ["N", "b", "se", "Partial_F", "Partial_R2", "Jval", "J_df", "pval_J", "esample_N"]
RTOL = 1e-6


def load(path):
    with open(path, newline="") as f:
        return {row["test"]: row for row in csv.DictReader(f)}


def num(x):
    return None if x in (".", "", None) else float(x)


def close(a, b):
    if a is None and b is None:
        return True
    if a is None or b is None:
        return False
    return a == b or math.isclose(a, b, rel_tol=RTOL, abs_tol=1e-10)


def order(t):
    head = t.split("_")[0]
    return (head[0], int("".join(c for c in head if c.isdigit()) or 0))


def latest_expected():
    files = sorted((TESTS / "expected").glob("*.csv"))
    if not files:
        sys.exit("no files in tests/expected/")
    return files[-1]


def main():
    if len(sys.argv) == 3:
        exp_path, act_path = Path(sys.argv[1]), Path(sys.argv[2])
    elif len(sys.argv) == 1:
        exp_path, act_path = latest_expected(), TESTS / "results" / "current_results.csv"
    else:
        sys.exit(__doc__)
    exp, act = load(exp_path), load(act_path)
    print(f"expected: {exp_path}\nactual:   {act_path}\n")
    print(f"{'test':<26} {'rc e/a':<10} agree  differences")
    print("-" * 100)
    ndiff = 0
    for t in sorted(set(exp) | set(act), key=order):
        e, a = exp.get(t), act.get(t)
        if e is None or a is None:
            ndiff += 1
            print(f"{t:<26} MISSING in {'expected' if e is None else 'actual'}")
            continue
        diffs = []
        if e["rc"] != a["rc"]:
            diffs.append(f"rc {e['rc']}->{a['rc']}")
        for c in NUMCOLS:
            ve, va = num(e.get(c)), num(a.get(c))
            if c not in e or c not in a:
                continue  # column not recorded by one side (e.g. older suite)
            if not close(ve, va):
                fe = "." if ve is None else f"{ve:.10g}"
                fa = "." if va is None else f"{va:.10g}"
                diffs.append(f"{c}: {fe} -> {fa}")
        ndiff += bool(diffs)
        print(f"{t:<26} {e['rc']+'/'+a['rc']:<10} {'SAME ' if not diffs else 'DIFF '} {'; '.join(diffs)}")

    for name, rows in (("expected", exp), ("actual", act)):
        a1, a17 = rows.get("A11_gmm_pweight_bare"), rows.get("A12_gmm_pweight_x17")
        if a1 and a17:
            ok = close(num(a1["b"]), num(a17["b"]))
            print(f"\n[{name}] pweight x17 scale invariance: {'OK' if ok else 'VIOLATED'}")

    print(f"\n{ndiff} test(s) differ")
    sys.exit(1 if ndiff else 0)


if __name__ == "__main__":
    main()
