sf<-file.choose()
data18 <- as.data.set(spss.system.file(sf))
data18<-as.data.frame(data)
head(data18)
glimpse(data18)
names(data18) %>%
  data.frame() %>%
  arrange
head(data18)
data18[5,]
kable(head(data18))
library(knitr)
l<-data.frame(data18)

l$A13

l %>% 
  select(contains('a1'), contains('a2'), contains('a3'), contains('a4'), contains('a5'), contains('a6'), contains('a7'), contains('a8'), 
         contains('a9')) %>%
  head()
names(l)
        
l[1:250, c('a13', 'a13a')]




#compare spss fields and spreadsheet fields
ssf<-file.choose()
data19 <- read.csv(file=ssf)

spreadsheetNames<-data19 %>%
  filter(Year==2018) %>%
  select(Field, Question) %>%
  unique() %>%
  mutate(SpreadSheetName=Field) %>%
  mutate(Field=tolower(Field))

m<-data.frame(BOSR_Name=names(data18)) %>%
  mutate(BOSR_Field=tolower(BOSR_Name)) %>%
  full_join(spreadsheetNames, by=c("BOSR_Field"="Field")) %>%
  select(Field=BOSR_Field, BOSR_Name, SpreadSheetName, Question)

write.csv(m,file="DeleteMe1.csv")


md<-data.frame(data18)
md$a11a
