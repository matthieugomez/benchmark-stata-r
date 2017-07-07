library(data.table)
library(readr)
K <- 100
N <- 1e7
set.seed(1)
N <- as.integer("1e7")
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
fwrite(DT, "~/1e7.csv")
fwrite(unique(DT, by = c("id1", "id3")),"~/merge_string.csv")
fwrite(unique(DT, by = c("id4", "id6")),"~/merge_int.csv")


