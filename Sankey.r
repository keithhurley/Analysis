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

#CreateRankChangeChart(d2, 8, title="Most Preferred Species")
