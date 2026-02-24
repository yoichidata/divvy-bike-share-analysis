# ============================================================
# 01_data_preparation.R
# Purpose: Import raw Divvy trip data (2019 & 2020),
#          standardize schema, and create analysis-ready features.
# Outputs: Processed_data/divvy_2019_processed.csv
#          Processed_data/divvy_2020_processed.csv
# ============================================================

# --- Libraries ---
library(tidyverse)
library(lubridate)
library(janitor)
# --- Import ---
divvy_2019_raw <- read_csv("Raw_data/Divvy_Trips_2019_Q1.csv")
divvy_2020_raw <- read_csv("Raw_data/Divvy_Trips_2020_Q1.csv")
# --- Standardize + Feature engineering ---
divvy_2019 <-divvy_2019_raw %>% 
  transmute(
    year = 2019,
    started_at = ymd_hms(start_time),
    ended_at = ymd_hms(end_time),
    usertype = case_when(
      usertype == "Subscriber" ~"member",
      usertype == "Customer" ~ "casual",
      TRUE ~ usertype
    )
  ) %>% 
  mutate(
    ride_length = as.numeric(difftime(ended_at,started_at,units = "mins")),
    day_of_week = wday(started_at, label = TRUE, abbr = FALSE, week_start = 7),
    day_type = if_else(day_of_week %in% c("Sunday", "Saturday"), "Weekend", "Weekday")
  ) %>% 
  relocate(ride_length, .after = ended_at) %>%
  relocate(day_of_week, .after = ride_length) %>%
  relocate(day_type, .after = day_of_week)

divvy_2020 <- divvy_2020_raw %>% 
  transmute(
    year = 2020,
    started_at = ymd_hms(started_at),
    ended_at = ymd_hms(ended_at),
    usertype = member_casual
  ) %>% 
  mutate(
    ride_length = as.numeric(difftime(ended_at, started_at,units = "mins")),
    day_of_week = wday(started_at, label = TRUE, abbr = FALSE, week_start = 7),
    day_type = if_else(day_of_week %in% c("Sunday", "Saturday"),"Weekend","Weekday")
    ) %>% 
  relocate(ride_length, .after = ended_at) %>% 
  relocate(day_of_week, .after = ride_length) %>% 
  relocate(day_type, .after = day_of_week)
# --- Ensure output directly exists ---
dir.create("Processed_data",showWarnings = FALSE, recursive = TRUE)
# --- Export ---
write_csv(divvy_2019, "Processed_data/divvy_2019_processed.csv")
write_csv(divvy_2020, "Processed_data/divvy_2020_processed.csv")
# --- Quick checks ---
glimpse(divvy_2019)
glimpse(divvy_2020)