library(tidyverse)
library(scales)
library(grid)
library(showtext)
library(ggtext)
library(suncalc)
library(gganimate)
library(gifski)



Sys.setlocale(category = "LC_TIME", locale = "es_ES")



año <- seq(ymd("2024-01-01"), ymd("2024-12-31"), by = "day")


fixHour <- function(fecha) {
  madridTZ <- with_tz(ymd_hms(fecha), tzone = "Europe/Madrid")

  return(madridTZ)
}

dataset <- map_dfr(
  año,
  ~getSunlightTimes(
    date = .x,
    lat = 40.4168,
    lon = -3.7038
  )
) %>%
  mutate(
    tiempo_sol = as.numeric(difftime(sunset, sunrise, units = "mins")),
    tiempo_sol_formatted = sprintf("%02d:%02d", floor(tiempo_sol/60), floor(tiempo_sol %% 60))
) %>%
  select(date, sunrise, solarNoon, sunset, tiempo_sol, tiempo_sol_formatted) |> 
  mutate(
    mod_sunset = fixHour(sunset) |> `year<-`(2024) |> `month<-`(1) |> `day<-`(1),
    mod_sunrise = fixHour(sunrise) |> `year<-`(2024) |> `month<-`(1) |> `day<-`(1),
    day_of_year = yday(date)
  )


sunset <- c("#152852", "#4B3D60", "#FD5E53", "#FC9C54")
# Add chulapa font
font_add('chulapa', regular = 'font/Chulapa-Regular.otf', bold = 'font/Chulapa-Bold.otf')
showtext_auto()


static_plot <- ggplot(dataset, aes(ymin = mod_sunrise, ymax = mod_sunset, xmin = date, xmax = date + ddays(1))) +
  geom_rect(aes(fill = tiempo_sol), alpha = 0.9) +
  scale_fill_gradientn(
    colors = sunset,
    limits = c(min(dataset$tiempo_sol, 60*9), max(dataset$tiempo_sol, 60*15)),
    breaks = seq(from = 60*9, to = 60*15, by = 120),
    labels = function(x) sprintf("%02d", floor(x/60))  
  ) +
  scale_y_datetime(date_labels = "%H:%M", limits = c(ymd_h('2024-01-01 05'), ymd_hm('2024-01-01 22')), date_breaks = '2 hours') +
  scale_x_date(
    breaks = function(x) {
      seq.Date(
        from = as.Date("2024-01-01"),
        to = as.Date("2025-01-01"),
        by = "3 months"
      )
    },
    labels = function(x) {
      mes <- format(x, "%b", locale = "es_ES")
      ifelse(format(x, "%m") == "01", paste0(mes, "\n", format(x, "%Y")), str_to_title(mes))
    },
    expand = c(0, 1)
  ) +
  labs(
    title = "Horas de sol en Madrid durante el año",
    caption = 'Hecho por @adrimaqueda.com\nCálculos de horas de luz hechos con {suncalc}',
    fill = "Horas de sol"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, lineheight = 0.3, size = 20),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(linetype = "dashed"),
    plot.background = element_rect(color = 'transparent', fill = "#FAFAFA", linewidth = 5),
    plot.title = element_text(family = 'chulapa', face='bold', size=60, margin = margin(20,0,20,0), hjust = 0.5),
    plot.caption = element_text(size=20, margin = margin(20,0,0,0), color="#888888", lineheight = 0.3),
    plot.margin = margin(25,35,20,25),
    axis.title = element_blank(),
    axis.text.y = element_text(size = 20),
    legend.position="top",
    legend.key.width = unit(1, 'cm'),  # Hace la barra de color más ancha
    legend.spacing.x = unit(1, 'cm'),   # Añade espacio entre elementos
    legend.text = element_text(vjust = 1, size = 16, color="#666666"),
    legend.title = element_text(vjust = 0.8, size = 20)
  )

ggsave('hs_madrid.png', static_plot, width = 8, height = 7, dpi = 300)



sunHours <- function(fecha) {
  horas <- as.numeric(str_split_i(fecha, ':', 1))
  minutos <- as.numeric(str_split_i(fecha, ':', 2))

  minutos_text <- if_else(minutos > 1, 'minutos', 'minuto')

  mins <- if_else(minutos != 0, str_glue(" y {minutos} {minutos_text}"), '')

  text <- str_glue("{horas} horas{mins}")

  return(text)
}

amanecer_temp <- function() {
  data <- dataset |> filter(min(dataset$mod_sunrise) == mod_sunrise)

  return (
    str_glue("amanecer más temprano:\n{format(data$date, '%d de %B')}\n{format(data$mod_sunrise, '%H:%M')}")
  )
}

atardecer_late <- function() {
  data <- dataset |> filter(max(dataset$mod_sunset) == mod_sunset)

  return (
    str_glue("atardecer más tardío:\n{format(data$date, '%d de %B')}\n{format(data$mod_sunset, '%H:%M')}")
  )
}


files <- str_c("./hs_anima/D", str_pad(1:366, 3, "left", "0"), ".png")

for(i in 1:366) {

  ggplot(dataset |> filter(day_of_year == i), aes(xmin = mod_sunrise, xmax = mod_sunset, ymin = 1, ymax = 2)) +
  geom_rect(aes(fill = tiempo_sol), alpha = 0.9) +
  geom_label(
    x = min(dataset$mod_sunrise) - dminutes(10),
    y = 1.5,
    label = amanecer_temp(),
    hjust = 1,
    vjust = 0.5,
    size = 10,
    colour = "#4D4D4D",
    fill = "#FAFAFA",
    lineheight = 0.4,
    label.size = NA
  ) +
  geom_segment(
    x = min(dataset$mod_sunrise),
    xend = min(dataset$mod_sunrise),
    y = 1.25,
    yend = 1.75,
    colour = "#888888"
  ) +
  geom_label(
    x = max(dataset$mod_sunset) + dminutes(10) ,
    y = 1.5,
    label = atardecer_late(),
    hjust = 0,
    vjust = 0.5,
    size = 10,
    lineheight = 0.4,
    colour = "#4D4D4D",
    fill = "#FAFAFA",
    label.size = NA
  ) +
  geom_segment(
    x = max(dataset$mod_sunset),
    xend = max(dataset$mod_sunset),
    y = 1.25,
    yend = 1.75,
    colour = "#888888"
  ) + 
  scale_x_datetime(date_labels = "%H:%M", limits = c(ymd_h('2023-12-31 23'), ymd_hm('2024-01-01 23:00')), date_breaks = '4 hours') +
  scale_y_continuous(limits = c(0,3)) +
  scale_fill_gradientn(
    colors = sunset,
    limits = c(min(dataset$tiempo_sol, 60*9), max(dataset$tiempo_sol, 60*15)),
    breaks = seq(from = 60*9, to = 60*15, by = 120),
    labels = function(x) sprintf("%02d", floor(x/60))  
  ) +
  labs(
    title = "Horas de sol en Madrid",
    subtitle = str_glue("{format(ymd(dataset[i,]$date),'%e de %B')}: {sunHours(dataset[i,]$tiempo_sol_formatted)}"),
    caption = 'Hecho por @adrimaqueda.com\nCálculos de horas de luz hechos con {suncalc}',
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5,  , size = 20),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(linetype = "dashed"),
    plot.background = element_rect(color = 'transparent', fill = "#FAFAFA", linewidth = 5),
    plot.subtitle = element_markdown(size=40, margin = margin(0,0,20,0), hjust = 0.5, color = "#666666"),
    plot.title = element_text(family = 'chulapa', face='bold', size=60, margin = margin(20,0,20,0), hjust = 0.5),
    plot.caption = element_text(size=20, margin = margin(20,0,0,0), color="#888888", lineheight = 0.3),
    plot.margin = margin(25,35,20,0),
    axis.title = element_blank(),
    axis.text.y = element_blank(),
    panel.grid.major.y = element_blank(),
    legend.position="none"
  ) +
  coord_cartesian(clip = "off")

  ggsave(files[i], width = 8, height = 8, type = "cairo", dpi = 300)

}

gifski(files, "hs_madrid.gif", width = 1200, height = 1200, loop = T, delay = 0.07)
