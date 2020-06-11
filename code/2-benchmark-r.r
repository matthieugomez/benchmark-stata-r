# To run the script, download the relevant packages:
# install.packages("data.table")
# install.packages("fst")
# install.packages("statar")
# install.packages("fixest")
# install.packages("ggplot")


# loading packages
library(data.table)
library(fixest)
library(statar)
library(fst)
library(ggplot2)


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
 
names <- append(names, "open csv")
out <- append(out, time(DT <- fread("~/statabenchmark/1e7.csv", data.table = FALSE)))

names <- append(names, "save binary")
out <- append(out, time(write.fst(DT, "~/statabenchmark/1e7.fst")))

names <- append(names, "open binary")
out <- append(out, time(DT <- read.fst("~/statabenchmark/1e7.fst")))

# sort and duplicates  
setDT(DT)

names <- append(names, "sort string")
out <- append(out, time(setkeyv(DT, c("id3"))))

names <- append(names, "sort int")
out <- append(out, time(setkeyv(DT, c("id6"))))

names <- append(names, "sort float")
out <- append(out, time(setkeyv(DT, c("v3"))))

names <- append(names, "count distinct strings")
out <- append(out, time(uniqueN(DT, by = c("id3"))))

names <- append(names, "count distinct ints")
out <- append(out, time(uniqueN(DT, by = c("id6"))))

# merge 
DT <- read.fst("~/statabenchmark/1e7.fst") 
setDT(DT)
f <- function(){
	DT_merge <- read.fst("~/statabenchmark/merge_string.fst")
	setDT(DT_merge)
	setkey(DT, id1, id3)
	setkey(DT_merge, id1, id3)
	merge(DT, DT_merge, all.x = TRUE, all.y = FALSE) 
}

names <- append(names, "merge string")
out <- append(out, time(f()))

DT <- read.fst("~/statabenchmark/1e7.fst") 
setDT(DT)
f <- function(){
	DT_merge <- read.fst("~/statabenchmark/merge_int.fst")
	setDT(DT_merge)
	setkey(DT, id4, id6)
	setkey(DT_merge, id4, id6)
	merge(DT, DT_merge, all.x = TRUE, all.y = FALSE) 
}

names <- append(names, "merge int")
out <- append(out, time(f()))


# append 

names <- append(names, "append")
DT1 <- copy(DT) 
out <- append(out, time(rbindlist(list(DT,DT1), fill = TRUE)))

# reshape
DT <- read.fst("~/statabenchmark/1e7.fst") 
setDT(DT)
DT1 <- unique(DT, by = c("id1", "id2", "id3"))
DT1 <- DT1[1:(nrow(DT1)/10),]

names <- append(names, "reshape long")
out <- append(out, time(DT2 <- melt(DT1, id.vars = c("id1", "id2", "id3"))))
rm(DT1) 

names <- append(names, "reshape wide")
out <- append(out, time(DT3 <- dcast(DT2, id1 + id2 + id3 ~ variable, value.var = "value")))
rm(list = c("DT2", "DT3"))

# recode
f <- function(){
	DT[v1 == 1, v1_name := "first"]
	DT[v1 %in% c(2,3), v1_name := "second"]
	DT[v1 %in% c(4,5), v1_name := "third"]
}

names <- append(names, "recode")
out <- append(out, time(f()))
DT[, v1_name := NULL]

# functions

names <- append(names, "xtile")
out <- append(out, time(DT[, temp := xtile(v3, 10)]))
DT[, temp := NULL] 

names <- append(names, "group strings")
out <- append(out, time(DT[, temp := .GRP, by =  c("id1", "id3")]))
DT[, temp := NULL]

names <- append(names, "group int")
out <- append(out, time(DT[, temp := .GRP, by =  c("id4", "id6")]))
DT[, temp := NULL]

# sum groups

names <- append(names, "sum over few groups (string)")
out <- append(out, time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id1")]))
DT[, temp := NULL] 

names <- append(names, "sum over many groups (string)")
out <- append(out, time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id3")]))
DT[, temp := NULL] 

names <- append(names, "sum over few groups (int)")
out <- append(out, time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id4")]))
DT[, temp := NULL] 

names <- append(names, "sum over many groups (int)")
out <- append(out, time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id6")]))
DT[, temp := NULL] 


# sd groups

names <- append(names, "sd over few groups (int)")
out <- append(out, time(DT[, temp := sd(v3, na.rm = TRUE), by = c("id4")]))
DT[, temp := NULL] 

names <- append(names, "sd over many groups (int)")
out <- append(out, time(DT[, temp := sd(v3, na.rm = TRUE), by = c("id6")]))
DT[, temp := NULL] 



# collapse large groups

names <- append(names, "collapse over few groups")
out <- append(out, time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id1")]))

# collapse small groups

names <- append(names, "collapse over many groups")
out <- append(out, time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id3")]))


# regress
DT1 <- DT[1:(nrow(DT)/2),]

names <- append(names, "reg")
out <- append(out, time(feols(v3 ~ v1 + v2 + id4 + id5, DT1)))

names <- append(names, "reg fe")
out <- append(out, time(feols(v3 ~ v2 + id4 + id5 + as.factor(v1), DT1)))

names <- append(names, "reg hfe")
## Automatically clusters by id6 too
out <- append(out, time(feols(v3 ~ v2 + id4 + id5  + as.factor(v1) | id6, DT1))) 

names <- append(names, "reg 2 hfe")
## Automatically clusters by id6 too)
out <- append(out, time(feols(v3 ~  v2 + id4 + id5  + as.factor(v1) | id6 + id3, DT1)))

# plot

names <- append(names, "plot 1000 points")
out <- append(out,  time(ggsave("~/statabenchmark/plot.pdf", ggplot(DT1[1:1000], aes(x = v1, y = v2)) +  geom_point())))

# run benchmark
fwrite(data.table(command = names, result = out), "~/statabenchmark/resultR1e7.csv")
