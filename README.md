# Benchmarks

## Results
This page compares the speed of R and Stata for typical data analysis. Instructions are runned on randomly generated datasets of 50 Mo, 500 Mo, and 5 Go.    The graph below shows the results for the 500MB dataset (corresponding to 1e7 observations).

<img class = "img-responsive"  src="/output/1e7.png" />

For each data operation, I use the fatest command available in each language (to the best of my knowledge). For instance, I use `fastxtile` instead of `xtile` in Stata. Similarly, I use the package `data.table` in R.

### loading data
R is ten times faster than Stata to read `.csv` (using the data.table command `fread` vs the Stata commands `insheet`). However, when reading or saving data in proprietary format (`.dta` for Stata and `.rds` for R), Stata is more than ten times faster.

### manipulating data
The package `data.table` is 10x faster than Stata for the principal commands of data cleaning: sorting, applying functions within groups, reshaping, joining multiple datasets. Moreover, the difference grows with the dataset size. The difference mostly reflects the fact that data.table uses more efficient algorithms than the ones used in Stata 13.


### estimating models 
R is much slower than Stata to estimate linear models (even using specialized packages such as `biglm` or `speedlm`). It may come from a variety of reasons: Stata is multi threaded, Stata datasets are in row major order while R datasets are in column major orders. That being said, for models with high dimensional fixed effect(s), `felm` is faster than the corresponding Stata commands `areg/reghdfe`. This difference reflects the fact that `reghdfe` is written in Mata while `felm` is partly written in C.



## Code

All the code below can be downloaded in the code folder in the repository.

### Data

I simulated four datasets using the file [1-generate-datasets.r](code/1-generate-datasets.r):

````r
library(data.table)
K <- 100
set.seed(1)
for (file in c("2e6", "1e7", "1e8")){
	N <- as.integer(file)
	DT <- data.table(
	  id1 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
	  id2 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
	  id3 = sample(sprintf("id%010d",1:(N/K)), N, TRUE), # small groups (char)
	  id4 = sample(K, N, TRUE),                          # large groups (int)
	  id5 = sample(K, N, TRUE),                          # large groups (int)
	  id6 = sample(N/K, N, TRUE),                        # small groups (int)
	  v1 =  sample(5, N, TRUE),                          # int in range [1,5]
	  v2 =  sample(1e6, N, TRUE),                        # int in range [1,1e6]
	  v3 =  sample(round(runif(100,max=100),4), N, TRUE) # numeric e.g. 23.5749
	)
	write.table(DT, paste0(file, ".csv"), row.names = F, sep = "\t")
	if (file == "2e6"){
		DT_merge <- unique(DT, by = c("id1", "id3"))
		write.table(DT_merge, "merge.csv", row.names = F, sep = "\t")
	}
}
````	

This script creates four files required in the R and Stata scripts: "2e6.csv", "1e7.csv" and "1e8.csv", and "merge.csv". You can also download directly [2e6.csv](http://www.princeton.edu/~mattg/data/2e6.csv) and [merge.csv](http://www.princeton.edu/~mattg/data/merge.csv)




### R Code

I runned the R script in the file [2-benchmark-r.r](code/2-benchmark-r.r):

```R
# To run the script, download the relevant packages:
# install.packages("data.table")
# install.packages("tidyr")
# install.packages("statar")
# install.packages("biglm")
# install.packages("lfe")

# loading packages
library(data.table)
library(tidyr)
library(statar)
library(lfe)

# setting options
options(mc.cores=4)

# creating the file to merge with
DTmerge <- fread("merge.csv", showProgress=FALSE)
saveRDS(DTmerge, file = "merge.rds", compress = FALSE)


# define the time function
time <- function(x){sum(system.time(x)[1:2])}

# defining the benchmark function
benchmark <- function(file){
	out <- NULL
	csvfile <- paste0(file, ".csv")
	rdsfile <- paste0(file, ".rds")

	# write and read
	out[length(out)+1] <- time(DT <- fread(csvfile, showProgress=FALSE))
	out[length(out)+1] <- time(saveRDS(DT, file = rdsfile, compress = FALSE))
	out[length(out)+1] <- time(DT <- readRDS(rdsfile))

	# sort and duplicates  
	out[length(out)+1] <- time(setkeyv(DT, c("id3")))
	out[length(out)+1] <- time(setkeyv(DT, c("id6")))
	out[length(out)+1] <- time(setkeyv(DT, c("v3")))
	out[length(out)+1] <- time(setkeyv(DT, c("id1","id2","id3", "id4", "id5", "id6")))
	out[length(out)+1] <- time(uniqueN(DT, by = c("id3")))
	out[length(out)+1] <- time(uniqueN(DT, by = c("id1", "id2", "id3")))
	out[length(out)+1] <- time(unique(DT, by = c("id2", "id3")))


	# merge 
	DT <- readRDS(rdsfile) 
	DT_merge <- readRDS("merge.rds")
	f <- function(){
		setkey(DT, id1, id3)
		setkey(DT_merge, id1, id3) 
		merge(DT, DT_merge, all.x = TRUE, all.y = FALSE) 
	}
	out[length(out)+1] <- time(f())

	# append 
	DT1 <- copy(DT) 
	out[length(out)+1] <- time(rbindlist(list(DT,DT1), fill = TRUE))

	# reshape
	DT <- readRDS(rdsfile) 
	DT1 <- unique(DT, by = c("id1", "id2", "id3"))
	DT1 <- DT1[1:(nrow(DT1)/10)]
	out[length(out)+1] <- time(DT2 <- gather(DT1, variable, value, id4, id5, id6, v1, v2, v3))
	rm(DT1) 
	out[length(out)+1] <- time(DT3 <- spread(DT2, variable, value))
	rm(list = c("DT2", "DT3"))

	# recode
	f <- function(){
		DT[v1 == 1, v1_name := "first"]
		DT[v1 %in% c(2,3), v1_name := "second"]
		DT[v1 %in% c(4,5), v1_name := "third"]
	}
	out[length(out)+1] <- time(f())
	DT[, v1_name := NULL]

	# functions
	out[length(out)+1] <- time(DT[, temp := bin(v3, 10)])
	DT[, temp := NULL] 
	out[length(out)+1] <- time(DT[, temp := .GRP, by =  c("id1", "id2", "id3")])
	DT[, temp := NULL] 
	
	# mean of large groups
	out[length(out)+1] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = id1])
	DT[, temp := NULL] 
	# mean of smaller groups
	out[length(out)+1] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = id3])
	DT[, temp := NULL] 
	# groups defined by int
	out[length(out)+1] <- time(DT[, temp := mean(v3, na.rm = TRUE) , by = id6])
	DT[, temp := NULL] 
	# groups defined by multiple string
	out[length(out)+1] <- time(DT[, temp := mean(v3, na.rm = TRUE) , by = c("id1", "id2", "id3")])
	DT[, temp := NULL] 
	out[length(out)+1] <- time(DT[, temp := sd(v3, na.rm = TRUE), by = id3])
	DT[, temp := NULL] 

	# collapse large groups
	out[length(out)+1] <- time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id1")])

	# collapse small groups
	out[length(out)+1] <- time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id3")])



	
	# regress
	DT1 <- DT[1:(nrow(DT)/2)]
	out[length(out)+1] <- time(felm(v3 ~ v1 + v2 + id4 + id5, DT1))
	out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5 + as.factor(v1), DT1))
	out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5  + as.factor(v1) | id6 | 0 | id6, DT1))
	out[length(out)+1] <- time(felm(v3 ~  v2 + id4 + id5  + as.factor(v1) | id6 + id3 | 0 | id6, DT1))


	# Vector / matrix functions
	loop_sum <- function(v){
		a <- 0
		for (obs in 1:(length(v))){
			a <- a + v[obs] 
		}
		a
	}
	out[length(out)+1] <- time(loop_sum(DT[["id4"]]))

	loop_generate <- function(n){
		v = rep(0, n)
		for (obs in 1:n){
			v[obs] <- 1
		}
		v
	}
	out[length(out)+1] <- time(DT[, temp := loop_generate(nrow(DT))])

	setDF(DT)
	out[length(out)+1] <- time(crossprod(as.matrix(select(DT, v2, id4, id5, id6))))
	setDT(DT)


	# return time vector
	out

}


# run benchmark
benchmark("2e6")
benchmark("1e7")
benchmark("1e8")






```

### Stata code

I runned the Stata script in the file [3-benchmark-stata.do](code/3-benchmark-stata.do):

```
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

```


## Session Info 

The machine used for this benchmark has a 2.9GHz i5 processor (4 cores) and a SSD disk.

The Stata version is Stata 13 MP.  The R session info is 

````R
R version 3.1.1 (2014-07-10)
Platform: x86_64-apple-darwin13.1.0 (64-bit)

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
 [1] statar_0.1.3    lfe_1.7-1404     Matrix_1.1-4    tidyr_0.1.0.9000 data.table_1.9.5 
````

## All results
#### 2e6 observations (50Mo)
<img class = "img-responsive"  src="/output/2e6.png" />
#### 1e7 observations (500Mo)
<img class = "img-responsive"  src="/output/1e7.png" />
#### 1e8 observations (5Go)
<img class = "img-responsive"  src="/output/1e8.png" />
