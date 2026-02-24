# ============================================================
# 02_analysis.R
# Purpose: Combine processed Divvy datasets (2019 & 2020),
#          clean for analysis (outliers), compute KPIs,
#          and generate plots + export tables.
# Inputs : Processed_data/divvy_2019_processed.csv
#          Processed_data/divvy_2020_processed.csv
# Outputs: Outputs/kpi_by_usertype.csv
#          Outputs/rides_by_day_of_week.csv
#          Outputs/avg_ride_length_by_day_of_week.csv
#          Outputs/rides_by_hour.csv
#          Outputs/plots/*.png
# ============================================================

# --- Libraries ---
library(tidyverse)
library(lubridate)
library(janitor)
library(scales)

# --- Import processed data ---
divvy_2019 <- read_csv("Processed_data/divvy_2019_processed.csv")
divvy_2020 <- read_csv("Processed_data/divvy_2020_processed.csv")

# --- Combine ---
divvy_all <- bind_rows(divvy_2019, divvy_2020)

# --- Quick sanity checks ---
glimpse(divvy_all)
summary(divvy_all$ride_length)
count(divvy_all, year)
count(divvy_all, usertype)

# --- Analysis cleaning rules (edit thresholds to match your story) ---
# Common case-study rule: remove <=0 and very long rides (e.g., > 12 hours)
divvy_analysis <- divvy_all %>%
  filter(!is.na(ride_length)) %>%
  filter(ride_length > 0) %>%
  filter(ride_length <= 720)

# --- KPI: overall summary by usertype ---
kpi_by_usertype <- divvy_analysis %>%
  group_by(usertype) %>%
  summarise(
    rides = n(),
    avg_ride_mins = mean(ride_length, na.rm = TRUE),
    median_ride_mins = median(ride_length, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(rides))

kpi_by_usertype
# --- Ride Volume Ratio (Member vs Casual) ---
ride_share <- divvy_analysis %>%
  count(usertype) %>%
  mutate(
    total = sum(n),
    share = n / total
  )

ride_share
# --- Rides by day_of_week (count + share) ---
rides_by_dow <- divvy_analysis %>%
  count(usertype, day_of_week) %>%
  group_by(usertype) %>%
  mutate(share = n / sum(n)) %>%
  ungroup()

rides_by_dow

# --- Average ride length by day_of_week ---
avglen_by_dow <- divvy_analysis %>%
  group_by(usertype, day_of_week) %>%
  summarise(
    avg_ride_mins = mean(ride_length, na.rm = TRUE),
    median_ride_mins = median(ride_length, na.rm = TRUE),
    .groups = "drop"
  )

avglen_by_dow

# --- Rides by hour of day (share) ---
rides_by_hour <- divvy_analysis %>%
  mutate(hour = hour(started_at)) %>%
  count(usertype, hour) %>%
  group_by(usertype) %>%
  mutate(share = n / sum(n)) %>%
  ungroup()

rides_by_hour

# --- Plot 1: Number of rides by day_of_week ---
p1 <- ggplot(rides_by_dow, aes(x = day_of_week, y = n, color = usertype, group = usertype)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    x = NULL,
    y = "Rides",
    color = "User type"
  ) +
  theme_minimal()

p1

# --- Plot 2: Average ride length by day_of_week ---
p2 <- ggplot(avglen_by_dow, aes(x = day_of_week, y = avg_ride_mins, color = usertype, group = usertype)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    x = NULL,
    y = "Average minutes",
    color = "User type"
  ) +
  theme_minimal()

p2

# --- Plot 3: Rides by hour of day (share) ---
p3 <- ggplot(rides_by_hour, aes(x = hour, y = share, color = usertype)) +
  geom_line(linewidth = 1) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    x = "Hour",
    y = "Share of rides",
    color = "User type"
  ) +
  theme_minimal()

p3



# --- Create output folders ---
dir.create("Outputs", showWarnings = FALSE, recursive = TRUE)
dir.create("Outputs/plots", showWarnings = FALSE, recursive = TRUE)

# --- Export tables ---
write_csv(kpi_by_usertype, "Outputs/kpi_by_usertype.csv")
write_csv(rides_by_dow, "Outputs/rides_by_day_of_week.csv")
write_csv(avglen_by_dow, "Outputs/avg_ride_length_by_day_of_week.csv")
write_csv(rides_by_hour, "Outputs/rides_by_hour.csv")

# --- Save plots ---
ggsave("Outputs/plots/plot_rides_by_dow.png", p1, width = 9, height = 5, dpi = 300)
ggsave("Outputs/plots/plot_avglen_by_dow.png", p2, width = 9, height = 5, dpi = 300)
ggsave("Outputs/plots/plot_rides_by_hour_share.png", p3, width = 9, height = 5, dpi = 300)
