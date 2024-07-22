{smcl}
{* *! version 1.0 16 Jul 2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "aivreg##syntax"}{...}
{viewerjumpto "Description" "aivreg##description"}{...}
{viewerjumpto "Options" "aivreg##options"}{...}
{viewerjumpto "Remarks" "aivreg##remarks"}{...}
{viewerjumpto "Examples" "aivreg##examples"}{...}
{title:Title}
{phang}
{bf:aivreg} {hline 2} Implements the Anti-IV method as used in {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":{it:Bell (2022)}}, {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4565093":{it:Bell, Calder-Wang, and Zhong (2023)}}, and {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974":{it:Bell et.al (2024)}}.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:aivreg}
varlist
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required }
{synopt:{opt h(varlist)}} Specify the anti-IV variable to be used; {cmd:aivreg} command currently ony supports one anti-IV variable {p_end}
{syntab:Optional }
{synopt:{opt control(strings)}} Specify the control variables to be added to the baseline regression {p_end}
{synopt:{opt fe(strings)}} Specify the fixed effects to be absorbed {p_end}
{synopt:{opt weight(strings)}} Specify the weighting options {p_end}
{synopt:{opt eststo(strings)}} Specify the model name to store estimates as; uses standard error from {cmdab:ivreghdfe} as the default standard error {p_end}


{marker examples}{...}
{title:Example 1: Job Safety}

{pstd} Exercepted from {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":{it:Bell (2022)}}. {p_end}

{pstd}Import accompanying labor market data. Wage is the outcome variable, safety is the amenity to be priced, and AFQT score is the anti-IV variable of choice. {p_end}
{phang2}{cmd:. use safety_aivreg_example, clear}

{pstd}Naive hedonic regression{p_end}
{phang2}{cmd:. reg wage safety}

{pstd}Hedonic regression with AFQT as control{p_end}
{phang2}{cmd:. reg wage safety afqt_1_1981}

{pstd}Apply the Anti-IV method using AFQT as anti-IV with the {cmd: aivreg} command, storing the estimated results as model1. {p_end}
{phang2}{cmd:. aivreg wage safety, h(afqt_1_1981) eststo(model1)}


{title:Example 2: Housing Amenities}

{pstd} Exercepted from {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4565093":{it:Bell, Calder-Wang, and Zhong (2023)}}. {p_end}

{pstd}Import accompanying housing market data. Log House Price Index(log_hpvi) is the outcome variables, crime_rate and medianaqi (Air Quality Index, higher means worse air) are the amenities to be priced, and rank (Geographic PageRank from migration flow) is the anti-IV variable of choice. {p_end}
{phang2}{cmd:. use housing_aivreg_example, clear}

{pstd} Single-amenity hedonic regression with geographic PageRank as controls to price air quality{p_end}
{phang2}{cmd:. reg log_hpvi medianaqi rank i.rooms if year==2019}

{pstd} Pricing a single housing amenity, air quality, using the {cmd: aivreg} command, with geographic PageRank as anti-IV, controlling for number of rooms as a categorical variable. Store the estimated results as model 2. {p_end}
{phang2}{cmd:. aivreg log_hpvi medianaqi if year==2019, h(rank) control(i.rooms) eststo(model2)}

{pstd} Simultaneously pricing multiple housing amenities, air quality and crime_rate, using the {cmd: aivreg} command, with geographic PageRank as anti-IV, controlling for room fixed effects. {p_end}
{phang2}{cmd:. aivreg log_hpvi medianaqi crime_rate if year==2019, h(rank) fe(rooms)}


{title:Stored results}

{pstd}
{cmd:aivreg} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(partial_F)}} Partial F-Stats on the anti-IV variable in the baseline regression{p_end}
{synopt:{cmd:r(beta`z')}} Estimated cofficient for the amenity "z" {p_end}
{synopt:{cmd:r(lb_AR)}} Anderson-Rubin confidence interval lower bound for the amenity "z" {p_end}
{synopt:{cmd:r(ub_AR)}} Anderson-Rubin confidence interval upper bound for the amenity "z" {p_end}


{marker references}{...}
{title:References}

{marker Bell2022}{...}
{phang}
Bell, Alex, 
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":{it:Job Amenities and Earnings Inequality}.}
Mimeo, 2022

{marker Bell2023}{...}
{phang}
Bell, Alex, Sophie Calder-Wang, and Shusheng Zhong,
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4565093":{it:Pricing Neighborhood Amenities: A Proxy-Based Approach}.}
Mimeo, 2023
{p_end}

{marker Bell2024}{...}
{phang}
Bell, Alex, Stephen B. Billings, Sophie Calder-Wang, and Shusheng Zhong,
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974":{it:An Anti-IV Approach for Pricing Residential Amenities: Applications to Flood Risk}.}
Mimeo, 2024
{p_end}

{marker Correia2018}{...}
{phang}
Correia, Sergio. {it:IVREGHDFE: Stata module for extended instrumental variable regressions with multiple levels of fixed effects.}
Mimeo, 2018
{p_end}






