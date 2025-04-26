

cap program drop aivreg
program define aivreg, eclass
    version 14.0

    /* 1.  Peek at first token ------------------------------------------ */
    gettoken maybe_est rest : 0          // maybe_est = first word

    capture confirm variable `maybe_est'
    if _rc {                             // first word is NOT a variable
        local estimator "`maybe_est'"    // so it must be the estimator
        local 0 "`rest'"                 // put the remainder back for parsing
    }
    else {                               // first word IS a variable
        local estimator "lin"            // default estimator
        local 0 "`maybe_est' `rest'"     // put *all* words back for parsing
    }

    /* 2.  Now parse the standard pieces (including the varlist!) -------- */
    syntax varlist(fv) [if] [in], aiv(varlist) ///
        [control(string) fe(varlist) weight(string) eststo(string) ///
         vce(string) reps(string) seed(string) cluster(varlist)   ///
         savefirst firststo(string) displayaiv steps(string) /// 
		 conv_ptol(string) conv_vtol(string) igmmiterate(string) ///
		 igmmeps(string) igmmweps(string) technique(string) ///
		 conv_maxiter(string) tracelevel(string)]

    /* 3.  How many anti-IVs?  Decide which engine to call --------------- */

	
    local nvars = wordcount("`aiv'")

    if "`estimator'" == "gmm" | `nvars' > 1 {
		if "`estimator'" != "gmm" {
			dis as text "Warning: Multiple anti-IVs inputted, switching to GMM"			
		}
		
		if "`fe'" != "" {
			dis "Warning: Fixed effects not available for GMM estimation"
		}
		
        *aivgmm `varlist' `if' `in', aiv(`aiv') ///
            control(`control') vce(`vce') steps(`steps') ///
			technique(`technique') conv_maxiter(`conv_maxiter') ///
			tracelevel(`tracelevel') reps(`reps')
			
			aivgmm `varlist' `if' `in', aiv(`aiv') control(`control') /// 
			weight(`weight') vce(`vce') steps(`steps') eststo(`eststo') /// 
			technique(`technique') conv_maxiter(`conv_maxiter') /// 
			conv_ptol(`conv_ptol') conv_vtol(`conv_vtol') /// 
			igmmiterate(`igmmiterate') igmmeps(`igmmeps') /// 
			igmmweps(`igmmweps') cluster(`cluster') reps(`reps')

			
    }
    else if inlist("`estimator'", "lin", "ols") {
        aivreglinear `varlist' `if' `in', aiv(`aiv') ///
            control(`control') fe(`fe') weight(`weight') eststo(`eststo') ///
            vce(`vce') reps(`reps') seed(`seed') cluster(`cluster')       ///
            `savefirst' firststo(`firststo') `displayaiv'
    }
    else {
        di as error "Invalid estimator `estimator'.  Use lin or gmm."
        exit 198
    }
end

	
	
cap prog drop aivreglinear

prog def aivreglinear, eclass
	syntax varlist(fv) [if] [in], aiv(varlist) [control(string)] [fe(varlist)] [weight(string)] [eststo(string)] [vce(string)] [reps(string)] [seed(string)] [cluster(varlist)] [savefirst] [firststo(string)] [displayaiv]

	preserve
	
	* remove i. and c.
	local varlist2 ""
	local varlist "`varlist'"
	
	foreach v of local varlist {
		
		local lead = substr("`v'",1,1)
		local dot2 = substr("`v'",2,1)
		local dot4 = substr("`v'",4,1)
		
		if "`dot2'" == "." {
			local u = substr("`v'",3,.)
		}
		if "`dot4'" == "." {
			local u = substr("`v'",5,.)
		}

		if "`lead'" == "i"{
			
			local num3`u' = substr("`v'",3,1)
			
			if "`dot4'" != "." {
				local num3`u' = 1
			}
			
			if "`dot2'" != "." & "`dot4'" != "." {
				local u "`v'"
			}
			
			if "`dot2'" == "." | "`dot4'" == "." {
				quiet tostring(`u'), replace
				quiet drop if `u' == "."
			}
			
		}
		else {
			local u "`v'"

			local typ: type `u'
			local typ = substr("`typ'", 1, 3)
			if "`typ'" == "str" {
				dis as error "`u': string variables may not be used as continuous variables"
				exit
			}
		}

		local varlist2 = "`varlist2' `u'"
	}
	
	local varlist `varlist2'
	
	* throw an error if a variable is a string
	
	* if the explanatory variable is categorical
	local j = 0
	local varlist2 `varlist'
	foreach v of varlist `varlist' {
		local typ: type `v'
		local typ = substr("`typ'", 1, 3)
		quiet distinct `v'
		local ndistinct = r(ndistinct)

		
		if `j' > 0 & "`typ'" == "str" {
			quiet tabulate `v', generate(`v')
			drop `v'`num3`v''
			local v `v'

			local varlist `varlist'
			local varlist2 : list varlist2 - v
			
			forvalues i = 1/`ndistinct' {
				
				if "`i'" != "`num3`v''" {
					local varlist2 = "`varlist2' `v'`i'"					
				}
			}

		}
		
		local j = `j' + 1
	}
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
	
	* eststo option
	if "`eststo'" != "" {
		local est_opt = 1
	}
	
	* to make sure ivreg2 works
	capture ereturn drop est1 
	capture ereturn drop `eststo'
	capture ereturn drop _ivreg2_`h' 
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
		local eststo "est1"
	}

	
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
			display "WARNING: seed must be a number. Seed left unspecified."
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
	else if inlist("`vce'", "", "ar", "AR", "andersonrubin", "anderson-rubin") | inlist("`vce'", "AndersonRuben", "Anderson-Rubin", "Anderson Ruben", "anderson ruben") {	
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
	
	* count variables
	
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
	
/*
	* get half of Partial F-stat
	
	if "`if'" == ""{
			if "`fe'" != "" {
		if "`vce'" == "boot" {
			quietly bootstrap, reps(`reps') seed(`seed') : reghdfe `h' `zlist' `control' `weight' if !mi(`w') `in', absorb(`fe') cluster(`cluster')
			local RSS_red = `=e(rss)'
		}
		else {
			quietly reghdfe `h' `zlist' `control' `weight' if !mi(`w') `in', absorb(`fe') cluster(`cluster')
			local RSS_red = `=e(rss)'
		}
	}
	else {
		if "`vce'" == "boot" {
			quietly bootstrap, reps(`reps') seed(`seed') : reg `h' `zlist' `control' `weight' if !mi(`w')  `in', cluster(`cluster')
			local RSS_red = `=e(rss)'	
		}
		else {
			qui reg `h' `zlist' `control' `weight' if !mi(`w')  `in', cluster(`cluster')
			local RSS_red = `=e(rss)'
		}
	}
	}
	else {
			if "`fe'" != "" {
		if "`vce'" == "boot" {
			quietly bootstrap, reps(`reps') seed(`seed') : reghdfe `h' `zlist' `control' `weight' `if' & !mi(`w') `in', absorb(`fe') cluster(`cluster')
			local RSS_red = `=e(rss)'
		}
		else {
			quietly reghdfe `h' `zlist' `control' `weight' `if' & !mi(`w') `in', absorb(`fe') cluster(`cluster')
			local RSS_red = `=e(rss)'
		}
	}
	else {
		if "`vce'" == "boot" {
			quietly bootstrap, reps(`reps') seed(`seed') : reg `h' `zlist' `control' `weight' `if' & !mi(`w')  `in', cluster(`cluster')
			local RSS_red = `=e(rss)'	
		}
		else {
			qui reg `h' `zlist' `control' `weight' `if' & !mi(`w')  `in', cluster(`cluster')
			local RSS_red = `=e(rss)'
		}
	}
	}
*/
	


	*********** start CI cases
	
	if "`vce'" == "asymp"{ // asymptotic case
	quietly {
	if  "`fe'" != "" {
			qui ivreghdfe `varlist' (`h' = `varlist') `control' `if' `in', absorb(`fe') cluster(`cluster') `weight' savefirst
			eststo `eststo'
	}
	else {
			qui ivreg2 `varlist' `control' (`h' = `varlist') `if' `in', cluster(`cluster')  `weight' savefirst
			eststo `eststo'
	}
	}
	
	
	* get first stage estimates
	qui estimates restore _ivreg2_`h'
	local n = `=e(N)'
	local k = `=e(df_m)'
	local betaw = e(b)[1, "`w'"]
	local sew = e(V)["`w'","`w'"]
	local sew = sqrt(`sew')
	local tsw = `betaw' / `sew'
	local partial_F = `tsw'^2

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
			
			ereturn scalar beta`z' = `beta'
			ereturn scalar SE_asymp`z' = `SE'
			ereturn scalar t_val`z' = `val_t'
			ereturn scalar p_more_t`z' = `test_stat' 
			ereturn scalar lb_asymp`z' = `lb'
			ereturn scalar ub_asymp`z' = `ub'
		
		}
		
		collect style header Col, level(hide) // removes Col names
		collect style cell result[`h'], border(bottom) border(top, pattern(nil)) // new column names
		collect style cell, sformat(" %s") // increase spacing
		qui collect layout (result) (Col)
		collect preview
		
		
		dis " "
		dis "{bf:Second Stage:}"
		
	}
	

	qui estimates restore `eststo'
	
	tempname n k
	sca `n'=e(N)
	sca `k'=e(df_m)

			* This adds the preamble like reghdfe
	dis " "
	local align_col 60  // Desired column for the "=" alignment
	local padding = `align_col' - length("Number of obs") - length("Anti-IV Regression")
	display "Anti-IV Regression" _dup(`padding') " " "Number of obs" " = " `n'
	if "`cluster'" != ""{
		local padding = `align_col' - length("SE clustered by ") - length("`cluster'") - length("Partial F-stat.")
		display "SE clustered by " "`cluster'" _dup(`padding') " " "Partial F-stat." " = " "`partial_F'"
	}
	else {
		local padding = `align_col'  - length("Partial F-stat.")
		display _dup(`padding') " " "Partial F-stat." " = " `partial_F'		
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
	ereturn scalar Partial_F = `partial_F'
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
			
			ereturn scalar beta`z' = `beta'
			ereturn scalar SE_asymp`z' = `SE'
			ereturn scalar t_val`z' = `val_t'
			ereturn scalar p_more_t`z' = `test_stat' 
			ereturn scalar lb_asymp`z' = `lb'
			ereturn scalar ub_asymp`z' = `ub'
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
			
			ereturn scalar beta`z' = `beta'
			ereturn scalar SE_asymp`z' = `SE'
			ereturn scalar t_val`z' = `val_t'
			ereturn scalar p_more_t`z' = `test_stat' 
			ereturn scalar lb_asymp`z' = `lb'
			ereturn scalar ub_asymp`z' = `ub'
		
	}
	}
	
	*Output
	collect style header Col, level(hide) // removes Col names
    collect style cell result[`w'], border(bottom) border(top, pattern(nil)) // new column names
	collect style cell, sformat(" %s") // increase spacing
	qui collect layout (result) (Col)
	collect preview
	

} 
else if "`vce'" == "boot"{ // bootstrap case
	
	quietly {
	if "`fe'" != "" {
		qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : ivreghdfe `varlist' (`h' = `varlist') `control' `if' `in', absorb(`fe') cluster(`cluster') `weight' // this only works with verbose
		eststo `eststo'
	}
	else {
		qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : ivreg2 `varlist' `control' (`h' = `varlist') `if' `in', cluster(`cluster') `weight' // this only works with verbose
		eststo `eststo'
	}
	}
	
	
	* get first stage estimates

	if "`fe'" != "" {
			qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : reghdfe `h' `varlist' `control' `if' `in', absorb(`fe') cluster(`cluster') `weight' // this only works with verbose
			eststo _ivreg2_`h'
	}
	else {
			qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : reg `h' `varlist' `control' `if' `in', cluster(`cluster') `weight' // this only works with verbose
			
			eststo _ivreg2_`h'
	}
	
	* get first stage estimates
	qui estimates restore _ivreg2_`h'
	local n = `=e(N)'
	local k = `=e(df_m)'
	local betaw = e(b)[1, "`w'"]
	local sew = e(V)["`w'","`w'"]
	local sew = sqrt(`sew')
	local tsw = `betaw' / `sew'
	local partial_F = `tsw'^2

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
			
			ereturn scalar beta`z' = `beta'
			ereturn scalar SE_asymp`z' = `SE'
			ereturn scalar t_val`z' = `val_t'
			ereturn scalar p_more_t`z' = `test_stat' 
			ereturn scalar lb_asymp`z' = `lb'
			ereturn scalar ub_asymp`z' = `ub'
		
	}
		
		collect style header Col, level(hide) // removes Col names
		collect style cell result[`h'], border(bottom) border(top, pattern(nil)) // new column names
		collect style cell, sformat(" %s") // increase spacing
		qui collect layout (result) (Col)
		collect preview
		
		dis " "
		dis "{bf:Second Stage:}"
		
	}
	
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
	local padding = `align_col' - length("Partial F-stat.")
	display _dup(`padding') " " "Partial F-stat." " = " `partial_F'
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
	ereturn scalar Partial_F = `partial_F'
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
			
			ereturn scalar beta`z' = `beta'
			ereturn scalar SE_boot`z' = `SE'
			ereturn scalar t_val`z' = `val_t'
			ereturn scalar p_more_t`z' = `test_stat' 
			ereturn scalar lb_boot`z' = `lb'
			ereturn scalar ub_boot`z' = `ub'
		
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
			
			ereturn scalar beta`z' = `beta'
			ereturn scalar SE_boot`z' = `SE'
			ereturn scalar t_val`z' = `val_t'
			ereturn scalar p_more_t`z' = `test_stat' 
			ereturn scalar lb_boot`z' = `lb'
			ereturn scalar ub_boot`z' = `ub'
		
	}
	}
	
	*Output
	collect style header Col, level(hide) // removes Col names
    collect style cell result[`w'], border(bottom) border(top, pattern(nil)) // new column names
	collect style cell, sformat(" %s") // increase spacing
	qui collect layout (result) (Col)
	collect preview


}
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
		local partial_F = `tsw'^2
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
		local partial_F = `tsw'^2
	}
			
	* eststo first stage
	eststo _ivreg2_`h'

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
			
			ereturn scalar beta`z' = `beta'
			ereturn scalar SE_asymp`z' = `SE'
			ereturn scalar t_val`z' = `val_t'
			ereturn scalar p_more_t`z' = `test_stat' 
			ereturn scalar lb_asymp`z' = `lb'
			ereturn scalar ub_asymp`z' = `ub'
		
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
	local padding = `align_col' - length("Partial F-stat.") - length("Uses Anderson-Rubin CI")
	display "Uses Anderson-Rubin CI" _dup(`padding') " " "Partial F-stat." " = " `partial_F'
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
				display "Error: CI undefined for `z'"
				sca `lb' = "-Inf"
				sca `ub' = "Inf"
				sca `SE' = .
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
			
			local beta`z' = `beta'
			local SE_AR`z' = `SE'
			local t_val`z' = `val_t'
			local p_more_t`z' = `test_stat' 
			local lb_AR`z' = `lb'
			local ub_AR`z' = `ub'
			
			
			
			*}

		* di "`z':  " `lb' " <-- " `beta' " --> " `ub'
		local i=`i'+1
	}

	*Output
	collect style header Col, level(hide) // removes Col names
    collect style cell result[`w'], border(bottom) border(top, pattern(nil)) // new column names
	collect style cell, sformat(" %s") // increase spacing
	qui collect layout (result) (Col)
	collect preview
	

if "`undef'" != "undef" {
	quietly{
	local N = `n'
	local DOF = `n' - `k'
	ereturn post b V, depname(`w') obs(`N') dof(`DOF')
	ereturn scalar Partial_F = `partial_F'
	foreach z of varlist `zlist' {
			ereturn scalar beta`z' = `beta`z''
			ereturn scalar SE_AR`z' = `SE_AR`z''
			ereturn scalar t_val`z' = `t_val`z''
			ereturn scalar p_more_t`z' = `p_more_t`z''
			ereturn scalar lb_AR`z' = `lb_AR`z''
			ereturn scalar ub_AR`z' = `ub_AR`z''
	}
	
	eststo `eststo'
	}
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
			if !strpos("`saved_models' _ivreg2_`h' `eststo'", "`model_for_loop3'") { 
				est drop `model_for_loop3'
			}
		}
	}
	}
	
	* rename first stage
		if "`firststo'" != "" {
			qui est restore _ivreg2_`h'
			qui est store `firststo'
			qui est restore `eststo'
			qui est drop _ivreg2_`h'
			
		}
		if "`firststo'" == "" {
			local firststo = "_ivreg2_`h'"
		}
	
	* fix outputs for results
	
	if "`savefirst'" == "savefirst" {
		if "`undef'" != "undef"{
			display as text "(results" as result "{stata `firststo': `firststo' }" as result "{stata `eststo': `eststo' }" as text "are active now)"	
		}
		else {
			display as text "(result" as result "{stata `firststo': `firststo' }" as text "is active now)"
		}
	}
	else if "`est_opt'" == "1" {
		display as text "(result" as result "{stata `eststo': `eststo' }" as text "is active now)"	
	}

	restore
end


cap program drop aivgmm

program define aivgmm, eclass
    
    ******************************************************
	/*
      Syntax
        aivgmm depvar expvars [if] [in] , aiv(varlist) \
               [control(varlist)] [fe(varlist)]          \
               [vce(string)] [steps(string)]
      ----------------------------------------------------
        depvar              outcome variable
        expvars             one **or more** potentially‑endogenous regressors
        aiv(varlist)        auxiliary instruments (one or more)
        control(varlist)    exogenous control regressors (optional)
		*/
    ******************************************************

    syntax varlist(min=2) [if] [in], aiv(varlist) [weight(string)] [control(varlist)] [vce(string)] [reps(string)] [eststo(string)] [vce(string)] [cluster(string)] [savefirst] [steps(string)] [conv_ptol(string)] [conv_vtol(string)] [igmmiterate(string)] ///
		 [igmmeps(string)] [igmmweps(string)] [technique(string)] ///
		 [conv_maxiter(string)] [tracelevel(string)] 

     ********************
     * 1. Parse inputs *
     ********************
    tokenize `varlist'               // depvar followed by endogenous variables
    local depvar `1'
    macro shift                       // now `*' holds all expvars
    local explist `*'
    local nexp   : word count `explist'

    local ctrls "`control'"          // may be empty
    local nctrl : word count `ctrls'

     ***********************************************
     * 2. Build pieces that will enter the residual
     ***********************************************

    * 2a. Coefficient parameters & starting values for each expvar
    local pars ""                       // will accumulate starting values
    foreach e of local explist {
        local pars "`pars' `e' 0"      // β_e starts at 0 (can be refined)
    }

    * 2b. Controls part of the residual and their starting values
    local ctrl_resid ""
    if "`ctrls'" != "" {
        foreach c of local ctrls {
            local ctrl_resid "`ctrl_resid' - {`c'}*`c'"
            local pars       "`pars' `c' 0"   // γ_c parameter, start=0
        }
    }

     ***************************************
     * 3. Mean of depvar for constant start
     ***************************************
    quietly summarize `depvar', meanonly
    local meandep = r(mean)

     ************************************************
     * 4. Construct moment conditions looped over AIVs
     ************************************************

    local moment_eq ""
    local count    = 1        // AIV counter (for constants)

    foreach h of local aiv {

        * 4a. Residual expression for this AIV
        local resid "`depvar'"
        foreach e of local explist {
            local resid "`resid' - {`e'}*`e'"
        }
        local resid "`resid' - {`h'}*`h' `ctrl_resid' - {const`count'}"

        * 4b. Moment block for this AIV
        local block ""
        foreach e of local explist {
            local block "`block' ((`resid')*`e')"
        }
        if `count' == 1 {                 // add additional orthogonality conditions only for first AIV
            local block "`block' ((`resid')*`depvar') (`resid')"
        }
        else {                            // for other AIVs keep residual*expvars + residual
            local block "`block' (`resid')"
        }

        local moment_eq "`moment_eq' `block'"

        * 4c. Add starting‑value placeholders for this AIV‑specific coeff & constant
        local pars "`pars' `h' 0 const`count' `meandep'"

        local ++count
    }

     *********************************
     * 5. Assemble instrument list   *
     *********************************
    local insts "`depvar' `explist'"
    if "`ctrls'" != "" local insts "`insts' `ctrls'"

     *************************
     * 6. Run the GMM system *
     *************************
	 if "`vce'" == "cluster" {
	 	local vce = "vce(`vce' `cluster')"
	 }
	 else if "`vce'" == "boot" | "`vce'" == "boots" | "`vce'" == "bootst" | "`vce'" == "bootstr" | "`vce'" == "bootstra" | "`vce'" == "bootstrap" {
	 	if "`reps'" == "" {
			local reps = 50
		}
	 	local vce = "vce(`vce', `reps')"
	 }
	 else if "`vce'" != "" {
	 	local vce = "vce(`vce')"
	 }

	*------------------------------------------------------------------*
	*  Derivative list: include d/d β_e′ for *all* endogenous betas
	*------------------------------------------------------------------*
	local deriv_spec ""
	local eq   = 1
	local kcnt = 1      // AIV counter (const1, const2, ...)

	foreach h of local aiv {

		/* ---------- residual × each endogenous regressor -------------- */
		foreach e1 of local explist {                    // e1 is outside
			foreach e2 of local explist {                // e2 is parameter
				local deriv_spec "`deriv_spec' deriv(`eq'/`e2' = -`e2'*`e1')"
			}
			local deriv_spec "`deriv_spec' deriv(`eq'/`h' = -`h'*`e1')"
			foreach c of local ctrls {
				local deriv_spec "`deriv_spec' deriv(`eq'/`c' = -`c'*`e1')"
			}
			local deriv_spec "`deriv_spec' deriv(`eq'/const`kcnt' = -`e1')"
			local ++eq
		}

		/* ---------- extra equations for first AIV --------------------- */
		if `kcnt' == 1 {
			/* residual × depvar */
			foreach e2 of local explist {
				local deriv_spec "`deriv_spec' deriv(`eq'/`e2' = -`e2'*P1)"
			}
			local deriv_spec "`deriv_spec' deriv(`eq'/`h' = -`h'*P1')"
			foreach c of local ctrls {
				local deriv_spec "`deriv_spec' deriv(`eq'/`c' = -`c'*P1)"
			}
			local deriv_spec "`deriv_spec' deriv(`eq'/const`kcnt' = -P1)"
			local ++eq

			/* residual alone */
			foreach e2 of local explist {
				local deriv_spec "`deriv_spec' deriv(`eq'/`e2' = -`e2')"
			}
			local deriv_spec "`deriv_spec' deriv(`eq'/`h' = -`h')"
			foreach c of local ctrls {
				local deriv_spec "`deriv_spec' deriv(`eq'/`c' = -`c')"
			}
			local deriv_spec "`deriv_spec' deriv(`eq'/const`kcnt' = -1)"
			local ++eq
		}
		else {   /* residual alone for other AIVs */
			foreach e2 of local explist {
				local deriv_spec "`deriv_spec' deriv(`eq'/`e2' = -`e2')"
			}
			local deriv_spec "`deriv_spec' deriv(`eq'/`h' = -`h')"
			foreach c of local ctrls {
				local deriv_spec "`deriv_spec' deriv(`eq'/`c' = -`c')"
			}
			local deriv_spec "`deriv_spec' deriv(`eq'/const`kcnt' = -1)"
			local ++eq
		}

		local ++kcnt
	}
	*------------------------------------------------------------------*

    gmm `moment_eq' `if' `in' `weight', `derivspec' instruments(`insts', noconstant)  winit(id) `steps' `vce' `savefirst' from(`pars') conv_ptol(`conv_ptol') conv_vtol(`conv_vtol') technique(`technique') conv_maxiter(`conv_maxiter') tracelevel(`tracelevel') igmmiterate(`igmmiterate') igmmeps(`igmmeps') igmmweps(`igmmweps')
		
	if "`eststo'" != "" {
		eststo `eststo'
		display as text "(result" as result "{stata `eststo': `eststo' }" as text "is active now)"
	}
	
	
end

