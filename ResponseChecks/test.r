library(survey)
library(dplyr)

rm(survey_design)
op <- d %>%
  filter(surveyYear == 2025) %>%
  filter(
    motivation_social_AnsweredAll == TRUE &
      motivation_natural_AnsweredAll == TRUE &
      motivation_pp_AnsweredAll == TRUE &
      motivation_resource_AnsweredAll == TRUE
  ) %>%
  left_join(
    ds_comparison %>% select(CustomerID, Age_group) %>% distinct(),
    by = c("CustomerID")
  ) %>%
  select(
    motivation_social,
    motivation_natural,
    motivation_pp,
    motivation_resource,
    Age_group,
    postWeight
  )


# use existing survey_design or create one from your data
design <- if (exists("survey_design")) {
  survey_design
} else {
  svydesign(ids = ~1, weights = ~postWeight, data = op)
}

vars <- c(
  "motivation_social",
  "motivation_natural",
  "motivation_resource",
  "motivation_pp"
) # replace op_scale with real name

out <- lapply(vars, function(v) {
  r <- svyby(
    as.formula(paste0("~", v)),
    ~Age_group,
    design,
    svymean,
    na.rm = TRUE
  )
  df <- as.data.frame(r)
  colnames(df)[2:3] <- c("mean", "se") # svyby returns group, mean, se
  df %>%
    mutate(
      var = v,
      low = mean - qnorm(0.975) * se,
      high = mean + qnorm(0.975) * se
    ) %>%
    select(Age_group, var, mean, se, low, high)
}) |>
  bind_rows()

out

library(ggplot2)

out <- out |>
  dplyr::mutate(Age_group = factor(Age_group, levels = unique(Age_group)))

p <- ggplot(out, aes(x = Age_group, y = mean, color = var, group = var)) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.2) +
  theme_minimal() +
  labs(
    x = "Age group",
    y = "Weighted mean",
    color = "Scale",
    title = "Weighted means by age group"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

p


# r
library(dplyr)
library(ggplot2)

# ensure age_group column exists
if (!"Age_group" %in% names(out) && "Age_group" %in% names(out)) {
  out$Age_group <- out$Age_group
}

# label mapping and factor ordering
labels_y <- c(
  "Not at all important",
  "Slightly important",
  "Moderately important",
  "Very important",
  "Extremely important"
)

out2 <- out |>
  mutate(
    var = dplyr::recode(
      var,
      "motivation_natural" = "Natural Environment",
      "motivation_pp" = "Psychological/Physical",
      "motivation_resource" = "Fishery Research",
      "motivation_social" = "Social"
    ),
    var = factor(
      var,
      levels = c(
        "Natural Environment",
        "Psychological/Physical",
        "Fishery Research",
        "Social"
      )
    ),
    Age_group = factor(Age_group, levels = unique(Age_group))
  )

p <- ggplot(out2, aes(x = Age_group, y = mean, color = var, group = var)) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.2) +
  scale_y_continuous(breaks = 1:5, labels = labels_y, limits = c(1, 5)) +
  theme_bw() +
  labs(
    x = "Age group",
    y = "",
    color = "",
    title = ""
  ) +
  scale_color_viridis_d(end = 0.9) +
  scale_fill_viridis_d(end = 0.9) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


p
ggsave("motivation_by_age_group.png", p, width = 8, height = 5, dpi = 300)


op <- d %>%
  filter(surveyYear == 2025) %>%
  filter(
    attitude_catch_AnsweredAll == TRUE &
      attitude_harvest_AnsweredAll == TRUE &
      attitude_numbers_AnsweredAll == TRUE &
      attitude_size_AnsweredAll == TRUE
  ) %>%
  left_join(
    ds_comparison %>% select(CustomerID, Age_group) %>% distinct(),
    by = c("CustomerID")
  ) %>%
  select(
    attitude_catch,
    attitude_harvest,
    attitude_numbers,
    attitude_size,
    Age_group,
    postWeight
  )
# r
labels_att <- c(
  "Strongly disagree",
  "Disagree",
  "Neutral",
  "Agree",
  "Strongly agree"
)

# r
library(survey)
library(dplyr)
library(ggplot2)

rm(survey_design)
# pick existing survey design
svy <- if (exists("design")) {
  design
} else if (exists("raked_design")) {
  raked_design
} else {
  stop("No survey design found")
}

# r
library(survey)
library(dplyr)
library(ggplot2)

svy <- if (exists("design")) {
  design
} else if (exists("raked_design")) {
  raked_design
} else {
  stop("No survey design found")
}

vars_att <- c("attitude_x", "attitude_y") # replace with discovered names

out_att <- lapply(vars_att, function(v) {
  r <- svyby(as.formula(paste0("~", v)), ~Age_group, svy, svymean, na.rm = TRUE)
  df <- as.data.frame(r)
  colnames(df)[2:3] <- c("mean", "se")
  df %>%
    mutate(
      var = v,
      low = mean - qnorm(0.975) * se,
      high = mean + qnorm(0.975) * se
    ) %>%
    select(Age_group, var, mean, se, low, high)
}) |>
  bind_rows()

out_att <- out_att %>%
  mutate(
    var = gsub("^attitude_", "", var),
    var = tools::toTitleCase(gsub("_", " ", var)),
    age_group = factor(age_group, levels = unique(age_group))
  )

labels_y <- c(
  "Not at all important",
  "Slightly important",
  "Moderately important",
  "Very important",
  "Extremely important"
)

ggplot(out_att, aes(x = age_group, y = mean, color = var, group = var)) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.2) +
  scale_y_continuous(breaks = 1:5, labels = labels_y, limits = c(1, 5)) +
  theme_minimal() +
  labs(x = "Age group", y = "Importance", color = "Scale") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
# nicer variable labels: remove prefix and title-case
out_att2 <- out_att |>
  mutate(
    var = gsub("^attitude_", "", var),
    var = tools::toTitleCase(gsub("_", " ", var)),
    var = factor(var, levels = unique(var)),
    age_group = factor(age_group, levels = unique(age_group))
  )

# y-axis labels
labels_y <- c(
  "Not at all important",
  "Slightly important",
  "Moderately important",
  "Very important",
  "Extremely important"
)

p_att <- ggplot(
  out_att2,
  aes(x = age_group, y = mean, color = var, group = var)
) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.2) +
  scale_y_continuous(breaks = 1:5, labels = labels_y, limits = c(1, 5)) +
  theme_minimal() +
  labs(
    x = "Age group",
    y = "Importance",
    color = "Scale",
    title = "Attitude scales: weighted means by age group"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# show results
out_att2
p_att


p_att2 <- ggplot(
  out_att2,
  aes(x = Age_group, y = mean, color = var, group = var)
) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.2) +
  scale_y_continuous(breaks = 1:5, labels = labels_att, limits = c(1, 5)) +
  theme_minimal() +
  labs(
    x = "Age group",
    y = "Agreement",
    color = "Attitude",
    title = "Attitude scales: weighted means by Age group"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

p_att2


# r
library(dplyr)
library(ggplot2)


op <- d %>%
  filter(surveyYear == 2025) %>%
  filter(
    motivation_social_AnsweredAll == TRUE &
      motivation_natural_AnsweredAll == TRUE &
      motivation_pp_AnsweredAll == TRUE &
      motivation_resource_AnsweredAll == TRUE
  ) %>%
  left_join(
    ds_comparison %>% select(CustomerID, Age_group) %>% distinct(),
    by = c("CustomerID")
  ) %>%
  filter(!is.na(Age_group)) %>%
  select(
    motivation_social,
    motivation_natural,
    motivation_pp,
    motivation_resource,
    Age_group,
    postWeight
  )

# detect motivation vars in op
vars <- grep("^motivation_", names(op), value = TRUE)

# y-axis labels
labels_y <- c(
  "Not at all important",
  "Slightly important",
  "Moderately important",
  "Very important",
  "Extremely important"
)

# compute unweighted means and 95% CI by Age_group
out_unwt <- lapply(vars, function(v) {
  op |>
    group_by(Age_group) |>
    summarise(
      n = sum(!is.na(.data[[v]])),
      mean = mean(.data[[v]], na.rm = TRUE),
      sd = sd(.data[[v]], na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(
      se = sd / sqrt(n),
      df = pmax(n - 1, 1),
      low = mean - qt(0.975, df) * se,
      high = mean + qt(0.975, df) * se,
      var = v
    ) |>
    select(Age_group, var, n, mean, se, low, high)
}) |>
  bind_rows()

# nicer labels for vars and ordering
out_unwt <- out_unwt |>
  mutate(
    var = dplyr::recode(
      var,
      "motivation_natural" = "Natural Environment",
      "motivation_pp" = "Psychological/Physical",
      "motivation_resource" = "Fishery Research",
      "motivation_social" = "Social"
    ),
    var = factor(
      var,
      levels = c(
        "Natural Environment",
        "Psychological/Physical",
        "Fishery Research",
        "Social"
      )
    ),
    Age_group = factor(Age_group, levels = unique(Age_group))
  )

# plot
p_unweighted <- ggplot(
  out_unwt,
  aes(x = Age_group, y = mean, color = var, group = var)
) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.2) +
  scale_y_continuous(breaks = 1:5, labels = labels_y, limits = c(1, 5)) +
  theme_minimal() +
  labs(
    x = "Age group",
    y = "Importance",
    color = "Scale",
    title = "Unweighted motivation means by Age group"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# show results
out_unwt
p_unweighted


# r
library(dplyr)
library(tidyr)
library(ggplot2)

# recompute per-Age_group unweighted and weighted means (uses op$postWeight)
vars <- grep("^motivation_", names(op), value = TRUE)

comp <- lapply(vars, function(v) {
  df_unw <- op |>
    group_by(Age_group) |>
    summarise(
      mean_unw = mean(.data[[v]], na.rm = TRUE),
      n = sum(!is.na(.data[[v]])),
      .groups = "drop"
    )
  df_w <- op |>
    group_by(Age_group) |>
    summarise(
      mean_w = weighted.mean(.data[[v]], w = postWeight, na.rm = TRUE),
      .groups = "drop"
    )
  left_join(df_unw, df_w, by = "Age_group") |> mutate(var = v)
}) |>
  bind_rows()

# summary of differences
comp <- comp |> mutate(diff = mean_w - mean_unw, abs_diff = abs(diff))
comp |>
  summarise(
    mean_abs_diff = mean(abs_diff, na.rm = TRUE),
    max_abs_diff = max(abs_diff, na.rm = TRUE)
  )

# prepare long data for plotting and nicer var labels
labels_y <- c(
  "Not at all important",
  "Slightly important",
  "Moderately important",
  "Very important",
  "Extremely important"
)
comp_long <- comp |>
  pivot_longer(
    cols = c(mean_unw, mean_w),
    names_to = "type",
    values_to = "mean"
  ) |>
  mutate(
    type = dplyr::recode(type, mean_unw = "Unweighted", mean_w = "Weighted"),
    var = dplyr::case_when(
      var == "motivation_natural" ~ "Natural Environment",
      var == "motivation_pp" ~ "Psychological/Physical",
      var == "motivation_resource" ~ "Fishery Research",
      var == "motivation_social" ~ "Social",
      TRUE ~ var
    ),
    var = factor(
      var,
      levels = c(
        "Natural Environment",
        "Psychological/Physical",
        "Fishery Research",
        "Social"
      )
    ),
    Age_group = factor(Age_group, levels = unique(Age_group))
  )

# plot: weighted vs unweighted lines
ggplot(
  comp_long,
  aes(
    x = Age_group,
    y = mean,
    color = var,
    linetype = type,
    group = interaction(var, type)
  )
) +
  geom_line() +
  geom_point(position = position_dodge(width = 0.15)) +
  scale_y_continuous(breaks = 1:5, labels = labels_y, limits = c(1, 5)) +
  theme_minimal() +
  labs(
    x = "Age group",
    y = "Importance",
    color = "Scale",
    linetype = "Estimate",
    title = "Motivation: Weighted vs Unweighted means by Age group"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# r
library(survey)
design_op <- svydesign(ids = ~1, weights = ~postWeight, data = op)
# r
vars <- grep("^motivation_", names(op), value = TRUE)

w_list <- lapply(vars, function(v) {
  m <- svymean(as.formula(paste0("~", v)), design_op, na.rm = TRUE)
  data.frame(
    var = v,
    mean_w = coef(m)[1],
    se_w = SE(m)[1],
    low_w = confint(m)[1, 1],
    high_w = confint(m)[1, 2]
  )
}) |>
  bind_rows()

# join with unweighted (as computed before)

# r
library(survey)
library(dplyr)

# (re)create design that uses op and postWeight
design_op <- svydesign(ids = ~1, weights = ~postWeight, data = op)

# motivation variables
vars <- grep("^motivation_", names(op), value = TRUE)

# weighted population estimates (robust to svymean errors)
w_list <- lapply(vars, function(v) {
  m <- tryCatch(
    svymean(as.formula(paste0("~", v)), design_op, na.rm = TRUE),
    error = function(e) NULL
  )
  if (is.null(m)) {
    return(data.frame(
      var = v,
      mean_w = NA_real_,
      se_w = NA_real_,
      low_w = NA_real_,
      high_w = NA_real_
    ))
  }
  data.frame(
    var = v,
    mean_w = as.numeric(coef(m)[1]),
    se_w = as.numeric(SE(m)[1]),
    low_w = as.numeric(confint(m)[1, 1]),
    high_w = as.numeric(confint(m)[1, 2])
  )
}) |>
  bind_rows()

# unweighted population estimates
unw_list <- lapply(vars, function(v) {
  vals <- op[[v]]
  n <- sum(!is.na(vals))
  mean_unw <- mean(vals, na.rm = TRUE)
  sd_unw <- sd(vals, na.rm = TRUE)
  se_unw <- if (n > 0) sd_unw / sqrt(n) else NA_real_
  df <- max(n - 1, 1)
  low_unw <- mean_unw - qt(0.975, df) * se_unw
  high_unw <- mean_unw + qt(0.975, df) * se_unw
  data.frame(
    var = v,
    n = n,
    mean_unw = mean_unw,
    se_unw = se_unw,
    low_unw = low_unw,
    high_unw = high_unw
  )
}) |>
  bind_rows()

# join and label
res <- left_join(w_list, unw_list, by = "var") %>%
  mutate(
    label = case_when(
      var == "motivation_natural" ~ "Natural Environment",
      var == "motivation_pp" ~ "Psychological/Physical",
      var == "motivation_resource" ~ "Fishery Research",
      var == "motivation_social" ~ "Social",
      TRUE ~ var
    )
  ) %>%
  select(
    var,
    label,
    n,
    mean_w,
    se_w,
    low_w,
    high_w,
    mean_unw,
    se_unw,
    low_unw,
    high_unw
  )

res

# r
library(dplyr)
library(ggplot2)

# compute age-group means and proportions
vars <- grep("^motivation_", names(op), value = TRUE)
age_stats <- op %>%
  group_by(Age_group) %>%
  summarise(
    n = n(),
    prop_n = n / sum(n),
    wt_sum = sum(postWeight, na.rm = TRUE),
    prop_w = wt_sum / sum(wt_sum),
    across(all_of(vars), ~ mean(.x, na.rm = TRUE), .names = "mean_{.col}"),
    .groups = "drop"
  )

# choose one variable to decompose, e.g. motivation_social
v <- "motivation_social"
age_stats <- age_stats %>%
  transmute(Age_group, prop_n, prop_w, mean = .data[[paste0("mean_", v)]]) %>%
  mutate(
    contrib_unw = prop_n * mean,
    contrib_w = prop_w * mean,
    contrib_diff = contrib_w - contrib_unw
  )

# total difference and contribution table
total_diff <- sum(age_stats$contrib_diff)
age_stats
cat('Total weighted - unweighted difference =', round(total_diff, 3), '\\n')

# bar plot of contributions
ggplot(age_stats, aes(x = Age_group, y = contrib_diff)) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = 'dashed') +
  labs(y = 'Contribution to (Weighted - Unweighted) mean', title = v) +
  theme_minimal()

op <- d %>%
  filter(surveyYear == 2025) %>%
  filter(!is.na(B1)) %>%
  select(B1, postWeight)

op <- d %>%
  filter(surveyYear == 2025) %>%
  filter(!is.na(B2_Answered)) %>%
  select(B2musk, postWeight)


op <- d %>%
  filter(surveyYear == 2025) %>%
  filter(!is.na(B1)) %>%
  filter(!is.na(D4a)) %>%
  select(D4a, B1, postWeight)


# r
library(dplyr)
library(ggplot2)
library(tidyr)
library(scales)

# build plotting data (uses props_all, props_musky, D4a_levels from session)
df_comb <- full_join(
  props_all,
  props_musky,
  by = "level",
  suffix = c("_all", "_musky")
)

df_plot <- df_comb %>%
  pivot_longer(
    cols = c(est_all, est_musky),
    names_to = "type",
    values_to = "est"
  ) %>%
  mutate(
    group = ifelse(type == "est_all", "All anglers", "Musky anglers"),
    low = ifelse(group == "All anglers", low_all, low_musky),
    high = ifelse(group == "All anglers", high_all, high_musky),
    level = factor(level, levels = D4a_levels)
  ) %>%
  mutate(across(c(est, low, high), as.numeric))

# safe y-limit
ymax <- max(df_plot$high, na.rm = TRUE)
if (!is.finite(ymax)) {
  ymax <- max(df_plot$est, na.rm = TRUE, na.rm = TRUE)
}
ymax <- ymax * 1.05

# grouped bar chart with 95% CIs
p_d4a_bar <- ggplot(df_plot, aes(x = level, y = est, fill = group)) +
  geom_col(
    position = position_dodge(width = 0.8),
    width = 0.7,
    color = "black",
    na.rm = TRUE
  ) +
  geom_errorbar(
    aes(ymin = low, ymax = high),
    position = position_dodge(width = 0.8),
    width = 0.2,
    na.rm = TRUE
  ) +
  scale_y_continuous(labels = percent_format(scale = 1), limits = c(0, ymax)) +
  labs(
    x = "D4a response",
    y = "Weighted percent",
    fill = "Group",
    title = "D4a: Weighted percent (All vs Musky anglers) with 95% CI"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

p_d4a_bar

# optional: save
# ggsave("D4a_all_vs_musky_bar.png", p_d4a_bar, width = 8, height = 5, dpi = 300)

######################################################################################
###########################################
######################################################################################

# r
library(survey)
library(dplyr)
library(ggplot2)

# replace RHS with the pipeline that creates 'op' if needed; here we assume op already exists
op <- d %>%
  filter(surveyYear == 2025) %>%
  filter(
    attitude_catch_AnsweredAll == TRUE &
      attitude_harvest_AnsweredAll == TRUE &
      attitude_numbers_AnsweredAll == TRUE &
      attitude_size_AnsweredAll == TRUE
  ) %>%
  left_join(
    ds_comparison %>% select(CustomerID, Age_group) %>% distinct(),
    by = c("CustomerID")
  ) %>%
  select(
    attitude_catch,
    attitude_harvest,
    attitude_numbers,
    attitude_size,
    Age_group,
    postWeight
  )
# r
labels_att <- c(
  "Strongly disagree",
  "Disagree",
  "Neutral",
  "Agree",
  "Strongly agree"
)

# recreate survey design (uses Age_group and postWeight in op)
design_op <- svydesign(ids = ~1, weights = ~postWeight, data = op)

# find attitude variables
vars_att <- grep("^attitude_", names(op), value = TRUE)

# compute weighted means + 95% CI by Age_group for each attitude variable
out_att <- lapply(vars_att, function(v) {
  r <- svyby(
    as.formula(paste0("~", v)),
    ~Age_group,
    design_op,
    svymean,
    na.rm = TRUE
  )
  df <- as.data.frame(r)
  mean_col <- names(df)[2]
  se_col <- names(df)[3]
  df <- df |>
    rename(mean = !!rlang::sym(mean_col), se = !!rlang::sym(se_col)) |>
    mutate(
      var = v,
      low = mean - qnorm(0.975) * se,
      high = mean + qnorm(0.975) * se
    ) |>
    select(Age_group, var, mean, se, low, high)
  df
}) |>
  bind_rows()

# clean variable labels and ordering
# r
out_att2 <- out_att %>%
  mutate(
    var = gsub("_", " ", gsub("^attitude_", "", var)),
    var = tools::toTitleCase(var),
    var = factor(var, levels = unique(var)),
    Age_group = factor(Age_group, levels = unique(Age_group))
  )

# y-axis labels for attitude scale
labels_att <- c(
  "Strongly disagree",
  "Disagree",
  "Neutral",
  "Agree",
  "Strongly agree"
)

# plot
p_att <- ggplot(
  out_att2,
  aes(x = Age_group, y = mean, color = var, group = var)
) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.2) +
  scale_y_continuous(breaks = 1:5, labels = labels_att, limits = c(1, 5)) +
  labs(
    x = "Age group",
    y = "",
    color = "",
    title = ""
  ) +
  scale_color_viridis_d(end = 0.9) +
  scale_fill_viridis_d(end = 0.9) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(
    panel.grid.major.x = element_blank(),
    axis.text = element_text(size = 14),
    plot.title = element_text(size = 18, face = "bold"),
    axis.title = element_text(size = 16),
    legend.title = element_blank()
  )


# display and save
print(p_att)
ggsave("attitude_by_age.png", p_att, width = 10, height = 6, dpi = 300)
