# To run the script, download the relevant packages:
# install.packages("data.table")
# install.packages("tidyr")
# install.packages("statar")
# install.packages("lfe")
# install.packages("fst")

# loading packages
library(data.table)
library(tidyr)
library(lfe)
library(statar)
library(fst)

# setting options
options(mc.cores=4)

# creating the file to merge with
write.fst(fread("~/merge_string.csv", data.table = FALSE), "~/merge_string.fst")
write.fst(fread("~/merge_int.csv", data.table = FALSE), "~/merge_int.fst")



# define the time function
time <- function(x){sum(system.time(x)[1:2])}


out <- NULL
names <- NULL


# write and read
names[length(names)+1] <- "open csv"
out[length(out)+1] <- time(DT <- fread("~/1e7.csv", data.table = FALSE))
names[length(names)+1] <- "save binary"
out[length(out)+1] <- time(write.fst(DT, "~/1e7.fst"))
names[length(names)+1] <- "open binary"
out[length(out)+1] <- time(DT <- read.fst("~/1e7.fst"))

# sort and duplicates  
setDT(DT)
names[length(names)+1] <- "sort string"
out[length(out)+1] <- time(setkeyv(DT, c("id3")))
names[length(names)+1] <- "sort int"
out[length(out)+1] <- time(setkeyv(DT, c("id6")))
names[length(names)+1] <- "sort float"
out[length(out)+1] <- time(setkeyv(DT, c("v3")))
names[length(names)+1] <- "sort all"
out[length(out)+1] <- time(setkeyv(DT, c("id1","id2","id3", "id4", "id5", "id6")))
names[length(names)+1] <- "distinct by int"
out[length(out)+1] <- time(uniqueN(DT, by = c("id3")))
names[length(names)+1] <- "distinct by 3 int"
out[length(out)+1] <- time(uniqueN(DT, by = c("id1", "id2", "id3")))
names[length(names)+1] <- "keep distinct"
out[length(out)+1] <- time(unique(DT, by = c("id2", "id3")))

# merge 
DT <- read.fst("~/1e7.fst") 
setDT(DT)
f <- function(){
	DT_merge <- read.fst("merge_string.fst")
	setDT(DT_merge)
	setkeyv(DT, c("id1", "id3"))
	setkeyv(DT_merge, c("id1", "id3")) 
	merge(DT, DT_merge, all.x = TRUE, all.y = FALSE) 
}
names[length(names)+1] <- "merge string"
out[length(out)+1] <- time(f())

DT <- read.fst("~/1e7.fst") 
setDT(DT)
f <- function(){
	DT_merge <- read.fst("merge_int.fst")
	setDT(DT_merge)
	setkeyv(DT, c("id4", "id6"))
	setkeyv(DT_merge, c("id4", "id6")) 
	merge(DT, DT_merge, all.x = TRUE, all.y = FALSE) 
}
names[length(names)+1] <- "merge int"
out[length(out)+1] <- time(f())


# append 
names[length(names)+1] <- "append"
DT1 <- copy(DT) 
out[length(out)+1] <- time(rbindlist(list(DT,DT1), fill = TRUE))

# reshape
DT <- read.fst("~/1e7.fst") 
setDT(DT)
DT1 <- unique(DT, by = c("id1", "id2", "id3"))
DT1 <- DT1[1:(nrow(DT1)/10)]
names[length(names)+1] <- "reshape long"
out[length(out)+1] <- time(DT2 <- gather(DT1, variable, value, id4, id5, id6, v1, v2, v3))
rm(DT1) 
names[length(names)+1] <- "reshape wide"
out[length(out)+1] <- time(DT3 <- spread(DT2, variable, value))
rm(list = c("DT2", "DT3"))

# recode
f <- function(){
	DT[v1 == 1, v1_name := "first"]
	DT[v1 %in% c(2,3), v1_name := "second"]
	DT[v1 %in% c(4,5), v1_name := "third"]
}
names[length(names)+1] <- "recode"
out[length(out)+1] <- time(f())
DT[, v1_name := NULL]

# functions
names[length(names)+1] <- "xtile"
out[length(out)+1] <- time(DT[, temp := xtile(v3, 10)])
DT[, temp := NULL] 
names[length(names)+1] <- "group"
out[length(out)+1] <- time(DT[, temp := .GRP, by =  c("id1", "id2", "id3")])
DT[, temp := NULL]

# sum of large groups
names[length(names)+1] <- "sum large group"
out[length(out)+1] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id1")])
DT[, temp := NULL] 
# sum of smaller groups
names[length(names)+1] <- "sum small group"
out[length(out)+1] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id3")])
DT[, temp := NULL] 
# groups defined by int
names[length(names)+1] <- "mean small group"
out[length(out)+1] <- time(DT[, temp := mean(v3, na.rm = TRUE) , by = c("id6")])
DT[, temp := NULL] 



# groups defined by multiple string
names[length(names)+1] <- "mean large group"
out[length(out)+1] <- time(DT[, temp := mean(v3, na.rm = TRUE) , by = c("id1", "id2", "id3")])
DT[, temp := NULL] 
names[length(names)+1] <- "sd small groups"
out[length(out)+1] <- time(DT[, temp := sd(v3, na.rm = TRUE), by = c("id3")])
DT[, temp := NULL] 
names[length(names)+1] <- "sd large groups"
out[length(out)+1] <- time(DT[, temp := sd(v3, na.rm = TRUE), by = c("id1", "id2", "id3")])
DT[, temp := NULL] 

# collapse large groups
names[length(names)+1] <- "collapse large groups"
out[length(out)+1] <- time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id1")])

# collapse small groups
names[length(names)+1] <- "collapse small groups"
out[length(out)+1] <- time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id3")])


# regress
DT1 <- DT[1:(nrow(DT)/2)]
names[length(names)+1] <- "reg"
out[length(out)+1] <- time(felm(v3 ~ v1 + v2 + id4 + id5, DT1))
names[length(names)+1] <- "reg fe"
out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5 + as.factor(v1), DT1))
names[length(names)+1] <- "reg hfe"
out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5  + as.factor(v1) | id6 | 0 | id6, DT1))
names[length(names)+1] <- "reg 2 hfe"
out[length(out)+1] <- time(felm(v3 ~  v2 + id4 + id5  + as.factor(v1) | id6 + id3 | 0 | id6, DT1))


# run benchmark
fwrite(data.table(command = names, result = out), "~/resultR1e7.csv")