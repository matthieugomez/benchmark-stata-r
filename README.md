# Benchmarks

## Results
This page compares the speed of R and Stata for typical data analysis. Instructions are runned on randomly generated datasets of 500 Mo (which corresponds to 1e7 observations). For each data operation, I use the fatest command available in each language. In particular, I use [ftools](https://github.com/sergiocorreia/ftools) and [gtools](https://github.com/mcaceresb/stata-gtools) in Stata. I use [data.table](https://github.com/Rdatatable/data.table) and [fst](https://github.com/fstpackage/fst) in R.


<img class = "img-responsive"  src="/output/1e7.png" />


## Code

All the code below can be downloaded in the code folder in the repository.
The dataset is generated in R using the file [1-generate-datasets.r](code/1-generate-datasets.r).
The R code in the file [2-benchmark-r.r](code/2-benchmark-r.r):
The Stata code in the file [3-benchmark-stata.do](code/3-benchmark-stata.do):


## Session Info 

The machine used for this benchmark has a 3.5 GHz Intel Core i5 (4 cores) and a SSD disk.

The Stata version is Stata 13 MP.  The R session info is 

````R
R version 3.5.0 (2018-04-23)
Platform: x86_64-apple-darwin15.6.0 (64-bit)
Running under: macOS High Sierra 10.13.6

Matrix products: default
BLAS: /Library/Frameworks/R.framework/Versions/3.5/Resources/lib/libRblas.0.dylib
LAPACK: /Library/Frameworks/R.framework/Versions/3.5/Resources/lib/libRlapack.dylib

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] scales_1.0.0      ggplot2_3.0.0     stringr_1.3.1     lfe_2.8-2        
[5] Matrix_1.2-14     tidyr_0.8.1       data.table_1.11.4

loaded via a namespace (and not attached):
 [1] Rcpp_0.12.18     pillar_1.3.0     compiler_3.5.0   plyr_1.8.4      
 [5] bindr_0.1.1      tools_3.5.0      tibble_1.4.2     gtable_0.2.0    
 [9] lattice_0.20-35  pkgconfig_2.0.2  rlang_0.2.2      parallel_3.5.0  
[13] bindrcpp_0.2.2   withr_2.1.2      dplyr_0.7.6      grid_3.5.0      
[17] tidyselect_0.2.4 glue_1.3.0       R6_2.2.2         Formula_1.2-3   
[21] purrr_0.2.5      magrittr_1.5     assertthat_0.2.0 xtable_1.8-3    
[25] colorspace_1.3-2 sandwich_2.5-0   stringi_1.2.4    lazyeval_0.2.1  
[29] munsell_0.5.0    crayon_1.3.4     zoo_1.8-2  
````
