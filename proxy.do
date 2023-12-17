

cap prog drop PROXY
prog def PROXY, rclass
	syntax [if] [in], h(varlist) w(varlist) z(varlist) [weight(string)]
	qui {
		reg `h' `w' `z' `weight' `if' `in'
		tempname pi delta c_pipi c_deldel c_delpi crit a b c lb ub beta F
		sca `pi' = _b[`w']
		sca `delta' = _b[`z']
		sca `F'=e(F)		
		mat _v = e(V)
		sca `c_pipi' = _v[1,1]
		sca `c_deldel' = _v[2,2]
		sca `c_delpi' = _v[2,1]

		sca `crit' = 1.96
		sca `a' = ((`pi')^2) - (`crit'^2) * `c_pipi'
		sca `b' = 2 * (`crit'^2) * `c_delpi' - 2 * `delta' * `pi'
		sca `c' = ((`delta')^2) - (`crit'^2) * `c_deldel'

		sca `lb' = - (-`b' + sqrt(  ((`b')^2) - 4 * `a' * `c') ) / (2 * `a')
		sca `ub' = - (-`b' - sqrt(  ((`b')^2) - 4 * `a' * `c') ) / (2 * `a')

		* calculate the parameter
		sca `beta' = -`delta' / `pi'

		if `a' < 0 {
			sca `lb' = .
			sca `ub' = .
		}
		return scalar beta = `beta'
		return scalar lb_AR = `lb'
		return scalar ub_AR = `ub'
		return scalar F = `F'
	}
	//bootstrap (-_b[`z']/_b[`w']), force: reg `h' `w' `z' `weight'
	//di "a = " `a'
	di `lb' " <-- " `beta' " --> " `ub'
end



cap prog drop PROXY
prog def PROXY, rclass
	syntax [if] [in], h(varlist) w(varlist) zlist(varlist) fe(string) [weight(string)]

	local proxy_count=0
	local price_count=0
	foreach h_var in `h' {
		local proxy_count=`proxy_count'+1
	}

	foreach w_var in `w' {
		local price_count=`price_count'+1
	}

	if `price_count'>1 {
		display "Error: Supplied more than one price variable"
		exit
	}

	if `proxy_count'>1 {
		display "Working on cases with multiple proxies"
		exit
	}


	foreach z of varlist `zlist' {
		qui {
			reg `h' `w' `zlist' `fe' `weight' `if' `in'
			tempname pi delta c_pipi c_deldel c_delpi crit a b c lb ub beta F
			sca `F'=e(F)
			sca `pi' = _b[`w']
			sca `delta' = _b[`z']
			mat _v = e(V)
			sca `c_pipi' = _v[1,1]
			sca `c_deldel' = _v[2,2]
			sca `c_delpi' = _v[2,1]

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
	}
	return scalar F=`F'
end