library(tidyverse)
library(rvest)

##

rounds <- c("GS", "R16", "QF", "SF","F")


##full matches
champions_matches_raw <- read_html("https://kassiesa.net/uefa/clubs/search/index.php?search=CL") %>% 
  html_element(".atable") %>% 
  html_table(header = T) %>% 
  rename(
    team_1 = 4,
    team_2 = 6,
    team_1_country = 5,
    team_2_country = 7,
    result_1 = 8,
    result_2 = 9,
    result_3 = 10
  ) %>% 
  select(season, cup, round, team_1, team_2) %>%
  filter(cup == "CL") %>% 
  select(!cup)


## a partir de 2003/04 hay ronda de octavos https://es.wikipedia.org/wiki/Liga_de_Campeones_de_la_UEFA_2003-04
champions_matches_clean <- champions_matches_raw %>%
  mutate(year = as.double(str_sub(season,0,4))) %>% 
  filter(year >= 2003) %>% 
  mutate(
    round = case_when(
      round == "R2" ~ "R16",
      T ~ round
    )
  ) %>% 
  filter(round %in% rounds) %>% 
  select(!year) %>% 
  mutate(year = str_sub(season, 0, 4)) %>% 
  arrange(year)

##long data so we can analyze it
long_data <- champions_matches_clean %>% 
  pivot_longer(!c(season, round), names_to = "x", values_to = "team") %>% 
  select(!x) %>% 
  filter(team != "")

write_csv(long_data, "Champions League rounds/long_data.csv")
