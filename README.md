# Benchmarks

## Results
This page compares the speed of R and Stata for typical data analysis. Instructions are runned on randomly generated datasets of 500 Mo (which corresponds to 1e7 observations). For each data operation, I use the fatest command available in each language. In particular, I use `ftools` and `fastxtile` in Stata. I use `data.table` and `fst` in R.


<img class = "img-responsive"  src="/output/1e7.png" />




## Code

All the code below can be downloaded in the code folder in the repository.
The dataset is generated in R using the file [1-generate-datasets.r](code/1-generate-datasets.r).
The R code in the file [2-benchmark-r.r](code/2-benchmark-r.r):
The Stata code in the file [3-benchmark-stata.do](code/3-benchmark-stata.do):


## Session Info 

The machine used for this benchmark has a 2.9GHz i5 processor (4 cores) and a SSD disk.

The Stata version is Stata 13 MP.  The R session info is 

````R
R version 3.3.0 (2016-05-03)
Platform: x86_64-apple-darwin13.4.0 (64-bit)
Running under: OS X 10.12.5 (unknown)

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
 [1] fst_0.7.2         statar_0.6.4      readr_1.1.1       lfe_2.5-1998     
 [5] Matrix_1.2-10     stringr_1.2.0     ggplot2_2.2.1     devtools_1.13.2  
 [9] lazyeval_0.2.0    tidyr_0.6.3       dplyr_0.7.1       data.table_1.10.4
[13] lubridate_1.6.0  

loaded via a namespace (and not attached):
 [1] Rcpp_0.12.11       plyr_1.8.4         bindr_0.1          tools_3.3.0       
 [5] digest_0.6.12      memoise_1.1.0      tibble_1.3.3       gtable_0.2.0      
 [9] lattice_0.20-35    pkgconfig_2.0.1    rlang_0.1.1        parallel_3.3.0    
[13] bindrcpp_0.2       withr_1.0.2        hms_0.3            grid_3.3.0        
[17] glue_1.1.1         R6_2.2.2           Formula_1.2-1      magrittr_1.5      
[21] scales_0.4.1       matrixStats_0.52.2 assertthat_0.2.0   colorspace_1.3-2  
[25] xtable_1.8-2       sandwich_2.3-4     stringi_1.1.5      munsell_0.4.3     
[29] zoo_1.8-0  
````
