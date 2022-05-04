# Use this script to assemble statistics for:
#   1. raw
#   2. stepwise f0, f1, f2
#   3. intensity features
#
# all extracted from the IDS dataset using PraatMasterScript.praat for further analysis
# Script written by Courtney Hilton & Cody Moser

# libraries ---------------------------------------------------------------

library(tidyverse)
library(here)

# load data ---------------------------------------------------------------

data <- read_csv(here("data", "Praat_MasterData.csv"))
mirrri <- read_csv(here("data", "mir_roughness_rolloff_inharm"))
mirras <- read_csv(here("data", "mir_reconcatenated_attack_summary"))
mirtp <- read_csv(here("data", "mir_tempo_pulseclarity"))
npvi <- read_csv(here("data", "npvi_summary"))
tm <- read_csv(here("data", "tm_summary"))

# Processing --------------------------------------------------------------

data <- data %>%
   group_by(id) %>%
   mutate(
      # Calculate stepwise euclidian travel distance for intensity
      praat_intensitytravel = sqrt((intensity - lag(intensity))^2),
      # Calculate stepwise euclidian travel distance for intensity
      praat_f0travel = sqrt((f0 - lag(f0))^2),
      # Calculate stepwise euclidian travel distance for vowel space
      praat_voweltravel = sqrt((sqrt(f1^2 + f2^2) - lag(sqrt(f1^2 + f2^2)))^2),
      # Change 0 to NA
      across(c(f0,f1,f2, intensity), ~ ifelse(.x == 0, NA, .x)),
      # remove extra bit on ID var
      id = str_sub(id, 1,6)
      )

# set column names for reference
colnames(data) <- c(
  "id",
  "time",
  "praat_f0",
  "praat_f1",
  "praat_f2",
  "praat_intensity",
  "praat_intensity_travel",
  "praat_f0_travel",
  "praat_vowel_travel"
)

# Caclulate summary data --------------------------------------------------

summarydata <- data %>%
  group_by(id) %>%
  summarize(
    praat_f0_mean = mean(praat_f0, na.rm = TRUE),
    praat_f0_median = median(praat_f0, na.rm = TRUE),
    praat_f0_std = sd(praat_f0, na.rm = TRUE),
    praat_f0_min = min(praat_f0, na.rm = TRUE),
    praat_f0_max = max(praat_f0, na.rm = TRUE),
    praat_f0_first_quart = quantile(praat_f0, probs = 0.25, na.rm = TRUE),
    praat_f0_third_quart = quantile(praat_f0, probs = 0.75, na.rm = TRUE),
    praat_f0_IQR = IQR(praat_f0, na.rm = TRUE),
    praat_f1_mean = mean(praat_f1, na.rm = TRUE),
    praat_f1_median = median(praat_f1, na.rm = TRUE),
    praat_f1_std = sd(praat_f1, na.rm = TRUE),
    praat_f1_min = min(praat_f1, na.rm = TRUE),
    praat_f1_max = max(praat_f1, na.rm = TRUE),
    praat_f1_first_quart = quantile(praat_f1, probs = 0.25, na.rm = TRUE),
    praat_f1_third_quart = quantile(praat_f1, probs = 0.75, na.rm = TRUE),
    praat_f1_IQR = IQR(praat_f1, na.rm = TRUE), praat_f2_mean = mean(praat_f2, na.rm = TRUE),
    praat_f2_median = median(praat_f2, na.rm = TRUE),
    praat_f2_std = sd(praat_f2, na.rm = TRUE),
    praat_f2_min = min(praat_f2, na.rm = TRUE),
    praat_f2_max = max(praat_f2, na.rm = TRUE),
    praat_f2_first_quart = quantile(praat_f2, probs = 0.25, na.rm = TRUE),
    praat_f2_third_quart = quantile(praat_f2, probs = 0.75, na.rm = TRUE),
    praat_f2_IQR = IQR(praat_f2, na.rm = TRUE),
    praat_intensity_mean = mean(praat_intensity, na.rm = TRUE),
    praat_intensity_median = median(praat_intensity, na.rm = TRUE),
    praat_intensity_std = sd(praat_intensity, na.rm = TRUE),
    praat_intensity_min = min(praat_intensity, na.rm = TRUE),
    praat_intensity_max = max(praat_intensity, na.rm = TRUE),
    praat_intensity_first_quart = quantile(praat_intensity, probs = 0.25, na.rm = TRUE),
    praat_intensity_third_quart = quantile(praat_intensity, probs = 0.75, na.rm = TRUE),
    praat_intensity_IQR = IQR(praat_intensity, na.rm = TRUE),
    praat_intensitytravel_mean = mean(praat_intensity_travel, na.rm = TRUE),
    praat_intensitytravel_median = median(praat_intensity_travel, na.rm = TRUE),
    praat_intensitytravel_std = sd(praat_intensity_travel, na.rm = TRUE),
    praat_intensitytravel_min = min(praat_intensity_travel, na.rm = TRUE),
    praat_intensitytravel_max = max(praat_intensity_travel, na.rm = TRUE),
    praat_intensitytravel_first_quart = quantile(praat_intensity_travel, probs = 0.25, na.rm = TRUE),
    praat_intensitytravel_third_quart = quantile(praat_intensity_travel, probs = 0.75, na.rm = TRUE),
    praat_intensitytravel_IQR = IQR(praat_intensity_travel, na.rm = TRUE),
    praat_voweltravel_mean = mean(praat_vowel_travel, na.rm = TRUE),
    praat_voweltravel_median = median(praat_vowel_travel, na.rm = TRUE),
    praat_voweltravel_std = sd(praat_vowel_travel, na.rm = TRUE),
    praat_voweltravel_min = min(praat_vowel_travel, na.rm = TRUE),
    praat_voweltravel_max = max(praat_vowel_travel, na.rm = TRUE),
    praat_voweltravel_first_quart = quantile(praat_vowel_travel, probs = 0.25, na.rm = TRUE),
    praat_voweltravel_third_quart = quantile(praat_vowel_travel, probs = 0.75, na.rm = TRUE),
    praat_voweltravel_IQR = IQR(praat_vowel_travel, na.rm = TRUE),
    praat_f0travel_mean = mean(praat_f0_travel, na.rm = TRUE),
    praat_f0travel_median = median(praat_f0_travel, na.rm = TRUE),
    praat_f0travel_std = sd(praat_f0_travel, na.rm = TRUE),
    praat_f0travel_min = min(praat_f0_travel, na.rm = TRUE),
    praat_f0travel_max = max(praat_f0_travel, na.rm = TRUE),
    praat_f0travel_first_quart = quantile(praat_f0_travel, probs = 0.25, na.rm = TRUE),
    praat_f0travel_third_quart = quantile(praat_f0_travel, probs = 0.75, na.rm = TRUE),
    praat_f0travel_IQR = IQR(praat_f0_travel, na.rm = TRUE),
    praat_f0_range = praat_f0_max - praat_f0_min,
    praat_f1_range = praat_f1_max - praat_f1_min,
    praat_f2_range = praat_f2_max - praat_f2_min,
    praat_intensity_range = praat_intensity_max - praat_intensity_min,
    praat_intensitytravel_range = praat_intensitytravel_max - praat_intensitytravel_min,
    praat_voweltravel_range = praat_voweltravel_max - praat_voweltravel_min,
    praat_f0travel_range = praat_f0travel_max - praat_f0travel_min,
    praat_f0travel_rate_median = median(praat_f0_travel / time, na.rm = TRUE),
    praat_f0travel_rate_IQR = IQR(praat_f0_travel / time, na.rm = TRUE),
    praat_voweltravel_rate_median = median(praat_vowel_travel / time, na.rm = TRUE),
    praat_voweltravel_rate_IQR = IQR(praat_vowel_travel / time, na.rm = TRUE),
    praat_intensitytravel_rate_median = median(praat_intensity_travel / time, na.rm = TRUE),
    praat_intensitytravel_rate_IQR = IQR(praat_intensity_travel / time, na.rm = TRUE),
    # sum file length, f0, vowel space, and intensity for gross travel rates
    timesum = sum(time),
    f0sum = sum(praat_f0_travel, na.rm = TRUE),
    vowelsum = sum(praat_vowel_travel, na.rm = TRUE),
    intensitysum = sum(praat_intensity_travel, na.rm = TRUE),
    # calculate gross travel rates
    praat_f0_travel_rate_default = (f0sum / timesum),
    praat_voweltravel_rate_default = (vowelsum / timesum),
    praat_intensitytravel_rate_default = (intensitysum / timesum)
  ) %>% 
   ungroup() %>% 
   # Remove unnecessary variables (minimums and sums)
   select(-c(
      praat_voweltravel_min,
      praat_intensitytravel_min,
      praat_f0travel_min,
      timesum,
      f0sum,
      vowelsum,
      intensitysum
   ))


# Add song info to files --------------------------------------------------

summarydata <- summarydata %>%
  transmute(
    id = id,
    voc_type = substr(id,6,6),
    song = case_when(
      endsWith(id, "A")  ~ 1 ,
      endsWith(id, "B")  ~ 0 ,
      endsWith(id, "C")  ~ 1 ,
      endsWith(id, "D")  ~ 0 ,
      ),
    infdir = case_when(
      endsWith(id, "A")  ~ 1 ,
      endsWith(id, "B")  ~ 1 ,
      endsWith(id, "C")  ~ 0 ,
      endsWith(id, "D")  ~ 0 ,
      ),
    id_site = substr(id,1,3),
    id_person = substr(id,1,5),
    ) %>% 
  merge(summarydata, by = "id")

# Combine summary statistics from Praat with additional files -------------

df_list <- list(summarydata, mirrri, mirras, mirtp, npvi, tm)
summarydata %>% reduce(full_join, by='id')

# Save output -------------------------------------------------------------

write_csv(summarydata, here("results", "praatsummary.csv"))
