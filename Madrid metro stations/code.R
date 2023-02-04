library(osmdata)
library(tidyverse)
library(patchwork)
library(showtext)



madrid_lines <- getbb("Madrid") %>% 
  opq() %>% 
  add_osm_feature(key = "route",
                  value = "subway") %>% 
  osmdata_sf()


ggplot() +
  geom_sf(data = madrid_lines$osm_lines,
          inherit.aes = FALSE,
          size = 0.25,
          colour = "white") +
  ggtitle(label = "Madrid") +
  theme_void() +
  theme(panel.background = element_rect(fill = "#284c5d", colour = "#284c5d"),
        plot.background = element_rect(fill = "#284c5d", colou = "#284c5d"),
        plot.title = element_text(colour = "white", size = 35, hjust = 0),
        plot.margin = margin(t = 10, b = 10, l = 10, r = 10))

