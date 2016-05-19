# To run the script, download the relevant packages:
# install.packages("data.table")
# install.packages("tidyr")
# install.packages("statar")
# install.packages("biglm")
# install.packages("lfe")

# loading packages
library(data.table)
library(tidyr)
library(statar)
library(lfe)

# setting options
options(mc.cores=4)

# creating the file to merge with
DTmerge <- fread("merge.csv", showProgress=FALSE)
saveRDS(DTmerge, file = "merge.rds", compress = FALSE)


# define the time function
time <- function(x){sum(system.time(x)[1:2])}

# defining the benchmark function
benchmark <- function(file){
	out <- NULL
	csvfile <- paste0(file, ".csv")
	rdsfile <- paste0(file, ".rds")

	# write and read
	out[length(out)+1] <- time(DT <- fread(csvfile, showProgress=FALSE))
	out[length(out)+1] <- time(saveRDS(DT, file = rdsfile, compress = FALSE))
	out[length(out)+1] <- time(DT <- readRDS(rdsfile))

	# sort and duplicates  
	out[length(out)+1] <- time(setkeyv(DT, c("id3")))
	out[length(out)+1] <- time(setkeyv(DT, c("id6")))
	out[length(out)+1] <- time(setkeyv(DT, c("v3")))
	out[length(out)+1] <- time(setkeyv(DT, c("id1","id2","id3", "id4", "id5", "id6")))
	out[length(out)+1] <- time(uniqueN(DT, by = c("id3")))
	out[length(out)+1] <- time(uniqueN(DT, by = c("id1", "id2", "id3")))
	out[length(out)+1] <- time(unique(DT, by = c("id2", "id3")))


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
	out[length(out)+1] <- time(DT[, temp := .GRP, by =  c("id1", "id2", "id3")])
	DT[, temp := NULL] 
	
	# mean of large groups
	out[length(out)+1] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = id1])
	DT[, temp := NULL] 
	# mean of smaller groups
	out[length(out)+1] <- time(DT[, temp := sum(v3, na.rm = TRUE), by = id3])
	DT[, temp := NULL] 
	# groups defined by int
	out[length(out)+1] <- time(DT[, temp := mean(v3, na.rm = TRUE) , by = id6])
	DT[, temp := NULL] 
	# groups defined by multiple string
	out[length(out)+1] <- time(DT[, temp := mean(v3, na.rm = TRUE) , by = c("id1", "id2", "id3")])
	DT[, temp := NULL] 
	out[length(out)+1] <- time(DT[, temp := sd(v3, na.rm = TRUE), by = id3])
	DT[, temp := NULL] 

	# collapse large groups
	out[length(out)+1] <- time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id1")])

	# collapse small groups
	out[length(out)+1] <- time(DT[, list(v1 = mean(v1, na.rm = TRUE), v2 = mean(v2, na.rm = TRUE), v3 = sum(v3, na.rm = TRUE),  sd = sd(v3, na.rm = TRUE)), by = c("id3")])


	# regress
	DT1 <- DT[1:(nrow(DT)/2)]
	out[length(out)+1] <- time(felm(v3 ~ v1 + v2 + id4 + id5, DT1))
	out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5 + as.factor(v1), DT1))
	out[length(out)+1] <- time(felm(v3 ~ v2 + id4 + id5  + as.factor(v1) | id6 | 0 | id6, DT1))
	out[length(out)+1] <- time(felm(v3 ~  v2 + id4 + id5  + as.factor(v1) | id6 + id3 | 0 | id6, DT1))


	# Vector / matrix functions
	loop_sum <- function(v){
		a <- 0
		for (obs in 1:(length(v))){
			a <- a + v[obs] 
		}
		a
	}
	out[length(out)+1] <- time(loop_sum(DT[["id4"]]))

	loop_generate <- function(n){
		v = rep(0, n)
		for (obs in 1:n){
			v[obs] <- 1
		}
		v
	}
	out[length(out)+1] <- time(DT[, temp := loop_generate(nrow(DT))])

	setDF(DT)
	out[length(out)+1] <- time(crossprod(as.matrix(select(DT, v2, id4, id5, id6))))
	setDT(DT)


	# return time vector
	out

}

# run benchmark
benchmark("2e6")
benchmark("1e7")
benchmark("1e8")





