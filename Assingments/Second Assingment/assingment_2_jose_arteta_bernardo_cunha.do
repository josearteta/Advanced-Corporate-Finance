/*
Advanced Corporate Fiance - Assingment 2 
Authors: Bernardo Cunha and José Arteta
*/

clear
set more off
cls

* Set working directory
cd "C:\Users\puent\OneDrive\Área de Trabalho\Advanced Corporate Finance\Assingments\Second Assingment"

// Load Dataset
use "MergedDatabaseAssignment2.dta"




 /* note that we have decided to drop negative values (<=0) of TotalAssets since we are 
 going to use log(.) in for Size and log(.) is not defined for negative values
 */
 drop if TotalAssets <= 0
 
* Generate Leverage
gen Leverage = (TotalCurrentDebt + LongTermDebt) / TotalAssets

* Generate LagPPEnt
gen LagPPEnt = NetPropertyPlantEquipment[_n-1]

* Generate CashFlow
gen CashFlow = (IncomeBefore + DepreciationAmort) / LagPPEnt

* Generate Tangibility
gen Tangibility = NetPropertyPlantEquipment / TotalAssets

* Generate Size
gen Size = log(TotalAssets)

* Generate Q
gen Q = (TotalAssets + MarketCapitalization - BookValueShare - DeferredTaxAssetsCurr) / TotalAssets

* Generate Investment 
gen Investment = (CapitalExpenditure - SaleofProperty) / LagPPEnt

* Generate Z
gen Z = (3.3 * PretaxIncome + Revenue + 1.4 * RetainedEarnings + 1.2 * (TotalCurrentAssets - TotalCurrentLiabilities)) / TotalAssets



* Additional step - define labels of the variables for the estimation and Latex table
label variable Investment "Investment"
label variable Q "Q"
label variable CashFlow "Cash Flow"
label variable Tangibility "Tangibility"
label variable Size "Size"
label variable Z "Z-score"


* Declaring the dataset as a panel 
xtset id year

* Counting for each id how many times it appears
egen count = count(year), by(id)

* Histogram of unbalanced
hist count




/***************************
	Regression Analysis
*/**************************

// OLS regression 
reg Investment Q  CashFlow i.id i.year, robust
eststo: est store model1 // exporting tex
esttab model1 using my_regression_output.tex, keep(_cons Q CashFlow) replace

// OLS regression - Winsorization
winsor2 Investment Q  CashFlow Leverage Tangibility Z,  cuts (5 95)
reg Investment_w Q_w CashFlow_w i.id i.year, robust 
eststo: est store model2 // exporting tex

// OLS regression - Trim
winsor2 Investment Q  CashFlow Leverage Tangibility Z,  cuts (5 95) trim
reg Investment_tr Q_tr CashFlow_tr i.id i.year, robust
eststo: est store model3 // exporting tex

// Fixed Effects regression - by year and firm
quietly: reghdfe Investment Q  CashFlow , absorb(id year)
eststo: est store model4 // exporting tex
esttab model4 using fe_ols.tex, replace // exporting tex

// Fixed Effects regression - Winsorization
quietly: reghdfe Investment_w Q_w CashFlow_w , absorb(id year)
eststo: est store model5 // exporting tex

// OFixed Effects regression - Trim
quietly: reghdfe Investment_tr Q_tr CashFlow_tr , absorb(id year)
eststo: est store model6 // exporting tex


/*
Matching
*/


 // In order to make the do file reproducible, I will set the seed for the random number generator
 set seed 666

 
* Randomly choosing 1000 observations 
gen random = runiform()
sort random
generate insample =_n <= 1000


* Checking for balance:
ttest Leverage, by(insample)
ttest Size, by(insample)
ttest Tangibility, by(insample)
ttest Z, by(insample)



* Install package for propensity score matching 
* ssc install psmatch2
* ssc install nnmatch
 
 
* Creating a variable to represent numerically each industry
encode SICCodes, generate(SICCodes_num)

* Nearest neighbor matching. Match with just 1 - no winsor or trim
nnmatch Investment insample Size Leverage Tangibility Z, exact(SICCodes_num) tc(att) m(1) keep(match_1) replace
joinby id using match_1,unmatched(master)
reshape wide varlist, i(id) j(date)
swapval cashflow_w0 cashflow_w1
reshape long varlist, i(id) j(date)






* Nearest neighbor matching. Match with just 1 - winsor 
nnmatch Investment_w insample Size_w Leverage_w Tangibility_w Z_w, exact(SICCodes_num) tc(att) m(1) keep(match_1_wr) replace  
  
* Nearest neighbor matching. Match with just 1 - no winsor or trim
nnmatch Investment_tr insample Size_tr Leverage_tr Tangibility_tr Z_tr, exact(SICCodes_num) tc(att) m(1) keep(match_1_tr) replace
  
* Nearest neighbor matching. Match with 4 and Mahalanobis metric
nnmatch Investment insample Size Leverage Tangibility Z, exact(SICCodes_num) tc(att) m(4) keep(match_4)  metric(maha) replace

 * Nearest neighbor matching. Match with just 1 - winsor
nnmatch Investment_wr insample Size_wr Leverage_wr Tangibility_wr Z_wr, exact(SICCodes_num) tc(att) m(1) keep(match_4_wr)  metric(maha) replace  
  
* Nearest neighbor matching. Match with just 1 - no winsor or trim
nnmatch Investment)tr insample Size_tr Leverage_tr Tangibility_tr Z_tr, exact(SICCodes_num) tc(att) m(1) keep(match_4_tr)  metric(maha) replace
  





* Reshape


reshape long Investment Size Leverage Tangibility Z SICCodes_num, i(id) j(insample)
joinby varlist using filename, unmatched(master)
set matsize 11000






 
 
 
 