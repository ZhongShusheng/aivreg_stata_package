
# ReadMe File for PROXY Stata Pacakge

## Syntax
 **PROXY** depvar [varlist] [if] [in], h(varlist) [fe(string)] [weight(string)]

## Input List
 - **depvar** the outcome variable 
 - **varlist** the list of amenities 
 - **h** a list of proxy variables (!currently PROXY only supports one proxy variable) 
 - **fe** the fixed effects to be added 
 - **weight** specifies weighting options

## Return List
 - **Partial F** Partial F-Stat 
 - **beta"var"** Coefficient for the amenity "var" 
 - **lb_AR"var"** Anderson-Rubin Confidence Interval (Lower Bound) for the amenity "var" 
 - **ub_AR"var"** Anderson-Rubin Confidence Interval (Upper Bound) for the amenity "var" 
 - ereturn stores all the post-estimation results from the baseline regression: reg h varlist depvar
 

