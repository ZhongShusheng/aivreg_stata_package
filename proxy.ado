
cap prog drop ARCI
prog def ARCI, rclass
	syntax , h(varlist) w(varlist) z(varlist ) [weight(string)]
	qui {
		reg `h' `w' `z' `weight'
		tempname pi delta c_pipi c_deldel c_delpi crit a b c lb ub beta
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
		return scalar beta = `beta'
		return scalar lb_AR = `lb'
		return scalar ub_AR = `ub'
	}
	//bootstrap (-_b[`z']/_b[`w']), force: reg `h' `w' `z' `weight'
	//di "a = " `a'
	di `lb' " <-- " `beta' " --> " `ub'
end