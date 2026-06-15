
d1<-d %>%
  select(surveyYear, B1) %>%
  group_by(surveyYear, B1) %>%
  summarise(num=n()) %>%
  ungroup() %>%
  mutate(surveyYear=factor(surveyYear)) %>%
  filter(!is.na(B1)) %>%
  mutate(yearGroup=as.numeric(surveyYear)) %>%
  group_by(surveyYear) %>%
  mutate(totalNum=sum(num)) %>%
  ungroup() %>%
  mutate(perc=round(num/totalNum*100,0)) %>%
  group_by(surveyYear) %>%
  top_n(n=8) %>%
  ungroup()

d2<-d1 %>%
  select(response=B1, percent=perc, year=surveyYear)
glimpse(d2)

boxes<-d1 %>%
  arrange(yearGroup, -perc) %>%
  group_by(yearGroup) %>%
  mutate(numEnd=100-cumsum(perc)) %>%
  mutate(numStart=100-(cumsum(perc) - perc)) %>%
  mutate(xStart = 2 * yearGroup - 1,
         xEnd = 2 * yearGroup - 0) %>%
  ungroup() %>%
  mutate(xMid=(xEnd-xStart)/2+xStart,
         yMid=((numStart-numEnd)/2)+numEnd)

ribbons<-boxes %>%
  select(B1, numStart, numEnd, xStart, xEnd) %>%
  gather(myX, myValue, c("xStart", "xEnd")) %>%
  select(-myX)



ggplot(boxes) +
  geom_rect(aes(xmin=xStart, xmax=xEnd, ymin=numStart, ymax=numEnd, fill=B1)) +
  geom_ribbon(data=ribbons,aes(x=myValue, ymin=numEnd, ymax=numStart, fill=B1), alpha=0.27) +
  geom_text(data=boxes %>% filter(yearGroup==3), aes(x=6.1, y=((numStart-numEnd)/2)+numEnd, label=B1, hjust=0)) +
  geom_text(data=data.frame(myX=c(1.5, 3.5, 5.5), myY=c(0,0,0), myLabel=c("2002", "2012", "2018")), aes(x=myX, y=myY, label=myLabel)) +
  geom_text(aes(x=xMid,y=yMid, label=paste(perc, "%", sep="")), color=c("white","white","white","black","white","white","black","white",
                                                                       "white","white","white","white","black","white","black","white","white","white","white",
                                                                       "white","white","black","white","white","white","black","white"),
            size=3) +
  scale_fill_viridis_d() +
  scale_x_continuous(limits=c(1,8)) +
  labs(x="", y="", title="Most Preferred Species") +
  theme_minimal() +
  theme(panel.grid=element_blank(),
        legend.position="none",
        axis.text.y=element_blank(),
        axis.text.x=element_blank(),
        plot.title=element_text(size=22, hjust=0.31)) 


#dataframe should include c("response", "percent", "year")
CreateRankChangeChart<-function(d, NumberOfResponses=5, title=""){
  require(ggspectra)
  require(viridis)
  require(forcats)
  
  d<-d %>%
    mutate(response=factor(response),
           year=factor(year)) %>%
    filter(!is.na(response)) %>%
    mutate(yearGroup=as.numeric(year)) %>%
    ungroup() %>%
    arrange(yearGroup, -percent) %>%
    group_by(year) %>%
    mutate(recnum=row_number()) %>%
    filter(recnum<=NumberOfResponses) %>%
    select(-recnum) %>%
    ungroup() %>%
    mutate(response=fct_drop(response))
  
  boxes<-d %>%
    arrange(yearGroup, -percent) %>%
    group_by(yearGroup) %>%
    mutate(numEnd=100-cumsum(percent)) %>%
    mutate(numStart=100-(cumsum(percent) - percent)) %>%
    mutate(xStart = 2 * yearGroup - 1,
           xEnd = 2 * yearGroup - 0) %>%
    ungroup() %>%
    mutate(xMid=(xEnd-xStart)/2+xStart,
           yMid=((numStart-numEnd)/2)+numEnd)
  
  ribbons<-boxes %>%
    select(response, numStart, numEnd, xStart, xEnd) %>%
    gather(myX, myValue, c("xStart", "xEnd")) %>%
    select(-myX)
  
  
  numberOfColors <- d %>%
    group_by(year) %>%
    summarise(num=n()) %>%
    ungroup() %>%
    summarise(num=max(num)) %>%
    pull(num)
  
  
  myPalette<-data.frame(fillColor=viridis_pal()(numberOfColors)) %>%
    mutate(responseNum=row_number())
  
  boxes<-boxes %>%
    mutate(responseNum=as.numeric(response)) %>%
    left_join(myPalette, by=("responseNum")) %>%
    select(-responseNum) %>%
    mutate(textColor=black_or_white(fillColor, threshold=0.65))
  
  op<-ggplot(boxes) +
    geom_rect(aes(xmin=xStart, xmax=xEnd, ymin=numStart, ymax=numEnd, fill=response)) +
    geom_ribbon(data=ribbons,aes(x=myValue, ymin=numEnd, ymax=numStart, fill=response), alpha=0.27) +
    geom_text(data=boxes %>% filter(yearGroup==max(boxes$yearGroup)), aes(x=(max(yearGroup*2) + 0.1), y=((numStart-numEnd)/2)+numEnd, label=response, hjust=0)) +
    geom_text(data=data.frame(myX=seq(1.5, (max(boxes$yearGroup*2)-0.5),by=2), myY=c(min(boxes$numEnd)-2), myLabel=levels(boxes$year)), aes(x=myX, y=myY, label=myLabel)) +
    geom_text(aes(x=xMid,y=yMid, label=paste(percent, "%", sep="")), color=boxes$textColor, size=3) +
    scale_fill_viridis_d() +
    scale_x_continuous(limits=c(1,max(boxes$xEnd)+1)) +
    labs(x="", y="", title=title, subtitle=paste("Top ", NumberOfResponses, " Responses", sep="")) +
    theme_minimal() +
    theme(panel.grid=element_blank(),
          legend.position="none",
          axis.text.y=element_blank(),
          axis.text.x=element_blank(),
          plot.title=element_text(size=22, hjust=0.31),
          plot.subtitle=element_text(size=14, hjust=0.31)) 
  
  
  return(op)
  
}

CreateRankChangeChart(d2, 8, title="Most Preferred Species")
