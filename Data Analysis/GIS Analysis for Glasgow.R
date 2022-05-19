library(tidyverse)
library(sf)

schools <- read_sf("Glasgow/Bld_Schools_Glasgow.shp")
iz <- read_sf("Glasgow/Glasgow_IZ.shp")
building <- read_sf("Glasgow/Bld_Glasgow.shx") %>% select(zone, area, type)
pgarden <- read_sf("Glasgow/Private_Garden_Glasgow.shp")

# I need to do a spatial join to get a zonal stats