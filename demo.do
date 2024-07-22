qui{
	* change into project directory
	* ""
	global log_dir ="./logs"
	local today : display %tdCYND date(c(current_date), "DMY")
	log using ${log_dir}/demo_`today'.txt, replace t
}


********************************************************************************
* 1. Labor Market Demo
********************************************************************************
* Load Example
* Outcome: wage
* Amenity: safety
* Anti-IV: afqt_1_1981 (AFQT score)

use safety_aivreg_example.dta, clear


* naive hedonic regression
reg wage safety

* hedonic regression with AFQT as control variables
reg wage safety afqt_1_1981

eststo clear
* AntiIV method using AFQT as Anti-IV
aivreg wage safety, h(afqt_1_1981) eststo(model1)


********************************************************************************
* 2. Housing Market Demo
********************************************************************************
* Load Example Housing Market Data
* Outcome: log_hpvi (house price index for given # of rooms in a given county)
* Amenities: medianaqi (Air Quality Index, higher means worse air), crime_rate
* anti-IV: rank (Geographic PageRank based on migration flows)

use housing_aivreg_example, clear

* Hedonic Regression with Controls to Price a Single Amenity (i.e., medianaqi)
reg log_hpvi medianaqi rank i.rooms if year==2019
eststo model4


* Single-Amenity Anti-IV method using the Stata program, with ARCI standard errors 
* Adding i.room as controls
aivreg log_hpvi medianaqi if year==2019, h(rank) control(i.rooms)
return list

* Single-Amenity Anti-IV method using the Stata program, with ARCI standard errors 
* Adding # of Rooms as a fixed effect variable
aivreg log_hpvi medianaqi if year==2019, h(rank) fe(rooms) eststo(model2) 


* the Equivalent way to calculate the antiIV coefficient with ivreg2 command
qui bootstrap, reps(100) seed(1): ivreg2 log_hpvi (rank=log_hpvi medianaqi) ///
				medianaqi i.rooms if year==2019, ffirst

esttab model1 model2, mgroup("aivreg results" "aivreg results", pattern(1 1)) modelwidth(25) varwidth(20) label

* Hedonic Regression with Controls to Price Multiple Amenities (i.e., medianaqi)
reg log_hpvi medianaqi crime_rate rank i.rooms if year==2019

* Multivariate anti-IV method with Stata program, with ARCI standard errors 
aivreg log_hpvi medianaqi crime_rate if year==2019, h(rank) control(i.rooms)
return list

* Currently not allowing multiple anti-IV option
aivreg log_hpvi medianaqi if year==2019, h(rank crime_rate) control(i.rooms)

log close












