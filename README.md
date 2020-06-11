# Benchmarks

## Results
This page compares the speed of R and Stata for typical data analysis. Instructions are runned on randomly generated datasets of with 10 millions observations. For each data operation, I try to use the fatest command available in each language. In particular, I use [gtools](https://github.com/mcaceresb/stata-gtools) in Stata. I use [data.table](https://github.com/Rdatatable/data.table), [fst](https://github.com/fstpackage/fst), and [fixest](https://github.com/fstpackage/fixe) in R.


<img class = "img-responsive"  src="/output/1e7.png" />


## Code

All the code below can be downloaded in the code folder in the repository.
The dataset is generated in R using the file [1-generate-datasets.r](code/1-generate-datasets.r).
The R code in the file [2-benchmark-r.r](code/2-benchmark-r.r):
The Stata code in the file [3-benchmark-stata.do](code/3-benchmark-stata.do):


## Session Info 

The machine used for this benchmark has a 3.5 GHz Intel Core i5 (4 cores) with a SSD disk.

The Stata version is Stata 16 MP with 2 cores.  The R session info is 

````R
R version 3.6.0 (2019-04-26)
Platform: x86_64-apple-darwin15.6.0 (64-bit)
Running under: macOS High Sierra 10.13.6

Matrix products: default
BLAS:   /Library/Frameworks/R.framework/Versions/3.6/Resources/lib/libRblas.0.dylib
LAPACK: /Library/Frameworks/R.framework/Versions/3.6/Resources/lib/libRlapack.dylib

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] scales_1.0.0      ggplot2_3.2.1     stringr_1.4.0     fst_0.9.0        
[5] statar_0.7.1      lfe_2.8-3         Matrix_1.2-17     tidyr_1.0.0      
[9] data.table_1.12.2

loaded via a namespace (and not attached):
 [1] Rcpp_1.0.2         pillar_1.4.2       compiler_3.6.0     tools_3.6.0       
 [5] zeallot_0.1.0      lifecycle_0.1.0    tibble_2.1.3       gtable_0.3.0      
 [9] lattice_0.20-38    pkgconfig_2.0.3    rlang_0.4.0        parallel_3.6.0    
[13] withr_2.1.2        dplyr_0.8.3        vctrs_0.2.0        grid_3.6.0        
[17] tidyselect_0.2.5   glue_1.3.1         R6_2.4.0           Formula_1.2-3     
[21] purrr_0.3.2        magrittr_1.5       ellipsis_0.3.0     backports_1.1.4   
[25] matrixStats_0.55.0 assertthat_0.2.1   xtable_1.8-4       colorspace_1.4-1  
[29] sandwich_2.5-1     stringi_1.4.3      lazyeval_0.2.2     munsell_0.5.0     
[33] crayon_1.3.4       zoo_1.8-6    
````
