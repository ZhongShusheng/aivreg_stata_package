# aivreg — Anti-IV Regression

## Syntax
```stata

    aivreg [estimator] depvar varlist [if] [in], aiv(varlist) [options]

```

## Options


### Model specification
    aiv(varlist)        anti-IV variables (one for OLS, multiple for GMM).
    control(varlist)    control variables.
    fe(varlist)         fixed effects to absorb (via reghdfe or ivreghdfe). Not available for GMM.
    weight(...)         observation weights for estimation.
    weightmatrix(matrix) estimation weight matrix for estimation (GMM only).

### Estimation & storage
    eststo(name)        store estimates under name.
    savefirst           save first-stage regression results.
    firststo(name)      store first-stage estimates under name.
    displayaiv          display coefficient on predicted anti-IV.

### Variance & inference
    vce(type)           variance estimator: ar (default), boot, asymp.
    cluster(varlist)    cluster-robust SEs.
    reps(#)             number of bootstrap replications.
    seed(#)             random seed for bootstrap.

## Description

aivreg implements the anti-IV estimator outlined in Bell et al. (2025). 
The method allows consistent estimation of hedonic prices when an imperfectly 
informative variable (anti-IV) for a confounder exists. 
Example: the cost of flood risk to home prices, where buyer income is informative for unobserved home quality.

## Details


### Estimator
    If estimator is blank, aivreg defaults to OLS using ivreg2, reg, reghdfe, or ivreghdfe.
    If estimator = gmm, aivreg uses the GMM estimator (default weight matrix = identity).
    If estimator = 2sls, aivreg uses GMM with the optimal homoskedastic weight matrix.
    With one anti-IV, 2SLS and OLS yield identical point estimates.

### Model specification
    aiv(varlist)   One anti-IV for OLS, multiple for GMM (switches automatically).
    control(varlist) Exogenous controls included in both stages.
    fe(varlist)    Fixed effects absorbed using reghdfe/ivreghdfe. Not allowed with GMM.
    weight(...)    For OLS, use Stata weight syntax (e.g. [aw=wt]).
                   For GMM, provide just the variable name; GMM uses probability weights.
    weightmatrix() Square matrix with (# amenities + # controls + 2 × # anti-IVs). Defaults to identity.

### Estimation & storage
    eststo(name)   Stores results under name.
    savefirst      Reports and stores first-stage regression.
    firststo(name) Stores first-stage estimates under name.
    displayaiv     Displays coefficient on predicted anti-IV (not with AR CIs).

### Variance & inference
    vce(type)      ar (Anderson–Rubin, default), boot (bootstrap), asymp (asymptotic).
    cluster()      Cluster-robust SEs.
    reps(#)        Bootstrap replications.
    seed(#)        Bootstrap seed.

### Examples

The following examples use data which are included in the aivreg package.

Load simulated flood risk and home prices dataset. This is made with simulate_flood_risk_data.do, included in the aivreg package.
```stata
    . use simulated_flood_risk.dta, clear
```
Baseline OLS with a potential anti_iv (buyer income) partially controlling for home quality.

```stata
    . reg log_price i.flood_factor log_income
    
```
```

      Source |       SS           df       MS      Number of obs   =    10,000
-------------+----------------------------------   F(10, 9989)     =  16437.26
       Model |  9554.37344        10  955.437344   Prob > F        =    0.0000
    Residual |  580.623646     9,989  .058126304   R-squared       =    0.9427
-------------+----------------------------------   Adj R-squared   =    0.9427
       Total |  10134.9971     9,999  1.01360107   Root MSE        =    .24109

------------------------------------------------------------------------------
   log_price | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
flood_factor |
          2  |   .0521018   .0111494     4.67   0.000     .0302468    .0739568
          3  |   .0503678   .0107759     4.67   0.000     .0292449    .0714908
          4  |   .0482142   .0108585     4.44   0.000     .0269294     .069499
          5  |   .0441611   .0107858     4.09   0.000     .0230188    .0653034
          6  |   .0480572   .0108359     4.44   0.000     .0268168    .0692977
          7  |   .0519298   .0108591     4.78   0.000     .0306438    .0732158
          8  |   .0508874   .0108414     4.69   0.000      .029636    .0721388
          9  |   .0520409   .0109709     4.74   0.000     .0305357    .0735461
         10  |    .063299   .0110846     5.71   0.000     .0415709    .0850271
             |
  log_income |   1.166645   .0030955   376.89   0.000     1.160578    1.172713
       _cons |  -.9503204   .0324316   -29.30   0.000    -1.013893   -.8867479
------------------------------------------------------------------------------

```

High-dimensional FE with clustering by block.
```stata
    . reghdfe log_price i.flood_factor elev_m distcoast log_income, absorb(block_id) vce(cluster block_id)
    . estimates store hdfe1
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

```

aivreg using income as anti-IV.
```stata
    . aivreg log_price i.flood_factor, aiv(log_income) eststo(aiv1)
```
```

. aivreg log_price i.flood_factor, aiv(log_income) eststo(aiv1)
 
Anti-IV Regression                             Number of obs = 10000
Uses Anderson-Rubin CI                       Partial F-stat. = 1.42e+05
SE inferred from radius closest to zero

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor1  |          0          0          .         .           0          0
flood_factor2  |   .0114884   .0115511   .9945732   .319968   -.0111517   .0340951
flood_factor3  |  -.0017934   .0111506  -.1608296  .8722309   -.0236915   .0200619
flood_factor4  |  -.0030903   .0112357   -.275041  .7832904   -.0251546   .0189318
flood_factor5  |  -.0051555     .01116  -.4619628  .6441181   -.0270698   .0167182
flood_factor6  |  -.0077301   .0112137  -.6893468   .490621   -.0297549   .0142487
flood_factor7  |  -.0026147   .0112373  -.2326762  .8160176   -.0246847   .0194105
flood_factor8  |  -.0007329   .0112182   -.065327  .9479149    -.022763   .0212548
flood_factor9  |  -.0103114   .0113555  -.9080567  .3638702   -.0326196   .0119454
flood_factor10 |  -.0392638   .0114954    -3.4156  .0006389   -.0618793  -.0167328
----------------------------------------------------------------------------------
(result aiv1 is active now)

```

aivreg with controls and block fixed effects; clustered SEs.
```stata
    . aivreg log_price i.flood_factor, aiv(log_income) fe(block_id) eststo(aiv2)
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
(result aiv2 is active now)

```

Display/export results with esttab.
```stata
    . esttab hdfe1 aiv1 aiv2, mgroup("reghdfe" "aivreg" "aivreg+ctrl+FE" "aivreg GMM" "aivreg 2SLS", pattern(1 1 1)) modelwidth(20) varwidth(18) label
```
```   

------------------------------------------------------------------------------------------
                                reghdfe                  aivreg               aivreg+FE   
                                    (1)                     (2)                     (3)   
                         Log sale price          Log sale price          Log sale price   
------------------------------------------------------------------------------------------
Flood risk facto~1                    0                       0                       0   
                                    (.)                     (.)                     (.)   

Flood risk facto~2               0.0521***               0.0115                  0.0115   
                                 (4.67)                  (0.99)                  (0.99)   

Flood risk facto~3               0.0505***             -0.00179                -0.00166   
                                 (4.68)                 (-0.16)                 (-0.15)   

Flood risk facto~4               0.0483***             -0.00309                -0.00295   
                                 (4.45)                 (-0.28)                 (-0.26)   

Flood risk facto~5               0.0444***             -0.00516                -0.00485   
                                 (4.12)                 (-0.46)                 (-0.43)   

Flood risk facto~6               0.0480***             -0.00773                -0.00773   
                                 (4.43)                 (-0.69)                 (-0.69)   

Flood risk facto~7               0.0522***             -0.00261                -0.00236   
                                 (4.80)                 (-0.23)                 (-0.21)   

Flood risk facto~8               0.0509***            -0.000733               -0.000679   
                                 (4.70)                 (-0.07)                 (-0.06)   

Flood risk facto~9               0.0517***              -0.0103                 -0.0106   
                                 (4.72)                 (-0.91)                 (-0.93)   

Flood risk fact~10               0.0630***              -0.0393***              -0.0395***
                                 (5.69)                 (-3.42)                 (-3.43)   

Log income                        1.167***                                                
                               (376.91)                                                   

Constant                         -0.951***                                                
                               (-29.31)                                                   
------------------------------------------------------------------------------------------
Observations                      10000                   10000                   10000   
------------------------------------------------------------------------------------------
t statistics in parentheses
* p<0.05, ** p<0.01, *** p<0.001

```

Make singular dummy for flood factor 10 as GMM does not accept factor variables.
```stata
    . tabulate flood_factor, generate(flood_factor)
    . label var flood_factor10 "Flood risk factor=10"
    . drop if flood_factor != 1 & flood_factor != 10
```
```	

 Flood risk |
     factor |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      1,054       10.54       10.54
          2 |        870        8.70       19.24
          3 |      1,018       10.18       29.42
          4 |        985        9.85       39.27
          5 |      1,007       10.07       49.34
          6 |      1,005       10.05       59.39
          7 |        993        9.93       69.32
          8 |        992        9.92       79.24
          9 |        974        9.74       88.98
         10 |      1,102       11.02      100.00
------------+-----------------------------------
      Total |     10,000      100.00

```

GMM version of aivreg.
```stata
    . aivreg gmm log_price flood_factor10, aiv(log_income) eststo(aiv_gmm)
```
``` 

Anti-IV GMM                                    Number of obs = 2156
                                          Number of anti-IVs = 1

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor10 |  -.0349469    .015583  -2.242626  .0250223   -.0654895  -.0044042
----------------------------------------------------------------------------------
(result aiv_gmm is active now)

```

2SLS version for comparison.
```stata
    . aivreg 2sls log_price flood_factor10, aiv(log_income) eststo(aiv_2sls)
```
```

Anti-IV GMM                                    Number of obs = 2156
                                          Number of anti-IVs = 1

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor10 |  -.0349469    .015583  -2.242626  .0250223   -.0654895  -.0044042
----------------------------------------------------------------------------------
(result aiv_2sls is active now)


```

Show results in esttab.
```stata
    . esttab aiv_gmm aiv_2sls
```
```
--------------------------------------------
                      (1)             (2)   
                log_price       log_price   
--------------------------------------------
flood_fac~10      -0.0349*        -0.0349*  
                  (-2.24)         (-2.24)   
--------------------------------------------
N                    2156            2156   
--------------------------------------------
t statistics in parentheses
* p<0.05, ** p<0.01, *** p<0.001

```


Load the sample wagesdatasets.
```stata
    . use safety_aivreg_example.dta, clear
```
A naive hedonic regression can be misleading.
```stata
    . reg wage safety
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
```

Even adding a potential anti-IV into OLS may not fix it.
```stata
    . reg wage safety afqt_1_1981
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
```

aivreg improves identification using an anti-IV.
```stata
    . aivreg wage safety, aiv(afqt_1_1981) eststo(model1)
```
```

Anti-IV Regression                             Number of obs = 3971
Uses Anderson-Rubin CI                       Partial F-stat. =  274.474
SE inferred from radius closest to zero

wage   |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
-------+------------------------------------------------------------------
safety |  -1.145084   .1010579  -11.33096  2.59e-29   -1.379237  -.9470102
--------------------------------------------------------------------------
(result model1 is active now)
```

Show results in esttab
```stata
   . esttab model1
```
```
----------------------------
                      (1)   
                     wage   
----------------------------
safety             -1.145***
                 (-11.33)   
----------------------------
N                    3971   
----------------------------
t statistics in parentheses
* p<0.05, ** p<0.01, *** p<0.001
```

## Saved results

### Scalars
    e(Partial_F)       partial F-statistic from first stage  
    e(df_r)            residual degrees of freedom  
    e(N)               number of observations  
    e(Jval)            J-test statistic (GMM only)  
    e(pval_J)          p-value of J-test (GMM only)  
    e(betavarname)     coefficient on variable varname  
    e(SE_vcevarname)   standard error of coefficient on varname, using vce (either AR, asymp, or boot); if AR, SE approximated using CI closest to zero  
    e(t_valvarname)    t-value for coefficient on varname  
    e(p_more_tvarname) t-test statistic for coefficient on varname  
    e(lb_vcevarname)   lower bound for coefficient on varname (95% confidence), using vce (AR, asymp, or boot)  
    e(ub_vcevarname)   upper bound for coefficient on varname (95% confidence), using vce (AR, asymp, or boot)  

### Macros
    e(cmd)         "aivreg"

### Matrices
    e(b)           coefficient vector
    e(V)           variance–covariance matrix; in AR, diagonal matrix with values approximated from AR CI closest to zero
    e(S)           covariance of moments (GMM only)
    e(weightmatrix) weight matrix (GMM only)

### Contact

Questions: aivregstata@gmail.com

## References

- Bell, A. (2020). Job Amenities and Earnings Inequality. SSRN.  
- Bell, A., Billings, S. B., Calder-Wang, S., & Zhong, S. (2024). An Anti-IV Approach for Pricing Residential Amenities: Applications to Flood Risk. SSRN.  
- Correia, S. (2018). IVREGHDFE: Stata module for extended instrumental variable regressions.  
