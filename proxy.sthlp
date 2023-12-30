{smcl}
{* *! version 1.0 30 Dec 2023}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "proxy##syntax"}{...}
{viewerjumpto "Description" "proxy##description"}{...}
{viewerjumpto "Options" "proxy##options"}{...}
{viewerjumpto "Remarks" "proxy##remarks"}{...}
{viewerjumpto "Examples" "proxy##examples"}{...}
{title:Title}
{phang}
{bf:proxy} {hline 2} Implements the proxy method as used in Bell (2022) and Bell, Calder-Wang, Zhong(2023).

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:proxy}
depvar varlist
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required }
{synopt:{opt h(varlist)}} Specify the proxy variable to be used; {cmd:proxy} command currently ony supports one proxy variable {p_end}
{syntab:Optional }
{synopt:{opt control(strings)}} Specify the control variables to be added to the baseline regression; can be fixed effects {p_end}
{synopt:{opt weight(strings)}} Specify the weighting options {p_end}


{marker examples}{...}
{title:Example 1: Job Safety}

{pstd} Exercepted from {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":{it:Bell (2022)}}. {p_end}

{pstd}Import accompanying labor market data. Wage is the outcome variable, safety is the amenity to be priced, and AFQT score is the proxy variable of choice. {p_end}
{phang2}{cmd:. use safety_proxy_example, clear}

{pstd}Naive hedonic regression{p_end}
{phang2}{cmd:. reg wage safety}

{pstd}Hedonic regression with AFQT as control{p_end}
{phang2}{cmd:. reg wage safety afqt_1_1981}

{pstd}Proxy method using AFQT as proxy{p_end}
{phang2}{cmd:. proxy wage safety, h(afqt_1_1981)}


{title:Example 2: Housing Amenities}

{pstd} Exercepted from {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4565093":{it:Bell, Calder-Wang, and Zhong (2023)}}. {p_end}

{pstd}Import accompanying housing market data. Log House Price Index(log_hpvi) is the outcome variables, crime_rate and medianaqi (Air Quality Index, higher means worse air) are the amenities to be priced, and rank (Geographic PageRank from migration flow) is the proxy variable of choice. {p_end}
{phang2}{cmd:. use housing_proxy_example, clear}

{pstd} Single-amenity hedonic regression with geographic PageRank as controls to price air quality{p_end}
{phang2}{cmd:. reg log_hpvi medianaqi rank i.rooms if year==2019}

{pstd} Pricing a single housing amenity, air quality, using the {cmd: proxy} command, with geographic PageRank as proxy, controlling for room fixed effects {p_end}
{phang2}{cmd:. proxy log_hpvi medianaqi if year==2019, h(rank) control(i.rooms)}

{pstd} Simultaneously pricing multiple housing amenities, air quality and crime_rate, using the {cmd: proxy} command, with geographic PageRank as proxy, controlling for room fixed effects {p_end}
{phang2}{cmd:. proxy log_hpvi medianaqi crime_rate if year==2019, h(rank) control(i.rooms)}


{title:Stored results}

{pstd}
{cmd:proxy} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(partial_F)}} Partial F-Stats on the proxy variable in the baseline regression{p_end}
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



