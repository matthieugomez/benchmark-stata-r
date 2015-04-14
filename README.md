# Benchmarks

## Results
This page compares speed of R and Stata for typical data analysis on randomly generated datasets (see below) of 50 Mo, 500 Mo, and 5 Go. The graph below shows the results for the 500MB dataset (with 1e7 observations).

<img class = "img-responsive"  src="/output/1e7.png" />


### loading data
R wins to read `.csv`: the data.table command `fread` is ten times faster than the Stata commands `insheet`. However, when reading or saving data in proprietary format (`.dta` for Stata and `.rds` for R), Stata is more than ten times faster.

### manipulating data
The package `data.table` is 10x faster than Stata for the principal commands of data cleaning: sorting, applying functions within groups, reshaping, joining multiple datasets.

### estimating models 
R is much slower than Stata to estimate linear models (even when I used specialized packages such as `biglm` or `speedlm`). I don't really understand why - one reason may be that Stata `reg` is multi threaded. 

For models with high dimensional fixed effect(s), `felm` is faster than the corresponding Stata commands (`areg/reghdfe)`. One reason is that `felm` embeds an algorithm to speed up within transformations of multiple factors as described [here](http://journal.r-project.org/archive/2013-2/gaure.pdf).

### conclusion
In conclusion, R is an order of magnitude faster than Stata for common data analysis. The difference grows with the dataset size.


The dataset and the code I used to produce these graphs are available below. 
If you are a Stata user and you want to know more about R, you may be interested in other things I wrote: an [online guide to R](http://www.princeton.edu/~mattg/statar/) and the [statar package](http://cran.r-project.org/package=statar).

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
# To run the script, you first need to ownload the relevant packages:
# install.packages("data.table")
# install.packages("tidyr")
# install.packages("statar")
# install.packages("biglm")
# install.packages("lfe")

# loading packages
library(data.table)
library(tidyr)
library(statar)
library(biglm)
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
	out[length(out)+1] <- time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id1", "id2", "id3")])


	# regress
	DT1 <- DT[1:(nrow(DT)/2)]
	out[length(out)+1] <- time(biglm(v3 ~ v2 + id4 + id5 + id6, DT1))
	out[length(out)+1] <- time(biglm(v3 ~ v2 + id4 + id5 + id6 + as.factor(v1), DT1))
	out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5 + id6 + as.factor(v1) | id1 | 0 | id1, DT1))
	out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5 + id6  | id1 + id2 | 0 | id1, DT1))
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
To run the script, you first need to download the relevant packages:
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


/* Execute the commands */
cap program drop benchmark
program define benchmark, rclass
	quietly{
	local i = 0
	/* write and read */
	timer clear
	timer on 1
	import delimited using `0'.csv, clear
	timer off 1	
	timer list
	return scalar cmd`++i' = r(t1)

	timer clear
	timer on 1
	save `0'.dta, replace
	timer off 1	
	timer list
	return scalar cmd`++i' = r(t1)

	timer clear
	timer on 1
	use `0'.dta, clear
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
	use `0'.dta, clear
	timer clear
	timer on 1
	merge m:1 id1 id3 using merge, keep(master matched) nogen
	timer off 1	
	timer list
	return scalar cmd`++i' = r(t1)
	
	/* append */
	use `0'.dta, clear
	timer clear
	timer on 1
	append using `0'.dta
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
	use `0'.dta, clear
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

	use `0'.dta, clear
	timer clear
	timer on 1
	collapse (mean) v1 v2 (sum) v3,  by(id1 id2 id3) fast
	timer off 1
	timer list
	return scalar cmd`++i' = r(t1)

	/* regress */
	use `0'.dta, clear
	keep if _n <= _N/2
	timer clear
	timer on 1
	reg v3 v2 id4 id5 id6
	timer off 1
	timer list
	return scalar cmd`++i' = r(t1)

	timer clear
	timer on 1
	reg v3 v2 id4 id5 id6 i.v1
	timer off 1
	timer list
	return scalar cmd`++i' = r(t1)

	timer clear
	timer on 1
	areg v3 v2 id4 id5 id6 i.v1, a(id1) cl(id1)
	timer off 1
	timer list
	return scalar cmd`++i' = r(t1)

	egen g1=group(id1)
	egen g2=group(id2)
	timer clear
	timer on 1
	reghdfe v3 v2 id4 id5 id6, absorb(g1 g2) vce(cluster g1)  tolerance(1e-6) fast
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
```


## Session Info 

The machine used for this benchmark has a 2.9GHz i5 processor (4 cores),

The version of Stata used is Stata 13 MP 4 cores. 
The R session info is 

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
