/***************************************************************************************************
To run the script, download the following packages:
ssc install distinct
ssc install reghdfe
ssc install fastxtile
***************************************************************************************************/
/* set options */
drop _all
set processors 4

/* create the file to merge with */
import delimited using merge.csv
save merge.dta, replace

/***************************************************************************************************
mata
***************************************************************************************************/
mata: 
	void loop_sum(string scalar y, real scalar first, real scalar last){
		real scalar index
		real scalar a
		index =  st_varindex(y)
		a = 0
		for (obs = first ; obs <= last ; obs++){
			a = a + _st_data(obs, index) 
		}
	}


mata:
	void loop_generate(string scalar newvar, real scalar first, real scalar last){
		real scalar index
		index = st_addvar("float", newvar)
		for (obs = first ; obs <= last ; obs++){
			st_store(obs, index, 1) 
		}
	}

end

mata:
	void m_invert(string scalar vars){
		st_view(V, ., vars)
		cross(V, V)
	}
end
/***************************************************************************************************

***************************************************************************************************/
/* Execute the commands */
cap program drop benchmark
program define benchmark, rclass
	quietly{
		local 0 file
		local i = 0
		/* write and read */
		timer clear
		timer on 1
		import delimited using `file'.csv, clear
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		save `file'.dta, replace
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		use `file'.dta, clear
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		/* sort  */
		timer clear
		timer on 1
		sort id3 
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		sort id6
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		sort v3
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		sort id1 id2 id3 id4 id5 id6
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		distinct id3
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)


		timer clear
		timer on 1
		distinct id1 id2 id3, joint
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		duplicates drop id2 id3, force
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		/* merge */
		use `file'.dta, clear
		timer clear
		timer on 1
		merge m:1 id1 id3 using merge, keep(master matched) nogen
		timer off 1	
		timer list
		return scalar cmd`++i' = r(t1)

		/* append */
		use `file'.dta, clear
		timer clear
		timer on 1
		append using `file'.dta
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)

		/* reshape */
		bys id1 id2 id3: keep if _n == 1
		keep if _n < _N/10
		foreach v of varlist id4 id5 id6 v1 v2 v3{
			rename `v' v_`v'
		}
		timer clear
		timer on 1
		reshape long v_, i(id1 id2 id3) j(variable) string
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)
		timer clear
		timer on 1
		reshape wide v_, i(id1 id2 id3) j(variable) string
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)

		/* recode */
		use `file'.dta, clear
		timer clear
		timer on 1
		gen v1_name = ""
		replace v1_name = "first" if v1 == 1
		replace v1_name = "second" if inlist(v1, 2, 3)
		replace v1_name = "third" if inlist(v1, 4, 5)
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)
		drop v1_name

		/* functions */
		timer clear
		timer on 1
		fastxtile temp = v3, n(10)
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)
		drop temp

		timer clear
		timer on 1
		egen temp = group(id1 id2 id3)
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)
		drop temp

		/* split apply combine */ 
		timer clear
		timer on 1
		egen temp = sum(v3), by(id1)
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)
		drop temp

		timer clear
		timer on 1
		egen temp = sum(v3), by(id3)
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)
		drop temp

		timer clear
		timer on 1
		egen temp = mean(v3), by(id6)
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)
		drop temp

		timer clear
		timer on 1
		egen temp = mean(v3),by(id1 id2 id3)
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)
		drop temp

		timer clear
		timer on 1
		egen temp = sd(v3), by(id3)
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)
		drop temp

		timer clear
		timer on 1
		collapse (mean) v1 v2 (sum) v3,  by(id1) fast
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)

		use `file'.dta, clear
		timer clear
		timer on 1
		collapse (mean) v1 v2 (sum) v3,  by(id3) fast
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)


		/* regress */
		use `file'.dta, clear
		keep if _n <= _N/2
		timer clear
		timer on 1
		reg v3 v1 v2 id4 id5
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		reg v3 i.v1 v2 id4 id5
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		areg v3 v2 id4 id5 i.v1, a(id6) cl(id6)
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)


		egen g = group(id3)
		timer clear
		timer on 1
		cap reghdfe v3 v2 id4 id5 i.v1, absorb(id6 g) vce(cluster id6)  tolerance(1e-6) fast
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)


		/* vector / matrix functions */
		use `file'.dta, clear
		timer clear
		timer on 1
		mata: loop_sum("id4", 1, `=_N')
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		mata: loop_generate("temp", 1, `=_N')
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)

		timer clear
		timer on 1
		mata: m_invert("v2 id4 id5 id6")
		timer off 1
		timer list
		return scalar cmd`++i' = r(t1)


	}
end


return clear
benchmark 2e6
return list, all

return clear
benchmark 1e7
return list, all

return clear
benchmark 1e8
return list, all


