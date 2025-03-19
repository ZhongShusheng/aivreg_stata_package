
# ReadMe File for aivreg Stata Package
The Stata **aivreg** command implements the anti-IV method developed in [Bell, Billings, Calder-Wang, and Zhong (2024)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974) and [Bell (2022)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522).

## Installation
- Download **aivreg.ado** and **aivreg.sthlp** from this repository
- In Stata, type in _sysdir_, find the directory listed as _PERSONAL_
- Put **aivreg.ado** and **aivreg.sthlp** in the _PERSONAL_ directory

## Syntax
 **aivreg** depvar varlist [if] [in], aiv(varlist) [control(string)] [fe(varlist)] [weight(string)] [eststo(string)] [vce(string)] [reps(string)] [seed(string)] [cluster(varlist)] [savefirst] [firststo(string)] [displayaiv]

## Input List
 - **depvar** the outcome variable 
 - **varlist** the list of amenities 
 - **aiv** a list of anti-IV variables, previously h (currently aivreg only supports one anti-IV variable) 
 - **control** specify the list of control variables
 - **fe** list of fixed effects to be absorbed; if used, ivreghdfe or reghdfe is called instead of ivreg2 or reg
 - **weight** specifies weighting options; if specified, you should include the full weighting statement, e.g.: weight([w=wt]) 
 - **eststo** specifies the model name to store the estimates under
 - **vce** specify standard error estimation: Anderson-Rubin is the default; boot computes bootstrapped SE; asymp uses the SE of ivreg2 or ivreghdfe
 - **reps** number of repetitions (for bootstrap only)
 - **seed** seed for bootstrap (for bootstrap only)
 - **cluster** cluster variables for standard errors
 - **savefirst** when set to savefirst, the first stage regression is reported; this is also saved in eststo as \_ivreg2\_`h'
 - **firststo** stores the name of the first stage estimates; automatically reports first stage
 - **displayaiv** displays the coefficient on the predicted value of the anti-instrumental variable; unavailable when using Anderson-Rubin confidence intervals

## Return List
 - **Partial F** Partial F-Stat at the first stage comparing with and without the depvar as a control. (Available with "e(Partial_F)")
 - **Coef.** Coefficient for the amenity "var". (Available with "e(beta_varname)")
 - **Std. Err.** Standard error of the coefficient (in Anderson-Rubin case, this is approximated from the confidence interval) (Available with "e(SE\__vcevarname)")
 - **t** t-statistic estimate of the coefficient (Available with "e(t\_val_varname)")
 - **P>|t|** p value based on the t-statistic (Available with "e(p\__varname)")
 - **[95% Conf. Interval]** 95% confidence interval for the coefficient (Available with "e(ub\__vcevarname)" and "e(lb\__vcevarname)")

## Examples
### Example 1: Job Safety
- Exercepted from [Bell (2022)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522)
- Import accompanying labor market data. Wage is the outcome variable, safety is the amenity to be priced, and AFQT score is the anti-IV variable of choice.
```text
. use safety_aivreg_example.dta, clear
```
- Naive hedonic regression
```text
. reg wage safety

      Source |       SS           df       MS      Number of obs   =     3,971
-------------+----------------------------------   F(1, 3969)      =     38.01
       Model |   58.098609         1   58.098609   Prob > F        =    0.0000
    Residual |  6066.92616     3,969  1.52857802   R-squared       =    0.0095
-------------+----------------------------------   Adj R-squared   =    0.0092
       Total |  6125.02477     3,970   1.5428274   Root MSE        =    1.2364

------------------------------------------------------------------------------
        wage | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
      safety |   .1257863    .020403     6.17   0.000     .0857849    .1657877
       _cons |   .1858175   .0196564     9.45   0.000     .1472798    .2243552
------------------------------------------------------------------------------

```
- Hedonic regression with AFQT as control
```text
. reg wage safety afqt_1_1981

      Source |       SS           df       MS      Number of obs   =     3,971
-------------+----------------------------------   F(2, 3968)      =    157.55
       Model |  450.608187         2  225.304094   Prob > F        =    0.0000
    Residual |  5674.41659     3,968   1.4300445   R-squared       =    0.0736
-------------+----------------------------------   Adj R-squared   =    0.0731
       Total |  6125.02477     3,970   1.5428274   Root MSE        =    1.1958

------------------------------------------------------------------------------
        wage | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
      safety |   .0435653   .0203489     2.14   0.032       .00367    .0834607
 afqt_1_1981 |   .0114346   .0006902    16.57   0.000     .0100814    .0127877
       _cons |  -.3182425    .035877    -8.87   0.000    -.3885815   -.2479035
------------------------------------------------------------------------------
```
- Apply the Anti-IV method using AFQT as anti-IV with the command, storing the estimated results as model1.
 ```text
. aivreg wage safety, aiv(afqt_1_1981) eststo(model1)
 
Anti-IV Regression                             Number of obs = 3971
Uses Anderson-Rubin CI                       Partial F-stat. = 341
SE inferred from radius closest to zero

wage   |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
-------+------------------------------------------------------------------
safety |  -1.145084    .110262  -10.38512  6.03e-25   -1.379237  -.9470102
--------------------------------------------------------------------------
(result model1 is active now)

 ```

### Example 2: Housing Amenities
- Excerpted from [Bell, Calder-Wang, and Zhong (2023)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4565093)
- Import accompanying housing market data. Log House Price Index(log_hpvi) is the outcome variables, crime_rate and medianaqi (Air Quality Index, higher means worse air) are the amenities to be priced, and rank (Geographic PageRank from migra w) is the anti-IV variable of choice.
```text
. use housing_aivreg_example, clear
```
- Single-amenity hedonic regression with geographic PageRank as controls to price air quality
```text
. reg log_hpvi medianaqi rank i.rooms if year==2019

      Source |       SS           df       MS      Number of obs   =    14,095
-------------+----------------------------------   F(6, 14088)     =   1581.71
       Model |  2446.93861         6  407.823102   Prob > F        =    0.0000
    Residual |  3632.39585    14,088  .257836162   R-squared       =    0.4025
-------------+----------------------------------   Adj R-squared   =    0.4022
       Total |  6079.33447    14,094  .431342023   Root MSE        =    .50778

------------------------------------------------------------------------------
    log_hpvi | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
   medianaqi |  -.0179744   .0046326    -3.88   0.000    -.0270548   -.0088939
        rank |   .1726248   .0044821    38.51   0.000     .1638394    .1814103
             |
       rooms |
          2  |   .1426972   .0136676    10.44   0.000      .115907    .1694874
          3  |   .5262077   .0136504    38.55   0.000     .4994511    .5529642
          4  |   .8092507   .0136549    59.26   0.000     .7824852    .8360162
          5  |   1.015283   .0137094    74.06   0.000     .9884108    1.042155
             |
       _cons |   11.40268   .0098292  1160.08   0.000     11.38341    11.42194
------------------------------------------------------------------------------
```
- Pricing a single housing amenity, air quality, using the aivreg command, with geographic PageRank as aivreg, controlling for room fixed effects; storing the estimates as model2
```text
. aivreg log_hpvi medianaqi if year==2019, aiv(rank) control(i.rooms) eststo(model2)
 
Anti-IV Regression                             Number of obs = 14095
Uses Anderson-Rubin CI                       Partial F-stat. = 1483
SE inferred from radius closest to zero

log_hpvi  |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
----------+------------------------------------------------------------------
medianaqi |  -.5250496   .0204574  -25.66557  5.1e-142   -.5666013  -.4864084
-----------------------------------------------------------------------------
(result model2 is active now)
```
- Simultaneously pricing multiple housing amenities, air quality and crime_rate, using the aivreg command, with geographic PageRank as anti-IV, controlling for room fixed effects
```text
. aivreg log_hpvi medianaqi crime_rate if year==2019, aiv(rank) fe(rooms)
 
Anti-IV Regression                             Number of obs = 14067
Uses Anderson-Rubin CI                       Partial F-stat. = 1269
SE inferred from radius closest to zero

log_hpvi   |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
-----------+------------------------------------------------------------------
medianaqi  |   -.535451   .0221685  -24.15374  2.5e-126   -.5806173  -.4937169
crime_rate |  -.6242351   .0277523  -22.49308  4.2e-110   -.6807541   -.571965
------------------------------------------------------------------------------
```
- Export the aivreg results using esttab
```text
. esttab model1 model2, mgroup("aivreg results" "aivreg results", pattern(1 1)) modelwidth(25) varwidth(20) label

------------------------------------------------------------------------------
                                aivreg results               aivreg results   
                                           (1)                          (2)   
                                          wage       Log Zillow Price Index   
------------------------------------------------------------------------------
safety                                  -1.145***                             
                                      (-10.39)                                

Median AQI                                                           -0.525***
                                                                   (-25.67)   
------------------------------------------------------------------------------
Observations                              3971                        14095   
------------------------------------------------------------------------------
t statistics in parentheses
* p<0.05, ** p<0.01, *** p<0.001
```


## Reference
-  Bell, Alex, [Job Amenities and Earnings Inequality](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522) (July 26, 2022). Available at SSRN: https://ssrn.com/abstract=4173522 or http://dx.doi.org/10.2139/ssrn.4173522
-  Bell, Alex, Sophie Calder-Wang, and Shusheng Zhong, [Pricing Neighborhood Amenities: A Proxy-Based Approach](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4565093). Mimeo, 2023.
-  Bell, Alex, Stephen B. Billings, Sophie Calder-Wang, and Shusheng Zhong, [An Anti-IV Approach for Pricing Residential Amenities: Applications to Flood Risk](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974). Mimeo, 2024.
-  Correia, Sergio, IVREGHDFE: Stata module for extended instrumental variable regressions with multiple levels of fixed effects. Mimeo, 2018






