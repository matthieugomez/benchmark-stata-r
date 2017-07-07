/***************************************************************************************************
To run the script, download the following packages:
ssc install distinct
ssc install reghdfe
ssc install fastxtile
ssc install ftools
***************************************************************************************************/

/* create the file to merge with */
import delimited using "~/merge_string.csv", clear
save "~/merge_string.dta", replace

import delimited using "~/merge_int.csv", clear
save "~/merge_int.dta", replace




/***************************************************************************************************

***************************************************************************************************/

/* timer helpers */
program define Tic
	syntax, n(integer)
	timer on `n'
end

program define Toc
	syntax, n(integer) 
	timer off `n'
end

/* benchmark */
set processors 4

timer clear
local i = 0
/* write and read */
Tic, n(`++i')
import delimited using "~/1e7.csv", clear
Toc, n(`i')

Tic, n(`++i')
save "~/1e7.dta", replace
Toc, n(`i')

drop _all 
Tic, n(`++i')
use "~/1e7.dta", clear
Toc, n(`i')

/* sort  */
Tic, n(`++i')
sort id3 
Toc, n(`i')

Tic, n(`++i')
sort id6
Toc, n(`i')

Tic, n(`++i')
sort v3
Toc, n(`i')

Tic, n(`++i')
sort id1 id2 id3 id4 id5 id6
Toc, n(`i')

Tic, n(`++i')
distinct id3
Toc, n(`i')


Tic, n(`++i')
distinct id1 id2 id3, joint
Toc, n(`i')

Tic, n(`++i')
duplicates drop id2 id3, force
Toc, n(`i')

/* merge */
use "~/1e7.dta", clear
Tic, n(`++i')
merge m:1 id1 id3 using "~/merge_string.dta", keep(master matched) nogen
Toc, n(`i')


use "~/1e7.dta", clear
Tic, n(`++i')
merge m:1 id4 id6 using "~/merge_int.dta", keep(master matched) nogen
Toc, n(`i')


/* append */
use "~/1e7.dta", clear
Tic, n(`++i')
append using "~/1e7.dta"
Toc, n(`i')

/* reshape */
bys id1 id2 id3: keep if _n == 1
keep if _n < _N/10
foreach v of varlist id4 id5 id6 v1 v2 v3{
	rename `v' v_`v'
}
Tic, n(`++i')
reshape long v_, i(id1 id2 id3) j(variable) string
Toc, n(`i')
Tic, n(`++i')
reshape wide v_, i(id1 id2 id3) j(variable) string
Toc, n(`i')

/* recode */
use "~/1e7.dta", clear
Tic, n(`++i')
gen v1_name = ""
replace v1_name = "first" if v1 == 1
replace v1_name = "second" if inlist(v1, 2, 3)
replace v1_name = "third" if inlist(v1, 4, 5)
Toc, n(`i')
drop v1_name

/* functions */
Tic, n(`++i')
fastxtile temp = v3, n(10)
Toc, n(`i')
drop temp

Tic, n(`++i')
fegen temp = group(id1 id2 id3)
Toc, n(`i')
drop temp

/* split apply combine */ 
Tic, n(`++i')
egen temp = sum(v3), by(id1)
Toc, n(`i')
drop temp

Tic, n(`++i')
egen temp = sum(v3), by(id3)
Toc, n(`i')
drop temp

Tic, n(`++i')
egen temp = mean(v3), by(id6)
Toc, n(`i')
drop temp

Tic, n(`++i')
egen temp = mean(v3),by(id1 id2 id3)
Toc, n(`i')
drop temp

Tic, n(`++i')
egen temp = sd(v3), by(id3)
Toc, n(`i')
drop temp

Tic, n(`++i')
egen temp = sd(v3), by(id1 id2 id3)
Toc, n(`i')
drop temp

Tic, n(`++i')
fcollapse (mean) v1 v2 (sum) v3,  by(id1) fast
Toc, n(`i')

use "~/1e7.dta", clear
Tic, n(`++i')
fcollapse (mean) v1 v2 (sum) v3,  by(id3) fast
Toc, n(`i')


/* regress */
use "~/1e7.dta", clear
keep if _n <= _N/2
Tic, n(`++i')
reg v3 v1 v2 id4 id5
Toc, n(`i')

Tic, n(`++i')
reg v3 i.v1 v2 id4 id5
Toc, n(`i')

Tic, n(`++i')
areg v3 v2 id4 id5 i.v1, a(id6) cl(id6)
Toc, n(`i')


fegen g = group(id3)
Tic, n(`++i')
cap reghdfe v3 v2 id4 id5 i.v1, absorb(id6 g) vce(cluster id6)  tolerance(1e-6) fast
Toc, n(`i')


timer list
drop _all
gen result = .
local i = 1
while r(nt`i') < .{
	set obs `i'
	replace result = r(t`i') if _n == `i'
	local i = `i' + 1
}
outsheet using "~/resultStata1e7.csv", replace
