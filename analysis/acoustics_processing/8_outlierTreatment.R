# Use this script to identify and correct outliers in the IDS data in two ways: 
# 1. Winsorization (using the 5% upper and lower tails of the data as cutoffs) 
# 2. Mean-imputation (using z-scores > |5|)
# Written by Courtney Hilton & Cody Moser

# libraries ---------------------------------------------------------------

library(pacman)
p_load(DescTools,
       here,
       tidyverse)

# load data ---------------------------------------------------------------

IDS <- read_csv(here("data", "acoustics-editedAudio.csv")) %>% 
  # Set problem variables as numeric
  mutate(across(-c(id, id_site), as.numeric),
         id_person = paste0(id_site, id_person),
         id_person = factor(id_person)) 

IDS_unedited <- read_csv(here("data", "acoustics-rawAudio.csv")) %>% 
  # Set problem variables as numeric
  mutate(across(-c(id, id_site), as.numeric),
         id_person = paste0(id_site, id_person),
         id_person = factor(id_person)) 

voc_info <- read_csv(here("data", "stimuli-rawMetadata.csv")) %>% 
  select(6,11) %>% 
  rename(
    "id" = 1,
    "voc_gender" = 2,
  )

# Outlier treatment functions ---------------------------------------------

winsorize <- function(data) {
  data %>% 
    mutate(across(matches("(praat_)|(mir_)|(tm_)|(npvi_)"), ~ Winsorize(.x, na.rm = TRUE)))
}

mean_impute <- function(data) {
  data %>% 
    # add vocalist gender info
    left_join(., voc_info, by = "id") %>% 
    group_by(id_site, voc_gender, infantdir, song) %>%
    # Impute mean by song type, site, and gender, for when |z-score| > 5 
    mutate(across(-c(1:6), ~ ifelse(abs(scale(.x, center = TRUE, scale = TRUE)) > 5,
                                    mean(.x, na.rm = TRUE),
                                    .x))) %>% 
    ungroup() %>% 
    select(-voc_gender) %>% 
    mutate(across(c(7:105), ~ as.numeric(.x))) # fixing a weird column type issue
}

# Treat outliers ----------------------------------------------------------

# for edited data
IDS_winsor <- winsorize(IDS)
IDS_mean_impute <- mean_impute(IDS)

# for unedited data
IDS_winsor_unedited <- winsorize(IDS_unedited)
IDS_mean_impute_unedited <- mean_impute(IDS_unedited)

# Save outputs ------------------------------------------------------------

# Write CSVs
write_csv(IDS_mean_impute, here("results", "acoustics-meanImpute.csv"))
write_csv(IDS_winsor, here("results", "acoustics-Winsorized.csv"))
write_csv(IDS_mean_impute_unedited, here("results", "acoustics-meanImpute-unEdited.csv"))
write_csv(IDS_winsor_unedited, here("results", "acoustics-Winsorized-unEdited.csv"))
