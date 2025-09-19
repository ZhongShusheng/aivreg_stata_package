cap program drop aivreg
program define aivreg, eclass
    version 17

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
	
    if "`estimator'" == "gmm" | "`estimator'" == "2sls" | `nvars' > 1 {
		if "`estimator'" != "gmm" & "`estimator'" != "2sls" {
			dis as text "Warning: Multiple anti-IVs inputted, switching to GMM"			
		}
		
		if "`fe'" != "" {
			dis "Warning: Fixed effects not available for GMM estimation"
		}

        *aivgmm `varlist' `if' `in', aiv(`aiv') ///
            control(`control') vce(`vce') steps(`steps') ///
			technique(`technique') conv_maxiter(`conv_maxiter') ///
			tracelevel(`tracelevel') reps(`reps')
			if "`estimator'" == "2sls" {
				local 2sls = "2sls"
			}
			
		aivgmm `varlist' `if' `in', aiv(`aiv') control(`control') /// 
			eststo(`eststo') cluster(`cluster') weight(`weight') `2sls'
			
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
	version 17
	
	syntax varlist(fv) [if] [in], aiv(varlist) [control(string)] [fe(varlist)] [weight(string)] [eststo(string)] [vce(string)] [reps(string)] [seed(string)] [cluster(varlist)] [savefirst] [firststo(string)] [displayaiv]

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
				local categ = "`categ' `u'"
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
			quiet replace `v'`num3`v'' = 0
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
	
	* eststo option
	if "`eststo'" != "" {
		local est_opt = 1
	}
	
	****************************************************************************
	* Keep track of estimation objects
	****************************************************************************
	
	* to make sure ivreg2 works
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
			qui ivreghdfe `varlist' (`h' = `varlist') `control' `if' `in' `weight', absorb(`fe') cluster(`cluster') savefirst
			eststo `eststo'
	}
	else {
			qui ivreg2 `varlist' `control' (`h' = `varlist') `if' `in' `weight', cluster(`cluster') savefirst
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
	if "`cluster'" != ""{
		local padding = `align_col' - length("SE clustered by ") - length("`cluster'") - length("Partial F-stat.")
		display "SE clustered by " "`cluster'" _dup(`padding') " " "Partial F-stat." " =" %9.3f `partial_F'
	}
	else {
		local padding = `align_col'  - length("Partial F-stat.")
		display _dup(`padding') " " "Partial F-stat." " =" %9.3f `partial_F'		
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
	* Save existing scalars
	tempname savedscalars
	local scalarnames : e(scalars)
	foreach s of local scalarnames {
		scalar `savedscalars'_`s' = e(`s')
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
				eststo _ivreg2_`h'
		}
		else {
				qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : reg `h' `varlist' `control' `if' `in' `weight', cluster(`cluster') // this only works with verbose
				
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
		local padding = `align_col' - length("Partial F-stat.")
		display _dup(`padding') " " "Partial F-stat." " =" %9.3f `partial_F'
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
		
		* Save existing scalars
		tempname savedscalars
		local scalarnames : e(scalars)
		foreach s of local scalarnames {
			scalar `savedscalars'_`s' = e(`s')
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
	display "Uses Anderson-Rubin CI" _dup(`padding') " " "Partial F-stat." " =" %9.3f `partial_F'
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

	foreach z of varlist `zlist' {
			ereturn scalar beta`z' = `beta`z''
			ereturn scalar SE_AR`z' = `SE_AR`z''
			ereturn scalar t_val`z' = `t_val`z''
			ereturn scalar p_more_t`z' = `p_more_t`z''
			ereturn scalar lb_AR`z' = `lb_AR`z''
			ereturn scalar ub_AR`z' = `ub_AR`z''
	}
	
	* Save existing scalars
	tempname savedscalars
	local scalarnames : e(scalars)
	foreach s of local scalarnames {
		scalar `savedscalars'_`s' = e(`s')
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
	ereturn local cmd "aivreg"
	

	
	eststo `eststo'
	}
	}
	}
	

	
	****************************************************************************
	****************************************************************************
	* Save results post estimation
	****************************************************************************
	****************************************************************************

	
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
			if !strpos("`saved_models' _ivreg2_`h' `eststo'", "`model_for_loop3'") { 
				est drop `model_for_loop3'
			}
		}
	}
	}

	
	
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
	ereturn scalar Partial_F = `partial_F'
	
	

	* Restore scalars
	foreach s of local scalarnames {
		ereturn scalar `s' = `savedscalars'_`s'
	}

	
restore

end
	
cap program drop aivgmm
program define aivgmm, eclass
    version 17

    // Accept full varlist and separate out the depvar
    syntax varlist [if], ///
        aiv(varlist numeric) ///
		[control(varlist)] ///
		[eststo(string)] ///
		[cluster(varlist)] ///
		[weight(string)] ///
		[displayaiv] ///
		[2sls]

	preserve	

	****************************************************************************
	* Clean data for estimation
	****************************************************************************
	
	quietly {
		if "`if'" != "" {
			keep `if'
		}
		
		if "`in'" != "" {
			keep `in'
		}
		
		// Get depvar variable from varlist

		local keeplist `varlist' `aiv' 
		
		if "`control'" != "" {
			local keeplist `keeplist' `control'
		}
		
		if "`cluster'" != "" {
			local keeplist `keeplist' `cluster'
		}
		
		keep `keeplist'
		
		* Create a count of missing values per row
		egen nmiss = rowmiss(`keeplist')

		* Drop any observation with at least one missing
		drop if nmiss > 0
		drop nmiss
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
    *quietly {
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

            matrix XT = XT + XT_i
            matrix XP = XP + XP_i
			matrix effw = effw + Xvec' * Xvec

			matrix Tones = J(1, `Trows', 1)
			matrix Tvec = Tones * Tmat / `Trows'
			forvalues colval = 1/`Trows' {
				scalar temp_T = Tvec[1, `colval']
				matrix Tfull[`i',`colval'] = temp_T
			}
			
			

			matrix Pfull[`i',1] = pi


			
            local row = `row' + 1
        }
    *}


	
    // Estimate theta
		
		matrix XT = XT / `=_N'
		matrix XP = XP / `=_N'
		

		if "`weight'" == "" & "`2sls'" == "" {
			local XTrows = `: rowsof XT'
			matrix weight = I(`XTrows')
		}
		else if "`2sls'" == "2sls" {
			matrix effw = effw / `=_N'
			matrix weight = invsym(effw)
		} 
		else {
			// validate user-supplied weight matrix size vs effw
			capture confirm matrix `weight'
			if _rc {
				di as err "weight matrix: specify the name of an existing matrix"
				exit 198
			}

			local nEff = rowsof(effw)
			local mEff = colsof(effw)
			local nW   = rowsof(`weight')
			local mW   = colsof(`weight')

			if (`nW' != `nEff') | (`mW' != `mEff') {
				di as err "weight matrix is `nW' x `mW'; expected `nEff' x `mEff'"
				exit 198
			}

			matrix weight = `weight'
		}

		
	    matrix XtX = XT' * weight * XT
        matrix XtXinv = invsym(XtX)
		matrix XtXP = XT' * weight * XP
		matrix theta = XtXinv * XtXP

		matrix Presid = Pfull - Tfull * theta
		matrix mat_SE_2sls = Presid' * Presid
		scalar SE_2sls = mat_SE_2sls[1,1]
		

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
				matrix epsilon = Xi * (Pmat - Tmat' * theta)

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
		dis as warning "Error: Number of clusters in `clustvar' < 2"
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
				matrix gsum = gsum + epsilon
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
		matrix Moments_all = Moments
		matrix S        = (Moments_all * Moments_all') / `=_N'
		matrix S = (`=_N' / (`=_N' - rowsof(theta)) ) * S
		matrix gbar     = Moments_all * J(`=_N',1,1) / `=_N'
	}
	else {
		matrix S = (Moments_by_cluster * Moments_by_cluster') / `=_N'
		local G : word count `cluster_ids'
		matrix S = (`G'/(`G'-1)) * ((`=_N' - 1)/(`=_N'-rowsof(theta))) * S
		matrix onesG = J(`G',1,1)
		matrix gbar = Moments_by_cluster * onesG / `=_N'
	}


	matrix Vtheta = invsym(XT' * weight *  XT) * XT' * weight *  S * weight *  XT * invsym(XT' * weight * XT)

	matrix Vtheta = Vtheta / `=_N'


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

	local N = `=_N'
	local dof = `=_N' - `namen' - 2*`L'
	
	****************************************************************************
	* Perform J-Test
	****************************************************************************
	
	if `L' > 1 {
		// Compute average moment vector
		matrix ones_mat = J(`=_N', 1, 1)



		// Compute J-statistic
		local Jdof = `L' * (`namen' + 2) - `namen' - 2*`L'

		matrix Jstat = `=_N' * gbar' * invsym(S) * gbar
		scalar Jval = Jstat[1,1]
		local Jval = string(Jval, "%9.4f")
		local Jval : subinstr local Jval " " "", all

		scalar pval_J = chi2tail(`Jdof', Jval)
		local pval_J = string(pval_J, "%9.4f")
		local pval_J : subinstr local pval_J " " "", all


		*di as text _newline(1) "Test of overidentifying restrictions:"
		*di as text "    Hansen J statistic = " as result %9.4f Jval
		*di as text "    Degrees of freedom = " as result %9.0f `Jdof'
		*di as text "    P-value            = " as result %9.4f pval_J
	}


	****************************************************************************
	* Display clean output table like aivreglinear
	****************************************************************************
	
	display ""
	local align_col 60
	local pad1 = `align_col' - length("Number of obs") - length("Anti-IV GMM")
	display "Anti-IV GMM" _dup(`pad1') " " "Number of obs = " "`N'"	
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
		display _dup(`pad3') " " "J-stat = "  "`Jval'"
		display _dup(`pad4') " " "J-stat p value = "  "`pval_J'"
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
	}

	collect style header Col, level(hide)
	collect style cell result[`depvar'], border(bottom) border(top, pattern(nil))
	collect style cell, sformat(" %s")
	quiet collect layout (result) (Col)
	collect preview

	
	****************************************************************************
	* Ereturn results
	****************************************************************************
	
	ereturn post b V, dof(`dof') obs(`=_N') depname("`depvar'")
	ereturn local cmd "aivreg"
	if `L' > 1 {
		ereturn scalar Jval = Jval
		ereturn scalar pval_J = pval_J
	}
	ereturn matrix weight = weight
	ereturn matrix S = S
	
	if "`eststo'" != "" {
		eststo `eststo'
		display as text "(result" as result "{stata `eststo': `eststo' }" as text "is active now)"
	}
	
	restore
end


