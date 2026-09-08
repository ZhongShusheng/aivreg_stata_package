# aivreg test

Regression tests for `aivreg`. The suite always tests the `aivreg.ado` at the repository root and compares its results with a frozen CSV from the last tagged release.

## Files

| File | Purpose |
|---|---|
| `install_deps.do` | Installs or updates ivreg2, ranktest, ivreghdfe, ftools, distinct, require, and reghdfe (>= 6.12.5). |
| `run_tests.do` | Runs all 29 test cases and writes `results/current_results.csv` and `logs/tests_current.log`. |
| `compare_results.py` | Compares two result CSVs test by test. Exits 1 if any test differs. |
| `get_version.py` | Extracts `aivreg.ado` from a git tag or commit into `.cache/` so an old version can be rerun. |
| `expected/<tag>.csv` | Frozen results for each tagged release. |
| `results/` | Output of the last run. Not tracked by git. |


## How to Run

All commands run from the repository root.

```stata
do tests/install_deps.do
do tests/run_tests.do
```

Then compare with the latest frozen release:

```bash
python tests/compare_results.py
```

The output lists every test with its return code in both files, `SAME` or `DIFF`, and the columns that differ. A run on unchanged code should end with `0 test(s) differ`.

To run without opening Stata, from a Windows command prompt:

```
"C:\Program Files\Stata19\StataMP-64.exe" /e do tests\run_tests.do
```

Stata batch mode also writes `run_tests.log` in the launch directory. That file is ignored by git; the suite's own log is in `logs/`.

The full suite takes about 80 minutes. The GMM cases dominate the time, and B12 (fixed effects, clusters, and weights together) alone takes about 20 minutes.

### Compare any two runs

```bash
python tests/compare_results.py tests/expected/v1.0.0.csv tests/results/current_results.csv
```

Numeric columns match when they agree to a relative tolerance of 1e-6. A column missing from one file is skipped, so older CSVs without `Partial_R2` still compare.

### Rerun an older version

Needed when new test cases are added and a fresh baseline is required.

```bash
python tests/get_version.py v1.0.0
```

```stata
do tests/run_tests.do v1.0.0 tests/.cache/v1.0.0
```

The first argument is a label used in the output file names. The second is the folder holding the `aivreg.ado` to test.

## Test cases

### Section A: normal usage

| ID | Path | What it checks | rc |
|---|---|---|---|
| A1 | ratio | Default Anderson-Rubin inference | 0 |
| A2 | ratio | `vce(asymp)` | 0 |
| A3 | ratio | `vce(boot)` with seed | 0 |
| A4 | ratio | Factor-variable controls with `if` | 0 |
| A5 | ratio | `fe()` | 0 |
| A6 | gmm | Two amenities, auto-switch to GMM | 0 |
| A7 | gmm | Two-step GMM, two anti-IVs, J reported | 0 |
| A8 | gmm | One-step GMM, J suppressed | 0 |
| A9 | 2sls | Two anti-IVs | 0 |
| A10 | gmm | `cluster()` | 0 |
| A11 | gmm | Bare probability weight `weight(w)` | 0 |
| A12 | gmm | Weights scaled by 17 give the same estimate | 0 |
| A13 | ratio | Bracketed `weight([aw=w])` | 0 |

### Section B: corner cases

| ID | Path | What it checks | rc |
|---|---|---|---|
| B1 | ratio | `in` range | 0 |
| B2 | gmm | `in` range | 0 |
| B3 | gmm | `if` and `in` together | 0 |
| B4 | gmm | `weight([aw=w])` is refused | 101 |
| B5 | gmm | `weight([fw=w])` is refused | 101 |
| B6 | gmm | Zero or negative weights are refused | 459 |
| B7 | gmm | Missing weights drop from the sample | 0 |
| B8 | gmm | Fewer than two clusters | 430 |
| B9 | ratio | 32-character variable names | 0 |
| B10 | gmm | 32-character anti-IV names | 0 |
| B11 | gmm | Failed call does not leave stale results | 459 |
| B12 | gmm | `fe()`, `cluster()`, and weights together | 0 |
| B13 | gmm | Single anti-IV, just identified, J suppressed | 0 |
| B14 | gmm | Collinear anti-IVs | 430 |
| B15 | any | Estimator typo `gmmm` is rejected | 198 |
| B16 | ratio | Non-consecutive integer `fe()` values | 0 |

Datasets: A1 to A3 use `safety_aivreg_example.dta`. All other cases use `housing_aivreg_example.dta`.
