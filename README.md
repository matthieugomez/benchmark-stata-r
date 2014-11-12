# Benchmarks

## Results
I compared the speed of R and Stata for typical data queries on a randomly generated dataset (similar to the ones used in the [data.table benchmarks](https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping) run by Matt Dowle). The graph below presents the results I obtained for 1e8 observations (5GB dataset) - results are similar with fewer rows: [1e7](https://github.com/matthieugomez/benchmark-stata-r/output/1e7.png) and [2e6](https://github.com/matthieugomez/benchmark-stata-r/output/2e6.png).  
<img class = "img-responsive"  src="http://www.princeton.edu/~mattg/statar/pictures/1e8.png" />

I first timed commands that load datasets into memory. To open .csv, the data.table command `fread` is an order of magnitude faster than the corresponding Stata commands. Yet, this speed difference is reversed for datasets in proprietary formats (resp .dta for Stata and .rds for R): Stata is impressively fast to open and save .dta while base R opens .rds at approximately the same speed as `fread` opens .csv.

I then tested a wide range of typical data manipulations, which constitute the bulk of my typical work. For those, the package `data.table` is much, much faster than Stata. Crucial commands such as sorting, executing functions within groups, reshaping and joining datasets are in average one order of magnitude faster in R. 

Then I estimated typical regression models. R is much slower than Stata to estimate simple regressions - even through packages such as `biglm` or `speedlm`. The difference becomes particularly important with larger datasets. I'd like to understand better this speed difference : one reason may be that Stata `reg` is multi threaded while `biglm` does not use parallel computation [yet](http://notstatschat.tumblr.com/post/54900159212/big-data-linear-models). That said, for models with high dimensional fixed effect(s), `felm` (from the package `lfe`) is faster than the corresponding Stata commands `areg/reg2hdfe/reg3hdfe`. Since `felm` embeds an algorithm to speed up within transformations of multiple factors (see the author's [article](http://journal.r-project.org/archive/2013-2/gaure.pdf), this gap increases with the number of high dimensional fixed effects

In summary, Stata appears to be much more optimized than base R for typical data manipulations. Yet, this difference is completely reversed once one takes into account recent R packages such as `data.table` and `felm`. These packages, mostly written in C, make R an order of magnitude faster than Stata for common data analysis.

The dataset and the code I used to produce these graphs are available below. Any feedback is welcome!

## Data and session info

### Computer

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

### Data

I simulated datasets of various sizes using the following R script

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
	write.table(DT,paste0(file,".csv"),row.names=F, sep="\t")

	if (file == "2e6"){
		DT_merge <- unique(DT, by = c("id1", "id3"))
		write.table(DT_merge,"merge.csv",row.names=F, sep="\t")
	}
}
````	

If you run this script on your computer, it will create 4 files required in the R and Stata scripts: "2e6.csv", "1e7.csv" and "1e8.csv", and "merge.csv". You can also download directly [2e6.csv](http://www.princeton.edu/~mattg/data/2e6.csv) and [merge.csv](http://www.princeton.edu/~mattg/data/merge.csv)





### Code
You can find the Stata and R script I used in the code folder of the repository. 

