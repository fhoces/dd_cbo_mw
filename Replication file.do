* How to get the data:
use "C:\Users\fhocesde\Documents\data\CPS\cepr_org_2013.dta", clear
 
*Following the notes here (https://cps.ipums.org/cps/outgoing_rotation_notes.shtml) I generate the weights as orgwgt/12
cap drop *_weight
gen final_weight = orgwgt/12
gen round_weight = round(orgwgt/12, 1)

* There are 1293 cases with missin values for the weigths. I delete them from the data. 
drop if orgwgt == .

*Employment categories:
global employed "empl == 1" 
global salary	"empl == 1 & selfinc == 0 & selfemp == 0"
global nhourly	"empl == 1 & selfinc == 0 & selfemp == 0 & (paidhre == 0 | paidhre ==.)"
global hrs_vary "empl == 1 & selfinc == 0 & selfemp == 0 & (paidhre == 0 | paidhre ==.) & hrsvary ==1"

*1 -Total 
sum final_weight 
noi di "Total sample in CPS ORG"
noi di %14.2f r(sum)

count if final_weight!=. 
noi di "Total sample in CPS ORG: unweighted"
noi di %14.2f r(N)

*2 -Employed
sum final_weight if $employed
noi di "Population Employed"
noi di %14.2f r(sum)

count if $employed
noi di "Population Employed: unweighted"
noi di %14.2f r(N)

*3 -Salaried worker
sum final_weight if $salary
noi di "Salaried workers"
noi di %14.2f r(sum)
local c = r(sum)

count if $salary
noi di "Salaried workers: unweighted"
noi di %14.2f r(N)
local c_uw = r(N)


*4 -Not paid by the hour
sum final_weight if $nhourly
noi di "Salaried workes who are not paid by the hour"
noi di %14.2f r(sum)

count if $nhourly
noi di "Salaried workes who are not paid by the hour: unweighted"
noi di %14.2f r(N)


*5 -Among those who are not paid by the hour: hours vary
sum final_weight if $hrs_vary
noi di "Salaried workes who are not paid by the hour and hour vary"
noi di %14.2f r(sum)
local a = r(sum)

count if $hrs_vary
noi di "Salaried workes who are not paid by the hour and hour vary: unweighted"
noi di %14.2f r(N)
local a_uw = r(N)


*Among those in group 3 but not 5, how many has no wage
sum final_weight if (empl == 1 & selfinc == 0 & selfemp == 0) & (paidhre == 1 | hrsvary != 1) & (wage3==0 | wage3==.)
noi di "Among those in group 3 but not 5, how many has no wage"
noi di %14.2f r(sum)
local b = r(sum)  + `a'

count if (empl == 1 & selfinc == 0 & selfemp == 0) & (paidhre == 1 | hrsvary != 1) & (wage3==0 | wage3==.)
noi di "Among those in group 3 but not 5, how many has no wage: unweighted"
noi di %14.2f r(N)
local b_uw = r(N)  + `a_uw'


*Population of interest: Salary workers minus:
* 	- those workes who are not paid by the hour and hours vary
*	- any additional workers that doesn't have a wage. 
noi di "Population of interest:"
noi di %14.2f  `c' - `b'
noi di "Population of interest: unweighted"
noi di %14.2f  `c_uw' - `b_uw'


*Tag poppulation of interest: Salary workers that either paid hourly or not paid by the hour but hours not vary, and have a non zero non missing wage
cap drop pop_of
gen pop_of_int = (empl == 1 & (selfinc ==0 & selfemp ==0) & (paidhre ==1 | (paidhre == 0 & hrsvary != 1))  & (wage3 != 0 & wage3 != .) )

sum final_weight if pop_of_int == 1 
noi di "Pop. of interest: workers excluded self* and not paid by the hour whose hours vary"
noi di %14.2f r(sum)


*Get descriptive stats for wage
noi di "Descriptive statistics for wage 3"
noi sum wage3 if pop_of_int ==1 [w = final_weight ], d 

*Look at histogram for wages below $10 an hour
histogram wage3 if wage3<=20 [fweight = round_w], bin(30) xline(7.25)

cap drop under_*
gen under_7 = (wage3<7.5)
gen under_9 = (wage3<9)
gen under_10 = (wage3<10.10)
gen under_13 = (wage3<13)
gen under_15 = (wage3<15)

noi sum under_* [w = final_weight] if pop_of == 1

sum final_	if (empl == 1 & (selfinc ==0 & selfemp ==0) &  (wage3 != 0 & wage3 != .) )
noi di %14.2f r(sum)


* Adjusting wages 

cap drop aux_1
xtile aux_1 = wage3 [w = final_weight], nq(10)
         
cap drop adj_wage3
gen adj_wage3 = .
replace adj_wage3 = 0.02400000  if aux_1 == 1
replace adj_wage3 = 0.02875144  if aux_1 == 2 
replace adj_wage3 = 0.03350288  if aux_1 == 3 
replace adj_wage3 = 0.03825432  if aux_1 == 4
replace adj_wage3 = 0.04300575  if aux_1 == 5 
replace adj_wage3 = 0.04775719  if aux_1 == 6 
replace adj_wage3 = 0.05250863  if aux_1 == 7 
replace adj_wage3 = 0.05726007  if aux_1 == 8 
replace adj_wage3 = 0.06201151  if aux_1 == 9 
replace adj_wage3 = 0.06676295  if aux_1 == 10

replace adj_wage3 = (1 + adj_wage3)^3 * wage3

*Adjust predicted wages by state min wages: 
gen state_min_2016 = . 
replace	state_min_2016 = 	9.75	if state == 	94
replace	state_min_2016 = 	8.75	if state == 	63
replace	state_min_2016 = 	8.05	if state == 	71
replace	state_min_2016 = 	8.05	if state == 	86
replace	state_min_2016 = 	10		if state == 	93
replace	state_min_2016 = 	8.23	if state == 	84
replace	state_min_2016 = 	9.6		if state == 	16
replace	state_min_2016 = 	8.25	if state == 	51
replace	state_min_2016 = 	8.05	if state == 	59
replace	state_min_2016 = 	7.25	if state == 	58
replace	state_min_2016 = 	8.5		if state == 	95
replace	state_min_2016 = 	7.25	if state == 	82
replace	state_min_2016 = 	8.25	if state == 	33
replace	state_min_2016 = 	7.25	if state == 	32
replace	state_min_2016 = 	7.25	if state == 	42
replace	state_min_2016 = 	7.25	if state == 	47
replace	state_min_2016 = 	7.25	if state == 	61
replace	state_min_2016 = 	7.25	if state == 	72
replace	state_min_2016 = 	7.5		if state == 	11
replace	state_min_2016 = 	8.25	if state == 	52
replace	state_min_2016 = 	10		if state == 	14
replace	state_min_2016 = 	8.5		if state == 	34
replace	state_min_2016 = 	9		if state == 	41
replace	state_min_2016 = 	7.25	if state == 	64
replace	state_min_2016 = 	7.65	if state == 	43
replace	state_min_2016 = 	8.05	if state == 	81
replace	state_min_2016 = 	9		if state == 	46
replace	state_min_2016 = 	8.25	if state == 	88
replace	state_min_2016 = 	7.25	if state == 	12
replace	state_min_2016 = 	8.38	if state == 	22
replace	state_min_2016 = 	7.5		if state == 	85
replace	state_min_2016 = 	9		if state == 	21
replace	state_min_2016 = 	7.25	if state == 	56
replace	state_min_2016 = 	7.25	if state == 	44
replace	state_min_2016 = 	8.1		if state == 	31
replace	state_min_2016 = 	7.25	if state == 	73
replace	state_min_2016 = 	9.25	if state == 	92
replace	state_min_2016 = 	7.25	if state == 	23
replace	state_min_2016 = 	9.6		if state == 	15
replace	state_min_2016 = 	7.25	if state == 	57
replace	state_min_2016 = 	8.5		if state == 	45
replace	state_min_2016 = 	7.25	if state == 	62
replace	state_min_2016 = 	7.25	if state == 	74
replace	state_min_2016 = 	7.25	if state == 	87
replace	state_min_2016 = 	9.6		if state == 	13
replace	state_min_2016 = 	7.25	if state == 	54
replace	state_min_2016 = 	9.47	if state == 	91
replace	state_min_2016 = 	8		if state == 	55
replace	state_min_2016 = 	7.25	if state == 	35
replace	state_min_2016 = 	5.15	if state == 	83
replace	state_min_2016 = 	10.5	if state == 	53

replace adj_wage3 = state_min_2016 if adj_wage3 < state_min_2016
*at this point the wage variables are differing slighlty between STATA and R

*Growth in number of workers from 2013 to 2016: %4.7255
local g_work = 1.047255
sum final_weight if pop_of_int == 1 
noi di "Pop. of interest: workers excluded self* and not paid by the hour whose hours vary"
noi di %14.2f r(sum) * `g_work'

*FH: There is a difference in population size of 7 workers between calculation in STATA and R

noi di "Descriptive statistics for adj_wage3 (forecast of wage 3 in 2016)"
cap drop final_weight_mod
gen final_weight_mod = final_weight * `g_work'
noi sum adj_wage3 if pop_of_int ==1 [w = final_weight_mod ], d 

cap drop round_w_mod
gen round_w_mod = round(final_weight_mod)
*Look at histogram for wages below $10 an hour
histogram adj_wage3 if adj_wage3<=20 [fweight = round_w_mod], bin(30) xline(7.25)

cap drop under_*
gen under_7 = (adj_wage3<7.5)
gen under_9 = (adj_wage3<9)
gen under_10 = (adj_wage3<10.10)
gen under_13 = (adj_wage3<13)
gen under_15 = (adj_wage3<15)

noi sum under_* [w = final_weight_mod] if pop_of == 1

sum final_weight_mod if (empl == 1 & (selfinc ==0 & selfemp ==0) &  (adj_wage3 != 0 & adj_wage3 != .) )
noi di %14.2f r(sum)


*FSLA eligibility
non.comp.stats <- df %>%
  select(wage3, state, orgwgt, peernuot)  %>%
    filter(pop_of_int == 1)  %>%
      summarise(
        "% of non compliers w/o adj" = 
          wtd.mean(wage3 < state.minw("2013")[state, ], 
                          weights = orgwgt), 
        "% of non compliers with adj" = 
          wtd.mean(wage3 + 0.25 * (peernuot == 2) + 
                          0.13 * (peernuot == 1)  < state.minw("2013")[state, ], 
                          weights = orgwgt) 
        )


*Ripple effects
gen min_increase = (10.10 - state_min_2016) * ( state_min_2016>7.25) + (10.10 - 7.25) * ( state_min_2016<=7.25)
replace min_increase = 0 if min_increase <0
sum adj_wage3 if adj_wage3>10.10 & adj_wage3<=10.10 + min_increase*.5   [w =final_weight_mod ]


