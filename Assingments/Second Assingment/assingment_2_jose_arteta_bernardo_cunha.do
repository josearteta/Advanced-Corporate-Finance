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




* Regression Analysis

// OLS regression 
reg Investment Q  CashFlow i.id i.year, robust
eststo: est store model1 // exporting tex
esttab model1 using my_regression_output.tex, keep(_cons Q Investment) replace

// OLS regression - Winsorization
winsor2 Investment Q  CashFlow,  cuts (5 95)
reg Investment_w Q_w CashFlow_w i.id i.year, robust
eststo: est store model2 // exporting tex

// OLS regression - Trim
winsor2 Investment Q  CashFlow,  cuts (5 95) trim
reg Investment_tr Q_tr CashFlow_tr i.id i.year, robust
eststo: est store model3 // exporting tex

// Fixed Effects regression - by year and firm
reghdfe Investment Q  CashFlow , absorb(id year)
eststo: est store model4 // exporting tex
esttab model4 using fe_ols.tex, replace // exporting tex

// Fixed Effects regression - Winsorization
reghdfe Investment_w Q_w CashFlow_w , absorb(id year)
eststo: est store model5 // exporting tex

// OFixed Effects regression - Trim
reghdfe Investment_tr Q_tr CashFlow_tr , absorb(id year)
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

* Nearest neighbor matching. Match with just 1 
nnmatch Investment insample Size Leverage Tangibility Z, exact(SICCodes_num) tc(att) m(1) keep(filename) replace

 
 
 * Nearest neighbor matching. Match with just 1 
nnmatch Investment insample Size Leverage Tangibility Z, exact(SICCodes_num) tc(att) m(4) keep(filename) replace

 
 
 
 
 
 
 