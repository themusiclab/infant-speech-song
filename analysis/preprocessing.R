# IDS preprocessing
# Script written by Courtney Hilton
# This script is only provided for transparency and will not run
# as we are unable to provide the raw data due to privary concerns
# our last saved output of this script is provided

# Libraries ---------------------------------------------------------------

library(pacman)
p_load(
  here,
  lingtypology,
  broom,
  scales,
  tidyverse
)

# Load raw data -----------------------------------------------------------

# raw_data <- read_csv(here("data", "ids_stimulusResponses_joined_processed.csv.gz"))
#, col_types = cols(.default = col_character())

# dropping irrelevant columns and rows to reduce memory load
dont_matter <- c("This study is being conducted",
                 "This experiment is being conducted",
                 "In this study", 
                 "In this game",
                 "Correct",
                 "Incorrect",
                 "We have just a few questions",
                 "Let's practice",
                 "infocard-button-response",
                 "Here are all the songs",
                 "mario.mp3", 
                 "play you some synthesized songs",
                 "First, let's practice",
                 "First, we'll play you a calibration tone",
                 "In this section",
                 "Let's practice a second time",
                 "You are now ready to begin the study",
                 "Great work on the practice",
                 "PLEASE NOTE", 
                 "23andMe", 
                 "Place your hands on the keyboard",
                 "feedback") 

# select useful columns
data <- raw_data %>%
  select(user_id, button, button_pressed, correct, correct1, correct_response, image_order1, isMobile, key, key_press, 
         response, responses, rt, stimulus, time_elapsed, trialName, trial_index, trial_type) %>% 
  # paste() creates this list of AND | conditions. grepl finds those cells in the df that contain these "don't matter" strings
  filter(!grepl(paste(dont_matter, collapse = "|"), stimulus)) 

# Integrating old data ----------------------------------------------------

# add trialName info for old data
clean_old_data <- data %>% 
  group_by(user_id) %>% 
  # heuristic to extract pre-trialName data:
  #   1. all rows per subject are NA for trialName
  #   2. there are at least a few rows
  filter(all(is.na(trialName)),
         n() > 4) %>% 
  ungroup() %>% 
  # manually add trialName
  mutate(
    trialName = case_when(
      stimulus == "What is your gender?" ~ "gender",
      trial_type == "survey-text-number" ~ "age",
      stimulus == "Do you live in the United States?" ~ "country",
      grepl("mp3", stimulus) ~ "toWho",
      stimulus == "Have you taken this quiz before?" ~ "takenBefore")
  ) %>% 
  # removing rows we aren't using (e.g., ethnicity, musical engagement etc)
  filter(!is.na(trialName))

# combine old data with new data
data <- data %>% 
  filter(user_id > max(as.numeric(clean_old_data$user_id))) %>% 
  bind_rows(clean_old_data, .)

rm(raw_data, clean_old_data)

# Data cleaning -----------------------------------------------------------

data <- data %>% 
  # joining response and responses (only one cell is ever populated at a time)
  mutate(response = coalesce(responses, response)) %>% 
  select(-responses) %>%
  # dropping some trial types that are irrelevent to analyses
  filter(trialName %in% c("gender", "age", "country", "language", "langOther", "langOtherWhich", "hearingImp", "workspace", "headphone",
                          "takenBefore", "toWho",
                          "education", "musicTime", "musicSkill", "musicPSing",
                          "tradMusic", "race", "latino", "income", "education_other", "parentSchool")) %>% 
  # dropping missing data 
  filter(!is.na(rt), 
         !is.na(trial_type),
         !is.na(time_elapsed)) %>% 
  mutate(
    across(c(rt, button_pressed, button, trial_index, time_elapsed),
           as.numeric),
    isMobile = case_when(
      isMobile == "True" ~ 1,
      isMobile == "False" ~ 0),
    stimulus = case_when(
      grepl("before", stimulus) ~ "donebefore",
      trialName == "gender" ~ "gender",
      trialName == "age" ~ "age",
      trialName == "country" ~ "country",
      trialName == "language" ~ "language",
      trialName == "langOther" ~ "langOther",
      trialName == "langOtherWhich" ~ "langOtherWhich",
      trialName == "hearingImp" ~ "hearingImp",
      trialName == "howquiet" ~ "howquiet",
      trialName == "headphones" ~ "headphones",
      grepl(".mp3", stimulus) ~ gsub(".*audio/|.mp3", "", stimulus),
      TRUE ~ stimulus
    )) %>% 
  mutate(
    response = case_when(
      trialName == "age" ~ str_extract(response, "(?<=:).*") %>% parse_number() %>% as.character(),
      trialName == "country" & str_length(response) > 3 ~ str_extract(response, "(?<=name: ).*(?=\\p{quotation mark})"),
      trialName == "country" & response == "Yes" ~ "United States",
      trialName == "country" & response == "No" ~ "Other (not USA)",
      trialName == "language" ~ str_extract(response, "(?<=name: ).*(?=\\p{quotation mark})"),
      trialName == "langOtherWhich" ~ str_extract(response, "(?<=name: ).*(?=\\p{quotation mark})"),
      TRUE ~ response 
    )
  )

# Preprocessing -----------------------------------------------------------

naive <- data %>%
  # remove duplicates
  group_by(user_id) %>%
  distinct() %>%
  ungroup() %>%
  #  dropping practice stim 
  # filter(!stimulus %in% c("TOR47A", "WEL10C")) %>%
  # coalescing correct and correct1 
  mutate(correct = coalesce(correct, correct1) %>% as.numeric) %>%
  # drop old `correct1`
  select(-correct1) %>%
  # recoding correct as 0/1 instead of False/True
  # mutate(correct = recode(correct, "False" = 0, "True" = 1)) %>%
  # column extracting ABCD from stimuli names 
  # A - infant directed song
  # B - infant directed speech
  # C - adult directed song
  # D - adult directed speech
  # (column `correct` is NA when row is not experimental ie gathers user age, gender etc.)
  group_by(stimulus) %>%
  mutate(voc_type = ifelse(!is.na(correct), substr(stimulus, 6, 6), NA)) %>%
  # binary labeling the voc_types as sung (0/1) and infant-directed (0/1)
  mutate(sung = ifelse(voc_type == "A"| voc_type == "C", 1, 0),
         infdir = ifelse(voc_type == "A" | voc_type == "B", 1, 0)) %>%
  # drop all participants who state they have participated in the experiment before
  group_by(user_id) %>%
  mutate(done = ifelse(stimulus == "donebefore" & response == "Yes", 1, 0),
         done = ifelse(any(done == 1), 1, 0))

# number of participants who have done the experiment before
n_done_before <- naive %>% group_by(user_id) %>% summarise(done = unique(done)) %>% filter(done == 1) %>% nrow
n_started <- n_distinct(naive %>% drop_na(correct) %>% pull(user_id))

naive <- naive %>% 
  # removing those who have done it before
  filter(done == 0) %>%
  select(-done) %>%
  # tagging which trial, per participant, was heard first 
  group_by(user_id) %>%
  mutate(first_trial = ifelse(time_elapsed == min(time_elapsed[!is.na(voc_type) & (!stimulus %in% c("TOR47A", "WEL10C"))]), 1, 0)) # tagging those trials that are first trials

# Turn into tidy wide format ----------------------------------------------

covariates <- naive %>% 
  select(user_id, trialName, response) %>% 
  filter(trialName != "toWho") %>% 
  # "values_fn = first" below needed to get rid of weird duplicates
  pivot_wider(names_from = "trialName", values_from = "response", values_fn = first)

# the full list of language name remappings is very long, so importing from .csv here
name_remappings <- read_csv(here("data", "language-name-conversions.csv"))

covariates <- covariates %>% 
  mutate(
    #Remove extinct and non-verbal languages from the analysis
    language = case_when(
      language == "Abenaki" ~ "", # keeping Abenaki... it's endangered, not extinct
      language == "Ainu" ~ "",
      language == "American Sign" ~ "",
      language == "Avestan" ~ "",
      language == "Ayapathu" ~ "",
      language == "Catawba" ~ "",
      language == "Coptic" ~ "",
      language == "Cornish" ~ "",
      language == "Delaware" ~ "",
      language == "Gothic" ~ "",
      language == "Other" ~ "",
      language == "Pahlavi" ~ "",
      language == "Pakahn" ~ "",
      language == "Pali" ~ "",
      language == "Sûdovian" ~ "",
      language == "S?dovian" ~ "",
      language == "Wyandot" ~ "",
      TRUE ~ as.character(language)
    ),
    # Correct the languages from TML to match Glottolog's classification
    language = recode(
      language,
      !!!setNames(name_remappings$new_label, name_remappings$old_label),
      .default = language
    ),
    # do the same for the 2nd languages
    langOtherWhich = recode(
      langOtherWhich,
      !!!setNames(name_remappings$new_label, name_remappings$old_label),
      .default = langOtherWhich
    )
  )

# adding primary language glottocodes
covariates <- covariates %>%
  ungroup() %>% 
  drop_na(language) %>% 
  summarise(
    language = unique(language)
  ) %>% 
  mutate(
    userglot = gltc.lang(language)
  ) %>% 
  right_join(., covariates, by = "language")

# adding secondary language glottocodes
covariates <- covariates %>%
  ungroup() %>% 
  drop_na(langOtherWhich) %>% 
  summarise(
    langOtherWhich = unique(langOtherWhich)
  ) %>% 
  mutate(
    userglot2 = gltc.lang(langOtherWhich)
  ) %>% 
  right_join(., covariates, by = "langOtherWhich")

trials <- naive %>% 
  select(user_id, trialName, stimulus, correct_response, correct, 
         rt, trial_index, voc_type, sung, infdir, first_trial, time_elapsed) %>% 
  filter(trialName == "toWho") %>% 
  mutate(fieldsite = str_sub(stimulus,1,3)) %>% 
  group_by(user_id) %>% 
  arrange(time_elapsed, .by_group = TRUE) %>% 
  mutate(trial_num = row_number())

data_preprocessed <- trials %>% 
  left_join(., covariates, by = "user_id") %>% 
  select(-trialName) %>% 
  # removing people without trial data
  filter(!is.na(voc_type))

# Add confound coding -----------------------------------------------------

# # mapping between anonymised tracks and actual track info
# mapping <- read_csv(here("data", "test_mapping.csv")) %>% 
#   mutate(value = str_remove(value, ".wav"))
# 
# # load coded confounds and bind with mapping
# confounds <- read_csv(here("data", "confounds.csv")) %>% 
#   mutate(across(c(infant, adult, english), ~ ifelse(is.na(.x), 0, .x))) %>% 
#   left_join(., mapping, by = c("voc" = "test_number")) %>% 
#   select(value, voc, infant, adult, english)

confounds <- read_csv(here("data", "simuli-confounds.csv"))

data_preprocessed <- data_preprocessed %>%
  mutate(id = str_sub(stimulus, start = 1, end = 5),
         inf_guess = case_when(
           correct == 1 & infdir == 1 ~ 1,
           correct == 0 & infdir == 0 ~ 1,
           TRUE ~ 0
         )) %>% 
  left_join(., 
            confounds,
            by = "stimulus") %>% 
  select(-voc)

# Fixing dodgy stimuli ----------------------------------------------------

data_preprocessed <- data_preprocessed %>% 
  mutate(stimulus = stimulus %>% as_factor) %>% 
  ##### during revision we identified some problematic vocalizations:
  # 1. the below vocalizations were identified as being problematic.
  # e.g., the participant notes "oh, that was actually a children's song" after supposedly singing an adult song.
  # These vocalizations are dropped entirely
  filter(!stimulus %in% c("TUR02C", "TUR04C", "WEL26C", "WEL31C", "WEL34C", "WEL49C")) %>% 
  ungroup() %>% 
  # mutate(across(.cols = c(rt, correct, user_id), .fns = as.numeric))
  mutate(across(c(user_id,correct,rt,trial_index,sung, infdir,age,inf_guess,
                  infant,adult,english, first_trial, trial_num),
                .fns = as.numeric))

# Fixing Language Families ------------------------------------------------

IDSvars <- read.csv(here("data", "fieldsite-metadata.csv")) %>%
  select(fieldsite:audioglot, Language.Family) %>%
  rename(audiofam = Language.Family)

IDSfams <- read.csv(here("data", "languages-families.csv"), fileEncoding = "UTF-8-BOM")

IDSprox <- read.csv(here("data", "language-proximity.csv")) %>%
  pivot_longer(cols = -glottocode, names_to = "audioglot", values_to = "distance") %>%
  mutate(distance = 1 - distance) # transforming so that distance 1 = a unrelated language

# Data from the "Who's Listening" TML game
# pre-processed trial-level data from analysis/statistical/preprocessing.R
data_preprocessed <- data_preprocessed %>%
  left_join(., IDSvars, by = "fieldsite") %>%
  left_join(., IDSfams, by = c("language" = "Language")) %>%
  left_join(., IDSfams %>% rename(Family2 = Family), by = c("langOtherWhich" = "Language")) %>% 
  mutate(
    audiofam = case_when(
      audiofam == "Indo-European Creole" ~ "Indo-European",
      audiofam == "Uralic and Indo-European" ~ "Uralic",
      TRUE ~ audiofam)
  )

extra_langfam_mappings <- read_csv(here("data","extra_langfam_mappings.csv"))

# adjust langfams for primary languages
for (i in 1:nrow(extra_langfam_mappings)) {
  data_preprocessed$Family <- ifelse(
    data_preprocessed$language == extra_langfam_mappings$search_term[[i]],
    extra_langfam_mappings$langfam[[i]],
    data_preprocessed$Family
  )
}

# adjust langfams for secondary languages
for (i in 1:nrow(extra_langfam_mappings)) {
  data_preprocessed$Family2 <- ifelse(
    data_preprocessed$langOtherWhich == extra_langfam_mappings$search_term[[i]],
    extra_langfam_mappings$langfam[[i]],
    data_preprocessed$Family2
  )
}

# Qualtrics ---------------------------------------------------------------

qualtrics <- read_csv(here("data", "processed_qualtrics.csv")) %>%
  drop_na(correct, infdir, inf_guess) %>% 
  left_join(., IDSvars %>% select(fieldsite, audioglot)) %>% 
  mutate(language = case_when(
    language == "Englkish" ~ "English",
    language == "E" ~ "English",
    language == "Siswati" ~ "Swati",
    language == "Setswana" ~ "Tswana",
    language == "Arabic" ~ "Standard Arabic",
    TRUE ~ language
  ),
  adult = 0, infant = 0)

qualtrics_langs <- tibble(
  language = unique(qualtrics$language)
  ) %>% 
  mutate(userglot = gltc.lang(language))

qualtrics_audiolangs <- tibble(
  audioglot = unique(qualtrics$audioglot)
) %>% 
  mutate(audiolang = lang.gltc(audioglot) %>% as.character())

qualtrics <- qualtrics %>% 
  left_join(., qualtrics_langs, by = "language") %>% 
  left_join(., qualtrics_audiolangs, by = "audioglot")

# qualtrics + tml mathcing stim scores
qualtrics_test <- inner_join(qualtrics %>% group_by(stimulus) %>%
                               summarise(qual_avg = mean(correct, na.rm = T)),
                             data_preprocessed %>% group_by(stimulus) %>%
                               summarise(tml_avg = mean(correct)), by = "stimulus")

user_info <- list()
user_info$qualtrics_validation <- cor.test(qualtrics_test$tml_avg, qualtrics_test$qual_avg) %>% tidy()

qualtrics_summary <- qualtrics %>%
  group_by(user_id, gender, age) %>%
  summarise(user_id = unique(user_id), .groups = "drop")

user_info$qualtrics$n <- nrow(qualtrics_summary)
user_info$qualtrics$n_stim <- n_distinct(qualtrics$stimulus)
user_info$qualtrics$gender <- qualtrics_summary %>%
  count(gender) %>%
  pivot_wider(names_from = gender, values_from = n)

user_info$qualtrics$age <- qualtrics_summary %>%
  summarise(avg = mean(age))

data_preprocessed <- data_preprocessed %>%
  bind_rows(., qualtrics)

# Extract user info -------------------------------------------------------

users <- read_csv(here("data", "ids_users.csv"))

user_info$started <- n_started
user_info$completed <- users %>% filter(completed == TRUE) %>% nrow
user_info$first <- users %>% slice_head(n = 1) %>% pull(created_at)
user_info$last <- users %>% slice_tail(n = 1) %>% pull(created_at)
user_info$n_done <- n_done_before

# EXCLUSIONS

# Exclude participants younger than 12
user_info$age12_or_younger <- data_preprocessed %>% filter(age < 12) %>% pull(user_id) %>% n_distinct
# Exclude participants with reported hearing impairments
user_info$hearing <- data_preprocessed %>% filter(hearingImp == "Yes") %>% pull(user_id) %>% n_distinct
user_info$conf_inf <- data_preprocessed %>% filter(infant == 1) %>% pull(stimulus) %>% n_distinct
user_info$conf_adult <- data_preprocessed %>% filter(adult == 1) %>% pull(stimulus) %>% n_distinct
user_info$conf_total <- data_preprocessed %>% filter(infant == 1 | adult == 1) %>% pull(stimulus) %>% n_distinct
user_info$rt_before5 <- data_preprocessed %>% filter(rt < 5000) %>% nrow
user_info$rt_before5_p <- user_info$rt_before5 / (data_preprocessed %>% nrow)
user_info$rt <- data_preprocessed %>% filter(!between(rt, 500, 5000)) %>% nrow
user_info$rt_p <- user_info$rt / (data_preprocessed %>% nrow)
user_info$total_trials <- nrow(data_preprocessed)
user_info$same_lang <- data_preprocessed %>% filter(audioglot == userglot) %>% nrow
user_info$same_lang_p <- (user_info$same_lang / (data_preprocessed %>% nrow))
n_recording <- n_distinct(data_preprocessed$stimulus)
data_preprocessed <- data_preprocessed %>% add_count(user_id) %>% mutate(complete = ifelse(n == 18, 1, 0)) %>% select(-n)

save(user_info, file = here("results", "user_info.RData"))

# Final Saving ------------------------------------------------------------

data_no_exclude <- data_preprocessed

# with confounds
data_preprocessed <- data_preprocessed %>%
  filter(
    between(rt, 500, 5000),
    age > 12,
    hearingImp != "Yes"
  ) %>%
  left_join(., IDSprox, by = c("userglot" = "glottocode", "audioglot" = "audioglot"))

# Save --------------------------------------------------------------------

write_csv(data_preprocessed, here("results", "listener-experiment.csv"))
write_csv(data_no_exclude, here("results", "listener-experiment_no-exclusions.csv"))
