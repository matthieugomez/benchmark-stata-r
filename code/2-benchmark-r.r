# To run the script, download the relevant packages:
# install.packages("data.table")
# install.packages("fst")
# install.packages("tidyr") ## optional
# install.packages("statar")
# install.packages("fixest")

# loading packages
library(data.table)
library(fixest)
library(statar)
library(fst)

# setting options
options(mc.cores=4)
setFixest_nthreads(4)

# creating the file to merge with
write.fst(fread("~/statabenchmark/merge_string.csv", data.table = FALSE), "~/statabenchmark/merge_string.fst")
write.fst(fread("~/statabenchmark/merge_int.csv", data.table = FALSE), "~/statabenchmark/merge_int.fst")



# define the time function
time <- function(x){system.time(x)[3]}


out <- NULL
names <- NULL
i <- 0

# write and read
i <- i + 1 
names[i] <- "open csv"
out[i] <- time(DT <- fread("~/statabenchmark/1e7.csv", data.table = FALSE))
i <- i + 1
names[i] <- "save binary"
out[i] <- time(write.fst(DT, "~/statabenchmark/1e7.fst"))
i <- i + 1
names[i] <- "open binary"
out[i] <- time(DT <- read.fst("~/statabenchmark/1e7.fst"))

# sort and duplicates  
setDT(DT)
i <- i + 1
names[i] <- "sort string"
out[i] <- time(setkeyv(DT, c("id3")))
i <- i + 1
names[i] <- "sort int"
out[i] <- time(setkeyv(DT, c("id6")))
i <- i + 1
names[i] <- "sort float"
out[i] <- time(setkeyv(DT, c("v3")))
i <- i + 1
names[i] <- "count distinct strings"
out[i] <- time(uniqueN(DT, by = c("id3")))
i <- i + 1
names[i] <- "count distinct ints"
out[i] <- time(uniqueN(DT, by = c("id6")))

# merge 
DT <- read.fst("~/statabenchmark/1e7.fst") 
setDT(DT)
f <- function(){
	DT_merge <- read.fst("~/statabenchmark/merge_string.fst")
	setDT(DT_merge)
	setkeyv(DT, c("id1", "id3"))
	setkeyv(DT_merge, c("id1", "id3")) 
	merge(DT, DT_merge, all.x = TRUE, all.y = FALSE) 
}
i <- i + 1
names[i] <- "merge string"
out[i] <- time(f())

DT <- read.fst("~/statabenchmark/1e7.fst") 
setDT(DT)
f <- function(){
	DT_merge <- read.fst("~/statabenchmark/merge_int.fst")
	setDT(DT_merge)
	setkeyv(DT, c("id4", "id6"))
	setkeyv(DT_merge, c("id4", "id6")) 
	merge(DT, DT_merge, all.x = TRUE, all.y = FALSE) 
}
i <- i + 1
names[i] <- "merge int"
out[i] <- time(f())


# append 
i <- i + 1
names[i] <- "append"
DT1 <- copy(DT) 
out[i] <- time(rbindlist(list(DT,DT1), fill = TRUE))

# reshape
DT <- read.fst("~/statabenchmark/1e7.fst") 
setDT(DT)
DT1 <- unique(DT, by = c("id1", "id2", "id3"))
DT1 <- DT1[1:(nrow(DT1)/10),]
i <- i + 1
names[i] <- "reshape long"
# out[i] <- time(DT2 <- tidyr::pivot_longer(DT1, cols = c(id4, id5, id6, v1, v2, v3))) ## Another option
out[i] <- time(DT2 <- melt(DT1, id.vars = c("id1", "id2", "id3")))
rm(DT1) 
i <- i + 1
names[i] <- "reshape wide"
# out[i] <- time(DT3 <- tidyr::pivot_wider(DT2, names_from=variable, values_from=value)) ## Another option
out[i] <- time(DT3 <- dcast(DT2, id1 + id2 + id3 ~ variable, value.var = "value"))
rm(list = c("DT2", "DT3"))

# recode
f <- function(){
	DT[v1 == 1, v1_name := "first"]
	DT[v1 %in% c(2,3), v1_name := "second"]
	DT[v1 %in% c(4,5), v1_name := "third"]
}
i <- i + 1
names[i] <- "recode"
out[i] <- time(f())
DT[, v1_name := NULL]

# functions
i <- i + 1
names[i] <- "xtile"
out[i] <- time(DT[, temp := xtile(v3, 10)])
DT[, temp := NULL] 
i <- i + 1
names[i] <- "group strings"
out[i] <- time(DT[, temp := .GRP, by =  c("id1", "id3")])
DT[, temp := NULL]
i <- i + 1
names[i] <- "group int"
out[i] <- time(DT[, temp := .GRP, by =  c("id4", "id6")])
DT[, temp := NULL]

# sum groups
i <- i + 1
names[i] <- "sum over large groups (string)"
out[i] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id1")])
DT[, temp := NULL] 
i <- i + 1
names[i] <- "sum over small groups (string)"
out[i] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id3")])
DT[, temp := NULL] 
i <- i + 1
names[i] <- "sum over large groups (int)"
out[i] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id4")])
DT[, temp := NULL] 
i <- i + 1
names[i] <- "sum over small groups (int)"
out[i] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id6")])
DT[, temp := NULL] 


# sd groups
i <- i + 1
names[i] <- "sd over large groups (int)"
out[i] <- time(DT[, temp := sd(v3, na.rm = TRUE), by = c("id4")])
DT[, temp := NULL] 
i <- i + 1
names[i] <- "sd over small groups (int)"
out[i] <- time(DT[, temp := sd(v3, na.rm = TRUE), by = c("id6")])
DT[, temp := NULL] 



# collapse large groups
i <- i + 1
names[i] <- "collapse over large groups"
out[i] <- time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id1")])

# collapse small groups
i <- i + 1
names[i] <- "collapse over small groups"
out[i] <- time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id3")])


# regress
DT1 <- DT[1:(nrow(DT)/2),]
i <- i + 1
names[i] <- "reg"
out[i] <- time(feols(v3 ~ v1 + v2 + id4 + id5, DT1))
i <- i + 1
names[i] <- "reg fe"
out[i] <- time(feols(v3 ~ v2 + id4 + id5 + as.factor(v1), DT1))
i <- i + 1
names[i] <- "reg hfe"
out[i] <- time(feols(v3 ~ v2 + id4 + id5  + as.factor(v1) | id6, DT1)) ## Automatically clusters by id6 too
i <- i + 1
names[i] <- "reg 2 hfe"
out[i] <- time(feols(v3 ~  v2 + id4 + id5  + as.factor(v1) | id6 + id3, DT1)) ## Automatically clusters by id6 too

# run benchmark
fwrite(data.table(command = names, result = out), "~/statabenchmark/resultR1e7.csv")
