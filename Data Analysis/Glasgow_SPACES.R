library(tidyverse)
library(sf)
library(plotly)
library(rstatix)
library(sfarrow)
library(leaflet)
options(scipen = 999)

datazone_name <- read_csv("Glasgow/dz2011_codes_and_labels_21042020.csv")
datazone <- read_sf("Glasgow/Glasgow_DataZone.shp")
childagg <- read_csv("Glasgow/ChildrenPOP_ScottishDZ.csv")



## merge
left_join(datazone, childagg, by = "DataZone") %>% 
  left_join(datazone_name, by = "DataZone") %>% 
  select(DataZone, DataZoneName, Freq.) %>% 
  rename(No_of_Children = Freq.)-> sch

plot(sch["No_of_Children"])


sch %>% 
  mutate(No_of_Children = factor(No_of_Children)) %>% 
  ggplot() +
  geom_sf(aes(fill = No_of_Children), show.legend = NA, colour = "grey") +
  scale_fill_manual(values = c("red", "blue"), na.value = "grey50") +
  theme_bw() +
  theme(legend.position = "bottom")

sch %>% 
  st_drop_geometry() %>% 
  arrange(desc(No_of_Children)) %>% 
  print(n = 20)

## Transform to a lat long coordinate
school_latlon <- 
  sch %>% 
  select(DataZoneName, No_of_Children) %>% 
  st_transform('+proj=longlat +datum=WGS84')

# Little configurations
pal <- colorBin("YlOrRd", domain = school_latlon$No_of_Children, bins = 3)
labels <- sprintf(
  "<strong>%s</strong><br/>%g Student(s)",
  school_latlon$DataZoneName, school_latlon$No_of_Children
) %>% lapply(htmltools::HTML)


# Visualisation
map1 <- leaflet() %>% 
  addTiles() %>% 
  addPolygons(data=school_latlon,
              fillColor = ~pal(No_of_Children),
              weight = 0.5,
              opacity = 1,
              color = "white",
              dashArray = "3",
              fillOpacity = 0.6,
              highlightOptions = highlightOptions(
                weight = 5,
                color = "#666",
                dashArray = "",
                fillOpacity = 0.7,
                bringToFront = TRUE),
              label = labels,
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")
              )
map1


