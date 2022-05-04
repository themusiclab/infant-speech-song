################################################################
# this script contains a variety of custom functions used in the
# analyses.rmd script
################################################################

##########################################
# Helper functions for formatting things #
##########################################

# Formats output lists for use in manuscript, data_list = list of outputs
# sets outputs as text + with thousand mark commas (e.g., 100,000 instead of 100000)
format_list <- function(data_list) {
  lapply(data_list, format, nsmall=0, big.mark = ",")
}

# rounds to 1 decimal place and adds percent sign
p <- function(num) {percent(num, accuracy=.1)}

# rounds to 2 decimal places
r2 <- function(num) {round(num, 2)}

# format p-values
fp <- function(num) {
  if (num < .0001) {
    return("< .0001")
  } else if (num < .001) {
    return("< .001")
  } else if (num < .01) {
    return(paste0("= ", round(num, digits = 3)))
  } else {
    return(paste0("= ", round(num, digits = 2)))
  }
}

f <- function(num) {format(num, big.mark = ",")}

######################
# analysis functions #
######################

# function to extract site estimates from d' random effects in mixed model
extract_site_estimates <- function(mod_x, voc_type, ref_level) {
  fixed <- mod_x %>% tidy %>% 
    filter(effect == "fixed",
           term == voc_type) %>% 
    select(d_prime = estimate) %>% pull(d_prime)
  
  random <- augment(ranef(mod_x), ci.level = 0.95) %>% tibble %>%
    filter(variable == voc_type)
  
  combined <- random %>%
    mutate(intercept = fixed,
           across(c(estimate, lb, ub), ~ .x + intercept)) %>%
    mutate(above_zero = ifelse(lb > ref_level, 1, 0))
  
  return(combined)
}

# return vector of stimulus IDs where there is both ID and AD version within voice
extract_complete_ids <- function(data) {
  data %>% 
    group_by(id, sung, infdir) %>% 
    summarise(stimulus = unique(stimulus)) %>% 
    group_by(id, sung) %>% 
    filter(n() == 2) %>% 
    pull(stimulus)
}

# return d' estimate for each vocalization, optionally grouped by a variable
extract_d <- function(data, grouping_var = NULL) {
  data %>% 
    filter(stimulus %in% extract_complete_ids(data)) %>% 
    group_by(id, sung = ifelse(sung == 1, "song", "speech"), {{grouping_var}}) %>% 
    summarise(hit = sum(correct == 1 & infdir == 1),
              miss = sum(correct == 0 & infdir == 1),
              false_alarm = sum(correct == 0 & infdir == 0),
              correct_reject = sum(correct == 1 & infdir == 0)) %>%
    filter(
      # somewhat arbitrarily choosing a minimum of 5 signal and noise trials for these estimates (roughly same result with other values)
      # this is to ensure an estimate of d' is reasonable for a given unit.
      (hit + miss > 5) & (false_alarm + correct_reject > 5)
    ) %>% 
    # Compute d-prime + confidence intervals for each voc type
    mutate(
      # computing rate metrics
      # applying a log-linear correction (more conservative estimate, adjusting for extreme hr & far values)
      # c.f., Snodgrass & Corwin, 1988; Hautus, 1995; Miller, 1996
      hr = (hit + 0.5) / (hit + miss + 1),
      far = (false_alarm + 0.5)/ (false_alarm + correct_reject + 1)
    ) %>% 
    ungroup() %>% 
    group_by(sung, id, {{grouping_var}}) %>% 
    summarise(across(everything(), ~ mean(.x))) %>% 
    mutate(
      phi_hr = 1/sqrt(2*pi)*exp((-1/2)*qnorm(hr)^2),
      phi_far = 1/sqrt(2*pi)*exp((-1/2)*qnorm(far)^2),
      d_prime = qnorm(hr) - qnorm(far),
      c = -(qnorm(hr) + qnorm(far))/2
    )
}

# summarise d' results with average and 95% CIs
summarise_d <- function(data) {
  data %>% 
    summarise(avg_d = mean(d_prime),
              sd_d = sd(d_prime),
              se_d = sd_d / sqrt(n()),
              conf.high = avg_d + se_d * qt(0.975, n() - 1),
              conf.low = avg_d - se_d * qt(0.975, n() - 1))
}

# for testing correlations between human LASSO model variable importance rankings & acoustic features identified
# in the exploratory/confirmatory analysis
relation_tester <- function(data_x, sung_x) {
  temp <- data_x$VI_data %>%
    filter(Importance > 0)
  
  # Create ranking of features according to how large their differences are between ID and AD
  features <- final$plot %>%
    filter(song == sung_x,
           feat %in% (temp %>% pull(Variable))) %>%
    group_by(feat, infdir) %>%
    summarise(avg = mean(z, na.rm = T)) %>%
    pivot_wider(names_from = infdir, values_from = avg) %>%
    mutate(diff = abs(infant - adult)) %>%
    ungroup() %>% 
    select(Variable = feat, diff)
  
  redo_mods <- map(setdiff(temp$Variable, features$Variable) %>% set_names, ~ {
    form <- reformulate(c("0 + voc_type + (0 + voc_type|id_site) + (1|id_person)"), response = .x %>% as.character())
    mod <- lmer(form, data = acoustic) %>% tidy
    
    if (sung_x == "speech") {
      diff = mod %>% filter(term == "voc_typeB") %>% pull(estimate) -
        mod %>% filter(term == "voc_typeD") %>% pull(estimate)
    } else if (sung_x == "song") {
      diff = mod %>% filter(term == "voc_typeA") %>% pull(estimate) -
        mod %>% filter(term == "voc_typeC") %>% pull(estimate)
    }
    
    return(diff)
  })
  
  redo_mods <- redo_mods %>% as_tibble %>% pivot_longer(cols = everything()) %>% rename(Variable = 1, diff = 2)
  features <- features %>% bind_rows(., redo_mods)
  
  temp <- temp %>%
    left_join(., features, by = "Variable")
  
  test <- cor.test(temp$Importance, temp$diff, alternative = "greater") %>% tidy
  
  return(test)
}

# plotting functions


"%||%" <- function(a, b) {
  if (!is.null(a)) a else b
}

geom_flat_violin <- function(mapping = NULL, data = NULL, stat = "ydensity",
                             position = "dodge", trim = TRUE, scale = "area",
                             show.legend = NA, inherit.aes = TRUE, ...) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomFlatViolin,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      trim = trim,
      scale = scale,
      ...
    )
  )
}

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
GeomFlatViolin <-
  ggproto("GeomFlatViolin", Geom,
          setup_data = function(data, params) {
            data$width <- data$width %||%
              params$width %||% (resolution(data$x, FALSE) * 0.9)
            
            # ymin, ymax, xmin, and xmax define the bounding rectangle for each group
            data %>%
              group_by(group) %>%
              mutate(ymin = min(y),
                     ymax = max(y),
                     xmin = x,
                     xmax = x + violin_direction*(width / 2))
            
          },
          
          draw_group = function(data, panel_scales, coord) {
            # Find the points for the line to go all the way around
            data <- transform(data, xminv = x,
                              xmaxv = x + violinwidth * (xmax - x))
            
            # Make sure it's sorted properly to draw the outline
            newdata <- rbind(plyr::arrange(transform(data, x = xminv), y),
                             plyr::arrange(transform(data, x = xmaxv), -y))
            
            # Close the polygon: set first and last point the same
            # Needed for coord_polar and such
            newdata <- rbind(newdata, newdata[1,])
            
            ggplot2:::ggname("geom_flat_violin", GeomPolygon$draw_panel(newdata, panel_scales, coord))
          },
          
          draw_key = draw_key_polygon,
          
          default_aes = aes(weight = 1, colour = "grey20", fill = "white", size = 0.5,
                            alpha = NA, linetype = "solid"),
          
          required_aes = c("x", "y", "violin_direction")
  )



