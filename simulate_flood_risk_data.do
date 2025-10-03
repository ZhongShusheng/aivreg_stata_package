************************************************************
* Simulate housing + HMDA–style variables, N = 1,000
************************************************************
clear
set obs 10000
set seed 12345

* -----------------------
* Geography
* -----------------------

* Block (location)
gen block_id = ceil(rnormal(0,8))
replace block_id = abs(block_id)
gen block_intermediate = rnormal(0, 1)
egen block_fe = first(block_intermediate)
drop block_intermediate

* Elevation: mean 243.6, sd 346.64
scalar k1 = (243.6/346.64)^2
scalar t1 = (346.64^2)/243.6
gen elev_m = rgamma(k1, t1)

* Distance to coast: mean 124.99, sd 168.86
scalar k2 = (124.99/168.86)^2
scalar t2 = (168.86^2)/124.99
gen distcoast = rgamma(k2, t2)

* -----------------------
* Income and latent quality
* -----------------------

* Latent home quality Φ
gen Phi = rnormal(0,1)

* Applicant income ($): 
gen log_income  = rnormal(0, 1) 
replace log_income = 0.2 * log_income + 0.8 * Phi + ln(50000)                 
gen income = exp(log_income)
gen income_thou = income / 1000
su income_thou

* -----------------------
* Flood factor, correlates with quality
* -----------------------

gen flood_factor = ceil(runiform()*10 + Phi - 1) + 1
replace flood_factor = 10 if flood_factor > 10
replace flood_factor = 1 if flood_factor < 1

* Effects relative to Flood Factor = 1
gen flood_effect = 0
replace flood_effect = 0.00313    if flood_factor==2
replace flood_effect = 0.00346    if flood_factor==3
replace flood_effect = 0.00291    if flood_factor==4
replace flood_effect = 0.00105    if flood_factor==5
replace flood_effect = 0.00236    if flood_factor==6
replace flood_effect = 0.00146    if flood_factor==7
replace flood_effect = 0.00492    if flood_factor==8
replace flood_effect = -0.00666   if flood_factor==9
replace flood_effect = -0.0348    if flood_factor == 10

* -----------------------
* Home price in logs
* -----------------------

gen log_price = Phi ///
  + 12.5 ///
  + block_fe ///
  + 0.001*(elev_m/100) - 0.0005*(distcoast/100) ///
  + flood_effect
reg Phi log_income
drop Phi flood_effect block_fe
  
gen price = exp(log_price)

* -----------------------
* Label variables
* -----------------------

label var block_id     "Block id"
label var elev_m       "Elevation (meters)"
label var distcoast    "Distance to Coast (miles)"
label var income      "Household income"
label var income_thou "Income in thousands"
label var log_income  "Log income"
label var flood_factor "Flood risk factor"
label var log_price   "Log sale price"
label var price       "Home sale price ($)"

* -----------------------
* Save data
* -----------------------

save "simulated_flood_risk.dta", replace
