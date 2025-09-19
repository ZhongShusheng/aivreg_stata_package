aivnonpar - Nonparametric Anti-IV Estimation in Stata

The Stata aivnonpar command implements a nonparametric approach to Anti-IV estimation.

Syntax:

aivnonpar varlist [if] [in], aiv(varlist) [control(varlist)] [fe(varlist)] [nbincontrol(string)] [equalbinwidthscontrol] [heatplot] [equalbinwidths] [equalbinwidthsx] [equalbinwidthsy] [nbin(string)] [nbinx(string)] [nbiny(string)] [firstheatplot] [ncolors(string)] [firstcontourplot] [asdata(string)] [firstdata(string)] [saveheatplot(string)] [savefirstheatplot(string)] [savefirstcontourplot(string)] [contourplot] [savecontourplot(string)] [xcategoryorder(string)] [contourplottitle(string)] [firstcontourplottitle(string)] [heatplottitle(string)] [firstheatplottitle(string)] [xtitle(string)] [ytitle(string)] [plotquantiles(string)] [scolor(string)] [ecolor(string)] [binmedians] [ccolors(string)] [estimatesequal(string)] [firstestimatesequal(string)] [firstestimatesequaltitle(string)] [estimatesequaltitle(string)] [savefirstestimatesequal(string)] [saveestimatesequal(string)] [critvalue(string)] [weight(varlist)]

Options:

aiv(varlist) - Anti-IV variable.

control(varlist) - Control variables for conditional estimation.

fe(varlist) - Add fixed effects (categorical controls).

nbincontrol(string) - Number of bins for the control variables.

equalbinwidthscontrol - Use equal bin widths for controls.

heatplot - Generate a heatmap visualization of the second stage results (dependent variable on explanatory variable). If binned by quantile, the blocks are centered on the larger bin number; if equalwinwidths is used, the center of the interval is used.

equalbinwidths - Use equal bin widths for discretization.

equalbinwidthsx - Use equal bin widths for the x variable.

equalbinwidthsy - Use equal bin widths for the y variable.

nbin(string) - Number of bins for both x and y variables.

nbinx(string) - Number of bins for the x variable.

nbiny(string) - Number of bins for the y variable.

firstheatplot - Generate a heatmap of the first stage, i.e., predicted values of the Anti-IV. If binned by quantile, the blocks are centered on the bin number; if equalwinwidths is used, the center of the interval is used.

ncolors(string) - Number of colors for heatplot visualization.

firstcontourplot - Show contour lines of the first stage estimation (predicted values of the Anti-IV).

asdata(string) - Save second stage output data to a specified filename.

firstdata(string) - Save first stage output data to a specified filename.

saveheatplot(string) - Save the second stage heatplot graph to a file.

savefirstheatplot(string) - Save the first stage heatplot to a file.

savefirstcontourplot(string) - Save the first stage contour plot to a file.

contourplot - Show contour plot of second stage estimation.

savecontourplot(string) - Save the second stage contour plot to a file.

xcategoryorder(string) - Order of x categories for categorical variables.

contourplottitle(string) - Title for the second stage contour plot.

firstcontourplottitle(string) - Title for the first stage contour plot.

heatplottitle(string) - Title for the second stage heatplot.

firstheatplottitle(string) - Title for the first stage heatplot.

xtitle(string) - Custom x-axis title.

ytitle(string) - Custom y-axis title.

plotquantiles(string) - Plots have colors represent quantile bins. Takes a number, for the number of bins. 

scolor(string) - The starting color of the plot scales. Does not work on heatplots or "is equal" plots; specify ccolors instead. 

ecolor(string) - The ending color of the plot scales. Does not work on heatplots or "is equal" plots; specify ccolors instead. 

binmedians(string) - Uses bin medians instead of means throughout the estimator.

ccolors(string) - Custom color for each interval of plots.

estimatesequal(string) - Makes a plot where dark gray bins have a second stage estimate with a confidence interval containing the user inputted value. 

firstestimatesequal(string) - Makes a plot where dark gray bins have a first stage estimate with a confidence interval containing the user inputted value.  

firstestimatesequaltitle(string) - Title of firstestimatesequal plot. 

estimatesequaltitle(string) - Title of estimatesequal plot. 

savefirstestimatesequal(string) - Save firstestimatesequal plot to pathway.  

saveestimatesequal(string) - Save estimatesequal plot to pathway. 

critvalue(string) - Custom critical value; defaults to 1.96.

weight(varlist) - User specified probability weights.

Returned Results:

depvar_bins: Bin cutoff values of the dependent variable.

expvar_bins: Bin cutoff values of the explanatory variable.

depvar_on_expvar_result: Final estimated result matrix.

freq_mat: Observation frequency matrix.

expvar_means: Mean values of the explanatory variable.

depvar_means: Mean values of the dependent variable.

aiv_means: Mean values of the Anti-IV variable (first stage estimation).

ub_result: Upper bound of Anderson-Rubin confidence interval on second stage estimates. 

ub_result: Upper bound of Anderson-Rubin confidence interval on second stage estimates. 

se_mat: Standard errors in first stage estimation.

Examples:

Example 1: Basic Usage

. aivnonpar wage safety, aiv(afqt) nbinx(5) nbiny(4) heatplot

```text

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


```

Example 2: Saving Results

. aivnonpar log_hpvi crime_rate, aiv(rank) asdata(results.dta) saveheatplot(heatmap.png)

```text

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

```

## Contact
-  Questions or concerns can be sent to aivregstata@gmail.com

References:

- Bell, A., Billings, S. B., Calder-Wang, S., & Zhong, S. An Anti-IV Approach for Pricing Residential Amenities (2024). SSRN: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974

- Bell, A. Job Amenities and Earnings Inequality (2022). SSRN: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522

- Correia, S. IVREGHDFE: Stata module for extended instrumental variable regressions (2018). RePEc: https://ideas.repec.org/c/boc/bocode/s458530.html

