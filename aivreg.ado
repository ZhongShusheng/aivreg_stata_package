
cap prog drop aivreg
prog def aivreg, rclass
	syntax varlist [if] [in], h(varlist) [control(string)] [fe(string)] [weight(string)] [eststo(string)]

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

	return scalar partial_F=`partial_F'

	collect clear 

	local i=1

	foreach z of varlist `zlist' {
		qui {
			* qui reg `h' `w' `zlist' `control' `weight' `if' `in'
			tempname pi delta c_pipi c_deldel c_delpi crit a b c lb ub beta

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

			
			sca `beta' = -`delta' / `pi'
			if `a' < 0 {
				display "Error: Quadratic Term Smaller than Zero"
				sca `lb' = .
				sca `ub' = .
			}

			collect get `z'=`beta', tags(Col[Coef])
			collect get `z'=`lb', tags(Col[ARCI_lb])
			collect get `z'=`ub', tags(Col[ARCI_ub])

			return scalar beta`z' = `beta'
			return scalar lb_AR`z' = `lb'
			return scalar ub_AR`z' = `ub'
			}

		* di "`z':  " `lb' " <-- " `beta' " --> " `ub'
		local i=`i'+1
	}

	qui collect layout (result) (Col)
	collect preview
	di "Partial_F: "  `partial_F'

	local s=0
	foreach foo in `eststo' {
		local s=`s'+1
	}

	display `s'

	* use aivreg to eststo result
	if `s'==1 {
		qui ivreghdfe `w' `zlist' (`h'=`zlist' `w') `control' `weight' `if' `in', absorb(`fe')
		eststo `eststo'
	}
	
end