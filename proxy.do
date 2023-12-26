
cap prog drop PROXY
prog def PROXY, rclass
	* syntax [if] [in], h(varlist) w(varlist) zlist(varlist) fe(string) [weight(string)]
	syntax varlist [if] [in], h(varlist) [fe(string)] [weight(string)]

	display "`varlist'"

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

	display "Number of amenities: `amenity_count'"

	* calculate partial F_stat

	tempname RSS_red
	qui reg `h' `zlist' `fe' `weight' `if' `in'
	sca `RSS_red'=e(rss)

	tempname RSS_full n k partial_F
	qui reg `h' `w' `zlist' `fe' `weight' `if' `in'
	sca `RSS_full'=e(rss)
	sca `n'=e(N)
	sca `k'=e(rank)

	sca `partial_F'=(`RSS_red'-`RSS_full')/(`RSS_full'/(`n'-`k'))
	di "Partial_F: "  `partial_F'

	return scalar partial_F=`partial_F'

	local i=1

	foreach z of varlist `zlist' {
		qui {
			* reg `h' `w' `zlist' `fe' `weight' `if' `in'
			tempname pi delta c_pipi c_deldel c_delpi crit a b c lb ub beta

			sca `pi' = _b[`w']
			sca `delta' = _b[`z']
			mat _v = e(V)
			sca `c_pipi' = _v[`i', `i']
			sca `c_deldel' = _v[`amenity_count'+1,`amenity_count'+1]
			sca `c_delpi' = _v[`amenity_count'+1,`i']

			sca `crit' = 1.96
			sca `a' = ((`pi')^2) - (`crit'^2) * `c_pipi'
			sca `b' = 2 * (`crit'^2) * `c_delpi' - 2 * `delta' * `pi'
			sca `c' = ((`delta')^2) - (`crit'^2) * `c_deldel'

			sca `lb' = - (-`b' + sqrt(  ((`b')^2) - 4 * `a' * `c') ) / (2 * `a')
			sca `ub' = - (-`b' - sqrt(  ((`b')^2) - 4 * `a' * `c') ) / (2 * `a')

			
			sca `beta' = -`delta' / `pi'
			if `a' < 0 {
				sca `lb' = .
				sca `ub' = .
			}
			return scalar beta`z' = `beta'
			return scalar lb_AR`z' = `lb'
			return scalar ub_AR`z' = `ub'
			}

		di "`z':  " `lb' " <-- " `beta' " --> " `ub'
		local i=`i'+1
	}
	
end