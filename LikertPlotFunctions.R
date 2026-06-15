LikertPlot_getOrder<-function(myData) {

  myOrder<-myData %>%
    select(Group,labelGroup, labelPerc) %>%
    unique() %>%
    spread(labelGroup, labelPerc) %>%
    mutate(order1 = high + mid) %>%
    mutate(order2=high) %>%
    arrange(order2, -order1) %>%
    mutate(Group=as.character(Group)) %>%
    pull(Group)
  
  return(myOrder)
}

LikertPlot_CreatePercents<- function(d, myQuestions, myQuestionList, myGroupVar=NA, minimumPerGroupVar=20){
require(foreach)
  
myGroupVar=enquo(myGroupVar)

#calculate percents for each groupVar and year
if (rlang::quo_text(myGroupVar) != "NA") {
  op_data<-foreach(i=myQuestions, .combine="rbind") %do% {
    data.frame(Question=i, base.summary.percent.selectOne(d %>% filter(!is.na(get(quo_name(i)))), i, get(quo_name(myGroupVar))), check.names=FALSE)
  }
} else {
  op_data<-foreach(i=myQuestions, .combine="rbind") %do% {
    data.frame(Question=i,
               base.summary.percent.selectOne(d %>% filter(!is.na(get(quo_name(i)))), i),
               check.names=FALSE)
  }
}

#add group counts and filter
  op_data<-op_data %>% 
    group_by(Year, Group, Question) %>%
    mutate(totalNumber=sum(Number, na.rm=TRUE)) %>%
    filter(totalNumber>=minimumPerGroupVar)
  
#add Question Text
  op_data<-myQuestionList %>% 
    filter(Field %in% myQuestions) %>% 
    select(Year, Question, Field) %>% 
    unique() %>%
    right_join(op_data, by=c("Year"="Year", "Field"="Question")) %>%
    mutate(Question=factor(Question))

    #generate text labels
  numLevels<-nlevels(op_data$Response)
  
  op_data<-op_data %>%
    mutate(labelGroup=ifelse(as.numeric(Response)<=(numLevels/2), "low", NA)) %>%
    mutate(labelGroup=ifelse(as.numeric(Response)>(numLevels/2), "high", labelGroup)) %>%
    mutate(labelGroup=ifelse(as.numeric(op_data$Response)==(numLevels/2 + 0.5), "mid", labelGroup)) %>%
    group_by(Year, Group, Question, Field, labelGroup) %>%
    mutate(labelPerc=round(sum(Value, na.rm=TRUE),0)) %>%
    ungroup() 
  
  return(op_data)
}

LikertPlot_Bar_Full<-function(myLikertPercents, myBarVar, myFacetVar, reverseResponses=TRUE, rowOrder=NA) {
  require(forcats)
  
  myBarVar=enquo(myBarVar)
  myFacetVar=enquo(myFacetVar)
  
  if(reverseResponses==TRUE) {
    myLikertPercents$Response=fct_rev(myLikertPercents$Response)
  }

  if(any(!is.na(rowOrder))) {
    myLikertPercents<-myLikertPercents %>%
      mutate(Group=factor(!!myBarVar, levels=rowOrder))
  }
if(reverseResponses==TRUE){
myplot<-ggplot(data=myLikertPercents) +
    geom_bar(aes(x=!!myBarVar, y=Value, fill=Response), stat="identity") +
    geom_text(data=myLikertPercents[myLikertPercents$labelGroup=="low",],
              aes(x=!!myBarVar, y=-5, label=paste(labelPerc, "%", sep=""))) +
    geom_text(data=myLikertPercents[myLikertPercents$labelGroup=="high",],
              aes(x=!!myBarVar, y=105, label=paste(labelPerc, "%", sep=""))) +
    #geom_text(data=myLikertPercents[myLikertPercents$labelGroup=="mid",],
    #          aes(x=!!myBarVar, y=50, label=paste(labelPerc, "%", sep=""))) +
    scale_fill_viridis_d(begin=0.3) +
    scale_y_continuous(limits=c(-5, 110), breaks=c(0,25,50,75,100)) +
    labs(x="", y="Percent", fill="") +
    guides(fill=guide_legend(reverse=TRUE)) +
    facet_wrap(~get(quo_name(myFacetVar)), ncol=1) +
    coord_flip() +theme_minimal() +
    theme(legend.position = "bottom",
          strip.text=element_text(size=rel(1)), 
          panel.background = element_rect(color="black", size=1))
} else {
  myplot<-ggplot(data=myLikertPercents) +
    geom_bar(aes(x=!!myBarVar, y=Value, fill=Response), stat="identity") +
    geom_text(data=myLikertPercents[myLikertPercents$labelGroup=="low",],
              aes(x=!!myBarVar, y=105, label=paste(labelPerc, "%", sep=""))) +
    geom_text(data=myLikertPercents[myLikertPercents$labelGroup=="high",],
              aes(x=!!myBarVar, y=-5, label=paste(labelPerc, "%", sep=""))) +
    #geom_text(data=myLikertPercents[myLikertPercents$labelGroup=="mid",],
    #          aes(x=!!myBarVar, y=50, label=paste(labelPerc, "%", sep=""))) +
    scale_fill_viridis_d(begin=0.3) +
    scale_y_continuous(limits=c(-5, 110), breaks=c(0,25,50,75,100)) +
    labs(x="", y="Percent", fill="") +
    guides(fill=guide_legend(reverse=TRUE)) +
    facet_wrap(~get(quo_name(myFacetVar)), ncol=1) +
    coord_flip() +theme_minimal() +
    theme(legend.position = "bottom",
          strip.text=element_text(size=rel(1)), 
          panel.background = element_rect(color="black", size=1))
}
return(myplot)
}

# myLikertPercents<-CreateLikertScorePercents(d, myQuestions, q, myGroupVar=B1)
# 
#  myD<-LikertPlot_CreatePercents(d, myQuestions, q, myGroupVar=B1) %>%
#    filter(Year==2018)
#  foreach(i=myQuestions) %do% {
#    td<- myD %>% filter(Field==i)
#    LikertPlot_Bar_Full(td, Group, Question, rowOrder=LikertPlot_getOrder(td))
#  }


deleteme<-function(myGroupVar) {
  return(enquo(myGroupVar))
}
