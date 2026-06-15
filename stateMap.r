options()

library(sf)
library(USAboundaries)

#NGPC_regions<-read_sf("https://opendata.arcgis.com/datasets/32f5ab06cd9b4ef9a0290f1c50e6fd05_59.geojson")
NGPC_regions<-read_sf("https://opendata.arcgis.com/datasets/32f5ab06cd9b4ef9a0290f1c50e6fd05_59.geojson")
#NGPC_public_waters<-read_sf("https://opendata.arcgis.com/datasets/2954cfbde1c44ddd8977848082d49029_37.geojson") %>% lwgeom::st_make_valid() %>% st_cast("MULTIPOLYGON")
#NGPC_public_waters<-read_sf("https://opendata.arcgis.com/datasets/75847bdc3e9e498da9e4dfaef4998820_0.geojson") %>% lwgeom::st_make_valid() %>% st_cast("MULTIPOLYGON")
NGPC_public_waters<-read_sf("https://opendata.arcgis.com/datasets/5fdfcc32648e43e6aa694af2eb15da46_0.geojson") %>%
  filter(!str_detect(WaterbodyName, "Scenic Park")) %>%
  filter(!str_detect(WaterbodyName, "Graske")) %>%
  filter(!str_detect(WaterbodyName, "Dodge Memorial Park")) %>%
  filter(!str_detect(WaterbodyName, "Haworth Park \\(Missouri River")) %>%
  filter(!str_detect(WaterbodyName, "Elkhorn Crossing")) %>%
  filter(!str_detect(WaterbodyName, "Waterloo River Access")) %>%
  filter(!str_detect(WaterbodyName, "Two Rivers SRA \\(Platte")) %>%
  filter(!str_detect(WaterbodyName, "\\(Missouri River")) %>%
  filter(!str_detect(WaterbodyName, "Louisville SRA \\(Platte")) %>%
  filter(!str_detect(WaterbodyName, "Blue Creek")) %>%
  filter(!str_detect(WaterbodyName, "Squaw Creek"))

sf_nebr<-us_states(resolution="high", states="Nebraska")
sf_counties<-us_counties(resolution="high", states="Nebraska")

baseMap<- ggplot() +
  geom_sf(data=sf_counties, fill="white", color="gray85") +
  geom_sf(data=sf_nebr, fill="transparent", color="black") +
  annotation_north_arrow(location="bl", 
                         height=unit(0.175, "snpc"), 
                         width=unit(0.175,"snpc"), 
                         which_north="true", 
                         style=north_arrow_nautical(), 
                         pad_x=unit(0.095, "npc"), 
                         pad_y=unit(0.15,"npc")) +
  annotation_scale(location="bl", 
                   height=unit(0.02, "npc"), 
                   width_hint=0.15, 
                   unit_category="imperial", 
                   pad_x=unit(0.073, "npc"), 
                   pad_y=unit(0.1,"npc")) +
  theme_minimal() +
  theme(panel.grid=element_line(color="transparent"),
        axis.text=element_blank(),
        plot.title=element_text(hjust=0.5, size=14))

baseMap_omaha <- ggplot() +
  geom_sf(data=sf_counties %>% filter(name %in% c("Douglas", "Sarpy")), fill="white", color="gray85") +
  annotation_north_arrow(location="bl", 
                         height=unit(0.175, "snpc"), 
                         width=unit(0.175,"snpc"), 
                         which_north="true", 
                         style=north_arrow_nautical(), 
                         pad_x=unit(0.025, "npc"), 
                         pad_y=unit(0.15,"npc")) +
  annotation_scale(location="bl", 
                   height=unit(0.02, "npc"), 
                   width_hint=0.15, 
                   unit_category="imperial", 
                   pad_x=unit(0.03, "npc"), 
                   pad_y=unit(0.1,"npc")) + 
  theme_minimal() +
  theme(panel.grid=element_line(color="transparent"),
        axis.text=element_blank(),
        plot.title=element_text(hjust=0.5, size=14))

getRegionMap<-function(myRegion=c("NE", "NW", "SE", "SW")){
  
    myCounties<-sf_counties %>% st_intersection(NGPC_regions %>% filter(District==myRegion))
      
    myNebr<-sf_nebr %>% st_intersection(NGPC_regions %>% filter(District==myRegion))
      
    baseMap<-ggplot() +
      geom_sf(data=myCounties, fill="white", color="gray85") +
      geom_sf(data=myNebr, fill="transparent", color="black") +
      theme_minimal() +
      theme(panel.grid=element_line(color="transparent"),
            axis.text=element_blank(),
            plot.title=element_text(hjust=0.5, size=14))
 return(baseMap)
}

getRegionPubWaters<-function(myRegion=c("NE", "NW", "SE", "SE")) {
  
  op <- lwgeom::st_make_valid(NGPC_public_waters) %>% st_cast("MULTIPOLYGON")
  op <- op %>% st_intersection(NGPC_regions %>% filter(District==myRegion))
  
  return(op)
}


getRegionWaters<-function(myData, myRegion=c("NE", "NW", "SE", "SE")) {
  
  op <- lwgeom::st_make_valid(st_as_sf(myData)) %>% st_cast("MULTIPOLYGON")
  op <- op %>% st_intersection(NGPC_regions %>% filter(District==myRegion))
  
  return(op)
}
