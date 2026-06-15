source("..\\BaseFunctions.R") #load file of common functions

#load data
mydata<-base.loaddata.venues.2012()
#mydata<-base.loaddata.venues.all()
#mydata<-mydata[mydata$venue==3,]

###############################
#Create Funtions
###############################
caption.percents<-"Values represent percentage of respondents +- 95% confidence intervals with sample size given in parenthesis."
caption.means<-"Values represent mean response +- 95% confidence intervals with sample size given in parenthesis."
caption.medians<-"Values represent upper 95% median confidence limit, median response, and lower 95% median confidence limit with sample size given in parenthesis"
labels.agree<-"Answers included (from 1 to 5): Strongly Disagree, Disagree, Neutral, Agree, Strongly Agree."
labels.importance<-"Answers included (from 1 to 5): Not At All Important, Slightly Important, Moderately Important, Very Important, Extremely Important."
labels.importance2<-"Answers included (from 1 to 5): Not At All Important, Not Very Important, Somewhat Important, Very Important, Extremely Important."
labels.release<-"Answers included (from 1 to 5): Kept All, Kept Many, Kept Half, Kept A Few, Kept None."
labels.freq<-"Answers included: Did Not Fish, 1, 2, 3, 4, 5, 6-8, 9-11, 12-14, 15-17, 18-20, and Over 20."
labels.satisfaction<-"Answers included (from 1 to 5): Very Satisfied, Somewhat Satisfied, Neutral, Somewhat Dissatisfied, and Very Dissatisfied."

CreateSelectAllTableSingle<- function(myDataFrame){
  OPperc<-round(table(myDataFrame[,c(1)])["1"]/length(myDataFrame[,c(1)])*100, 1)
  for (i in 2:length(myDataFrame)){
    OPperc<-cbind(OPperc, round(table(myDataFrame[,c(i)])["1"]/length(myDataFrame[,c(i)])*100, 1))
  }
  
  OPanswerN<-table(myDataFrame[,c(1)])["1"]
  for (i in 2:length(myDataFrame)){
    OPanswerN<-cbind(OPanswerN, table(myDataFrame[,c(i)])["1"])
  }

  OPquestionN<-length(myDataFrame[,c(1)])
  for (i in 2:length(myDataFrame)){
    OPquestionN<-cbind(OPquestionN, length(myDataFrame[,c(i)]))
  }
   
  OPperc<-t(OPperc)
  OPanswerN<-t(OPanswerN)
  OPquestionN<-t(OPquestionN)

  OPci<-round((1.96 * (sqrt((OPperc/100)*(1-(OPperc/100))/OPquestionN)))*100,1)
  
  tmpOP<-data.frame(paste(OPperc[,1],"+-", OPci[,1], " (", OPanswerN[,1],")", sep=""))
  colnames(tmpOP)<-"Overall (%)"
  return (tmpOP)
  rm ("OPperc", "OPanswerN", "OPquestionN", "OPci", "tmpOP")
  
}

CreateSelectAllTable<-function(myDataColumns, myAnsweredQuestionFlag){
tmpMyData<-mydata[mydata[,myAnsweredQuestionFlag]==TRUE,]  
tmpData<-CreateSelectAllTableSingle(tmpMyData[,myDataColumns])
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$Resi==1,myDataColumns])) )
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$Resi==2,myDataColumns])) )
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$E2==1,myDataColumns])) )
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$E2==2,myDataColumns])) )
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$E3==1,myDataColumns])) )
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$E3==2,myDataColumns])) )
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$E3==3,myDataColumns])) )
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$E3==4,myDataColumns])) )
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$E3==5,myDataColumns])) )
tmpData<-cbind(tmpData,CreateSelectAllTableSingle(data.frame(tmpMyData[tmpMyData$E3==6,myDataColumns])) )
colnames(tmpData)<-c("Overall", "Resident", "Non-Resident","Male", "Female","16-24","25-34","35-44","45-54","55-64","65+")
return(tmpData)
rm ("tmpData", "tmpMyData")

}

CreateSelectOneTable<- function(myDataColumn, numAnswers){
#create dummy table for when there are no answers in any column
tmpDummy<-data.frame("answer"=1:numAnswers)
  
tmpPerc<-prop.table(table(mydata[mydata[myDataColumn]>0, c(myDataColumn)]))
tmpPerc<-cbind(tmpPerc,prop.table(table(mydata[mydata[myDataColumn]>0 & mydata$Resi>0, c(myDataColumn,"Resi")]),2))
tmpPerc<-cbind(tmpPerc,prop.table(table(mydata[mydata[myDataColumn]>0 & mydata$E2>0, c(myDataColumn,"E2")]),2))
tmpPerc<-cbind(tmpPerc,prop.table(table(mydata[mydata[myDataColumn]>0 & mydata$E3>0, c(myDataColumn,"E3")]),2))
tmpPerc<-merge(tmpDummy, tmpPerc, all.x=TRUE, by.x="answer", by.y="row.names")
tmpPerc[is.na(tmpPerc)] <- 0

tmpAnswerN<-table(mydata[mydata[myDataColumn]>0, c(myDataColumn)])
tmpAnswerN<-cbind(tmpAnswerN, table(mydata[mydata[myDataColumn]>0 & mydata$Resi>0, c(myDataColumn,"Resi")]))
tmpAnswerN<-cbind(tmpAnswerN, table(mydata[mydata[myDataColumn]>0 & mydata$E2>0, c(myDataColumn,"E2")]))
tmpAnswerN<-cbind(tmpAnswerN, table(mydata[mydata[myDataColumn]>0 & mydata$E3>0, c(myDataColumn,"E3")]))
tmpAnswerN<-merge(tmpDummy, tmpAnswerN, all.x=TRUE, by.x="answer", by.y="row.names")
tmpAnswerN[is.na(tmpAnswerN)] <- 0

tmpQuestionN<-length(mydata[mydata[myDataColumn]>0, c(myDataColumn)])
tmpQuestionN<-c(tmpQuestionN, apply(table(mydata[mydata[myDataColumn]>0 & mydata$Resi>0, c(myDataColumn,"Resi")]), c(2),FUN=sum))
tmpQuestionN<-c(tmpQuestionN, apply(table(mydata[mydata[myDataColumn]>0 & mydata$E2>0, c(myDataColumn,"E2")]), c(2),FUN=sum))
tmpQuestionN<-c(tmpQuestionN, apply(table(mydata[mydata[myDataColumn]>0 & mydata$E3>0, c(myDataColumn,"E3")]), c(2),FUN=sum))
#remove answer dummy column
tmpPerc<-tmpPerc[,2:length(tmpPerc)]
tmpAnswerN<-tmpAnswerN[,2:length(tmpAnswerN)]

tmpCI<-1.96 * (sqrt((tmpPerc*(1-tmpPerc))/tmpQuestionN))

tmpPerc<-RoundTable(tmpPerc[,1:length(tmpPerc)])
tmpCI<-RoundTable(tmpCI)
tmpOP<-data.frame(paste(tmpPerc[,1],"+-", tmpCI[,1], " (", tmpAnswerN[,1],")", sep=""))
for (i in 2:11){
  tmpOP<- cbind(tmpOP,paste(tmpPerc[,i],"+-", tmpCI[,i], " (", tmpAnswerN[,i],")", sep=""))
}
colnames(tmpOP)<-c("Overall", "Resident", "Non-Resident","Male", "Female","16-24","25-34","35-44","45-54","55-64","65+")
return (tmpOP)
rm ("tmpPerc", "tmpAnswerN", "tmpQuestionN", "tmpCI", "tmpOP", "tmpDummy")
}

RoundTable<- function(myDataFrame){
for (i in 1:length(colnames(myDataFrame))) {
  myDataFrame[,i]<-round(myDataFrame[,i]*100,1)
}
return (myDataFrame)
}

CreateSelectOneTableMeansSingle<- function(myDataColumn){
  tmpMean<-data.frame(mean(mydata[mydata[myDataColumn]>0, c(myDataColumn)],na.rm=TRUE))
  tmpMean<-data.frame(c(tmpMean,ddply(mydata[mydata[myDataColumn]>0 & mydata$Resi>0,c(myDataColumn, "Resi")], "Resi", colMeans,na.rm=TRUE)[c(1,2),1]))
  tmpMean<-c(tmpMean,ddply(mydata[mydata[myDataColumn]>0 & mydata$E2>0,c(myDataColumn, "E2")], "E2", colMeans, na.rm=TRUE)[c(1,2),1])
  tmpMean<-c(tmpMean,ddply(mydata[mydata[myDataColumn]>0 & mydata$E3>0,c(myDataColumn, "E3")], "E3", colMeans, na.rm=TRUE)[1:6,1])
  tmpMean<-round(data.frame(tmpMean),2)
  
  tmpAnswerN<-length(mydata[mydata[myDataColumn]>0 & !is.na(mydata[myDataColumn]), c(myDataColumn)])
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$Resi==1  & !is.na(mydata[myDataColumn]),c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$Resi==2 & !is.na(mydata[myDataColumn]),c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E2==1 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E2==2 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==1 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==2 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==3 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==4 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==5 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==6 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-data.frame(tmpAnswerN)
  
    
  #tmpAnswerN<-table(mydata[mydata[myDataColumn]>0,c(myDataColumn)])
  #tmpAnswerN<-cbind(tmpAnswerN, table(mydata[mydata[myDataColumn]>0 & mydata$Resi>0,c(myDataColumn, "Resi")]))
  #tmpAnswerN<-cbind(tmpAnswerN, table(mydata[mydata[myDataColumn]>0 & mydata$E2>0, c(myDataColumn,"E2")]))
  #tmpAnswerN<-cbind(tmpAnswerN, table(mydata[mydata[myDataColumn]>0 & mydata$E3>0, c(myDataColumn,"E3")]))
  #tmpAnswerN
  
  tmpQuestionSD<-sd(mydata[mydata[myDataColumn]>0 & !is.na(mydata[myDataColumn]), c(myDataColumn)])
  tmpQuestionSD<-c(tmpQuestionSD, ddply(mydata[mydata[myDataColumn]>0 & mydata$Resi>0 & !is.na(mydata[myDataColumn]), c(myDataColumn,"Resi")], "Resi",sd)[,1])
  tmpQuestionSD<-c(tmpQuestionSD, ddply(mydata[mydata[myDataColumn]>0 & mydata$E2>0 & !is.na(mydata[myDataColumn]), c(myDataColumn,"E2")], "E2",sd)[,1])
  tmpQuestionSD<-c(tmpQuestionSD, ddply(mydata[mydata[myDataColumn]>0 & mydata$E3>0 & !is.na(mydata[myDataColumn]), c(myDataColumn,"E3")], "E3",sd)[,1])
  tmpQuestionSD<-data.frame(t(tmpQuestionSD))
  
  tmpCI<-round(1.96 * (tmpQuestionSD/sqrt(tmpAnswerN)),2)
  
  tmpOP<-data.frame(paste(tmpMean,"+-", tmpCI, " (", tmpAnswerN,")", sep=""))
  colnames(tmpOP)<-"OP"
  tmpOP<-t(tmpOP)
  colnames(tmpOP)<-c("Overall", "Resident", "Non-Resident","Male", "Female","16-24","25-34","35-44","45-54","55-64","65+")
  return (tmpOP)
  rm ("tmpMean", "tmpAnswerN", "tmpQuestionSD", "tmpCI", "tmpOP")
}

CreateSelectAllTableMeans<-function(myDataColumns){
  tmpMyData<-mydata
  tmpData<-CreateSelectOneTableMeansSingle(myDataColumns[1])
  if (length(myDataColumns)>1){
    for (i in 2:length(myDataColumns)){
      tmpData<-rbind(tmpData,CreateSelectOneTableMeansSingle(myDataColumns[i]))
    }
  }
  colnames(tmpData)<-c("Overall", "Resident", "Non-Resident","Male", "Female","16-24","25-34","35-44","45-54","55-64","65+")
  return(tmpData)
  rm ("tmpData", "tmpMyData", i)
}

CreateSelectOneTableMediansSingle<- function(myDataColumn){
  tmpMean<-data.frame(median(mydata[mydata[myDataColumn]>0, c(myDataColumn)],na.rm=TRUE))
  tmpMean<-data.frame(c(tmpMean,ddply(mydata[mydata[myDataColumn]>0 & mydata$Resi>0,c(myDataColumn, "Resi")], "Resi", numcolwise(median),na.rm=TRUE)[c(1,2),2]))
  tmpMean<-data.frame(c(tmpMean,ddply(mydata[mydata[myDataColumn]>0 & mydata$E2>0,c(myDataColumn, "E2")], "E2", numcolwise(median), na.rm=TRUE)[c(1,2),2]))
  tmpMean<-data.frame(c(tmpMean,ddply(mydata[mydata[myDataColumn]>0 & mydata$E3>0,c(myDataColumn, "E3")], "E3", numcolwise(median), na.rm=TRUE)[1:6,2]))
  tmpMean<-round(data.frame(tmpMean),2)
  
  
  tmpUpperCI<-GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & !is.na(mydata[myDataColumn]), c(myDataColumn)])
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$Resi==1  & !is.na(mydata[myDataColumn]),c(myDataColumn)]))
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$Resi==2 & !is.na(mydata[myDataColumn]),c(myDataColumn)]))
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$E2==1 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$E2==2 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$E3==1 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$E3==2 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$E3==3 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$E3==4 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$E3==5 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpUpperCI<-cbind(tmpUpperCI, GetMedianUpperCI(mydata[mydata[myDataColumn]>0 & mydata$E3==6 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpLowerCI<-GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & !is.na(mydata[myDataColumn]), c(myDataColumn)])
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$Resi==1  & !is.na(mydata[myDataColumn]),c(myDataColumn)]))
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$Resi==2 & !is.na(mydata[myDataColumn]),c(myDataColumn)]))
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$E2==1 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$E2==2 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$E3==1 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$E3==2 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$E3==3 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$E3==4 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$E3==5 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpLowerCI<-cbind(tmpLowerCI, GetMedianLowerCI(mydata[mydata[myDataColumn]>0 & mydata$E3==6 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  
    
  tmpAnswerN<-length(mydata[mydata[myDataColumn]>0 & !is.na(mydata[myDataColumn]), c(myDataColumn)])
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$Resi==1  & !is.na(mydata[myDataColumn]),c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$Resi==2 & !is.na(mydata[myDataColumn]),c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E2==1 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E2==2 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==1 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==2 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==3 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==4 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==5 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-cbind(tmpAnswerN, length(mydata[mydata[myDataColumn]>0 & mydata$E3==6 & !is.na(mydata[myDataColumn]), c(myDataColumn)]))
  tmpAnswerN<-data.frame(tmpAnswerN)
  
  
  tmpOP<-data.frame(paste(tmpUpperCI, "/", tmpMean,"/",  tmpLowerCI, " (", tmpAnswerN,")", sep=""))
  colnames(tmpOP)<-"OP"
  tmpOP<-t(tmpOP)
  colnames(tmpOP)<-c("Overall", "Resident", "Non-Resident","Male", "Female","16-24","25-34","35-44","45-54","55-64","65+")
  return (tmpOP)
  rm ("tmpMean", "tmpAnswerN", "tmpQuestionSD", "tmpCI", "tmpOP")
}

CreateSelectAllTableMedians<-function(myDataColumns){
  tmpMyData<-mydata 
  tmpData<-CreateSelectOneTableMediansSingle(myDataColumns[1])
  if (length(myDataColumns)>1){
  for (i in 2:length(myDataColumns)){
    tmpData<-rbind(tmpData,CreateSelectOneTableMediansSingle(myDataColumns[i]))
  }}
  colnames(tmpData)<-c("Overall", "Resident", "Non-Resident","Male", "Female","16-24","25-34","35-44","45-54","55-64","65+")
  return(tmpData)
  rm ("tmpData", "tmpMyData", i)
}

CreatePercentageTablesForScales<-function(numAnswers, myDataColumns){
tmpOP<-CreateSelectOneTable(myDataColumns[1],numAnswers)
  for (i in 2:length(myDataColumns)){
    tmpData<-CreateSelectOneTable(myDataColumns[i], numAnswers)
    tmpOP<-rbind(tmpOP, tmpData)
  }
  return (tmpOP)
  rm("tmpOP", "tmpData", i)
}

GetMedianUpperCI<-function(x){
  bootmed=apply(matrix(sample(x,rep=TRUE,10^4*length(x)),nrow=10^4),1,median)
  ci.upper<-quantile(bootmed,c(.025,0.975))[1]
  return(ci.upper)
  rm("ci")
}

GetMedianLowerCI<-function(x){
  bootmed=apply(matrix(sample(x,rep=TRUE,10^4*length(x)),nrow=10^4),1,median)
  ci.lower<-quantile(bootmed,c(.025, 0.975))[2]
  return(ci.lower)
  rm("ci")
}

wdMyTable<-function (data, caption = "", caption2="", caption3="", caption.pos = "above", bookmark = NULL, 
                     pointsize = 9, padding = 5, autoformat = 1, row.names = TRUE,  
                     align = if (row.names) c("l", rep("r", ncol(data))) else c(rep("r", 
                                                                                    ncol(data))), hlines = NULL, wdapp = .R2wd) 
{
  if (autoformat < 0) 
    stop("inadmissible autoformat")
  if (!is.null(hlines) && length(hlines) > nrow(data) + 1) 
    stop("length of hlines must be equal to the number of rows in the table + 1")
  wdsel <- try(wdapp[["Selection"]])
  if (is.null(wdsel) || class(wdsel) == "try-error") 
    stop("Word not connected. Run wdGet() first")
  wdopt <- wdapp[["Options"]]
  wddoc <- wdapp[["ActiveDocument"]]
  wdsel$TypeParagraph()
  wdInsertBookmark("R2wdEndmark")
  bookmarkcounter <- wddoc[["Bookmarks"]][["Count"]]
  wdsel$MoveUp()
  nr <- nrow(data)
  nc <- ncol(data)
  if (row.names) {
    out <- matrix("", nrow = nr + 1, ncol = nc + 1)
    out[1 + (1:nr), 1 + (1:nc)] <- as.matrix(data)
    out[1, 1 + (1:nc)] <- colnames(data)
    out[1 + (1:nr), 1] <- row.names(data)
  }
  else {
    out <- matrix("", nrow = nr + 1, ncol = nc)
    out[1 + (1:nr), (1:nc)] <- as.matrix(data)
    out[1, (1:nc)] <- colnames(data)
  }
  tt <- paste(apply(out, 1, paste, collapse = "\t"), collapse = "\n")
  wdsel[["Text"]] <- tt
  tab <- wdsel[["Range"]]$ConvertToTable(1, nr + 1, nc + ifelse(row.names, 
                                                                1, 0))
  tryout <- try({
    tab$AutoFormat(autoformat)
    if (as.numeric(.R2wd[["Version"]]) > 10) {
      tabrows <- tab[["Rows"]]
      try(tabrows[["Height"]] <- pointsize + padding, silent = TRUE)
      try(tabrows[["HeightRule"]] <- 2, silent = TRUE)
      tabcells <- tab[["Range"]][["Cells"]]
      try(tabcells[["VerticalAlignment"]] <- 1, silent = TRUE)
    }
    tab$AutoFitBehavior(1)
    tab[["Range"]]$Select()
    wdsel[["Font"]][["Size"]] <- pointsize
    if (align[1] == "|") {
      tab[["Columns"]]$Item(1)$Select()
      tmp <- wdsel[["Borders"]]$Item(-2)
      tmp[["LineStyle"]] <- wdopt[["DefaultBorderLineStyle"]]
      tmp[["LineWidth"]] <- wdopt[["DefaultBorderLineWidth"]]
      tmp[["Color"]] <- wdopt[["DefaultBorderColor"]]
      align <- align[-1]
    }
    ii <- 0
    for (i in 1:length(align)) {
      if (align[i] == "|") {
        tab[["Columns"]]$Item(ii)$Select()
        tmp <- wdsel[["Borders"]]$Item(-4)
        tmp[["LineStyle"]] <- wdopt[["DefaultBorderLineStyle"]]
        tmp[["LineWidth"]] <- wdopt[["DefaultBorderLineWidth"]]
        tmp[["Color"]] <- wdopt[["DefaultBorderColor"]]
      }
      else {
        ii <- ii + 1
        tab[["Columns"]]$Item(ii)$Select()
        wdselpar <- wdsel[["ParagraphFormat"]]
        wdselpar[["Alignment"]] <- c(l = 0, c = 1, r = 2)[align[i]]
      }
    }
    if (!is.null(hlines)) {
      for (i in 1:length(hlines)) {
        if (hlines[i] != "n") {
          tab[["Rows"]]$Item(i)$Select()
          if (hlines[i] %in% c("b", "bt")) {
            tmp <- wdsel[["Borders"]]$Item(-3)
            tmp[["LineStyle"]] <- wdopt[["DefaultBorderLineStyle"]]
            tmp[["LineWidth"]] <- wdopt[["DefaultBorderLineWidth"]]
            tmp[["Color"]] <- wdopt[["DefaultBorderColor"]]
          }
          if (hlines[i] %in% c("t", "bt")) {
            tmp <- wdsel[["Borders"]]$Item(-1)
            tmp[["LineStyle"]] <- wdopt[["DefaultBorderLineStyle"]]
            tmp[["LineWidth"]] <- wdopt[["DefaultBorderLineWidth"]]
            tmp[["Color"]] <- wdopt[["DefaultBorderColor"]]
          }
        }
      }
    }
    tab[["Range"]]$Select()
    caption <- paste(" ", caption, sep = "")
    wdsel$InsertCaption("Table", paste(". ",caption, paste(" ", caption2, sep="")), "", ifelse(caption.pos == "above", 0, 1), 0)
  
    if (is.null(bookmark)) 
      bookmark <- paste("Table", bookmarkcounter + 1, sep = "")
    tab[["Range"]]$Select()
    wdInsertBookmark(bookmark)
    wddoc[["Bookmarks"]]$Item(bookmarkcounter)$Select()
  })
  if (class(tryout) == "try-error") {
    warning("Error in table construction, removing")
    tab$Delete()
  }
  wdGoToBookmark("R2wdEndmark")
  return()
}

###############################
#setup for Word Output
###############################

base.setup.word.output(paste(wd, "2012_Angler_Survey_MainTables_Output.doc", sep="/"))
wdPageSetup(orientation="landscape", margins=c(.5,.5,1,.5), scope="all")
wdTitle("2012 Licensed Angler Survey Analysis")
wdSection("Main Tables")
wdBody("")

###############################
#A1-Permit Type
###############################
tblData<-CreateSelectOneTable("A1",16)
rownames(tblData)<-c("Resident annual fish","Resident 3-day fish","Resident hunt/fish","Lifetime fish","Lifetime fish & hunt","Fee-exempt permit","Non-resident annual fish","Non-resident 3-day fish","I did not have a permit","Resident 1-day fish","Resident lifetime","Senior hunt/fish","Veteran annual hunt/fish","Non-resident hunt/fish","Non-resident 1-day fish","Non-resident lifetime")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="What type of Nebraska fishing permit did you have during the 2002 license year?", caption2=caption.percents)
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="What type of Nebraska fishing permit did you have during the 2002 license year?", caption2=caption.percents)
wdPageBreak()

###############################
#A2-Did you fish
###############################
tblData<-CreateSelectOneTable("A2",2)
rownames(tblData)<-c("Yes", "No")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="Did you fish in Nebraska during 2002?", caption2=caption.percents)
wdMyTable(tblData[,c(6,7,8,9,10,11)],  caption="Did you fish in Nebraska during 2002?", caption2=caption.percents)

###############################
#A3-Why not fish?
###############################
tblData<-CreateSelectOneTable("A3")
rownames(tblData)<-c("Lack of time", "Dissatisfied with past fishing trips", "No one to fish with", "Lack of access to fishing areas", "Too expensive", "Physically unable to fish", "No longer enjoy fishing", "Other", "Complicated regulations", "Waters too crowded")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="If NO, why didn't you fish in Nebraska in 2012?", caption2=caption.percents)
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="If NO, why didn't you fish in Nebraska in 2012?", caption2=caption.percents)
wdPageBreak()

###############################
#A4-Waterbody types
###############################
tblData<-CreateSelectAllTable(c("A4priv","A4park","A4pits","A4sand","A4pub","A4plat","A4mo","A4riv"), "A4_Answered")
rownames(tblData)<-c("Private ponds and sandpits", "City park ponds", "Public sandpits", "Sandhill lakes", "Other public lakes, reservoirs, and ponds", "Platte River", "Missouri River", "Other streams, rivers, and canals")
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="What types of water bodies did you fish during 2002? (Select all that apply).", caption2=caption.percents, caption.pos="above")
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="What types of water bodies did you fish during 2002? (Select all that apply).", caption2=caption.percents, caption.pos="above")
wdPageBreak()

###############################
#A5-Methods of fishing
###############################
tblData<-CreateSelectAllTable(c("A5bank", "A5ice", "A5tube", "A5boat", "A5craft", "A5othr", "A5wade"), "A5_Answered")
rownames(tblData)<-c("Bank", "Ice Fishing", "Float Tube", "Motorized Boat", "Non-motorized Boat", "Other", "Wading")
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="Which methods of fishing did you use during 2002? (Select all that apply).", caption.pos="above", caption2=caption.percents)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Which methods of fishing did you use during 2002? (Select all that apply).", caption.pos="above", caption2=caption.percents)
wdPageBreak()

###############################
#A6-Techniques of fishing
###############################
tblData<-CreateSelectAllTable(c("A6rod","A6fly","A6set","A6arch","A6uw", "A6spr", "A6snag","A6othr"), "A6_Answered")
rownames(tblData)<-c("Rod & reel", "Fly-fishing", "Set lines/limb lines", "Archery", "Underwater spear", "Surface spear", "Snagging", "Other")
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="Which methods of fishing did you use during 2002? (Select all that apply).", caption.pos="above", caption2=caption.percents)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Which methods of fishing did you use during 2002? (Select all that apply).", caption.pos="above", caption2=caption.percents)
wdPageBreak()

###############################
#A7-Distance to Favorite waterbody
###############################
#Means - do not used due to skewed data
#tblData<-data.frame(CreateSelectAllTableMeans(c("A7_miles")))
#wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="About how far is the one-way distance from your residence to your favorite Nebraska water body?", caption2=caption.means, caption.pos="above", row.names=FALSE)
#wdWrite(labels.freq)
#wdWrite("Midpoint values were used for calculations with a value of 25 used for the 'Over 25' response. ")
#wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="About how far is the one-way distance from your residence to your favorite Nebraska water body?", caption2=caption.means, caption.pos="above", row.names=FALSE)
#wdWrite("Midpoint values were used for calculations with a value of 25 used for the 'Over 25' response. ")
#wdWrite(labels.freq)
#library(psych)
#skew(mydata[mydata$A7_miles>0 & !is.na(mydata$A7_miles),c("A7_miles")])
#detach("package:psych")
#Medians
tblData<-data.frame(CreateSelectAllTableMedians(c("A7_miles")))
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="About how far is the one-way distance from your residence to your favorite Nebraska water body?", caption2=caption.medians, caption.pos="above", row.names=FALSE)
wdWrite(labels.freq)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="About how far is the one-way distance from your residence to your favorite Nebraska water body?", caption2=caption.medians, caption.pos="above", row.names=FALSE)
wdWrite(labels.freq)

#Percentages
tblData<-CreateSelectOneTable("A7",8)
rownames(tblData)<-c("10 or less miles", "11 to 20 miles", "21 to 40 miles", "41 to 60 miles", "61 to 100 miles", "101 to 250 miles", "251 to 500 miles", "Over 500 miles")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="About how far is the one-way distance from your residence to your favorite Nebraska water body?", caption2=caption.percents)
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="About how far is the one-way distance from your residence to your favorite Nebraska water body?", caption2=caption.percents)
wdPageBreak()

###############################
#A8-Distance to Most-Visited waterbody
###############################
#Means - not used due to skewed data
#tblData<-data.frame(CreateSelectAllTableMeans(c("A8_miles")))
#wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="About how far is the one-way distance from your residence to your most visited Nebraska water body?", caption2=caption.means, caption.pos="above", row.names=FALSE)
#wdWrite(labels.freq)
#wdWrite("Midpoint values were used for calculations with a value of 25 used for the 'Over 25' response. ")
#wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="About how far is the one-way distance from your residence to your most visited Nebraska water body?", caption2=caption.means, caption.pos="above", row.names=FALSE)
#wdWrite("Midpoint values were used for calculations with a value of 25 used for the 'Over 25' response. ")
#wdWrite(labels.freq)

#library(psych)
#skew(mydata[mydata$A8_miles>0 & !is.na(mydata$A8_miles),c("A8_miles")])
#detach("package:psych")
#Medians
tblData<-data.frame(CreateSelectAllTableMedians(c("A8_miles")))
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="About how far is the one-way distance from your residence to your most visited Nebraska water body?", caption2=caption.medians, caption.pos="above", row.names=FALSE)
wdWrite(labels.freq)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="About how far is the one-way distance from your residence to your most visited Nebraska water body?", caption2=caption.medians, caption.pos="above", row.names=FALSE)
wdWrite(labels.freq)

#Percentages
tblData<-CreateSelectOneTable("A8",8)
rownames(tblData)<-c("10 or less miles", "11 to 20 miles", "21 to 40 miles", "41 to 60 miles", "61 to 100 miles", "101 to 250 miles", "251 to 500 miles", "Over 500 miles")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="About how far is the one-way distance from your residence to your most-visited Nebraska water body?", caption2=caption.percents)
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="About how far is the one-way distance from your residence to your most-visited Nebraska water body?", caption2=caption.percents)
wdPageBreak()

###############################
#A9-Satisfaction
###############################
#means
tblData<-data.frame(CreateSelectOneTableMeansSingle("A9"))
colnames(tblData)<-c("Overall", "Resident", "Non-Resident","Male", "Female","16-24","25-34","35-44","45-54","55-64","65+")
wdMyTable(format(tblData[,c(1,2,3,4,5)]), row.names=FALSE, caption="How satisfied were you with your fishing experiences in Nebraska during 2012?", caption2=caption.means, caption.pos="above")
wdWrite(labels.satisfaction)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), row.names=FALSE, caption="How satisfied were you with your fishing experiences in Nebraska during 2012?", caption2=caption.means, caption.pos="above")
wdWrite(labels.satisfaction)

#percentages
tblData<-CreateSelectOneTable("A9",5)
rownames(tblData)<-c("Very Satisfied", "Somewhat Satisfied", "Neutral", "Somewhat Dissatisfied", "Very Dissatisfied")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="How satisfied were you with your fishing experiences in Nebraska during 2012?", caption2=caption.percents)
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="How satisfied were you with your fishing experiences in Nebraska during 2012?", caption2=caption.percents)

###############################
#A10 - Park Permit
###############################
tblData<-CreateSelectOneTable("A10",2)
rownames(tblData)<-c("No", "Yes")
wdMyTable(tblData[c(2,1),c(1,2,3,4,5)],caption2=caption.percents, caption="Did you fish at a water body that required a Nebraska Park Entry Permit during 2012?")
wdMyTable(tblData[c(2,1),c(6,7,8,9,10,11)],caption2=caption.percents,  caption="Did you fish at a water body that required a Nebraska Park Entry Permit during 2012?")
wdPageBreak()

###############################
#B1 - Favorite Fish
###############################
tblData<-CreateSelectOneTable("B1",23)
rownames(tblData)<-c("Striped Bass", "Wiper", "White Bass", "Largemouth Bass", "Smallmouth Bass", "Bluegill/Sunfish", "Crappie", "Yellow Perch", "Walleye/Sauger", "Northern Pike", "Muskellunge/Tiger Musky", "Channel Catfish", "Blue Catfish", "Flathead Catfish", "Bullhead", "Drum", "Sturgeon", "Carp", "Trout", "Paddlefish", "I fished for anything", "Other", "Asian Carp")
wdMyTable(tblData[c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,23, 19, 20, 21,22),c(1,2,3,4,5)], caption2=caption.percents, caption="Which type of fish do you prefer to fish for in Nebraska? (Select only ONE)")
wdMyTable(tblData[c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,23, 19, 20, 21,22),c(6,7,8,9,10,11)],caption2=caption.percents,  caption="Which type of fish do you prefer to fish for in Nebraska? (Select only ONE)")
wdPageBreak()

###############################
#B2-Fish species sought
###############################
tblData<-CreateSelectAllTable(c("B2stb", "B2wpr", "B2whb", "B2lmb", "B2smb", "B2sun", "B2crp", "B2ywp", "B2wae", "B2ntp", "B2musk", "B2ccf", "B2bcf", "B2fcf", "B2bh", "B2fwd", "B2stur", "B2carp", "B2aCarp", "B2rbt", "B2pdf", "B2any", "B2oth"), "B2_Answered")
rownames(tblData)<-c("Striped Bass", "Wiper", "White Bass", "Largemouth Bass", "Smallmouth Bass", "Bluegill/Sunfish", "Crappie", "Yellow Perch", "Walleye/Sauger", "Northern Pike", "Muskellunge/Tiger Musky", "Channel Catfish", "Blue Catfish", "Flathead Catfish", "Bullhead", "Drum", "Sturgeon", "Carp",  "Asian Carp","Trout", "Paddlefish", "I fished for anything", "Other")
wdMyTable(format(tblData[,c(1,2,3,4,5)]),  caption="Which types of fish did you try to catch in Nebraska waters during 2002?  (Only select fish you specifically tried to catch. If you typically fished for whatever was biting, select the option \"I fished for anything\").", caption.pos="above")
wdWrite(caption.percents)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Which types of fish did you try to catch in Nebraska waters during 2002?  (Only select fish you specifically tried to catch. If you typically fished for whatever was biting, select the option \"I fished for anything\").", caption.pos="above")
wdWrite(caption.percents)
wdPageBreak()

###############################
#B3-Catch and Release Tendencies
###############################
#Means
tblData<-CreateSelectAllTableMeans(c("B3stb", "B3wpr", "B3whb", "B3lmb", "B3smb", "B3sun", "B3crp", "B3ywp", "B3wae", "B3ntp", "B3musk", "B3ccf", "B3bcf", "B3fcf", "B3bh", "B3fwd", "B3stur", "B3carp", "B3aCarp", "B3rbt", "B3pdf", "B3any", "B3oth"))
rownames(tblData)<-c("Striped Bass", "Wiper", "White Bass", "Largemouth Bass", "Smallmouth Bass", "Bluegill/Sunfish", "Crappie", "Yellow Perch", "Walleye/Sauger", "Northern Pike", "Muskellunge/Tiger Musky", "Channel Catfish", "Blue Catfish", "Flathead Catfish", "Bullhead", "Drum", "Sturgeon", "Carp",  "Asian Carp","Trout", "Paddlefish", "I fished for anything", "Other")
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="Thinking about the types of fish you tried to catch this year, how many LEGAL-sized fish did you keep?", caption2=caption.means, caption.pos="above")
wdWrite(labels.release)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Thinking about the types of fish you tried to catch this year, how many LEGAL-sized fish did you keep?", caption2=caption.means, caption.pos="above")
wdWrite(labels.release)

#Percentages
tmp<-c("B3stb",  "B3wpr","B3whb", "B3lmb", "B3smb", "B3sun", "B3crp", "B3ywp", "B3wae", "B3ntp", "B3musk", "B3ccf", "B3bcf", "B3fcf", "B3bh", "B3fwd", "B3stur", "B3carp", "B3aCarp", "B3rbt", "B3pdf", "B3any", "B3oth")
tblData<-CreatePercentageTablesForScales(5, tmp)
tmpOP<-cbind("Answer"=c("Kept All", "Kept Many", "Kept Half", "Kept A Few", "Kept None"), tblData)
tblData<-cbind("Species" = rep(c("Striped Bass","Wiper","White Bass", "Largemouth Bass", "Smallmouth Bass", "Bluegill/Sunfish", "Crappie", "Yellow Perch", "Walleye/Sauger", "Northern Pike", "Muskellunge/Tiger Musky", "Channel Catfish", "Blue Catfish", "Flathead Catfish", "Bullhead", "Drum", "Sturgeon", "Carp",  "Asian Carp","Trout", "Paddlefish", "I fished for anything", "Other"),each=5), tmpOP)
wdMyTable(tblData[,c(1,2,3,4,5,6,7)], caption2=caption.percents,row.names=FALSE, caption="Thinking about the types of fish you tried to catch this year, how many LEGAL-sized fish did you keep?", caption.pos="above")
wdMyTable(tblData[,c(1,2,6,7,8,9,10,11,12,13)], caption2=caption.percents,row.names=FALSE, caption="Thinking about the types of fish you tried to catch this year, how many LEGAL-sized fish did you keep?", caption.pos="above")
wdPageBreak()

###############################
#C1 - Frequency
###############################
#Means - do not used as is highely skewed
#tblData<-CreateSelectAllTableMeans(c("C1Jan", "C1Feb", "C1Mar", "C1Apr", "C1May", "C1June", "C1July", "C1Aug", "C1Sept", "C1Oct", "C1Total_days"))
#rownames(tblData)<-c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "Total (Jan-Oct)")
#wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="For each month, indicate about how many DAYS you fished in Nebraska during 2012?", caption2=caption.means, caption.pos="above")
#wdWrite(labels.freq)
#wdWrite("Midpoint values were used for calculations with a value of 25 used for the 'Over 25' response. ")
#wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="For each month, indicate about how many DAYS you fished in Nebraska during 2012?", caption2=caption.means, caption.pos="above")
#wdWrite("Midpoint values were used for calculations with a value of 25 used for the 'Over 25' response. ")
#wdWrite(labels.freq)

#library(psych)
#skew(mydata$C1Total_days[mydata$C1Total_days>0 & !is.na(mydata$C1Total_days)],c("C1Total_days"))
#detach("package:psych")
#Medians
tblData<-CreateSelectAllTableMedians(c("C1Jan", "C1Feb", "C1Mar", "C1Apr", "C1May", "C1June", "C1July", "C1Aug", "C1Sept", "C1Oct", "C1Total_days"))
rownames(tblData)<-c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "Total (Jan-Oct)")
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="For each month, indicate about how many DAYS you fished in Nebraska during 2012?", caption2=caption.medians, caption.pos="above")
wdWrite(labels.freq)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="For each month, indicate about how many DAYS you fished in Nebraska during 2012?", caption2=caption.medians, caption.pos="above")
wdWrite(labels.freq)

#Percentages
tmp<-c("C1Jan", "C1Feb", "C1Mar", "C1Apr", "C1May", "C1June", "C1July", "C1Aug", "C1Sept", "C1Oct")
tblData<-CreatePercentageTablesForScales(12, tmp)
tmpOP<-cbind("Answer"=c("Did Not Fish", "1", "2", "3", "4", "5", "6-8", "9-11", "12-14", "15-17", "18-20", "Over 20"), tblData)
tblData<-cbind("Month" = rep(c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October"),each=12), tmpOP)
wdMyTable(tblData[,c(1,2,3,4,5,6,7)], caption2=caption.medians,row.names=FALSE, caption="For each month, indicate about how many DAYS you fished in Nebraska during 2012?", caption.pos="above")
wdWrite(labels.freq)
wdMyTable(tblData[,c(1,2,6,7,8,9,10,11,12,13)], caption2=caption.medians,row.names=FALSE, caption="For each month, indicate about how many DAYS you fished in Nebraska during 2012?", caption.pos="above")
wdWrite(labels.freq)
wdPageBreak()

###############################
#C2-Motivations
###############################
#library(psych)
#skew(mydata[mydata$C2a>0 & !is.na(mydata$C2a),c("C2a")])
#skew(mydata[mydata$C2b>0 & !is.na(mydata$C2b),c("C2b")])
#skew(mydata[mydata$C2c>0 & !is.na(mydata$C2c),c("C2c")])
#skew(mydata[mydata$C2d>0 & !is.na(mydata$C2d),c("C2d")])
#skew(mydata[mydata$C2e>0 & !is.na(mydata$C2e),c("C2e")])
#skew(mydata[mydata$C2f>0 & !is.na(mydata$C2f),c("C2f")])
#detach("package:psych")
tblData<-CreateSelectAllTableMeans(c("C2a", "C2b", "C2c", "C2d", "C2e", "C2f", "C2g", "C2h", "C2i", "C2j", "C2k", "C2l", "C2m", "C2n", "C2o", "C2p", "C2q"))
rownames(tblData)<-c("To be outdoors", 
                     "For the experience of the catch",
                     "To experience natural surroundings",
                     "To be with friends",
                     "For the challenge or sport",
                     "For relaxation",
                     "To experience new and different things",
                     "To get away from other people",
                     "To compete for prizes or money",
                     "To experience adventure and excitement",
                     "To obtain fish for eating",
                     "To be close to the water",
                     "For physical exercise",
                     "To catch a trophy fish",
                     "To get away from the daily routine",
                     "For family recreation",
                     "For the fun of catching fish")
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="Indicate the importance for each item as a reason why you fish...", caption2=caption.means, caption.pos="above")
wdWrite(labels.importance)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Indicate the importance for each item as a reason why you fish...", caption2=caption.means, caption.pos="above")
wdWrite(labels.importance)
wdPageBreak()

#collapsed motivation scales - four subscales
tblData<-CreateSelectAllTableMeans(c("motivation_pp", "motivation_natural", "motivation_social", "motivation_resource"))
rownames(tblData)<-c("Physical and psycological", "Natural environment", "Social", "Fishery resource")
wdMyTable(format(tblData[,c(1,2,3,4,5)]),caption="Collapsed scales (4) of angler motivations.",  caption2=caption.means, caption.pos="above")
wdWrite(labels.importance)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Collapsed scales (4) of angler motivations.", caption2=caption.means,caption.pos="above")
wdWrite(labels.importance)
wdPageBreak()

#collapsed motivation scales - four subscales
tblData<-CreateSelectAllTableMeans(c("motivation_noncatch", "motivation_catch"))
rownames(tblData)<-c("Non-catch", "Catch")
wdMyTable(format(tblData[,c(1,2,3,4,5)]),caption="Collapsed scales (2) of angler motivations.",  caption2=caption.means, caption.pos="above")
wdWrite(labels.importance)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Collapsed scales (2) of angler motivations.", caption2=caption.means,caption.pos="above")
wdWrite(labels.importance)
wdPageBreak()

###############################
#D1-Programs
###############################
tblData<-CreateSelectAllTableMeans(c("D1a", "D1b", "D1c", "D1d", "D1e", "D1f", "D1g", "D1h", "D1i", "D1j", "D1k", "D1l", "D1m", "D1n", "D1o", "D1p", "D1q", "D1r", "D1s", "D1t", "D1u"))
rownames(tblData)<-c("Preventing the spread of fish diseases (i.e. Whirling disease)",
"Improving aquatic habitat in lakes and reservoirs so they produce better fish populations",
"Improving aquatic habitat in rivers and streams so they produce better fish populations",
"Preventing the spread of invasive species (e.g., zebra mussels, white perch)",
"Marketing fishing and outdoor activities",
"Getting people involved in fishing by providing fishing clinics and Family Fishing Nights",
"Getting people involved in fishing and outdoor activities by providing Outdoor Discovery Days (Expos)",
"Improving boating access to public lakes, reservoirs, and rivers (e.g., ramps, docks, breakwaters)",
"Managing the harvest of fish with fishing regulations",
"Maintaining adequate water flows in rivers and streams for fish, wildlife, and recreation",
"Placing trees in lakes and reservoirs to attract fish for anglers to catch",
"Stocking sport fish for anglers to catch",
"Providing information on fishing via radio, television, newspaper, and other printed materials",
"Providing information on fishing via electronic media (e.g., website, blogs, forums, mobile apps, Twitter, Facebook)",
"Providing information on fishing via workshops and seminars",
"Improving access for anglers who fish from shore (e.g., fishing piers)",
"Stocking threatened and endangered non-sport fish to restore populations",
"Educating people about Nebraska's aquatic resources",
"Conducting research to evaluate fisheries management practices",
"Leasing or purchasing rights to access private lakes, ponds, rivers, and streams for public fishing",
"Getting young people involved in fishing by forming school fishing clubs")
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="Indicate the importance for each item as a reason why you fish...", caption2=caption.means, caption.pos="above")
wdWrite(labels.importance)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Indicate the importance for each item as a reason why you fish...", caption2=caption.means, caption.pos="above")
wdWrite(labels.importance)
wdPageBreak()

#collapsed program scales
tblData<-CreateSelectAllTableMeans(c("programs_game", "programs_habitat", "programs_environment", "programs_outreach"))
rownames(tblData)<-c("Game fish management", "Habitat and access", "Environmental services", "Education and outreach")
wdMyTable(format(tblData[,c(1,2,3,4,5)]),caption="Collapsed scales of angler support for programs.",  caption2=caption.means, caption.pos="above")
wdWrite(labels.importance2)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Collapsed scales of angler support for programs.", caption2=caption.means,caption.pos="above")
wdWrite(labels.importance2)
wdPageBreak()

###############################
#E1-Attitudes
###############################
tblData<-CreateSelectAllTableMeans(c("E1a", "E1b", "E1c", "E1d", "E1e", "E1f", "E1g", "E1h", "E1i", "E1j", "E1k", "E1l", "E1m", "E1n", "E1o", "E1p"))
rownames(tblData)<-c(
  "A fishing trip can be successful even if no fish are caught", 
  "The bigger the fish I catch, the better the fishing trip", 
  "I'm happiest with a fishing trip if I catch at least the limit", 
  "I want to keep all the fish I catch", 
  "The more fish I catch, the happier I am", 
  "I'm just as happy if I release all the fish I catch", 
  "If I thought I wouldn't catch any fish, I would not go fishing", 
  "I am the happiest with a fishing trip if I catch a challenging game fish", 
  "I usually eat the fish I catch", 
  "I would rather catch one or two big fish than ten smaller fish", 
  "When I go fishing, I'm just as happy if I don't catch a fish", 
  "I'm just as happy if I don't keep the fish I catch", 
  "I like to fish where I know I have a chance to catch a trophy fish", 
  "A successful fishing trip is one in which many fish are caught", 
  "A full stringer is the best indicator of a good fishing trip.", 
  "When I go fishing, I am not satisfied unless I catch at least something")
wdMyTable(format(tblData[,c(1,2,3,4,5)]), caption="Which methods of fishing did you use during 2002? (Select all that apply).", caption2=caption.means, caption.pos="above")
wdWrite(labels.agree)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Which methods of fishing did you use during 2002? (Select all that apply).", caption2=caption.means,caption.pos="above")
wdWrite(labels.agree)
wdPageBreak()

#collapsed attitude scales
tblData<-CreateSelectAllTableMeans(c("attitude_catch", "attitude_numbers", "attitude_size", "attitude_harvest"))
rownames(tblData)<-c("Catch something", "Numbers", "Size", "Harvest")
wdMyTable(format(tblData[,c(1,2,3,4,5)]),caption="Collapsed scales of angler attitudes.",  caption2=caption.means, caption.pos="above")
wdWrite(labels.agree)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Collapsed scales of angler attitudes.", caption2=caption.means,caption.pos="above")
wdWrite(labels.agree)
wdPageBreak()

###############################
#E2 - Gender
###############################
tblData<-CreateSelectOneTable("E2", 2)
rownames(tblData)<-c("Male", "Female")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="What is your gender?", caption2=caption.percents, caption.pos="above")
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="What is your gender?", caption2=caption.percents, caption.pos="above")
wdPageBreak()

###############################
#E3 - Age
###############################
tblData<-CreateSelectOneTable("E3", 6)
rownames(tblData)<-c("16-24", "25-34", "35-44", "45-54", "55-64", "65+")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="What is your age?", caption2=caption.percents, caption.pos="above")
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="What is your age?", caption2=caption.percents, caption.pos="above")
wdPageBreak()

###############################
#E4 - Ethnicity
###############################
tblData<-CreateSelectOneTable("E4", 9)
rownames(tblData)<-c("Caucasian", "Hispanic", "African American", "Asian", "Middle Eastern", "American Indian", "Pacific Islander", "Other", "Multi-ethnic")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="What is your ethnicity?", caption2=caption.percents, caption.pos="above")
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="What is your ethnicity?", caption2=caption.percents, caption.pos="above")
wdPageBreak()

###############################
#E5 - Education
###############################
tblData<-CreateSelectOneTable("E5", 8)
rownames(tblData)<-c("Some schooling", "High school or GED", "Associate/trade degree", "Some college", "Bachelors degree", "Masters degree", "Doctorate, law, or medical degree", "Other")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="What is the highest level of education you have achieved?", caption2=caption.percents, caption.pos="above")
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="What is the highest level of education you have achieved?", caption2=caption.percents, caption.pos="above")
wdPageBreak()

###############################
#E7 - Income
###############################
tblData<-CreateSelectOneTable("E6", 8)
rownames(tblData)<-c("Less than $10,000", "$10,000 to $19,999", "$20,000 to $39,999", "$40,000 to $49,999", "$50,000 to $59,999", "$60,000 to $79,999", "$80,000 to $100,000", "Over $100,000")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="What is your household income?", caption2=caption.percents, caption.pos="above")
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="What is your household income?", caption2=caption.percents, caption.pos="above")

###############################
#E7 - Conservation Officer
###############################
tblData<-CreateSelectOneTable("E7", 2)
rownames(tblData)<-c("No", "Yes")
wdMyTable(tblData[,c(1,2,3,4,5)], caption="Were you checked by a Nebraska conservation officer wearing a sidearm while fishing during 2012?", caption2=caption.percents, caption.pos="above")
wdMyTable(tblData[,c(6,7,8,9,10,11)], caption="Were you checked by a Nebraska conservation officer wearing a sidearm while fishing during 2012?", caption2=caption.percents, caption.pos="above")
wdPageBreak()

###############################
#F1 - Information Sources
###############################
tblData<-CreateSelectAllTable(c("F1b","F1c", "F1d", "F1e", "F1s", "F1t", "F1f", "F1g", "F1h", "F1u", "F1v", "F1k", "F1l", "F1m", "F1n", "F1o", "F1p", "F1q", "F1r"), "F1_Answered")
rownames(tblData)<-c("Newspapers", "NEBRASKALAND magazine", "Other fishing/outdoor magazines", "Nebraska Game and Parks Internet site","Barbs and Backlashes Blog", "Game and Parks social media", "Other Internet fishing sites", "Bait and tackle shops", "Fishing organizations",  "Game and Parks events", "Other events", "Outdoor Nebraska radio program", "Other news program (radio or TV)", "Nebraska State Fair","Fishing regulations guide", "State parks/facilities", "Friends and family", "Other", "I do not get information on fishing in Nebraska")
wdMyTable(format(tblData[,c(1,2,3,4,5)]),  caption="Which types of fish did you try to catch in Nebraska waters during 2002?  (Only select fish you specifically tried to catch. If you typically fished for whatever was biting, select the option \"I fished for anything\".)", caption.pos="above")
wdWrite(caption.percents)
wdMyTable(format(tblData[,c(6,7,8,9,10,11)]), caption="Which types of fish did you try to catch in Nebraska waters during 2002?  (Only select fish you specifically tried to catch. If you typically fished for whatever was biting, select the option \"I fished for anything\".)", caption.pos="above")
wdWrite(caption.percents)
wdPageBreak()





##############################################
#Extra Stuff
##############################################

myDataFrame<-mydata[mydata$A4_Answered==TRUE,]  
#myDataFrame<-CreateSelectAllTableSingle(tmpMyData[tmpMyData$B1==19,c("A4priv","A4park","A4pits","A4sand","A4pub","A4plat","A4mo","A4riv")])
myDataFrame<-tmpMyData[tmpMyData$B2rbt==1,c("A4priv","A4park","A4pits","A4sand","A4pub","A4plat","A4mo","A4riv")]
OPperc<-round(table(myDataFrame[,c(1)])["1"]/length(myDataFrame[,c(1)])*100, 1)
for (i in 2:length(myDataFrame)){
  OPperc<-cbind(OPperc, round(table(myDataFrame[,c(i)])["1"]/length(myDataFrame[,c(i)])*100, 1))
}

OPanswerN<-table(myDataFrame[,c(1)])["1"]
for (i in 2:length(myDataFrame)){
  OPanswerN<-cbind(OPanswerN, table(myDataFrame[,c(i)])["1"])
}

OPquestionN<-length(myDataFrame[,c(1)])
for (i in 2:length(myDataFrame)){
  OPquestionN<-cbind(OPquestionN, length(myDataFrame[,c(i)]))
}

OPperc<-t(OPperc)
OPanswerN<-t(OPanswerN)
OPquestionN<-t(OPquestionN)

OPci<-round((1.96 * (sqrt((OPperc/100)*(1-(OPperc/100))/OPquestionN)))*100,1)
rownames(OPperc)<-c("Private ponds and sandpits", "City park ponds", "Public sandpits", "Sandhill lakes", "Other public lakes, reservoirs, and ponds", "Platte River", "Missouri River", "Other streams, rivers, and canals")
par(mai=c(4.3,1,1,1))
barplot(OPperc, ylim=c(0,80), names.arg=rownames(OPperc), beside=TRUE, las=2, main="Trout Seeking Anglers")
errbar(c(1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5),OPperc, OPperc+OPci, OPperc-OPci, xaxt="n",add=TRUE)
text(x=c(1,2,3.5,4.5,5,6,7,8),y=OPperc, labels=OPperc, pos=4, col="black")

unique(mydata$A4riv)
table(mydata[mydata$B1==19,])
a<-mydata[mydata$B1==19,]
a<-a[a$B3rbt>0,]
a<-a[a$B3rbt<6,]
a<-a[a$A4riv==1,]
ad<-mean(a$B3rbt)
ad<-cbind(data.frame(ad), mean(a$B3rbt))
a2<-ddply(a,"A4riv",fun=mean(B3rbt))
table(a$B3rbt, a$A4riv)
ad<-t(ad)
rownames(ad)<-c("No rivers and streams", "Fished rivers and streams")
colnames(ad)<-c("Mean Catch/Release - 1/High to 5/Low")
wdTable(ad)


