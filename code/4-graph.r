library(data.table)
library(tidyr)
library(stringr) 
library(ggplot2) 

DT = fread("~/resultR1e7.csv")
DT2 = fread("~/resultStata1e7.csv")
setnames(DT, "result", "R")
DT[, Stata := DT2[["result"]]]


DT=gather(DT, language, value, Stata, R)
setDT(DT)
DT[,value:=value/60]
DT[, command = factor(command, levels=rev(unique(command)))]

DT[command == "open csv", value := value/3]
DT[command == "group", value := value/2]
DT[command == "sd large groups", value := value/7]
DT[command == "reg 2 hfe", value := value/2]



image = ggplot(DT,aes(x=command,y=value,fill=language,width=0.6)) + geom_bar(position=position_dodge(width=0.6),stat="identity")+ coord_flip()+scale_fill_discrete(breaks=c("Stata","R")) + ylab("Time (min)")

ggsave(filename="~/1e7.svg", image)

ggsave(filename="~/1e7.png", image)
