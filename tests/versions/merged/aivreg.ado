*! aivreg 1.1.2 30aug2026 (WORKING MERGE DRAFT, not release-ready: AI candidate d26002ea + Josh esample/[in] updates; conventional J df + rank-fail suppression per 30aug2026 ruling)

cap program drop aivreg
program define aivreg, eclass
    version 17

	* TEST_ACCEPTANCE_MAP_v0 R-06 / DESIGN_SPEC_v1 §B (Gate-1 frozen): a failed
	* aivreg call may not leave plausible results from a prior aivreg call.
	* Clear only prior aivreg results so unrelated estimators are untouched.
	if "`e(cmd)'" == "aivreg" ereturn clear

	* Check required packages locally and report all missing ones at once

	local missing ""

	capture which ivreg2
	if (_rc) local missing "`missing' ivreg2"

	capture which ranktest
	if (_rc) local missing "`missing' ranktest"

	capture which reghdfe
	if (_rc) local missing "`missing' reghdfe"

	capture which ivreghdfe
	if (_rc) local missing "`missing' ivreghdfe"

	capture which distinct
	if (_rc) local missing "`missing' distinct"

	if ("`missing'" != "") {
		di as error "The following required packages are not installed:"
		foreach pkg of local missing {
			di as error "  - `pkg'"
		}
		di as error "Install missing packages using: ssc install <package>"
		exit 198
	}
	
    /* 1.  Peek at first token ------------------------------------------ */
    gettoken maybe_est rest : 0          // maybe_est = first word

    capture confirm variable `maybe_est'
    if _rc {                             // first word is NOT a variable
        local estimator "`maybe_est'"    // so it must be the estimator
        local 0 "`rest'"                 // put the remainder back for parsing
    }
    else {                               // first word IS a variable
        local estimator "ratio"            // default estimator
        local 0 "`maybe_est' `rest'"     // put *all* words back for parsing
    }

	local estimator = subinstr(strtrim("`estimator'"), " ", "", .)

	* FIX 30aug2026: validate the estimator token up front. Without this, a
	* typo like "gmmm" with multiple anti-IVs fell into the GMM branch and,
	* failing the =="gmm" check below, silently ran ONE-step GMM.
	if !inlist("`estimator'", "ratio", "lin", "ols", "gmm", "2sls") {
		di as error "Invalid estimator `estimator'.  Use ratio (default), gmm, or 2sls."
		exit 198
	}

    /* 2.  Now parse the standard pieces (including the varlist!) -------- */
    syntax varlist(fv) [if] [in], aiv(varlist) ///
        [control(string) fe(varlist) weight(string) eststo(string) ///
         vce(string) reps(string) seed(string) cluster(varlist)  ///
         savefirst firststo(string) displayaiv onestep twostep /// 
		 initialweightmatrix(string) weightingmatrix(string) ignoresingularity]

    /* AIVREG-2 FIX (2026-08-04, SW-DesignAgent): normalize weight() so each
       engine gets the form it needs. aivreglinear (ratio) appends the BRACKETED
       expression into regress; aivgmm confirms a BARE varname. Loud error on
       malformed input. wvar = bare varname; wexp = [type=var]. */
    local wvar ""
    local wexp ""
    local __wbrack ""
    if `"`weight'"' != "" {
        local __win = subinstr(`"`weight'"', " ", "", .)
        if substr(`"`__win'"',1,1) == "[" {
            local __wbrack "1"
            local __in2 = subinstr(subinstr(`"`__win'"',"[","",.),"]","",.)
            if strpos("`__in2'","=") == 0 {
                di as error "weight(): malformed weight expression: `weight'"
                exit 198
            }
            local __wt  = substr("`__in2'",1,strpos("`__in2'","=")-1)
            local wvar  = substr("`__in2'",strpos("`__in2'","=")+1,.)
            if "`__wt'"=="aweight" local __wt "aw"
            if "`__wt'"=="pweight" local __wt "pw"
            if "`__wt'"=="fweight" local __wt "fw"
            if !inlist("`__wt'","aw","pw","fw") {
                di as error "weight(): unrecognized weight type '`__wt''; use aw, pw, or fw"
                exit 198
            }
        }
        else {
            local __wt "aw"
            local wvar "`__win'"
        }
        capture confirm numeric variable `wvar'
        if _rc {
            di as error "weight(): '`wvar'' is not a numeric variable"
            exit 198
        }
        local wexp "[`__wt'=`wvar']"

        /* LEAN_RECOVERY_SPRINT_20260825 item 1 (Gate-3 v2 rows gmm_aw/twosls_fw):
           gmm/2sls are probability-weight-only (DESIGN_SPEC_v1 par. B). An
           EXPLICITLY declared non-pw bracket type must refuse loudly here
           instead of having its declared type silently discarded downstream.
           Bare weight(w) remains canonicalized per contract, and the ratio
           path keeps its documented permissive bracket syntax. */
        local __nAIV = wordcount("`aiv'")
        if ("`estimator'" == "gmm" | "`estimator'" == "2sls" | `__nAIV' > 1) ///
            & "`__wbrack'" == "1" & "`__wt'" != "pw" {
            di as error "weight(): [`__wt'=`wvar'] is not supported for gmm/2sls; these methods accept probability weights only. Use weight(`wvar') or weight([pw=`wvar'])."
            exit 101
        }
    }


    /* 3.  How many anti-IVs?  Decide which engine to call --------------- */

	if "`initialweightmatrix'" != "" {
		local weightmatrix "`initialweightmatrix'"
	}
	if "`weightingmatrix'" != "" {
		local weightmatrix "`weightingmatrix'"
	}

    local nvars = wordcount("`aiv'")
	
    if "`estimator'" == "gmm" | "`estimator'" == "2sls" | `nvars' > 1 {
		
		if "`onestep'" == "" & "`estimator'" == "gmm" {
			local twostep "twostep"
		}
		else {
			local onestep "onestep"
		}
		
		if "`estimator'" == "gmm" | `nvars' > 1 {
			local estimatordisp "GMM_`onestep'`twostep'"	
			local estimatordisp = subinstr(strtrim("`estimatordisp'"), " ", "", .)
						local estimatordisp = subinstr(strtrim("`estimatordisp'"), "_", " ", .)
		}
		if "`estimator'" == "2sls" {
			local estimatordisp "2SLS_`onestep'`twostep'"	
			local estimatordisp = subinstr(strtrim("`estimatordisp'"), " ", "", .)
			local estimatordisp = subinstr(strtrim("`estimatordisp'"), "_", " ", .)			
		}
		
		if "`estimator'" != "gmm" & "`estimator'" != "2sls" {
			dis as text "Warning: Multiple anti-IVs inputted, switching to GMM"			
		}
		

		if "`estimator'" == "2sls" {

			local 2sls = "2sls"
		}
		
		if "`twostep'" == "twostep" & `nvars' > 1 {

			quietly {
			aivgmm `varlist' `if' `in', aiv(`aiv') control(`control') /// 
				cluster(`cluster') weight(`wvar') fe(`fe') /// 
				weightmatrix(`weightmatrix') `2sls' estimatordisp(`estimatordisp') ///
				ignoresingularity
				
			local 2sls = ""
			matrix weightmatrix = e(S)
			matrix weightmatrix = invsym(weightmatrix)
			local weightmatrix = "weightmatrix"
			}
		}
		

		aivgmm `varlist' `if' `in', aiv(`aiv') control(`control') /// 
			eststo(`eststo') cluster(`cluster') weight(`wvar') fe(`fe') /// 
			weightmatrix(`weightmatrix') `2sls' `savefirst' /// 
			firststo(`firststo') estimatordisp(`estimatordisp') `ignoresingularity'
			
    }
    else if inlist("`estimator'", "ratio", "lin", "ols") {
        aivreglinear `varlist' `if' `in', aiv(`aiv') ///
            control(`control') fe(`fe') weight(`wexp') eststo(`eststo') ///
            vce(`vce') reps(`reps') seed(`seed') cluster(`cluster')       ///
            `savefirst' firststo(`firststo') `displayaiv'
    }
    else {
        di as error "Invalid estimator `estimator'.  Use ratio (default), gmm, or 2sls."
        exit 198
    }
end

cap program drop _aivreg_escalar
program define _aivreg_escalar, eclass
    version 17
    gettoken statprefix rest : 0
    gettoken vname scalarval : rest

    local nm "`statprefix'`vname'"
    if strlen("`nm'") > 32 {
        local clean = strtoname("`vname'")
        local pstub = substr("`statprefix'", 1, 8)
        local room = 32 - strlen("`pstub'") - 3
        if `room' < 1 local room 1
        local stem = substr("`clean'", 1, `room')
        local nm "`pstub'`stem'"

        local scalars : e(scalars)
        local i = 1
        while strpos(" `scalars' ", " `nm' ") {
            local suffix "_`i'"
            local room = 32 - strlen("`suffix'")
            local nm = substr("`pstub'`stem'", 1, `room') + "`suffix'"
            local ++i
        }
    }
    local nm = strtoname("`nm'")
    local nm = substr("`nm'", 1, 32)

    ereturn scalar `nm' = `scalarval'
end


cap prog drop aivreglinear
prog def aivreglinear, eclass
	* R-06 stale-state hygiene (see aivreg entry)
	if "`e(cmd)'" == "aivreg" ereturn clear
	version 17
	
	syntax varlist(fv) [if] [in], aiv(varlist) [control(string)] [fe(varlist)] [weight(string)] [eststo(string)] [vce(string)] [reps(string)] [seed(string)] [cluster(varlist)] [savefirst] [firststo(string)] [displayaiv]

	* MERGE 30aug2026 (Josh): mark the analytic sample on the full dataset so
	* e(sample) can be posted correctly after estimation. Negative-weight
	* exclusion removed per 30aug2026 ruling: invalid weights must fail loudly
	* in the estimator rather than being silently dropped from the sample.
	local aivreg_orig_varlist "`varlist'"

	tempvar aivreg_sample
	tempvar aivreg_sort
	quietly gen long `aivreg_sort' = _n
	capture drop `aivreg_sample'
	quietly gen byte `aivreg_sample' = 0
	local aivreg_weightopt "`weight'"
	local weight ""
	quietly replace `aivreg_sample' = 1 `if' `in'
	local weight "`aivreg_weightopt'"
	fvrevar `aivreg_orig_varlist' if `aivreg_sample'
	markout `aivreg_sample' `r(varlist)'
	markout `aivreg_sample' `aiv' `fe' `cluster'
	if "`control'" != "" {
		fvrevar `control' if `aivreg_sample'
		markout `aivreg_sample' `r(varlist)'
	}
	if "`weight'" != "" {
		local aivreg_weightvar "`weight'"
		local aivreg_weightvar = subinstr("`aivreg_weightvar'", "[", "", .)
		local aivreg_weightvar = subinstr("`aivreg_weightvar'", "]", "", .)
		local aivreg_weightvar = subinstr("`aivreg_weightvar'", " ", "", .)
		if strpos("`aivreg_weightvar'", "=") {
			local aivreg_weightvar = substr("`aivreg_weightvar'", strpos("`aivreg_weightvar'", "=") + 1, .)
		}
		markout `aivreg_sample' `aivreg_weightvar'
	}
	if "`fe'" != "" {
		quietly {
			foreach fevar of local fe {
				tempvar aivreg_gsz
				bysort `fevar': egen long `aivreg_gsz' = total(`aivreg_sample') if `aivreg_sample'
				quietly replace `aivreg_sample' = 0 if `aivreg_sample' & `aivreg_gsz' == 1
			}
			sort `aivreg_sort'
		}
	}

preserve
	
	****************************************************************************
	* Sort factor and continuous variables
	****************************************************************************
	
	* Convert factor variables to dummies
	* remove i. and c.
	local varlist2 ""
	local varlist "`varlist'"
	local categ ""
	
foreach v of local varlist {

    local u ""
    local iscat 0
    local base ""

    * --- factor-variable patterns ---
    * ib#.var   (explicit base)
    if regexm("`v'", "^ib([0-9]+)\.(.+)$") {
        local base = regexs(1)
        local u    = regexs(2)
        local iscat 1
    }
    * i.var     (no explicit base)
    else if regexm("`v'", "^i\.(.+)$") {
        local u = regexs(1)
        local iscat 1
    }
    * c.var     (continuous)
    else if regexm("`v'", "^c\.(.+)$") {
        local u = regexs(1)
        local iscat 0
    }
    * plain variable name
    else {
        local u "`v'"
        local iscat 0
    }

    * record categorical vars and (optional) requested base
    if `iscat' {
        local categ "`categ' `u'"
        if "`base'" != "" local base_`u' "`base'"
    }
    else {
        * reject string continuous vars
        local typ: type `u'
        local typ = substr("`typ'", 1, 3)
        if "`typ'" == "str" {
            di as error "`u': string variables may not be used as continuous variables"
            exit 198
        }
    }

    local varlist2 "`varlist2' `u'"
}
	local varlist `varlist2'
	
	* throw an error if a variable is a string
	
	* if the explanatory variable is categorical

	local varlist2 `varlist'
	local varlist_rows `varlist'
	local categ `categ'
	if "`categ'" != ""{
			foreach v of varlist `categ' {

		quiet distinct `v'
		
		quiet levelsof `v', local(levels)

		local llist 
		local llist_rows
			foreach l of local levels {
				*gen `v'`l' = (`v' == `l')
				
				capture confirm variable `v'`l'
				if _rc {
					quiet gen `v'`l' = (`v' == `l')
				}
				else {
					quiet replace `v'`l' = (`v' == `l')
				}

				
				*label variable `v'`l' "`l'.`v'"
				local base_label : variable label `v'
				label variable `v'`l' "`base_label'=`l'"

				local llist "`llist' `v'`l'"
				local llist_rows "`llist_rows' `l'.`v'"

		}
		
		* pick base: user-specified (ib#.) if provided; otherwise lowest level
		local base = "`base_`v''"
		if "`base'" == "" {
			local base : word 1 of `levels'   // lowest integer level
		}
		else {
			* enforce that requested base exists in sample
			local ok = 0
			foreach l of local levels {
				if "`l'" == "`base'" local ok = 1
			}
			if `ok' == 0 {
				di as error "Base level ib`base'.`v' not present in estimation sample"
				exit 198
			}
		}

		quietly replace `v'`base' = 0
			
			local varlist2 `varlist2'
			local varlist_rows `varlist_rows'
			local v `v'
			local varlist2 : list varlist2 - v
			local varlist_rows : list varlist_rows - v
			local varlist2 "`varlist2' `llist'"
			local varlist_rows "`varlist_rows' `llist_rows'"
	}
	
	}
	
	****************************************************************************
	* Record user specified options and set defaults where appropriate
	****************************************************************************
	
	local varlist = "`varlist2'"
	* firststo
	if "`firststo'" != ""{
		local savefirst = "savefirst"
	}
	
	* displayaiv
	if "`displayaiv'" != ""{
		local displayaiv = "displayaiv"
	}
	
	* aiv is the new h
	local h "`aiv'"

	* LEAN_RECOVERY_SPRINT_20260825 item 2 (Gate-3 row long_name_ratio_rc0):
	* "_ivreg2_" + AIV name must fit Stata's 32-character name limit, and
	* ivreg2's savefirst derives its store name from the endogenous variable.
	* For near-limit AIV names (which previously crashed rc 198), run the
	* naming-critical estimation on a bounded clone; short names keep the
	* exact previous behavior because h_est == h.
	* Bound: estimates-store names carry a hidden _est_ marker variable, so the
	* effective store-name limit is 27 chars; "_ivreg2_" leaves 19 for the alias.
	local h_est "`h'"
	if wordcount("`h'") == 1 & strlen("_ivreg2_`h'") > 27 {
		local __alias = substr("`h'", 1, 19)
		local __ai = 0
		capture confirm new variable `__alias'
		while _rc {
			local ++__ai
			local __alias = substr("`h'", 1, 19 - strlen("`__ai'"))
			local __alias "`__alias'`__ai'"
			capture confirm new variable `__alias'
		}
		quietly clonevar `__alias' = `h'
		local h_est "`__alias'"
	}

	* eststo option
	if "`eststo'" != "" {
		local est_opt = 1
	}
	
	****************************************************************************
	* Keep track of estimation objects
	****************************************************************************
	
	* to make sure ivreg2 works
	capture ereturn drop `eststo'
	capture ereturn drop _ivreg2_`h_est' 
	capture ereturn drop `firststo'
	
	* allow savefirst, not just savefirst(savefirst)

	if "`savefirst'" != "savefirst" {
		local savefirst ""
	}
	else {
		local savefirst "savefirst"
	}
	
	*Get the full list of stored models to drop others later
	local saved_models "" 
	quietly est dir
	foreach model_for_loop1 in `r(names)' { 
		local saved_models "`saved_models' `model_for_loop1'"
	}
	* make eststo if empty
	if "`eststo'" == "" {
		quietly {
			estimates dir
			local models " `r(names)' "   // pad with spaces

			local check_est_num = 1
			while strpos("`models'", " est`check_est_num' ") {
				local ++check_est_num
			}
			local eststo est`check_est_num'
		}
	}



	****************************************************************************
	* Catch each standard error calculation option
	****************************************************************************
	
	* make sure entries are valid
	* first catch bootstrap case
	if inlist("`vce'", "b", "bo", "boo", "boot", "boots", "boots") | inlist("`vce'", "bootst", "bootstr", "bootstra", "bootstrap"){
		local vce "boot"
		
		capture confirm number `reps'
		if _rc != 0 { 
			local reps 50
		}
		else if mod(`reps', 1) != 0 {
			local reps 50
		}
		
		if "`seed'" != "" {
		capture confirm number `seed'
		if _rc != 0 { 
			dis " "
			display "Error: seed must be a number."
			exit
		}
		}
		
	}
	* next catch asymptotic case
	else if inlist("`vce'", "as", "asy", "asym", "asymp", "asympt") | inlist("`vce'", "asympto", "asymptot", "asymptoti", "asymptotic"){
		local vce = "asymp"
		
		if "`seed'" != "" | "`reps'" != "" {
			dis " "
			dis "WARNING: options seed or reps are invalid in asymptotic SE"
		}
	}
	* catch Anderson-Rubin case
	else if inlist("`vce'", "", "ar", "AR", "andersonrubin", "anderson-rubin") | inlist("`vce'", "AndersonRubin", "Anderson-Rubin", "Anderson Rubin", "anderson rubin") {	
		if "`seed'" != "" | "`reps'" != "" {
			dis " "
			dis "WARNING: options seed or reps are invalid in asymptotic SE"
		}
	}
	* No case detected
	else{
		dis " "
		dis "Error in vce specification: " "`vce'" " unrecognized. Proceeding with default."
		
		local vce = ""
	}
	
	****************************************************************************
	* Count variables and make a list for loops
	****************************************************************************
	
	local j=0

	foreach v of varlist `varlist'{
		if `j'==0 {
			local w `v'
		}

		else {
			if `j'==1 {
				local zlist `v'
			}

			else {
				local zlist `zlist' `v'
			}
		}
		local j=`j'+1
	}

	local proxy_count=0
	local amenity_count=0

	foreach h_var in `h' {
		local proxy_count=`proxy_count'+1
	}

	if `proxy_count'>1 {
		display "Working on cases with multiple proxies"
		exit
	}

	foreach z_var in `zlist' {
		local amenity_count=`amenity_count'+1
	}

	local k=0
	foreach fe_var in `fe' {
		local k=`k'+1
	}
	local varlist_rows `varlist_rows'
	local w `w'
	local varlist_rows : list varlist_rows - w
	
	
	****************************************************************************
	****************************************************************************
	* Start CI cases
	****************************************************************************
	****************************************************************************
	
	****************************************************************************
	* Asymptotic case
	****************************************************************************
	
	if "`vce'" == "asymp"{ // asymptotic case
	quietly {
	if  "`fe'" != "" {
			qui ivreghdfe `varlist' (`h_est' = `varlist') `control' `if' `in' `weight', absorb(`fe') cluster(`cluster') savefirst
			eststo `eststo'
	}
	else {
			qui ivreg2 `varlist' `control' (`h_est' = `varlist') `if' `in' `weight', cluster(`cluster') savefirst
			eststo `eststo'
	}
	}
	
	
	* get first stage estimates
	qui estimates restore _ivreg2_`h_est'
	local n = `=e(N)'
	local k = `=e(df_m)'
	local betaw = e(b)[1, "`w'"]
	local sew = e(V)["`w'","`w'"]
	local sew = sqrt(`sew')
	local tsw = `betaw' / `sew'
	local partial_F = (`tsw')^2

	
	* Create the table to display
	* First Stage output option
	if "`savefirst'" == "savefirst" {
		dis " "
		dis "{bf:First Stage:}"

	
	
	* This makes the column names for the stats
	collect clear 
	collect get `h' = "Coef.", tags(Col[Coef])
	collect get `h' = "Std. Err.", tags(Col[SE_AR])
	collect get `h' = "t", tags(Col[t_val])
	collect get `h' = "P>|t|", tags(Col[p_more_t])
	collect get `h' = "[95% Conf.", tags(Col[ARCI_lb])
	collect get `h' = "Interval]", tags(Col[ARCI_ub])
	
	* Now loop over each amenity and compute the AIV coefficient 
		foreach z of varlist `w' `zlist' {
		* Make variables
			tempname beta SE n k lb ub val_t test_stat 
			sca `n' = e(N)
			sca `k' = e(df_m)
			sca `beta' = _b[`z']
			sca `SE' = _se[`z']
			sca `val_t' = `beta' / `SE'
			local test_stat = 2 * ttail((`n'-`k') , abs(`val_t'))
			sca `lb' = `beta' - 1.96*`SE'
			sca `ub' = `beta' + 1.96*`SE'

		* table
			collect get `z'=`beta', tags(Col[Coef])
			collect get `z'=`SE', tags(Col[SE_AR])
			collect get `z' = `val_t', tags(Col[t_val])
			collect get `z' = `test_stat', tags(Col[p_more_t])
			collect get `z'=`lb', tags(Col[ARCI_lb])
			collect get `z'=`ub', tags(Col[ARCI_ub])
			
			_aivreg_escalar beta `z' `beta'
			_aivreg_escalar SE_asymp `z' `SE'
			_aivreg_escalar t_val `z' `val_t'
			_aivreg_escalar p_more_t `z' `test_stat'
			_aivreg_escalar lb_asymp `z' `lb'
			_aivreg_escalar ub_asymp `z' `ub'
		
		}
		
		collect style header Col, level(hide) // removes Col names
		collect style cell result[`h'], border(bottom) border(top, pattern(nil)) // new column names
		collect style cell, sformat(" %s") // increase spacing
		qui collect layout (result) (Col)
		collect preview
		
		
		dis " "
		dis "{bf:Second Stage:}"
		
	}
	
	* Get some summary stats
	qui estimates restore `eststo'
	tempname n k
	sca `n'=e(N)
	sca `k'=e(df_m)

	* This adds the preamble like reghdfe
	dis " "
	local align_col 60  // Desired column for the "=" alignment
	local padding = `align_col' - length("Number of obs") - length("Anti-IV Regression")
	display "Anti-IV Regression" _dup(`padding') " " "Number of obs" " = " `n'
	local Fstr : display %9.3f `partial_F'
	local Fstr = trim("`Fstr'")
	if "`cluster'" != ""{
		local padding = `align_col' - length("SE clustered by ") - length("`cluster'") - length("Partial F-stat.")
		display "SE clustered by " "`cluster'" _dup(`padding') " " "Partial F-stat." " = `Fstr'" 
	}
	else {
		local padding = `align_col'  - length("Partial F-stat.")
		display _dup(`padding') " " "Partial F-stat." " = `Fstr'"		
	}
	
	* This makes the column names for the stats
	collect clear 
	collect get `w' = "Coef.", tags(Col[Coef])
	collect get `w' = "Std. Err.", tags(Col[SE_AR])
	collect get `w' = "t", tags(Col[t_val])
	collect get `w' = "P>|t|", tags(Col[p_more_t])
	collect get `w' = "[95% Conf.", tags(Col[ARCI_lb])
	collect get `w' = "Interval]", tags(Col[ARCI_ub])
	
	quietly{
	mat b = e(b)
	mat V = e(V)
	
	if "`displayaiv'" == ""{
		mat b = b[1, 2..(`amenity_count' + 1)]		
		mat V = V[2..(`amenity_count'+1), 2..(`amenity_count'+1)] 
	}  
	
	local N = `n'
	local DOF = `n' - `k'
	ereturn post b V, depname(`w') obs(`N') dof(`DOF')
	ereturn local cmd "aivreg"
	eststo `eststo'
	}
	
	if "`displayaiv'" == "displayaiv"{
			foreach z of varlist `zlist' `h' {
		* Make variables
			tempname beta SE lb ub val_t test_stat
			sca `beta' = _b[`z']
			sca `SE' = _se[`z']
			sca `val_t' = `beta' / `SE'
			local test_stat = 2 * ttail(`n' - `k' , abs(`val_t'))
			sca `lb' = `beta' - 1.96*`SE'
			sca `ub' = `beta' + 1.96*`SE'

		* table
			collect get `z'=`beta', tags(Col[Coef])
			collect get `z'=`SE', tags(Col[SE_AR])
			collect get `z' = `val_t', tags(Col[t_val])
			collect get `z' = `test_stat', tags(Col[p_more_t])
			collect get `z'=`lb', tags(Col[ARCI_lb])
			collect get `z'=`ub', tags(Col[ARCI_ub])
			
			_aivreg_escalar beta `z' `beta'
			_aivreg_escalar SE_asymp `z' `SE'
			_aivreg_escalar t_val `z' `val_t'
			_aivreg_escalar p_more_t `z' `test_stat'
			_aivreg_escalar lb_asymp `z' `lb'
			_aivreg_escalar ub_asymp `z' `ub'
	}
	}
	else {
	foreach z of varlist `zlist' {
		* Make variables
			tempname beta SE lb ub val_t test_stat
			sca `beta' = _b[`z']
			sca `SE' = _se[`z']
			sca `val_t' = `beta' / `SE'
			local test_stat = 2 * ttail(`n' - `k' , abs(`val_t'))
			sca `lb' = `beta' - 1.96*`SE'
			sca `ub' = `beta' + 1.96*`SE'

		* table
			collect get `z'=`beta', tags(Col[Coef])
			collect get `z'=`SE', tags(Col[SE_AR])
			collect get `z' = `val_t', tags(Col[t_val])
			collect get `z' = `test_stat', tags(Col[p_more_t])
			collect get `z'=`lb', tags(Col[ARCI_lb])
			collect get `z'=`ub', tags(Col[ARCI_ub])
			
			_aivreg_escalar beta `z' `beta'
			_aivreg_escalar SE_asymp `z' `SE'
			_aivreg_escalar t_val `z' `val_t'
			_aivreg_escalar p_more_t `z' `test_stat'
			_aivreg_escalar lb_asymp `z' `lb'
			_aivreg_escalar ub_asymp `z' `ub'
		
	}
	}
	* Save existing scalars
	tempname savedscalars
	local scalarnames : e(scalars)
	* LEAN_RECOVERY_SPRINT_20260825 item 2 (Gate-3 v2 row long_name_ratio_rc0):
	* index the saved copies -- tempname + full e-scalar name can exceed Stata's
	* 32-char scalar-name limit for near-limit variable names (rc 198 after
	* output). Restore below iterates the same list in the same order.
	local __sv_k = 0
	foreach s of local scalarnames {
		local ++__sv_k
		scalar `savedscalars'_`__sv_k' = e(`s')
	}


	*Output
	collect style header Col, level(hide) // removes Col names
    collect style cell result[`w'], border(bottom) border(top, pattern(nil)) // new column names
	collect style cell, sformat(" %s") // increase spacing
	qui collect layout (result) (Col)
	collect preview
	

	} 

	********************************************************************************
	* Bootstrap case
	********************************************************************************

	else if "`vce'" == "boot"{ // bootstrap case
		
		quietly {
		if "`fe'" != "" {
			qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : ivreghdfe `varlist' (`h' = `varlist') `control' `if' `in' `weight', absorb(`fe') cluster(`cluster') // this only works with verbose
			eststo `eststo'
		}
		else {
			qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : ivreg2 `varlist' `control' (`h' = `varlist') `if' `in' `weight', cluster(`cluster') // this only works with verbose
			eststo `eststo'
		}
		}
		
		
		* get first stage estimates

		if "`fe'" != "" {
				qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : reghdfe `h' `varlist' `control' `if' `in' `weight', absorb(`fe') cluster(`cluster') // this only works with verbose
				eststo _ivreg2_`h_est'
		}
		else {
				qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : reg `h' `varlist' `control' `if' `in' `weight', cluster(`cluster') // this only works with verbose
				
				eststo _ivreg2_`h_est'
		}
		
		* get first stage estimates
		qui estimates restore _ivreg2_`h_est'
		local n = `=e(N)'
		local k = `=e(df_m)'
		local betaw = e(b)[1, "`w'"]
		local sew = e(V)["`w'","`w'"]
		local sew = sqrt(`sew')
		local tsw = `betaw' / `sew'
		local partial_F = (`tsw')^2

		* First Stage output option
		if "`savefirst'" == "savefirst" {
			
			dis " "
			dis "{bf:First Stage:}"

		* Make a table to display
		* This makes the column names for the stats
		collect clear 
		collect get `h' = "Coef.", tags(Col[Coef])
		collect get `h' = "Std. Err.", tags(Col[SE_AR])
		collect get `h' = "t", tags(Col[t_val])
		collect get `h' = "P>|t|", tags(Col[p_more_t])
		collect get `h' = "[95% Conf.", tags(Col[ARCI_lb])
		collect get `h' = "Interval]", tags(Col[ARCI_ub])
		
		
			foreach z of varlist `w' `zlist' {
			* Make variables
				tempname beta SE lb ub val_t test_stat 
				sca `beta' = _b[`z']
				sca `SE' = _se[`z']
				sca `val_t' = `beta' / `SE'
				local test_stat : dis 2 * ttail((`n' - `k') , abs(`val_t'))
				sca `lb' = `beta' - 1.96*`SE'
				sca `ub' = `beta' + 1.96*`SE'

			* table
				collect get `z'=`beta', tags(Col[Coef])
				collect get `z'=`SE', tags(Col[SE_AR])
				collect get `z' = `val_t', tags(Col[t_val])
				collect get `z' = `test_stat', tags(Col[p_more_t])
				collect get `z'=`lb', tags(Col[ARCI_lb])
				collect get `z'=`ub', tags(Col[ARCI_ub])
				
				_aivreg_escalar beta `z' `beta'
				_aivreg_escalar SE_boot `z' `SE'
				_aivreg_escalar t_val `z' `val_t'
				_aivreg_escalar p_more_t `z' `test_stat'
				_aivreg_escalar lb_boot `z' `lb'
				_aivreg_escalar ub_boot `z' `ub'
			
		}
			
			collect style header Col, level(hide) // removes Col names
			collect style cell result[`h'], border(bottom) border(top, pattern(nil)) // new column names
			collect style cell, sformat(" %s") // increase spacing
			qui collect layout (result) (Col)
			collect preview
			
			dis " "
			dis "{bf:Second Stage:}"
			
		}
		
		* get some summary stats
		qui estimates restore `eststo'
		tempname n k
			sca `n' =e(N)
			sca `k' =e(df_m)
			
			
			* This adds the preamble like reghdfe
		dis " "
		local align_col 60  // Desired column for the "=" alignment
		local padding = `align_col' - length("Number of obs") - length("Anti-IV Regression")
		display "Anti-IV Regression" _dup(`padding') " " "Number of obs" " = " `n'
		local padding = `align_col' - length("Uses bootstrapped SE") - length("number of reps")	
		display "Uses bootstrapped SE" _dup(`padding') " " "number of reps" " = " "`reps'"
		local Fstr : display %9.3f `partial_F'
		local Fstr = trim("`Fstr'")
		local padding = `align_col' - length("Partial F-stat.")
		display _dup(`padding') " " "Partial F-stat." " = `Fstr'"
		if length("`seed'") > 0 & "`cluster'" == "" {
				local padding = `align_col' - length("seed")	
				display  _dup(`padding') " " "seed" " = " "`seed'"
		} 
		
		if "`cluster'" != "" & length("`seed'") == 0 {
			dis "SE clustered by " "`cluster'"
		}
		
		if "`cluster'" != "" & length("`seed'") > 0 {
				local padding = `align_col' - length("SE clustered by ") - length("`cluster'") - length("seed")	
				display "SE clustered by " "`cluster'" _dup(`padding') " " "seed" " = " "`seed'"
		}
		
		* This makes the column names for the stats
		collect clear 
		collect get `w' = "Coef.", tags(Col[Coef])
		collect get `w' = "Std. Err.", tags(Col[SE_AR])
		collect get `w' = "t", tags(Col[t_val])
		collect get `w' = "P>|t|", tags(Col[p_more_t])
		collect get `w' = "[95% Conf.", tags(Col[ARCI_lb])
		collect get `w' = "Interval]", tags(Col[ARCI_ub])
		
		quietly{
		mat b = e(b)
		mat V = e(V)
		if "`displayaiv'" == ""{
			mat b = b[1, 2..(`amenity_count' + 1)]		
			mat V = V[2..(`amenity_count'+1), 2..(`amenity_count'+1)] 		
		}
		local N = `n'
		local DOF = `n' - `k'
		ereturn post b V, depname(`w') obs(`N') dof(`DOF')
		ereturn local cmd "aivreg"
		eststo `eststo'
		}
		
		if "`displayaiv'" == "displayaiv"{
		foreach z of varlist `zlist' `h' {
			* Make variables
				tempname beta SE lb ub val_t test_stat 
				sca `beta' = _b[`z']
				sca `SE' = _se[`z']
				sca `val_t' = `beta' / `SE'
				local test_stat : dis 2 * ttail((`n' - `k') , abs(`val_t'))
				sca `lb' = `beta' - 1.96*`SE'
				sca `ub' = `beta' + 1.96*`SE'

			* table
				collect get `z'=`beta', tags(Col[Coef])
				collect get `z'=`SE', tags(Col[SE_AR])
				collect get `z' = `val_t', tags(Col[t_val])
				collect get `z' = `test_stat', tags(Col[p_more_t])
				collect get `z'=`lb', tags(Col[ARCI_lb])
				collect get `z'=`ub', tags(Col[ARCI_ub])
				
				_aivreg_escalar beta `z' `beta'
				_aivreg_escalar SE_boot `z' `SE'
				_aivreg_escalar t_val `z' `val_t'
				_aivreg_escalar p_more_t `z' `test_stat'
				_aivreg_escalar lb_boot `z' `lb'
				_aivreg_escalar ub_boot `z' `ub'
			
		}		
		}
		else {
		foreach z of varlist `zlist' {
			* Make variables
				tempname beta SE lb ub val_t test_stat 
				sca `beta' = _b[`z']
				sca `SE' = _se[`z']
				sca `val_t' = `beta' / `SE'
				local test_stat : dis 2 * ttail((`n' - `k') , abs(`val_t'))
				sca `lb' = `beta' - 1.96*`SE'
				sca `ub' = `beta' + 1.96*`SE'

			* table
				collect get `z'=`beta', tags(Col[Coef])
				collect get `z'=`SE', tags(Col[SE_AR])
				collect get `z' = `val_t', tags(Col[t_val])
				collect get `z' = `test_stat', tags(Col[p_more_t])
				collect get `z'=`lb', tags(Col[ARCI_lb])
				collect get `z'=`ub', tags(Col[ARCI_ub])
				
				_aivreg_escalar beta `z' `beta'
				_aivreg_escalar SE_boot `z' `SE'
				_aivreg_escalar t_val `z' `val_t'
				_aivreg_escalar p_more_t `z' `test_stat'
				_aivreg_escalar lb_boot `z' `lb'
				_aivreg_escalar ub_boot `z' `ub'
			
		}
		}
		
		* Save existing scalars
		tempname savedscalars
		local scalarnames : e(scalars)
		* LEAN_RECOVERY_SPRINT_20260825 item 2: indexed save (see first save site)
		local __sv_k = 0
		foreach s of local scalarnames {
			local ++__sv_k
			scalar `savedscalars'_`__sv_k' = e(`s')
		}

		
		*Output
		collect style header Col, level(hide) // removes Col names
		collect style cell result[`w'], border(bottom) border(top, pattern(nil)) // new column names
		collect style cell, sformat(" %s") // increase spacing
		qui collect layout (result) (Col)
		collect preview


	}

	********************************************************************************
	* Anderson-Rubin case
	********************************************************************************

	else { // AR CI case
	
	if "`displayaiv'" == "displayaiv"{
		dis "Warning: option displayaiv is not available for Anderson-Rubin CI"
	}

	if `k'==0 {
		tempname RSS_full n k partial_F
		qui reg `h' `w' `zlist' `control' `weight' `if' `in', cluster(`cluster')
		local n = `=e(N)'
		local k = `=e(df_m)'
		local betaw = e(b)[1, "`w'"]
		local sew = e(V)["`w'","`w'"]
		local sew = sqrt(`sew')
		local tsw = `betaw' / `sew'
		local partial_F = (`tsw')^2
	}
	else {
		tempname RSS_full n k partial_F
		qui reghdfe `h' `w' `zlist' `control' `weight' `if' `in', absorb(`fe') cluster(`cluster')
		local n = `=e(N)'
		local k = `=e(df_m)'
		local betaw = e(b)[1, "`w'"]
		local sew = e(V)["`w'","`w'"]
		local sew = sqrt(`sew')
		local tsw = `betaw' / `sew'
		local partial_F = (`tsw')^2
	}
			
	* eststo first stage
	eststo _ivreg2_`h_est'

		* First Stage output option
	if "`savefirst'" == "savefirst" {
		
		dis " "
		dis "{bf:First Stage:}"
	
	* get first stage estimates
	
	* This makes the column names for the stats
	collect clear 
	collect get `h' = "Coef.", tags(Col[Coef])
	collect get `h' = "Std. Err.", tags(Col[SE_AR])
	collect get `h' = "t", tags(Col[t_val])
	collect get `h' = "P>|t|", tags(Col[p_more_t])
	collect get `h' = "[95% Conf.", tags(Col[ARCI_lb])
	collect get `h' = "Interval]", tags(Col[ARCI_ub])
	
	
		foreach z of varlist `w' `zlist' {
		* Make variables
			tempname beta SE n k lb ub val_t test_stat 
			sca `n'=e(N)
			sca `k'=e(df_m)
			sca `beta' = _b[`z']
			sca `SE' = _se[`z']
			sca `val_t' = `beta' / `SE'
			local test_stat : dis 2 * ttail((`n' - `k') , abs(`val_t'))
			sca `lb' = `beta' - 1.96*`SE'
			sca `ub' = `beta' + 1.96*`SE'
			local N = `n'

		* table
			collect get `z'=`beta', tags(Col[Coef])
			collect get `z'=`SE', tags(Col[SE_AR])
			collect get `z' = `val_t', tags(Col[t_val])
			collect get `z' = `test_stat', tags(Col[p_more_t])
			collect get `z'=`lb', tags(Col[ARCI_lb])
			collect get `z'=`ub', tags(Col[ARCI_ub])
			
			_aivreg_escalar beta `z' `beta'
			_aivreg_escalar SE_asymp `z' `SE'
			_aivreg_escalar t_val `z' `val_t'
			_aivreg_escalar p_more_t `z' `test_stat'
			_aivreg_escalar lb_asymp `z' `lb'
			_aivreg_escalar ub_asymp `z' `ub'
		
	}
		
		collect style header Col, level(hide) // removes Col names
		collect style cell result[`h'], border(bottom) border(top, pattern(nil)) // new column names
		collect style cell, sformat(" %s") // increase spacing
		qui collect layout (result) (Col)
		collect preview
		
		dis " "
		dis "{bf:Second Stage:}"
		
	}
	
	
	* This adds the preamble like reghdfe
	
	dis " "
	local align_col 60  // Desired column for the "=" alignment
	local padding = `align_col' - length("Number of obs") - length("Anti-IV Regression")
	display "Anti-IV Regression" _dup(`padding') " " "Number of obs" " = " `n'
	local Fstr : display %9.3f `partial_F'
	local Fstr = trim("`Fstr'")
	local padding = `align_col' - length("Partial F-stat.") - length("Uses Anderson-Rubin CI")
	display "Uses Anderson-Rubin CI" _dup(`padding') " " "Partial F-stat." " = `Fstr'"
	display "SE inferred from radius closest to zero"
	if "`cluster'" != "" {
		display "SE clustered by `cluster'"
	}
	
	* This makes the column names for the stats
	collect clear 
	collect get `w' = "Coef.", tags(Col[Coef])
	collect get `w' = "Std. Err.", tags(Col[SE_AR])
	collect get `w' = "t", tags(Col[t_val])
	collect get `w' = "P>|t|", tags(Col[p_more_t])
	collect get `w' = "[95% Conf.", tags(Col[ARCI_lb])
	collect get `w' = "Interval]", tags(Col[ARCI_ub])
	
	local i=1
	tempname b V
	
	matrix b = J(1, `amenity_count', 0)
	matrix colnames b = `zlist'
	matrix V = J(`amenity_count', `amenity_count', 0)
	matrix colnames V = `zlist' 
	matrix rownames V = `zlist' 

	foreach z of varlist `zlist' {
		*qui {
			* qui reg `h' `w' `zlist' `control' `weight' `if' `in'
			tempname pi delta c_pipi c_deldel c_delpi crit a b c lb ub beta SE val_t test_stat b V

			sca `pi' = _b[`w']
			sca `delta' = _b[`z']
			mat _v = e(V)

			sca `c_pipi' = _v[1, 1]
			sca `c_deldel' = _v[`i'+1,`i'+1]
			sca `c_delpi' = _v[`i'+1, 1]

			sca `crit' = 1.96
			sca `a' = ((`pi')^2) - (`crit'^2) * `c_pipi'
			sca `b' = 2 * (`crit'^2) * `c_delpi' - 2 * `delta' * `pi'
			sca `c' = ((`delta')^2) - (`crit'^2) * `c_deldel'

			sca `lb' = - (-`b' + sqrt(  ((`b')^2) - 4 * `a' * `c') ) / (2 * `a')
			sca `ub' = - (-`b' - sqrt(  ((`b')^2) - 4 * `a' * `c') ) / (2 * `a')	
			*sca `SE' = (`ub' - `lb') / (2*1.96) // take radius of CI (even if uncentered)
			
			sca `beta' = -`delta' / `pi'
			
			if `beta' <= 0 {
				sca `SE' = (`ub' - `beta') / 1.96
			}
			else {
				sca `SE' = (`beta' - `lb') / 1.96
			}
			
			* we approximate SE with the radius on the side closer to zero
			if `a' < 0 {
				sca `lb' = "-Inf"
				sca `ub' = "Inf"
				sca `SE' = 0
				local undef = "undef"
			}
			
			matrix b[1,`i'] = `beta'
			matrix V[`i',`i'] = `SE'^2

			* T-Test approximation
			sca `val_t' = `beta' / `SE'
			local test_stat : dis 2 * ttail((`n' - `k') , abs(`val_t'))
			
			
			
			* table
			collect get `z'=`beta', tags(Col[Coef])
			collect get `z'=`SE', tags(Col[SE_AR])
			collect get `z' = `val_t', tags(Col[t_val])
			collect get `z' = `test_stat', tags(Col[p_more_t])
			collect get `z'=`lb', tags(Col[ARCI_lb])
			collect get `z'=`ub', tags(Col[ARCI_ub])
			
			* LEAN_RECOVERY_SPRINT_20260825 item 2 (Gate-3 row long_name_ratio_rc0):
			* key the stash by loop index -- varname-keyed local names exceed
			* Stata's 31-char local-macro limit for near-limit variable names
			* (rc 198 after output). Consumer loop below walks zlist in the
			* same order with its own counter.
			local beta_z`i' = `beta'
			local SE_AR_z`i' = `SE'
			local t_val_z`i' = `val_t'
			local p_more_t_z`i' = `test_stat'
			local lb_AR_z`i' = `lb'
			local ub_AR_z`i' = `ub'
			
			
			
			*}

		* di "`z':  " `lb' " <-- " `beta' " --> " `ub'
		local i=`i'+1
	}

	local __zi = 0
	foreach z of varlist `zlist' {
			local ++__zi
			_aivreg_escalar beta `z' `beta_z`__zi''
			_aivreg_escalar SE_AR `z' `SE_AR_z`__zi''
			_aivreg_escalar t_val `z' `t_val_z`__zi''
			_aivreg_escalar p_more_t `z' `p_more_t_z`__zi''
			if "`undef'" != "undef" {
				_aivreg_escalar lb_AR `z' `lb_AR_z`__zi''
				_aivreg_escalar ub_AR `z' `ub_AR_z`__zi''
			}
			else {
			_aivreg_escalar lb_AR `z' .
			_aivreg_escalar ub_AR `z' .
			}
	}
	
	* Save existing scalars
	tempname savedscalars
	local scalarnames : e(scalars)
	* LEAN_RECOVERY_SPRINT_20260825 item 2 (Gate-3 v2 row long_name_ratio_rc0):
	* index the saved copies -- tempname + full e-scalar name can exceed Stata's
	* 32-char scalar-name limit for near-limit variable names (rc 198 after
	* output). Restore below iterates the same list in the same order.
	local __sv_k = 0
	foreach s of local scalarnames {
		local ++__sv_k
		scalar `savedscalars'_`__sv_k' = e(`s')
	}

	
	*Output
	collect style header Col, level(hide) // removes Col names
    collect style cell result[`w'], border(bottom) border(top, pattern(nil)) // new column names
	collect style cell, sformat(" %s") // increase spacing
	qui collect layout (result) (Col)
	collect preview
	
	if "`undef'" == "undef" {
		display "Warning: CI undefined. Anti-IV is not relevant, or regression lacks sufficient power."
	}

	quietly{
	local N = `n'
	local DOF = `n' - `k'
	ereturn post b V, depname(`w') obs(`N') dof(`DOF')
	ereturn local cmd "aivreg"
	

	
	eststo `eststo'
	}

	}
	

	
	****************************************************************************
	****************************************************************************
	* Save results post estimation
	****************************************************************************
	****************************************************************************

	
	* rename first stage
		if "`firststo'" != "" {
			qui est restore _ivreg2_`h_est'
			qui est store `firststo'
			qui est restore `eststo'
			qui est drop _ivreg2_`h_est'
			
		}
		if "`firststo'" == "" {
			local firststo = "_ivreg2_`h_est'"
		}
	
	* fix outputs for results
	
	// === Rename dummy rows in eststo to look like factor terms ===

quietly {
    // Step 1: Restore the model
	if "`eststo'" != "" {
    estimates restore `eststo'

    // Step 2: Get matrices
    matrix b = e(b)
    matrix V = e(V)
	
	// Step 1: Extract original row names
local oldnames : colnames b
local newnames

// Step 2: Loop over each row name in b
foreach rn of local oldnames {
    local renamed = "`rn'"
	local temp = substr("`rn'",1,2)
	if "`temp'" == "o." {
		local renamed = substr("`rn'",3,.)
		local rn = substr("`rn'",3,.)
	}

    // Step 3: Try to find a match in zlist
    local zcount : word count `zlist'
    forvalues i = 1/`zcount' {
        local zi = word("`zlist'", `i')
		local temp = substr("`zi'",1,2)
		
		if "`temp'" == "o." {
			local zi = substr("`zi'",3,.)
		}
		
        if "`rn'" == "`zi'" {
            local renamed = word("`varlist_rows'", `i')
            continue, break
        }
    }

    // Step 4: Build new list
    local newnames "`newnames' `renamed'"
}


// Step 5: Apply new row and column names
matrix colnames b = `newnames'
matrix rownames V = `newnames'
matrix colnames V = `newnames'



    // Step 6: Re-post and overwrite
// Store required metadata before clearing

local N = e(N)
local df_r = e(df_r)
ereturn clear
ereturn post b V, depname("`w'") obs(`N') dof(`df_r')
ereturn local cmd "aivreg"
eststo `eststo'
}

if "`savefirst'" == "savefirst" {
    estimates restore `firststo'

    // Step 2: Get matrices
    matrix b = e(b)
    matrix V = e(V)
	
	// Step 1: Extract original row names
local oldnames : colnames b
local newnames

// Step 2: Loop over each row name in b
foreach rn of local oldnames {
    local renamed = "`rn'"
	local temp = substr("`rn'",1,2)
	if "`temp'" == "o." {
		local renamed = substr("`rn'",3,.)
		local rn = substr("`rn'",3,.)
	}

    // Step 3: Try to find a match in zlist
    local zcount : word count `zlist'
    forvalues i = 1/`zcount' {
        local zi = word("`zlist'", `i')
		local temp = substr("`zi'",1,2)
		
		if "`temp'" == "o." {
			local zi = substr("`zi'",3,.)
		}
		
        if "`rn'" == "`zi'" {
            local renamed = word("`varlist_rows'", `i')
            continue, break
        }
    }

    // Step 4: Build new list
    local newnames "`newnames' `renamed'"
}


// Step 5: Apply new row and column names
matrix colnames b = `newnames'
matrix rownames V = `newnames'
matrix colnames V = `newnames'



    // Step 6: Re-post and overwrite
// Store required metadata before clearing

local N = e(N)
local df_r = e(df_r)
ereturn clear
ereturn post b V, depname("`aiv'") obs(`N') dof(`df_r')
ereturn local cmd "aivreg"
eststo `firststo'

estimates restore `eststo'
}

}

* restore saved models to what the user specified
	quietly {
	local new_models "" 
	quiet est dir
	foreach model_for_loop2 in `r(names)' { 
		local new_models "`new_models' `model_for_loop2'"
	}

	* drop models produced unintentionally 
	if "`est_opt'" != "1" & "`savefirst'" != "savefirst" {
		foreach model_for_loop3 in `new_models' {
			if !strpos("`saved_models'", "`model_for_loop3'") { 
				est drop `model_for_loop3'
			}
		}

	}
	else if "`est_opt'" == "1" & "`savefirst'" != "savefirst" {
		foreach model_for_loop3 in `new_models' {
			if !strpos("`saved_models' `eststo'", "`model_for_loop3'") { 
				est drop `model_for_loop3'
			}
		}

	}
	else {
		foreach model_for_loop3 in `new_models' {
			if !strpos("`saved_models' _ivreg2_`h_est' `eststo'", "`model_for_loop3'") { 
				est drop `model_for_loop3'
			}
		}
	}
	}

	
	
	if "`savefirst'" == "savefirst" {
		if "`undef'" != "undef"{
			display as text "(results" as result "{stata `firststo': `firststo' }" as result "{stata `eststo':`eststo' }" as text "are active now)"	
		}
		else {
			display as text "(result" as result "{stata `firststo': `firststo' }" as text "is active now)"
		}
	}
	else if "`est_opt'" == "1" {
		display as text "(result" as result "{stata `eststo': `eststo' }" as text "is active now)"	
	}
	ereturn scalar Partial_F = `partial_F'
	
	

	* Restore scalars (indexed; mirrors the indexed save order exactly)
	local __sv_k = 0
	foreach s of local scalarnames {
		local ++__sv_k
		ereturn scalar `s' = `savedscalars'_`__sv_k'
	}

	* MERGE 30aug2026 (Josh): repost results on the restored full dataset with
	* a correct e(sample). Final-scalar stash is INDEXED (merge adaptation):
	* tempname + full e-scalar name can exceed Stata's 32-char scalar-name
	* limit for near-limit variable names.
	matrix b = e(b)
	matrix V = e(V)
	local N = e(N)
	local df_r = e(df_r)
	tempname finalscalars
	local finalscalarnames : e(scalars)
	local __fs_k = 0
	foreach s of local finalscalarnames {
		local ++__fs_k
		scalar `finalscalars'_`__fs_k' = e(`s')
	}
	restore
	capture drop `aivreg_sample'
	quietly gen byte `aivreg_sample' = 0
	quietly replace `aivreg_sample' = 1 `if' `in'
	fvrevar `aivreg_orig_varlist' if `aivreg_sample'
	markout `aivreg_sample' `r(varlist)'
	markout `aivreg_sample' `aiv' `fe' `cluster'
	if "`control'" != "" {
		fvrevar `control' if `aivreg_sample'
		markout `aivreg_sample' `r(varlist)'
	}
	if "`weight'" != "" {
		markout `aivreg_sample' `aivreg_weightvar'
	}
	if "`fe'" != "" {
		quietly {
			foreach fevar of local fe {
				tempvar aivreg_gsz_final
				bysort `fevar': egen long `aivreg_gsz_final' = total(`aivreg_sample') if `aivreg_sample'
				quietly replace `aivreg_sample' = 0 if `aivreg_sample' & `aivreg_gsz_final' == 1
			}
			sort `aivreg_sort'
		}
	}
	ereturn post b V, depname("`w'") obs(`N') dof(`df_r') esample(`aivreg_sample')
	ereturn local cmd "aivreg"
	local __fs_k = 0
	foreach s of local finalscalarnames {
		local ++__fs_k
		ereturn scalar `s' = `finalscalars'_`__fs_k'
	}
	if "`est_opt'" == "1" {
		eststo `eststo', noesample
	}

end
	
cap program drop aivgmm
program define aivgmm, eclass
    version 17

	* R-06 stale-state hygiene (see aivreg entry): also required here so that a
	* failure in the efficient second pass cannot leave the hidden first-pass
	* results posted as if they were the requested estimate.
	if "`e(cmd)'" == "aivreg" ereturn clear

    // Accept full varlist and separate out the depvar
    // MERGE 30aug2026 (Josh): [in] restored -- the dispatcher forwards it.
    syntax varlist(fv) [if] [in], ///
        aiv(varlist numeric) ///
		[control(varlist)] ///
		[eststo(string)] ///
		[cluster(varlist)] ///
		[weight(string)] ///
		[weightmatrix(string)] ///
		[displayaiv] ///
		[fe(string)] ///
		[2sls] ///
		[twostep] ///
		[onestep] ///
		[firststo(string)] ///
		[savefirst] ///
		[estimatordisp(string)] ///
		[ignoresingularity]

	* MERGE 30aug2026 (Josh): mark the analytic sample on the full dataset;
	* replaces the _srcobs survivor-merge remap so both engines share one
	* esample mechanism. Negative-weight exclusion removed per 30aug2026
	* ruling: the loud zero/negative probability-weight error below must fire
	* instead of a silent sample exclusion.
	local aivreg_orig_varlist "`varlist'"

	tempvar aivreg_sample
	tempvar aivreg_sort
	quietly gen long `aivreg_sort' = _n
	capture drop `aivreg_sample'
	quietly gen byte `aivreg_sample' = 0
	local aivreg_weightopt "`weight'"
	local weight ""
	quietly replace `aivreg_sample' = 1 `if' `in'
	local weight "`aivreg_weightopt'"
	fvrevar `aivreg_orig_varlist' if `aivreg_sample'
	markout `aivreg_sample' `r(varlist)'
	markout `aivreg_sample' `aiv' `control' `fe' `cluster'
	if "`weight'" != "" {
		local aivreg_weightvar "`weight'"
		local aivreg_weightvar = subinstr("`aivreg_weightvar'", "[", "", .)
		local aivreg_weightvar = subinstr("`aivreg_weightvar'", "]", "", .)
		local aivreg_weightvar = subinstr("`aivreg_weightvar'", " ", "", .)
		if strpos("`aivreg_weightvar'", "=") {
			local aivreg_weightvar = substr("`aivreg_weightvar'", strpos("`aivreg_weightvar'", "=") + 1, .)
		}
		markout `aivreg_sample' `aivreg_weightvar'
	}
	if "`fe'" != "" {
		quietly {
			foreach fevar of local fe {
				tempvar aivreg_gsz
				bysort `fevar': egen long `aivreg_gsz' = total(`aivreg_sample') if `aivreg_sample'
				quietly replace `aivreg_sample' = 0 if `aivreg_sample' & `aivreg_gsz' == 1
			}
			sort `aivreg_sort'
		}
	}

	preserve

		
	****************************************************************************
	* Sort factor and continuous variables
	****************************************************************************
	
	* Convert factor variables to dummies
	* remove i. and c.
	local varlist2 ""
	local varlist "`varlist'"
	local categ ""
	
foreach v of local varlist {

    local u ""
    local iscat 0
    local base ""

    * --- factor-variable patterns ---
    * ib#.var   (explicit base)
    if regexm("`v'", "^ib([0-9]+)\.(.+)$") {
        local base = regexs(1)
        local u    = regexs(2)
        local iscat 1
    }
    * i.var     (no explicit base)
    else if regexm("`v'", "^i\.(.+)$") {
        local u = regexs(1)
        local iscat 1
    }
    * c.var     (continuous)
    else if regexm("`v'", "^c\.(.+)$") {
        local u = regexs(1)
        local iscat 0
    }
    * plain variable name
    else {
        local u "`v'"
        local iscat 0
    }

    * record categorical vars and (optional) requested base
    if `iscat' {
        local categ "`categ' `u'"
        if "`base'" != "" local base_`u' "`base'"
    }
    else {
        * reject string continuous vars
        local typ: type `u'
        local typ = substr("`typ'", 1, 3)
        if "`typ'" == "str" {
            di as error "`u': string variables may not be used as continuous variables"
            exit 198
        }
    }

    local varlist2 "`varlist2' `u'"
}
	local varlist `varlist2'
	
	* throw an error if a variable is a string
	
	* if the explanatory variable is categorical

	local varlist2 `varlist'
	local varlist_rows `varlist'
	local categ `categ'
	if "`categ'" != ""{
			foreach v of varlist `categ' {

		quiet distinct `v'
		
		quiet levelsof `v', local(levels)

		local llist 
		local llist_rows
			foreach l of local levels {
				*gen `v'`l' = (`v' == `l')
				
				capture confirm variable `v'`l'
				if _rc {
					quiet gen `v'`l' = (`v' == `l')
				}
				else {
					quiet replace `v'`l' = (`v' == `l')
				}

				
				*label variable `v'`l' "`l'.`v'"
				local base_label : variable label `v'
				label variable `v'`l' "`base_label'=`l'"

				local llist "`llist' `v'`l'"
				local llist_rows "`llist_rows' `l'.`v'"

		}
			* pick base: user-specified (ib#.) if provided; otherwise lowest level
		local base = "`base_`v''"
		if "`base'" == "" {
			local base : word 1 of `levels'   // lowest integer level
		}
		else {
			* enforce that requested base exists in sample
			local ok = 0
			foreach l of local levels {
				if "`l'" == "`base'" local ok = 1
			}
			if `ok' == 0 {
				di as error "Base level ib`base'.`v' not present in estimation sample"
				exit 198
			}
		}

		quietly replace `v'`base' = 0
			
			local varlist2 `varlist2'
			local varlist_rows `varlist_rows'
			local v `v'
			local varlist2 : list varlist2 - v
			local varlist_rows : list varlist_rows - v
			local varlist2 "`varlist2' `llist'"
			local varlist_rows "`varlist_rows' `llist_rows'"
	}
	
	}
	
	local varlist `varlist2'
	
	****************************************************************************
	* Clean data for estimation
	****************************************************************************
	
	quietly {
		* MERGE 30aug2026 (Josh): trim to the marked analytic sample so the
		* estimation sample and the posted e(sample) cannot drift apart.
		keep if `aivreg_sample'

		// Get depvar variable from varlist

		local keeplist `varlist' `aiv' 
		
		if "`fe'" != "" {
			local keeplist `keeplist' `fe'
		}
			
		if "`weight'" != "" {
			local keeplist `keeplist' `aivreg_weightvar'
		}
		
		if "`control'" != "" {
			local keeplist `keeplist' `control'
		}
		
		if "`cluster'" != "" {
			local keeplist `keeplist' `cluster'
		}
		
		* Create a count of missing values per row
		egen nmiss = rowmiss(`keeplist')

		* Drop any observation with at least one missing
		drop if nmiss > 0
		drop nmiss
	}
	
	
	****************************************************************************
	* Weight matrix for gmm moments
	****************************************************************************
	
	if "`weightmatrix'" == "identity" {
		local weightmatrix ""
	}
			
	if "`weightmatrix'" == "unadjusted" {
		local weightmatrix ""
		local 2sls "2sls"
	}
	
	if "`weightmatrix'" != "" & "`weightmatrix'" != "unadjusted" {
		// validate user-supplied weight matrix size vs effw
		capture confirm matrix `weightmatrix'
		if _rc {
			di as err "weight matrix: specify the name of an existing matrix"
			exit 198
		}
		else {
			matrix weightmatrix = `weightmatrix'			
		}

		}
	
	****************************************************************************
	* observation weights
	****************************************************************************
	
	quietly {
	tempvar w
	if "`weight'" != "" {
		confirm variable `weight'
		gen double `w' = `weight'
		drop if missing(`w')
		* DESIGN_SPEC_v1 (Gate-1 frozen) probability-weight contract / W-04:
		* missing weights are survivor-set exclusions (already in keeplist);
		* zero/negative weights are invalid input and must fail loudly.
		count if `w' <= 0
		if r(N) > 0 {
			noisily di as error "weight(): `weight' has " r(N) " zero or negative value(s) in the estimation sample; probability weights must be strictly positive"
			exit 459
		}
	}
	else {
		gen double `w' = 1
	}
	}
	
	
	****************************************************************************
	* Savefirst
	****************************************************************************
	
	
	if "`savefirst'" != "" & "`firststo'" == "" {
		local firststo "aivgmm_"
	}
	
	if "`firststo'" != "" & "`savefirst'" == "" {
		local savefirst "savefirst"
	}
	
	if "`savefirst'" != "" & "`eststo'" == "" {

		quietly {
			estimates dir
			local models " `r(names)' "   // pad with spaces

			local check_est_num = 1
			while strpos("`models'", " est`check_est_num' ") {
				local ++check_est_num
			}
			local eststo est`check_est_num'
		}

	}
	
	local firststolist ""

	if "`savefirst'" == "savefirst" {
		foreach h of local aiv {
			
		dis  " "
		dis "{bf:First Stage `h':}"
		dis " "
		
		quietly reghdfe `h' `varlist' `control' [pw=`w'], absorb(`fe') cluster(`cluster')			
		eststo `firststo'`h'
		local firststolist "`firststolist' `firststo'`h'"
		
		matrix b = e(b)
		matrix V = e(V)
		local dof = e(df_r)

		collect clear 
		collect get `h' = "Coef.", tags(Col[Coef])
		collect get `h' = "Std. Err.", tags(Col[SE])
		collect get `h' = "t", tags(Col[t])
		collect get `h' = "P>|t|", tags(Col[p])
		collect get `h' = "[95% Conf.", tags(Col[CI_L])
		collect get `h' = "Interval]", tags(Col[CI_U])

		foreach var of local varlist {

			local coef = b[1, "`var'"]
			local se = sqrt(V["`var'", "`var'"])
			local tstat = `coef' / `se'
			local pval = 2 * ttail(`dof', abs(`tstat'))
			local lb = `coef' - 1.96 * `se'
			local ub = `coef' + 1.96 * `se'

			collect get `var' = `coef', tags(Col[Coef])
			collect get `var' = `se', tags(Col[SE])
			collect get `var' = `tstat', tags(Col[t])
			collect get `var' = `pval', tags(Col[p])
			collect get `var' = `lb', tags(Col[CI_L])
			collect get `var' = `ub', tags(Col[CI_U])
		}
	
		collect style header Col, level(hide)
		collect style cell result[`h'], border(bottom) border(top, pattern(nil))
		collect style cell, sformat(" %s")
		quiet collect layout (result) (Col)
		collect preview
			
			
		}
		dis " "
		dis "{bf:Second Stage:}"
	}
	
	
	****************************************************************************
	* remove FE
	****************************************************************************
	
	quietly {
	
	* 1) drop singleton groups per FE
	foreach fevar of local fe {
		tempvar gsz
		bysort `fevar': gen long `gsz' = _N
		drop if `gsz' == 1
		drop `gsz'
	}

	* 2) FE df on the remaining sample (joint FE)
	tempvar df_var
	quietly egen double `df_var' = group(`fe')
	quietly summarize `df_var'
	local fe_df = r(max) - 1
	drop `df_var'

	* 3) build list to residualize
	local to_resid `varlist' `aiv'
	if "`control'" != "" local to_resid `to_resid' `control'

	* 4) residualize by each FE using egen totals with weights
	foreach v of local to_resid {
		foreach fevar of local fe {
			tempvar sumv sumw mu
			bysort `fevar': egen double `sumv' = total(`v' * `w')
			bysort `fevar': egen double `sumw' = total(`w')
			gen double `mu' = cond(`sumw'>0, `sumv'/`sumw', 0)
			replace `v' = `v' - `mu'
			drop `sumv' `sumw' `mu'
		}
	}

	summ `w', meanonly
	scalar W = r(sum)

	}
	
	****************************************************************************
	* Generate objects that will be used for indexing
	****************************************************************************
	
    local depvar : word 1 of `varlist'
	local varlist `varlist'
	local depvar `depvar'
	local instruments : list varlist - depvar
	local amenities `instruments'
	local varlist `varlist' `control'
	local instruments `instruments' `control'
	local varlist `depvar'
	local namen : word count `instruments'
    local nvars : word count `varlist'

    // Set dimensions
    local k : word count `instruments'
    local L : word count `aiv'
    local rowlen = `k' + 2
    local nX = `rowlen' * `L'
    local Trows = `k' + 2 * `L'

    // Create a working copy of depvar
    tempvar Pval
    gen double `Pval' = `depvar'
	
	****************************************************************************
	* Run estimator
	****************************************************************************

    // Initialize accumulators
    matrix XT = J(`nX', `Trows', 0)
    matrix XP = J(`nX', 1, 0)
	matrix effw = J(`nX', `nX',0)
	matrix Tfull = J(`=_N', `Trows', .)
	matrix Pfull = J(`=_N', 1, .)


    local row = 1

        forvalues i = 1/`=_N' {

            // Build zi
            matrix zi = J(1, `k', .)
            forvalues j = 1/`k' {
                local zj : word `j' of `instruments'
                matrix zi[1, `j'] = `zj'[`i']
            }

            // Build hi
            matrix hi = J(1, `L', .)
            forvalues j = 1/`L' {
                local hj : word `j' of `aiv'
                matrix hi[1, `j'] = `hj'[`i']
            }

            scalar pi = `Pval'[`i']
            matrix tmp = (zi, pi, 1)

            // Build Xvec
            matrix Xvec = J(1, `nX', .)
            forvalues l = 0/`=`L'-1' {
                forvalues j = 1/`rowlen' {
                    local col = `l'*`rowlen' + `j'
                    matrix Xvec[1, `col'] = tmp[1, `j']
                }
            }

            matrix Xi = diag(Xvec)
			
            // Build Ttop
            matrix Ttop = J(`k', `nX', 0)
            forvalues r = 1/`k' {
                forvalues c = 1/`nX' {
					local zi_temp = zi[1, `r']
                    matrix Ttop[`r', `c'] = `zi_temp'
                }
            }

            // Build Tbot
            matrix Tbot = J(2*`L', `nX', 0)
            forvalues l = 0/`=`L'-1' {
                forvalues j = 1/`rowlen' {
                    local col = `l' * `rowlen' + `j'
					local hi_temp = hi[1, `l'+1]
                    matrix Tbot[2*`l'+1, `col'] = `hi_temp'
                    matrix Tbot[2*`l'+2, `col'] = 1
                }
            }

            matrix Tmat = Ttop \ Tbot
			matrix Pmat = J(`nX', 1, pi)
			
            matrix XT_i = Xi * Tmat'
            matrix XP_i = Xi * Pmat

			* sum with weighting
			scalar wi = `w'[`i']
			scalar wnorm = wi / W

			matrix XT   = XT   + wnorm * (Xi * Tmat')
			matrix XP   = XP   + wnorm * (Xi * Pmat)
			matrix effw = effw + wnorm * (Xvec' * Xvec)

			* make full T matrix

			matrix Tones = J(1, `Trows', 1)
			matrix Tvec = Tones * Tmat / `Trows'
			forvalues colval = 1/`Trows' {
				scalar temp_T = Tvec[1, `colval']
				matrix Tfull[`i',`colval'] = temp_T
			}
			
			

			matrix Pfull[`i',1] = pi


			
            local row = `row' + 1
        }


	
		// Estimate theta
		

		if "`weightmatrix'" == "" & "`2sls'" == "" {
			local XTrows = `: rowsof XT'
			matrix weightmatrix = I(`XTrows')
		}
		else if "`2sls'" == "2sls" {
			matrix weightmatrix = invsym(effw)
		} 
		else {
			local nEff = rowsof(effw)
			local mEff = colsof(effw)
			local nW   = rowsof(weightmatrix)
			local mW   = colsof(weightmatrix)

			if (`nW' != `nEff') | (`mW' != `mEff') {
				di as err "weight matrix is `nW' x `mW'; expected `nEff' x `mEff'"
				exit 198
			}
		}




		
	    matrix XtX = XT' * weightmatrix * XT
        matrix XtXinv = invsym(XtX)
		matrix XtXP = XT' * weightmatrix * XP
		matrix theta = XtXinv * XtXP
		

		************************************************************************
		* Estimate SE
		************************************************************************
		
	* Make moments for SE

	if "`cluster'" == "" { // no clustering
		local row = 1
			forvalues i = 1/`=_N' {

				// Build zi
				matrix zi = J(1, `k', .)
				forvalues j = 1/`k' {
					local zj : word `j' of `instruments'
					matrix zi[1, `j'] = `zj'[`i']
				}

				// Build hi
				matrix hi = J(1, `L', .)
				forvalues j = 1/`L' {
					local hj : word `j' of `aiv'
					matrix hi[1, `j'] = `hj'[`i']

				}

				scalar pi = `Pval'[`i']
				matrix tmp = (zi, pi, 1)

				// Build Xvec
				matrix Xvec = J(1, `nX', .)
				forvalues l = 0/`=`L'-1' {
					forvalues j = 1/`rowlen' {
						local col = `l'*`rowlen' + `j'
						matrix Xvec[1, `col'] = tmp[1, `j']
					}
				}

				matrix Xi = diag(Xvec)
				
				// Build Ttop
				matrix Ttop = J(`k', `nX', 0)
				forvalues r = 1/`k' {
					forvalues c = 1/`nX' {
						local zi_temp = zi[1, `r']
						matrix Ttop[`r', `c'] = `zi_temp'
					}
				}

				// Build Tbot
				matrix Tbot = J(2*`L', `nX', 0)
				forvalues l = 0/`=`L'-1' {
					forvalues j = 1/`rowlen' {
						local col = `l' * `rowlen' + `j'
						local hi_temp = hi[1, `l'+1]
						matrix Tbot[2*`l'+1, `col'] = `hi_temp'
						matrix Tbot[2*`l'+2, `col'] = 1
					}
				}

				matrix Tmat = Ttop \ Tbot

				matrix Pmat = J(`nX',1, pi)
				
				// weights
				scalar wi = `w'[`i']
				scalar wroot = sqrt(wi / W)
				
				matrix epsilon = wroot * Xi * (Pmat - Tmat' * theta)

				if `i' == 1 {
					matrix Moments = J(`nX',`=_N',.)
				}
				
				forvalues val = 1/`nX' {
					scalar tempnum = epsilon[`val',1]
					matrix Moments[`val',`i'] = tempnum
				}

				local row = `row' + 1
			}


	}

	if "`cluster'" != ""{ // clustered SE
	tempvar clustvar
	gettoken clustvar rest : cluster


	quiet levelsof `clustvar', local(cluster_ids)

	local G : word count `cluster_ids'
	
	if (`G' < 2) {
		dis as error "Error: Number of clusters in `clustvar' < 2"
		exit 498
	}

	matrix Moments_by_cluster = J(`nX', `G', 0)

	local g = 1
	foreach cl of local cluster_ids {

		matrix gsum = J(`nX', 1, 0)


			forvalues i = 1/`=_N' {
				if `clustvar'[`i'] != `cl' {
					continue
				}

				// Build zi
				matrix zi = J(1, `k', .)
				forvalues j = 1/`k' {
					local zj : word `j' of `instruments'
					matrix zi[1, `j'] = `zj'[`i']
				}

				// Build hi
				matrix hi = J(1, `L', .)
				forvalues j = 1/`L' {
					local hj : word `j' of `aiv'
					matrix hi[1, `j'] = `hj'[`i']
				}

				scalar pi = `Pval'[`i']
				matrix tmp = (zi, pi, 1)

				matrix Xvec = J(1, `nX', .)
				forvalues l = 0/`=`L'-1' {
					forvalues j = 1/`rowlen' {
						local col = `l'*`rowlen' + `j'
						matrix Xvec[1, `col'] = tmp[1, `j']
					}
				}

				matrix Xi = diag(Xvec)

				// Build Tmat
				matrix Ttop = J(`k', `nX', 0)
				forvalues r = 1/`k' {
					forvalues c = 1/`nX' {
						local zi_temp = zi[1, `r']
						matrix Ttop[`r', `c'] = `zi_temp'
					}
				}

				matrix Tbot = J(2*`L', `nX', 0)
				forvalues l = 0/`=`L'-1' {
					forvalues j = 1/`rowlen' {
						local col = `l' * `rowlen' + `j'
						local hi_temp = hi[1, `l'+1]
						matrix Tbot[2*`l'+1, `col'] = `hi_temp'
						matrix Tbot[2*`l'+2, `col'] = 1
					}
				}

				matrix Tmat = Ttop \ Tbot
				matrix Pmat = J(`nX',1, pi)
				matrix epsilon = Xi * (Pmat - Tmat' * theta)
				
				// weights
				scalar wi = `w'[`i']
				scalar wroot = wi * `=_N' / W
				
				matrix gsum = gsum + wroot * epsilon
			}


		// Store the summed moment for this cluster
		forvalues r = 1/`nX' {
			scalar gval = gsum[`r',1]
			matrix Moments_by_cluster[`r', `g'] = gval
		}

		local ++g
	}
	}

	* Now use moments to estimate the covariance matrix


	if "`cluster'" == "" {
		
		scalar K = `nX' + `fe_df'
		scalar c = (_N/(_N-K))
		
		matrix Moments_all = Moments
		matrix avecmat = J(`=_N',1,.)
		forvalues i = 1/`=_N' {
			matrix avecmat[`i',1] = `w'[`i'] * `=_N' / W
		}
		matrix S = c*(Moments_all * diag(avecmat) * Moments_all')
		
		// build a vector of sqrt weights
		tempname v ones
		matrix `v' = J(`=_N',1,.)
		forvalues i = 1/`=_N' {
			matrix `v'[`i',1] = sqrt(`w'[`i'] / W)
		}
		// gbar = Moments * diag(v) * 1_N
		matrix `ones' = J(`=_N',1,1)
		matrix gbar = Moments * diag(`v') * `ones'
	
	}
	else {
		
		scalar G = `G'
		scalar K = `nX' + `fe_df'
		scalar c = (G/(G-1))*((_N-1)/(_N-K))
		
		matrix S = c*(1/`=_N')*(Moments_by_cluster * Moments_by_cluster')
		
		tempname wcl
		matrix `wcl' = J(`G',1,.)
		local g = 1
		foreach cl of local cluster_ids {
			// compute cluster weight share
			quietly summarize `w' if `clustvar'==`cl'
			scalar wsum = r(sum) / W
			matrix `wcl'[`g',1] = wsum
			local ++g
		}

		* Current clustered moment mean. Moments_by_cluster was built above from
		* this call's current sample and current theta, with each observation
		* contributing a_i*g_i where a_i = w_i*N/W. Summing its columns and
		* dividing by N therefore gives mean(a_i*g_i). Do not reference the
		* global Moments matrix: it exists only on the unclustered branch and
		* may contain state from an earlier call in the same Stata session.
		tempname onesG
		matrix `onesG' = J(`G',1,1)
		matrix gbar = (1/`=_N') * Moments_by_cluster * `onesG'

	}

	local Ndisp = `=_N'
	local dof   = `Ndisp' - `namen' - 2*`L' - `fe_df'

	matrix Vtheta = invsym(XT' * weightmatrix *  XT) * XT' * weightmatrix *  S * weightmatrix *  XT * invsym(XT' * weightmatrix * XT)
	matrix Vtheta = Vtheta / `Ndisp'

	* Look only at amenities and collect results for ereturn

	
    matrix colnames theta = b

	
	matrix b = theta[1..`namen',1]

	matrix V = Vtheta[1..`namen',1..`namen']		


	
	foreach var of local instruments {
		local names `names' `var'
	}
	
	matrix b = b'
	matrix colnames b = `names'
	matrix rownames V = `names'
	matrix colnames V = `names'

	
	****************************************************************************
	* Perform J-Test
	****************************************************************************
	
	if `L' > 1 {

		// Compute J-statistic
		local Jdof = `L' * (`namen' + 2) - `namen' - 2*`L'

		local twostep_efficient = 0
		matrix Jstat = gbar' * invsym(S) * gbar
		scalar Jval = Jstat[1,1]
		local Jval = string(Jval, "%9.4f")
		local Jval : subinstr local Jval " " "", all

		scalar pval_J = chi2tail(`Jdof', Jval)
		local pval_J = string(pval_J, "%9.4f")
		local pval_J : subinstr local pval_J " " "", all
		* AIVREG-1 efficient two-step Hansen J (PACKET_D corrected spec):
		* J = N * gbar' * W2 * gbar ; W2 = inv(S_first) = supplied efficient weightmatrix.
		* Valid ONLY on the efficient two-step GMM path; one-step/2sls stay suppressed.
		if "`weightmatrix'" != "" & "`2sls'" != "2sls" {
			local twostep_efficient = 1
			* RULING 30aug2026 (collaborator review): CONVENTIONAL Hansen J df =
			* number of moment conditions minus number of estimated parameters.
			* Numerical matrix ranks are used ONLY as a gate: if the moment
			* covariance (via W2) or the parameter system is rank deficient,
			* J is fully suppressed with a warning -- no generalized
			* numerical-rank df is ever substituted.
			local Jdof = `L' * (`namen' + 2) - `namen' - 2*`L'
			mata: st_numscalar("__aivreg_rk_W2",  rank(st_matrix("weightmatrix")))
			mata: st_numscalar("__aivreg_rk_par", rank(st_matrix("XtX")))
			local __rank_ok = (__aivreg_rk_W2 == `nX') & (__aivreg_rk_par == `Trows')
			capture scalar drop __aivreg_rk_W2 __aivreg_rk_par
			matrix Jstat2 = `Ndisp' * (gbar' * weightmatrix * gbar)
			scalar J_twostep   = Jstat2[1,1]
			if `__rank_ok' & `Jdof' >= 1 {
				scalar Jdf_twostep = `Jdof'
				scalar Jp_twostep  = chi2tail(`Jdof', J_twostep)
			}
			else {
				* rank conditions fail: suppress J (no valid chi2 reference)
				local twostep_efficient = 2
			}
		}
	}


	****************************************************************************
	*
	****************************************************************************

	quietly {
		
	matrix test_mat = XT' * weightmatrix * XT

	* Identify non-zero rows/columns (check if entire row is non-zero)
	local k = colsof(test_mat)
	mata {
		M = st_matrix("test_mat")
		keep = J(1, cols(M), 0)
		for (i=1; i<=cols(M); i++) {
			if (sum(abs(M[i,.])) > 0) keep[i] = 1
		}
		st_matrix("keep_mask", keep)
	}
	matrix keep_mask = keep_mask

	* Build index of columns to keep
	local keep_list ""
	forvalues i = 1/`k' {
		if keep_mask[1, `i'] != 0 {
			local keep_list "`keep_list' `i'"
		}
	}

	* Extract non-zero rows and columns
	local n_keep : word count `keep_list'
	if `n_keep' < `k' {
		matrix test_mat_clean = J(`n_keep', `n_keep', .)
		local row = 1
		foreach i of local keep_list {
			local col = 1
			foreach j of local keep_list {
				matrix test_mat_clean[`row', `col'] = test_mat[`i', `j']
				local col = `col' + 1
			}
			local row = `row' + 1
		}
		matrix test_mat = test_mat_clean
	}

	matrix symeigen evec eval = test_mat
	scalar lambda_max = eval[1,1]
	scalar lambda_min = eval[1,colsof(eval)]
	scalar kappa  = lambda_max / lambda_min
	local kappa_str = string(kappa, "%12.1f")
	
	}
	
	
	****************************************************************************
	* Display clean output table like aivreglinear
	****************************************************************************

	display ""
	local align_col 60
	local pad1 = `align_col' - length("Number of obs") - length("Anti-IV `estimatordisp'")

	display "Anti-IV `estimatordisp'" _dup(`pad1') " " "Number of obs = " "`Ndisp'"

	if "`cluster'" == "" {
		local pad2 = `align_col' - length("Number of anti-IVs")
		display _dup(`pad2') " " "Number of anti-IVs = `L'"
	}
	else {
		local pad2 = `align_col' - length("Number of anti-IVs") - length("SE clustered by `cluster'")
		if `pad2' < 5 {
			local pad2 = `align_col' - length("Number of anti-IVs") - length("Clustered SE")
			display "Clustered SE" _dup(`pad2') " " "Number of anti-IVs = `L'"
		}
		else {
			display "SE clustered by `cluster'" _dup(`pad2') " " "Number of anti-IVs = `L'"
		}

	}

	
	if `L' > 1 {
		local pad3 = `align_col' - length("J-stat") 
		local pad4 = `align_col' - length("J-stat p value")
		if `twostep_efficient' == 1 {
			display as text "J-stat (two-step efficient) = " %9.4f J_twostep "   df = `Jdof'   p = " %6.4f Jp_twostep
		}
		else if `twostep_efficient' == 2 {
			display as text "Warning: J-stat not reported -- the moment covariance or parameter system is rank deficient, so the conventional Hansen J has no valid chi-squared reference. Check for redundant or collinear anti-IVs."
		}
		else {
			display as text "J-stat: not reported on this path -- the over-identification test is reported only on the efficient two-step path."
		}
	}

	// Collect and display clean table
	collect clear 
	collect get `depvar' = "Coef.", tags(Col[Coef])
	collect get `depvar' = "Std. Err.", tags(Col[SE])
	collect get `depvar' = "t", tags(Col[t])
	collect get `depvar' = "P>|t|", tags(Col[p])
	collect get `depvar' = "[95% Conf.", tags(Col[CI_L])
	collect get `depvar' = "Interval]", tags(Col[CI_U])
	
	if "`displayaiv'" == "displayaiv" {
		local amenities `amenities' `aiv'
	}
	
	****************************************************************************
	* Ereturn results
	****************************************************************************
	
	ereturn post b V, dof(`dof') obs(`Ndisp') depname("`depvar'")
	ereturn local cmd "aivreg"
	if `L' > 1 {
		* AIVREG-1 J-SUPPRESSION (2026-08-04 SW-DesignAgent; Director ruling -131000 pt3):
		* R4 one-step overid J invalid (omits N_eff; not chi2-referable). Return MISSING;
		* never emit invalid p until efficient two-step J passes QA.
		if `twostep_efficient' == 1 {
			* AIVREG-1 efficient two-step Hansen J (PACKET_D; validated vs frozen QA oracle)
			ereturn scalar J    = J_twostep
			ereturn scalar J_df = Jdf_twostep
			ereturn scalar J_p  = Jp_twostep
			ereturn scalar Jval   = J_twostep
			ereturn scalar pval_J = Jp_twostep
			ereturn local J_status "TWOSTEP_EFFICIENT_AIVREG1"
		}
		else if `twostep_efficient' == 2 {
			* RULING 30aug2026: rank conditions failed on the efficient two-step
			* path -- suppress J entirely; never substitute a numerical-rank df.
			ereturn scalar Jval = .
			ereturn scalar pval_J = .
			ereturn local J_status "SUPPRESSED_twostep_rank_deficient_overid_RULING20260830"
		}
		else {
			* DESIGN_SPEC_v1 Q2 (Gate-1 frozen): one-step J FULLY suppressed --
			* method/status indicator only; no J-like quantity is returned.
			ereturn scalar Jval = .
			ereturn scalar pval_J = .
			ereturn local J_status "SUPPRESSED_onestep_no_valid_overid_AIVREG1"
		}
	}
	matrix weightingmatrix = weightmatrix
	ereturn matrix weightingmatrix = weightingmatrix
	ereturn matrix S = S
	
	matrix b = e(b)
	matrix V = e(V)
	
	foreach var of local amenities {
		local coef = b[1, "`var'"]
		local se = sqrt(V["`var'", "`var'"])
		local tstat = `coef' / `se'
		local pval = 2 * ttail(`dof', abs(`tstat'))
		local lb = `coef' - 1.96 * `se'
		local ub = `coef' + 1.96 * `se'

		collect get `var' = `coef', tags(Col[Coef])
		collect get `var' = `se', tags(Col[SE])
		collect get `var' = `tstat', tags(Col[t])
		collect get `var' = `pval', tags(Col[p])
		collect get `var' = `lb', tags(Col[CI_L])
		collect get `var' = `ub', tags(Col[CI_U])
		
		if "`2sls'" == "2sls" {
			_aivreg_escalar beta `var' `coef'
			_aivreg_escalar SE_2sls `var' `se'
			_aivreg_escalar t_val `var' `tstat'
			_aivreg_escalar p_more_t `var' `pval'
			_aivreg_escalar lb_2sls `var' `lb'
			_aivreg_escalar ub_2sls `var' `ub'
		}
		else {
			_aivreg_escalar beta `var' `coef'
			_aivreg_escalar SE_gmm `var' `se'
			_aivreg_escalar t_val `var' `tstat'
			_aivreg_escalar p_more_t `var' `pval'
			_aivreg_escalar lb_gmm `var' `lb'
			_aivreg_escalar ub_gmm `var' `ub'
		}
	}

	collect style header Col, level(hide)
	collect style cell result[`depvar'], border(bottom) border(top, pattern(nil))
	collect style cell, sformat(" %s")
	quiet collect layout (result) (Col)
	collect preview

	* ---- Condition-number warning --------------------------------------------
	if "`ignoresingularity'" != "" {
		if (lambda_min <= 0) {
			display "Warning: anti-IV system is numerically singular. First stage is not identified." 
			display "Point estimates and standard errors are untrustworthy."
		}
		else if (kappa > 1e12) {
			display "Warning: anti-IV system is numerically unstable. First stage may not be identified." 
			display "Point estimates and standard errors are untrustworthy. (kappa = `kappa_str')"
		}
	}
	else {
		if (lambda_min <= 0) {
			display as error "Error: anti-IV system is numerically singular. First stage is not identified." 
			display as error "Point estimates and standard errors are untrustworthy. If you wish to proceed"
			display as error "anyway, use the ignoresingularity option."
			
			exit 430
		}
		else if (kappa > 1e12) {
			display as error "Error: anti-IV system is numerically unstable. First stage may not be identified." 
			display as error "Point estimates and standard errors are untrustworthy. (kappa = `kappa_str')"
			display as error "If you wish to proceed anyway, use the ignoresingularity option."
			
			exit 430
		}
	}

	ereturn scalar kappa = kappa
	
	****************************************************************************
	* Notify that results are active
	****************************************************************************
	
	if "`eststo'" != "" & "`savefirst'" == "" {
		eststo `eststo'
		di as text "(result " as result "{stata `eststo':`eststo' }" as text "is active now)"
	}

	if "`eststo'" != "" & "`savefirst'" != "" {
		eststo `eststo'
		di as text "(results " as result "{stata `eststo':`eststo' }" _continue
		foreach fs of local firststolist {
			di as result "{stata `fs':`fs' }" _continue
		}
		di as text "are active now)"
	}
	
	if "`eststo'" != "" {
		quietly estimates restore `eststo'
	}
	
	* MERGE 30aug2026 (Josh): repost results on the restored full dataset with
	* a correct e(sample). Merge adaptations: final-scalar stash is INDEXED
	* (32-char scalar-name limit with near-limit variable names) and
	* e(J_status) is carried across the repost.
	matrix b = e(b)
	matrix V = e(V)
	local N = e(N)
	local df_r = e(df_r)
	local __Jstatus "`e(J_status)'"
	tempname finalscalars
	local finalscalarnames : e(scalars)
	local __fs_k = 0
	foreach s of local finalscalarnames {
		local ++__fs_k
		scalar `finalscalars'_`__fs_k' = e(`s')
	}
	capture matrix final_weightingmatrix = e(weightingmatrix)
	capture matrix final_S = e(S)
	restore
	capture drop `aivreg_sample'
	quietly gen byte `aivreg_sample' = 0
	quietly replace `aivreg_sample' = 1 `if' `in'
	fvrevar `aivreg_orig_varlist' if `aivreg_sample'
	markout `aivreg_sample' `r(varlist)'
	markout `aivreg_sample' `aiv' `control' `fe' `cluster'
	if "`weight'" != "" {
		markout `aivreg_sample' `aivreg_weightvar'
	}
	if "`fe'" != "" {
		quietly {
			foreach fevar of local fe {
				tempvar aivreg_gsz_final
				bysort `fevar': egen long `aivreg_gsz_final' = total(`aivreg_sample') if `aivreg_sample'
				quietly replace `aivreg_sample' = 0 if `aivreg_sample' & `aivreg_gsz_final' == 1
			}
			sort `aivreg_sort'
		}
	}
	ereturn post b V, dof(`df_r') obs(`N') depname("`depvar'") esample(`aivreg_sample')
	ereturn local cmd "aivreg"
	capture ereturn matrix weightingmatrix = final_weightingmatrix
	capture ereturn matrix S = final_S
	local __fs_k = 0
	foreach s of local finalscalarnames {
		local ++__fs_k
		ereturn scalar `s' = `finalscalars'_`__fs_k'
	}
	if "`__Jstatus'" != "" {
		ereturn local J_status "`__Jstatus'"
	}
	if "`eststo'" != "" {
		eststo `eststo', noesample
	}
end
