

load_audio_data <- function(data) {
  acoustic <<- data %>% 
    rename(
      id_recording = id,
      infdir = infantdir
    ) %>% 
    mutate(
      id_person = paste0(id_site, id_person),
      type = paste(ifelse(infdir == 1, 'infant', 'adult'),
                   ifelse(song == 1, 'song', 'speech'),
                   sep = "_")
    ) %>% 
    relocate(type, .after = song) %>% 
    select(-ids) %>% 
    # keep only voices with all 4 vocalization types
    group_by(id_person) %>% filter(n() == 4) %>% ungroup() %>%
    select(id_person, id_recording, id_site, type,
           !matches("(mean)|(std)|(quart)|(_1q)|(_3q)|(range)|(dist)|(max)|(min)|(num_events)|(default)|(travel)"),
           praat_voweltravel_median, praat_voweltravel_IQR, praat_voweltravel_rate_median, praat_voweltravel_rate_IQR,
           -infdir) %>%
    drop_na() %>% 
    # log-transform skewed variables
    mutate(across(matches("(praat_voweltravel_rate_.*)|(mir_pulseclarity)|(mir_roughness_.*)"), ~ log(.x + 1))) %>% 
    mutate(across(matches("(mir_roughness_.*)"), ~ log(.x))) %>% 
    rename_with(~ paste0(.x, "_log"), matches("(mir_roughness_.*)|(praat_voweltravel_rate_.*)|(mir_pulseclarity)")) %>% 
    # add in fieldsite info
    left_join(., fieldsites %>% select(id_site = fieldsite, region, langfam), by = c("id_site"))
  
  # Demean within voices
  acoustic_demean <<- acoustic %>% 
    group_by(id_person, song) %>% 
    mutate(across(matches("(praat_)|(mir_)|(tm_)|(npvi_)"), ~ .x - mean(.x))) %>%
    ungroup() %>% 
    select(-song)
}

# function does LASSO with cross-validation using multinomial log-loss as evaluation metric to tune model
# data_x: data to use
# mod_type: 'binomial' or 'multinomial'
# cv_variable: what to do cross-validation over (e.g., fieldsites)
# 
# function returns:
# 1. lasso_grid: cross-validation data
# 2. model_perf_plot: plots of model tuning of lambda
# 3. var_import_data: variable importance of final fitted model
# 4. var_import_plot: diagnostic plot of variable importance
# 5. selected_features: selected features
# 6. lasso_predictions: post-validated model predictions
# 7. mod_auc: AUC scores for each fieldsite + average overall
# 8. mod_acc: accuracy scores for each fieldsite + average overall
run_lasso <- function(data_x, mod_type, cv_variable) {
  # initializing output list
  output <- list()
  
  # Preprocessing recipe
  feature_recipe <- recipe(type ~ ., data = data_x) %>%
    update_role(c(id_person, id_recording, id_site, region, langfam), new_role = "ID") %>% 
    step_string2factor(type, skip = TRUE) %>% 
    step_zv(all_numeric(), -all_outcomes()) %>% 
    step_normalize(all_numeric(), -all_outcomes())
  
  # Add to workflow
  wf <- workflow() %>% 
    add_recipe(feature_recipe)
  
  # Specify LASSO model
  if (mod_type == "multinomial") {
    lasso_spec <- multinom_reg(mode = "classification", penalty = tune(), mixture = 1) %>%
      set_engine("glmnet", grouped = FALSE)
  } else {
    lasso_spec <- logistic_reg(mode = "classification", penalty = tune(), mixture = 1) %>%
      set_engine("glmnet", grouped = FALSE)
  }
  
  doParallel::registerDoParallel()
  
  lasso_grid <- tune_grid(
    wf %>% add_model(lasso_spec),
    # Leave-one out CV over id_sites
    resamples = group_vfold_cv(data_x, group = {{cv_variable}}),
    grid = grid_regular(penalty(), levels = 100),
    metrics = metric_set(accuracy, mn_log_loss)
  )
  
  output$lasso_grid <- lasso_grid
  
  # Visualize model performance over grid of lambda values
  output$model_perf_plot <- lasso_grid %>%
    collect_metrics() %>%
    ggplot(aes(penalty, mean, color = .metric)) +
    geom_errorbar(aes(ymin = mean - std_err, ymax = mean + std_err), alpha = 0.5) +
    geom_line(size = 1.5) +
    facet_wrap(~.metric, scales = "free", nrow = 3) +
    scale_x_log10(labels = comma) +
    geom_vline(
      xintercept = select_best(lasso_grid, metric = "mn_log_loss") %>% pull(penalty), 
      linetype = "dashed", color = "red", alpha = .7
    ) +
    theme(legend.position = "none") +
    theme_bw()
  
  # final lasso with selected lambda
  final_lasso <- finalize_workflow(
    wf %>% add_model(lasso_spec),
    # Using Mean Log-loss as metric to be consistent with the standard cv.glmnet metric
    # (Otherwise known as multinomial deviance)
    select_best(lasso_grid, metric = "mn_log_loss")
  )
  
  lasso_fit <- final_lasso %>% 
    fit(data_x)
  
  # Computing variable importance (using absolute model coefficients)
  output$var_import_data <- lasso_fit %>%
    pull_workflow_fit() %>%
    vi(lambda = select_best(lasso_grid, metric = "mn_log_loss") %>% pull(penalty)) %>%
    mutate(
      Importance = abs(Importance),
      Variable = fct_reorder(Variable, Importance)
    )
  
  # visualize variable importance
  output$var_import_plot <- lasso_fit %>%
    pull_workflow_fit() %>%
    vi(lambda = select_best(lasso_grid, metric = "mn_log_loss") %>% pull(penalty)) %>%
    mutate(
      Importance = abs(Importance),
      Variable = fct_reorder(Variable, Importance)
    ) %>%
    ggplot(aes(x = Importance, y = Variable, fill = Sign)) +
    geom_col() +
    scale_x_continuous(expand = c(0, 0)) +
    labs(y = NULL) + 
    theme_bw()
  
  # Coefficients (selected features)
  output$selected_features <- lasso_fit %>% 
    pull_workflow_fit() %>% 
    tidy() %>% 
    filter(estimate != 0)
  
  # Extracting post-validated model predictions
  output$lasso_predictions <- lasso_fit %>%
    predict(new_data = data_x, type = "prob") %>%
    rowwise() %>%
    mutate(prediction = which.max(c_across(everything())),
           prediction = colnames(.)[prediction] %>% str_remove(".pred_")) %>%
    bind_cols(id_recording = data_x$id_recording, id_site = data_x$id_site,
              id_person = data_x$id_person, region = data_x$region,
              langfam = data_x$langfam, ., actual_type = data_x$type)
  
  # computing AUC at the level of the cross-validation variable (e.g., fieldsite, language family, or world region)
  output$mod_auc$sites <- output$lasso_predictions %>% 
    rename(inf_prob = contains("infant")) %>% 
    ungroup() %>% 
    group_by({{cv_variable}}) %>% 
    summarise(roc = list(roc(actual_type, inf_prob, percent=TRUE, ci=TRUE, quiet = TRUE)$ci %>% as.numeric)) %>%
    rowwise() %>% 
    summarise(
      {{cv_variable}} := {{cv_variable}},
      auc = roc[[2]],
      conf.low = roc[[1]],
      conf.high = roc[[3]],
    )
  
  # computing average across cross-validation variable
  output$mod_auc$avg <- output$mod_auc$sites %>% 
    ungroup() %>% 
    summarise(
      avg_auc = mean(auc), 
      sd_auc = sd(auc),
      se_auc = sd_auc / sqrt(n()),
      conf.low = avg_auc - se_auc*qt(0.975, n() - 1),
      conf.high = avg_auc + se_auc*qt(0.975, n() - 1)
    )
  
  # Computing accuracy at the level of the cross-validation variable
  output$mod_acc$sites <- output$lasso_predictions %>% 
    mutate(correct = ifelse(actual_type == prediction, 1, 0)) %>% 
    ungroup() %>% 
    group_by({{cv_variable}}) %>% 
    summarise(avg = mean(correct),
              se = sd(correct) / sqrt(n()),
              conf.low = avg - se*qt(0.975, n() - 1),
              conf.high = avg + se*qt(0.975, n() - 1))
  
  # Computing average accuracy across the cross-validation variable
  output$mod_acc$avg <- output$mod_acc$sites %>% 
    ungroup() %>% 
    summarise(
      acc = mean(avg), 
      sd_acc = sd(avg),
      se_acc = sd_acc / sqrt(n()),
      conf.low = acc - se_acc*qt(0.975, n() - 1),
      conf.high = acc + se_acc*qt(0.975, n() - 1)
    )
  
  output$conf_matrix <- conf_mat(output$lasso_predictions, actual_type, prediction)
  
  return(output)
}

run_lasso2 <- function(voc_type_x) {
  
  intuitions_per_voc <- trial_data %>% 
    group_by(stimulus) %>% 
    summarise(perc_inf = sum(inf_guess) / n(),
              perc_ad = 1 - perc_inf,
              voc_type = unique(voc_type))
  
  test_data <- intuitions_per_voc %>% 
    left_join(., acoustic_demean, by = c("stimulus" = "id_recording")) %>% 
    drop_na() %>% 
    select(-id_person, -type) %>% 
    # group_by(id_site) %>% 
    # filter(n() > 5) %>% 
    ungroup() %>%
    filter(voc_type %in% voc_type_x)
  
  output <- list()
  
  # Preprocessing recipe
  feature_recipe <- recipe(perc_inf ~ ., data = test_data) %>%
    update_role(c(voc_type, id_site, perc_ad, stimulus, region, langfam), new_role = "ID") %>% 
    #step_string2factor(type, skip = TRUE) %>% 
    step_zv(all_numeric(), -all_outcomes()) %>%
    step_normalize(all_numeric(), -all_outcomes())
  
  # Add to workflow
  wf <- workflow() %>% 
    add_recipe(feature_recipe)
  
  # Specify LASSO model
  lasso_spec <- linear_reg(mode = "regression", penalty = tune(), mixture = 1) %>%
    set_engine("glmnet", grouped = FALSE)
  
  doParallel::registerDoParallel()
  
  lasso_grid <- tune_grid(
    wf %>% add_model(lasso_spec),
    # Leave-one out CV over id_sites
    resamples = group_vfold_cv(test_data, group = id_site),
    grid = grid_regular(penalty(), levels = 100),
    metrics = metric_set(rmse, rsq)
  )
  
  lasso_grid %>%
    collect_metrics() %>%
    ggplot(aes(penalty, mean, color = .metric)) +
    geom_errorbar(aes(ymin = mean - std_err, ymax = mean + std_err), alpha = 0.5) +
    geom_line(size = 1.5) +
    facet_wrap(~.metric, scales = "free", nrow = 3) +
    scale_x_log10(labels = comma) +
    geom_vline(
      xintercept = select_best(lasso_grid, metric = "rmse") %>% pull(penalty), 
      linetype = "dashed", color = "red", alpha = .7
    ) +
    theme(legend.position = "none") +
    theme_bw()
  
  
  # final lasso with selected lambda
  final_lasso <- finalize_workflow(
    wf %>% add_model(lasso_spec),
    # Using Mean Log-loss as metric to be consistent with the standard cv.glmnet metric
    # (Otherwise known as multinomial deviance)
    select_best(lasso_grid, metric = "rmse")
    # opting to use the 1std rule to select optimal lambda
    #select_by_one_std_err(lasso_grid, desc(mean), metric = "rmse")
  )
  
  
  output$mod_acc <- lasso_grid %>%
    collect_metrics() %>% 
    filter(penalty == select_best(lasso_grid, metric = "rsq") %>% pull(penalty),
           .metric == "rsq") %>% 
    select(mean, std_err) %>% 
    mutate(
      cilo = mean + qnorm(.025) * std_err,
      cihi = mean + qnorm(.975) * std_err)
  
  lasso_fit <- final_lasso %>% 
    fit(test_data)
  
  output$VI_data <- lasso_fit %>%
    pull_workflow_fit() %>%
    # vi(lambda = select_by_one_std_err(lasso_grid, desc(mean), metric = "rmse") %>% pull(penalty)) %>%
    vi(lambda = select_best(lasso_grid, metric = "rmse") %>% pull(penalty)) %>%
    mutate(
      importance_label = ifelse(Sign == "NEG", Importance * -1, Importance),
      Importance = abs(Importance),
      Variable = fct_reorder(Variable, Importance)
    )
  
  output$coefs <- lasso_fit %>% 
    pull_workflow_fit() %>% 
    tidy() %>% 
    filter(estimate != 0)
  
  #Predictions
  output$predictions <- lasso_fit %>%
    predict(new_data = test_data) %>%
    bind_cols(., test_data %>% select(1:5))
  
  return(output)
}

