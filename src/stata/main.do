		**********************************************
		***		MERGING CONFLICT AND PRICE DATA	   ***
		**********************************************

*****************************************************
*		Fetch raw data: full dataset for plots      *
*****************************************************

		
*******************************
*		Fetch raw data.       *
*******************************
global restricted_sample = 1

clear
cd "/Users/pantoine/school/m2/thesis/conflict_data"

import delimited acled_data

*	Create a variable event_YM, to be used for merging purposes
gen month = "01" if substr(event_date,4,3) == "Jan"
replace month = "02" if substr(event_date,4,3) == "Feb"
replace month = "03" if substr(event_date,4,3) == "Mar"
replace month = "04" if substr(event_date,4,3) == "Apr"
replace month = "05" if substr(event_date,4,3) == "May"
replace month = "06" if substr(event_date,4,3) == "Jun"
replace month = "07" if substr(event_date,4,3) == "Jul"
replace month = "08" if substr(event_date,4,3) == "Aug"
replace month = "09" if substr(event_date,4,3) == "Sep"
replace month = "10" if substr(event_date,4,3) == "Oct"
replace month = "11" if substr(event_date,4,3) == "Nov"
replace month = "12" if substr(event_date,4,3) == "Dec"

gen event_YM = substr(event_date,-4,4)+"-"+month
drop month
sort event_YM
order event_date event_YM

//////////////////////////////////////////////////////////////////////////////////
// HAVE TO BE VERY CAREFUL WITH THE NAMES: HILMAND == HELMAND, NIMROZ == NIMRUZ, HIRAT == HERAT, SUR-PUL == SAR-E POL, JAWZJAN == JOWZJAN, URUZGAN == UROZGAN //
//////////////////////////////////////////////////////////////////////////////////

*	1. Aggregate at the regional level (NE, Central, Southern, etc...)

*	Province-region association changes:
*		2018: Zabul, Urozgan added up to 2020. No other changes (false flags due to small string variations (often a blank space added)).

	gen region_agg = cond(admin1 == "Baghlan" | admin1 == "Balkh" | admin1 == "Faryab" | admin1 ==  "Sar-e Pol" | admin1 ==  "Jowzjan" | admin1 == "Samangan", "N", ///
						cond(admin1 == "Badakhshan" | admin1 == "Takhar" | admin1 == "Kunduz", "NE", ///
							cond(admin1 == "Kunar" | admin1 == "Laghman" | admin1 == "Nangarhar", "E", ///
								cond(admin1 == "Helmand" | admin1 == "Kandahar", "S", ///
									cond(admin1 == "Badghis" | admin1 == "Farah" | admin1 == "Ghor" | admin1 == "Herat" | admin1 == "Nimruz", "W", ".") ///
								) ///
							) ///
						) ///
					) if year == 2017
	
	replace region_agg = cond(admin1 == "Baghlan" | admin1 == "Balkh" | admin1 == "Faryab" | admin1 ==  "Sar-e Pol" | admin1 ==  "Jowzjan" | admin1 == "Samangan", "N", ///
							cond(admin1 == "Badakhshan" | admin1 == "Takhar" | admin1 == "Kunduz", "NE", ///
								cond(admin1 == "Kunar" | admin1 == "Laghman" | admin1 == "Nangarhar", "E", ///
									cond(admin1 == "Helmand" | admin1 == "Kandahar" | admin1 == "Urozgan" | admin1 == "Zabul", "S", ///
										cond(admin1 == "Badghis" | admin1 == "Farah" | admin1 == "Ghor" | admin1 == "Herat" | admin1 == "Nimruz", "W", ".") ///
									) ///
								) ///
							) ///
						) if year == 2018 | year == 2019 | year == 2020
	
	replace region_agg = "OTHER" if region_agg == "."
	
*	Drop unused variables, and regions not contained in the price data.
drop data_id iso event_id_cnty event_id_no_cnty region country admin3 timestamp iso3

preserve
	
	// exclude poppy-free regions
	drop if region_agg == "OTHER" & $restricted_sample == 1
	
*	2.1 By month and region, establish conflict type weights

		bysort event_YM region_agg: egen battle_weight = max(sum(cond(event_type == "Battles", 1, 0)) / _N)
		bysort event_YM region_agg: egen remote_violence_weight = max(sum(cond(event_type == "Explosions/Remote violence", 1, 0)) / _N)
		bysort event_YM region_agg: egen protests_weight = max(sum(cond(event_type == "Protests", 1, 0)) / _N)
		bysort event_YM region_agg: egen strat_dev_weight = max(sum(cond(event_type == "Strategic developments", 1, 0)) / _N)
		bysort event_YM region_agg: egen civ_violence_weight = max(sum(cond(event_type == "Violence against civilians", 1, 0)) / _N)

*	2.2 Do the same, but with the 'inter1' variable which contains actor types.

*	Correspondance is the following:
*		1: State forces
*		2: Rebel Groups
*		3: Political Militias
*		4: Identity Militias
*		5: Rioters (NONE IN THE DATASET)
*		6: Protesters
*		7: Civilians
*		8: External/Other Forces
*		Note: the Taliban can have their own variable due to the frequency of observations and since they are at the center of the research question

		bysort event_YM region_agg: egen state_actor_weight = max(sum(cond(inter1 == 1), 1, 0) / _N)
		bysort event_YM region_agg: egen rebel_actor_weight = max(sum(cond(inter1 == 2), 1, 0) / _N) //collinear with taliban
		bysort event_YM region_agg: egen pol_militia_actor_weight = max(sum(cond(inter1 == 3, 1 ,0)) / _N)
		bysort event_YM region_agg: egen identity_militias_actor_wight = max(sum(cond(inter1 == 4, 1 ,0)) / _N)
		bysort event_YM region_agg: egen protesters_actor_weight = max(sum(cond(inter1 == 6, 1 ,0)) / _N)
		bysort event_YM region_agg: egen civilians_actor_weight = max(sum(cond(inter1 == 7, 1 ,0)) / _N)
		bysort event_YM region_agg: egen external_actor_weight = max(sum(cond(inter1 == 8, 1 ,0)) / _N)
		bysort event_YM region_agg: egen taliban_actor_weight = max(sum(cond(actor1 == "Taliban", 1 ,0)) / _N)

*	2.3 Fatalities

		bysort event_YM region_agg: egen fatalities_month_region = total(fatalities)
		
		// sum of fatalities due to talibans
		bysort event_YM region_agg: egen fatalities_taliban = max(sum(cond(actor1 == "Taliban", fatalities, 0)))
		
		//share of fatalies due to talibans
		bysort event_YM region_agg: gen fatalities_taliban_weight = fatalities_taliban / fatalities_month_region
		
		//computes the avg fatalities whenever a conflict is due to taliban: sum of taliban fatalities in region-month, divded by n. of conflicts in region-month
		bysort event_YM region_agg: egen avg_fatalities_taliban = mean(cond(actor1 == "Taliban", fatalities, 0))
		
		bysort event_YM region_agg: egen fatalities_state_actors = max(sum(cond(inter1 == 1, fatalities,0)))
		bysort event_YM region_agg: replace fatalities_state_actors = fatalities_state_actors / fatalities_month_region
		rename fatalities_state_actor share_fat_state_actors
		
		bysort event_YM region_agg: egen avg_fatalities_state_actors = mean(cond(inter1 == 1, fatalities,0))

		drop fatalities_month_region admin2 location source source_scale notes

*	Avg. monthly fatalities, province level, excluding poppy free regions

		bysort event_YM admin1: egen fatalities_month_province = total(fatalities)
		bysort event_YM: egen mean_fatalities_month_price = mean(fatalities_month_province)

*	Avg. conflict events by taliban, province level

		bysort event_YM admin1: egen conflicts_taliban_province = max(sum(cond(actor1 == "Taliban", 1, 0)))
		bysort event_YM: egen mean_conflicts_taliban_price = mean(conflicts_taliban_province)

		drop fatalities_month_province conflicts_taliban_province
		
*	2.4 Also use raw number of conflict events, at region level

		bysort event_YM region_agg: egen total_battles = max(sum(cond(event_type == "Battles", 1, 0)))
		bysort event_YM region_agg: egen total_remote_violence = max(sum(cond(event_type == "Explosions/Remote violence", 1, 0)))
		//note: once we collapse to region level, we xtset and get the lag of these two variables (end of dofile)
		
		*2.4.2 Total battles, remote violence if taliban
		
		bysort event_YM region_agg: egen total_battles_taliban = max(sum(cond(event_type == "Battles" & actor1 == "Taliban", 1, 0)))
		bysort event_YM region_agg: egen total_remoteviolence_taliban = max(sum(cond(event_type == "Explosions/Remote violence" & actor1 == "Taliban", 1, 0)))
		
		*2.4.3 Total battles, remote violence if military
		
		bysort event_YM region_agg: egen total_battles_afmilitary = max(sum(cond(event_type == "Battles" & substr(actor1, 1, 30) == "Military Forces of Afghanistan", 1, 0)))
		bysort event_YM region_agg: egen total_remoteviolence_afmilitary = max(sum(cond(event_type == "Explosions/Remote violence" & substr(actor1, 1, 30) == "Military Forces of Afghanistan", 1, 0)))

		*2.4.4 Total battles, remote violence if police
		
		bysort event_YM region_agg: egen total_battles_afpolice = max(sum(cond(event_type == "Battles" & substr(actor1, 1, 28) == "Police Forces of Afghanistan", 1, 0)))
		bysort event_YM region_agg: egen total_remoteviolence_afpolice = max(sum(cond(event_type == "Explosions/Remote violence" & substr(actor1, 1, 28) == "Police Forces of Afghanistan", 1, 0)))
		
		*		At province level (all actors)
		
		bysort event_YM admin1: egen total_battles_province = max(sum(cond(event_type == "Battles", 1, 0)))
		bysort event_YM admin1: egen total_remoteviolence_province = max(sum(cond(event_type == "Explosions/Remote violence", 1, 0)))
		
		*	Bonus: fatalities due to police/military
		
		bysort event_YM region_agg: egen fatalities_afmilitary = max(sum(cond(substr(actor1, 1, 30) == "Military Forces of Afghanistan", fatalities, 0)))
		bysort event_YM region_agg: gen avg_fatalities_afmilitary = fatalities_afmilitary/_N
		bysort event_YM region_agg: egen fatalities_afpolice = max(sum(cond(substr(actor1, 1, 28) == "Police Forces of Afghanistan", fatalities, 0)))
		bysort event_YM region_agg: gen avg_fatalities_afpolice = fatalities_afpolice/_N
		
	cd "/Users/pantoine/school/m2/thesis/raw_merged_csv"
	//use acled_data_pre_merge.dta, clear
	if $restricted_sample == 1 {
		save acled_data_pre_merge.dta, replace
		export delimited acled_data_pre_merge.csv, replace
		}
	else if $restricted_sample == 0 {
		cd "/Users/pantoine/school/m2/thesis/merged_data"
		//use full_data_summary_stats, clear
		save full_data_summary_stats.dta, replace
		}
	
restore


preserve
	
	//only no price regions for graphs

	replace region_agg = "OTHER" if region_agg == "."
	drop if region_agg != "OTHER"
	
	//get number of battles and remote violence in given month-region
	bysort event_YM admin1: egen fatalities_month_province = total(fatalities)
	bysort event_YM admin1: egen total_battles_province = max(sum(cond(event_type == "Battles", 1, 0)))
	bysort event_YM admin1: egen total_remote_violence_province = max(sum(cond(event_type == "Explosions/Remote violence", 1, 0)))
	
	//get the mean of these events in a given month
	bysort event_YM: egen mean_fatalities_month_no_price = mean(fatalities_month_province)
	bysort event_YM: egen mean_battles_no_price = mean(total_battles_province)
	bysort event_YM: egen mean_remoteviolence_no_price = mean(total_remote_violence_province)

*	Avg. conflict events by taliban, province level (poppy free regions)

	bysort event_YM admin1: egen conflicts_taliban_province = max(sum(cond(actor1 == "Taliban", 1, 0)))
	bysort event_YM: egen mean_conflicts_taliban_no_price = mean(conflicts_taliban_province)

	drop  conflicts_taliban_province
	
	bysort event_YM: keep if _n == 1	
	cd "/Users/pantoine/school/m2/thesis/merged_data"
	//use acled_full_province,clear
	save acled_full_province.dta, replace
	export delimited acled_full_province.csv, replace
	
restore


*************************************
*		Fetch raw price data.       *
*************************************

/////////////////////////////////////////
// 			TRADER PRICES
/////////////////////////////////////////

	clear
	cd "/Users/pantoine/school/m2/thesis/raw_merged_csv"

	import delimited 10-20_final_merged.csv,clear

	rename v1 date
	rename v2 region
	rename v3 dry_op_price_trader
			
	sort date region

	*	3.1	Set region string to be the same as in ACLED data.
						
		gen region_agg = cond(substr(region, 1, 13) == "North-eastern", "NE", cond(substr(region,1,2) == "No", "N", cond(substr(region,1,1) == "E", "E", cond(substr(region,1 ,1) == "S", "S", cond(substr(region,1,1) == "W", "W", ".")))))

	*	3.2 Can now merge with ACLED data using region_agg, and date.

	rename date event_YM
	drop region
	order event_YM region_agg
	tempfile oppricestrader
	save `oppricestrader'

	/////////////////////////
	// 			FARM GATE PRICES
	/////////////////////////

	import delimited opium_prices_17-20_farmgate.csv, clear

	rename v1 date
	rename v2 region
	rename v3 dry_op_price_farmgate
	sort date region		
		gen region_agg = cond(substr(region, 1, 13) == "North-eastern", "NE", cond(substr(region,1,2) == "No", "N", cond(substr(region,1,1) == "E", "E", cond(substr(region,1 ,1) == "S", "S", cond(substr(region,1,1) == "W", "W", ".")))))
	rename date event_YM
	drop region
	order event_YM region_agg

	merge 1:1 event_YM region_agg using `oppricestrader'
	drop if _merge == 2
	drop _merge

	/////////////////////////
	// 			ERROR IN THE PDF REPORT FOR MAY 2017: THEY SWITCHED TRADER AND FARM PRICES (confirmed, check the report)
	//			can check using bysort event_YM: tab region_agg if dry_op_price_farmgate > dry_op_price_trader
	/////////////////////////

	g correct_trader_p = dry_op_price_farmgate if event_YM == "2017-05"
	g correct_farmgate_p = dry_op_price_trader if event_YM == "2017-05"
	replace dry_op_price_farmgate = correct_farmgate_p if event_YM == "2017-05"
	replace dry_op_price_trader = correct_trader_p if event_YM == "2017-05"
	drop correct_trader_p correct_farmgate_p

	tempfile allopprices
	save `allopprices'
	
	*************************************
	*		Merge heroin prices	       **
	*************************************

	import excel merged_hprices17-20.xlsx, clear
	rename A event_YM
	rename B region_hprices
	rename C h_prices
	rename D h_quality

	replace h_prices = cond(substr(h_prices,2,1) == ",", substr(h_prices,1,1)+""+substr(h_prices,3,3), h_prices)

	//nested conds to gen region_agg

	gen region_agg = cond(substr(region,1,3) == "Bad", "NE", ///
						cond(substr(region,1,3) == "Bal", "N", ///
							cond(substr(region,1,3) == "Kan", "S", ///
								cond(substr(region,1,3) == "Hir", "W", ///
									cond(substr(region,1,3) == "Nan", "E", ///
										cond(substr(region,1,3) == "Tak", "NE", "."))))))

	destring h_prices,replace

	gen month = "01" if substr(event_YM,1,3) == "Jan"
	replace month = "02" if substr(event_YM,1,3) == "Feb"
	replace month = "03" if substr(event_YM,1,3) == "Mar"
	replace month = "04" if substr(event_YM,1,3) == "Apr"
	replace month = "05" if substr(event_YM,1,3) == "May"
	replace month = "06" if substr(event_YM,1,3) == "Jun"

	replace event_YM = "2020-"+month if substr(event_YM, 5, 2) == "20"
	drop month

	//AVG FOR NE SINCE WE HAVE TWO DATAPOINTS
	bysort region_agg event_YM: egen meanhprices = mean(h_prices)
	replace h_prices = meanhprices if region_agg == "NE"
	drop meanhprices
	sort region_hprices event_YM
	replace h_quality = "Off-white 80% avg quality (AGG. WITH TAKHAR)" if region_agg == "NE"
	drop if region_hprices == "Takhar"

	order event_YM region_agg region_hprices

	duplicates report event_YM region_agg
	duplicates list
	duplicates tag, g(dup)
	sort dup h_quality
	bysort dup: drop if mod(_n, 2) == 1 & dup == 1
	drop dup

	merge 1:1 event_YM region_agg using `allopprices'
	drop _merge

	*************************************
	*		MERGE WITH ACLED.	       **
	*************************************

	merge 1:m event_YM region_agg using acled_data_pre_merge
	drop if _merge != 3
	drop _merge

	save opium_acled.dta, replace



	********************************************
	*		Adjust prices with afg. CPI.       *
	********************************************

	clear
	cd "/Users/pantoine/school/m2/thesis/cpi_data"
	import delimited cpi_17-20

	replace months = "01" if substr(months,1,3) == "Jan"
	replace months = "02" if substr(months,1,3) == "Feb"
	replace months = "03" if substr(months,1,3) == "Mar"
	replace months = "04" if substr(months,1,3) == "Apr"
	replace months = "05" if substr(months,1,3) == "May"
	replace months = "06" if substr(months,1,3) == "Jun"
	replace months = "07" if substr(months,1,3) == "Jul"
	replace months = "08" if substr(months,1,3) == "Aug"
	replace months = "09" if substr(months,1,3) == "Sep"
	replace months = "10" if substr(months,1,3) == "Oct"
	replace months = "11" if substr(months,1,3) == "Nov"
	replace months = "12" if substr(months,1,3) == "Dec"

	tostring year, replace
	gen event_YM = year+"-"+months
	drop domaincode domain areacodem49 area yearcode year itemcode months monthscode flag note
	drop if item == "Food price inflation" | item == "Consumer Prices, Food Indices (2015 = 100)"

	save cpi_17-20.dta, replace

	cd "/Users/pantoine/school/m2/thesis/raw_merged_csv"
	use opium_acled, clear
	cd "/Users/pantoine/school/m2/thesis/cpi_data"

	merge m:1 event_YM using cpi_17-20

	*****************************************
	*		Create variables for regs       *
	*****************************************

	generate double event_time = monthly(event_YM, "YM")
	format event_time %tm

	rename value cpi
	g dry_op_trader_2015cpi = ( 100/cpi )*dry_op_price_trader
	g dry_op_farmgate_2015cpi = ( 100/cpi )*dry_op_price_farmgate
	g h_prices_2015cpi = ( 100/cpi )*h_prices

	// Drop where price data stops (2020 july), and take the log
	drop if _merge == 2
	g log_dryop_trader_2015cpi = log(dry_op_trader_2015cpi)
	g log_dryop_farmgate_2015cpi = log(dry_op_farmgate_2015cpi)
	g log_hprices_2015cpi = log(h_prices_2015cpi)

	//deviation from month-region mean
	gen month = month(dofm(event_time))
	bys region_agg month: egen mavg_trader = mean(dry_op_trader_2015cpi)
	bys region_agg month: egen mavg_farmgate = mean(dry_op_farmgate_2015cpi)

	cd "/Users/pantoine/school/m2/thesis/merged_data"
	save main_panel,replace
	export delimited main_panel.csv, replace

	cd "/Users/pantoine/school/m2/thesis/merged_data"
	use main_panel, clear

*			SUMMARY STATISTICS TABLE

preserve
	ssc install estout, replace
	
			//// FULL SAMPLE \\\\ (merged_data directory)
			
	use full_data_summary_stats, clear
	rename fatalities fatalities_full_sample
	
	bysort event_YM: egen monthly_battles_country_full = max(sum(cond(event_type == "Battles", 1, 0)))
	bysort event_YM: egen monthly_remoteviolence_full = max(sum(cond(event_type == "Explosions/Remote violence", 1, 0)))
	bysort event_YM: gen all_monthly_conflicts_full = _N
	
	//conflicts involving talibans/military/police
	bysort event_YM: egen involving_talibans_full = max(sum(cond(actor1 == "Taliban", 1, 0)))
	bysort event_YM: egen involving_military_full = max(sum(cond(substr(actor1,1,30) == "Military Forces of Afghanistan", 1, 0)))
	bysort event_YM: egen involving_police_full = max(sum(cond(substr(actor1,1,28) == "Police Forces of Afghanistan", 1, 0)))
	

	//opium prices: just use dry_op_farmgate_2015cpi and dry_op_trader_2015cpi
	est clear
	estpost tabstat fatalities_full_sample monthly_battles_country_full monthly_remoteviolence_full all_monthly_conflicts_full involving_talibans_full involving_military_full involving_police_full  , c(stat) stat(sum mean sd min max n)
	ereturn list
	
	cd "/Users/pantoine/school/m2/thesis/latex/Figures/latex_tables"
	esttab using "summarystatsfullsample.tex", replace ///
	cells("Sum Mean(fmt(%6.2fc)) SD(fmt(%6.2fc)) Min Max count") ///
	nonumber nomtitle nonote noobs label booktabs ///
	collabels("Sum" "Mean" "St.dev" "Min" "Max" "N") ///
	title("Summary statistics (full sample)")

	//manually add h prices to the table
	est clear
	estpost tabstat h_prices_2015cpi, c(stat) stat(sum mean sd min max n)
	ereturn list
	
			//// RESTRICTED SAMPLE \\\\
			
	drop if region_agg == "OTHER"
	
	rename fatalities_full_sample fatalities_restricted_sample

	// sum makes no sense here, delete it in the table !
	//g fatalities_restricted_sample = fatalities
	bysort event_YM: egen monthly_battles_restr = max(sum(cond(event_type == "Battles", 1, 0)))
	bysort event_YM: egen monthly_remoteviolence_restr = max(sum(cond(event_type == "Explosions/Remote violence", 1, 0)))
	bysort event_YM: gen all_monthly_conflicts_restr = _N
	
	//conflicts involving talibans/military/police
	bysort event_YM: egen involving_talibans_restr = max(sum(cond(actor1 == "Taliban", 1, 0)))
	bysort event_YM: egen involving_military_restr = max(sum(cond(substr(actor1,1,30) == "Military Forces of Afghanistan", 1, 0)))
	bysort event_YM: egen involving_police_restr = max(sum(cond(substr(actor1,1,28) == "Police Forces of Afghanistan", 1, 0)))
	
	est clear
	estpost tabstat fatalities_restricted_sample monthly_battles_restr monthly_remoteviolence_restr all_monthly_conflicts_restr involving_talibans_restr involving_military_restr involving_police_restr, c(stat) stat(sum mean sd min max n)
	ereturn list
	
	cd "/Users/pantoine/school/m2/thesis/latex/Figures/latex_tables"
	esttab using "summarystatsrestrictedsample.tex", replace ///
	cells("Sum Mean(fmt(%6.2fc)) SD(fmt(%6.2fc)) Min Max count") ///
	nonumber nomtitle nonote noobs label booktabs ///
	collabels("Sum" "Mean" "St.dev" "Min" "Max" "N") ///
	title("Summary statistics (restricted sample)")
	
restore

preserve
		
	//FOR PLOTS: different merged

	drop _merge
	//only contains region with price data, so we can get mean price for each month.
	bysort event_YM: egen mean_trader_price = mean(dry_op_trader_2015cpi)
	bysort event_YM: egen mean_farmgate_price = mean(dry_op_farmgate_2015cpi)
	bysort event_YM: egen mean_price_premium = mean(dry_op_trader_2015cpi - dry_op_farmgate_2015cpi)
	
	//get meam number of battle and remote violence for province with prices
	bysort event_YM: egen mean_battles_price = mean(total_battles_province)
	bysort event_YM: egen mean_remoteviolence_price = mean(total_remote_violence_province)
	bysort event_YM: keep if _n == 1
		
	tempfile meanprices
	save `meanprices'
	
	use acled_full_province.dta, clear
	
	merge 1:1 event_YM using `meanprices'
	keep event_YM mean_battles_price mean_remoteviolence_price mean_remoteviolence_no_price mean_battles_no_price mean_fatalities_month_price mean_conflicts_taliban_price mean_fatalities_month_no_price mean_conflicts_taliban_no_price mean_trader_price mean_farmgate_price mean_price_premium
	
	save pricevsnoprice_conflicts, replace
	export delimited pricevsnoprice_conflicts.csv, replace
restore


////////////////////////////////REGRESSIONS

ssc install outreg2

cd "/Users/pantoine/school/m2/thesis/merged_data"
use main_panel, clear

preserve
bysort event_YM region_agg: drop if _n != 1
encode region_agg, g(enc_region_agg)
xtset enc_region_agg event_time, monthly

// need lag of total battles and remote violence for the regression (REGION LEVEL)

g lag_total_battles = l.total_battles
g lag_remote_violence = l.total_remote_violence

g lag_battles_taliban = l.total_battles_taliban
g lag_remoteviolence_taliban = l.total_remoteviolence_taliban

g lag_battles_afmilitary = l.total_battles_afmilitary
g lag_remoteviolence_afmilitary = l.total_remoteviolence_afmilitary

g lag_battles_afpolice = l.total_battles_afpolice
g lag_remoteviolence_afpolice = l.total_remoteviolence_afpolice

gen diff_price = dry_op_trader_2015cpi - dry_op_farmgate_2015cpi
gen log_diff_price = log(diff_price)
gen h_premium = h_prices_2015cpi - dry_op_trader_2015cpi
gen dev_mmean_trader = dry_op_trader_2015cpi - mavg_trader
gen dev_mmean_farmgate = dry_op_farmgate_2015cpi - mavg_farmgate

// DUMMY FOR HARVEST TIME

// E S W: flowering in march/april, harvesting 2 months after MAX
// N NE: flowering in may/june/july, harvesting 2 months after MAX

g harvesting_month = cond((substr(event_YM,6,2) == "05" | substr(event_YM, 6, 2) == "06") & (region_agg == "E" | region_agg == "S" | region_agg == "W"), 1, cond((substr(event_YM,6,2) == "07" | substr(event_YM, 6, 2) == "08" | substr(event_YM, 6, 2) == "09") & (region_agg == "N" | region_agg == "NE"), 1, 0))

//could also be after before (planting time) ? look at page 21 Lind et. al

g planting_month = cond(substr(event_YM, 6, 2) == "09" | substr(event_YM, 6, 2) == "10" | substr(event_YM, 6, 2) == "11", 1, 0)

//NEW SET OF REGRESSIONS
*	Store output in latex figure

cd "/Users/pantoine/school/m2/thesis/latex/Figures/latex_tables"

* 1. Farmgate price
*	1.1 Time fixed effects: NOT SIGNIFICANT !

xtreg dry_op_farmgate_2015cpi total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice i.event_time, fe vce(robust)

*	1.1.5	no fixed effects, time trend

xtreg dry_op_farmgate_2015cpi total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice c.event_time, vce(robust)

//outreg2 using regoutput.tex, replace ctitle(Farm gate price OLS) addtext(Region FE, NO)

*	1.2 Time trend

xtreg dry_op_farmgate_2015cpi total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice c.event_time, fe vce(robust)

//outreg2 using regoutput.tex, append ctitle(Farm gate price, fixed effects) addtext(Region FE, YES)

*	1.3. Time trend add fatalities (not in table : directly add harvest month)

xtreg dry_op_farmgate_2015cpi total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice avg_fatalities_taliban avg_fatalities_afmilitary avg_fatalities_afpolice c.event_time, fe vce(robust)


*	1.4. Time trend add fatalities + harvesting_month

xtreg dry_op_farmgate_2015cpi total_battles_taliban  total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice avg_fatalities_taliban avg_fatalities_afmilitary avg_fatalities_afpolice harvesting_month c.event_time, fe vce(robust)

//uncomment below to write output to the tex file
//outreg2 using regoutput.tex, append ctitle(Farm gate price, fixed effects) addtext(Region FE, YES)

*	1.5. Time trend add fatalities + harvesting_month L2 harvesting month used as Z on total taliban battles

xtivreg dry_op_farmgate_2015cpi (total_battles_taliban = l.harvesting_month) total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice avg_fatalities_taliban avg_fatalities_afmilitary avg_fatalities_afpolice c.event_time, fe vce(robust)

* 2. Trader price
*	2.1 Time fixed effects: NOT SIGNIFICANT !

xtreg dry_op_trader_2015cpi total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice i.event_time, fe vce(robust)

*	2.1.5 Time trend, NO FIXED EFFECTS

xtreg dry_op_trader_2015cpi total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice c.event_time, vce(robust)

//outreg2 using regoutput.tex, append ctitle(Trader price, OLS) addtext(Region FE, NO)

*	2.2 Time trend

xtreg dry_op_trader_2015cpi total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice c.event_time, fe vce(robust)

//uncomment below to write output to the tex file
//outreg2 using regoutput.tex, append ctitle(Trader price, FE) addtext(Region FE, YES)

*	2.3 Time trend, add fatalities + harvestmonth
	
	xtreg dry_op_trader_2015cpi total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice avg_fatalities_taliban avg_fatalities_afmilitary avg_fatalities_afpolice c.event_time harvesting_month, fe vce(robust)

//uncomment below to write output to the tex file
//outreg2 using regoutput.tex, append ctitle(Trader price, FE) addtext(Region FE, Yes)
	
* 3. Trader-Farmgate
*	3.1 Time fixed effects: NOT SIGNIFICANT !

xtreg diff_price total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice i.event_time, fe vce(robust)

*	3.1.5 Time trend NO FIXED EFFECTS

xtreg diff_price total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice c.event_time, vce(robust)

//uncomment below to write output to the tex file
outreg2 using regoutputappendix.tex, replace ctitle(Price premium, FE) addtext(Region FE, No)

*	3.2 Time trend

xtreg diff_price total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice c.event_time, fe vce(robust)

//uncomment below to write output to the tex file
outreg2 using regoutputappendix.tex, append ctitle(Price premium, FE) addtext(Region FE, Yes)

*	3.3 Time trend, add fatalities + harvesting month

xtreg diff_price total_battles_taliban total_remoteviolence_taliban lag_battles_taliban lag_remoteviolence_taliban total_battles_afmilitary total_remoteviolence_afmilitary lag_battles_afmilitary lag_remoteviolence_afmilitary total_battles_afpolice total_remoteviolence_afpolice lag_battles_afpolice lag_remoteviolence_afpolice avg_fatalities_taliban avg_fatalities_afmilitary avg_fatalities_afpolice c.event_time harvesting_month, fe vce(robust)

//uncomment below to write output to the tex file
outreg2 using regoutputappendix.tex, append ctitle(Price premium, FE) addtext(Region FE, Yes)

//uncomment below to write output to the tex file

restore

//old regressions
xtreg dev_mmean_trader battle_weight remote_violence_weight, fe cluster(region_agg)
xtreg diff_price battle_weight remote_violence_weight, fe cluster(region_agg)
xtreg log_diff_price battle_weight remote_violence_weight avg_fatalities_taliban, fe cluster(region_agg)
xtreg h_premium battle_weight remote_violence_weight avg_fatalities_taliban, fe cluster(region_agg)
xtreg log_diff_price taliban_actor_weight remote_violence_weight avg_fatalities_taliban h_prices_2015cpi, fe cluster(region_agg)

