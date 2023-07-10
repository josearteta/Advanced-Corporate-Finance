// Advanced Credit Markets Assignment 2

// Import data
use "/Users/bernardo/Documents/Economics/Mestrado EPGE/Advanced Corporate Finance/Assignments/Assignment 2/MergedDatabaseAssignment2.dta"

// Declare data to be time-series data
tsset id year

// Generate Leverage
gen Leverage = (TotalCurrentDebt + LongTermDebt) / TotalAssets

// Generate LagPPEnt
gen LagPPEnt = NetPropertyPlantEquipment[_n-1]

// Generate CashFlow
gen CashFlow = (IncomeBefore + DepreciationAmort) / LagPPEnt

// Generate Tangibility
gen Tangibility = NetPropertyPlantEquipment / TotalAssets

// Generate Size
gen Size = log(TotalAssets)

// Generate Q
gen Q = (TotalAssets + MarketCapitalization - BookValueShare - DeferredTaxAssetsCurr) / TotalAssets

// Generate Investment 
gen Investment = (CapitalExpenditure - SaleofProperty) / LagPPEnt

// Generate Z
gen Z = (3.3 * PretaxIncome + Revenue + 1.4 * RetainedEarnings + 1.2 * (TotalCurrentAssets - TotalCurrentLiabilities)) / TotalAssets

// Detailed summary statistics
sum Investment CashFlow Q Size Leverage Tangibility Z, d

// Detailed summary statistics by industry
bysort SICCodes: sum Investment CashFlow Q Size Leverage Tangibility Z, d

// Correlations
pwcorr Investment Q CashFlow Leverage Tangibility Size Z, star(.05)

// Winsorize variables
winsor2 Investment CashFlow Q Size Leverage Tangibility Z, cuts (5 95)

// Basic Box Graph (Winsorized)
graph box Investment_w CashFlow_w Q_w Size_w Leverage_w Tangibility_w Z_w

// Regression FE (Winsorized)
reg Investment_w Q_w CashFlow_w i.id i.year
