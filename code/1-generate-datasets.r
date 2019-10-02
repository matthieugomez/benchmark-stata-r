# To run the script, download the relevant packages:
# install.packages("data.table")

library(data.table)
library(readr)
K <- 20
N <- 1e7L
set.seed(1)
DT <- data.table(
  id1 = sample(sprintf("id%03d",1:K), N, TRUE),      # few groups (char)
  id2 = sample(sprintf("id%03d",1:K), N, TRUE),      # few groups (char)
  id3 = sample(sprintf("id%010d",1:(N/K)), N, TRUE), # many groups (char)
  id4 = sample(K, N, TRUE),                          # few groups (int)
  id5 = sample(K, N, TRUE),                          # few groups (int)
  id6 = sample(N/K, N, TRUE),                        # many groups (int)
  v1 =  sample(5, N, TRUE),                          # int in range [1,5]
  v2 =  sample(1e6, N, TRUE),                        # int in range [1,1e6]
  v3 =  sample(round(runif(100,max=100),4), N, TRUE) # numeric e.g. 23.5749
)
fwrite(DT, "~/1e7.csv")
fwrite(unique(DT[, list(id1, id3)]),"~/statabenchmark/merge_string.csv")
fwrite(unique(DT[, list(id4, id6)]),"~/statabenchmark/merge_int.csv")


