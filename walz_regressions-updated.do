clear all
set memory 2G

use $data/walz_firstdiff, replace

keep if year>=1987 & year<=1999

//Dahl & Lochner: corrected income measures
*Make monetary variables be in $1,000 instead of $10,000 to match up with tables in AER paper
local vars "x0 x1 x2 x3 x4 x5 d02inc012nontax d13inc1012nontax d24inc1012nontax dsuminc1012nontax d02eitcsim411new d13eitcsim811new d24eitcsim811new dsumeitcsim811new inc012nontax  d02eitcsim211new d02eitcsim311new"
  foreach var of varlist `vars' {
  replace `var' = `var'*10
}

*//Lundstrom: make additional monetary variables be in $1,000 instead of $10,0000
local vars "inc1012nontax d02inc1012nontax d02inc2012nontax d02inc3012nontax d02inc4012nontax d02inc5012nontax d02inc6012nontax d02inc7012nontax d02inc8012nontax d02eitcsim811new"
  foreach var of varlist `vars' {
  replace `var' = `var'*10
}

save walz_estimationsample, replace

*covariates for levels and first differenced regressions
global grplevels = "black hispanic ageofrimp ed1age23 ed2age23 ed3age23 ed4age23 afqtadj afqtadjmiss marrlyimp sped* ageofsnew spmissage liveboth livebothmiss fatstg fatstgmiss motstg motstgmiss numofa numofamiss hgcbyf79 hgcbyfmis hgcbym79 hgcbymmis"
global grpbase = "male age_of_child ddd1 ddd3 black hispanic"

capture log close
log using $out/tables, text replace

*****Table 1
*Create sample for this table which only includes observations used in the baseline regression
*To include the 1987 observations, use the lagged income and eitc variables in 1989
clear
use walz_estimationsample, replace
gen inctot=inc1012nontax  //Dahl & Lochner: corrected income
gen eitctot=eitc012+stateeitc012
gen flagf2=F2.eitctot!=. & F2.esamp0 & year==1987
gen esamp1 = esamp0 | flagf2
*note: statistics for 1987-1999 are referred to as 1988-2000 in Table 1
*Number of children
tab year if esamp1
*Median lagged family income
centile inctot if esamp1  //Dahl & Lochner: corrected income
bys year: centile inctot if esamp1  //Dahl & Lochner: corrected income
*Fraction of children in EITC eligible families
gen elig=eitctot!=. & eitctot!=0 if esamp1
tab year if esamp1, sum(elig)
*Median EITC payment if eligible (divided by $10,000)
centile eitctot if elig & esamp1
bys year: centile eitctot if elig & esamp1
*EITC payment as a fraction of family income if eligible
gen fraction=eitctot/inctot
*1 child families
tab year if maxndeply==1 & elig & esamp1, sum(fraction)
*2 child families
tab year if maxndeply>=2 & elig & esamp1, sum(fraction)

*****Table 5 (with cluster-robust joint F-statistics)
*****Also used for Online Appendix Tables

*//Dahl & Lochner: changed to correct income measure and fixed number of kids for eitc schedules throughout 

*column 1
ivregress 2sls d02mathread (d02inc1012nontax d13inc1012nontax = d02eitcsim811new d13eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if estsamp & year>=1991 & flag6 & flag7 & !getmarr13 & !getdiv13, cluster(momid) first
lincom d02inc1012nontax+d13inc1012nontax
gen esamp13=e(sample)
regress d02inc1012nontax d02eitcsim811new d13eitcsim811new x0 x1 x2 x3 x4 x5 $grpbase if esamp13, cluster(momid)
testparm *eitc*
regress d13inc1012nontax d02eitcsim811new d13eitcsim811new x0 x1 x2 x3 x4 x5 $grpbase if esamp13, cluster(momid)
testparm *eitc*

*column 3
ivregress 2sls d02mathread (d02inc1012nontax dsuminc1012nontax = d02eitcsim811new dsumeitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if estsamp & year>=1991 & !getdiv04 & !getmarr04 & flag5 & flag6 & flag7 & !getmarr13 & !getdiv13, cluster(momid) first
lincom d02inc1012nontax+2*dsuminc1012nontax
gen esamp1324=e(sample)
regress d02inc1012nontax d02eitcsim811new dsumeitcsim811new x0 x1 x2 x3 x4 x5 $grpbase if esamp1324, cluster(momid)
testparm *eitc*
regress dsuminc1012nontax d02eitcsim811new dsumeitcsim811new x0 x1 x2 x3 x4 x5 $grpbase if esamp1324, cluster(momid)
testparm *eitc*

*column 2
ivregress 2sls d02mathread (d02inc1012nontax d13inc1012nontax d24inc1012nontax = d02eitcsim811new d13eitcsim811new d24eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if estsamp & year>=1991 & !getdiv04 & !getmarr04 & flag5 & flag6 & flag7 & !getmarr13 & !getdiv13, cluster(momid) first
lincom d02inc1012nontax+d13inc1012nontax+d24inc1012nontax
regress d02inc1012nontax d02eitcsim811new d13eitcsim811new d24eitcsim811new x0 x1 x2 x3 x4 x5 $grpbase if esamp1324, cluster(momid)
testparm *eitc*
regress d13inc1012nontax d02eitcsim811new d13eitcsim811new d24eitcsim811new x0 x1 x2 x3 x4 x5 $grpbase if esamp1324, cluster(momid)
testparm *eitc*
regress d24inc1012nontax d02eitcsim811new d13eitcsim811new d24eitcsim811new x0 x1 x2 x3 x4 x5 $grpbase if esamp1324, cluster(momid)
testparm *eitc*

*****Table 2
xtset idchild year
gen suminc1012nontax = L1.inc1012nontax+L2.inc1012nontax //Dahl & Lochner: fix income

*//Dahl & Lochner: changed to correct income measure throughout

*Panel 1 (levels)
regress mathread inc1012nontax $grpbase $grplevels trend if esamp0, cluster(momid)
regress mathread inc1012nontax L1.inc1012nontax $grpbase $grplevels trend if esamp13, cluster(momid)
lincom inc1012nontax+L1.inc1012nontax
regress mathread inc1012nontax L1.inc1012nontax L2.inc1012nontax $grpbase $grplevels trend if esamp1324, cluster(momid)
lincom inc1012nontax+L1.inc1012nontax + L2.inc1012nontax
regress mathread inc1012nontax suminc1012nontax $grpbase $grplevels year if esamp1324, cluster(momid)
lincom inc1012nontax+2*suminc1012nontax

*Panel 2 (differences)
regress d02mathread d02inc1012nontax $grpbase if esamp0, cluster(momid)
regress d02mathread d02inc1012nontax d13inc1012nontax $grpbase if esamp13, cluster(momid)
lincom d02inc1012nontax+d13inc1012nontax
*regress d02mathread d02inc1012nontax d24inc1012nontax $grpbase if esamp24, cluster(momid)
regress d02mathread d02inc1012nontax d13inc1012nontax d24inc1012nontax $grpbase if esamp1324, cluster(momid)
lincom d02inc1012nontax+d13inc1012nontax+d24inc1012nontax
regress d02mathread d02inc1012nontax dsuminc1012nontax $grpbase if esamp1324, cluster(momid)
lincom d02inc1012nontax+2*dsuminc1012nontax

*****Table 3

*//Dahl & Lochner: changed to correct income measure and fixed number of kids for eitc schedules throughout 

ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0, cluster(momid) first
ivregress 2sls d02math (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0, cluster(momid) first
ivregress 2sls d02rer (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0, cluster(momid) first
ivregress 2sls d02rec (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0, cluster(momid) first

*****Table 4

*//Dahl & Lochner: changed to correct income measure and fixed number of kids for eitc schedules throughout 

*Year dummies (year dummies also in 0 stage)
ivregress 2sls d02mathread (d02inc1012nontax=d02eitcsim311new) x0 x1 x2 x3 x4 x5 $grpbase yy* if estsamp, cluster(momid) first
*Trend (trend also in 0 stage)
ivregress 2sls d02mathread (d02inc1012nontax=d02eitcsim211new) x0 x1 x2 x3 x4 x5 $grpbase trend if estsamp, cluster(momid) first
ivregress 2sls d02mathread (d02inc1012nontax=d02eitcsim211new) x0 x1 x2 x3 x4 x5 $grpbase trend trendx* if estsamp, cluster(momid) first
ivregress 2sls d02mathread (d02inc1012nontax=d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase postaccount postaccountx* if estsamp, cluster(momid) first
ivregress 2sls d02mathread (d02inc1012nontax=d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase postwelfare postwelfarex* if estsamp, cluster(momid) first
ivregress 2sls d02mathread (d02inc1012nontax=d02eitcsim211new) x0 x1 x2 x3 x4 x5 $grpbase trend trendx* postaccount postaccountx* postwelfare postwelfarex* if estsamp, cluster(momid) first

*****Table 6
*50th percentiles (kid-based, not mom based)
centile afqtadj if esamp0
gen lowafqt=afqtadj<=-.5715607
gen eitcrange=x1<=30

ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & (ed1age23|ed2age23), cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & !(ed1age23|ed2age23), cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & (black|hispanic), cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & !(black|hispanic), cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & marrlyimp==0, cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & marrlyimp==1, cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & lowafqt & !afqtadjmiss, cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & !lowafqt & !afqtadjmiss, cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & age_of_child<12, cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & age_of_child>=12, cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & male, cluster(momid) first
sum eitcrange if e(sample)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 & !male, cluster(momid) first
sum eitcrange if e(sample)

*****Table 7
*A: Bigger set of control variables
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase $grplevels trend postaccount postwelfare if esamp0, cluster(momid) first
*B: No control variables (except for control function, i.e., polynomial in lagged earnings)
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 if esamp0, cluster(momid) first
*C: Interact control function with all regressors
replace x5=x5/1000
foreach var1 of varlist $grpbase {
  foreach var2 of varlist x0 x1 x2 x3 x4 x5 {
    gen gb`var1'`var2' = `var1'*`var2'
  }
}
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase gb* if esamp0, cluster(momid) first
replace x5=x5*1000
*D: State Dummies
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase ss* if esamp0, cluster(momid) first
*E: Use NLSY-supplied weights
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0 [weight=weight], cluster(momid) first
*F: Log family income measure
gen d02lninc012nontax=ln(inc012nontax) - ln(L2.inc012nontax)
gen d02lneitcsim411new=ln(eitc411+stateeitc411) - ln(L2.eitc011+L2.stateeitc011)
ivregress 2sls d02mathread (d02lninc012nontax = d02eitcsim811new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0, cluster(momid) first
ivregress 2sls d02mathread (d02lninc012nontax = d02lneitcsim411new) x0 x1 x2 x3 x4 x5 $grpbase if esamp0, cluster(momid) first
*G: Labor supply
ivregress 2sls d02mathread (d02inc1012nontax = d02eitcsim811new) dpart dhrs x0 x1 x2 x3 x4 x5 $grpbase if esamp0, cluster(momid) first

*****Table A1
*Baseline variables (in differences regressions)
gen ddd2=!ddd1 & !ddd3
*note: differences & statistical significance between categories can be calculated by hand, using the supplied robust s.e.'s
mean $grpbase ddd2 year if esamp1, vce(cluster idchild)
mean $grpbase ddd2 year if !elig & esamp1, vce(cluster idchild)
mean $grpbase ddd2 year if elig & esamp1, vce(cluster idchild)
drop ddd2

*Additional variables for levels regressions (and for robustness table)
*note: if a variable appears here and above (i.e., in baseline variables $grpbase) report in baseline panel and not here
*note: differences & statistical significance between categories can be calculated by hand, using the supplied robust s.e.'s
mean $grplevels if esamp1, vce(cluster idchild)
mean $grplevels if !elig & esamp1, vce(cluster idchild)
mean $grplevels if elig & esamp1, vce(cluster idchild)

*Spouse variables conditional on mother being married
mean marrlyimp sped* ageofsnew spmissage if esamp1 & marrlyimp, vce(cluster idchild)
mean marrlyimp sped* ageofsnew spmissage if !elig & esamp1 & marrlyimp==1, vce(cluster idchild)
mean marrlyimp sped* ageofsnew spmissage if elig & esamp1 & marrlyimp==1, vce(cluster idchild)

*number of child-year observations
xtset idchild year
xtdescribe if esamp1
xtdescribe if !elig & esamp1
xtdescribe if elig & esamp1

log close
