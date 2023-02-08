/***************************************************************************************************
To run the script, download the following packages:
ssc install gtools
ssc install fastreshape
ssc install reghdfe
ssc install autorename
ssc install ftools
***************************************************************************************************/
/* timer helpers */
cap program drop Tic
program define Tic
	syntax, n(integer)
	timer on `n'
end

cap program drop Toc
program define Toc
	syntax, n(integer) 
	timer off `n'
end


import delimited using "~/statabenchmark/merge_string.csv", clear
autorename
save "~/statabenchmark/merge_string.dta", replace

import delimited using "~/statabenchmark/merge_int.csv", clear
save "~/statabenchmark/merge_int.dta", replace

/***************************************************************************************************

***************************************************************************************************/

/* benchmark */
set processors 2

timer clear
local i = 0
/* write and read */
Tic, n(`++i')
import delimited using "~/statabenchmark/1e7.csv", clear
Toc, n(`i')

Tic, n(`++i')
save "~/statabenchmark/1e7.dta", replace
Toc, n(`i')

drop _all 
Tic, n(`++i')
use "~/statabenchmark/1e7.dta", clear
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
gdistinct id3
Toc, n(`i')

Tic, n(`++i')
gdistinct id6
Toc, n(`i')

/* merge */
use "~/statabenchmark/1e7.dta", clear
Tic, n(`++i')
fmerge m:1 id1 id3 using "~/statabenchmark/merge_string.dta", keep(master matched) nogen
Toc, n(`i')

use "~/statabenchmark/1e7.dta", clear
Tic, n(`++i')
fmerge m:1 id4 id6 using "~/statabenchmark/merge_int.dta", keep(master matched) nogen
Toc, n(`i')

/* append */
use "~/statabenchmark/1e7.dta", clear
Tic, n(`++i')
append using "~/statabenchmark/1e7.dta"
Toc, n(`i')

/* reshape */
bys id1 id2 id3: keep if _n == 1
keep if _n < _N/10
foreach v of varlist id4 id5 id6 v1 v2 v3{
	rename `v' v_`v'
}
Tic, n(`++i')
greshape long v_, i(id1 id2 id3) j(variable) string
Toc, n(`i')

Tic, n(`++i')
greshape wide v_, i(id1 id2 id3) j(variable) string
Toc, n(`i')

/* recode */
use "~/statabenchmark/1e7.dta", clear
Tic, n(`++i')
gen v1_name = ""
replace v1_name = "first" if v1 == 1
replace v1_name = "second" if inlist(v1, 2, 3)
replace v1_name = "third" if inlist(v1, 4, 5)
Toc, n(`i')
drop v1_name

/* functions */
Tic, n(`++i')
gquantiles temp = v3, n(10) xtile
Toc, n(`i')
drop temp

Tic, n(`++i')
gegen temp = group(id1 id3)
Toc, n(`i')
drop temp

Tic, n(`++i')
gegen temp = group(id4 id6)
Toc, n(`i')
drop temp


/* split apply combine */ 
Tic, n(`++i')
gegen temp = sum(v3), by(id1)
Toc, n(`i')
drop temp

Tic, n(`++i')
gegen temp = sum(v3), by(id3)
Toc, n(`i')
drop temp

Tic, n(`++i')
gegen temp = sum(v3), by(id4)
Toc, n(`i')
drop temp

Tic, n(`++i')
gegen temp = sum(v3), by(id6)
Toc, n(`i')
drop temp


Tic, n(`++i')
gegen temp = sd(v3), by(id4)
Toc, n(`i')
drop temp

Tic, n(`++i')
gegen temp = sd(v3), by(id6)
Toc, n(`i')
drop temp


Tic, n(`++i')
gcollapse (mean) v1 v2 (sum) v3,  by(id1) fast
Toc, n(`i')

use "~/statabenchmark/1e7.dta", clear
Tic, n(`++i')
gcollapse (mean) v1 v2 (sum) v3,  by(id3) fast
Toc, n(`i')


/* regress */
use "~/statabenchmark/1e7.dta", clear
keep if _n <= _N/2
Tic, n(`++i')
reg v3 v1 v2 id4 id5
Toc, n(`i')

Tic, n(`++i')
reg v3 i.v1 v2 id4 id5
Toc, n(`i')

Tic, n(`++i')
reghdfe v3 v2 id4 id5 i.v1, a(id6) vce(cluster id6) tolerance(1e-6)
Toc, n(`i')

gegen g = group(id3)
Tic, n(`++i')
reghdfe v3 v2 id4 id5 i.v1, absorb(id6 g) vce(cluster id6)  tolerance(1e-6)
Toc, n(`i')

/* plot */
keep if _n <= 1000
Tic, n(`++i')
twoway (scatter v2 v1)
graph export "~/statabenchmark/plot_stata.pdf", replace
Toc, n(`i')

drop _all
gen result = .
set obs `i'
timer list
forval j = 1/`i'{
	replace result = r(t`j') if _n == `j'
}
outsheet using "~/statabenchmark/resultStata1e7.csv", replace
