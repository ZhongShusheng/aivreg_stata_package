{smcl}
{title:aivnonpar - Nonparametric Anti-IV Estimation in Stata}

{pstd}
The Stata {bf:aivnonpar} command implements a nonparametric approach to Anti-IV estimation.

{title:Syntax}

{pstd}
{cmd:aivnonpar} {it:varlist} [{cmd:if}] [{cmd:in}], {cmd:aiv}({it:varlist}) [{cmd:control}({it:varlist})] [{cmd:fe}({cmd:varlist})] [{cmd:nbincontrol}({it:string})] [{cmd:equalbinwidthscontrol}] [{cmd:heatplot}] [{cmd:equalbinwidths}] [{cmd:equalbinwidthsx}] [{cmd:equalbinwidthsy}] [{cmd:nbin}({it:string})] [{cmd:nbinx}({it:string})] [{cmd:nbiny}({it:string})] [{cmd:firstheatplot}] [{cmd:ncolors}({it:string})] [{cmd:firstcontourplot}] [{cmd:asdata}({it:string})] [{cmd:firstdata}({it:string})] [{cmd:saveheatplot}({it:string})] [{cmd:savefirstheatplot}({it:string})] [{cmd:savefirstcontourplot}({it:string})] [{cmd:contourplot}] [{cmd:savecontourplot}({it:string})] [{cmd:xcategoryorder}({it:string})] [{cmd:contourplottitle}({it:string})] [{cmd:firstcontourplottitle}({it:string})] [{cmd:heatplottitle}({it:string})] [{cmd:firstheatplottitle}({it:string})] [{cmd:xtitle}({it:string})] [{cmd:ytitle}({it:string})] [{cmd:plotquantiles}({it:string})] [{cmd:scolor}({it:string})] [{cmd:ecolor}({it:string})] [{cmd:binmedians}] [{cmd:ccolors}({it:string})] [{cmd:estimatesequal}({it:string})] [{cmd:firstestimatesequal}({it:string})] [{cmd:firstestimatesequaltitle}({it:string})] [{cmd:estimatesequaltitle}({it:string})] [{cmd:savefirstestimatesequal}({it:string})] [saveestimatesequal(string)] [critvalue(string)] [weight(varlist)]

{title:Options}

{phang} {cmd:aiv}({it:varlist}) - Anti-IV variable.

{phang} {cmd:control}({it:varlist}) - Control variables for conditional estimation.

{phang} {cmd:fe}({it:varlist}) - Add fixed effects (categorical controls).

{phang} {cmd:nbincontrols}({it:string}) - Number of bins for the control variables.

{phang} {cmd:equalbinwidthscontrols} - Use equal bin widths for controls.

{phang} {cmd:heatplot} - Generate a heatmap visualization of the second stage results (dependent variable on explanatory variable). If binned by quantile, the blocks are centered on the larger bin number; if equalwinwidths is used, the center of the interval is used.

{phang} {cmd:equalbinwidths} - Use equal bin widths for discretization.

{phang} {cmd:equalbinwidthsx} - Use equal bin widths for the x variable.

{phang} {cmd:equalbinwidthsy} - Use equal bin widths for the y variable.

{phang} {cmd:nbin}({it:string}) - Number of bins for both x and y variables.

{phang} {cmd:nbinx}({it:string}) - Number of bins for the x variable.

{phang} {cmd:nbiny}({it:string}) - Number of bins for the y variable.

{phang} {cmd:firstheatplot} - Generate a heatmap of the first stage, i.e., predicted values of the Anti-IV. If binned by quantile, the blocks are centered on the bin number; if equalwinwidths is used, the center of the interval is used.

{phang} {cmd:ncolors}({it:string}) - Number of colors for heatplot visualization.

{phang} {cmd:firstcontourplot} - Show contour lines of the first stage estimation (predicted values of the Anti-IV).

{phang} {cmd:asdata}({it:string}) - Save second stage output data to a specified filename.

{phang} {cmd:firstdata}({it:string}) - Save first stage output data to a specified filename.

{phang} {cmd:saveheatplot}({it:string}) - Save the second stage heatplot graph to a file.

{phang} {cmd:savefirstheatplot}({it:string}) - Save the first stage heatplot to a file.

{phang} {cmd:savefirstcontourplot}({it:string}) - Save the first stage contour plot to a file.

{phang} {cmd:contourplot} - Show contour plot of second stage estimation.

{phang} {cmd:savecontourplot}({it:string}) - Save the second stage contour plot to a file.

{phang} {cmd:xcategoryorder}({it:string}) - Order of x categories for categorical variables.

{phang} {cmd:contourplottitle}({it:string}) - Title for the second stage contour plot.

{phang} {cmd:firstcontourplottitle}({it:string}) - Title for the first stage contour plot.

{phang} {cmd:heatplottitle}({it:string}) - Title for the second stage heatplot.

{phang} {cmd:firstheatplottitle}({it:string}) - Title for the first stage heatplot.

{phang} {cmd:xtitle}({it:string}) - Custom x-axis title.

{phang} {cmd:ytitle}({it:string}) - Custom y-axis title.

{phang} -  {bf:plotquantiles}: Plots have colors represent quantile bins. Takes a number, for the number of bins. 

{phang} - {bf:scolor}: The starting color of the plot scales. Does not work on heatplots or "is equal" plots; specify ccolors instead.  

{phang} - {bf:ecolor}: The ending color of the plot scales. Does not work on heatplots or "is equal" plots; specify ccolors instead. 

{phang} - {bf:binmedians}: Uses bin medians instead of means throughout the estimator.

{phang} - {bf:ccolors}({it:string}): Custom color for each interval of plots. 

{phang} - {bf:estimatesequal}({it:string}) - Makes a plot where dark gray bins have a second stage estimate with a confidence interval containing the user inputted value. 

{phang} - {bf:firstestimatesequal}({it:string}) - Makes a plot where dark gray bins have a first stage estimate with a confidence interval containing the user inputted value.  

{phang} - {bf:firstestimatesequaltitle}({it:string}) - Title of firstestimatesequal plot. 

{phang} - {bf:estimatesequaltitle}({it:string}) - Title of estimatesequal plot. 

{phang} - {bf:savefirstestimatesequal}({it:string}) - Save firstestimatesequal plot to pathway.  

{phang} - {bf:saveestimatesequal}({it:string}) - Save estimatesequal plot to pathway. 

{phang} - {bf:critvalue}({it:string}) - Custom critical value; defaults to 1.96.

{phang} - {bf:weight}({it:varlist}) - User specified probability weights.

{title:Returned Results}

{phang} - {bf:depvar_bins}: Bin cutoff values of the dependent variable.

{phang} - {bf:expvar_bins}: Bin cutoff values of the explanatory variable.

{phang} - {bf:depvar_on_expvar_result}: Final estimated result matrix.

{phang} - {bf:freq_mat}: Observation frequency matrix.

{phang} - {bf:expvar_means}: Mean values of the explanatory variable.

{phang} - {bf:depvar_means}: Mean values of the dependent variable.

{phang} - {bf:aiv_means}: Mean values of the Anti-IV variable (first stage estimation).

{phang} - {bf:ub_result}: Upper bound of Anderson-Rubin confidence interval on second stage estimates. 

{phang} - {bf:ub_result}: Upper bound of Anderson-Rubin confidence interval on second stage estimates. 

{phang} - {bf:se_mat}: Standard errors in first stage estimation.

{title:Examples}

{pstd} {bf:Example 1: Basic Usage}

{cmd:. aivnonpar wage safety, aiv(afqt) nbinx(5) nbiny(4) heatplot}

wage_bins[1,3]
            c1          c2          c3
r1  -.37990876  -.15426877     .244518

safety_bins[1,4]
            c1          c2          c3          c4
r1  -.53724879   .27097142   .61889076   .77790755

wage_on_safety_result[3,4]
            2           3           4           5
2  -.04381579  -.35488216  -.42679604   141.08258
3  -.07350824  -.29080661  -.87917134  -.81696434
4  -.74684152  -.54111319   -3.463303  -2.1066547

lb_result[3,4]
            2           3           4           5
2  -.10570986   -.5821146  -1.1102179           .
3  -.14819393           .  -6.2666521  -3.4530516
4  -1.2371179  -2.1928702  -5.6045432  -6.0161284

ub_result[3,4]
            2           3           4           5
2   .04992658  -.17278046   .25436744           .
3   .01222432           .   .72764671   4.8001919
4  -.40959248   1.8586739  -1.4650159   2.4659852

freq_mat[4,5]
     1    2    3    4    5
1  248  253  231  117  147
2  228  223  190  185  165
3  215  221  162  217  178
4  105  158  162  275  291

afqt_1_1981_means[4,5]
           1          2          3          4          5
1  25.020161  24.782609  30.441558  37.051282  45.095238
2  30.662281  33.273543  41.831579  45.702703  45.109091
3  40.218605  44.642534  47.283951   51.16129  52.646067
4   44.87619  56.879747  58.592593  66.421818  68.381443

{pstd} {bf:Example 2: Saving Results}

{cmd:. aivnonpar log_hpvi crime_rate, aiv(rank) asdata(results.dta) saveheatplot(heatmap.png)}

log_hpvi_bins[1,4]
           c1         c2         c3         c4
r1  11.260696  11.643053  11.962287  12.335924

crime_rate_bins[1,4]
            c1          c2          c3          c4
r1  -.73004055  -.33483812   .05671585   .64029443

log_hpvi_on_crime_rate_result[4,4]
            2           3           4           5
2  -1.5892174  -1.5611283   -1.013437  -.89986228
3  -1.0837365  -1.5438806  -1.4480192  -.99566947
4  -1.5114773  -1.3126416   -.5658329   -3.165494
5  -1.3642071  -1.4106229  -.34105511  -.60467342

lb_result[4,4]
            2           3           4           5
2  -3.4536569  -1.9930369  -1.3135554   -1.290304
3  -1.6984894  -3.4322563   5.7997537  -4.4692929
4  -2.8591896  -1.9679795  -1.0007471   1.2668259
5  -1.6109896   -1.717168  -.64119483  -.73788477

ub_result[4,4]
            2           3           4           5
2  -1.0509917  -1.2491649  -.71486818  -.71069313
3  -.80761087  -1.0584572  -.68720706  -.61720436
4  -1.0782613  -1.0012952  -.21210714  -.87081629
5  -1.1396148  -1.1239677   .05286363  -.50358746

freq_mat[5,5]
      1     2     3     4     5
1  1421  1006   832   931  1097
2  1305  1110  1000   942   930
3  1096  1135  1054  1017   984
4   885  1033  1129  1167  1073
5   583  1004  1268  1233  1198

rank_means[5,5]
            1           2           3           4           5
1  -.35304618  -.31293499  -.27800899  -.21589692   .06856448
2  -.33064934  -.28427277  -.19299706  -.07875444   .32151627
3  -.31522548  -.23758397  -.12723571  -.02894096   .49015101
4   -.2903377  -.18800823  -.00173777   .09329861   .53677118
5  -.18434342   .05928874   .36947023   .46497928   1.2101031


{title:Contact}

{phang} - Questions or concerns can be sent to aivregstata@gmail.com


{title:References}

{phang} - Bell, A., Billings, S. B., Calder-Wang, S., & Zhong, S. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974":An Anti-IV Approach for Pricing Residential Amenities} (2024).

{phang} - Bell, A. {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522":Job Amenities and Earnings Inequality} (2022).

{phang} - Correia, S. {browse "https://ideas.repec.org/c/boc/bocode/s458530.html":IVREGHDFE: Stata module for extended instrumental variable regressions} (2018).
