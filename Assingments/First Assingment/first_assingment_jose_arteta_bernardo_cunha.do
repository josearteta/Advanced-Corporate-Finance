clear
set more off

* Change working directory
cd "C:\Users\puent\OneDrive\Área de Trabalho\Advanced Corporate Finance\Assingments\First Assingment"

* Load dataset
use "MergedDatabaseAssignment1.dta"


* There is a duplicate observations for the Millenium Plastic Corps (4579 and 4580)
* We will drop the second occurance of this duplicate and keep the first
drop if _n == 4580

* Creates id variable
gen id = _n


* Convert data form wide to long format
reshape long TotalCurLiabilities TotalLiabilities TotalAssets NetIncome DeprecAmort NetPropPlantEquip BookValueShare DefTaxAssetsCurr DefTaxAssetsLT MarketCap TotalCurrDebt LongTermDebt IncomeBeforeEI EBIT, i(id CompanyName ExchangeTicker CompanyType GeographicLocations SICCodes) j(year)




* Cleaning steps according the 

* Extract the SIC code and creates a numerical variable of it
gen SICNum = .
replace SICNum = real(regexs(0)) if regexm(SICCodes, "(\d+)")



* Convert some variables from string to double
 destring TotalCurrDebt, replace force
 destring LongTermDebt, replace force
 destring EBIT, replace force


* Creating Variables for the OLS
* Creating Leverage variable
gen Leverage = (TotalCurrDebt + LongTermDebt)/TotalAssets

* Declaring the dataset as a panel 
tsset id year

* Creating cash flow
gen CashFlow = ( EBIT + DeprecAmort) / L.NetPropPlantEquip

* Creating Tangibility
gen Tangibility = NetPropPlantEquip / TotalAssets

* Creating Size variable
gen Size = log(TotalAssets)

* Creating the Tobin's Q variable
gen Q = (TotalAssets + MarketCap - BookValueShare - DefTaxAssetsCurr - DefTaxAssetsLT) / TotalAssets




* Question 1
sum 





* Question 3
reg Leverage CashFlow Tangibility Size Q 


* Question 4


* We need to install this package in STATA
* ssc install reghdfe




reghdfe Leverage CashFlow Tangibility Size Q , absorb(year SICNum id)










