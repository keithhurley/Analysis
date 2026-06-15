options(stringsAsFactors = FALSE)
library(tidyverse)
library(foreach)
library(survey)
library(readxl)
library(eeptools) #age_calc function
library(dplyr) #make it last for name conflicts

source("..\\BaseFunctions.R") #load file of common functions

#get permit database data
mySample<-read_excel(path="../../Data/Anglers_tracking_cleaned.xlsx") %>% 
  mutate(LicenseDbId=as.numeric(LicenseDbId))

myPermits<-read_excel(path="../../Data/KH_10.25.2018_Fishing Permit Data (Permits Valid in 2017).xlsx") %>% 
  mutate(licenseUID=OwnerCustomerUID) %>%
  group_by(licenseUID) %>%
  mutate(tmpRank=rank(PermitNumber)) %>%
  left_join(mySample, by=c("licenseUID"="LicenseDbId")) %>%
  mutate(LicenseDbId=licenseUID)


myPermits2<-myPermits %>%
  filter(as.Date(dob)<as.Date('2018-11-1')) %>%
  mutate(Age=round(age_calc(as.Date(dob), enddate=as.Date('2018-11-1'), units = "years", precise = TRUE)), 0) %>%
  filter(Age>=16) %>%
  mutate(Age_cat=cut(as.numeric(Age),
                     breaks=c(16, 25, 35, 45, 55, 65, Inf),
                     labels=c("16-24", "25-34", "35-44", "45-54", "55-64", "65 and older" ),
                     right = FALSE)) %>%
  filter(!is.na(Age_cat) & Age_cat!="NULL") %>%
  ungroup() 

#save(myPermits2, file="tempMyPermits2.rdata")
load(file="tempMyPermits2.rdata")

#load data
d<-base.loaddata(myYears="2018", myVenues=c("mail", "email"))

#fill in unanswered E3 with database derived age group
#must use unique on myPermits as there are multiples of the same ID

myPermits2<-myPermits2 %>%
  group_by(licenseUID) %>%
  slice(1)

d<-d %>%
  left_join(myPermits2[,c("BosrId", "Age_cat")], by=c("licenseUID"="BosrId")) %>%
  mutate(E3=factor(ifelse(is.na(E3), as.character(Age_cat), as.character(E3)))) 


#create survey design object for survey package
library(survey)
svyObject<-svydesign(ids=~1,data=d)

#create license population distributions for age
ageDist<-myPermits2 %>%
  ungroup() %>%
  #left_join(myPermits2, by=c("licenseUID"="BosrId")) %>%
  select(Age_cat) %>%
  filter(!is.na(Age_cat)) 

ageDist<-data.frame(table(ageDist$Age_cat)) %>%
  mutate(ageGroup=factor(Var1)) %>%#,
         #Freq=round(Freq,3)*100) %>%
  select(ageGroup, Freq) %>%
  mutate(E3=factor(ageGroup)) %>%
  select(-ageGroup) %>%
  mutate(Freq=Freq/sum(Freq)*nrow(d))


#compute weights by raking
set.seed(123454321)
d_rake<-rake(design=svyObject, 
             sample.margins=list(~E3),
             population.margins = list(ageDist))

summary(weights(d_rake))
sum(weights(d_rake))

ggplot(data.frame(w=weights(d_rake))) +
  geom_histogram(aes(x=w))

d_rake<-trimWeights(d_rake, lower=0.5, upper=3, strict=TRUE)

summary(weights(d_rake))
sum(weights(d_rake))

ggplot(data.frame(w=weights(d_rake))) +
  geom_histogram(aes(x=w))

tmp<-data.frame(weights(d_rake))
names(tmp)<-c("var1")
ggplot(tmp) +
  geom_histogram(aes(x=var1))
  
sum(weights(d_rake))  

postWeights<-cbind(d, postWeight=weights(d_rake)) %>% 
  select(licenseUID, postWeight)

sum(postWeights$postWeight)
nrow(postWeights)

#save(postWeights, file="../../Data/weights_raked_ageGroup_20190705.rData")


go<-function(mySurveyObject, myVariables, myPopMargins){
  #myVariables<-enquo(myVariables)
  
  t_rake<-rake(design=mySurveyObject,
               sample.margins=myVariables,
               population.margins=myPopMargins)
  return(t_rake)
}


mySurveyObject=svyObject
myVariables="E3"
myPopMargins=ageDist
go(svyObject, list(~E3), list(ageDist))