	set processors 4
	drop _all


foreach file in temp_1e8.csv{
	/* write and read */
	timer on 1
	import delimited using "`file'", clear
	timer off 1

	timer on 2
	save temp_stata, replace
	timer off 2
	timer on 3
	use temp_stata, clear
	timer off 3

	/* sort  */
	timer on 4
	sort id3 
	timer off 4

	timer on 5
	sort id6
	timer off 5

	timer on 6
	sort v3
	timer off 6

	timer on 7
	sort id1 id2 id3 id4 id5 id6
	timer off 7

	timer on 8
	distinct id3
	timer off 8

	/* merge */
	use temp_stata, clear
	timer on 9
	merge m:1 id1 id3 using temp_merge_stata, keep(master matched) nogen
	timer off 9
	
	/* append */
	use temp_stata, clear
	timer on 10
	append using temp_stata
	timer off 10

	/* reshape */
	bys id1 id2 id3: keep if _n == 1
	keep if _n<_N/10
	foreach v of varlist id4 id5 id6 v1 v2 v3{
		rename `v' v_`v'
	}
	timer on 11
	reshape long v_, i(id1 id2 id3) j(variable) string
	timer off 11
	timer on 12
	reshape wide v_, i(id1 id2 id3) j(variable) string
	timer off 12

	/* recode */
	use temp_stata, clear
	timer on 13
	gen v1_name = ""
	replace v1_name = "first" if v1 == 1
	replace v1_name = "second" if inlist(v1, 2, 3)
	replace v1_name = "third" if inlist(v1, 4, 5)
	timer off 13
	drop v1_name

	/* split apply combine */ 
	timer on 14
	egen temp = sum(v3), by(id3)
	timer off 14
	drop temp

	timer on 15
	egen temp = sum(v3), by(id3 id2 id1)
	timer off 15
	drop temp

	timer on 16
	egen temp = mean(v3), by(id6)
	timer off 16
	drop temp

	timer on 17
	egen temp = mean(v3),by(id6 id5 id4)
	timer off 17
	drop temp

	timer on 18
	egen temp = mean(v3), by(id1 id2 id3 id4 id5 id6)	
	timer off 18
	drop temp

	timer on 19
	keep if _n < _N/10
	egen temp = sd(v3), by(id3 id2 id1)
	timer off 19
	drop temp


	/* regress */
	timer on 20
	reg v3 v2 id4 id5 id6
	timer off 20

	timer on 21
	reg v3 v2 id4 id5 id6 i.v1
	timer off 21

	timer on 22
	areg v3 v2 id4 id5 id6 i.v1, a(id1) cl(id1)
	timer off 22

	egen g1 = group(id1)
	egen g2 = group(id2)
	timer on 23
	reg2hdfe v3 v2 id4 id5 id6, id1(g1) id2(g2) cluster(g1)
	timer off 23

	timer list
	timer clear
}

