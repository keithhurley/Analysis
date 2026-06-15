options(stringsAsFactors = FALSE)
#devtools::install_github("davidgohel/officer")
#devtools::install_github("davidgohel/officedown")
library(officedown)
library(rmarkdown)
library(tidyverse)
library(knitr)
library(flextable)
library(stringr)

source("..\\BaseFunctions.R") #load file of common functions
source("CrossTabTableFunctions.R") #load file of cross tab report functions

d<-base.loaddata(myYears="2018", myVenues=c("mail", "email"))
save(d, file="d_20180227_2018_email_mail.rData")
load(file="d_20180227_2018_email_mail.rData")

#q<-base.loaddata.factorlevels()
#save(q, file="q_20180221")
load(file="q_20180221")

l=read.csv(file="..\\..\\Data\\Labels.csv")

table(d$gtype2)

d1<-d %>%
  filter(gtype %in% c("Bass", "Catfish", "Walleye-Sauger", "Sunfish")) %>%
  filter(Resi=="Resident")

unique(d1$E4)
unique(d1$E3)
unique(d1$E5)
unique(d1$E6)

names(d1)

ggplot(d1) +
  geom_histogram(aes(x=E3), stat="count") +
  facet_wrap(~gtype, ncol=1)

ggplot(d1) +
  geom_histogram(aes(x=E4), stat="count") +
  facet_wrap(~gtype, ncol=1)

ggplot(d1) +
  geom_histogram(aes(x=E5), stat="count") +
  facet_wrap(~gtype, ncol=1)

ggplot(d1) +
  geom_histogram(aes(x=E6), stat="count") +
  facet_wrap(~gtype, ncol=1)

ggplot(d1) +
  geom_histogram(aes(x=A7_miles), stat="count") +
  facet_wrap(~gtype, ncol=1)

ggplot(d1) +
  geom_histogram(aes(x=A8_miles), stat="count") +
  facet_wrap(~gtype, ncol=1)

library(rgdal)
library(sf)
geos<-readOGR("..\\..\\data\\FullDocGeocode\\Full_DocLocations.shp") %>%
  st_as_sf() %>%
  mutate(USER_BosrI=as.numeric(USER_BosrI))

myAnglers<-d1 %>%
  left_join(geos[,c("X", "Y", "USER_BosrI")], by=c("licenseUID"="USER_BosrI")) %>%
  select(ID=licenseUID, X=X.y, Y, anglerType=gtype)

write.csv(myAnglers, file="Anglers.csv")
