{smcl}
{* *! version 1.0 9 Oct 2025}{...}
{title:aivreg — Anti-IV Regression}

{title:Syntax}

{p 8 17 2}
{cmd:aivreg} [{it:estimator}] {depvar} {help varlist:varlist} [{help if}] [{help in}], 
{cmd:aiv}({help varlist:varlist}) 
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr:estimators}
{synoptline}
{synopt:{opt ratio}} default estimator; ratio-of-coefficients. Allows a single Anti-IV.{p_end}
{synopt:{opt 2sls}} two-stage least squares Anti-IV estimator. Allows multiple Anti-IVs.{p_end}
{synopt:{opt gmm}} generalized method of moments Anti-IV estimator. Allows multiple Anti-IVs.{p_end}
{synoptline}

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model specification}
{synopt:{opt aiv(varlist)}}anti-IV variables.{p_end}
{synopt:{opt control(varlist)}}control variables.{p_end}
{synopt:{opt fe(varlist)}}fixed effects to absorb.{p_end}
{synopt:{opt weight(...)}}observation weights for estimation.{p_end}
{synopt:{opt twostep}}default for GMM; run twostep GMM.{p_end}
{synopt:{opt initialweightmatrix(matrix)}}initial estimation weight matrix for two-step GMM.{p_end}
{synopt:{opt onestep}}run onestep GMM.{p_end}
{synopt:{opt weightingmatrix(matrix)}}estimation weight matrix for one-step GMM.{p_end}
{synopt:{opt ignoresingularity}}if a (nearly) singular matrix is detected, continue without an error.{p_end}
{syntab:Estimation & storage}
{synopt:{opt eststo(name)}}store estimates under {it:name}.{p_end}
{synopt:{opt savefirst}}save first-stage regression results.{p_end}
{synopt:{opt firststo(name)}}store first-stage estimates under {it:name}.{p_end}

{syntab:Variance & inference}
{synopt:{opt vce(type)}}variance estimator: {it:ar} (default), {it:{ul:b}oot}, {it:{ul:as}ymp}.{p_end}
{synopt:{opt cluster(varlist)}}cluster-robust SEs.{p_end}
{synopt:{opt reps(#)}}number of bootstrap replications.{p_end}
{synopt:{opt seed(#)}}random seed for bootstrap.{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:aivreg} implements the anti-IV estimator outlined in {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974":Bell, Billings, Calder-Wang, & Zhong (2024)}. The method allows the user to estimate implicit amenity prices in the presence of an unobservable confounder.

{title:Details}

{dlgtab:Estimator}
{phang}- {bf:ratio}    default estimator; ratio-of-coefficients. Allows a single Anti-IV.{p_end}
{phang}- {bf:2sls}     two-stage least squares Anti-IV estimator. Allows multiple Anti-IVs.{p_end}
{phang}- {bf:gmm}      generalized method of moments Anti-IV estimator. Allows multiple Anti-IVs.{p_end}

{dlgtab:Model specification}
{phang}- {bf:aiv(}{it:varlist}{bf:)}    Anti-IV variables (one for {it:ratio}, one or more for {it:2sls} and {it:gmm}).{p_end}
{phang}- {bf:control(}{it:varlist}{bf:)}  Exogenous controls included in both stages; assumed conditionally orthogonal with the Anti-IV and outcome given the latent confounder.{p_end}
{phang}- {bf:fe(}{it:varlist}{bf:)}      Absorb fixed effects.{p_end}
{phang}- {bf:weight(...)}   For {it:ratio}: probability/frequency/analytic weights using brackets, e.g., {cmd:weight([aw=wt])}. For {it:gmm} and {it:2sls}: probability weights only, e.g., {cmd:weight(wvar)}.{p_end}

{dlgtab:ratio}
{phang}- {bf:vce(}{it:type}{bf:)}  Variance estimator: {it:AR} (default, Anderson–Rubin), {it:bootstrap}, or {it:asymptotic}.{p_end}
{phang}- {bf:cluster(}{it:varlist}{bf:)}  Cluster-robust SEs.{p_end}
{phang}- {bf:reps(}{it:#}{bf:)}  Bootstrap repetitions (default 50).{p_end}
{phang}- {bf:seed(}{it:#}{bf:)}  Random seed for bootstrap reproducibility.{p_end}

{dlgtab:2sls}
{phang}- {bf:cluster(}{it:varlist}{bf:)}  Cluster-robust SEs.{p_end}
{phang}- {bf:onestep}  Default, runs one-step GMM with 2SLS-equivalent weight matrix.{p_end}
{phang}- {bf:twostep}  Runs two-step GMM with 2SLS in step one.{p_end}
{phang}- {bf:ignoresingularity} If a (nearly) singular matrix is detected, continue without an error.{p_end}

{dlgtab:gmm}
{phang}- {bf:cluster(}{it:varlist}{bf:)}  Cluster-robust SEs.{p_end}
{phang}- {bf:twostep}  Default; runs two-step GMM.{p_end}
{phang}- {bf:initweightmatrix(}{it:matrix}{bf:)}  Initial weighting matrix for two-step GMM. Defaults to identity. Accepts {it:identity}, {it:unadjusted}, or a matrix name. {it:initialweightmatrix(unadjusted)} requests a weight matrix that is suitable when the errors are homoskedastic.  The GMM estimator with this weight matrix is equivalent to the 2SLS estimator.{p_end}
{phang}- {bf:onestep}  Runs one-step GMM.{p_end}
{phang}- {bf:weightingmatrix(}{it:matrix}{bf:)}  Weight matrix for one-step GMM. Defaults to identity. Accepts {it:identity}, {it:unadjusted}, or a matrix name. {it:weightingmatrix(unadjusted)} requests a weight matrix that is suitable when the errors are homoskedastic.  The GMM estimator with this weight matrix is equivalent to the 2SLS estimator.{p_end}
{phang}- {bf:ignoresingularity} If a (nearly) singular matrix is detected, continue without an error.{p_end}

{dlgtab:Estimation & storage}
{phang}- {bf:eststo(}{it:name}{bf:)}  Store fitted model under {it:name}. Also compatible with {cmd:eststo: aivreg ...}.{p_end}
{phang}- {bf:savefirst}  Report and store first-stage regression. For {it:ratio}, if {bf:firststo()} is unspecified, first stage is named {it:_ivreg2_varname} where {it:varname} is the Anti-IV. For {it:gmm} and {it:2sls}, defaults to saving as {it:aivgmm_h} for each Anti-IV {it:h}.{p_end}
{phang}- {bf:firststo(}{it:name}{bf:)}  Store first-stage estimates under {it:name} for {it:ratio}; for {it:gmm} and {it:2sls}, first stages are stored as {it:name}{it:h} for each Anti-IV {it:h}.{p_end}


{dlgtab:Saved results}

{pstd}
{cmd:aivreg} saves results in {cmd:e()}.

{synoptset 22 tabbed}
{synopthdr:Scalars}
{synoptline}
{synopt:{cmd:e(Partial_F)}}partial F-statistic from first stage (Not in 2SLS or GMM){p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(Jval)}}J-test statistic (2SLS and GMM only, and only when there are multiple Anti-IVs){p_end}
{synopt:{cmd:e(pval_J)}}p-value of J-test (2SLS and GMM only, and only when there are multiple Anti-IVs){p_end}
{synopt:{cmd:e(betavarname)}}coefficient on variable {it:varname}{p_end}
{synopt:{cmd:e(SE_vcevarname)}}standard error of the coefficient on variable {it:varname}, using {opt vce} (either AR, asymp, boot, 2sls, or gmm); if AR, SE approximated using CI closest to zero{p_end}
{synopt:{cmd:e(t_valvarname)}}t-value for the coefficient on variable {it:varname}{p_end}
{synopt:{cmd:e(p_more_tvarname)}}t-test statistic for the coefficient on variable {it:varname}{p_end}
{synopt:{cmd:e(lb_vcevarname)}}lower bound for the coefficient on variable {it:varname} (95% confidence), using {opt vce} (either AR, asymp, boot, 2sls, or gmm){p_end}
{synopt:{cmd:e(lb_vcevarname)}}upper bound for the coefficient on variable {it:varname} (95% confidence), using {opt vce} (either AR, asymp, boot, 2sls, or gmm){p_end} 
{synopt:{cmd:e(kappa)}}condition number for inverted matrix in 2SLS and GMM formulas. Warning message appears when it is > 10^12. (2SLS and GMM only){p_end}
{synoptline}

{synopthdr:Macros}
{synoptline}
{synopt:{cmd:e(cmd)}}aivreg{p_end}
{synoptline}

{synopthdr:Matrices}
{synoptline}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}estimated covariance matrix of coefficients; in AR, diagonal matrix with values approximated from AR CI closest to zero{p_end}
{synopt:{cmd:e(S)}}estimated covariance matrix of moments (2SLS and GMM only){p_end}
{synopt:{cmd:e(weightingmatrix)}}weight matrix (2SLS and GMM only; last weight matrix used for twostep){p_end}
{synoptline}

{synopthdr:Functions}
{synoptline}
{synopt:{cmd:e(sample)}}retrieve estimation sample{p_end}
{synoptline}

{title:Examples}

{pstd}
The following examples use simulated or sampled data which are included in the aivreg package SSC release. All commands are clickable.

{pstd}
{bf:Flood Risk Example}

{pstd}The underlying data in Bell, Billings, Calder-Wang and Zhong (2024) are from commercial providers; for illustrative purposes, we thus provided a small, simulated version of the data. For the underlying DGP, please see simulate_flood_risk_data.do. 

{pstd}Load the simulated flood risk dataset.{p_end}
{phang} {stata use simulated_flood_risk.dta, clear}

{phang} {stata estimates clear}

{pstd}An OLS regression with block FE is not sufficient to retrieve the implicit price of flood risk.{p_end}
{phang} {stata "eststo: reghdfe log_price i.flood_factor, absorb(block_id)"}

{pstd}If we control for the log income of the home buyers, under the intuition that it is informative for the unobserved quality, the estimates are still biased.{p_end}
{phang} {stata "eststo: reghdfe log_price i.flood_factor log_income, absorb(block_id)"}

{pstd}But when {cmd:aivreg} uses income as the anti-IV, it will correctly estimate the implicit price of flood risk.{p_end}
{phang} {stata "eststo: aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) vce(asymp)"}

{pstd}{cmd:aivreg} can also use Anderson-Rubin confidence intervals. This is particularly helpful when there is a weak anti-IV. Anderson-Rubin confidence intervals are the default of {cmd:aivreg}; however, one can also call them using {opt vce(AR)}. In this setting, log income is a strong anti-IV, so the confidence interval is similar to those calculated above.{p_end}
{phang} {stata "eststo: aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) vce(AR)"}

{pstd}The option {cmd:savefirst} shows the first stage regression to help judge the strength on the anti-IV.{p_end}
{phang} {stata "aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) vce(AR) savefirst"}

{pstd}Display or export results with {help esttab}.{p_end}
{phang} {stata esttab est1 est2 est3 est4, mgroup("reghdfe" "reghdfe + anti-IV control" "aivreg" "aivreg + AR CI", pattern(1 1 1 1)) modelwidth(20) varwidth(18) label}

{phang} {stata estimates clear}

{pstd}There is also a 2SLS version which allows for multiple anti-IV variables.{p_end}
{phang} {stata "eststo: aivreg 2sls log_price i.flood_factor i.block_id, aiv(log_income)"}

{pstd}And this is the more general GMM version of {cmd:aivreg}.{p_end}
{phang} {stata "eststo: aivreg gmm log_price i.flood_factor i.block_id, aiv(log_income)"}

{pstd}GMM and 2SLS estimators also offer a {opt savefirst} option.{p_end}
{phang} {stata "aivreg gmm log_price i.flood_factor i.block_id, aiv(log_income) savefirst"}

{pstd}Show results in {help esttab}.{p_end}
{phang} {stata esttab est1 est2, keep(flood_factor*) mgroup("2sls" "GMM", pattern(1 1)) label}

{pstd}
{bf:Safety and Wages Example}

{pstd}Load the dataset of wages and job safety, which is sampled from the data used in Bell (2020).{p_end}
{phang} {stata use safety_aivreg_example.dta, clear}

{phang} {stata estimates clear}

{pstd}A naive hedonic regression can be misleading.{p_end}
{phang} {stata "eststo: reg wage safety"}

{pstd}Even controlling for the anti-IV in OLS may not fix it.{p_end}
{phang} {stata "eststo: reg wage safety afqt_1_1981"}

{pstd}{cmd:aivreg} improves identification using AFQT scores as an anti-IV.{p_end}
{phang} {stata "eststo: aivreg wage safety, aiv(afqt_1_1981)"}

{pstd}Show results in {help esttab}.{p_end}
{phang} {stata esttab est1 est2 est3}

{pstd}{cmd:aivreg} GMM and 2SLS versions can use multiple anti-IVs. And {opt savefirst} shows the first stages. Here are the results using test scores again.{p_end}
{phang} {stata "eststo: aivreg 2sls wage safety, aiv(afqt_1_1981)"}

{pstd}Next, here is using height after controlling for sex.{p_end}
{phang} {stata "eststo: aivreg 2sls wage safety, aiv(height_res_sex)"}

{pstd}And now we use both anti-IVs. In the top right, {cmd:aivreg} shows the J-Test statistic and the corresponding p-value.{p_end}
{phang} {stata "eststo: aivreg 2sls wage safety, aiv(afqt_1_1981 height_res_sex) savefirst"}

{pstd}The results can be compared using {help esttab}.{p_end}
{phang} {stata esttab est4 est5 est6}

{title:Dependencies}

{pstd}
{cmd:aivreg} requires stata 17 or higher. It also requires {help ivreg2}, {help ranktest}, {help distinct}, {help reghdfe}, and {help ivreghdfe}. 

{title:Contact}

{pstd}
Questions or concerns: {browse "mailto:aivregstata@gmail.com":aivregstata@gmail.com}

{title:If you encounter "option requirements not allowed r(198)"}

{pstd}This is a rather common issue that stems from {help ivreghdfe} not having been properly installed. Try reinstalling required packages through the following commands:

{pstd}Install ftools{p_end}
{phang} {stata "cap ado uninstall ftools"}

{phang} {stata `"net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/") replace"'}

{pstd}Install reghdfe{p_end}
{phang} {stata "cap ado uninstall reghdfe"}

{phang} {stata `"net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/") replace"'}

{pstd}Install ivreg2{p_end}
{phang} {stata "cap ado uninstall ivreg2"}

{phang} {stata "ssc install ivreg2, replace"}

{pstd}Install ivreghdfe{p_end}
{phang} {stata "cap ado uninstall ivreghdfe"}

{phang} {stata `"net install ivreghdfe, from("https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/") replace"'}

{title:References}

{phang} - Bell, A. (2020) {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":Job Amenities and Earnings Inequality}. 

{phang} - Bell, A, Billings, S. B., Calder-Wang, S., & Zhong, S. (2024) {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974":An Anti-IV Approach for Pricing Residential Amenities: Applications to Flood Risk}

{phang} - Correia, S. (2018) {browse "https://ideas.repec.org/c/boc/bocode/s458530.html":IVREGHDFE: Stata module for extended instrumental variable regressions}.

