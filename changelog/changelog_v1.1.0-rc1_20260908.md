# Changelog

## v1.1.0-rc1 (2026-09-08)

Last version: 1.0.0

### Added
- **`e(sample)`** is now posted by both engines. Results are reposted on the full dataset after estimation, so `e(sample)` marks exactly the observations used. Rows with missing values in the outcome, treatment, anti-IVs, controls, fixed effects, clusters, or weights are excluded, as are singleton fixed-effect groups.
- **Partial R-squared** for the first stage (ratio path). Printed as `Partial R-sq.` next to the partial F-stat and returned in `e(Partial_R2)`. Available in asymptotic, bootstrap, and Anderson-Rubin modes, with and without fixed effects.
- **`[in]`** is now accepted by the GMM and 2SLS engine. Previously only `[if]` worked there.
- **New returns for GMM:** `e(J)`, `e(J_df)`, `e(J_p)`, and `e(J_status)`.

### Fixed — GMM / 2SLS
- **Hansen J test** now uses the conventional degrees of freedom (number of moments minus number of parameters). J is reported only on the efficient two-step path. It is suppressed with a warning if the moment covariance or parameter system is rank deficient. One-step GMM and 2SLS return missing J.
- **Weights.** `weight()` is now parsed once in the dispatcher and passed to each engine in the form it expects. Accepted forms: `weight(w)`, `weight([aw=w])`, `weight([pw=w])`, `weight([fw=w])`. Ratio accepts aw/pw/fw. GMM and 2SLS accept pw only; an explicit aw/fw bracket is refused with an error.
- **Weighted GMM variance.** Moments are scaled by normalized weights (w_i * N / W) instead of sqrt(w_i / W); small-sample corrections use N rather than the weight sum. The clustered `gbar` is rebuilt from the current sample instead of a stale global matrix.
- **Zero or negative probability weights** now stop with an error instead of being silently dropped from the sample.
- **Estimator typo** (e.g. `estimator(gmmm)`) is rejected up front instead of silently running one-step GMM.

### Fixed — ratio path
- **Partial F sign bug.** The first-stage t-statistic is now squared as `(t)^2`. Previously a negative t produced a negative partial F because of operator precedence.

### Fixed — corner cases
- **Long variable names.** Anti-IV names near Stata's 32-character limit no longer crash with rc 198. Returned scalars are truncated safely, internal stashes are indexed rather than name-keyed, and the first-stage store name is shortened when needed.
- **Stale results.** A failed `aivreg` call clears prior `aivreg` results instead of leaving them in `e()`.
- Fewer-than-two-clusters message is now shown as an error, not a warning.

### Known limitations
- GMM and 2SLS support probability weights only.
- Partial R2 and partial F are reported on the ratio path only.
