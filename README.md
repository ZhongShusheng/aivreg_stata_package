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
Example: the cost of flood risk to home prices, where buyer income proxies for unobserved home quality.

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

Load simulated flood risk and home prices dataset.
```stata
    . use simulated_flood_risk.dta, clear
```
Baseline OLS with a potential anti_iv (buyer income) partially controlling for home quality.

```stata
    . reg log_price i.flood_factor log_income
    
```
```

      Source |       SS           df       MS      Number of obs   =    10,000
-------------+----------------------------------   F(10, 9989)     =  15595.36
       Model |  9191.56316        10  919.156316   Prob > F        =    0.0000
    Residual |  588.729773     9,989  .058937809   R-squared       =    0.9398
-------------+----------------------------------   Adj R-squared   =    0.9397
       Total |  9780.29293     9,999  .978127106   Root MSE        =    .24277

------------------------------------------------------------------------------
   log_price | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
flood_factor |
          2  |   .0431904   .0109361     3.95   0.000     .0217535    .0646273
          3  |   .0715514   .0107991     6.63   0.000      .050383    .0927197
          4  |   .0602352   .0106209     5.67   0.000     .0394161    .0810542
          5  |   .0528837   .0105715     5.00   0.000     .0321613     .073606
          6  |   .0650941   .0106289     6.12   0.000     .0442594    .0859288
          7  |   .0525767   .0108627     4.84   0.000     .0312837    .0738697
          8  |     .06526    .010615     6.15   0.000     .0444524    .0860676
          9  |   .0696757   .0108714     6.41   0.000     .0483655    .0909859
         10  |    .076571   .0110501     6.93   0.000     .0549107    .0982313
             |
  log_income |   1.162906   .0031784   365.87   0.000     1.156676    1.169137
       _cons |   .0779676   .0331978     2.35   0.019     .0128933     .143042
------------------------------------------------------------------------------
```

High-dimensional FE with clustering by block.
```stata
    . reghdfe log_price i.flood_factor elev_m distcoast log_income, absorb(block_id) vce(cluster block_id)
    . estimates store hdfe1
```
```
(dropped 2 singleton observations)
(MWFE estimator converged in 1 iterations)

HDFE Linear regression                            Number of obs   =      9,998
Absorbing 1 HDFE group                            F(  12,     29) =   19589.51
Statistics robust to heteroskedasticity           Prob > F        =     0.0000
                                                  R-squared       =     0.9399
                                                  Adj R-squared   =     0.9397
                                                  Within R-sq.    =     0.9398
Number of clusters (block_id) =         30        Root MSE        =     0.2429

                              (Std. err. adjusted for 30 clusters in block_id)
------------------------------------------------------------------------------
             |               Robust
   log_price | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
flood_factor |
          2  |    .042308   .0090085     4.70   0.000     .0238835    .0607325
          3  |   .0709069   .0083701     8.47   0.000     .0537881    .0880256
          4  |   .0596414   .0126158     4.73   0.000     .0338391    .0854437
          5  |    .052776   .0091967     5.74   0.000     .0339667    .0715853
          6  |   .0650946   .0112762     5.77   0.000     .0420323    .0881569
          7  |   .0514181   .0128376     4.01   0.000     .0251623     .077674
          8  |   .0645995   .0119606     5.40   0.000     .0401374    .0890616
          9  |    .069124   .0134039     5.16   0.000       .04171    .0965381
         10  |   .0755926   .0105046     7.20   0.000     .0541083    .0970769
             |
      elev_m |   3.00e-06   7.70e-06     0.39   0.699    -.0000128    .0000188
   distcoast |   7.38e-06   .0000127     0.58   0.567    -.0000187    .0000335
  log_income |   1.163002   .0041803   278.21   0.000     1.154452    1.171551
       _cons |   .0758352   .0457109     1.66   0.108     -.017654    .1693244
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
    block_id |        30          30           0    *|
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation
```

aivreg using income as anti-IV.
```stata
    . aivreg log_price i.flood_factor, aiv(log_income) eststo(aiv1)
```
```

Anti-IV Regression                             Number of obs = 10000
Uses Anderson-Rubin CI                       Partial F-stat. = 1.34e+05
SE inferred from radius closest to zero

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor1  |          0          0          .         .           0          0
flood_factor2  |  -.0028931   .0113373  -.2551819  .7985879   -.0251522    .019328
flood_factor3  |   .0210505   .0112178   1.876524  .0606124   -.0009364   .0429956
flood_factor4  |   .0036576   .0110378   .3313692  .7403726   -.0179764   .0252448
flood_factor5  |   .0004001   .0109836   .0364285  .9709414   -.0211278   .0218846
flood_factor6  |   .0158272   .0110407   1.433536  .1517361   -.0058125   .0374263
flood_factor7  |  -.0015544   .0112634  -.1380017  .8902419   -.0236754   .0205219
flood_factor8  |   .0147062   .0110273   1.333616  .1823603   -.0069073   .0362778
flood_factor9  |   .0095011   .0112999   .8408138  .4004724   -.0126467   .0315991
flood_factor10 |  -.0309191   .0114866  -2.691762  .0071194   -.0535217  -.0084054
----------------------------------------------------------------------------------
(result aiv1 is active now)
```

aivreg with controls and block fixed effects; clustered SEs.
```stata
    . aivreg log_price i.flood_factor, aiv(log_income) control(elev_m distcoast) fe(block_id) cluster(block_id) eststo(aiv2)
```   
```
 
Anti-IV Regression                             Number of obs = 9998
Uses Anderson-Rubin CI                       Partial F-stat. =91001.537
SE inferred from radius closest to zero
SE clustered by block_id

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor1  |          0          0          .         .           0          0
flood_factor2  |  -.0038948   .0096825  -.4022544  .6875054   -.0229352   .0150829
flood_factor3  |   .0201961    .008603   2.347566   .018916    .0033342   .0370762
flood_factor4  |   .0030903   .0124429   .2483618  .8038596   -.0212978   .0274229
flood_factor5  |   .0000504   .0088242   .0057065   .995447   -.0172452   .0173659
flood_factor6  |   .0157572   .0122644   1.284794   .198894    -.008281   .0398536
flood_factor7  |  -.0029206   .0129374  -.2257508  .8213998    -.028216   .0224367
flood_factor8  |   .0138071   .0117315    1.17693  .2392516   -.0091866   .0367986
flood_factor9  |   .0087179   .0149753   .5821482    .56048   -.0206338   .0380485
flood_factor10 |  -.0319271   .0105879   -3.01542  .0025727   -.0527365  -.0111747
----------------------------------------------------------------------------------
(result aiv2 is active now)
```

Display/export results with esttab.
```stata
    . esttab hdfe1 aiv1 aiv2, mgroup("reghdfe" "aivreg" "aivreg+ctrl+FE" "aivreg GMM" "aivreg 2SLS", pattern(1 1 1)) modelwidth(20) varwidth(18) label
```
```   
------------------------------------------------------------------------------------------
                                reghdfe                  aivreg          aivreg+ctrl+FE   
                                    (1)                     (2)                     (3)   
                         Log sale price          Log sale price          Log sale price   
------------------------------------------------------------------------------------------
Flood risk facto~1                    0                       0                       0   
                                    (.)                     (.)                     (.)   

Flood risk facto~2               0.0423***             -0.00289                -0.00389   
                                 (4.70)                 (-0.26)                 (-0.40)   

Flood risk facto~3               0.0709***               0.0211                  0.0202*  
                                 (8.47)                  (1.88)                  (2.35)   

Flood risk facto~4               0.0596***              0.00366                 0.00309   
                                 (4.73)                  (0.33)                  (0.25)   

Flood risk facto~5               0.0528***             0.000400               0.0000504   
                                 (5.74)                  (0.04)                  (0.01)   

Flood risk facto~6               0.0651***               0.0158                  0.0158   
                                 (5.77)                  (1.43)                  (1.28)   

Flood risk facto~7               0.0514***             -0.00155                -0.00292   
                                 (4.01)                 (-0.14)                 (-0.23)   

Flood risk facto~8               0.0646***               0.0147                  0.0138   
                                 (5.40)                  (1.33)                  (1.18)   

Flood risk facto~9               0.0691***              0.00950                 0.00872   
                                 (5.16)                  (0.84)                  (0.58)   

Flood risk fact~10               0.0756***              -0.0309**               -0.0319** 
                                 (7.20)                 (-2.69)                 (-3.02)   

Elevation (meters)           0.00000300                                                   
                                 (0.39)                                                   

Distance to Coas~)           0.00000738                                                   
                                 (0.58)                                                   

Log income                        1.163***                                                
                               (278.21)                                                   

Constant                         0.0758                                                   
                                 (1.66)                                                   
------------------------------------------------------------------------------------------
Observations                       9998                   10000                    9998   
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
          1 |      1,158       11.58       11.58
          2 |        895        8.95       20.53
          3 |        946        9.46       29.99
          4 |      1,023       10.23       40.22
          5 |      1,031       10.31       50.53
          6 |      1,002       10.02       60.55
          7 |        933        9.33       69.88
          8 |      1,010       10.10       79.98
          9 |        944        9.44       89.42
         10 |      1,058       10.58      100.00
------------+-----------------------------------
      Total |     10,000      100.00

```

GMM version of aivreg.
```stata
    . aivreg gmm log_price flood_factor10, aiv(log_income) control(elev_m distcoast) eststo(aiv_gmm)
```
``` 

Anti-IV GMM                                    Number of obs = 2216
                                          Number of anti-IVs = 1

log_price      |     Coef.  Std. Err.         t     P>|t|  [95% Conf.  Interval]
---------------+----------------------------------------------------------------
flood_factor10 |  .0625603    .010713  5.839659  6.00e-09    .0415628   .0835578
--------------------------------------------------------------------------------
(result aiv_gmm is active now)
```

2SLS version for comparison.
```stata
    . aivreg 2sls log_price flood_factor10, aiv(log_income) control(elev_m distcoast) eststo(aiv_2sls)
```
```
Anti-IV GMM                                    Number of obs = 2216
                                          Number of anti-IVs = 1

log_price      |      Coef.  Std. Err.          t     P>|t|  [95% Conf.  Interval]
---------------+------------------------------------------------------------------
flood_factor10 |  -.0215269   .0155109  -1.387857  .1653205   -.0519284   .0088745
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
flood_fac~10       0.0626***      -0.0215   
                   (5.84)         (-1.39)   

elev_m       -0.000000623        8.36e-08   
                  (-0.05)          (0.01)   

distcoast     -0.00000771       -6.99e-08   
                  (-0.28)         (-0.00)   
--------------------------------------------
N                    2216            2216   
--------------------------------------------
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
