library(tidyverse)
library(terra)
library(giscoR)
library(elevatr)
library(sf)

library(ggplot2)
library(ggtext)
library(dplyr)
library(ggridges)
library(emojifont)


# Select a Spanish Region: Comunidad de Madrid
region <- gisco_get_nuts(nuts_id = "ES30") %>%
  # And project data
  st_transform(25830)


dem <- get_elev_raster(region, z = 7, clip = "bbox", expand = 4000) %>%
  # And convert to terra
  rast() %>%
  # Mask to the shape
  mask(vect(region))

# Rename layer for further manipulation
names(dem) <- "elev"

nrow(dem)
#> [1] 698

##terra::plot(dem)



# Approx
factor <- round(nrow(dem) / 110)

dem_agg <- aggregate(dem, factor)

nrow(dem_agg)
#> [1] 88

##terra::plot(dem_agg)



dem_agg[dem_agg < 0] <- 0
dem_agg[is.na(dem_agg)] <- 0

dem_df <- as.data.frame(dem_agg, xy = TRUE, na.rm = FALSE)

as_tibble(dem_df)


ggplot() +
  geom_sf(data = region, color = NA, fill = NA) +
  geom_ridgeline(
    data = dem_df, aes(
      x = x, y = y,
      group = y,
      height = elev
    ),
    scale = 7,
    fill = "white",
    color = "#d10002",
    size = .2,
    ##min_height = .1
  ) +
  theme_void() +
  labs(
    title = "MADRID",
    subtitle = "\U2605\U2605\U2605\U2605\U2605\U2605\U2605",
    caption = "Realizado por **@adrimaqueda**<br>A partir del tutorial de @dhernangomez",
  ) + 
  theme(plot.margin = margin(1,0,1,0, "cm"),
        plot.background = element_rect(fill = "white", colour = "white"),
        plot.title = element_text(color = "#d10002", size = 40, face = "bold", hjust = 0.07, vjust = 0.05),
        plot.subtitle = element_text(color = "#d10002", size = 20, face = "bold", hjust = 0.06, vjust = 0.05),
        plot.caption = element_markdown(color = "#444444", size = 6, lineheight = 1.5),
        panel.background = element_rect(color = "white")
  )


ggsave("elevation_cam.png", dpi = 300, width = 2000, height = 2400, units = "px")
  