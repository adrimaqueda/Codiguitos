## LITTLE PICTURE SUBMISSION
## ADRIÁN MAQUEDA - @adrimaqueda

## libraries ----

library(terra)
library(giscoR)
library(tidyverse)
library(sf)
library(slendr)

## maps ----

# europe
europeMap <- gisco_get_countries(region = 'Europe') |> 
  filter(CNTR_ID != "RU")

# world
world <- read_sf('worldMap/ne_50m_admin_0_countries.shp') 

## load data ----

files <- list.files("data", pattern = "*.nc", full.names = T)
fullEuropeRaster <- rast(files)

# mask to Europe territories
europeRaster <- terra::crop(fullEuropeRaster, europeMap) |>  
  terra::mask(vect(europeMap))

# make the dataframe
europeDF <- as.data.frame(europeRaster, xy = T)

# rename the columns
dates <- time(europeRaster)
nCols <- europeDF |> ncol()
names(europeDF)[3:nCols] <- as.character(str_sub(dates, 1, 10))

# make it long
europeLong <- europeDF |> 
  pivot_longer(!c(x,y), names_to = "date", values_to = "fwi") |> 
  mutate(
    date = ymd(date),
    year = year(date)
  )

## calc progression ----

yearRecountRaw <- europeLong |> 
  filter(fwi > 38) |> 
  group_by(x, y, year) |> 
  summarise(daysOnRisk = n()) |> 
  ungroup()

yearRecount <- yearRecountRaw |> 
  arrange(year) |> 
  pivot_wider(names_from = year, values_from = daysOnRisk, values_fill = 0) |> 
  pivot_longer(cols = !c(x,y), names_to = "year", values_to = "daysOnRisk")

# loess
loessRecount <- yearRecount |> 
  group_by(x,y) |> 
  mutate(
    loess = if_else(predict(loess(daysOnRisk ~ year, span = 0.5)) > 0, predict(loess(daysOnRisk ~ year, span = 0.5)), 0)
  ) |> 
  ungroup()

# variations
bigVariation <- loessRecount |> 
  filter(year %in% c("1971", "2022")) |> 
  select(!daysOnRisk) |> 
  pivot_wider(names_from = year, values_from = loess) |> 
  mutate(variation = `2022` - `1971`)


lastDecadeVariation <- loessRecount |> 
  filter(year %in% c("2000", "2022")) |> 
  select(!daysOnRisk) |> 
  pivot_wider(names_from = year, values_from = loess) |> 
  mutate(variation = `2022` - `2000`)


## graph ----

ortho_crs <-'+proj=ortho +lat_0=38 +lon_0=9 +x_0=0 +y_0=0 +R=6371000 +units=m +no_defs +type=crs'

mapData <- reproject(
  from = "epsg:4326",
  to = ortho_crs,
  coords = bigVariation,
  add = TRUE # add converted [lon,lat] coordinates as a new column
)

landColor <- '#111111'

# circle
circleMap <- ggplot() +
  geom_sf(data = world, fill=landColor, colour = landColor) +
  geom_point(data = mapData |> filter(`2022` >= 0.5), aes(x=newx, y=newy, colour = variation, size = `2022`), alpha = .8) +
  coord_sf(expand = FALSE, crs= ortho_crs) +
  lims(x = c(-2800000, 3800000), y = c(-1200000, 4200000)) +
  scale_color_gradient(low="yellow", high="red") +
  scale_size_continuous(range = c(.1,3)) +
  theme_minimal() +
  theme(
    legend.position="none",
    line = element_blank(),
    text = element_blank(),
    panel.background = element_rect(fill = "#333333")
  )


ggsave("circleMap.png", circleMap, width = 60, height = 60, units = "cm")







