library(tidyverse)
library(sf)
library(plotly)
library(rstatix)
library(sfarrow)
options(scipen = 999)


schools <- 
  read_sf("Glasgow/Bld_Schools_Glasgow.shp") %>% 
  select(-c(FID_1, FID_2)) %>% 
  mutate(FID = row_number()) %>% 
  select(FID, everything()) # display a few variables
iz <- read_sf("Glasgow/Glasgow_IZ.shp")
building <- read_sf("Glasgow/Bld_Glasgow.shx") %>% select(zone, area, type)
#pgarden <- read_sf("Glasgow/Private_Garden_Glasgow.shp")
pgarden_p <- st_read_parquet("Glasgow/pgarden.parquet")
code <- read_csv("Glasgow/dz2011_codes_and_labels_21042020.csv")



# Glimpse
schools %>%
  st_drop_geometry() %>%
  glimpse()

# Summary
schools %>%
  st_drop_geometry() %>% 
  get_summary_stats() %>% 
  print(n = Inf) %>% 
  View()

## merge
left_join(schools, code, by = "DataZone") %>% 
  select(FID, DataZone, IntZone, IntZoneName) %>% 
  rename(InterZone = IntZone) -> sch

sch %>% 
  group_by(InterZone, IntZoneName) %>% 
  summarise(no_of_schools = length(FID)) -> schools_area

schools_area %>%
  st_drop_geometry() %>% 
  arrange(desc(no_of_schools)) %>% 
  print(n = Inf)


###
schools_area %>% st_drop_geometry() -> sch_df
  
iz %>% 
  left_join(sch_df, by = "InterZone") -> schools_choropleth


plot(schools_choropleth["no_of_schools"])


schools_choropleth %>% 
  ggplot() +
  geom_sf(aes(fill = no_of_schools), show.legend = NA) +
  theme_bw() +
  scale_fill_continuous(low="thistle2", high="darkred", 
                        guide="colorbar",na.value="white") +
  theme(legend.position = "bottom")


## Plotly
schools_choropleth %>% 
  ggplot() +
  geom_sf(aes(fill = no_of_schools),
          show.legend = NA) +
  theme_bw() +
  scale_fill_continuous(low="thistle2", high="darkred", 
                        guide="colorbar",na.value="white") +
  theme(legend.position = "bottom") -> schools_plotly

ggplotly(schools_plotly)


# building
building %>%
  group_by(type) %>% 
  st_drop_geometry() %>%
  summarise(n = n()) %>% 
  mutate(freq = round(n / sum(n), 3))
  

plot_ly(building, split = ~type)

## Garden
#st_write_parquet(obj=pgarden, dsn=file.path(getwd(), "pgarden.parquet"))

ggplot(pgarden_p) + 
  geom_sf(aes(fill = Land_use), fill = "chartreuse4", color = NA) + 
  theme_bw()

st_join(iz, pgarden_p) %>% 
  group_by(Name) %>% 
  st_drop_geometry() %>% 
  summarise(IZ_Area = sum(area) / 10^6) %>% 
  arrange(desc(IZ_Area))
