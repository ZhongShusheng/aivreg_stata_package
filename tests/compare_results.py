"""Compare baseline vs merged aivreg test-suite results.

Usage: python tests/compare_results.py
Reads  tests/results/baseline_results.csv and tests/results/merged_results.csv.
"""
import csv
import math
from pathlib import Path

RESULTS = Path(__file__).parent / "results"
NUMCOLS = ["N", "b", "se", "Partial_F", "Jval", "J_df", "pval_J", "esample_N"]
RTOL = 1e-6  # relative tolerance for coefficient/SE agreement


def load(name):
    rows = {}
    with open(RESULTS / f"{name}_results.csv", newline="") as f:
        for row in csv.DictReader(f):
            rows[row["test"]] = row
    return rows


def num(x):
    return None if x in (".", "", None) else float(x)


def close(a, b):
    if a is None and b is None:
        return True
    if a is None or b is None:
        return False
    if a == b:
        return True
    return math.isclose(a, b, rel_tol=RTOL, abs_tol=1e-10)


def main():
    base, merged = load("baseline"), load("merged")
    tests = sorted(set(base) | set(merged), key=lambda t: (t[0], int("".join(c for c in t.split("_")[0] if c.isdigit()) or 0)))
    print(f"{'test':<26} {'rc b/m':<10} agree  differences")
    print("-" * 100)
    for t in tests:
        b, m = base.get(t), merged.get(t)
        if b is None or m is None:
            print(f"{t:<26} {'MISSING in ' + ('baseline' if b is None else 'merged')}")
            continue
        diffs = []
        if b["rc"] != m["rc"]:
            diffs.append(f"rc {b['rc']}->{m['rc']}")
        for c in NUMCOLS:
            vb, vm = num(b.get(c)), num(m.get(c))
            if not close(vb, vm):
                fb = "." if vb is None else f"{vb:.10g}"
                fm = "." if vm is None else f"{vm:.10g}"
                diffs.append(f"{c}: {fb} -> {fm}")
        flag = "SAME " if not diffs else "DIFF "
        print(f"{t:<26} {b['rc']+'/'+m['rc']:<10} {flag} {'; '.join(diffs)}")

    # within-version invariance check: weight scale x17
    for name, rows in (("baseline", base), ("merged", merged)):
        a, b17 = rows.get("A11_gmm_pweight_bare"), rows.get("A12_gmm_pweight_x17")
        if a and b17:
            ba, b1 = num(a["b"]), num(b17["b"])
            ok = close(ba, b1)
            print(f"\n[{name}] pweight x17 scale invariance: "
                  f"b={ba} vs {b1} -> {'OK' if ok else 'VIOLATED'}")


if __name__ == "__main__":
    main()
