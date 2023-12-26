qui{
	cd "/Users/shushengzhong/Library/CloudStorage/GoogleDrive-zhongshusheng98@gmail.com/.shortcut-targets-by-id/1boJDCakyAAS94F5KjSRVfXd4ICmDvdRP/Measuring and Pricing Neighborhood Characteristics/pricing_amenities/stata_package"
	global temp_dir = "../data/temp"
	global log_dir ="./logs"

}

qui do proxy.do


local today : display %tdCYND date(c(current_date), "DMY")
log using ${log_dir}/demo_`today'.txt, replace t


use ${temp_dir}/county_amenities_price, clear

***************
* 1. One Amenity Only
***************

* Univraite proxy method with Stata program, with ARCI standard errors 
* PROXY if year==2019, h(rank) w(log_hpvi) zlist(medianaqi) fe(i.rooms)
PROXY log_hpvi medianaqi if year==2019, h(rank) fe(i.rooms)

* Show Return List
return list

* run with ivreg2 package
bootstrap, reps(100) seed(1): ivreg2 log_hpvi (rank=log_hpvi medianaqi) medianaqi i.rooms ///
				if year==2019, cluster(fips) ffirst

***************
* 2. Multiple Amenities 
***************
* Multivariate proxy method with Stata program, with ARCI standard errors 
PROXY log_hpvi medianaqi crime_rate if year==2019, h(rank) fe(i.rooms)



* Show Return List
return list



* run with ivreg2 package (multivariate)
bootstrap, reps(100) seed(1): ivreg2 log_hpvi (rank=log_hpvi medianaqi crime_rate) medianaqi crime_rate  i.rooms ///
				if year==2019, cluster(fips) ffirst


***************
* 3. Test Error Code
***************
* Multiple Proxy
PROXY log_hpvi medianaqi if year==2019, h(rank HH_MED_INC) fe(i.rooms)


log close












