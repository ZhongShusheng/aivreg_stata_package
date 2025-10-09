{smcl}
{* *! version 1.0 9 Oct 2025}{...}
{title:aivreg — Anti-IV Regression}

{title:Syntax}

{p 8 17 2}
{cmd:aivreg} [{it:estimator}] {depvar} {help varlist:varlist} [{help if}] [{help in}], 
{cmd:aiv}({help varlist:varlist}) 
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model specification}
{synopt:{opt aiv(varlist)}}anti-IV variables (one for OLS, multiple for GMM).{p_end}
{synopt:{opt control(varlist)}}control variables.{p_end}
{synopt:{opt fe(varlist)}}fixed effects to absorb (via {help reghdfe} or {help ivreghdfe}). Not available for GMM.{p_end}
{synopt:{opt weight(...)}}observation weights for estimation.{p_end}
{synopt:{opt weightmatrix(matrix)}}estimation weight matrix for estimation (GMM only).{p_end}

{syntab:Estimation & storage}
{synopt:{opt eststo(name)}}store estimates under {it:name}.{p_end}
{synopt:{opt savefirst}}save first-stage regression results.{p_end}
{synopt:{opt firststo(name)}}store first-stage estimates under {it:name}.{p_end}
{synopt:{opt displayaiv}}display coefficient on predicted anti-IV.{p_end}

{syntab:Variance & inference}
{synopt:{opt vce(type)}}variance estimator: {it:ar} (default), {it:{ul:b}oot}, {it:{ul:as}ymp}.{p_end}
{synopt:{opt cluster(varlist)}}cluster-robust SEs.{p_end}
{synopt:{opt reps(#)}}number of bootstrap replications.{p_end}
{synopt:{opt seed(#)}}random seed for bootstrap.{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:aivreg} implements the anti-IV estimator outlined in Bell, Billings, Calder-Wang, & Zhong (2024). The method allows the user to estimate consistent, unbiased hedonic prices when the error term is caused by an imperfectly informative variable (anti-IV) for a confounding variable. Examples include the implicit price of flood risk for home prices, where buyer income is informative for unobserved home quality, or the implicit price of job safety for wages, where test scores are informative for worker skills.

{title:Details}

{dlgtab:Estimator}

{phang}
{it:estimator} will default to using OLS to estimate the relationships by calling {help ivreg2}, {help reg}, {help reghdfe}, or {help ivreghdfe} if left blank; this is equivalent to specifying {it:ols}. If it is set to {it:gmm}, instead the GMM estimator is used, defaulting to the identity weight matrix. And if set to {it:2sls}, aivreg uses GMM but sets the weight matrix to the optimal weight matrix under homoskedasticity, which yields equivalent point estimates as {it:ols} if there is only one anti-IV.

{dlgtab:Model specification}

{phang}
{opt aiv(varlist)} specifies the anti-IV variables. OLS supports one anti-IV; GMM allows multiple. {cmd:aivreg} will automatically switch to GMM if multiple anti-IVs are specified. 

{phang}
{opt control(varlist)} specifies exogenous control variables included in both stages. These represent additional controls on which conditional independence of the anti-IV and the outcome given the latent confounder holds.

{phang}
{opt fe(varlist)} absorbs fixed effects using {help reghdfe} or {help ivreghdfe}. If unspecified, then {cmd:aivreg} calls {help reg} or {help ivreg2} instead. This is not available in GMM.

{phang}
{opt weight(...)} allows either probability/frequency/analytic weights for OLS or probability weights for GMM. For the OLS estimator, use brackets: for example, {it:weight([aw=wt])} (see {help weight} for guidence). For GMM, only place the variable to weigh by: for example, {it:weight(varname)}. GMM uses probability weights.

{phang}
{opt weightmatrix(matrix)} is the moment weight matrix for GMM. Should be square with the number of rows equalling the number of amenities + number of controls + 2 X number of anti-IVs. Defaults to identity. (For GMM only.)

{dlgtab:Estimation & storage}

{phang}
{opt eststo(name)} stores the fitted model under {it:name} for later retrieval. {cmd:aivreg} is also compatible with the syntax {help eststo}: {cmd:aivreg}. 

{phang}
{opt savefirst} reports and stores the first-stage regression. If {opt firststo(name)} is unspecified, then the first stage is named {it: _ivreg2_varname}, where {it:varname} is the anti_IV's variable name.

{phang}
{opt firststo(name)} stores the first-stage estimates under {it:name}.

{phang}
{opt displayaiv} displays the coefficient on the predicted anti-IV (not available with Anderson–Rubin CIs).

{dlgtab:Variance & inference}

{phang}
{opt vce(type)} specifies the variance estimator:  
  {it:ar} for Anderson–Rubin (default),  
  {it:{ul:b}ootstrap} for bootstrap SEs,  
  {it:{ul:as}ymptotic} for asymptotic SEs via {help ivreg2} or {help ivreghdfe}.

{phang}
{opt cluster(varlist)} provides cluster-robust SEs.

{phang}
{opt reps(#)} sets the number of bootstrap repetitions. Defaults to 50.

{phang}
{opt seed(#)} sets the random seed for bootstrap reproducibility.

{title:Saved results}

{pstd}
{cmd:aivreg} saves results in {cmd:e()}.

{synoptset 22 tabbed}
{synopthdr:Scalars}
{synoptline}
{synopt:{cmd:e(Partial_F)}}partial F-statistic from first stage{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(Jval)}}J-test statistic (GMM only){p_end}
{synopt:{cmd:e(pval_J)}}p-value of J-test (GMM only){p_end}
{synopt:{cmd:e(betavarname)}}coefficient on variable {it:varname}{p_end}
{synopt:{cmd:e(SE_vcevarname)}}standard error of the coefficient on variable {it:varname}, using {it:vce} (either AR, asymp, or boot); if AR, SE approximated using CI closest to zero{p_end}
{synopt:{cmd:e(t_valvarname)}}t-value for the coefficient on variable {it:varname}{p_end}
{synopt:{cmd:e(p_more_tvarname)}}t-test statistic for the coefficient on variable {it:varname}{p_end}
{synopt:{cmd:e(lb_vcevarname)}}lower bound for the coefficient on variable {it:varname} (95% confidence), using {it:vce} (either AR, asymp, or boot){p_end}
{synopt:{cmd:e(lb_vcevarname)}}upper bound for the coefficient on variable {it:varname} (95% confidence), using {it:vce} (either AR, asymp, or boot){p_end}
{synoptline}

{synopthdr:Macros}
{synoptline}
{synopt:{cmd:e(cmd)}}aivreg{p_end}
{synoptline}

{synopthdr:Matrices}
{synoptline}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance–covariance matrix; in AR, diagonal matrix with values approximated from AR CI closest to zero{p_end}
{synopt:{cmd:e(S)}}estimated covariance matrix of moments (GMM only){p_end}
{synopt:{cmd:e(weightmatrix)}}weight matrix (GMM only){p_end}
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

{pstd}{cmd:aivreg} can also use Anderson-Rubin confidence intervals. This is particularly helpful when there is a weak anti-IV. Anderson-Rubin confidence intervals are the default of {cmd:aivreg}; however, one can also call them using {it:vce(ar)}. In this setting, log income is a strong anti-IV, so the confidence interval is similar to those calculated above.{p_end}
{phang} {stata "eststo: aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) vce(ar)"}

{pstd}The option {cmd:savefirst} shows the first stage regression to help judge the strength on the anti-IV.{p_end}
{phang} {stata "aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) vce(ar) savefirst"}

{pstd}Display or export results with {help esttab}.{p_end}
{phang} {stata esttab est1 est2 est3 est4, mgroup("reghdfe" "reghdfe + anti-IV control" "aivreg" "aivreg + AR CI", pattern(1 1 1 1)) modelwidth(20) varwidth(18) label}

{phang} {stata estimates clear}

{pstd}There is also a 2SLS version which allows for multiple anti_IV variables.{p_end}
{phang} {stata "eststo: aivreg 2sls log_price i.flood_factor i.block_id, aiv(log_income)"}

{pstd}And this is the more general GMM version of {cmd:aivreg}.{p_end}
{phang} {stata "eststo: aivreg gmm log_price i.flood_factor i.block_id, aiv(log_income)"}

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

{pstd}{cmd:aivreg} improves identification using a anti-IV.{p_end}
{phang} {stata "eststo: aivreg wage safety, aiv(afqt_1_1981)"}

{pstd}Show results in {help esttab}.{p_end}
{phang} {stata esttab est1 est2 est3}



{title:Contact}

{pstd}
Questions or concerns: {browse "mailto:aivregstata@gmail.com":aivregstata@gmail.com}

{title:References}

{phang} - Bell, A. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":Job Amenities and Earnings Inequality} (2020). 

{phang} - Bell, A, Billings, S. B., Calder-Wang, S., & Zhong, S. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974":An Anti-IV Approach for Pricing Residential Amenities: Applications to Flood Risk} (2024)

{phang} - Correia, S. {browse "https://ideas.repec.org/c/boc/bocode/s458530.html":IVREGHDFE: Stata module for extended instrumental variable regressions} (2018).

