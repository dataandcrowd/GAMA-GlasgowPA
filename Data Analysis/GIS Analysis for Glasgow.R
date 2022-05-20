library(tidyverse)
library(sf)

schools <- 
  read_sf("Glasgow/Bld_Schools_Glasgow.shp") %>% 
  select(-c(FID_1, FID_2)) %>% 
  mutate(FID = row_number()) %>% 
  select(FID, 2:15) # display a few variables
iz <- read_sf("Glasgow/Glasgow_IZ.shp")
building <- read_sf("Glasgow/Bld_Glasgow.shx") %>% select(zone, area, type)
pgarden <- read_sf("Glasgow/Private_Garden_Glasgow.shp")

# I need to do a spatial join to get a zonal stats
# 
# sptial join and sum
aggregate(iz[1], schools[1], sum)
https://ryanpeek.org/2019-04-29-spatial-joins-in-r/