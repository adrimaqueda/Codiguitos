library(worldfootballR)
library(tidyverse)

## GET THE DATA ----

matches <- fb_match_urls(country = "ESP", gender = "M", season_end_year = 2024, tier="1st")

# Define a function to fetch match information
fetch_match_info <- function(match_url) {
  matchInfo <- fb_match_lineups(match_url = match_url)
  print(paste0(i, "/", length(matches)))
  return(matchInfo)
}

# Use map_dfr to iterate over the matches and bind the rows
i <- 0
fullDataset <- map_dfr(matches, function(match) {
  i <<- i + 1
  fetch_match_info(match)
})

## CLEAN THE DATA ----

cleanedData <- fullDataset |> 
  transmute(Matchday, Team, Player_Name, Player_Num, Starting, Pos, Min, 
            Starting_Minute = if_else(Starting == "Pitch", 0, 90 - Min)
            ) |> 
  group_by(Team) |> 
  mutate(jornada = cumsum(!duplicated(Matchday))) |> 
  ungroup()

chartData <- cleanedData |> 
  drop_na() |> 
  select(Team, Player_Name, Min, Starting_Minute, jornada)


write_csv(chartData, "heatMap.csv")

## STABLE CALC ----

# total played minutes
totalMinutes <- 11 * 90 * max(cleanedData$jornada)

# team list
teams <- distinct(cleanedData, Team)

# weekly STABLE value

stableWeeklyData <- tibble()

for (i in seq(2, max(cleanedData$jornada), 1)) {
  
  for (team in teams$Team) {
    
    stableValue <- cleanedData |> 
      filter(Team == team & jornada <= i) |> 
      select(Player_Name, Min, jornada) |> 
      pivot_wider(names_from = Player_Name, values_from = Min) |> 
      pivot_longer(!jornada, names_to = "player", values_to = "minutes") |> 
      mutate(minutes = if_else(is.na(minutes), 0, minutes)) |> 
      group_by(player) |> 
      mutate(diference = minutes - lag(minutes)) |> 
      ungroup() |> 
      summarise( stable = 100 - sum(abs(diference), na.rm = TRUE ) / totalMinutes / 2 * 100) |> 
      mutate(team = team, jornada = i)
    
    stableWeeklyData <- stableWeeklyData |> bind_rows(stableValue)
    
  }
  
}

write_csv(stableWeeklyData, "stablePuntuation.csv")
