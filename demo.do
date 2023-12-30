qui{
	* change into project directory
	* ""
	global log_dir ="./logs"
	local today : display %tdCYND date(c(current_date), "DMY")
	log using ${log_dir}/demo_`today'.txt, replace t
}

* qui do proxy.do




********************************************************************************
* 1. Labor Market Demo
********************************************************************************
* Load Example
* Outcome: wage
* Amenity: safety
* proxy: afqt_1_1981 (AFQT score)

use safety_proxy_example, clear

* naive hedonic regression
reg wage safety

* hedonic regression with AFQT as control variables
reg wage safety afqt_1_1981

* proxy method using AFQT as proxy
proxy wage safety, h(afqt_1_1981)


********************************************************************************
* 2. Housing Market Demo
********************************************************************************
* Load Example Housing Market Data
* Outcome: log_hpvi (house price index for given # of rooms in a given county)
* Amenities: medianaqi (Air Quality Index, higher means worse air), crime_rate
* Proxy: rank (Geographic PageRank based on migration flows)

use housing_proxy_example, clear

* Hedonic Regression with Controls to Price a Single Amenity (i.e., medianaqi)
reg log_hpvi medianaqi rank i.rooms if year==2019

* Single-Amenity proxy method using the Stata program, with ARCI standard errors 
proxy log_hpvi medianaqi if year==2019, h(rank) control(i.rooms)
return list 

* the Equivalent way to calculate the proxy coefficient with ivreg2 command
bootstrap, reps(100) seed(1): ivreg2 log_hpvi (rank=log_hpvi medianaqi) ///
				medianaqi i.rooms if year==2019, cluster(fips) ffirst


* Hedonic Regression with Controls to Price Multiple Amenities (i.e., medianaqi)
reg log_hpvi medianaqi crime_rate rank i.rooms if year==2019

* Multivariate proxy method with Stata program, with ARCI standard errors 
proxy log_hpvi medianaqi crime_rate if year==2019, h(rank) control(i.rooms)
return list

* Currently not allowing multiple proxy option
proxy log_hpvi medianaqi if year==2019, h(rank crime_rate) control(i.rooms)

log close












