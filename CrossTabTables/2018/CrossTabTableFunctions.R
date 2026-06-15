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
caption.raked<-"These results were weighted.  Please consult the survey methodology for details."

# Create Generic Functions ------------------------------------------------
RoundTable <- function(myDataFrame, includesHeaderColumn = FALSE) {
  numCols = ncol(myDataFrame)
  startCol = 1
  if (includesHeaderColumn == TRUE) {
    startCol = 2
  }
  for (i in startCol:ncol(myDataFrame)) {
    myDataFrame[, i] <- round(myDataFrame[, i] * 100, 1)
  }
  return (myDataFrame)
}

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

# Arrange Tables - takes calculations and lays out table in a dataframe ------
ArrangeTableA <- function(myData, roundDigits = 1, ordered=FALSE) {
  if ("CI" %in% names(myData)) {
    #create table 
    myData <- myData %>%
      mutate(Value = round(Value, roundDigits),
             CI = round(CI, roundDigits+1)) %>%
      mutate(text = paste(Value, "+-", CI, " (", Number, ")", sep = "")) %>%
      select(Response, Group, text) %>% 
      group_by(Response, Group) %>%
      mutate(row_id=1:n()) %>%
      ungroup() %>%
      spread(Group, text) %>%
      select(-row_id)
  }
  else if ("CIupper" %in% names(myData)) {
    #create table
    myData <- myData %>%
      mutate(Value = round(Value, roundDigits),
             CIupper = round(CIupper, roundDigits),
             CIlower=round(CIlower, roundDigits+1)) %>%
      mutate(text = paste(CIlower, "/", Value, "/", CIupper, " (", Number, ")", sep = "")) %>%
      select(Response, Group, text) %>% 
      group_by(Response, Group) %>%
      mutate(row_id=1:n()) %>%
      ungroup() %>%
      spread(Group, text) %>%
      select(-row_id)
  }
  
  if (ordered==TRUE){
    myData <- myData %>% 
      separate(Overall, c("val", "deleteMe"),sep="\\+-", remove=FALSE) %>% 
      mutate(val=as.numeric(val)) %>% 
      arrange(-val) %>% 
      select(-val, -deleteMe)
  }
  
  myData<-myData %>%
    select(Response, Overall, Resident, 'Non-Resident', Male, Female)
  
  #remove NA
  myData[, 2:5] <-
    lapply(myData[, 2:5], function(x)
      ifelse(is.na(x), "", x))
  
  return(myData)
}

ArrangeTableB <- function(myData, roundDigits = 1, ordered=FALSE) {
  if ("CI" %in% names(myData)) {
  #Create Table
  myData <- myData %>%
    mutate(Value = round(Value, roundDigits),
           CI = round(CI, roundDigits+1)) %>%
    mutate(text = paste(Value, "+-", CI, " (", Number, ")", sep = "")) %>%
    select(Response, Group, text) %>% 
    group_by(Response, Group) %>%
    mutate(row_id=1:n()) %>%
    ungroup() %>%
    spread(Group, text) %>%
    select(-row_id) 
  }
  else if ("CIupper" %in% names(myData)) {
    #Create Table
    myData <- myData %>%
      mutate(Value = round(Value, roundDigits),
             CIupper = round(CIupper, roundDigits+1),
             CIlower = round(CIlower, roundDigits+1)) %>%
      mutate(text = paste(CIlower, "/", Value, "/", CIupper, " (", Number, ")", sep = "")) %>%
      select(Response, Group, text) %>% 
      group_by(Response, Group) %>%
      mutate(row_id=1:n()) %>%
      ungroup() %>%
      spread(Group, text) %>%
      select(-row_id)
  }
  
  
  if (ordered==TRUE){
    myData <- myData %>% 
      separate(Overall, c("val", "deleteMe"),sep="\\+-", remove=FALSE) %>% 
      mutate(val=as.numeric(val)) %>% 
      arrange(-val) %>% 
      select(-val, -deleteMe, -Overall)
  }
  
  #select proper columns
  myData<-myData %>%
    select(Response,
           `16-24`,
           `25-34`,
           `35-44`,
           `45-54`,
           `55-64`,
           `65 and older`)
  
  # #remove NA
  myData[, 2:6] <-
    lapply(myData[2:6], function(x)
      ifelse(is.na(x), "", x))
  return(myData)
}

# Create tables for select one questions --------------------------------------

CreateTableA_selectOne_percent <- function(myData, myQuestion, ordered=FALSE) {
  myQuestion <- enquo(myQuestion)

  #get results
  op <-
    base.summary.percent.selectOne(myData,!!myQuestion, myGroupVar = NA)
  op <-
    rbind(op,
          base.summary.percent.selectOne(myData,!!myQuestion, myGroupVar = Resi))
  op <-
    rbind(op,
          base.summary.percent.selectOne(myData,!!myQuestion, myGroupVar = E2))

    #create table
  op <- ArrangeTableA(op, ordered=ordered)

  return(op)
}

CreateTableB_selectOne_percent <- function(myData, myQuestion, ordered=FALSE) {
  myQuestion <- enquo(myQuestion)
  
  #get results
  op <-base.summary.percent.selectOne(myData,!!myQuestion, myGroupVar = E3)

  if(ordered==TRUE){
    op <-rbind(op,
      base.summary.percent.selectOne(myData,!!myQuestion, myGroupVar = NA))
    }
    
  #create table
  op <- ArrangeTableB(op, ordered=ordered)
  
  
  return(op)
}


# Create tables for select all questions --------------------------------------
CreateTableA_selectAll_percent <-
  function(myData, myQuestions, myAnsweredVar, ordered=FALSE) {
    #myQuestions<-enquo(myQuestions)
    myAnsweredVar <- enquo(myAnsweredVar)
    
    #get results
    op <-
      base.summary.percent.selectAll(
        myData,
        myQuestions,
        myAnsweredVar = !!myAnsweredVar,
        myGroupVar = NA
      )
    op <-
      rbind(
        op,
        base.summary.percent.selectAll(
          myData,
          myQuestions,
          myAnsweredVar = !!myAnsweredVar,
          myGroupVar = Resi
        )
      )
    op <-
      rbind(
        op,
        base.summary.percent.selectAll(
          myData,
          myQuestions,
          myAnsweredVar = !!myAnsweredVar,
          myGroupVar = E2
        )
      )
    
    #create table
    op <- ArrangeTableA(op, ordered=ordered)
    
    return(op)
  }

CreateTableB_selectAll_percent <-
  function(myData, myQuestions, myAnsweredVar, ordered=FALSE) {
    myAnsweredVar <- enquo(myAnsweredVar)
    
    #get results
    op <-
      base.summary.percent.selectAll(
        myData,
        myQuestions,
        myAnsweredVar = !!myAnsweredVar,
        myGroupVar = E3
      )
    op <-rbind(op,
      base.summary.percent.selectAll(
        myData,
        myQuestions,
        myAnsweredVar = !!myAnsweredVar,
        myGroupVar = NA
      ))
    
    #create table
    op <- ArrangeTableB(op, ordered=ordered)

    return(op)
  }

# Create Table For Mean Of Responses --------------------------------------
CreateTableA_means <- function(myData, myQuestions) {

  op <- foreach(i = 1:length(myQuestions), .combine = "rbind") %do%  {
    base.summary.means(myData,!!rlang::sym(myQuestions[i]), myGroupVar = NA)
  }
  
  op1 <-
    foreach(i = 1:length(myQuestions), .combine = "rbind") %do%  {
      base.summary.means(myData,!!rlang::sym(myQuestions[i]), myGroupVar = Resi)
    }
  
  op2 <-
    foreach(i = 1:length(myQuestions), .combine = "rbind") %do%  {
      base.summary.means(myData,!!rlang::sym(myQuestions[i]), myGroupVar = E2)
    }
  
  op <- rbind(op, op1, op2)
  
  #create table
  op <- ArrangeTableA(op)
  
  return(op)
}

CreateTableB_means <- function(myData, myQuestions) {

  #get results
  op <- foreach(i = 1:length(myQuestions), .combine = "rbind") %do%  {
    base.summary.means(myData,!!rlang::sym(myQuestions[i]), myGroupVar = E3)
  }
  
  #create table
  op <- ArrangeTableB(op)
  
  
  return(op)
}

#CreateTableA_means(d, c("B3ccf", "B3lmb", "B3crp"))
#CreateTableB_means(d, c("B3ccf", "B3lmb", "B3crp"))


# Create Table For Medians Of Responses --------------------------------------
CreateTableA_medians <- function(myData, myQuestions) {

  op <- foreach(i = 1:length(myQuestions), .combine = "rbind") %do%  {
    base.summary.medians(myData,!!rlang::sym(myQuestions[i]), myGroupVar = NA)
  }

  op1 <-
    foreach(i = 1:length(myQuestions), .combine = "rbind") %do%  {
      base.summary.medians(myData,!!rlang::sym(myQuestions[i]), myGroupVar = Resi)
    }

  op2 <-
    foreach(i = 1:length(myQuestions), .combine = "rbind") %do%  {
      base.summary.medians(myData,!!rlang::sym(myQuestions[i]), myGroupVar = E2)
    }
  
  op <- rbind(op, op1, op2)
  #create table
  op <- ArrangeTableA(op)

  return(op)
}

CreateTableB_medians <- function(myData, myQuestions) {
  #get results
  op <- foreach(i = 1:length(myQuestions), .combine = "rbind") %do%  {
    base.summary.medians(myData,!!rlang::sym(myQuestions[i]), myGroupVar = E3)
  }

    #create table
  op <- ArrangeTableB(op)
  
  
  return(op)
}

#CreateTableA_medians(d, c("B3ccf", "B3lmb", "B3crp"))
#CreateTableB_medians(d, c("B3ccf", "B3lmb", "B3crp"))
