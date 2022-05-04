

test <- trial_data %>% 
  filter(stimulus %in% extract_complete_ids(trial_data)) %>% 
  pivot_longer(names_to = "lang_type", values_to = "lang_name", cols = c("language", "langOtherWhich")) %>%
  group_by(id, sung = ifelse(sung == 1, "song", "speech"), lang_name, lang_type, fieldsite, region) %>% 
  summarise(hit = sum(correct == 1 & infdir == 1),
            miss = sum(correct == 0 & infdir == 1),
            false_alarm = sum(correct == 0 & infdir == 0),
            correct_reject = sum(correct == 1 & infdir == 0)) %>%
  filter(
    # somewhat arbitrarily choosing a minimum of 5 signal and noise trials for these estimates (roughly same result with other values)
    (hit + miss > 5) & (false_alarm + correct_reject > 5)
  ) %>% 
  # Compute d-prime + confidence intervals for each voc typ
  mutate(
    # computing rate metrics
    hr = (hit + 0.5) / (hit + miss + 1),
    far = (false_alarm + 0.5)/ (false_alarm + correct_reject + 1)
  ) %>% 
  ungroup() %>% 
  group_by(sung, id, lang_name, lang_type, fieldsite, region) %>% 
  summarise(across(everything(), ~ mean(.x))) %>% 
  mutate(
    phi_hr = 1/sqrt(2*pi)*exp((-1/2)*qnorm(hr)^2),
    phi_far = 1/sqrt(2*pi)*exp((-1/2)*qnorm(far)^2),
    d_prime = qnorm(hr) - qnorm(far),
    c = -(qnorm(hr) + qnorm(far))/2
  )


mod <- lmer(d_prime ~ lang_type + sung + (1|lang_name) + (0 + sung|region/fieldsite), test)
mod %>% tidy()

linearHypothesis(mod, "first_lang1 - first_lang0 = 0")



