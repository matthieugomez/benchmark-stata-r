library(data.table)
library(tidyr)
library(stringr) 
library(ggplot2) 
library(scales)
DT = fread("~/resultR1e7.csv")
DT2 = fread("~/resultStata1e7.csv")
setnames(DT, "result", "R")
DT[, Stata := DT2[["result"]]]

DT[, value := Stata / R]
DT[, language := "Stata"]
setDT(DT)


DT[, command := factor(command, levels=rev(unique(command)))]
image = ggplot(DT,aes(x=command,y=value, fill = "red", width=0.2)) + geom_bar(position=position_dodge(width=0.2),stat="identity")+ coord_flip()+scale_fill_discrete(breaks=c("Stata","R")) + ylab("Time using Stata / Time using R") +  scale_y_log10(breaks = c(0.1, 1, 10, 100),
              labels = c("0.1", "1", "10", "100"))
ggsave(filename="~/1e7.svg", image)
ggsave(filename="~/1e7.png", image)
