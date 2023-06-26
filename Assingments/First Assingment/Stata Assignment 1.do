// Importar dados
use "/Users/bernardo/Documents/Economics/Mestrado EPGE/Advanced Corporate Finance/Assignments/Assignment 1/MergedDatabaseAssignment1.dta"

// Destring TotalCurrDebt, LongTermDebt, IncomeBeforeEI, EBIT
destring TotalCurrDebt1980 TotalCurrDebt1981 TotalCurrDebt1982 TotalCurrDebt1983 TotalCurrDebt1984 TotalCurrDebt1985 TotalCurrDebt1986 TotalCurrDebt1987 TotalCurrDebt1988 TotalCurrDebt1989 TotalCurrDebt1990 TotalCurrDebt1991 TotalCurrDebt1992 TotalCurrDebt1993 TotalCurrDebt1994 TotalCurrDebt1995 TotalCurrDebt1996 TotalCurrDebt1997 TotalCurrDebt1998 TotalCurrDebt1999 TotalCurrDebt2000 TotalCurrDebt2001 TotalCurrDebt2002 TotalCurrDebt2003 TotalCurrDebt2004 TotalCurrDebt2005 TotalCurrDebt2006 TotalCurrDebt2007 TotalCurrDebt2008 TotalCurrDebt2009 TotalCurrDebt2010 TotalCurrDebt2011 TotalCurrDebt2012 TotalCurrDebt2013 TotalCurrDebt2014 LongTermDebt1980 LongTermDebt1981 LongTermDebt1982 LongTermDebt1983 LongTermDebt1984 LongTermDebt1985 LongTermDebt1986 LongTermDebt1987 LongTermDebt1988 LongTermDebt1989 LongTermDebt1990 LongTermDebt1991 LongTermDebt1992 LongTermDebt1993 LongTermDebt1994 LongTermDebt1995 LongTermDebt1996 LongTermDebt1997 LongTermDebt1998 LongTermDebt1999 LongTermDebt2000 LongTermDebt2001 LongTermDebt2002 LongTermDebt2003 LongTermDebt2004 LongTermDebt2005 LongTermDebt2006 LongTermDebt2007 LongTermDebt2008 LongTermDebt2009 LongTermDebt2010 LongTermDebt2011 LongTermDebt2012 LongTermDebt2013 LongTermDebt2014 IncomeBeforeEI1980 IncomeBeforeEI1981 IncomeBeforeEI1982 IncomeBeforeEI1983 IncomeBeforeEI1984 IncomeBeforeEI1985 IncomeBeforeEI1986 IncomeBeforeEI1987 IncomeBeforeEI1988 IncomeBeforeEI1989 IncomeBeforeEI1990 IncomeBeforeEI1991 IncomeBeforeEI1992 IncomeBeforeEI1993 IncomeBeforeEI1994 IncomeBeforeEI1995 IncomeBeforeEI1996 IncomeBeforeEI1997 IncomeBeforeEI1998 IncomeBeforeEI1999 IncomeBeforeEI2000 IncomeBeforeEI2001 IncomeBeforeEI2002 IncomeBeforeEI2003 IncomeBeforeEI2004 IncomeBeforeEI2005 IncomeBeforeEI2006 IncomeBeforeEI2007 IncomeBeforeEI2008 IncomeBeforeEI2009 IncomeBeforeEI2010 IncomeBeforeEI2011 IncomeBeforeEI2012 IncomeBeforeEI2013 IncomeBeforeEI2014 EBIT1980 EBIT1981 EBIT1982 EBIT1983 EBIT1984 EBIT1985 EBIT1986 EBIT1987 EBIT1988 EBIT1989 EBIT1990 EBIT1991 EBIT1992 EBIT1993 EBIT1994 EBIT1995 EBIT1996 EBIT1997 EBIT1998 EBIT1999 EBIT2000 EBIT2001 EBIT2002 EBIT2003 EBIT2004 EBIT2005 EBIT2006 EBIT2007 EBIT2008 EBIT2009 EBIT2010 EBIT2011 EBIT2012 EBIT2013 EBIT2014, replace force

// gerar id
gen id = _n

// reshape
reshape long TotalCurLiabilities TotalLiabilities TotalAssets NetIncome  DeprecAmort NetPropPlantEquip BookValueShare DefTaxAssetsCurr DefTaxAssetsLT MarketCap TotalCurrDebt LongTermDebt IncomeBeforeEI EBIT, i(id) j(year)

// Declare data to be time-series data
tsset id year

// gerar Leverage
gen Leverage = (TotalCurrDebt + LongTermDebt) / TotalAssets

// gerar CashFlow
gen CashFlow = (EBIT + DeprecAmort) / L.NetPropPlantEquip

// gerar Tangibility
gen Tangibility = NetPropPlantEquip / TotalAssets

// gerar Size
gen Size = log(TotalAssets)

// gerar Q
gen Q = (TotalAssets + MarketCap - BookValueShare - DefTaxAssetsCurr - DefTaxAssetsLT) / TotalAssets

// Questão 1

// detailed summary statistics
sum Leverage CashFlow Tangibility Size Q, d

// detailed summary statistics by country
bysort GeographicLocations: sum Leverage CashFlow Tangibility Size Q, d

// detailed summary statistics by industry
bysort SICCodes: sum Leverage CashFlow Tangibility Size Q, d 

// Questão 2

// correlations
pwcorr Leverage CashFlow Tangibility Size Q, star(.05)

// correlations by country
bysort GeographicLocations: pwcorr Leverage CashFlow Tangibility Size Q, star(.05)

// correlations by industry
bysort SICCodes: pwcorr Leverage CashFlow Tangibility Size Q, star(.05)
 
// Questão 3

// OLS
regress Leverage CashFlow Tangibility Size Q

// Question 4

// Install reghdfe
// ssc install reghdfe

// Install ftools
// ssc install ftools

// OLS-FE
reghdfe Leverage CashFlow Tangibility Size Q, absorb(year SICCodes id)

// Question 5

// Install winsor
// ssc install winsor 
// ssc install winsor2

// "Winsorize" all variables at the 5% and 95% cutoffs
winsor2 Leverage CashFlow Tangibility Size Q, cuts(5 95) suffix(_w)
 
// OLS winsor
regress Leverage_w CashFlow_w Tangibility_w Size_w Q_w
 
// Trim all variables at the 5% and 95% cutoffs
winsor2 Leverage CashFlow Tangibility Size Q, trim cuts (5 95) suffix(_t)

// OLS trim
regress Leverage_t CashFlow_t Tangibility_t Size_t Q_t

// Question 6

// Declare data to be time-series data
tsset id year

// OLS with independent variables lagged one period
regress Leverage L.CashFlow L.Tangibility L.Size L.Q
