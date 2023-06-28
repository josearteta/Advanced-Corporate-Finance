clear
set more off

* Change working directory
cd "C:\Users\puent\OneDrive\Área de Trabalho\Advanced Corporate Finance\Assingments\First Assingment"

* Load dataset
use "MergedDatabaseAssignment1.dta"

/* There is a duplicate observations for the Millenium Plastic Corps (4579 and 4580)
 We will drop the second occurance of this duplicate and keep the first but there is
some information in the second occurance that is not in the first, so we will make 
a loop to replace these values in the first ocurrance that is present in the second.
Note that we manually found all variables t
*/

foreach var in TotalCurrDebt2000 TotalCurrDebt2001 TotalCurrDebt2002 TotalCurrDebt2003 TotalCurrDebt2004 TotalCurrDebt2005 TotalCurrDebt2006 LongTermDebt2000 LongTermDebt2001 LongTermDebt2002 LongTermDebt2003 LongTermDebt2004 LongTermDebt2005 LongTermDebt2006 EBIT2000 EBIT2001 EBIT2002 EBIT2003 EBIT2004 EBIT2005 EBIT2006 {
    replace `var' = `var'[4580] in 4579
}


* Droping repeated occurance
drop if _n == 4580


* Creates id variable
gen id = _n


* Convert data form wide to long format
reshape long TotalCurLiabilities TotalLiabilities TotalAssets NetIncome DeprecAmort NetPropPlantEquip BookValueShare DefTaxAssetsCurr DefTaxAssetsLT MarketCap TotalCurrDebt LongTermDebt IncomeBeforeEI EBIT, i(id CompanyName ExchangeTicker CompanyType GeographicLocations SICCodes) j(year)




* Cleaning steps according the Appendix

* Extract the SIC code and creates a numerical variable of it
gen SICNum = .
replace SICNum = real(regexs(0)) if regexm(SICCodes, "(\d+)")
drop if SICNum < 2000 | SICNum > 4000


* Convert some variables from string to double
 destring TotalCurrDebt, replace force
 destring LongTermDebt, replace force
 destring EBIT, replace force
 destring IncomeBeforeEI, replace force

* Declaring the dataset as a panel 
tsset id year

 /* note that we have decided to drop negative values (<=0) of TotalAssets since we are 
 going to use log(.) in for Size and log(.) is not defined for negative values
 */
 drop if TotalAssets <= 0
 
* Creating Variables for the OLS accroding to what was done in the Email
* Creating Leverage variable
gen Leverage = (TotalCurrDebt + LongTermDebt)/TotalAssets

* Creating cash flow
gen CashFlow = ( EBIT + DeprecAmort) / L.NetPropPlantEquip

* Creating Tangibility
gen Tangibility = NetPropPlantEquip / TotalAssets

* Creating Size variable
gen Size = log(TotalAssets)

* Creating the Tobin's Q variable
gen Q = (TotalAssets + MarketCap - BookValueShare - DefTaxAssetsCurr - DefTaxAssetsLT) / TotalAssets


* We know proceed to do perform an analysis in balanced panel
* Number of periods
local T 35
bysort id: gen byte complete = _N == `T'
drop if complete != 1


/* 
Question 1 -  Summary Statistics
*/

* summary statatiscs of the dataset
sum Leverage CashFlow Tangibility Size Q 

* In order to export the results it is important to run the 
* ssc install estout
estpost sum Leverage CashFlow Tangibility Size Q  
esttab using summary_stats.tex, replace ///
   cells("sum(fmt(%6.0fc)) mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count") nonumber ///
   nomtitle nonote noobs label collabels("Sum" "Mean" "SD" "Min" "Max" "N")

 * Export histograms of each variable
 foreach var in Leverage CashFlow Tangibility Size Q {
    histogram `var', normal bin(50) title("Histogram - `var'") name(`var', replace)
    graph export "`var'.pdf", as(pdf) replace
}

/* 
Question 2 -  Calculate pairwise correlations
*/

* Pairwise correlations
pwcorr Leverage CashFlow Tangibility Size Q

* Exporting to TeX the pairwise correlations
estpost corr Leverage CashFlow Tangibility Size Q, matrix // exporting tex
eststo correlation // exporting tex
esttab correlation  using Correlations.tex, replace not unstack compress noobs // exporting tex
        
* Export scaterrplots of leverage against each independent variable
foreach var in CashFlow Tangibility Size Q {
    twoway (scatter Leverage `var') (lfit Leverage `var'), title("Scatterplot: `var' vs. Leverage") name(`var', replace)
    graph export "`var'_scatterplot.pdf", as(pdf) replace
}

/* 
Question 3 - OLS regression
*/

* OLS regression 
reg Leverage CashFlow Tangibility Size Q 
eststo: est store model1 // exporting tex
esttab model1 using ols_reg.tex, replace // exporting tex

/* 
Question 4 - Fixed Effect regression
*/

* We need to install this package in STATA
* ssc install reghdfe

reghdfe Leverage CashFlow Tangibility Size Q , absorb(year SICNum id)
eststo: est store model2 // exporting tex
esttab model2 using fe_ols.tex, replace // exporting tex


/* 
Question 5 - Windsorized regression
*/  

* This package is required
*ssc install winsor2
 
* Windsorized regression p5th and p95th
winsor2 Leverage CashFlow Tangibility Size Q,  cuts(5 95) // winsorize at 5th and 95th percentile
reg Leverage_w CashFlow_w Tangibility_w Size_w Q_w, robust
eststo: est store model3

eststo model3 // Renaming variables to make the output better
estadd local CashFlow_w "CashFlow"
estadd local Tangibility_w "Tangibility"
estadd local Size_w "Size"
estadd local Q_w "Q"


* Trimmed regression p5th and p95th
winsor2 Leverage CashFlow Tangibility Size Q,  cuts(5 95) trim // trimmed at 5th and 95th percentile
reg Leverage_tr CashFlow_tr Tangibility_tr Size_tr Q_tr, robust
eststo: est store model4 

eststo model4 // Renaming variables to make the output better
estadd local CashFlow_tr "CashFlow"
estadd local Tangibility_tr "Tangibility"
estadd local Size_tr "Size"
estadd local Q_tr "Q"

* Exporting TeX
esttab model3 model4 using mymodels.tex, replace mlabels("Windsorized" "Trimmed") ///
varlabels(_cons "Constant") ///
nomtitle collabels(none) nonote

/*
Question 6
*/

* Lagged regression
reghdfe Leverage L.CashFlow L.Tangibility L.Size L.Q , absorb(year SICNum id)
eststo: est store model5 
esttab model5 using lagged_ols.tex, replace


/*
Question 7
*/

* Generate the initial  leverage for each firm
sort id year
by id: gen leverage_initial = Leverage[1]

* Regression with lagged variables and initial leverage
reghdfe Leverage L.CashFlow L.Tangibility L.Size L.Q leverage_initial if year > 1980, absorb(year)

* Exporting TeX
eststo: est store model5 
esttab model5 using lag_leverage.tex, replace  ///
varlabels(_cons "Constant") ///
nomtitle collabels(none) nonote
