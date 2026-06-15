options(stringsAsFactors = FALSE)
library(dplyr)
library(tidyr)
library(foreach)


# Create Captions and Labels ----------------------------------------------
caption.percents <-
  "Values represent percentage of respondents +- 95% confidence intervals with sample size given in parenthesis."
caption.means <-
  "Values represent mean response +- 95% confidence intervals with sample size given in parenthesis."
caption.medians <-
  "Values represent lower 95% median confidence limit, median response, and upper 95% median confidence limit with sample size given in parenthesis"
caption.ranks <-
  "Values represent rank order of responses."
labels.distance <-
  "Answers included: 10 or less miles, 11 to 20 miles, 21 to 40 miles, 41 to 60 miles, 61 to 100 miles, 101 to 250 miles, 251 to 500 miles, and Over 500 miles."
labels.agree <-
  "Answers included (from 1 to 5): Strongly Disagree, Disagree, Neutral, Agree, Strongly Agree."
labels.importance <-
  "Answers included (from 1 to 5): Not At All Important, Slightly Important, Moderately Important, Very Important, Extremely Important."
labels.importance2 <-
  "Answers included (from 1 to 5): Not At All Important, Not Very Important, Somewhat Important, Very Important, Extremely Important."
labels.release <-
  "Answers included (from 1 to 5): Kept All, Kept Many, Kept Half, Kept A Few, Kept None."
labels.freq <-
  "Answers included: Did Not Fish, 1, 2, 3, 4, 5, 6-8, 9-11, 12-14, 15-17, 18-20, and Over 20."
labels.satisfaction <-
  "Answers included (from 1 to 5): Very Satisfied, Somewhat Satisfied, Neutral, Somewhat Dissatisfied, and Very Dissatisfied."
labels.barriers<-
  "Answers included (from 1 to 4): I would fish the same amount, I may go fishing more, I would likely go fishing more, I would definitely go fishing more."
# Create Generic Functions ------------------------------------------------
SubstitueQuesForResponse<-function(myData, myQuestionList, myQuestion, myYear, responseField="Response"){
  myQuestion<-enquo(myQuestion)

  l<-myQuestionList %>% 
    filter(str_detect(.$Field, rlang::quo_text(myQuestion)) & Year==myYear) %>%
    select(Field, Question) %>%
    unique()

  op<-myData %>%
    mutate(Response2=as.character(get(responseField))) %>%
    left_join(l, by=c("Response2"="Field")) %>%
    mutate(!!rlang::sym(responseField):=Question) %>%
    select(-Question, -Response2)

  return(op)
}

LabelResponses<-function(myData, myLabels, responseField="Response"){
  op<-  myData %>%
    mutate(Response2=as.character(get(responseField))) %>%
    left_join(myLabels, by=c("Response2"="Response")) %>%
    #arrange(Response) %>%
    mutate(!!rlang::sym(responseField):=Label) %>%
    select(-Label, -Response2)
  
  return(op) 
  }


ArrangeTable<-function(x, roundDigits=1){
  
  op<- x %>% 
    select(Year, Response, Value, CI, Number) %>% 
    mutate(Value=round(Value,roundDigits), CI=round(CI,roundDigits+1)) %>%
    gather(variable, value, 3:5) %>%
    unite(temp, Year, variable) %>% 
    group_by(Response, temp) %>%
    mutate(row_id=1:n()) %>%
    ungroup() %>%
    spread(temp, value) %>%
    select(-row_id)
  
  return(op)
}

ArrangeTableGrouped<-function(x, groupedVar, roundDigits=1){
  groupedVar=enquo(groupedVar)
  
  op<- x %>% 
    select(Species, Year, Response, Value, CI, Number) %>% 
    mutate(Value=round(Value,roundDigits), CI=round(CI,roundDigits+1)) %>%
    gather(variable, value, 3:5) %>%
    unite(temp, Year, variable) %>%
    group_by(Response, temp) %>%
    mutate(row_id=1:n()) %>%
    ungroup() %>%
    spread(temp, value) %>%
    select(-row_id)
  
  return(op)
}

ArrangeTableMedians<-function(x, roundDigits=1){
  
  op<- x %>% 
    select(Year, Response, Value, CIupper, CIlower, Number) %>% 
    mutate(CI=paste(CIlower, "/", CIupper, sep="")) %>%
    select(-CIupper, -CIlower) %>%
    gather(variable, value, 3:5) %>%
    unite(temp, Year, variable) %>% 
    group_by(temp, Response) %>%
    mutate(row_id=1:n()) %>%
    ungroup() %>%
    spread(temp, value) %>%
    select(-row_id)
  
  return(op)
}

ArrangeTableRanks<-function(x, roundDigits=1){
  
  op<- x %>%
    mutate(text=paste(Rank, " (", round(Value,1), "%)", sep="")) %>% 
    select(Year, Response, text) %>% 
    group_by(Year, Response) %>%
    mutate(row_id=1:n()) %>%
    ungroup() %>%
    spread(Year, text) %>%
    select(-row_id) %>%
    separate(`2002`, c("order"), sep=" ", remove=FALSE) %>%
    arrange(as.numeric(order)) %>%
    select(-order)
  
  return(op)
}


CreateFt<-function(x, headerColumn=NA, mergeOnFirst=FALSE, formatStyle="perc", roundDigits=1){
  headerColumn<-enquo(headerColumn)
  require(officer)
  require(flextable)
  
  if (rlang::quo_text(headerColumn)=="NA") {
    myCol.keys= c('Response',
                  '2002_Value',
                  '2002_CI',
                  '2002_Number',
                  "sep2",
                  '2012_Value',
                  '2012_CI',
                  '2012_Number',
                  "sep3",
                  '2018_Value',
                  '2018_CI',
                  '2018_Number')
    
    typology <- data.frame(
      col_keys = c("Response", 
                   "2002_CI", "2002_Number",
                   "2002_Value", "2012_CI","2012_Number","2012_Value","2018_CI","2018_Number","2018_Value"),
      year = c("Response", "2002", "2002", "2002", "2012", "2012", "2012", "2018", "2018", "2018"),
      measure = c("Response", "CI", "N", "Value", "CI", "N", "Value", "CI", "N", "Value"),
      stringsAsFactors = FALSE ) 
    
  } else {
    myCol.keys= c(rlang::quo_text(headerColumn),
                  'Response',
                  '2002_Value',
                  '2002_CI',
                  '2002_Number',
                  "sep2",
                  '2012_Value',
                  '2012_CI',
                  '2012_Number',
                  "sep3",
                  '2018_Value',
                  '2018_CI',
                  '2018_Number')
    
    typology <- data.frame(
      col_keys = c(rlang::quo_text(headerColumn), "Response",
                   "2002_CI", "2002_Number",
                   "2002_Value", "2012_CI","2012_Number","2012_Value","2018_CI","2018_Number","2018_Value"),
      year = c(rlang::quo_text(headerColumn),"Response", "2002", "2002", "2002", "2012", "2012", "2012", "2018", "2018", "2018"),
      measure = c(rlang::quo_text(headerColumn),"Response", "CI", "N", "Value", "CI", "N", "Value", "CI", "N", "Value"),
      stringsAsFactors = FALSE )
    
  }
  
  
  
  
  bigborder=officer:: fp_border(color="black", width = 1.5)
  smallborder=officer:: fp_border(color="black", width=1.0)
  
  myFlex <- flextable(x, col_keys = myCol.keys) %>%
    set_header_df(mapping = typology, key = "col_keys" ) %>%
    merge_h(part = "header") %>%
    merge_v(part = "header") 
  
  if(mergeOnFirst==TRUE) {
    #merge first column cells
    myFlex <-myFlex %>%
      merge_v(j=1, part="body")
    #add border below merged cells in first column
    myFlex<-myFlex %>%
      border(border.bottom = smallborder, i=rle(cumsum(myFlex$body$spans$columns[,1] ))$values, part="body") %>%
      align(align="left", j=2, part="all")
  }
  
  myFlex <- myFlex %>%
    theme_zebra() %>%
    #border_outer(officer:: fp_border(color="black", width = 1.5), part="all") %>%
    #add border above and below footer
    bg(bg = "#CFCFCF", part = "header") %>%
    border(border.bottom = bigborder, border.top = bigborder, part = "header") %>%
    #add border at bottom of body
    border(border.bottom = bigborder, i=nrow(myFlex$body$spans$rows), part = "body") %>%
    padding(j=1, padding.left=3) %>%
    align(align="right", part="all") %>%
    align(align="left", j=1, part="all") %>%
    fontsize(part = "header", size = 10) %>%
    fontsize(part="body", size=8) %>%
    bold(part="header") %>%
    autofit() #%>%
  #width(j = 1, width = 1.2)
  
  
  if (formatStyle=="perc"){
    myFlex<-myFlex %>% 
      colformat_num(col_keys = c("2002_Value", "2012_Value", "2018_Value"), big.mark = ",", digits = roundDigits, na_str = "") %>%
      colformat_num(col_keys = c("2002_CI", "2012_CI", "2018_CI"), big.mark = ",", digits = roundDigits+1, na_str = "") %>%
      colformat_num(col_keys = c("2002_Number", "2012_Number", "2018_Number"), big.mark = ",", digits = 0, na_str = "")
  }
  
  return(myFlex)
}

CreateFtRanks<-function(x){
  require(officer)
  require(flextable)
  
  bigborder=officer:: fp_border(color="black", width = 1.5)
  smallborder=officer:: fp_border(color="black", width=1.0)
  
  myFlex <- flextable(x) %>%
    theme_zebra()
  
  myFlex<-myFlex %>%
    #border_outer(officer:: fp_border(color="black", width = 1.5), part="all") %>%
    #add border above and below footer
    bg(bg = "#CFCFCF", part = "header") %>%
    border(border.bottom = bigborder, border.top = bigborder, part = "header") %>%
    #add border at bottom of body
    border(border.bottom = bigborder, i=nrow(myFlex$body$spans$rows), part = "body") %>%
    padding(j=1, padding.left=3) %>%
    align(align="right", part="all") %>%
    align(align="left", j=1, part="all") %>%
    fontsize(part = "header", size = 10) %>%
    fontsize(part="body", size=8) %>%
    bold(part="header") %>%
    autofit() #%>%
  #width(j = 1, width = 1.2)
  
  return(myFlex)
}


CreatePercPlot<-function(mydata, freeScale=TRUE, numCols=3, label_x="Percent Of Respondants") {
  #munge data
  op<-mydata %>%
    mutate(Year=factor(Year)) 
  
  #create plot 
  op<-ggplot(op) +
    geom_bar(aes(x=Year, y=Value, fill=Year), stat="identity") +
    geom_errorbar(aes(x=Year, ymin=Value-CI, ymax=Value+CI), width=0.5) +
    scale_fill_viridis_d(begin=0.3, end=0.8) +
    labs(y=label_x, x="")
  
  #facet
  if(freeScale) {
    op<-op +
      facet_wrap(~Response, ncol=numCols, scales="free_y")
  } else {
    op<-op +
      facet_wrap(~Response, ncol=numCols)
  }
  
  #theme
  op <- op +
    theme_minimal() +
    theme(panel.grid.major.x=element_blank(),
          legend.position = "none",
          strip.text=element_text(hjust=1, face="bold", color=viridis::viridis(3, option = "D")[1]))
  
  return(op)
}

CreateMeanPlot<-function(mydata, label_x="Mean Of Responses", freeScale=TRUE, numCols=3) {
  #munge data
  op<-mydata %>%
    mutate(Year=factor(Year)) 
  
  #create plot 
  op<-ggplot(op) +
    geom_point(aes(x=Year, y=Value, color=Year), size=3, stat="identity") +
    geom_errorbar(aes(x=Year, ymin=Value-CI, ymax=Value+CI), width=0.5) +
    scale_color_viridis_d(begin=0.3, end=0.8) +
    labs(y=label_x, x="")
  
  #facet
  if(freeScale) {
    op<-op +
      facet_wrap(~Response, ncol=numCols, scales="free_y")
  } else {
    op<-op +
      facet_wrap(~Response, ncol=numCols)
  }
  
  #theme
  op <- op +
    theme_minimal() +
    theme(panel.grid.major.x=element_blank(),
          legend.position = "none",
          strip.text=element_text(hjust=1, face="bold", color=viridis::viridis(3, option = "D")[1]))
  
  return(op)
}

CreateMedianPlot<-function(mydata, label_x="Median Of Responses", freeScale=TRUE, numCols=3) {
  #munge data
  op<-mydata %>%
    mutate(Year=factor(Year)) 
  
  #create plot 
  op<-ggplot(op) +
    geom_point(aes(x=Year, y=Value, color=Year), size=3, stat="identity") +
    geom_errorbar(aes(x=Year, ymin=Value-CI, ymax=Value+CI), width=0.5) +
    scale_color_viridis_d(begin=0.3, end=0.8) +
    labs(y=label_x, x="")
  
  #facet
  if(freeScale) {
    op<-op +
      facet_wrap(~Response, ncol=numCols, scales="free_y")
  } else {
    op<-op +
      facet_wrap(~Response, ncol=numCols)
  }
  
  #theme
  op <- op +
    theme_minimal() +
    theme(panel.grid.major.x=element_blank(),
          legend.position = "none",
          strip.text=element_text(hjust=1, face="bold", color=viridis::viridis(3, option = "D")[1]))
  
  return(op)
}


CreateLikert_Grouped<-function(myData, myQuestions, myQuestionList, myTitle=""){
  
  myLabels<-myQuestionList %>% filter(Field %in% myQuestions) %>% filter(Year==2018) %>% select(Question, Field) %>% unique() 
  
  op<-myData %>% 
    select(myQuestions, surveyYear) %>%
    filter(complete.cases(.)) %>%
    mutate(surveyYear=factor(surveyYear)) %>%
    as.data.frame()
  
  names(op) <- c(myLabels$Question, "surveyYear")
  
  myPlot<-plot(likert(op %>% select(-surveyYear), grouping=op$surveyYear), ordered=FALSE) + 
    scale_fill_viridis_d(begin=0.3) + 
    ggtitle(myTitle) +
    theme(legend.title=element_blank(),
          strip.background = element_rect(color="black"),
          panel.background = element_rect(color="black"),
          plot.title = element_text(hjust=0.5))
  return(myPlot)
}

CreateSubScaleLikertGraphs<-function(mydata, myScaleName, myQuestionList){
  
  mySubscales<-s %>% filter(ScaleName==myScaleName) %>% pull(SubScaleName) %>% unique()
  
  op<-foreach(i=mySubscales) %do% {
    myFields<-s %>% filter(ScaleName==myScaleName) %>% filter(SubScaleName==i) %>% pull(Field)
    CreateLikert_Grouped(d, myFields, q , i)
  }
  return(op)
}

