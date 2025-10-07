{smcl}
{* *! version 1.0 25 Apr 2025}{...}
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
{cmd:aivreg} implements the anti-IV estimator outlined in Bell et al. (2025). The method allows the user to estimate consistent, unbiased hedonic prices when the error term is caused by an imperfectly informative variable (anti-IV) for a confounding variable. An example includes the cost of flood risk to home prices, where buyer income is informative for unobserved home quality.

{title:Details}

{dlgtab:Estimator}

{phang}
{it:estimator} can be left blank, and {cmd:aivreg} will default to using OLS to estimate the relationships by calling {help ivreg2}, {help reg}, {help reghdfe}, or {help ivreghdfe}; this is equivalent to specifying {it:ols}. If it is set to {it:gmm}, instead the GMM estimator is used, defaulting to the identity weight matrix. And if set to {it:2sls}, aivreg uses GMM but sets the weight matrix to the optimal weight matrix under homoskedasticity, which yields equivalent point estimates as {it:ols} if there is only one anti-IV.

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
{opt weightmatrix(matrix)} weight matrix for GMM. Should be square with the number of rows equalling the number of amenities + number of controls + 2 X number of anti-IVs. Defaults to identity. (For GMM only.)

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
{opt reps(#)} sets the number of bootstrap repetitions.

{phang}
{opt seed(#)} sets the random seed for bootstrap reproducibility. Defaults to 50.

{title:Examples}

{pstd}
The following examples use simulated or sampled data which are included in the aivreg package SSC release. All commands are clickable.

{pstd}Load the simulated flood risk dataset. This is made in simulate_flood_risk_data.do, which is included in the aivreg package.{p_end}
{phang} {stata use simulated_flood_risk.dta, clear}

{pstd}Baseline OLS with an anti-IV for quality (buyer income).{p_end}
{phang} {stata reg log_price i.flood_factor log_income}

{pstd}High-dimensional FE by block.{p_end}
{phang} {stata reghdfe log_price i.flood_factor log_income, absorb(block_id)}

{phang} {stata estimates store hdfe1}

{pstd}{cmd:aivreg} using income as the anti-IV.{p_end}
{phang} {stata aivreg log_price i.flood_factor, aiv(log_income) vce(asymp) eststo(aiv1)}

{pstd}{cmd:aivreg} with controls and block fixed effects; Anderson-Rubin confidence interval.{p_end}
{phang} {stata aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) eststo(aiv2)}

{pstd}Display or export results with {help esttab}.{p_end}
{phang} {stata esttab hdfe1 aiv1 aiv2, mgroup("reghdfe" "aivreg" "aivreg + FE + AR CI", pattern(1 1 1)) modelwidth(20) varwidth(18) label}

{pstd}Make singular dummy for flood factor 10 as GMM does not accept factor variables.{p_end}
{phang} {stata tabulate flood_factor, generate(flood_factor)}

{phang} {stata label var flood_factor10 "Flood risk factor=10"}

{phang} {stata drop if flood_factor != 1 & flood_factor != 10}

{pstd}GMM version of {cmd:aivreg}.{p_end}
{phang} {stata aivreg gmm log_price flood_factor10, aiv(log_income) eststo(aiv_gmm)}

{pstd}2SLS version for comparison.{p_end}
{phang} {stata aivreg 2sls log_price flood_factor10, aiv(log_income) eststo(aiv_2sls)}

{pstd}Show results in {help esttab}.{p_end}
{phang} {stata esttab aiv_gmm aiv_2sls}

{pstd}Load the sample wages dataset.{p_end}
{phang} {stata use safety_aivreg_example.dta, clear}

{pstd}A naive hedonic regression can be misleading.{p_end}
{phang} {stata reg wage safety}

{pstd}Even controling for the anti-IV in OLS may not fix it.{p_end}
{phang} {stata reg wage safety afqt_1_1981}

{pstd}{cmd:aivreg} improves identification using a anti-IV.{p_end}
{phang} {stata aivreg wage safety, aiv(afqt_1_1981) eststo(model1)}

{pstd}Show results in {help esttab}.{p_end}
{phang} {stata esttab model1}

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
{synopt:{cmd:e(SE_vcevarname)}}standard error of coefficient on variable {it:varname}, using {it:vce} (either AR, asymp, or boot); if AR, SE approximated using CI closest to zero{p_end}
{synopt:{cmd:e(t_valvarname)}}t-value for coefficient on variable {it:varname}{p_end}
{synopt:{cmd:e(p_more_tvarname)}}t-test statistic for coefficient on variable {it:varname}{p_end}
{synopt:{cmd:e(lb_vcevarname)}}lower bound for coefficient on variable {it:varname} (95% confidence), using {it:vce} (either AR, asymp, or boot){p_end}
{synopt:{cmd:e(lb_vcevarname)}}upper bound for coefficient on variable {it:varname} (95% confidence), using {it:vce} (either AR, asymp, or boot){p_end}
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

{title:Contact}

{pstd}
Questions or concerns: {browse "mailto:aivregstata@gmail.com":aivregstata@gmail.com}

{title:References}

{phang} - Bell, A. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":Job Amenities and Earnings Inequality} (2020). 

{phang} - Bell, A., Calder-Wang, S., & Zhong, S. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4565093":Pricing Neighborhood Amenities: A Proxy-Based Approach} (2023). 

{phang} - Bell, A, Billings, S. B., Calder-Wang, S., & Zhong, S. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974":An Anti-IV Approach for Pricing Residential Amenities: Applications to Flood Risk} (2024)

{phang} - Correia, S. {browse "https://ideas.repec.org/c/boc/bocode/s458530.html":IVREGHDFE: Stata module for extended instrumental variable regressions} (2018).

