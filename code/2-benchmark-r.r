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


# defining the time function
time <- function(x){sum(system.time(x)[1:2])}

# defining the benchmark function
benchmark <- function(file){
	out <- NULL
	csvfile <- paste0(file, ".csv")
	rdsfile <- paste0(file, ".rds")
	# write and read
	out[length(out)+1] <- time(DT <- fread(csvfile, showProgress=FALSE))
	out[length(out)+1] <- time(saveRDS(DT, file = rdsfile, compress = FALSE))
	rm(list = setdiff(ls(),"out")) 
	out[length(out)+1] <- time(DT <- readRDS(rdsfile))

	# sort and duplicates  
	out[length(out)+1] <- time(setkeyv(DT, c("id3")))
	out[length(out)+1] <- time(setkeyv(DT, c("id6")))
	out[length(out)+1] <- time(setkeyv(DT, c("v3")))
	out[length(out)+1] <- time(setkeyv(DT, c("id1","id2","id3", "id4", "id5", "id6")))
	out[length(out)+1] <- time(sum(!duplicated(DT, by = c("id3"))))

	# merge 
	DT <- readRDS(rdsfile) 
	DT_merge <- readRDS("merge.rds")
	f <- function(){
		setkey(DT, id1, id3)
		setkey(DT_merge, id1, id3) 
		merge(DT, DT_merge, all.x = TRUE, all.y = FALSE) 
	}
	out[length(out)+1] <- time(f())

	# append 
	DT1 <- copy(DT) 
	out[length(out)+1] <- time(rbindlist(list(DT,DT1), fill = TRUE))

	# reshape
	rm(list = setdiff(ls(),"out"))
	DT <- readRDS(rdsfile) 
	DT1 <- unique(DT, by = c("id1", "id2", "id3"))
	DT1 <- DT1[1:(nrow(DT1)/10)]
	out[length(out)+1] <- time(DT2 <- gather(DT1, variable, value, id4, id5, id6, v1, v2, v3))
	rm(DT1) 
	out[length(out)+1] <- time(DT3 <- spread(DT2, variable, value))
	rm(list = c("DT2", "DT3"))

	# recode
	f <- function(){
		DT[v1 == 1, v1_name := "first"]
		DT[v1 %in% c(2,3), v1_name := "second"]
		DT[v1 %in% c(4,5), v1_name := "third"]
	}
	out[length(out)+1] <- time(f())
	DT[, v1_name := NULL]

	# functions
	out[length(out)+1] <- time(DT[, temp := bin(v3, 10)])
	DT[, temp := NULL] 
	out[length(out)+1] <- time(DT[, temp := .GRP, by = id3])
	DT[, temp := NULL] 
	
	# split apply combine
	rm(list = setdiff(ls(),"out"))
	out[length(out)+1] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = id3])
	DT[, temp := NULL] 
	out[length(out)+1] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = c("id3", "id2", "id1")])
	DT[, temp := NULL] 
	out[length(out)+1] <- time(DT[, temp := mean(v3, na.rm = TRUE) , by = id6])
	DT[, temp := NULL] 
	out[length(out)+1] <- time(DT[, temp := mean(v3, na.rm = TRUE) , by = c("id6", "id5", "id4")])
	DT[, temp := NULL] 
	out[length(out)+1] <- time(DT[, temp := mean(v3, na.rm = TRUE) , by = c("id1", "id2", "id3", "id4", "id5", "id6")])
	DT[, temp := NULL]
	DT1 <- DT[1:(nrow(DT)/2)]
	out[length(out)+1] <- time(DT1[, temp := sd(v3, na.rm = TRUE), by = id3])
	DT[, temp := NULL] 

	# regress
	out[length(out)+1] <- time(biglm(v3 ~ v2 + id4 + id5 + id6, DT1))
	out[length(out)+1] <- time(biglm(v3 ~ v2 + id4 + id5 + id6 + as.factor(v1), DT1))
	out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5 + id6 + as.factor(v1) | id1 | 0 | id1, DT1))
	out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5 + id6  | id1 + id2 | 0 | id1, DT1))
	# return time vector
	out
}


# run benchmark
benchmark("2e6")
benchmark("1e7")
benchmark("1e8")

