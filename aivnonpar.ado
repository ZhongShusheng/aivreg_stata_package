
cap program drop aivnonpar
program define aivnonpar, eclass
    syntax varlist [if] [in], aiv(varlist) [control(varlist)] [fe(varlist)] [nbincontrol(string)] [equalbinwidthscontrol] [heatplot] [equalbinwidths] [equalbinwidthsx] [equalbinwidthsy] [nbin(string)] [nbinx(string)] [nbiny(string)] [firstheatplot] [ncolors(string)] [firstcontourplot] [asdata(string)] [firstdata(string)] [saveheatplot(string)] [savefirstheatplot(string)] [savefirstcontourplot(string)] [contourplot] [savecontourplot(string)] [xcategoryorder(string)] [contourplottitle(string)] [firstcontourplottitle(string)] [heatplottitle(string)] [firstheatplottitle(string)] [xtitle(string)] [ytitle(string)] [plotquantiles(string)] [scolor(string)] [ecolor(string)] [binmedians] [ccolors(string)] [estimatesequal(string)] [firstestimatesequal(string)] [firstestimatesequaltitle(string)] [estimatesequaltitle(string)] [savefirstestimatesequal(string)] [saveestimatesequal(string)] [critvalue(string)]
	
	* save unaltered data
		preserve

	if "`critvalue'" == ""{
		local critvalue = 1.96
	}
	if "`firstdata'" != ""{
		local firstdatacheck = "firstdatacheck"
	}
	if "`asdata'" != ""{
		local asdatacheck = "asdatacheck"
	}
	
	if "`savefirstheatplot'" != ""{
		local firstheatplot = "firstheatplot"
	}
	
	if "`saveheatplot'" != ""{
		local heatplot = "heatplot"
	}
	
	if "`savecontourplot'" != ""{
		if "`contourplot'" == ""{
			local contourplot = "contourplot"
		}
	}
	
	if "`contourplot'" != "" | "`heatplot" != ""{
		if "`asdata'" == ""{
			local asdata = "asdata"
		}
	}
	
	
	if "`savefirstcontourplot'" != ""{
		local firstcontourplot = "firstcontourplot"
	}
	
	if "`firstcontourplot'" != "" | "`firstheatplot'" != ""{
		if "`firstdata'" == ""{
			local firstdata = "firstdata"			
		}
	}
	
	if "`firstestimatesequal'" != "" {
		if "`firstdata'" == ""{
			local firstdata = "firstdata"			
		}
	
	}
	if "`estimatesequal'" == "" {
		if "`asdata'" == "" {
			local asdata = "asdata"			
		}

	}
	
	if "`ncolors'" == ""{
		if "`plotquantiles'" == ""{
			if "`ccolors'" == "" {
				local ncolors = 10				
			}
			else {
				local ncolors : word count `ccolors'
			}
		}
	}
	else{
		if "`plotquantiles'" != ""{
			dis "Warning: Can not set ncolors and plotquantiles. Defaulting to plotquantiles."
			local ncolors = ""
		}
	}
	if "`ccolors'" != ""{
		if "`ncolors'" != ""{
			local colorlistcount = wordcount("`ccolors'")
			if "`ncolors'" != "`colorlistcount'" {
				dis "Warning: `ncolors' colors needed but only `colorlistcount' provided."
			}
		}
		else {
			local colorlistcount = wordcount("`ccolors'")
			if "`plotquantiles'" != "`colorlistcount'" {
				dis "Warning: `plotquantiles' colors needed but only `colorlistcount' provided."
			}
		}
	}


	
	if "`equalbinwidths'" != "equalbinwidths" {
		local equalbinwidths ""
	}
	else{
		local equalbinwidths "equalbinwidths"
		local equalbinwidthsx = "equalbinwidthsx"
		local equalbinwidthsy = "equalbinwidthsy"
	}
	if "`equalbinwidthsx'" != ""{
		local equalbinwidthsx = "equalbinwidthsx"
	}
	
	if "`equalbinwidthsy'" != ""{
		local equalbinwidthsy = "equalbinwidthsy"
	}
	
	qui {
	tokenize `varlist'
    local depvar `1'
    local expvar `2'
	
    if "`nbinx'" == "" {
        local nbinx = 5
		
		if "`nbin'" != ""{
			local nbinx = `nbin'
		}
    }

    if "`nbiny'" == "" {
        local nbiny = 5
		
		if "`nbin'" != ""{
			local nbiny = `nbin'
		}
    }

	local n2binx = 2* `nbinx'
	local n2biny = 2* `nbiny'

	}
	
	if "`xtitle'" == ""{
		local xtitle = "`expvar'"
	}
	if "`ytitle'" == ""{
		local ytitle = "`depvar'"
	}
	
	* Compatability check
	
	capture confirm numeric variable `depvar'
	if _rc != 0{
		dis "Error: y variable is not numeric"
		exit
	}
	

	capture confirm numeric variable `expvar'
	if _rc != 0{
		if "`xcategoryorder'" == ""{
			dis "Error: x variable is not numeric and xcategoryorder is unset"			
			exit
		}
	}
	quietly{	
	
	* if and in
	
	if "`in'" != ""{
		drop `in'
	}
	if "`if'" != ""{
		keep `if'
	}


	* drop other vars
	keep `expvar' `depvar' `aiv' `control' `fe'
	

	
	gen weight = 1
	if "`xcategoryorder'" == "" {
		xtile weighty = `depvar', n(`n2biny')
		xtile weightx = `expvar', n(`n2binx')
		bys weighty weightx: egen altweight = sum(weight)
		replace weight = 1 / altweight
	}


	* controls
	if "`control'" != ""{
		
		if "`nbincontrol'" == ""{
			local nbincontrol = 5
			
			if "`nbin'" != ""{
				local nbincontrol = `nbin'
			}
		}

		local ncontrols : word count `control'

		tokenize `control'
		forvalues i = 1/`ncontrols'{
			local control`i' ``i''

		}

		* make control bins
		
		if "`equalbinwidthscontrol'" != "" {
			local control_bins 

			forvalues i = 1/`ncontrols' {
				summarize `control`i''
				local minbincon`i' = `=r(min)'
				local maxbincon`i' = `=r(max)'
				
				local numlistdep`i' "`minbincon`i''"  // Initialize numlist with the min value

				forvalues j = 1/`=`nbincontrol'-1' {  
					local tempnumber`i' = `minbincon`i'' + `j' * (`maxbincon`i'' - `minbincon`i'') / `nbincontrol'
					local numlistdep`i' "`numlistdep`i'' `tempnumber`i''"
				}

				gen control`i'_bin = .
				
				forvalues j = 1/`nbincontrol' {
					local threshold`j' = `=word("`numlistdep`i''", `j')'
					replace control`i'_bin = `j' if `control`i'' >= `threshold`j''
				}
				
				local control_bins `control_bins' control`i'_bin
			}


		}
		else {
		local control_bins = ""
			forvalues i = 1/`ncontrols'{
				xtile control`i'_bin = `control`i'', n(`nbincontrol')
				
				levelsof control`i'_bin, local(unique_vals)
				local unique_vals: word count `unique_vals'
				if `unique_vals' < `nbincontrol'{
					dis as error "Error: `control`i'' does not have `nbincontrol' unique quantiles."
				}
				
				local control_bins `control_bins' control`i'_bin
			}
		}
	}
	
	if "`control'" != "" | "`fe'" != ""{
		if "`binmedians'" != ""{
			egen `aiv'_mean = median(`aiv'), by(`control_bins' `fe')
			replace `aiv' = `aiv' - `aiv'_mean
			drop `aiv'_mean
						
		}
		else{
			egen `aiv'_mean = mean(`aiv' * weight), by(`control_bins' `fe')
			replace `aiv' = `aiv' - `aiv'_mean
			drop `aiv'_mean
					
		}
	
	}

		egen `depvar'_mean =  mean(`depvar' * weight), by(`control_bins' `fe')
		replace `depvar' = `depvar' - `depvar'_mean
		drop `depvar'_mean

		if "`xcategoryorder'" == ""{
			egen `expvar'_mean = mean(`expvar' * weight), by(`control_bins' `fe')
			replace `expvar' = `expvar' - `expvar'_mean
			drop `expvar'_mean
		}	

	*categorical data

	if "`xcategoryorder'" != ""{
		
		local wordcount : word count `xcategoryorder'
		local ndep = `wordcount'
		local equalbinwidthsx = "equalbinwidthsx"
		gen `expvar'_number = .
		
		forvalues i = 1/`wordcount'{
			local catval : word `i' of `xcategoryorder'
			dis "test`catval'test"
			replace `expvar'_number = `i' if `expvar' == "`catval'"
		}
		
		drop `expvar'
		gen `expvar' = `expvar'_number
		drop `expvar'_number
	
	}


    * h means
    tempfile preservefile
	save `preservefile'
	
	
	drop if mi(`aiv') |  mi(`depvar') | mi(`expvar')
	
		if "`equalbinwidthsx'" == "equalbinwidthsx"{

			summarize `expvar' , d 
	
			local minbinx = `=r(min)'
			local maxexp = `=r(max)'
			local numlistexp = `minbinx'
			
			forvalues i = 1/`=`nbinx'- 1' {
				local tempnumber = `minbinx' + `i' * (`maxexp' - `minbinx') / `nbinx'
				local numlistexp = "`numlistexp' `tempnumber'"
			}
			gen bin_var1 = .
			gen mid_var1 = .
			local dist1 = `=word("`numlistexp'", 3)'/2  -  `=word("`numlistexp'", 2)' / 2 
			forvalues i = 1/`nbinx' {
				replace bin_var1 = `i' if `expvar' >= `=word("`numlistexp'", `i')'
				replace mid_var1 = `=word("`numlistexp'", 2)' - 3*`dist1' + `dist1'*2*`i' if `expvar' >= `=word("`numlistexp'", `i')'
			}
		}
		else{
			xtile bin_var1 = `expvar', n(`nbinx')	
			
			levelsof bin_var1, local(unique_vals)
			local unique_vals: word count `unique_vals'
			if `unique_vals' < `nbinx'{
				dis as error "Error: `expvar' does not have `nbinx' unique quantiles."
			}
			
		}
		
		if "`equalbinwidthsy'" == "equalbinwidthsy" {
			summarize `depvar'
			local minbiny = `=r(min)'
			local maxdep = `=r(max)'
			local numlistdep = `minbiny'
			forvalues i = 1/`=`nbiny'- 1' {
				local tempnumber = `minbiny' + `i' * (`maxdep' - `minbiny') / `nbiny'
				local numlistdep = "`numlistdep' `tempnumber'"
			}
			gen bin_var2 = .
			gen mid_var2 = .
			local dist2 = `=word("`numlistdep'", 3)'/2  -  `=word("`numlistdep'", 2)' / 2 
			forvalues i = 1/`nbiny' {
				replace bin_var2 = `i' if `depvar' >= `=word("`numlistdep'", `i')'
				
				replace mid_var2 = `=word("`numlistdep'", 2)' - 3*`dist2' + `dist2'*2*`i' if `depvar' >= `=word("`numlistdep'", `i')'
				
			}

		}
		else {
			xtile bin_var2 = `depvar', n(`nbiny')
			levelsof bin_var2, local(unique_vals)
			local unique_vals: word count `unique_vals'
			if `unique_vals' < `nbiny'{
				dis as error "Error: `depvar' does not have `nbiny' unique quantiles."
			}
			
		}
        
		gen special_sum_var = 1
		
		if "`equalbinwidthsx'" == "equalbinwidthsx"{
			local mid_var1 = "mid_var1"
		}
		if "`equalbinwidthsy'" == "equalbinwidthsy"{
			local mid_var2 = "mid_var2"
		}
		
		if "`binmedians'" != ""{
			collapse (median) `aiv'=`aiv' `depvar' `expvar' (sum) special_sum_var (semean) SE=`aiv' [aw=weight], by(bin_var1 bin_var2 `mid_var1' `mid_var2')	
			replace SE = 1.253 * SE
		}
		else{
			collapse (mean) `aiv'=`aiv' `depvar' `expvar' (sum) special_sum_var (semean) SE=`aiv' [aw = weight], by(bin_var1 bin_var2 `mid_var1' `mid_var2')		
		}

        drop if mi(bin_var1) | mi(bin_var2)
		
		tempfile meandata
		save `meandata', replace
		
		if "`equalbinwidthsx'" == "equalbinwidthsx"{
			keep mid_var1 bin_var1 bin_var2
			tempfile mid_var1_data
			save `mid_var1_data'
			use `meandata', clear
			drop mid_var1
			tempfile meandata
			save `meandata', replace
		}
		if "`equalbinwidthsy'" == "equalbinwidthsy"{
			keep mid_var2 bin_var1 bin_var2
			tempfile mid_var2_data
			save `mid_var2_data'
			use `meandata', clear
			drop mid_var2
			tempfile meandata
			save `meandata', replace
		}
		
		drop `expvar' `depvar' special_sum_var SE
		
        reshape wide `aiv', i(bin_var1) j(bin_var2) 

        drop bin_var1
		
        mkmat *, matrix(mean_matrix)
		
		* depvar means
		
		use `meandata', replace
		
		drop `expvar' `aiv' special_sum_var SE
		
        reshape wide `depvar', i(bin_var1) j(bin_var2) 
        drop bin_var1
		
        mkmat *, matrix(dep_mat)
		
		* expvar means
		
		use `meandata', clear
		
		drop `aiv' `depvar' special_sum_var SE
		
        reshape wide `expvar', i(bin_var1) j(bin_var2) 
        drop bin_var1

        mkmat *, matrix(exp_mat)
		
		* frequencies
		
		use `meandata', clear
		
		drop `expvar' `depvar' `aiv' SE		 

        reshape wide special_sum_var, i(bin_var1) j(bin_var2) 
        drop bin_var1

        mkmat *, matrix(freq_mat)
		
		* SE
		
		use `meandata', clear
		
		drop `expvar' `depvar' `aiv' special_sum_var

        reshape wide SE, i(bin_var1) j(bin_var2) 
        drop bin_var1

        mkmat *, matrix(se_mat)
		
	use `preservefile', clear

    * take differences
    mat dhd = mean_matrix[2..`nbinx', 2..`nbiny'] - mean_matrix[2..`nbinx', 1..(`nbiny' - 1)]
    mat dd = dep_mat[2..`nbinx', 2..`nbiny'] - dep_mat[2..`nbinx', 1..(`nbiny' - 1)]

    mat dhe = mean_matrix[2..`nbinx', 2..`nbiny'] - mean_matrix[1..(`nbinx'-1), 2..`nbiny']
    mat dex = exp_mat[2..`nbinx', 2..`nbiny'] - exp_mat[1..(`nbinx'-1), 2..`nbiny']
	}
    * Initialize matrices for division

    matrix dh_dd = J((`nbinx'-1), (`nbiny'-1), .)  // Missing values
    matrix dh_de = J((`nbinx'-1), (`nbiny'-1), .)  // Missing values


    * Element-wise division using Stata loops
    local rows = `nbinx' - 1
    local cols = `nbiny' - 1

    forvalues i = 1/`rows' {
        forvalues j = 1/`cols' {
            local dhd_val = dhd[`i', `j']
            local dd_val = dd[`i', `j']
            if `dd_val' != 0 {
                matrix dh_dd[`i', `j'] = `dhd_val' / `dd_val'
            }
            
            local dhe_val = dhe[`i', `j']
            local dex_val = dex[`i', `j']
            if `dex_val' != 0 {
                matrix dh_de[`i', `j'] = `dhe_val' / `dex_val'
            }
        }
    }

    * Compute final matrix
    matrix dd_de = J(`rows', `cols', .)  // Initialize final matrix

    forvalues i = 1/`rows' {
        forvalues j = 1/`cols' {
            local dh_de_val = dh_de[`i', `j']
            local dh_dd_val = dh_dd[`i', `j']
            if `dh_dd_val' != 0 {
                matrix dd_de[`i', `j'] = -`dh_de_val' / `dh_dd_val'
            }
        }
    }

	* compute SE for second stage
	
	matrix ub_result = J(`rows', `cols', .)
	matrix lb_result = J(`rows', `cols', .)
	
	forvalues i = 1/`rows' {
        forvalues j = 1/`cols' {
				local pi = dh_dd[`i',`j']
				local delta = dh_de[`i',`j']
				local dexl = dex[`i',`j']
				local ddl = dd[`i',`j']
				local c_deldel = (se_mat[`i',`=`j'+1']^2 + se_mat[`=`i'+1', `=`j'+1']^2 ) / `dexl'^2
				local c_pipi = (se_mat[`=`i'+1',`=`j'+1']^2 + se_mat[`=`i'+1',`j']^2 ) / `ddl'^2
				local c_delpi = se_mat[`=`i'+1',`=`j'+1']^2 / `dexl'  / `ddl'
				
				local crit = `critvalue'
				local a = ((`pi')^2) - (`crit'^2) * `c_pipi'
				local b = 2 * (`crit'^2) * `c_delpi' - 2 * `delta' * `pi'
				local c = ((`delta')^2) - (`crit'^2) * `c_deldel'
				
				if `a' > 0 {
   					matrix ub_result[`i',`j'] = - (-`b' - sqrt((`b')^2 - 4 * `a' * `c')) / (2 * `a')
 					matrix lb_result[`i',`j'] = - (-`b' + sqrt((`b')^2 - 4 * `a' * `c')) / (2 * `a')
				}
				else if `a' < 0 {
    					* Flip the roots if the parabola opens downward
    					matrix lb_result[`i',`j'] = - (-`b' - sqrt((`b')^2 - 4 * `a' * `c')) / (2 * `a')
    					matrix ub_result[`i',`j'] = - (-`b' + sqrt((`b')^2 - 4 * `a' * `c')) / (2 * `a')
				}
				else {
    					* a == 0 is linear; avoid divide-by-zero
    					matrix lb_result[`i',`j'] = .
   					matrix ub_result[`i',`j'] = .
				}

        }
    }
	
	
	* row and column names results
	local rownames ""
	local colnames ""
	local othercols ""

	forvalues i = 2/`nbinx' {

		local rownames `rownames' `i'
	}
	forvalues j = 2/`nbiny' {
		local colnames `colnames' `j'
	}

	matrix rownames dd_de = `rownames'
	matrix colnames dd_de = `colnames'
	
	matrix rownames ub_result = `rownames'
	matrix colnames ub_result = `colnames'
	matrix rownames lb_result = `rownames'
	matrix colnames lb_result = `colnames'
	
	local otherrows = "`rownames'"
	
	* row and column names frequencies
	local rownames ""
	local colnames ""

	forvalues i = 1/`nbinx' {
		local rownames `rownames' `i'
	}
	forvalues j = 1/`nbiny' {
		local colnames `colnames' `j'
	}

	matrix rownames freq_mat = `rownames'
	matrix colnames freq_mat = `colnames'
	matrix rownames mean_matrix = `rownames'
	matrix colnames mean_matrix = `colnames'
	matrix rownames exp_mat = `rownames'
	matrix colnames exp_mat = `colnames'
	matrix rownames dep_mat = `rownames'
	matrix colnames dep_mat = `colnames'	
	
    * Store the final result
	
	* display y bins
	if "`equalbinwidthsy'" == ""{
		
	mat `depvar'_bins = J(1,`=`nbiny'-1', .)
	_pctile `depvar', nquantiles(`nbiny')
	forvalues i = 1/`=`nbiny'-1' {
		mat `depvar'_bins[1, `i'] = r(r`i')
	}
	mat list `depvar'_bins
	
	}
	else{
		
		mat `depvar'_bins = J(1,`=`nbiny'-1', .)
		
		forvalues i = 2/`nbiny' {
			mat `depvar'_bins[1,`=`i'-1'] = `=word("`numlistdep'", `i')'
		}
		
		mat list `depvar'_bins
		
	}
	
	* display x bins
	if "`equalbinwidthsx'" == ""{
			
	mat `expvar'_bins = J(1,`=`nbinx'-1', .)
	_pctile `expvar', nquantiles(`nbinx')
	forvalues i = 1/`=`nbinx'-1' {
		mat `expvar'_bins[1, `i'] = r(r`i')
	}
	mat list `expvar'_bins
	}
	else{
		mat `expvar'_bins = J(1,`=`nbinx'-1', .)
		forvalues i = 2/`nbinx' {
			mat `expvar'_bins[1,`=`i'-1'] = `=word("`numlistexp'", `i')'
		}
		mat list `expvar'_bins		
	}
	
	* output interface and ereturn
	
	mat `depvar'_means = dep_mat'
	mat `expvar'_means = exp_mat'
	mat `aiv'_means = mean_matrix'
	mat freq_mat = freq_mat'
	mat `depvar'_on_`expvar'_result = dd_de'
	mat lb_result = lb_result'
	mat ub_result = ub_result'
	mat se_mat = se_mat'
	
    mat list `depvar'_on_`expvar'_result
	mat list lb_result
	mat list ub_result
	mat list freq_mat
	
	ereturn matrix `depvar'_bins = `depvar'_bins
	ereturn matrix `expvar'_bins = `expvar'_bins
	ereturn matrix `depvar'_on_`expvar'_result = `depvar'_on_`expvar'_result
	ereturn matrix ub_result = ub_result
	ereturn matrix lb_result = lb_result
	ereturn matrix freq_mat = freq_mat
	
	if "`binmedians'" != ""{
		
		mat `expvar'_medians = `expvar'_means
		mat `depvar'_medians = `depvar'_means
		mat `aiv'_medians = `aiv'_means
		mat `aiv'_medians_se = se_mat
		mat list `aiv'_medians		
		
		ereturn matrix `expvar'_medians = `expvar'_medians
		ereturn matrix `depvar'_medians = `depvar'_medians
		ereturn matrix `aiv'_medians = `aiv'_medians
		ereturn matrix `aiv'_medians_se = `aiv'_medians_se
	}
	else{
		mat list `aiv'_means
		mat `aiv'_means_se = se_mat
		
		ereturn matrix `expvar'_means = `expvar'_means
		ereturn matrix `depvar'_means = `depvar'_means
		ereturn matrix `aiv'_means = `aiv'_means
		ereturn matrix `aiv'_means_se = `aiv'_means_se
	}

	* save first stage as data
	if "`firstdata'" != ""{
		quietly{
			
			use `meandata', clear
			
			if "`equalbinwidthsx'" == "equalbinwidthsx"{
				merge 1:1 bin_var1 bin_var2 using `mid_var1_data'
				drop _merge
			}
			if "`equalbinwidthsy'" == "equalbinwidthsy"{
				merge 1:1 bin_var1 bin_var2 using `mid_var2_data'
				drop _merge
			}
			
			if "`xcategoryorder'" != ""{
				local equalbinwidthsx = ""
			}
			
			if "`firstcontourplot'" != ""{
					if "`binmedians'" != ""{
						local firstcontourplottitle = "Estimated median of `aiv' conditional on `expvar' and `depvar'"						
					}
					else{
						local firstcontourplottitle = "Estimated mean of `aiv' conditional on `expvar' and `depvar'"					
					}			
				
				if "`plotquantiles'" != ""{
					_pctile `aiv', nquantiles(`plotquantiles')
					local `aiv'_bins ""
					forvalues i = 1/`=`plotquantiles'-1' {
						local `aiv'_bins = "``aiv'_bins' `r(r`i')'"
					}
				}

				twoway contour `aiv' `depvar' `expvar', levels(`ncolors') title(`firstcontourplottitle') ytitle("`ytitle'") xtitle("`xtitle'") ccuts(``aiv'_bins') scolor(`scolor') ecolor(`ecolor') ccolors(`ccolors')
				
				if "`savefirstcontourplot'" != ""{
					graph export "`savefirstcontourplot'", replace
				}
			}
			
			if "`firstheatplot'" != ""{
				if "`firstheatplottitle'" == ""{
					if "`binmedians'" != ""{
						local firstheatplottitle = "Estimated median of `aiv' conditional on `expvar' and `depvar'"						
					}
					else{
						local firstheatplottitle = "Estimated mean of `aiv' conditional on `expvar' and `depvar'"					
					}

				}					
				
				if "`plotquantiles'" != ""{
					_pctile `aiv', nquantiles(`plotquantiles')
					local `aiv'_bins ""
					forvalues i = 1/`=`plotquantiles'-1' {
						local `aiv'_bins = "``aiv'_bins' `r(r`i')'"
					}
				}

				*twoway contour `aiv' `depvar' `expvar', levels(`ncolors') heatmap title(`firstheatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") ccuts(``aiv'_bins') scolor(`scolor') ecolor(`ecolor') ccolors(`ccolors')
				if "`equalbinwidthsx'" == "equalbinwidthsx" & "`equalbinwidthsy'" == "equalbinwidthsy"{
					heatplot `aiv' mid_var2 mid_var1, levels(`ncolors') title(`firstheatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") cuts(``aiv'_bins') colors(`ccolors')						
				}
				if "`equalbinwidthsx'" == "equalbinwidthsx" & "`equalbinwidthsy'" != "equalbinwidthsy"{
					heatplot `aiv' bin_var2 mid_var1, levels(`ncolors') title(`firstheatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") cuts(``aiv'_bins') colors(`ccolors')					
				}
				if "`equalbinwidthsx'" != "equalbinwidthsx" & "`equalbinwidthsy'" == "equalbinwidthsy"{
					heatplot `aiv' mid_var2 bin_var1, levels(`ncolors') title(`firstheatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") cuts(``aiv'_bins') colors(`ccolors')					
				}
				if "`equalbinwidthsx'" != "equalbinwidthsx" & "`equalbinwidthsy'" != "equalbinwidthsy"{
					heatplot `aiv' bin_var2 bin_var1, levels(`ncolors') title(`firstheatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") cuts(``aiv'_bins') colors(`ccolors')
				}
				if "`xcategoryorder'" != ""{
					local equalbinwidthsx = "equalbinwidthsx"
				}
				
				if "`savefirstheatplot'" != ""{
					graph export "`savefirstheatplot'", replace
				}		
			}
			
			if "`firstestimatesequal'" != ""{
		
				gen equal = 0
				gen lb = `aiv' - `critvalue' * SE
				gen ub = `aiv' + `critvalue' * SE
				replace equal = 1 if lb  <= `firstestimatesequal' & ub >= `firstestimatesequal'
				drop lb ub
				
				if "`estimatesequaltitle'" == "" {
					local firstestimatesequaltitle = "First stage estimates equal to `firstestimatesequal'"
				}
				
				
				*twoway contour equal `depvar' `expvar', levels(2) heatmap clegend(off) title(`firstestimatesequaltitle') ytitle("`ytitle'") xtitle("`xtitle'") ccolors(gs15 gs1) 
				
				qui sum(equal), meanonly
				local check = r(mean)
				if `check' == 0 {
					heatplot equal bin_var2 bin_var1, levels(2) title(`firstestimatesequaltitle') ytitle("`ytitle'") xtitle("`xtitle'") colors(gs15) legend(off)					
				}
				else {
					heatplot equal bin_var2 bin_var1, levels(2) title(`firstestimatesequaltitle') ytitle("`ytitle'") xtitle("`xtitle'") colors(gs15 gs1) legend(off)		
				}

				if "`savefirstestimatesequal'" != "" {
					graph export "`savefirstestimatesequal'", replace
				}
			}
			
			if "`firstdatacheck'" != ""{
				save "`firstdata'", replace				
			}
			

		}
	}


	
	* results as data
	if "`asdata'" != ""{
	quietly{
		
	drop if mi(`aiv') |  mi(`depvar') | mi(`expvar')	
		
	* Save the matrix into variables
	mat dd_de = e(`depvar'_on_`expvar'_result) 
	clear
	svmat dd_de

	gen dep = _n 
	replace dep = dep + 1
	reshape long dd_de, i(dep) j(exp)
	replace exp =  exp + 1
	rename (dd_de) (Estimate)
	tempfile esttemp
	save `esttemp', replace
	
	clear
	mat lb_result = e(lb_result)
	svmat lb_result
	gen dep = _n 
	replace dep = dep + 1
	reshape long lb_result, i(dep) j(exp)
	replace exp =  exp + 1
	merge 1:1 exp dep using `esttemp'
	drop _merge
	save `esttemp', replace
	
	clear
	mat ub_result = e(ub_result)
	svmat ub_result
	gen dep = _n 
	replace dep = dep + 1
	reshape long ub_result, i(dep) j(exp)
	replace exp =  exp + 1
	merge 1:1 exp dep using `esttemp'
	drop _merge

	* add cutoffs
	if "`xcategoryorder'" != ""{
			gen `expvar'_cutoff = exp
	}
	else{
		gen `expvar'_cutoff = .
		forvalues i = 1/`=`nbinx'-1'{
			local value = e(`expvar'_bins)[1, `i']
			replace `expvar'_cutoff = `value' if exp == `=`i'+1' 
		}
	}
	
	gen `depvar'_cutoff = .
	forvalues i = 1/`=`nbiny'-1'{
		local value = e(`depvar'_bins)[1, `i'] 
		replace `depvar'_cutoff = `value' if dep == `=`i'+1' 
	}
	
	rename(exp dep)(`expvar'_bin `depvar'_bin)
	
	drop if mi(Estimate) |  mi(`depvar'_cutoff) | mi(`expvar'_cutoff)
	
	if "`contourplot'" != ""{
			if "`contourplottitle'" == ""{
				local contourplottitle = "Estimated effect of `expvar' on `depvar'"
			}
		
			if "`plotquantiles'" != ""{
				_pctile Estimate, nquantiles(`plotquantiles')
				local Estimate_bins ""
				forvalues i = 1/`=`plotquantiles'-1' {
					local Estimate_bins = "`Estimate_bins' `r(r`i')'"
				}
			}		
		
			twoway contour Estimate `depvar'_cutoff `expvar'_cutoff, levels(`ncolors') title(`contourplottitle') ytitle("`ytitle'") xtitle("`xtitle'") ccuts(`Estimate_bins') scolor(`scolor') ecolor(`ecolor') ccolors(`ccolors')
				
			if "`savecontourplot'" != ""{
				graph export "`savecontourplot'", replace
			}		
	}
	
	if "`heatplot'" != ""{
			if "`heatplottitle'" == ""{
				local heatplottitle = "Estimated effect of `expvar' on `depvar'" 
			}
			
			if "`plotquantiles'" != ""{
				_pctile Estimate, nquantiles(`plotquantiles')
				local Estimate_bins ""
				forvalues i = 1/`=`plotquantiles'-1' {
					local Estimate_bins = "`Estimate_bins' `r(r`i')'"
				}
			}
			
		*twoway contour Estimate `depvar'_cutoff `expvar'_cutoff, levels(`ncolors') heatmap title(`heatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") ccuts(`Estimate_bins') scolor(`scolor') ecolor(`ecolor') ccolors(`ccolors')
		if "`equalbinwidthsx'" == "equalbinwidthsx" & "`equalbinwidthsy'" == "equalbinwidthsy" {
			heatplot Estimate `depvar'_cutoff `expvar'_cutoff, levels(`ncolors') title(`heatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") cuts(`Estimate_bins') colors(`ccolors')
		}
		if "`equalbinwidthsx'" == "equalbinwidthsx" & "`equalbinwidthsy'" != "equalbinwidthsy" {
			heatplot Estimate `depvar'_bin `expvar'_cutoff, levels(`ncolors') title(`heatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") cuts(`Estimate_bins') colors(`ccolors')
		}
		if "`equalbinwidthsx'" != "equalbinwidthsx" & "`equalbinwidthsy'" == "equalbinwidthsy" {
			heatplot Estimate `depvar'_cutoff `expvar'_bin, levels(`ncolors') title(`heatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") cuts(`Estimate_bins') colors(`ccolors')
		}
		if "`equalbinwidthsx'" != "equalbinwidthsx" & "`equalbinwidthsy'" != "equalbinwidthsy" {
			heatplot Estimate `depvar'_bin `expvar'_bin, levels(`ncolors') title(`heatplottitle') ytitle("`ytitle'") xtitle("`xtitle'") cuts(`Estimate_bins') colors(`ccolors')
		}
		
		if "`saveheatplot'" != ""{
			graph export "`saveheatplot'", replace
		}
	}	
	
	if "`estimatesequal'" != ""{
		
		gen equal = 0
		replace equal = 1 if  lb_result <= `estimatesequal' & ub_result >= `estimatesequal'
		
		if "`estimatesequaltitle'" == "" {
			local estimatesequaltitle = "Estimates equal to `estimatesequal'"
		}
		
		
		*twoway contour equal `depvar'_cutoff `expvar'_cutoff, levels(2) heatmap clegend(off) title(`estimatesequaltitle') ytitle("`ytitle'") xtitle("`xtitle'") ccolors(gs15 gs1)
		
		qui sum(equal), meanonly
		local check = r(mean)
		
		if `check' == 0 {
			heatplot equal `depvar'_bin `expvar'_bin, levels(2) title(`estimatesequaltitle') ytitle("`ytitle'") xtitle("`xtitle'") colors(gs15) legend(off)			
		}
		else {
			heatplot equal `depvar'_bin `expvar'_bin, levels(2) title(`estimatesequaltitle') ytitle("`ytitle'") xtitle("`xtitle'") colors(gs15 gs1) legend(off)			
		}

		
		if "`saveestimatesequal'" != "" {
			graph export "`saveestimatesequal'", replace
		}
	}
	
	if "`asdatacheck'" != ""{
		save "`asdata'", replace		
	}
	
	use `preservefile', clear
	}	
	}
	


	


	
	restore
	
end

