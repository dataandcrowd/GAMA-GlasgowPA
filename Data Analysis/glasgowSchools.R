library(sf)

schoolpop <- read_csv("Glasgow/ChildrenPOP_ScottishDZ.csv")
glasgowoa <- read_sf("Glasgow/Glasgow_OA.shp")


glasgowoa %>% 
  left_join(schoolpop, by = c("InterZone" = "DataZone")) %>% 
  View()
  
