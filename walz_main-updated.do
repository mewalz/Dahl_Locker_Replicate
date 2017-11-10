*****Stata programs to correct a coding error and update the tables in Dahl and Lochner "The Impact of Family Income on Child Achievement: Evidence from the Earned Income Tax Credit"
*****Original paper published in the American Economic Review (2012, 102:5)

*****Please read "Correction and Addendum to `The Impact of Family Income on Child Achievement: Evidence from the Earned Income Tax Credit'"
*****That note explains what happened and provides a new set of tables

*****Note 1: These programs use as inputs main.dta (data from the NLSY) and welfare_data.csv (data on state school accountability and welfare reforms)
*****Note 2: Since the variable for "state" is only available in the restricted use version of the NLSY, in main.dta this variable is set to 0
*****Note 3: Those interested in using information on the state must apply for access to the restricted NLSY and merge this variable into the dataset
*****Note 4: Without the state variable, the results will not match the reported results exactly

global prog = "E:\UH\Dahl_Lockner\Code"
global data = "E:\UH\Dahl_Lockner\Data"
global out = "E:\UH\Dahl_Lockner\Work"

*Setup
set more off
clear all
set matsize 800

*Step 1: Send data to taxsim and get eitc
do $prog/walz_taxsim-eitc-updated.do

*Step 2: Merge in state data for school accountability and welfare reforms
*Note that this only works if you have the "state" variable merged in from the restricted NLSY dataset
do $prog/walz_merge-school-welfare.do

*Step 3: Create first-differenced data and other covariates
do $prog/walz_makevars-updated.do

*Step 4: Run regressions to replicate tables
do $prog/walz_regressions-updated.do
