# New LASSO analysis
# by Courtney Hilton, June, 2021

# libraries ---------------------------------------------------------------

library(pacman)
p_load(
  here,
  vip,
  pROC,
  scales,
  tidymodels,
  ggtext,
  tidyverse
)

# !! this loads in the custom LASSO functions that are used in the analyses below
# see the function definitions for full details
source(here("analysis", "lasso_functions.R"))

# load data ---------------------------------------------------------

# fieldsite info
fieldsites <- read_csv(here("data", "fieldsite-list.csv"))

# load preprocessed acoustic data
load_audio_data(read_csv(here("results", "acoustics-Winsorized.csv")))

# Run LASSO models --------------------------------------------------------

set.seed(02141)

# 1. cross-validating over fieldsites

song_LASSO <- run_lasso(
  acoustic_demean %>% filter(type %in% c("infant_song", "adult_song")), # data
  "binomial", # model engine type
  id_site) # cross-validating over

speech_LASSO <- run_lasso(
  acoustic_demean %>% filter(type %in% c("infant_speech", "adult_speech")),
  "binomial",  
  id_site)

# 2. cross-validating over language families

song_LASSO_langfam <- run_lasso(
  acoustic_demean %>% filter(type %in% c("infant_song", "adult_song")),
  "binomial",
  langfam)

speech_LASSO_langfam <- run_lasso(
  acoustic_demean %>% filter(type %in% c("infant_speech", "adult_speech")),
  "binomial", 
  langfam)

# 3. cross-validating over world regions

song_LASSO_region <- run_lasso(
  acoustic_demean %>% filter(type %in% c("infant_song", "adult_song")),
  "binomial", 
  region)

speech_LASSO_region <- run_lasso(
  acoustic_demean %>% filter(type %in% c("infant_speech", "adult_speech")),
  "binomial", 
  region)

# Saving ------------------------------------------------------------------

# save LASSO info and diagnostics
save(speech_LASSO, song_LASSO,
     speech_LASSO_langfam, song_LASSO_langfam,
     speech_LASSO_region, song_LASSO_region,
     file = here("results", "lasso_results.RData"))

# Predictive LASSO models -------------------------------------------------

trial_data <- read_csv(here("results", "listener-experiment.csv.gz"),
                       col_types = cols(.default = "c")) %>%
  mutate(across(c(user_id,duration,correct,rt,trial_index,sung, infdir,age,inf_guess,infant,adult,english, first_trial, trial_num),
                as.numeric)) %>%
  # removing confounded stimuli
  filter(infant == 0 & adult == 0) %>%
  select(-c(infant, adult))

song_mod <- run_lasso2(c("A", "C"))
speech_mod <- run_lasso2(c("B", "D"))

# Saving ------------------------------------------------------------------

save(song_mod, speech_mod, file = here("results", "human_lasso.RData"))

# Replicate results on raw audio ------------------------------------------

load_audio_data(read_csv(here("results", "acoustics-Winsorized-withRawAudio.csv")))

song_LASSO_raw <- run_lasso(
  acoustic_demean %>% filter(type %in% c("infant_song", "adult_song")),
  "binomial",
  id_site)

speech_LASSO_raw <- run_lasso(
  acoustic_demean %>% filter(type %in% c("infant_speech", "adult_speech")),
  "binomial",
  id_site)

save(song_LASSO_raw, speech_LASSO_raw, file = here("results", "lasso_results-rawAudio.RData"))
