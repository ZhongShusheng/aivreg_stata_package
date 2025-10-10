# aivreg — Anti-IV Regression

## Description

aivreg  implements the anti-IV estimator outlined in [Bell, Billings, Calder-Wang, & Zhong (2024)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974). The method allows the user to estimate implicit amenity prices in the presence of an unobservable confounder. 

## Download Instructions

Go to https://github.com/ZhongShusheng/aivreg_stata_package and clone the repository (alternatively, under "Code", click "Download ZIP") to locally store a copy of the package. Place aivreg.ado and aivreg.sthlp into the same folder as the do-file in which you would like to use the command. Then stata will recognize the aivreg command. aivreg requires stata 17 or higher.

## Syntax

```stata

    aivreg [estimator] depvar varlist [if] [in], aiv(varlist) [options]

```

## Options

### Estimator

- **estimator**         defaults to the ratio-of-coefficient estimator, which allows for one anti-instrument. Other options include 2sls (two-stage least squares) and gmm (generalized method of moments), which allow for one or more anti-instruments.

### Model specification

- **aiv(varlist)**       anti-IV variables (one for the default ratio-of-coefficient estimator, one or more for 2SLS and GMM estimators).
- **control(varlist)**  specifies exogenous control variables included in both stages. These represent additional controls on which conditional orthogonality of the anti-IV and the outcome given the latent confounder holds.
- **fe(varlist)**      absorbs fixed effects. This is currently not available in 2SLS or GMM; however, 2SLS and GMM can take factor variables (use i.varname).
- **weight(...)**       allows either probability/frequency/analytic weights for the ratio-of-coefficient estimator or probability weights for GMM and 2SLS. For the ratio-of-coefficient estimator, use brackets: for example, weight([aw=wt]). For GMM and 2SLS, only place the variable to weigh by: for example, weight(varname). 
- **weightmatrix(matrix)**    estimation weight matrix (GMM only), defaults to identity matrix. Should be square and will have the same dimensions as e(S): If there are A amenities, C controls, and L anti-IVs, the number of rows = (A + C + 2)*L.

### Estimation & storage

- **eststo(name)**      stores the fitted model under name for later retrieval. aivreg is also compatible with the syntax eststo: aivreg.
- **savefirst**         reports and stores the first-stage regression. If firststo(name) is unspecified, then the first stage is named _ivreg2_varname, where varname is the anti_IV's variable name. (Not available in 2SLS or GMM.)
- **firststo(name)**    stores the first-stage estimates under name. (Not available in 2SLS or GMM.)

### Variance & inference

- **vce(type)**         specifies the variance estimator:  AR for Anderson–Rubin (default), bootstrap for bootstrap SEs, asymptotic for asymptotic SE.
- **cluster()**         provides cluster-robust SEs.
- **reps(#)**           sets the number of bootstrap repetitions. Defaults to 50.
- **seed(#)**           sets the random seed for bootstrap reproducibility. 

## Saved results

### Scalars
- **e(Partial_F)**       partial F-statistic from first stage (Not in 2SLS or GMM)
- **e(df_r)**            residual degrees of freedom  
- **e(N)**               number of observations  
- **e(Jval)**            J-test statistic (2SLS and GMM only)  
- **e(pval_J)**          p-value of J-test (2SLS and GMM only)  
- **e(betavarname)**     coefficient on variable varname 
- **e(SE_vcevarname)**   standard error of the coefficient on varname, using vce (either AR, asymp, boot, 2sls, or gmm); if AR, SE approximated using CI closest to zero 
- **e(t_valvarname)**    t-value for the coefficient on varname 
- **e(p_more_tvarname)** t-test statistic for the coefficient on varname 
- **e(lb_vcevarname)**   lower bound for the coefficient on varname (95% confidence), using vce (either AR, asymp, boot, 2sls, or gmm)
- **e(ub_vcevarname)**   upper bound for the coefficient on varname (95% confidence), using vce (either AR, asymp, boot, 2sls, or gmm) 

### Macros

- **e(cmd)**         "aivreg"

### Matrices

- **e(b)**            coefficient vector
- **e(V)**            estimated covariance matrix of coefficients; in AR, diagonal matrix with values approximated from AR CI closest to zero
- **e(S)**            covariance of moments (2SLS and GMM only)
- **e(weightmatrix)** weight matrix (2SLS and GMM only)


### Examples

The following examples use simulated or sampled data which are included with the aivreg package on github.

##### Flood Risk Example

 The underlying data in Bell, Billings, Calder-Wang and Zhong (2024) are from commercial providers; for illustrative purposes, we thus provided a small, simulated version of the data. For the underlying DGP, please see simulate_flood_risk_data.do.

 Load the simulated flood risk dataset.

```stata
    use simulated_flood_risk.dta, clear
```
```stata
    estimates clear
```

 An OLS regression with block FE is not sufficient to retrieve the implicit price of flood risk.
```stata
    eststo: reghdfe log_price i.flood_factor, absorb(block_id)
```
```
(MWFE estimator converged in 1 iterations)

HDFE Linear regression                            Number of obs   =     10,000
Absorbing 1 HDFE group                            F(   9,   9986) =     162.91
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.1281
                                                  Adj R-squared   =     0.1270
                                                  Within R-sq.    =     0.1280
                                                  Root MSE        =     0.9407

------------------------------------------------------------------------------
   log_price | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
flood_factor |
          2  |   .6293552   .0431077    14.60   0.000     .5448553     .713855
          3  |   .7919106   .0413423    19.15   0.000     .7108714    .8729498
          4  |   .7777989   .0416928    18.66   0.000     .6960727    .8595251
          5  |    .745061   .0414591    17.97   0.000     .6637927    .8263292
          6  |   .8416348   .0414787    20.29   0.000     .7603282    .9229413
          7  |   .8278283   .0416038    19.90   0.000     .7462764    .9093801
          8  |   .7850859   .0416213    18.86   0.000     .7034997    .8666721
          9  |   .9385813   .0418137    22.45   0.000     .8566181    1.020545
         10  |   1.521647   .0405364    37.54   0.000     1.442188    1.601107
             |
       _cons |   10.94794   .0289782   377.80   0.000     10.89113    11.00474
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
    block_id |         5           0           5     |
-----------------------------------------------------+
(est1 stored)
```

 If we control for the log income of the home buyers, under the intuition that it is informative for the unobserved quality, the estimates are still biased.
```stata
    eststo: reghdfe log_price i.flood_factor log_income, absorb(block_id)
```
```
(MWFE estimator converged in 1 iterations)

HDFE Linear regression                            Number of obs   =     10,000
Absorbing 1 HDFE group                            F(  10,   9985) =   16438.41
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.9427
                                                  Adj R-squared   =     0.9427
                                                  Within R-sq.    =     0.9427
                                                  Root MSE        =     0.2411

------------------------------------------------------------------------------
   log_price | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
flood_factor |
          2  |   .0520716   .0111532     4.67   0.000     .0302091    .0739341
          3  |   .0504507   .0107762     4.68   0.000     .0293272    .0715741
          4  |    .048319   .0108588     4.45   0.000     .0270336    .0696044
          5  |   .0444007   .0107864     4.12   0.000     .0232571    .0655443
          6  |   .0480453   .0108366     4.43   0.000     .0268034    .0692871
          7  |    .052156   .0108589     4.80   0.000     .0308704    .0734417
          8  |   .0509228    .010843     4.70   0.000     .0296684    .0721773
          9  |    .051741   .0109712     4.72   0.000     .0302353    .0732467
         10  |    .063046    .011086     5.69   0.000     .0413153    .0847767
             |
  log_income |   1.166668   .0030954   376.91   0.000     1.160601    1.172736
       _cons |  -.9505752   .0324305   -29.31   0.000    -1.014145    -.887005
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
    block_id |         5           0           5     |
-----------------------------------------------------+
(est2 stored)
```

 But when aivreg uses income as the anti-IV, it will correctly estimate the implicit price of flood risk.
```stata
    eststo: aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) vce(asymp)
```
```
Anti-IV Regression                             Number of obs = 10000
                                             Partial F-stat. = 1.42e+05

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor1  |          0          0          .         .           0          0
flood_factor2  |   .0114959   .0115461   .9956479  .3194454   -.0111345   .0341263
flood_factor3  |  -.0016645   .0111615  -.1491289  .8814549    -.023541    .020212
flood_factor4  |  -.0029541   .0112464   -.262671  .7928096   -.0249971   .0190889
flood_factor5  |  -.0048468   .0111707   -.433884  .6643821   -.0267414   .0170478
flood_factor6  |  -.0077339   .0112258  -.6889433  .4908749   -.0297365   .0142686
flood_factor7  |  -.0023638   .0112482  -.2101533  .8335523   -.0244104   .0196827
flood_factor8  |  -.0006795   .0112303  -.0605042  .9517553   -.0226909   .0213319
flood_factor9  |  -.0105926   .0113685  -.9317478  .3514894   -.0328749   .0116897
flood_factor10 |  -.0394751    .011518  -3.427266  .0006122   -.0620503  -.0168999
----------------------------------------------------------------------------------
(est3 stored)
```

 aivreg can also use Anderson-Rubin confidence intervals. This is particularly helpful when there is a weak anti-IV. Anderson-Rubin confidence intervals are the default of aivreg; however, one can also call them using vce(AR). In this setting, log
    income is a strong anti-IV, so the confidence interval is similar to those calculated above.

```stata
    eststo: aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) vce(AR)
```
```
Anti-IV Regression                             Number of obs = 10000
Uses Anderson-Rubin CI                       Partial F-stat. = 1.42e+05
SE inferred from radius closest to zero

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor1  |          0          0          .         .           0          0
flood_factor2  |   .0114959   .0115548   .9948996  .3198092   -.0111516   .0341099
flood_factor3  |  -.0016645   .0111507  -.1492732   .881341   -.0235628   .0201909
flood_factor4  |  -.0029541   .0112358  -.2629191  .7926184   -.0250186   .0190681
flood_factor5  |  -.0048468   .0111605  -.4342802  .6640944    -.026762   .0170278
flood_factor6  |  -.0077339   .0112142  -.6896536  .4904281   -.0297598    .014246
flood_factor7  |  -.0023638   .0112369  -.2103645  .8333875   -.0244331   .0196605
flood_factor8  |  -.0006795   .0112196  -.0605618  .9517094   -.0227124    .021311
flood_factor9  |  -.0105926   .0113556  -.9328092   .350941   -.0329009   .0116644
flood_factor10 |  -.0394751   .0114966  -3.433634   .000598   -.0620928  -.0169418
----------------------------------------------------------------------------------
(est4 stored)
```

 The option savefirst shows the first stage regression, to help judge the strength on the anti-IV.
```stata
    aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) vce(AR) savefirst
```
```
First Stage:

log_income     |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
log_price      |   .8008521   .0021248   376.9084         0    .7966875   .8050167
flood_factor1  |          0          0          .         .           0          0
flood_factor2  |  -.0092065   .0092503  -.9952713  .3196285    -.027337    .008924
flood_factor3  |    .001333    .008938     .14914  .8814462   -.0161855   .0188516
flood_factor4  |   .0023658   .0090056   .2627046  .7927837   -.0152851   .0200168
flood_factor5  |   .0038816   .0089443   .4339727  .6643176   -.0136492   .0214123
flood_factor6  |   .0061937   .0089869   .6891951  .4907165   -.0114206   .0238081
flood_factor7  |   .0018931   .0090072   .2101762  .8335345    -.015761   .0195472
flood_factor8  |   .0005442   .0089935    .060506  .9517538   -.0170832   .0181715
flood_factor9  |   .0084831   .0090995   .9322556   .351227    -.009352   .0263182
flood_factor10 |   .0316137   .0091943   3.438385  .0005876    .0135928   .0496346
----------------------------------------------------------------------------------
 
Second Stage:
 
Anti-IV Regression                             Number of obs = 10000
Uses Anderson-Rubin CI                       Partial F-stat. = 1.42e+05
SE inferred from radius closest to zero

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor1  |          0          0          .         .           0          0
flood_factor2  |   .0114959   .0115548   .9948996  .3198092   -.0111516   .0341099
flood_factor3  |  -.0016645   .0111507  -.1492732   .881341   -.0235628   .0201909
flood_factor4  |  -.0029541   .0112358  -.2629191  .7926184   -.0250186   .0190681
flood_factor5  |  -.0048468   .0111605  -.4342802  .6640944    -.026762   .0170278
flood_factor6  |  -.0077339   .0112142  -.6896536  .4904281   -.0297598    .014246
flood_factor7  |  -.0023638   .0112369  -.2103645  .8333875   -.0244331   .0196605
flood_factor8  |  -.0006795   .0112196  -.0605618  .9517094   -.0227124    .021311
flood_factor9  |  -.0105926   .0113556  -.9328092   .350941   -.0329009   .0116644
flood_factor10 |  -.0394751   .0114966  -3.433634   .000598   -.0620928  -.0169418
----------------------------------------------------------------------------------
(results _ivreg2_log_income  est5 are active now)
```

Display or export results with esttab.

```stata
    esttab est1 est2 est3 est4, mgroup("reghdfe" "reghdfe + anti-IV control" "aivreg" "aivreg + AR CI", pattern(1 1 1 1)) modelwidth(20) varwidth(18) label
```
```
------------------------------------------------------------------------------------------------------------------
                                reghdfe    reghdfe + anti-IV ~l                  aivreg          aivreg + AR CI   
                                    (1)                     (2)                     (3)                     (4)   
                         Log sale price          Log sale price          Log sale price          Log sale price   
------------------------------------------------------------------------------------------------------------------
Flood risk facto~1                    0                       0                       0                       0   
                                    (.)                     (.)                     (.)                     (.)   

Flood risk facto~2                0.629***               0.0521***               0.0115                  0.0115   
                                (14.60)                  (4.67)                  (1.00)                  (0.99)   

Flood risk facto~3                0.792***               0.0505***             -0.00166                -0.00166   
                                (19.15)                  (4.68)                 (-0.15)                 (-0.15)   

Flood risk facto~4                0.778***               0.0483***             -0.00295                -0.00295   
                                (18.66)                  (4.45)                 (-0.26)                 (-0.26)   

Flood risk facto~5                0.745***               0.0444***             -0.00485                -0.00485   
                                (17.97)                  (4.12)                 (-0.43)                 (-0.43)   

Flood risk facto~6                0.842***               0.0480***             -0.00773                -0.00773   
                                (20.29)                  (4.43)                 (-0.69)                 (-0.69)   

Flood risk facto~7                0.828***               0.0522***             -0.00236                -0.00236   
                                (19.90)                  (4.80)                 (-0.21)                 (-0.21)   

Flood risk facto~8                0.785***               0.0509***            -0.000679               -0.000679   
                                (18.86)                  (4.70)                 (-0.06)                 (-0.06)   

Flood risk facto~9                0.939***               0.0517***              -0.0106                 -0.0106   
                                (22.45)                  (4.72)                 (-0.93)                 (-0.93)   

Flood risk fact~10                1.522***               0.0630***              -0.0395***              -0.0395***
                                (37.54)                  (5.69)                 (-3.43)                 (-3.43)   

Log income                                                1.167***                                                
                                                       (376.91)                                                   

Constant                          10.95***               -0.951***                                                
                               (377.80)                (-29.31)                                                   
------------------------------------------------------------------------------------------------------------------
Observations                      10000                   10000                   10000                   10000   
------------------------------------------------------------------------------------------------------------------
t statistics in parentheses
* p<0.05, ** p<0.01, *** p<0.001
```

There is also a 2SLS version which allows for multiple anti-IV variables.

```stata
    estimates clear
```
```stata
    eststo: aivreg 2sls log_price i.flood_factor10 i.block_id, aiv(log_income)
```
```
Anti-IV GMM                                    Number of obs = 10000
                                          Number of anti-IVs = 1

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor1  |          0          0          .         .           0          0
flood_factor2  |   .0114959   .0115977   .9912254  .3215995   -.0112355   .0342273
flood_factor3  |  -.0016645   .0110646   -.150435  .8804245   -.0233511   .0200221
flood_factor4  |  -.0029541    .011381  -.2595648  .7952048   -.0252609   .0193527
flood_factor5  |  -.0048468   .0110839  -.4372826  .6619159   -.0265712   .0168776
flood_factor6  |  -.0077339   .0113206  -.6831731  .4945133   -.0299223   .0144545
flood_factor7  |  -.0023638   .0112697  -.2097524  .8338652   -.0244525   .0197248
flood_factor8  |  -.0006795   .0115935  -.0586088  .9532649   -.0234027   .0220437
flood_factor9  |  -.0105926   .0112369  -.9426623  .3458765   -.0326169   .0114317
flood_factor10 |  -.0394751   .0115892  -3.406192  .0006614   -.0621899  -.0167602
block_id1      |          0          0          .         .           0          0
block_id2      |  -.0005182   .0079797  -.0649368  .9482256   -.0161583    .015122
block_id3      |   .0039769   .0077412   .5137346  .6074489   -.0111959   .0191498
block_id4      |   .0135845   .0078902   1.721684  .0851578   -.0018804   .0290493
block_id5      |   -.003392   .0079341  -.4275205  .6690095   -.0189428   .0121589
----------------------------------------------------------------------------------
(est1 stored)
```

And this is the more general GMM version of aivreg.

```stata
    eststo: aivreg gmm log_price i.flood_factor i.block_id, aiv(log_income)
```
```
Anti-IV GMM                                    Number of obs = 10000
                                          Number of anti-IVs = 1

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor1  |          0          0          .         .           0          0
flood_factor2  |   .0114959   .0115977   .9912254  .3215995   -.0112355   .0342273
flood_factor3  |  -.0016645   .0110646   -.150435  .8804245   -.0233511   .0200221
flood_factor4  |  -.0029541    .011381  -.2595648  .7952048   -.0252609   .0193527
flood_factor5  |  -.0048468   .0110839  -.4372826  .6619159   -.0265712   .0168776
flood_factor6  |  -.0077339   .0113206  -.6831731  .4945133   -.0299223   .0144545
flood_factor7  |  -.0023638   .0112697  -.2097524  .8338652   -.0244525   .0197248
flood_factor8  |  -.0006795   .0115935  -.0586088  .9532649   -.0234027   .0220437
flood_factor9  |  -.0105926   .0112369  -.9426623  .3458765   -.0326169   .0114317
flood_factor10 |  -.0394751   .0115892  -3.406191  .0006614   -.0621899  -.0167602
block_id1      |          0          0          .         .           0          0
block_id2      |  -.0005182   .0079797  -.0649368  .9482256   -.0161583    .015122
block_id3      |   .0039769   .0077412   .5137345   .607449   -.0111959   .0191498
block_id4      |   .0135845   .0078902   1.721684  .0851578   -.0018804   .0290493
block_id5      |   -.003392   .0079341  -.4275206  .6690094   -.0189428   .0121589
----------------------------------------------------------------------------------
(est2 stored)
```

Show results in esttab.

```stata
    esttab est1 est2, keep(flood_factor*) mgroup("2sls" "GMM", pattern(1 1)) label
```
```
----------------------------------------------------
                             2sls             GMM   
                              (1)             (2)   
                     Log sale p~e    Log sale p~e   
----------------------------------------------------
flood_factor1                   0               0   
                              (.)             (.)   

flood_factor2              0.0115          0.0115   
                           (0.99)          (0.99)   

flood_factor3            -0.00166        -0.00166   
                          (-0.15)         (-0.15)   

flood_factor4            -0.00295        -0.00295   
                          (-0.26)         (-0.26)   

flood_factor5            -0.00485        -0.00485   
                          (-0.44)         (-0.44)   

flood_factor6            -0.00773        -0.00773   
                          (-0.68)         (-0.68)   

flood_factor7            -0.00236        -0.00236   
                          (-0.21)         (-0.21)   

flood_factor8           -0.000679       -0.000679   
                          (-0.06)         (-0.06)   

flood_factor9             -0.0106         -0.0106   
                          (-0.94)         (-0.94)   

flood_factor10            -0.0395***      -0.0395***
                          (-3.41)         (-3.41)   
----------------------------------------------------
Observations                10000           10000   
----------------------------------------------------
t statistics in parentheses
* p<0.05, ** p<0.01, *** p<0.001
```

##### Safety and Wages Example

Load the dataset of wages and job safety, which is sampled from the data used in Bell (2020).

```stata
    use safety_aivreg_example.dta, clear
```
```stata
    estimates clear
```
A naive hedonic regression can be misleading.

```stata
    reg wage safety
```
```
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
(est1 stored)
```

Even controlling for a measure of worker skill in OLS may not fix it.

```stata
    reg wage safety afqt_1_1981
```
```
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
(est2 stored)
```

aivreg improves identification using AFQT scores as an anti-IV.

```stata
    aivreg wage safety, aiv(afqt_1_1981)
```
```
Anti-IV Regression                             Number of obs = 3971
Uses Anderson-Rubin CI                       Partial F-stat. =  274.474
SE inferred from radius closest to zero

wage   |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
-------+------------------------------------------------------------------
safety |  -1.145084   .1010579  -11.33096  2.59e-29   -1.379237  -.9470102
--------------------------------------------------------------------------
(est3 stored)
```

Show results in esttab.

```stata
    esttab est1 est2 est3
```
```
------------------------------------------------------------
                      (1)             (2)             (3)   
                     wage            wage            wage   
------------------------------------------------------------
safety              0.126***       0.0436*         -1.145***
                   (6.17)          (2.14)        (-11.33)   

afqt_1_1981                        0.0114***                
                                  (16.57)                   

_cons               0.186***       -0.318***                
                   (9.45)         (-8.87)                   
------------------------------------------------------------
N                    3971            3971            3971   
------------------------------------------------------------
t statistics in parentheses
* p<0.05, ** p<0.01, *** p<0.001

```

### Contact

Questions or concerns: aivregstata@gmail.com

## References

- Bell, A. (2020). Job Amenities and Earnings Inequality. SSRN. https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4173522.  
- Bell, A., Billings, S. B., Calder-Wang, S., & Zhong, S. (2024). An Anti-IV Approach for Pricing Residential Amenities: Applications to Flood Risk. SSRN. https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4899974.
- Correia, S. (2018). IVREGHDFE: Stata module for extended instrumental variable regressions.  
