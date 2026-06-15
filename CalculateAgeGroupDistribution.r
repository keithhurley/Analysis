#run this code everytime new 2018 data is added...
#it creates age-groups for the permit data and age distributions for raking

options(stringsAsFactors = FALSE)
library(tidyverse)
library(foreach)
library(survey)
library(readxl)
library(eeptools) #age_calc function
library(dplyr) #make it last for name conflicts

#get permit database data
mySample<-read_excel(path="../../Data/Anglers_tracking_cleaned.xlsx") %>% 
  mutate(LicenseDbId=as.numeric(LicenseDbId))

myPermits<-read_excel(path="../../Data/KH_10.25.2018_Fishing Permit Data (Permits Valid in 2017).xlsx") %>% 
  group_by(OwnerCustomerUID) %>%
  left_join(mySample, by=c("OwnerCustomerUID"="LicenseDbId")) #%>%
  #mutate(LicenseDbId=licenseUID)

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

#create license population distributions for age
ageDist<-myPermits2 %>%
  ungroup() %>%
  select(Age_cat) %>%
  filter(!is.na(Age_cat)) 

ageDist<-data.frame(table(ageDist$Age_cat)) %>%
  mutate(ageGroup=factor(Var1)) %>%
  select(ageGroup, Freq) %>%
  mutate(E3=factor(ageGroup)) %>%
  select(-E3) %>%
  rename(age_group=ageGroup) %>%
  mutate(Freq=Freq/sum(Freq))


save(myPermits2, ageDist, file="../../data/AgeDistributions_2018.rdata")
