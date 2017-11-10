*****Create first-differenced and related variables*****
clear all
set memory 2G
use $data/walz_merged, replace
capture drop _merge

drop if year<1985
*Convert pwages to real 2000$ dollars
replace pwages=(2.295/(10000*cpily))*pwages

***PIAT test variables
replace piamatsn=. if piamats==0
replace piarecsn=. if piarecs==0
replace piarersn=. if piarers==0

gen piaave=(piamatsn+piarersn+piarecsn)/3
sum piaave if samprandom
replace piaave=(piaave-r(mean))/r(sd)

*Shorter PIAT variable names
rename piamatsn math
rename piarersn rer
rename piarecsn rec
rename piaave mathread

sort idchild year
xtset idchild year, yearly delta(1)

//Lundstrom: flag families with two+ kids in lagged year
gen kid2p=0 
replace kid2p=1 if L2.depchild>=2

*Take second difference of piat variables
local vars "math rer rec mathread"
  foreach var of varlist `vars' {
  gen d02`var' = `var'-L2.`var'
}

gen getdiv13=L1.marrlyimp==0 & (L2.marrlyimp==1|L3.marrlyimp==1)
gen getdiv24=L2.marrlyimp==0 & (L3.marrlyimp==1|L4.marrlyimp==1)
gen getmarr13=L1.marrlyimp==1 & (L2.marrlyimp==0|L3.marrlyimp==0)
gen getmarr24=L2.marrlyimp==1 & (L3.marrlyimp==0|L4.marrlyimp==0)
gen getdiv04=getdiv02|getdiv13|getdiv24
gen getmarr04=getmarr02|getmarr13|getmarr24

***differences with various lags for income variables
gen d02inc012 = inc012 - L2.inc012
gen d13inc012 = L1.inc012 - L3.inc012
gen d24inc012 = L2.inc012 - L4.inc012

***IV variables
gen d02eitcsim211new=eitc211 - L2.eitc011 + stateeitc211 - L2.stateeitc011
gen d02eitcsim311new=eitc311 - L2.eitc011 + stateeitc311 - L2.stateeitc011
gen d02eitcsim411new=eitc411 - L2.eitc011 + stateeitc411 - L2.stateeitc011
gen d02eitcsim811new=eitc811 - L2.eitc011 + stateeitc811 - L2.stateeitc011 //Lundstrom: IV with fixed schedule (i.e. 1 vs 2+ kids)across differenced years 
*gen d02eitcsim911new=eitc811 - L2.eitc011 //Lundstrom: exclude state EITCs from IV for Figure 2 and Tables 3, A2, A3
gen d13eitcsim811new=L1.eitc611 - L3.eitc711  + L1.stateeitc611 - L2.stateeitc711 //Dahl & Lochner: IV with fixed schedule (i.e. 1 vs 2+ kids) across differenced years fixed in taxsim-eitc program 
gen d24eitcsim811new=L2.eitc011 - L4.eitc511  + L2.stateeitc211 - L4.stateeitc511 //Dahl & Lochner: IV with fixed schedule (i.e. 1 vs 2+ kids) across differenced years fixed in taxsim-eitc program 

***gen d02eitcsim911=eitc911 - L2.eitc011 + stateeitc911 - L2.stateeitc011

***replace d02eitcsim911=eitc911 - eitc811 - (L2.eitc911 - L2.eitc011)

***Other variables
gen d02nontax=non_tax_inc_couple_imputed_nom-L2.non_tax_inc_couple_imputed_nom
gen d02inc012nontax=d02inc012 + d02nontax

gen d02inc1012nontax=inc1012 - L2.inc1012 + d02nontax  //Lundstrom: corrected income 
gen d02inc2012nontax=eitc012 - L2.eitc012  //Lundstrom: EITC income only 
gen d02inc3012nontax=earn_inc_respondent_imputed_nom - L2.earn_inc_respondent_imputed_nom  //Lundstrom: maternal earnings
gen d02inc4012nontax=earn_inc_spouse_imputed_nom - L2.earn_inc_spouse_imputed_nom  //Lundstrom: paternal earnings
gen d02inc5012nontax=other_tax_inc_couple_imputed_nom - L2.other_tax_inc_couple_imputed_nom + d02nontax   //Lundstrom: unearned income + nontaxable income
gen d02inc6012nontax=d02inc012nontax - d02inc5012nontax - d02inc4012nontax - d02inc3012nontax  //Lundstrom: DL income - unearned & nontaxable income - paternal earnings - maternal earnings
gen d02inc7012nontax=d02inc1012nontax - d02inc012nontax  //Lundstrom: corrected income - DL income
gen d02inc8012nontax=d02inc1012nontax - d02inc012nontax - d02inc2012nontax  //Lundstrom: corrected income - DL income - EITC income

gen d24inc1012nontax=(L2.inc1012 + L2.non_tax_inc_couple_imputed_nom) - (L4.inc1012 + L4.non_tax_inc_couple_imputed_nom)  //Dahl & Lochner: corrected income
gen d13inc1012nontax=(L1.inc1012 + L1.non_tax_inc_couple_imputed_nom) - (L3.inc1012 + L3.non_tax_inc_couple_imputed_nom)  //Dahl & Lochner: corrected income
gen d24eitcreal=L2.eitc012 - L4.eitc012

gen dsuminc1012nontax=d13inc1012nontax+d24inc1012nontax  //Dahl & Lochner: corrected income
gen dsumeitcsim811new=d13eitcsim811new+d24eitcsim811new  //Dahl & Lochner: corrected schedule 
gen inc012nontax=inc012 + non_tax_inc_couple_imputed_nom
gen inc1012nontax=inc1012 + non_tax_inc_couple_imputed_nom  //Lundstrom & Lochner: corrected income

gen part=hrswrinew>0
gen hrs=hrswrinew
gen dpart=part-L2.part
gen dhrs=hrs-L2.hrs

***data restrictions for estimation samples
gen nonpoorsamp=(samprandom&sampnm)|sampnmblack|sampnmhisp
gen flagpretax = (2.295/(10000*cpily))*pretax_inc_couple_nom<10 & (2.295/(10000*L2.cpily))*L2.pretax_inc_couple_nom<10
gen flagtot=abs(d02inc012nontax)<4
gen dearn=earn_inc_couple_imputed_nom-L2.earn_inc_couple_imputed_nom
gen drtotwead=(2.295/10000)*(rtotweadimp2-L2.rtotweadimp2)
gen flagdwea=!(drtotwead<-.25 & (dearn<-drtotwead)) & !(drtotwead>.25 & drtotwead<. & (dearn>-drtotwead))
gen estsamp=nonpoorsamp & flagdwea & year>=1989 & !getmarr02 & !getdiv02 & flagtot & flagpretax
quietly ivregress 2sls d02mathread (d02inc012nontax = d02eitcsim411new) x0 x1 x2 x3 x4 x5 $grpbase if estsamp, cluster(momid) first
capture drop esamp
gen esamp0=e(sample)

gen dearn5=(L2.test-L4.test)
gen drtotwead5=(2.295/10000)*(L2.rtotweadimp2-L4.rtotweadimp2)
gen flagdwea5=!(drtotwead5<-.25 & (dearn5<-drtotwead5)) & !(drtotwead5>.25 & drtotwead5<. & (dearn5<-drtotwead5))
gen flag5 = L2.test<10 & L4.test<10 & flagdwea5

gen dearn6=test-L1.test
gen drtotwead6=(2.295/10000)*(rtotweadimp2-L1.rtotweadimp2)
gen flagdwea6=!(drtotwead6<-.25 & (dearn6<-drtotwead6)) & !(drtotwead6>.25 & drtotwead6<. & (dearn6<-drtotwead6))
gen flag6 = year>=1989 & L1.test<10 & test<10 & flagdwea6

gen dearn7=(test-L3.test)
gen drtotwead7=(2.295/10000)*(rtotweadimp2-L3.rtotweadimp2)
gen flagdwea7=!(drtotwead7<-.25 & (dearn7<-drtotwead7)) & !(drtotwead7>.25 & drtotwead7<. & (dearn7<-drtotwead7))
gen flag7 = year>=1989 & L3.test<10 & test<10 & flagdwea7

drop dearn* drtotwead* flagdwea5 flagdwea6 flagdwea7

save $data/walz_firstdiff, replace

