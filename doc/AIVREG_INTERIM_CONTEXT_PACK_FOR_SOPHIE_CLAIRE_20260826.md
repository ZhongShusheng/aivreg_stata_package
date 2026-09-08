# `aivreg` Interim Technical Context Pack

**Prepared:** August 26, 2026  
**Audience:** Alex Bell, Sophie Calder-Wang, and Claire Meng  
**Purpose:** Support an informed review of the current `aivreg` maintenance work before an updated SSC release. This document distinguishes verified defects and test results from proposed statistical or interface choices. It is a status report, not a claim that the current build is ready for public use.

## Executive summary

Alex submitted `aivreg` 1.0.0 to SSC in December 2025. The current work is a maintenance update to that released command, not a new estimator designed from scratch.

The review has found and addressed several concrete software defects: the public version's partial-F calculation can be wrong because of missing parentheses; older code mishandled some weighted and clustered GMM calculations; some calls could leave or report misleading estimation state; unsupported weight types were silently accepted on GMM/2SLS paths; and long variable names could cause the single-AIV path to fail after displaying apparently valid output.

The newest working candidate contains proposed corrections for these issues and has passed focused developer checks. An earlier candidate passed a 44-row independent numerical comparison covering core unclustered and clustered estimation, including the efficient two-step GMM J statistic. However, the newest candidate has **not yet completed one clean independent run of the entire regression suite**, and no final SSC package or updated help file exists. It should therefore not yet replace the public SSC copy.

The main unresolved statistical question is narrow: how `aivreg` should behave when the moment covariance matrix is rank deficient. The recommended conservative release rule is to report the conventional Hansen J only for efficient two-step GMM when the relevant matrices have full usable rank, with degrees of freedom equal to the number of independent moment conditions minus the number of estimated parameters; otherwise suppress the statistic and give a clear diagnostic. A prior agent-derived proposal instead generalized the degrees of freedom using numerical matrix ranks. That proposal is plausible but should not be made part of a public command without human methodological approval.

## 1. Provenance: what version is being reviewed?

### Public version now on SSC

- Command: `aivreg` 1.0.0.
- Submitted to SSC by Alex Bell in December 2025; the project record dates public distribution to December 22, 2025.
- Alex's currently installed SSC copy identifies itself as `*! aivreg 1.0.0 19sep2025`.
- The public repository identified by Shusheng is [ZhongShusheng/aivreg_stata_package](https://github.com/ZhongShusheng/aivreg_stata_package).

The public SSC copy remains the released version. It has not been overwritten during this review.

### Development lineage

The present maintenance line began from a later internal successor to the public code. The fixed baseline used for this release review has SHA-256:

`e0233db06cb9cea47cc651bef55ecc1cc168706389a7abfae3cdd6ab734199f6`

That baseline had previously been accepted only for two specifically identified internal paper computations. That limited acceptance did **not** establish that it was suitable for general users or SSC.

A first release-cell candidate had SHA-256:

`03452fa4e9dd72048aae2789523fdaa56e08c8d1ddf4f50d4ffc711db4818f40`

After independent testing identified two remaining production defects, a focused correction produced the newest working candidate:

- Banner: `aivreg 1.1.1 25aug2026`
- SHA-256: `d26002eadf9a8d049024d1abb39a151c7d3c4899831c109d9e68f5b5238a10a3`

This is a **working candidate**, not a frozen release candidate.

### Repository reconciliation still required

The project has also referred to Sophie's `test_aivreg` repository, which contains both `aivreg` and `aivlpoly` material. Before SSC submission, the final candidate must be compared with:

1. the exact package currently distributed by SSC;
2. the current head of Shusheng's public `aivreg` repository; and
3. the relevant `aivreg` files in Sophie's repository.

The purpose is to identify any collaborator work not yet incorporated and to leave a clear public source of record. The last internal repository comparison is not recent enough to substitute for this final reconciliation.

## 2. Known bugs or problems

The labels below distinguish confirmed software defects from open design questions.

### A. Confirmed defects

#### 1. Partial-F calculation in the public SSC version

The public copy contains an unparenthesized expression that can change the intended order of operations and produce an incorrect partial-F statistic, including implausible negative values.

**Chosen correction:** add the required parentheses so the numerator and denominator implement the intended formula. This correction is already present in the later development baseline and must remain protected by regression tests.

#### 2. Weighted GMM and clustered covariance

Earlier implementations did not consistently apply probability weights in the covariance calculation and could allow clustered moment calculations to depend on the wrong state. These errors affect standard errors and, for efficient two-step GMM, can affect the weighting matrix and J statistic.

**Implemented correction in the current lineage:** normalize probability weights by their sample mean; apply normalized weights linearly to the sample moment and squared in the covariance “meat”; use observation-count-based finite-sample factors so rescaling all probability weights does not change estimates; and calculate clustered moment sums without dependence on cluster labels or prior calls.

#### 3. Hansen J calculation and reporting in efficient two-step GMM

Older versions did not provide a reliably validated multi-AIV J path. A reported J of exactly zero can be legitimate in special cases, but it can also be a symptom of a collapsed or incorrectly constructed moment/weighting system.

**Implemented core correction:** on the efficient two-step GMM path, calculate

`J = N × ḡ(β)' × W × ḡ(β)`

using the efficient second-step weighting matrix and the final second-step estimate; calculate the p-value from the reported J and degrees of freedom; and ensure that adding nonredundant anti-IVs expands the moment system rather than silently leaving it unchanged.

The ordinary full-rank implementation has passed independent numerical comparisons. Rank-deficient edge-case behavior remains an open decision described below.

#### 4. Estimation sample and stale returned state

Some older paths could leave misleading returned results after an error or fail to make `e(sample)` correspond exactly to the observations used after missingness, weights, controls, fixed effects, and clustering were applied.

**Implemented correction:** remap `e(sample)` to the analytic survivor sample; ensure its count agrees with `e(N)`; and clear misleading estimation state after failed calls.

#### 5. Invalid or missing weights

Zero and negative weights require loud refusal, while observations with missing weights should be excluded consistently from the analytic sample.

**Implemented correction:** reject invalid nonpositive weights and incorporate missing-weight observations into sample exclusion rather than allowing ambiguous behavior.

#### 6. Unsupported weight types silently accepted by GMM and 2SLS

The command parsed analytic- or frequency-weight syntax on the GMM/2SLS paths but discarded the declared weight type and then applied probability-weight semantics. A call could therefore run successfully while doing something different from what the user requested.

**Newest correction:** GMM and 2SLS now accept explicit probability weights and the command's documented bare weight form, but reject explicit analytic and frequency weights with a clear error. The single-AIV ratio path retains its existing, more permissive documented weight syntax.

#### 7. Long variable names on the single-AIV path

With legal but long Stata variable names, the single-AIV path could print an estimate and then fail because internal names derived from the user's variable names exceeded Stata's limits.

**Newest correction:** use bounded internal aliases and index-based temporary storage while preserving the user's original variable names in displayed and returned results. Focused developer tests now pass for long outcome, amenity, anti-IV, and control names.

#### 8. Too few clusters and state leakage

Some clustered edge cases did not fail cleanly, and prior-command state could contaminate later J calculations.

**Implemented correction:** refuse insufficient-cluster cases loudly and construct each call's moment and covariance objects from the current call only.

### B. Problems that are partly documentation or interface design

#### 9. J reporting outside efficient two-step GMM

The existing public help suggests J results more broadly for multiple-AIV 2SLS and GMM calls. The current development contract reports the Hansen J only for efficient two-step GMM and suppresses it for one-step GMM and 2SLS.

This suppression is a defensible interface choice, not a universal statistical necessity. Some software allows an overidentification diagnostic to be calculated after other estimators, provided it is labeled and constructed appropriately. The release needs a deliberate, documented policy rather than an accidental difference between code and help.

#### 10. Parsed options that may not affect GMM/2SLS

Several options appear to be accepted by the parser even when they may not have an active effect on GMM/2SLS. A public command should either implement them, document precisely where they apply, or reject them on unsupported paths.

#### 11. Long-name behavior with optional saved first-stage estimates

The newest correction covers the tested single-AIV long-name failure. The optional GMM `savefirst` surface has an analogous internal naming limit that has been identified but not yet corrected or tested. This should either be fixed before release or documented and excluded from the supported release surface.

#### 12. Documentation and build identity

The current help file predates the corrected J, weighting, error-handling, and sample behavior. The current development banner is useful for preventing build confusion, but the final version number and public changelog still need to be agreed and applied consistently.

## 3. Steps taken so far

1. **Established exact version identities.** The installed SSC copy, the later internal baseline, each test candidate, and the newest working candidate were separately hashed so results cannot be attributed to the wrong file.
2. **Reconstructed the intended behavior.** The review compared the public help, inherited code, reported bugs, standard estimating equations, and actual Stata behavior. Where those sources disagreed, the disagreement was recorded rather than silently resolved.
3. **Built an independent numerical oracle.** Core estimates were compared against calculations independent of `aivreg`, including unclustered and clustered probability-weighted GMM, efficient two-step covariance, J, degrees of freedom, and p-values.
4. **Ran a 44-row core comparison.** On the earlier candidate, all 44 core rows passed. This is strong evidence for the ordinary tested GMM/2SLS calculations, but it is not a release verdict because additional suites subsequently found other defects.
5. **Ran focused interface and adversarial tests.** These found unsupported weight types being silently reinterpreted and the long-variable-name failure. They also exposed a disputed rank-deficient J target and a very small numerical scale-invariance discrepancy on an ill-conditioned synthetic fixture.
6. **Applied two focused production fixes.** The newest candidate rejects unsupported GMM/2SLS weight types and fixes the tested single-AIV long-name failures. Its developer-level targeted tests pass.
7. **Prepared a comprehensive independent harness.** It is designed to run the core numerical comparisons, focused bug tests, and inherited regression suite in one fail-closed job. It has deliberately not been treated as final because its rank-deficient J expectation must first be reconciled with the human decision requested here.

No public repository, installed SSC copy, manuscript, or collaborator file has been modified.

## 4. Inferences made along the way—and confidence in each

### High confidence: ordinary full-rank efficient two-step Hansen J

For a conventional full-rank efficient two-step GMM problem, the J statistic should use the final efficient estimate and efficient weighting matrix, with degrees of freedom equal to the number of independent moment conditions minus the number of estimated parameters. The p-value should be the corresponding upper-tail chi-squared probability.

**Why confidence is high:** this is the conventional Hansen overidentification test; it can be calculated independently; and the tested candidate reconciled with the independent numerical oracle on the ordinary fixtures.

### High confidence: partial-F parentheses correction

The negative/incorrect partial-F behavior in the public line traces to missing parentheses, and the correction is to restore the intended grouping.

**Why confidence is high:** the source-level error and corrected formula are direct and mechanically testable.

### High confidence: unsupported weights must not be silently reinterpreted

If GMM/2SLS supports probability weights but not analytic or frequency weights, accepting `[aw=...]` or `[fw=...]` and silently using probability-weight semantics is a software defect.

**Why confidence is high:** the declared weight type was demonstrably discarded. Loud rejection is safer than silently changing the requested estimand.

### High confidence: long-name failure is an implementation defect

Legal Stata variable names should not cause the command to display an estimate and then fail because of avoidable internal-name construction.

**Why confidence is high:** the failure was reproduced, traced to specific internal naming limits, and removed by changing only temporary naming/storage logic.

### Moderate-to-high confidence: current probability-weight covariance formula

The current rule—normalized probability weights, linear weighting of moments, squared weights in the sandwich covariance meat, and observation-count-based finite-sample factors—is internally coherent and invariant to multiplying every probability weight by a constant.

**Why confidence is not labeled unqualified high:** this is statistically well motivated and has passed numerical checks, but it defines the public meaning of weighted `aivreg` estimation. Sophie and Claire should confirm that it matches the intended estimand and the weighting convention used in the paper and prior applications.

### Moderate confidence: clustered implementation contract

The proposed clustered covariance aggregates weighted score/moment contributions within cluster, uses a cluster-independent overall sample moment, and applies the standard cluster finite-sample factor based on the number of observations, regressors, and clusters.

**Why confidence is moderate:** the algebra and invariance tests are persuasive, but this was reconstructed from code, documentation, and statistical conventions rather than confirmed against an original authorial derivation.

### Moderate confidence: suppressing J for one-step GMM and 2SLS

The current development line suppresses the Hansen J for one-step GMM and the command's 2SLS path so that only the efficient two-step result is labeled “Hansen J.” This is conservative and avoids presenting a non-efficient criterion value as though it were the standard efficient test.

**Why confidence is moderate:** this is a defensible reporting policy, but it is a design choice. A separately constructed and clearly labeled overidentification test could in principle be offered after one-step GMM or 2SLS.

### Low-to-moderate confidence: generalized rank-based degrees of freedom in rank-deficient cases

A prior proposed rule calculated J degrees of freedom as a numerical covariance rank minus a numerical parameter/Jacobian rank. On one synthetic six-AIV fixture this produced 14 rather than a hard-coded 15.

**Why confidence is limited:** generalized rank logic can be mathematically defensible, but numerical rank depends on tolerances and the resulting statistic may not have the ordinary chi-squared reference distribution without additional regularity conditions. The conservative recommendation is **not** to make this a silent public feature. Suppress/refuse J when rank conditions fail unless the authors deliberately approve and document a generalized test.

### Low-to-moderate confidence: relaxing one scale-invariance tolerance

On an ill-conditioned synthetic fixture, multiplying all probability weights by 17 changed the coefficient by about `3 × 10^-8`; covariance and J differences were much smaller. A proposed test change would loosen the coefficient tolerance from `10^-8` to `10^-6`.

**Why confidence is limited:** this looks like numerical generalized-inverse sensitivity, not a substantively different estimate, but a tolerance should not be relaxed merely because a candidate missed it. The fixture's conditioning and a precommitted tolerance should be reviewed before the test is changed.

## 5. Work that remains

### Before another full test run

1. Obtain the three human rulings below, especially the rank-deficient J policy.
2. Amend the written estimator contract and independent test expectations to match those rulings.
3. Decide whether to fix or explicitly exclude the optional GMM `savefirst` long-name surface and inert/unsupported options.

### Technical validation

4. Freeze the exact candidate, test harness, numerical targets, dependencies, and Stata version under immutable identities.
5. Run one complete independent job from the beginning: core numerical oracle, focused bug/edge cases, and the inherited regression suite. A partial prior run cannot substitute.
6. Route any finite failures back to the code producer; changes require a new candidate identity and a complete rerun.
7. After a full technical pass, obtain an independent release-QA verdict on the exact candidate—not on an earlier hash.

### Packaging and release preparation

8. Reconcile the candidate with the live SSC package and both named repositories.
9. Write a new `aivreg.sthlp` that accurately documents methods, weights, J availability, returned results, long-name limitations, dependencies, errors, and examples.
10. Prepare a concise SSC changelog explaining user-visible corrections and compatibility implications.
11. Assemble a manifest-hashed package and test installation, examples, estimation, and uninstallation in a clean Stata environment.
12. Obtain final independent package QA and collaborator review. Alex retains the decision and act of emailing the update to SSC.

## 6. The three most important matters for human review

### 1. What exactly should be reported as the J test?

**Recommended default:** report the conventional Hansen J only after efficient two-step GMM when the moment covariance and parameter/Jacobian system have sufficient rank. Use the standard full-rank degrees of freedom—independent moment conditions minus estimated parameters. If rank conditions fail, suppress J and give a clear warning rather than silently substituting a generalized numerical-rank rule.

Please also confirm whether one-step GMM and 2SLS should continue to suppress J, or whether the package should calculate a separately labeled overidentification test for either path.

### 2. Does the weighted and clustered GMM contract match the intended estimator?

Please confirm or correct the following public rule:

- GMM/2SLS supports probability weights;
- weights are normalized by their sample mean;
- point moments use normalized weights linearly;
- covariance score products use squared normalized weights;
- finite-sample factors depend on observation and cluster counts, not the raw sum of weights;
- clustered covariance sums weighted score contributions within cluster; and
- rescaling all probability weights by a constant leaves coefficient, covariance, and J unchanged apart from numerical precision.

If the paper or original derivation intended a different sampling-weight interpretation, that should control the implementation and tests.

### 3. What public surface should this maintenance release promise?

The proposed narrow release policy is:

- retain the existing single-AIV ratio estimator and multi-AIV `2sls` and `gmm` methods;
- permit the ratio path's historically documented weight forms;
- support probability weights only for GMM/2SLS and loudly reject analytic/frequency weights there;
- retain fixed-effects support where documented;
- fix or explicitly exclude optional saved-first-stage behavior with long names; and
- reject or clearly scope options that are parsed but inactive on a method.

Please identify any workflow used by the paper or collaborators that this policy would accidentally exclude or change.

## 7. If this thread were decommissioned: five things the next agent must know

1. **Do not confuse the public release with the working candidate.** SSC still distributes `aivreg` 1.0.0. The newest working candidate is bannered 1.1.1 and has SHA-256 `d26002eadf9a8d049024d1abb39a151c7d3c4899831c109d9e68f5b5238a10a3`; it is not frozen, independently accepted, installed, or public.
2. **The immediate blocker is a statistical-contract decision, not unfinished coding.** The current test bundle encodes a generalized rank-based J degrees-of-freedom rule. Alex has questioned that inference. The recommended conservative decision is conventional full-rank J and suppression/refusal when rank deficient. Record the human ruling before changing tests or running the integration job.
3. **Preserve independence among code, tests, and acceptance.** The code producer has fixed unsupported weights and the tested ratio long-name failures; targeted self-tests pass. A separate test owner must run the exact candidate against an independently specified oracle and complete suite, and a separate release reviewer must issue the final technical verdict.
4. **No complete release test has yet passed on the newest candidate.** An earlier candidate passed 44 core numerical rows but then failed five focused rows; two code defects have since been fixed, while the rank-deficient target and numerical-tolerance row still require resolution. The inherited suite was not reached in that run. Start the final run from the beginning after the contract is settled.
5. **A technical pass is not the end of the SSC job.** Reconcile all three lineages (SSC, Shusheng's public repository, and Sophie's repository), produce accurate help and changelog files, assemble and hash the package, perform a clean-room install/test/uninstall, obtain independent package QA and collaborator review, and then give Alex the exact archive and evidence. Only Alex authorizes and sends the SSC update.

## Bottom line

There is now a credible corrected working candidate and substantial evidence that the ordinary efficient two-step GMM J calculation works. The command is nevertheless **not yet SSC-ready**. The highest-value collaborator input is to settle the narrow J-reporting/rank policy, confirm the probability-weighted clustered estimator contract, and confirm the intended supported interface. Once those are recorded, the remaining path is mostly finite engineering, independent regression testing, documentation, repository reconciliation, and clean-package verification.

