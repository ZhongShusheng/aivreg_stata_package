{smcl}
{* *! version 2.0 25 Apr 2025}{...}
{title:aivreg - Anti-IV Regression in Stata}

{pstd}
The Stata {bf:aivreg} command implements the anti-IV method used in 
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":Bell (2022)}, 
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4565093":Bell, Calder-Wang, and Zhong (2023)}, and 
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974":Bell et al. (2024)}.

{title:Installation}

{phang} - Download {cmd:aivreg.ado} and {cmd:aivreg.sthlp} from the repository.

{phang} - In Stata, type {cmd:sysdir} to find the directory listed as {cmd:PERSONAL}.

{phang} - Move {cmd:aivreg.ado} and {cmd:aivreg.sthlp} into the {cmd:PERSONAL} directory.

{title:General Syntax}

{phang} {cmd:aivreg} [{it:estimator}] {it:depvar} {it:varlist} [{cmd:if}] [{cmd:in}], 
{cmd:aiv}({it:varlist}) [{cmd:control}({it:string})] [{cmd:fe}({it:varlist})] [{cmd:weight}({it:string})] 
[{cmd:eststo}({it:string})] [{cmd:vce}({it:string})] [{cmd:reps}({it:string})] [{cmd:seed}({it:string})] 
[{cmd:cluster}({it:varlist})] [{cmd:savefirst}] [{cmd:firststo}({it:string})] [{cmd:displayaiv}] 
[{cmd:steps}({it:string})] [{cmd:conv_ptol}({it:string})] [{cmd:conv_vtol}({it:string})] 
[{cmd:igmmiterate}({it:string})] [{cmd:igmmeps}({it:string})] [{cmd:igmmweps}({it:string})] 
[{cmd:technique}({it:string})] [{cmd:conv_maxiter}({it:string})] [{cmd:tracelevel}({it:string})]

{title:Syntax for OLS Estimator}

{phang} {cmd:aivreg} {it:depvar} {it:varlist} [{cmd:if}] [{cmd:in}], 
{cmd:aiv}({it:varlist}) [{cmd:control}({it:string})] [{cmd:fe}({it:varlist})] [{cmd:weight}({it:string})] 
[{cmd:eststo}({it:string})] [{cmd:vce}({it:string})] [{cmd:reps}({it:string})] [{cmd:seed}({it:string})] 
[{cmd:cluster}({it:varlist})] [{cmd:savefirst}] [{cmd:firststo}({it:string})] [{cmd:displayaiv}]

{title:Input List}

{phang} - {bf:estimator} specify "gmm" for GMM estimation; otherwise leave blank

{phang} - {bf:depvar} the outcome variable

{phang} - {bf:varlist} the list of amenities

{phang} - {bf:aiv} a list of anti-IV variables (currently supports one anti-IV variable for OLS)

{phang} - {bf:control} specify the list of control variables

{phang} - {bf:fe} list of fixed effects to be absorbed; uses {cmd:ivreghdfe} or {cmd:reghdfe}

{phang} - {bf:weight} specifies weighting options; e.g., {cmd:weight([w=wt])}

{phang} - {bf:eststo} specifies the model name to store the estimates under

{phang} - {bf:vce} specify standard error estimation: Anderson-Rubin (default); boot (bootstrap SE); asymp (ivreg2 or ivreghdfe SE)

{phang} - {bf:reps} number of repetitions (for bootstrap only)

{phang} - {bf:seed} seed for bootstrap (for bootstrap only)

{phang} - {bf:cluster} cluster variables for standard errors

{phang} - {bf:savefirst} saves and reports the first-stage regression

{phang} - {bf:firststo} stores the name of the first stage estimates

{phang} - {bf:displayaiv} displays the coefficient on the predicted value of the anti-IV (not available with Anderson-Rubin CI)

{title:Return List}

{phang} - {bf:Partial F} Partial F-statistic at the first stage comparing with and without the depvar as a control (Available with {cmd:e(Partial_F)})

{phang} - {bf:Coef.} Coefficient for the amenity "var" (Available with {cmd:e(beta_varname)})

{phang} - {bf:Std. Err.} Standard error of the coefficient (in Anderson-Rubin case, approximated from CI) (Available with {cmd:e(SE_vcevarname)})

{phang} - {bf:t} t-statistic estimate of the coefficient (Available with {cmd:e(t_val_varname)})

{phang} - {bf:P>|t|} p-value based on the t-statistic (Available with {cmd:e(p_varname)})

{phang} - {bf:[95% Conf. Interval]} 95% confidence interval for the coefficient (Available with {cmd:e(ub_vcevarname)} and {cmd:e(lb_vcevarname)})

{title:Syntax for GMM Estimator}

{phang} {cmd:aivreg gmm} {it:depvar} {it:varlist} [{cmd:if}] [{cmd:in}], 
{cmd:aiv}({it:varlist}) [{cmd:weight}({it:string})] [{cmd:control}({it:varlist})] [{cmd:fe}({it:varlist})] 
[{cmd:vce}({it:string})] [{cmd:reps}({it:string})] [{cmd:eststo}({it:string})] [{cmd:cluster}({it:varlist})]
[{cmd:savefirst}] [{cmd:steps}({it:string})] [{cmd:conv_ptol}({it:string})] [{cmd:conv_vtol}({it:string})] 
[{cmd:igmmiterate}({it:string})] [{cmd:igmmeps}({it:string})] [{cmd:igmmweps}({it:string})]
[{cmd:technique}({it:string})] [{cmd:conv_maxiter}({it:string})] [{cmd:tracelevel}({it:string})]

{title:Input List (GMM Version)}

{phang} - {bf:estimator} specify "gmm" for GMM estimation; otherwise leave blank

{phang} - {bf:depvar} the outcome variable

{phang} - {bf:varlist} the list of endogenous regressors or amenities

{phang} - {bf:aiv} a list of one or more anti-IV variables (multiple allowed)

{phang} - {bf:control} specify the list of exogenous control variables

{phang} - {bf:weight} specifies weighting options

{phang} - {bf:eststo} specifies the model name to store the estimates under

{phang} - {bf:vce} specify standard error estimation: asymp (default), boot, or cluster(varname)

{phang} - {bf:reps} number of repetitions (for bootstrap only)

{phang} - {bf:cluster} cluster variables for standard errors

{phang} - {bf:savefirst} saves the first stage residual specification

{phang} - {bf:steps} specify GMM steps (onestep, twostep, or iterated)

{phang} - {bf:conv_ptol} parameter convergence tolerance

{phang} - {bf:conv_vtol} objective function convergence tolerance

{phang} - {bf:igmmiterate} number of iterations for IGMM

{phang} - {bf:igmmeps} parameter tolerance for IGMM

{phang} - {bf:igmmweps} weighting matrix tolerance for IGMM

{phang} - {bf:technique} optimization technique (e.g., nr, bfgs)

{phang} - {bf:conv_maxiter} maximum number of iterations allowed

{phang} - {bf:tracelevel} controls verbosity during estimation

{title:Return List (GMM Version)}

{phang} See Stata’s {browse "https://www.stata.com/manuals13/rgmm.pdf":gmm manual} for full list of returned results.

{title:References}

{phang} - Bell, A. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":Job Amenities and Earnings Inequality} (2022).

{phang} - Bell, A., Calder-Wang, S., & Zhong, S. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4565093":Pricing Neighborhood Amenities: A Proxy-Based Approach} (2023).

{phang} - Bell, A., Billings, S. B., Calder-Wang, S., & Zhong, S. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974":An Anti-IV Approach for Pricing Residential Amenities} (2024).

{phang} - Correia, S. {browse "https://ideas.repec.org/c/boc/bocode/s458530.html":IVREGHDFE: Stata module for extended instrumental variable regressions} (2018).

