# To run the script, you first need to ownload the relevant packages:
# install.packages("data.table")
# install.packages("tidyr")
# install.packages("statar")
# install.packages("biglm")
# install.packages("lfe")

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


# Define a function with the set of commands
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
	out[8] <- sum(system.time(length(!duplicated(DT, by = c("id3"))))[1:2])

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


# Run commands
benchmark("2e6.csv")
benchmark("1e7.csv")
benchmark("1e8.csv")
