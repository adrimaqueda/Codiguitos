library(suncalc)
library(tidyverse)
library(scales)
library(grid)
library(httr2)
library(showtext)
library(ggtext)



# Basic stuff ------------------------------------------------------------------------------------------

Sys.setlocale(category = "LC_TIME", locale = "es_ES")

fecha_actual <- today("Europe/Madrid")
año <- year(fecha_actual)



# We calculate the daily sunshine hours ------------------------------------------------------------------------------------------

# Function for calculating daylight hours for the whole year
calcular_luz_anual <- function(año, latitud, longitud) {
  # Create dataframe with dates
  resultados <- tibble(
    fecha = seq(ymd(paste0(año, "-01-01")), 
                ymd(paste0(año, "-12-31")), 
                by = "day")
  ) |>
    mutate(
      dia_mes = day(fecha),
      dia_año = yday(fecha)
    )
  
  # Calculate sunlight times using purrr
  resultados <- resultados |>
    mutate(
      tiempos_sol = map(
        fecha,
        ~getSunlightTimes(
          date = .x,
          lat = latitud,
          lon = longitud
        )
      ),
      amanecer = map_chr(tiempos_sol, ~format(.x$sunrise, "%H:%M")),
      atardecer = map_chr(tiempos_sol, ~format(.x$sunset, "%H:%M")),
      horas_luz = map_dbl(
        tiempos_sol,
        ~as.numeric(difftime(.x$sunset, .x$sunrise, units = "hours"))
      ),
      tiempo_luz_formato = map_dbl(
        tiempos_sol,
        ~as.numeric(difftime(.x$sunset, .x$sunrise, units = "mins"))
      ) |> 
        map_chr(~sprintf("%02d:%02d", 
                        floor(.x/60), 
                        floor(.x %% 60)))  # floor en lugar de round
    ) |>
    select(-tiempos_sol)  # Remove the temporary column
  
  return(resultados)
}

# Calculate data for Madrid in the current year
# Update local file on January 1st
if (as.numeric(format(fecha_actual, "%j")) == 1) {
  # latitud_madrid <- 40.4168
  # longitud_madrid <- -3.7038
  datos_luz_anuales <- calcular_luz_anual(año, 40.4168, -3.7038)
  write_csv(datos_luz_anuales, 'year_info.csv')
} else {
  datos_luz_anuales <- read_csv('year_info.csv', col_types = c('Didccdc'))
}


# Get today's info
hoy <- datos_luz_anuales |> filter(dia_año == as.numeric(format(fecha_actual, "%j")))

# Create the data for the solstice
s_verano <- ymd(paste0(año, "-06-21"))
s_invierno <- ymd(paste0(año, "-12-21"))

solsticio_verano <- datos_luz_anuales |> filter(dia_año == as.numeric(format(s_verano, "%j")))
solsticio_invierno <- datos_luz_anuales|> filter(dia_año == as.numeric(format(s_invierno, "%j")))



# Select the post text ------------------------------------------------------------------------------------------

# change the hour to spanish timezone
fixHour <- function(hora) {
  madridTZ <- with_tz(ymd_hms(str_glue("{fecha_actual} {hora}:00")), tzone = "Europe/Madrid")

  return(format(madridTZ, "%H:%M"))
}

# text depending on the day of the year
daysCount <- function() {

  d_cortos <- fecha_actual > s_verano

  calc_dias <- if_else(
    d_cortos,
    interval(ymd(fecha_actual),ymd(s_invierno)) %/% days(1), 
    interval(ymd(fecha_actual),ymd(s_verano)) %/% days(1)
  )

  max_sol <- '¡Hoy es el día con más horas de luz del año! 🎉🎉🎉'
  max_noche <- 'Hoy es el día con menos horas de luz del año... 🫤🫤🫤\n\n❄️❄️ Winter is coming ❄️❄️'

  start_max_sol <- '¡Vamos! ¡Que a partir de hoy los días empiezan a ser más largos! 🎉🎉🎉'

  menos_luz <- str_glue("Hoy habrá menos horas de luz que ayer 🫠\n\nDurante {calc_dias} días más se seguirán acortando las horas de sol")
  mas_luz <- str_glue("Hoy habrá más horas de luz que ayer, durante {calc_dias} días más seguirán aumentando las horas de sol")

  text <- case_when(
    fecha_actual == s_verano ~ max_sol,
    fecha_actual == s_invierno ~ max_noche,
    as.numeric(fecha_actual) == as.numeric(format(s_verano, "%j")) + 1 ~ start_max_sol,
    d_cortos ~ menos_luz,
    T ~ mas_luz,
  )
  
  return(text)
}

# sun hours
sunHours <- function() {
  horas <- as.numeric(str_split_i(hoy$tiempo_luz_formato, ':', 1))
  minutos <- as.numeric(str_split_i(hoy$tiempo_luz_formato, ':', 2))

  minutos_text <- if_else(minutos > 1, 'minutos', 'minuto')

  text <- str_glue("En total, habrá {horas} horas y {minutos} {minutos_text} de sol:\n🌅 {fixHour(hoy$amanecer)}\n🌇 {fixHour(hoy$atardecer)}")

  return(text)
}



# Let's create the chart ------------------------------------------------------------------------------------------

# Color scale
sunset <- c("#152852", "#4B3D60", "#FD5E53", "#FC9C54")

# Border color
color_hoy <- col_numeric(palette = sunset, domain = range(datos_luz_anuales$horas_luz, na.rm = TRUE))(hoy$horas_luz)

# Add chulapa font
font_add('chulapa', regular = 'font/Chulapa-Regular.otf', bold = 'font/Chulapa-Bold.otf')
showtext_auto()

# ggplot
plot <- ggplot(datos_luz_anuales, aes(x = fecha, y = horas_luz, color = horas_luz)) +
  geom_line(color = "#CCCCCC", linewidth=1.5, alpha = 0.9) +
  geom_point(data = solsticio_verano |> bind_rows(solsticio_invierno), 
      shape = 1,  # Empty circle (border only)
      aes(x = fecha, y = horas_luz, color = horas_luz),
      size = 6,
      alpha = 0.7) +
  geom_point(data = hoy, 
      aes(x = fecha, y = horas_luz, color = horas_luz),
      size = 5) +
  scale_color_gradientn(
    colors = sunset,
    limits = range(datos_luz_anuales$horas_luz, na.rm = TRUE)  
  ) +
  geom_label(
    x = min(datos_luz_anuales$fecha),
    y = 15,
    label = "horas",
    hjust = 0.2,
    vjust = 0.55,
    size = 2.8,
    colour = "#4D4D4D",
    fill = "#FAFAFA",
    label.size = NA
  ) +
  labs(
    title = "Horas de luz en Madrid",
    subtitle = str_glue("{format(ymd(hoy$fecha),'%d de %B')}: <img src='./images/sunrise.png' height='10' style='vertical-align: bottom'/>{fixHour(hoy$amanecer)} - <img src='./images/sunset.png' height='10' style='vertical-align: bottom'/>{fixHour(hoy$atardecer)}"),
    caption = 'Hecho por @adrimaqueda.com\nCálculos de horas de luz hechos con {suncalc}'
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, lineheight = 0.9),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(linetype = "dashed"),
    plot.background = element_rect(color = color_hoy, fill = "#FAFAFA", linewidth = 5),
    plot.title = element_text(family = 'chulapa', face='bold', size=20, margin = margin(10,0,10,0), hjust = 0.5),
    plot.subtitle = element_markdown(size=10, margin = margin(0,0,20,0), hjust = 0.5, color = "#666666"),
    plot.caption = element_text(size=7, margin = margin(10,0,0,0), color="#888888"),
    plot.margin = margin(25,35,20,25),
    axis.title = element_blank(),
    legend.position="none"
  ) +
  scale_x_date(
    breaks = function(x) {
      seq.Date(
        from = as.Date(paste0(año, "-01-01")),
        to = as.Date(paste0(año+1, "-01-01")),
        by = "3 months"
      )
    },
    labels = function(x) {
      mes <- format(x, "%b", locale = "es_ES")
      ifelse(format(x, "%m") == "01", paste0(mes, "\n", format(x, "%Y")), str_to_title(mes))
    },
    expand = c(0, 1)
  ) +
  coord_cartesian(clip = "off")


# create the png file
png("chart.png", width = 6, height = 6, units = "in", res = 300)

# add the border
grid.newpage()
grid.draw(ggplotGrob(plot))
grid.roundrect(gp = gpar(fill = NA, col = color_hoy, lwd = 25), r = unit(10, "mm"))

dev.off()



# Bsky API stuff ------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------
# Basically all translated from the Python example at https://atproto.com/blog/create-post
# Adapted from Adrew Heiss' code https://gist.github.com/andrewheiss/fa6b43cfa94bb11f0c1144b6cb4a0272
# ---------------------------------------------------------------------------------------------------------

# Create a logged-in API session object
session <- request("https://bsky.social/xrpc/com.atproto.server.createSession") |> 
  req_method("POST") |> 
  req_body_json(list(
    identifier = "horasdesolmadrid.bsky.social",
    password = Sys.getenv('BLUESKY_APP_PASS')
  )) |> 
  req_perform() |> 
  resp_body_json()

# This is the token you can use for other API calls:
# session$accessJwt

# path & type of image
IMAGE_PATH <- "chart.png"
IMAGE_MIMETYPE <- "image/png"
IMAGE_ALT_TEXT <- "Horas de sol en Madrid"

# read the image as bytes
img_bytes <- readBin(IMAGE_PATH, "raw", file.info(IMAGE_PATH)$size)

# verify img size
if (length(img_bytes) > 1000000) {
  stop("Image file size too large. 1000000 bytes maximum, got: ", length(img_bytes))
}

# upload the img & get the blob
upload_response <- request(paste0('https://bsky.social', "/xrpc/com.atproto.repo.uploadBlob")) |> 
  req_method("POST") |> 
  req_headers(
    "Content-Type" = IMAGE_MIMETYPE,
    "Authorization" = paste0("Bearer ", session$accessJwt)
  ) |> 
  req_body_raw(img_bytes) |> 
  req_perform()

if (resp_status(upload_response) != 200) {
  stop("Error uploading image: ", resp_body_string(upload_response))
}

blob <- resp_body_json(upload_response)$blob


# Create a post as a list
post_body <- list(
  "$type" = "app.bsky.feed.post",
  text = str_glue("{daysCount()}\n\n{sunHours()}"),
  createdAt = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%OS6Z"),
  langs = list("es-ES"),
  embed = list(
    `$type` = "app.bsky.embed.images",
    images = list(
      list(
        image = blob,
        alt = IMAGE_ALT_TEXT
      )
    )
  )
)

# Publish the post
resp <- request("https://bsky.social/xrpc/com.atproto.repo.createRecord") |> 
  req_method("POST") |> 
  req_headers(Authorization = paste0("Bearer ", session$accessJwt)) |> 
  req_body_json(list(
    repo = session$did,
    collection = "app.bsky.feed.post",
    record = post_body
  ))

# Actually make the request and post the thing
resp |> req_perform()
