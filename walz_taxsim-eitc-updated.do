*****Prepare data for calculation of EITC, send to TAXSIM, and create dataset for IV
//MW comments in this style "//"
//This program creates an instrument for expected pretax income by regressing on a 5th degree polynomial. 
//It then takes the predicted income and runs it through taxsim9 to determine tax liability and eitc

**Changes to original program denoted with //Dahl & Lochner or //Lundstrom
set more off
cd $data

/*
The following variables are used in taxsim9 (and must be kept with these names when using taxsim9):

	year
	state
	mstat
	depx
	agex
	pwages
	swages
	dividends
	otherprop
	pensions
	gssi
	transfers
	rentpaid
	proptax
	otheritem
	childcare
	ui
	depchild
	motgage
	stcg
	ltcg
help taxsim9 for descriptions of each variable
I'm moving the renaming of these variable to the end of the code	
*/
	
	

*****Setup

*Baseline without state
**001 is wage income only
**002 is wage plus unearned income
**012, 011 include state taxes and credits

******
foreach j in 012 011 211 311 411 511 611 711 811 {  //Lundstrom: added 811

***KEY to datasets***
*hat=0: real data, hat=4: baseline predicted, hat=2,3 needed for Table 4, hat=5,6,7 needed for Table 5
*state=0: no state tax information calculated, state=1: state taxes included
*spec=1: excludes unearned income, spec2: includes unearned income
local hat=substr("`j'",1,1)
local state=substr("`j'",2,1)
local spec=substr("`j'",3,1)

use $data/main-nostate, replace
sort idchild year

*IMPORTANT NOTE: all income variables are in 1979 dollars, and need to be converted to nominal dollars before sending through taxsim
*(convert to nominal dollars by multiplying by cpily)
rename earnincrimp earn_inc_respondent_imputed
rename earnincsimp earn_inc_spouse_imputed
//couple = respondent + spouse
rename earnincrsimp earn_inc_couple_imputed
rename unearnincrsimp unearn_tax_inc_couple_imputed
rename nontaxincrsimp non_tax_inc_couple_imputed
rename marrlyimp married_currently_imputed
rename yrsbirth age_of_child


gen earn_inc_respondent_imputed_nom = earn_inc_respondent_imputed * cpily
gen earn_inc_spouse_imputed_nom = earn_inc_spouse_imputed *cpily
gen earn_inc_couple_imputed_nom = earn_inc_couple_imputed * cpily
gen other_tax_inc_couple_imputed_nom = unearn_tax_inc_couple_imputed * cpily
gen non_tax_inc_couple_imputed_nom = non_tax_inc_couple_imputed * cpily


gen pretax_inc_couple_nom = earn_inc_couple_imputed_nom + other_tax_inc_couple_imputed_nom + non_tax_inc_couple_imputed_nom

*****As needed, make variable changes or sample restrictions

*note: one year already subtracted off to reflect that NLSY reports lagged income
gen trend=year-1986

***Set state variable to missing if necessary (for state=0 samples)
replace state=0 if `state'==0

*****Sample restrictions
gen samp=1
//the following two lines appear to have no effect. I assume they are there as a double check.
replace samp = (year==1985|year==1987|year==1989|year==1991|year==1993|year==1995|year==1997|year==1999) & (piamatsn!=. | piarecsn!=. | piarersn!=.) if `hat'==2 | `hat'==3 | `hat'==4 | `hat'==5
replace samp = samp | (year==1988|year==1990|year==1992|year==1994|year==1996|year==1998) if `hat'==6 | `hat'==7

sort idchild year
xtset idchild year, yearly delta(1)

*create variables for SIV and to define sample
//2.295 is the cpily value for 1999 when adjusting from 1978 dollars
//so this appears to scale income down by 10,000 1999 dollars
gen test=(2.295/(10000*cpily))*earn_inc_couple_imputed_nom
gen x0=L2.test==0
gen x1=L2.test
gen x2=x1^2
gen x3=x1^3
gen x4=x1^4
gen x5=x1^5

gen got_divorced_prev_2yr = married_currently_imputed==0 & (L1.married_currently_imputed==1|L2.married_currently_imputed==1)
gen got_married_prev_2yr = married_currently_imputed==1 & (L1.married_currently_imputed==0|L2.married_currently_imputed==0)

//flag those with incomes less than $100,000 (1999 dollars) respondent + spouse income in past 2 years
gen flag1 = (2.295/(10000*cpily))*pretax_inc_couple_nom<10 & (2.295/(10000*L2.cpily))*L2.pretax_inc_couple_nom<10
//flag those who haven't changed marital status in past 2 years and incomes under 100k
gen flag = year>=1989 & !got_married_prev_2yr & !got_divorced_prev_2yr & flag1 if `hat'==2 | `hat'==3 | `hat'==4 | `hat'==6 | `hat'==7
replace flag = year>=1987 & !got_married_prev_2yr & !got_divorced_prev_2yr & flag1 if `hat'==5

keep if samp

*drop poor oversample
keep if ((samprandom&sampnm)|sampnmblack|sampnmhisp) | (year==1994|year==1996|year==1998)

*****Get predicted income

*Need to have earned income (for eitc credit) and unearned income (for location on eitc schedule)
gen predict_earned_inc_nom=.
gen predicted_other_inc=.

*Use actual data (for hat=0 samples)
*********I changed this!************************
***replace predict_earned_inc_nom=earn_inc_couple_imputed_nom + 3000 if `hat'==0
replace predict_earned_inc_nom=earn_inc_couple_imputed_nom if `hat'==0
replace predicted_other_inc=other_tax_inc_couple_imputed_nom if `hat'==0

*for Table 3
*year trend
if `hat'==2 {
  reg test x0 x1 x2 x3 x4 x5 trend if samp & flag
  predict predict_earned_inc if samp & flag
  replace predict_earned_inc_nom=predict_earned_inc*((10000*cpily)/2.295) if samp & flag

  //Dahl & Lochner: keep tax schedule constant
  gen depchild_2=depchild 
  replace depchild_2=L2.depchild if L2.depchild>0 & L2.depchild!=.  
  replace depchild=depchild_2 
  replace depx=depchild_2  
  drop depchild_2
 }

*for Table 3
*year dummies
if `hat'==3 {
  reg test x0 x1 x2 x3 x4 x5 yy* if samp & flag
  predict predict_earned_inc if samp & flag
  replace predict_earned_inc_nom=predict_earned_inc*((10000*cpily)/2.295) if samp & flag

  //Dahl & Lochner: keep tax schedule constant
  gen depchild_2=depchild 
  replace depchild_2=L2.depchild if L2.depchild>0 & L2.depchild!=.  
  replace depchild=depchild_2 
  replace depx=depchild_2  
  drop depchild_2
}

*baseline
if `hat'==4 {
  reg test x0 x1 x2 x3 x4 x5 if samp & flag
  predict predict_earned_inc if samp & flag
  replace predict_earned_inc_nom=predict_earned_inc*((10000*cpily)/2.295) if samp & flag
}

*for Table 5
if `hat'==5 {
  gen f0=F2.test==0
  gen f1=F2.test
  gen f2=f1^2
  gen f3=f1^3
  gen f4=f1^4
  gen f5=f1^5

  reg test f0 f1 f2 f3 f4 f5 if samp & flag
  predict predict_earned_inc if samp & flag
  replace predict_earned_inc_nom=predict_earned_inc*((10000*cpily)/2.295) if samp & flag
  
  //Dahl & Lochner: keep tax schedule constant
  gen depchild_2=depchild 
  replace depchild_2=L2.depchild if L2.depchild>0 & L2.depchild!=.  
  replace depchild=depchild_2 
  replace depx=depchild_2  
  drop depchild_2
}

*for Table 5
if `hat'==6 {
  gen f0=L1.test==0
  gen f1=L1.test
  gen f2=f1^2
  gen f3=f1^3
  gen f4=f1^4
  gen f5=f1^5

  reg test f0 f1 f2 f3 f4 f5 if samp & flag & (year==1987|year==1989|year==1991|year==1993|year==1995|year==1997|year==1999) & (piamatsn!=. | piarecsn!=. | piarersn!=.)
  predict predict_earned_inc if samp & flag 
  replace predict_earned_inc_nom=predict_earned_inc*((10000*cpily)/2.295) if samp & flag 
  
  //Dahl & Lochner: keep tax schedule constant
  gen depchild_2=depchild 
  replace depchild_2=L2.depchild if L2.depchild>0 & L2.depchild!=.  
  replace depchild=depchild_2 
  replace depx=depchild_2  
  drop depchild_2
}

*for Table 5
if `hat'==7 {
  gen f0=F1.test==0
  gen f1=F1.test
  gen f2=f1^2
  gen f3=f1^3
  gen f4=f1^4
  gen f5=f1^5
  
  reg test f0 f1 f2 f3 f4 f5 if samp & flag & (year==1987|year==1989|year==1991|year==1993|year==1995|year==1997|year==1999) & (piamatsn!=. | piarecsn!=. | piarersn!=.)
  predict predict_earned_inc if samp & flag
  replace predict_earned_inc_nom=predict_earned_inc*((10000*cpily)/2.295) if samp & flag
  
  //Dahl & Lochner: keep tax schedule constant
  gen depchild_2=depchild 
  replace depchild_2=L2.depchild if L2.depchild>0 & L2.depchild!=.  
  replace depchild=depchild_2 
  replace depx=depchild_2  
  drop depchild_2
}

//Lundstrom: same as `hat'==4, but changing depchild and depx to lagged year values 
if `hat'==8 {
  reg test x0 x1 x2 x3 x4 x5 if samp & flag
  predict predict_earned_inc if samp & flag
  replace predict_earned_inc_nom=predict_earned_inc*((10000*cpily)/2.295) if samp & flag
  gen depchild_2=depchild 
  replace depchild_2=L2.depchild if L2.depchild>0 & L2.depchild!=.  
  replace depchild=depchild_2 
  replace depx=depchild_2  
  drop depchild_2   
}

gen oldyear=year

*****Replace pwages and ui with predicted values predict_earned_inc_nom and predicted_other_inc and save pre-eitc dataset

replace swages=0
replace pwages=predict_earned_inc_nom
replace ui=predicted_other_inc 

*Set non-wage income (unearn_tax_inc_couple_imputed_nom, which we are feeding through taxsim as "ui") equal to zero if necessary (for spec=1 samples)
replace ui=0 if `spec'==1
********
replace pwages=0 if pwages==.
//Lundstrom: for some reason I have problems in some runs if I don't add this line
********
drop predict_earned_inc_nom predicted_other_inc

*Save pre-eitc master dataset, using real data, for later merging in future program
if "`j'"=="012" {
  save $data/walz_preeitcinput, replace
}

keep idchild cpily year state mstat depx agex pwages swages dividends otherprop pensions gssi transfers rentpaid proptax otheritem childcare ui number_depedent_children mortgage stcg ltcg oldyear

*Note: don't send idchild to taxsim if using state identifiers

*****Send data to TAXSIM and get after tax income and EITC

taxsim9, replace full

replace year=oldyear

sort idchild year
save $data/walz_taxsimout`j', replace

}

*****Now rename taxsim variables and merge taxsim datasets together

*****Rename variables from taxsim output

local datasets 012 011 211 311 411 511 611 711 811 //Lundstrom: included 811

foreach i of local datasets {
  use $data/walz_taxsimout`i', replace
  rename v10 fedagi
  rename v25 eitc
  rename v28 fedinctax
  rename v39 stateeitc
  rename v40 statetotcredit
  keep idchild year fedagi eitc fedinctax stateeitc statetotcredit siitax cpily pwages otherprop fiitax //Lundstrom: included fiitax

  *Put dollar values back in real terms (2000 dollars, so divide by cpily and multiply by 2.295) and divide all monetary variables by 10,000
  local vars "fedagi eitc fedinctax stateeitc statetotcredit siitax pwages fiitax"  //Lundstrom: included fiitax
    foreach var of varlist `vars' {
    qui replace `var' = `var'*(2.295/(10000*cpily))
  }

  *Create income variables
  gen inc=fedagi-fedinctax-siitax+statetotcredit
  gen inc1=fedagi-fiitax-siitax  //Lundstrom: correctly measured income
  gen incnotax=pwages+eitc
  gen tax=fedagi-eitc

  *rename variables with appropriate extension
  local vars "fedagi eitc fedinctax stateeitc statetotcredit siitax pwages inc incnotax tax inc1"  //Lundstrom: included inc1
  foreach var of varlist `vars' {
    rename `var' `var'`i'
  }

  save $data/walz_taxsim`i', replace
}

*****Merge all datasets together
*Start with preeitcinput for real data
use $data/walz_preeitcinput, replace
sort idchild year

foreach dataset of local datasets {
  merge idchild year using $data/taxsim`dataset'
  tab _merge
  drop _merge
  sort idchild year
}

*Now for additional variables, put back in real terms (into 2000 dollars, so divide by cpily and multiply by 2.295) and divide all monetary variables by 10,000
  local vars "ui otherprop non_tax_inc_couple_imputed_nom earn_inc_couple_imputed_nom unearn_tax_inc_couple_imputed_nom earned_income_respondent_imputed earn_inc_spouse_imputed_nom"  //Lundstrom: included earned_income_respondent_imputed and earn_inc_spouse_imputed_nom
    foreach var of varlist `vars' {
    replace `var' = `var'*(2.295/(10000*cpily))
  }

*Now for some variables, put into year 2000 dollars in real terms (convert from 1979 dollars to 2000 dollars, so multiply by 2.295) and divide all monetary variables by 10,000
  local vars "totweadimp2"
    foreach var of varlist `vars' {
    replace `var' = `var'/(10000*(1/2.295))
  }

//rename crappy variable names to something comprehensible
rename depchild number_depedent_children
-
save $data/walz_taxsim-merged, replace
