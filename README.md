# Benchmarks

## Results
I compared the speed of R and Stata for typical data queries on a randomly generated dataset (similar to the ones used in the [data.table benchmarks](https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping) run by Matt Dowle). The graph below presents the results I obtained for 1e7 observations (500MB dataset) - results are similar with different number of rows: [1e8](/output/1e8.png) and [2e6](/output/2e6.png).  

<img class = "img-responsive"  src="/output/1e7.png" />

I first timed commands that load datasets into memory. To open .csv, the data.table command `fread` is an order of magnitude faster than the corresponding Stata commands. Yet, this speed difference is reversed for datasets in proprietary formats (resp .dta for Stata and .rds for R): Stata is impressively fast to open and save .dta while base R opens .rds at approximately the same speed as `fread` opens .csv.

I then tested a wide range of typical data manipulations, which constitute the bulk of my typical work. For those, the package `data.table` is much, much faster than Stata. Crucial commands such as sorting, executing functions within groups, reshaping and joining datasets are in average one order of magnitude faster in R. 

Then I estimated typical regression models. R is much slower than Stata to estimate simple regressions - even through packages such as `biglm` or `speedlm`. The difference becomes particularly important with larger datasets. I'd like to understand better this speed difference : one reason may be that Stata `reg` is multi threaded while `biglm` does not use parallel computation [yet](http://notstatschat.tumblr.com/post/54900159212/big-data-linear-models). That said, for models with high dimensional fixed effect(s), `felm` (from the package `lfe`) is faster than the corresponding Stata commands `areg/reg2hdfe/reg3hdfe`. Since `felm` embeds an algorithm to speed up within transformations of multiple factors (see the author's [article](http://journal.r-project.org/archive/2013-2/gaure.pdf), this gap increases with the number of high dimensional fixed effects

In summary, Stata appears to be much more optimized than base R for typical data manipulations. Yet, this difference is completely reversed once one takes into account recent R packages such as `data.table` and `felm`. These packages, mostly written in C, make R an order of magnitude faster than Stata for common data analysis.

The dataset and the code I used to produce these graphs are available below. Any feedback is welcome!


## Code

All the code below can be downloaded in the code folder in the repository.

### Data

I simulated four datasets using the file (1-generate-datasets.r)[code/1-generate-datasets.r]:

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

This script creates fourt files required in the R and Stata scripts: "2e6.csv", "1e7.csv" and "1e8.csv", and "merge.csv". You can also download directly [2e6.csv](http://www.princeton.edu/~mattg/data/2e6.csv) and [merge.csv](http://www.princeton.edu/~mattg/data/merge.csv)




### R Code

I simulated four datasets using the file (2-benchmark-r.r)[code/2-benchmark-r.r]:

```R
# loading packages
library(data.table)
library(tidyr)
library(statar)
library(biglm)
library(lfe)

# setting options
options(mc.cores=4)

# creating the file to merge with
DT <- fread("merge.csv", showProgress=FALSE)
saveRDS(DT, file = "merge.rds", compress = FALSE)


# defining the benchmark function
benchmark <- function(file){
	# write and read
	out <- rep(NA, 23)
	out[1] <- sum(system.time( DT <- fread(file, showProgress=FALSE) )[1:2])
	out[2] <- sum(system.time( saveRDS(DT, file = "temp.rds", compress = FALSE) )[1:2])
	rm(list = setdiff(ls(),"out")) 
	out[3] <- sum(system.time( DT <- readRDS("temp.rds") )[1:2])

	# sort and duplicates  
	out[4] <- sum(system.time(setkeyv(DT, c("id3")))[1:2])
	out[5] <- sum(system.time(setkeyv(DT, c("id6")))[1:2])
	out[6] <- sum(system.time(setkeyv(DT, c("v3")))[1:2])
	out[7] <- sum(system.time(setkeyv(DT, c("id1","id2","id3", "id4", "id5", "id6")))[1:2])
	out[8] <- sum(system.time(sum(!duplicated(DT, by = c("id3"))))[1:2])

	# merge 
	DT <- readRDS("temp.rds") 
	DT_merge <- readRDS("merge.rds")
	f <- function(){
		setkey(DT, id1, id3)
		setkey(DT_merge, id1, id3) 
		merge(DT, DT_merge, all.x = TRUE, all.y = FALSE) 
	}
	out[9] <- sum(system.time(f())[1:2])

	# append 
	DT1 <- copy(DT) 
	out[10] <- sum(system.time(rbindlist(list(DT,DT1), fill = TRUE) )[1:2])

	# reshape
	rm(list = setdiff(ls(),"out"))
	DT <- readRDS("temp.rds") 
	DT1 <- unique(DT, by = c("id1", "id2", "id3"))
	DT1 <- DT1[1:(nrow(DT1)/10)]
	out[11] <- sum(system.time(DT2 <- gather(DT1, variable, value, id4, id5, id6, v1, v2, v3))[1:2])
	rm(DT1) 
	out[12] <- sum(system.time(DT3 <- spread(DT2, variable, value))[1:2])
	rm(list = c("DT2", "DT3"))

	# recode
	f <- function(){
		DT[v1 == 1, v1_name := "first"]
		DT[v1 %in% c(2,3), v1_name := "second"]
		DT[v1 %in% c(4,5), v1_name := "third"]
	}
	out[13] <- sum(system.time(f())[1:2])
	DT[, v1_name := NULL]

	# split apply combine
	rm(list = setdiff(ls(),"out"))
	DT <- readRDS("temp.rds") 
	out[14] <- sum(system.time( DT[, temp := sum(v3, na.rm = TRUE), by = id3] )[1:2])
	DT[, temp := NULL] 
	out[15] <- sum(system.time( DT[, temp := sum(v3, na.rm = TRUE), by = c("id3", "id2", "id1")] )[1:2])
	DT[, temp := NULL] 
	out[16] <- sum(system.time( DT[, temp := mean(v3, na.rm = TRUE) , by = id6] )[1:2])
	DT[, temp := NULL] 
	out[17] <- sum(system.time( DT[, temp := mean(v3, na.rm = TRUE) , by = c("id6", "id5", "id4")] )[1:2])
	DT[, temp := NULL] 
	out[18] <-sum(system.time( DT[, temp := mean(v3, na.rm = TRUE) , by = c("id1", "id2", "id3", "id4", "id5", "id6")] )[1:2])
	DT[, temp := NULL]
	DT1 <- DT[1:(nrow(DT)/10)]
	out[19] <- sum(system.time( DT[, temp := sd(v3, na.rm = TRUE), by = c("id3", "id2", "id1")] )[1:2])
	DT[, temp := NULL] 


	# regress
	out[20] <- sum(system.time( biglm(v3 ~ v2 + id4 + id5 + id6, DT1) )[1:2])
	out[21] <- sum(system.time( biglm(v3 ~ v2 + id4 + id5 + id6 + as.factor(v1), DT1) )[1:2])
	out[22] <- sum(system.time( felm(v3 ~ v2 + id4 + id5 + id6 + as.factor(v1) | id1 | 0 | id1, DT1) )[1:2])
	out[23] <- sum(system.time( felm(v3 ~ v2 + id4 + id5 + id6  | id1 + id2 | 0 | id1, DT1) )[1:2])
	# return time vector
	out
}


# run benchmark
benchmark("2e6.csv")
benchmark("1e7.csv")
benchmark("1e8.csv")
```

### Stata code

I simulated four datasets using the file (3-benchmark-stata.do)[code/3-benchmark-stata.do]:

```
/***************************************************************************************************
The command distinct can be downloaded here: https://ideas.repec.org/c/boc/bocode/s424201.html

The command regh2dfe can be dowloaded here: https://ideas.repec.org/c/boc/bocode/s457101.html
***************************************************************************************************/
/* set options */
drop _all
set processors 4

/* create the file to merge with */
import delimited using merge.csv
save merge.dta


/* Execute the commands */
foreach file in "2e6.csv" "1e7.csv" "1e8.csv"{
	/* write and read */
	timer on 1
	import delimited using "`file'", clear
	timer off 1

	timer on 2
	save temp, replace
	timer off 2
	timer on 3
	use temp, clear
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
	use temp, clear
	timer on 9
	merge m:1 id1 id3 using merge, keep(master matched) nogen
	timer off 9
	
	/* append */
	use temp, clear
	timer on 10
	append using temp
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
	use temp, clear
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
