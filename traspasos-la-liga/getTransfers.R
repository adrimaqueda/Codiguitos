# Cargar las librerías necesarias.
# worldfootballR se usa para descargar los datos de traspasos desde Transfermarkt.
# tidyverse es una colección de paquetes para la manipulación y visualización de datos.
library(worldfootballR)
library(tidyverse)

# --- EXTRACCIÓN DE DATOS ---

# Definir el rango de años para el que se quieren obtener los datos.
years <- c(2017:2025)
# Inicializar un tibble (data frame) vacío para almacenar todos los traspasos.
all_transfers_data <- tibble()

# Iterar sobre cada año para descargar los datos de traspasos.
for (year in years) {
  # Pausa de 10 minutos (600 segundos) entre cada petición para no sobrecargar el servidor.
  Sys.sleep(600)

  # Imprimir mensaje de progreso en la consola.
  cat(str_glue("\nEmpezando el año {year}..."))

  # Obtener las URLs de los equipos de La Liga para el año actual.
  team_urls <- tm_league_team_urls(country_name = "Spain", start_year = year)

  cat("\nExtrayendo los traspasos...")
  # Descargar los datos de traspasos para todos los equipos y ventanas de fichajes.
  transfers <- tm_team_transfers(
    team_url = team_urls,
    transfer_window = "all"
  )
  # Añadir una columna con el año para identificar la temporada.
  transfers$year <- year

  cat("\nUniendo los datos...\n\n")
  # Unir los datos del año actual con los datos acumulados.
  all_transfers_data <- bind_rows(all_transfers_data, transfers)
}

# --- LIMPIEZA Y TRANSFORMACIÓN DE DATOS ---

# Filtrar para quedarse solo con traspasos entre equipos de LaLiga.
spainTransfers <- all_transfers_data |
  filter(league == "LaLiga" & league_2 == "LaLiga") |
  # Excluir los registros que son "Fin de cesión" (End of loan) para no contarlos como nuevos traspasos.
  filter(
    str_detect(transfer_notes, "End of loan", negate = TRUE) |
      is.na(transfer_notes)
  )

# Crear un diccionario para normalizar los nombres de los equipos.
# Esto soluciona inconsistencias como "Athletic" vs "Athletic Bilbao".
teamsDict <- unique(c(spainTransfers$team_name, spainTransfers$club_2)) |
  as_tibble() |
  rename(og = value) |
  mutate(
    new = case_when(
      og == "Athletic" ~ "Athletic Bilbao",
      og == "Atlético Madrid" ~ "Atlético de Madrid",
      og == "Barcelona" ~ "FC Barcelona",
      og == "Getafe" ~ "Getafe CF",
      og == "Girona" ~ "Girona FC",
      og == "Levante" ~ "Levante UD",
      og == "RCD Espanyol Barcelona" ~ "Espanyol",
      og == "Real Betis Balompié" ~ "Real Betis",
      og == "Betis" ~ "Real Betis",
      og == "Alavés" ~ "Deportivo Alavés",
      og == "Villarreal" ~ "Villarreal CF",
      og == "Valencia" ~ "Valencia CF",
      TRUE ~ og
    )
  )

# Obtener la lista final de nombres de equipos ya normalizados.
laLigaTeams <- unique(teamsDict$new)

# Aplicar la normalización de nombres al data frame de traspasos.
# Se hace un left_join para reemplazar los nombres originales en la columna 'team_name'.
spainTransfers <- spainTransfers |
  left_join(teamsDict, by = c("team_name" = "og")) |
  select(-team_name) |
  rename(team_name = new) |
  # Se repite el proceso para la columna 'club_2'.
  left_join(teamsDict, by = c("club_2" = "og")) |
  select(-club_2) |
  rename(club_2 = new)

# --- AGREGACIÓN Y CREACIÓN DE LA MATRIZ FINAL ---

# Contar el número de traspasos y cesiones entre cada par de equipos.
transfers <- spainTransfers |
  summarise(count = n(), .by = c("team_name", "is_loan", "club_2")) |
  # Pivotar la tabla para tener columnas separadas para cesiones (loans) y traspasos (transfers).
  pivot_wider(
    names_from = is_loan,
    values_from = count,
    values_fill = 0
  ) |
  # Renombrar columnas para mayor claridad.
  rename(
    loans = `TRUE`,
    transfers = `FALSE`,
    team_1 = team_name,
    team_2 = club_2
  ) |
  # Calcular el total de movimientos (traspasos + cesiones).
  mutate(
    totals = transfers + loans
  )

# Crear una matriz completa con todas las combinaciones posibles de equipos.
transfers_matrix <- expand.grid(
  origen = laLigaTeams,
  destino = laLigaTeams,
  stringsAsFactors = FALSE
) |
  # Unir los datos de traspasos a la matriz completa.
  left_join(transfers, by = join_by(destino == team_1, origen == team_2)) |
  as_tibble() |
  # Filtrar para eliminar las filas donde un equipo se traspasa a sí mismo.
  filter(origen != destino)

# --- EXPORTACIÓN DE DATOS ---

# Guardar la matriz de traspasos en un archivo CSV.
# Los valores NA (equipos sin traspasos entre ellos) se reemplazan por "0".
write_csv(transfers_matrix, "transfers_matrix.csv", na = "0")
