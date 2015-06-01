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
		real scalar index, a, obs
		index =  st_varindex(y)
		a = 0
		for (obs = first ; obs <= last ; obs++){
			a = a + _st_data(obs, index) 
		}
	}


mata:
	void loop_generate(string scalar newvar, real scalar first, real scalar last){
		real scalar index, obs
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
program define benchmark
	quietly{
		local file `0'
		local i = 0
		/* write and read */
		Tic, n(`++i')
		import delimited using `file'.csv, clear
		Toc, n(`i')

		Tic, n(`++i')
		save `file'.dta, replace
		Toc, n(`i')

		Tic, n(`++i')
		use `file'.dta, clear
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
		use `file'.dta, clear
		Tic, n(`++i')
		merge m:1 id1 id3 using merge, keep(master matched) nogen
		Toc, n(`i')

		/* append */
		use `file'.dta, clear
		Tic, n(`++i')
		append using `file'.dta
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
		use `file'.dta, clear
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
		egen temp = group(id1 id2 id3)
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
		collapse (mean) v1 v2 (sum) v3,  by(id1) fast
		Toc, n(`i')

		use `file'.dta, clear
		Tic, n(`++i')
		collapse (mean) v1 v2 (sum) v3,  by(id3) fast
		Toc, n(`i')


		/* regress */
		use `file'.dta, clear
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


		egen g = group(id3)
		Tic, n(`++i')
		cap reghdfe v3 v2 id4 id5 i.v1, absorb(id6 g) vce(cluster id6)  tolerance(1e-6) fast
		Toc, n(`i')


		/* vector / matrix functions */
		use `file'.dta, clear
		Tic, n(`++i')
		mata: loop_sum("id4", 1, `=_N')
		Toc, n(`i')

		Tic, n(`++i')
		mata: loop_generate("temp", 1, `=_N')
		Toc, n(`i')

		Tic, n(`++i')
		mata: m_invert("v2 id4 id5 id6")
		Toc, n(`i')

	}
end

/***************************************************************************************************
Execude program
***************************************************************************************************/

timer clear
benchmark 2e6
timer list

timer clear
benchmark 1e7
timer list

timer clear
benchmark 1e8
timer list

