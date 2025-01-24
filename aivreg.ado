
cap prog drop aivreg

prog def aivreg, rclass
	syntax varlist [if] [in], h(varlist) [control(string)] [fe(varlist)] [weight(string)] [eststo(string)] [vce(string)] [reps(string)] [seed(string)] [cluster(varlist)]
	
	* because AR clustering not set up
	if "`cluster'" != "" & "`vce'" == "" {
		local vce = "asymp"
		local AR_clust = 1
	}
	
	
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
	
	*********** start CI cases
	
	if "`vce'" == "asymp"{ // asymptotic case
	
	if  "`fe'" != "" {
			qui ivreghdfe `varlist' (`h' = `varlist') `control' `if' `in', absorb(`fe') cluster(`cluster') `weight' `first'
			eststo `eststo'
	}
	else {
			qui ivreg2 `varlist' `control' (`h' = `varlist') `if' `in', cluster(`cluster')  `weight' `first'
			eststo `eststo'
	}

	
	tempname n 
	sca `n'=e(N)

			* This adds the preamble like reghdfe
	dis " "
	local align_col 60  // Desired column for the "=" alignment
	local padding = `align_col' - length("Number of obs") - length("Anti-IV Regression")
	display "Anti-IV Regression" _dup(`padding') " " "Number of obs" " = " `n'
	if "`cluster'" != ""{
		display "SE clustered by " "`cluster'"
	}
	
	* This makes the column names for the stats
	collect clear 
	collect get `w' = "Coef.", tags(Col[Coef])
	collect get `w' = "Std. Err.", tags(Col[SE_AR])
	collect get `w' = "t", tags(Col[t_val])
	collect get `w' = "P>|t|", tags(Col[p_more_t])
	collect get `w' = "[95% Conf.", tags(Col[ARCI_lb])
	collect get `w' = "Interval]", tags(Col[ARCI_ub])
	
	
	foreach z of varlist `zlist' {
		* Make variables
			tempname beta SE n k lb ub val_t test_stat 
			sca `n'=e(N)
			sca `k'=e(df_m)
			sca `beta' = _b[`z']
			sca `SE' = _se[`z']
			sca `val_t' = `beta' / `SE'
			local test_stat : dis 2 * ttail((`n' - `k') , sqrt(`val_t'^2))
			sca `lb' = `beta' - 1.96*`SE'
			sca `ub' = `beta' + 1.96*`SE'

		* table
			collect get `z'=`beta', tags(Col[Coef])
			collect get `z'=`SE', tags(Col[SE_AR])
			collect get `z' = `val_t', tags(Col[t_val])
			collect get `z' = `test_stat', tags(Col[p_more_t])
			collect get `z'=`lb', tags(Col[ARCI_lb])
			collect get `z'=`ub', tags(Col[ARCI_ub])
			
			return scalar beta`z' = `beta'
			return scalar SE_asymp`z' = `SE'
			return scalar t_val`z' = `val_t'
			return scalar p_more_t`z' = `test_stat' 
			return scalar lb_asymp`z' = `lb'
			return scalar ub_asymp`z' = `ub'
		
	}
	
	
	*Output
	collect style header Col, level(hide) // removes Col names
    collect style cell result[`w'], border(bottom) border(top, pattern(nil)) // new column names
	collect style cell, sformat(" %s") // increase spacing
	qui collect layout (result) (Col)
	collect preview
	
	if "`AR_clust'" == "1" {
		display "WARNING: Clustering not available for Anderson Ruben SE"
		display _dup(9) " " "Defaults to asymptotic SE with custering"
	}


} 
else if "`vce'" == "boot"{ // bootstrap case
		
	if "`fe'" != "" {
			qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : ivreghdfe `varlist' (`h' = `varlist') `control' `if' `in', absorb(`fe') cluster(`cluster') `weight' `first' // this only works with verbose
			eststo `eststo'
	}
	else {
		qui bootstrap, reps(`reps') seed(`seed') cluster(`cluster') verbose : ivreg2 `varlist' `control' (`h' = `varlist') `if' `in', cluster(`cluster') `weight' `first' // this only works with verbose
		eststo `eststo'
	}
	
	tempname n 
	sca `n'=e(N)

	
		* This adds the preamble like reghdfe
	dis " "
	local align_col 60  // Desired column for the "=" alignment
	local padding = `align_col' - length("Number of obs") - length("Anti-IV Regression")
	display "Anti-IV Regression" _dup(`padding') " " "Number of obs" " = " `n'
	local padding = `align_col' - length("Uses bootstrapped SE") - length("number of reps")	
	display "Uses bootstrapped SE" _dup(`padding') " " "number of reps" " = " "`reps'"
	
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
	
	
	foreach z of varlist `zlist' {
		* Make variables
			tempname beta SE n k lb ub val_t test_stat 
			sca `n'=e(N)
			sca `k'=e(df_m)
			sca `beta' = _b[`z']
			sca `SE' = _se[`z']
			sca `val_t' = `beta' / `SE'
			local test_stat : dis 2 * ttail((`n' - `k') , sqrt(`val_t'^2))
			sca `lb' = `beta' - 1.96*`SE'
			sca `ub' = `beta' + 1.96*`SE'

		* table
			collect get `z'=`beta', tags(Col[Coef])
			collect get `z'=`SE', tags(Col[SE_AR])
			collect get `z' = `val_t', tags(Col[t_val])
			collect get `z' = `test_stat', tags(Col[p_more_t])
			collect get `z'=`lb', tags(Col[ARCI_lb])
			collect get `z'=`ub', tags(Col[ARCI_ub])
			
			return scalar beta`z' = `beta'
			return scalar SE_boot`z' = `SE'
			return scalar t_val`z' = `val_t'
			return scalar p_more_t`z' = `test_stat' 
			return scalar lb_boot`z' = `lb'
			return scalar ub_boot`z' = `ub'
		
	}
	
	
	*Output
	collect style header Col, level(hide) // removes Col names
    collect style cell result[`w'], border(bottom) border(top, pattern(nil)) // new column names
	collect style cell, sformat(" %s") // increase spacing
	qui collect layout (result) (Col)
	collect preview

	
}
	else { // AR CI case
	

	if `k'==0 {
		tempname RSS_red
		qui reghdfe `h' `zlist' `control' `weight' `if' `in', noabsorb
		sca `RSS_red'=e(rss)

		tempname RSS_full n k partial_F
		qui reghdfe `h' `w' `zlist' `control' `weight' `if' `in', noabsorb
		sca `RSS_full'=e(rss)
		sca `n'=e(N)
		sca `k'=e(rank)
	}

	else {
		tempname RSS_red
		qui reghdfe `h' `zlist' `control' `weight' `if' `in', absorb(`fe')
		sca `RSS_red'=e(rss)

		tempname RSS_full n k partial_F
		qui reghdfe `h' `w' `zlist' `control' `weight' `if' `in', absorb(`fe')
		sca `RSS_full'=e(rss)
		sca `n'=e(N)
		sca `k'=e(rank)
	}

	sca `partial_F'=(`RSS_red'-`RSS_full')/(`RSS_full'/(`n'-`k'))

	* This adds the preamble like reghdfe
	
	dis " "
	local align_col 60  // Desired column for the "=" alignment
	local padding = `align_col' - length("Number of obs") - length("Anti-IV Regression")
	display "Anti-IV Regression" _dup(`padding') " " "Number of obs" " = " `n'
	local padding = `align_col' - length("Partial F-stat.") - length("Uses AR CI; SE inferred from radius")
	display "Uses AR CI; SE inferred from radius" _dup(`padding') " " "Partial F-stat." " = " `partial_F'
	
	* This makes the column names for the stats
	collect clear 
	collect get `w' = "Coef.", tags(Col[Coef])
	collect get `w' = "Std. Err.", tags(Col[SE_AR])
	collect get `w' = "t", tags(Col[t_val])
	collect get `w' = "P>|t|", tags(Col[p_more_t])
	collect get `w' = "[95% Conf.", tags(Col[ARCI_lb])
	collect get `w' = "Interval]", tags(Col[ARCI_ub])
	
	local i=1
	
	matrix b = J(1, `amenity_count' + 1, 0)
	matrix V = J(`amenity_count' + 1, `amenity_count' + 1, 0)
	
	foreach z of varlist `zlist' {
		qui {
			* qui reg `h' `w' `zlist' `control' `weight' `if' `in'
			tempname pi delta c_pipi c_deldel c_delpi crit a b c lb ub beta SE val_t test_stat

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
			
			sca `SE' = (`ub' - `lb') / (2*1.96) // take radius of CI (even if uncentered)
			
			sca `beta' = -`delta' / `pi'
			if `a' < 0 {
				display "Error: Quadratic Term Smaller than Zero"
				sca `lb' = .
				sca `ub' = .
			}
			
			* T-Test approximation
			sca `val_t' = `beta' / `SE'
			local test_stat : dis 2 * ttail((`n' - `k') , sqrt(`val_t'^2))
			
			
			
			* table
			collect get `z'=`beta', tags(Col[Coef])
			collect get `z'=`SE', tags(Col[SE_AR])
			collect get `z' = `val_t', tags(Col[t_val])
			collect get `z' = `test_stat', tags(Col[p_more_t])
			collect get `z'=`lb', tags(Col[ARCI_lb])
			collect get `z'=`ub', tags(Col[ARCI_ub])
			
			return scalar beta`z' = `beta'
			return scalar SE_AR`z' = `SE'
			return scalar t_val`z' = `val_t'
			return scalar p_more_t`z' = `test_stat' 
			return scalar lb_AR`z' = `lb'
			return scalar ub_AR`z' = `ub'
			
			}

		* di "`z':  " `lb' " <-- " `beta' " --> " `ub'
		local i=`i'+1
	}

	*Output
	collect style header Col, level(hide) // removes Col names
    collect style cell result[`w'], border(bottom) border(top, pattern(nil)) // new column names
	collect style cell, sformat(" %s") // increase spacing
	qui collect layout (result) (Col)
	collect preview

	
	local s=0
	foreach foo in `eststo' {
		local s=`s'+1
	}

	*display `s'

	* use aivreg to eststo result
	if `s'==1 {
		qui ivreghdfe `w' `zlist' (`h'=`zlist' `w') `control' `weight' `if' `in', absorb(`fe')
		eststo `eststo'
	}
	}
end