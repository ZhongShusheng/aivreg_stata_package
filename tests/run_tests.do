* run_tests.do -- aivreg regression suite
*
* Usage (run from the repository root):
*   do tests/run_tests.do
*       tests ./aivreg.ado, label "current"
*   do tests/run_tests.do <label> <adodir>
*       tests <adodir>/aivreg.ado under <label>, e.g. a version extracted
*       from git with:  python tests/get_version.py v1.0.0
*
* Output: tests/results/<label>_results.csv and logs/tests_<label>.log
* Compare against a frozen release with:  python tests/compare_results.py

clear all
set more off

local label "`1'"
local adodir "`2'"
if "`label'" == "" local label "current"
if "`adodir'" == "" local adodir "."

adopath ++ "`adodir'"
which aivreg

capture mkdir "tests/results"
capture mkdir "logs"
log using "logs/tests_`label'.log", replace text

* ---------------------------------------------------------------- helpers
capture program drop record
program define record
    * record <testname> <rc> : append one CSV row from current e() results
    args tname rc
    local N = cond(e(N) < ., string(e(N), "%18.0g"), ".")
    local b = "."
    local se = "."
    capture local b = string(el(e(b),1,1), "%21.0g")
    if "`b'" == "." & e(beta) < . local b = string(e(beta), "%21.0g")
    capture local se = string(sqrt(el(e(V),1,1)), "%21.0g")
    if "`se'" == "." {
        foreach s in SE_asymp SE_AR SE_boot SE_gmm SE_2sls {
            if "`se'" == "." & e(`s') < . local se = string(e(`s'), "%21.0g")
        }
    }
    local pF   = cond(e(Partial_F) < ., string(e(Partial_F), "%21.0g"), ".")
    local pR2  = cond(e(Partial_R2) < ., string(e(Partial_R2), "%21.0g"), ".")
    local Jval = cond(e(Jval)  < ., string(e(Jval),  "%21.0g"), ".")
    local Jp   = cond(e(pval_J)< ., string(e(pval_J),"%21.0g"), ".")
    local Jdf  = cond(e(J_df)  < ., string(e(J_df),  "%18.0g"), ".")
    local esN  = "."
    capture {
        qui count if e(sample)
        local esN = r(N)
    }
    file open __R using "tests/results/${TESTVER}_results.csv", write append
    file write __R "`tname',`rc',`N',`b',`se',`pF',`pR2',`Jval',`Jdf',`Jp',`esN'" _n
    file close __R
end

global TESTVER "`label'"
capture erase "tests/results/`label'_results.csv"
file open __R using "tests/results/`label'_results.csv", write replace
file write __R "test,rc,N,b,se,Partial_F,Partial_R2,Jval,J_df,pval_J,esample_N" _n
file close __R

* ================================================================
* SECTION A - normal usage (README/demo patterns)
* ================================================================

use safety_aivreg_example.dta, clear

* --- A1 ratio path, default (Anderson-Rubin) SEs ---
di _n "===== TEST A1_ratio_default ====="
capture noisily aivreg wage safety, aiv(afqt_1_1981)
record A1_ratio_default `=_rc'

* --- A2 ratio path, asymptotic SEs ---
di _n "===== TEST A2_ratio_asymp ====="
capture noisily aivreg wage safety, aiv(afqt_1_1981) vce(asymp)
record A2_ratio_asymp `=_rc'

* --- A3 ratio path, bootstrap SEs (seeded) ---
di _n "===== TEST A3_ratio_boot ====="
capture noisily aivreg wage safety, aiv(afqt_1_1981) vce(boot) reps(50) seed(42)
record A3_ratio_boot `=_rc'


use housing_aivreg_example.dta, clear

* --- A4 ratio + factor-variable controls + if ---
di _n "===== TEST A4_ratio_controls_if ====="
capture noisily aivreg log_hpvi medianaqi if year==2019, aiv(rank) control(i.rooms) vce(asymp)
record A4_ratio_controls_if `=_rc'

* --- A5 ratio + fixed effects ---
di _n "===== TEST A5_ratio_fe ====="
capture noisily aivreg log_hpvi medianaqi if year==2019, aiv(rank) fe(rooms) vce(asymp)
record A5_ratio_fe `=_rc'

* --- A6 multi-amenity (auto-switch to GMM) ---
di _n "===== TEST A6_multiamenity_gmm ====="
capture noisily aivreg log_hpvi medianaqi crime_rate if year==2019, aiv(rank) fe(rooms)
record A6_multiamenity_gmm `=_rc'

* --- A7 two-step GMM, multiple anti-IVs ---
di _n "===== TEST A7_gmm_twostep ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms)
record A7_gmm_twostep `=_rc'

* --- A8 one-step GMM ---
di _n "===== TEST A8_gmm_onestep ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) onestep
record A8_gmm_onestep `=_rc'

* --- A9 2SLS ---
di _n "===== TEST A9_2sls ====="
capture noisily aivreg 2sls log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms)
record A9_2sls `=_rc'

* --- A10 clustered GMM (cluster on fips) ---
di _n "===== TEST A10_gmm_cluster ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) cluster(fips)
record A10_gmm_cluster `=_rc'

* --- A11 GMM with probability weight ---
qui {
    set seed 20260830
    gen double wvar = 0.5 + runiform()
}
di _n "===== TEST A11_gmm_pweight_bare ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) weight(wvar)
record A11_gmm_pweight_bare `=_rc'

* --- A12 same but all weights multiplied by 17 (scale invariance) ---
qui gen double wvar17 = 17*wvar
di _n "===== TEST A12_gmm_pweight_x17 ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) weight(wvar17)
record A12_gmm_pweight_x17 `=_rc'

* --- A13 ratio path with bracketed aw weight ---
di _n "===== TEST A13_ratio_aw_bracket ====="
capture noisily aivreg log_hpvi medianaqi if year==2019, aiv(rank) weight([aw=wvar]) vce(asymp)
record A13_ratio_aw_bracket `=_rc'

* ================================================================
* SECTION B - corner cases
* ================================================================

* --- B1 [in] range on ratio path ---
di _n "===== TEST B1_ratio_in ====="
capture noisily aivreg log_hpvi medianaqi in 1/15000, aiv(rank) vce(asymp)
record B1_ratio_in `=_rc'

* --- B2 [in] range on GMM path ---
di _n "===== TEST B2_gmm_in ====="
capture noisily aivreg gmm log_hpvi medianaqi in 1/15000, aiv(rank crime_rate) control(rooms)
record B2_gmm_in `=_rc'

* --- B3 if + in combined on GMM path ---
di _n "===== TEST B3_gmm_if_in ====="
capture noisily aivreg gmm log_hpvi medianaqi if year>=2015 in 1/25000, aiv(rank crime_rate) control(rooms)
record B3_gmm_if_in `=_rc'

* --- B4 explicit [aw=] on GMM path (should reject loudly) ---
di _n "===== TEST B4_gmm_aw_bracket ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) weight([aw=wvar])
record B4_gmm_aw_bracket `=_rc'

* --- B5 explicit [fw=] on GMM path (should reject loudly) ---
qui gen int fwvar = 1 + mod(_n, 3)
di _n "===== TEST B5_gmm_fw_bracket ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) weight([fw=fwvar])
record B5_gmm_fw_bracket `=_rc'

* --- B6 zero/negative weights on GMM path (should refuse loudly)
qui {
    gen double wbad = wvar
    replace wbad = 0  in 1/50
    replace wbad = -1 in 51/60
}
di _n "===== TEST B6_gmm_negzero_weight ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) weight(wbad)
record B6_gmm_negzero_weight `=_rc'

* --- B7 missing weights (obs should drop from analytic sample) ---
qui {
    gen double wmiss = wvar
    replace wmiss = . if mod(_n, 10)==0
}
di _n "===== TEST B7_gmm_missing_weight ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) weight(wmiss)
record B7_gmm_missing_weight `=_rc'

* --- B8 too few clusters ---
qui gen byte twoclust = 1 + (_n > _N/2)
di _n "===== TEST B8_gmm_two_clusters ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) cluster(twoclust)
record B8_gmm_two_clusters `=_rc'

* --- B9 long variable names, ratio path (32-char legal names) ---
di _n "===== TEST B9_ratio_longnames ====="
qui {
    gen double outcome_variable_with_a_very_lon = log_hpvi
    gen double amenity_variable_with_a_very_lon = medianaqi
    gen double antiiv_variable_with_a_very_long = rank
    gen double control_variable_with_a_very_lon = crime_rate
}
capture noisily aivreg outcome_variable_with_a_very_lon amenity_variable_with_a_very_lon if year==2019, ///
    aiv(antiiv_variable_with_a_very_long) control(control_variable_with_a_very_lon) vce(asymp)
record B9_ratio_longnames `=_rc'

* --- B10 long variable names, GMM path (two distinct long-named anti-IVs) ---
di _n "===== TEST B10_gmm_longnames ====="
qui gen double antiiv2_variable_with_a_very_lo = crime_rate
capture noisily aivreg gmm outcome_variable_with_a_very_lon amenity_variable_with_a_very_lon if year==2019, ///
    aiv(antiiv_variable_with_a_very_long antiiv2_variable_with_a_very_lo)
record B10_gmm_longnames `=_rc'

* --- B11 e(sample) integrity after error: failed call must not leave stale J ---
di _n "===== TEST B11_state_after_error ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms)
local J_before = cond(e(Jval)<., string(e(Jval),"%21.0g"), ".")
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) control(rooms) weight(wbad)
* whatever the rc, e() should not still claim the *previous* successful J as its own
record B11_state_after_error `=_rc'
di "J from prior successful call was `J_before'"

* --- B12 GMM with fe() + cluster + weights together ---
di _n "===== TEST B12_gmm_fe_clus_w ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate) fe(rooms) cluster(fips) weight(wvar)
record B12_gmm_fe_clus_w `=_rc'

* --- B13 single-AIV via gmm keyword (just-identified; J should be 0/df 0 or suppressed) ---
di _n "===== TEST B13_gmm_justidentified ====="
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank) control(rooms)
record B13_gmm_justidentified `=_rc'

* --- B14 collinear anti-IV added (rank + copy of rank): moment system must not silently collapse ---
di _n "===== TEST B14_gmm_collinear_aiv ====="
qui gen double rank_copy = rank
capture noisily aivreg gmm log_hpvi medianaqi if year==2019, aiv(rank rank_copy) control(rooms)
record B14_gmm_collinear_aiv `=_rc'

* --- B15 estimator typo must error, not run ---
di _n "===== TEST B15_bad_estimator ====="
capture noisily aivreg gmmm log_hpvi medianaqi if year==2019, aiv(rank crime_rate)
record B15_bad_estimator `=_rc'

* --- B16 non-consecutive integer fe values (Josh: integers not starting at 1) ---
qui gen int rooms_shift = rooms*10 + 7
di _n "===== TEST B16_fe_nonconsecutive ====="
capture noisily aivreg log_hpvi medianaqi if year==2019, aiv(rank) fe(rooms_shift) vce(asymp)
record B16_fe_nonconsecutive `=_rc'

log close
di "SUITE DONE for `label'"
