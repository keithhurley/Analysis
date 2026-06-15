library(dplyr)
library(tidyr)
library(lubridate)
library(forcats)
library(ggplot2)
library(readxl)
library(stringr)
library(scales)
library(purrr)
library(rlang)

#import license dataset
ds_license <- readxl::read_xlsx(
  ".//SurveyDraw/Permits.xlsx"
)
#import subsample dataset
ds_subsample <- read.csv("SurveyDraw/subsample_final_20251020.csv") %>%
  left_join(
    ds_license %>% select(CustomerID, ZipCode) %>% unique(),
    by = "CustomerID"
  )
#import response dataset
ds_responses <- readxl::read_excel(
  "./Data/DataAggregation/TrackingForm_Client.xlsx"
) %>%
  select(
    CustomerID = 'CustomerID',
    Responded = 'Completion disposition (1.1)',
    Mode = 'Mode of completion (Mail, web, phone)',
    Notes
  ) %>%
  left_join(
    ds_license %>% select(CustomerID, ZipCode) %>% unique(),
    by = "CustomerID"
  ) %>%
  mutate(
    Subsampled = TRUE,
    Responded = !is.na(Responded), # Only TRUE if actually responded
    Mode = case_when(
      str_detect(tolower(Mode), "^mail") ~ "Mail",
      str_detect(tolower(Mode), "^postcard") ~ "Mail",
      str_detect(tolower(Mode), "^text") ~ "Text",
      str_detect(tolower(Mode), "^email") ~ "Email",
      str_detect(tolower(Mode), "^web") ~ "Web",
      .default = NA
    ),
    Undeliverable_Email1 = str_detect(Notes, "Undeliverable via: Email 1"),
    Undeliverable_Email2 = str_detect(Notes, "Undeliverable via: Email 2"),
    Undeliverable_Text1 = str_detect(Notes, "Undeliverable via: Text 1"),
    Undeliverable_Text2 = str_detect(Notes, "Undeliverable via: Text 2"),
    Undeliverable_MailLetter1 = str_detect(
      Notes,
      "Undeliverable via: Mail \\(Letter 1\\)"
    ),
    Undeliverable_MailLetter2 = str_detect(
      Notes,
      "Undeliverable via: Mail \\(Letter 2\\)"
    ),
    Undeliverable_MailPostcard = str_detect(
      Notes,
      "Undeliverable via: Mail \\(Postcard\\)"
    ),
    across(starts_with("Undeliverable_"), \(x) replace_na(x, FALSE))
  )


#extract and shape response analysis dataset
ds_license <- ds_license %>%
  select(CustomerID, ZipCode, Age, GenderStatus, PermitName, ResidencyStatus)

ds_subsample <- ds_subsample %>%
  select(CustomerID) %>%
  mutate(Subsample = TRUE)

ds_subsample <- ds_subsample %>%
  select(CustomerID) %>%
  distinct(CustomerID) %>%
  mutate(Subsample = TRUE)

ds_responses <- ds_responses %>%
  filter(Responded) %>% # Only keep actual respondents
  select(CustomerID) %>%
  mutate(Response = TRUE)

ds <- ds_license %>%
  left_join(ds_subsample, by = "CustomerID") %>%
  left_join(ds_responses, by = "CustomerID") %>%
  mutate(
    Subsample = replace_na(Subsample, FALSE),
    Response = replace_na(Response, FALSE)
  )


library(tidycensus)
library(zipcodeR)
library(sf)
library(tigris)

# Set up urban/rural classification
sf_zctas <- zctas(year = 2010, state = "NE") %>%
  st_as_sf() %>%
  st_transform(4326)

myUrbanCities <- c(
  "Omaha",
  "Lincoln",
  "Bellevue",
  "Grand Island",
  "Kearney",
  "Fremont",
  "Hastings",
  "Norfolk",
  "North Platte",
  "Columbus",
  "Papillion",
  "La Vista",
  "Scottsbluff",
  "South Sioux City",
  "Beatrice",
  "Lexington",
  "Alliance",
  "Offutt A F B",
  "Elkhorn"
)

data("zip_code_db")
myUrbanZips <- zip_code_db %>%
  filter(
    state == "NE",
    major_city %in% myUrbanCities
  ) %>%
  pull(zipcode) %>%
  unique()

sf_urbanZips <- sf_zctas %>%
  mutate(zc = as.character(ZCTA5CE10)) %>%
  filter(zc %in% myUrbanZips)

# Add urban variable to all three datasets
ds <- ds %>%
  mutate(
    ZipCode = as.character(ZipCode),
    urban = ZipCode %in% sf_urbanZips$zc,
    UrbanRural = ifelse(urban, "Urban", "Rural")
  )

# ds_subsample <- ds_subsample %>%
#   mutate(
#     ZipCode = as.character(ZipCode),
#     urban = ZipCode %in% sf_urbanZips$zc,
#     UrbanRural = ifelse(urban, "Urban", "Rural")
#   )

# ds_license <- ds_license %>%
#   mutate(
#     ZipCode = as.character(ZipCode),
#     urban = ZipCode %in% sf_urbanZips$zc,
#     UrbanRural = ifelse(urban, "Urban", "Rural")
#   )

# Quick check
ds %>% count(UrbanRural)

# ── 1. Add grouping variables ────────────────────────────────────────────────
ds_grp <- ds |>
  mutate(
    AgeGroup = cut(
      Age,
      breaks = c(0, 24, 34, 44, 54, 64, Inf),
      labels = c("16-24", "25-34", "35-44", "45-54", "55-64", "65 or older"),
      right = TRUE
    ),
    GenderStatus = factor(
      GenderStatus,
      levels = c("Male", "Female", "Other", "PreferNotToSay")
    ),
    ResidencyStatus = if_else(
      ResidencyStatus == "Yes",
      "Resident",
      "Non-Resident"
    )
  )


# Summarize percent of each demographic group within Licenses, Subsample, and Responses
# prepare dataset slices (base dataset is licenses)
datasets <- list(
  n = ds_grp,
  Licenses = ds_grp,
  Subsample = ds_grp |> filter(Subsample),
  Responses = ds_grp |> filter(Response)
)

make_summary <- function(df, group_var, dataset_name) {
  nvar <- ensym(group_var)
  ntotal <- nrow(df)
  ndf <- df |>
    filter(!is.na(!!nvar)) |>
    count(!!nvar, name = "n") |>
    mutate(
      pct = n / ifelse(ntotal == 0, NA_real_, ntotal),
      dataset = dataset_name,
      group = as.character(!!nvar)
    ) |>
    select(dataset, group, n, pct)
  return(ndf)
}

group_vars <- c("AgeGroup", "GenderStatus", "ResidencyStatus", "UrbanRural")

summaries <- map_dfr(group_vars, function(gv) {
  map_dfr(names(datasets)[-1], function(name) {
    make_summary(datasets[[name]], !!sym(gv), name) |> mutate(var = gv)
  })
})

# tables per variable for easy inspection
ntables_age <- summaries |> filter(var == "AgeGroup") |> arrange(dataset, group)
ntables_gender <- summaries |>
  filter(var == "GenderStatus") |>
  arrange(dataset, group)
ntables_residency <- summaries |>
  filter(var == "ResidencyStatus") |>
  arrange(dataset, group)
ntables_urbanrural <- summaries |>
  filter(var == "UrbanRural") |>
  arrange(dataset, group)

# plots: percent by group, grouped by dataset
plot_for_var <- function(var_name, x_lab = NULL, file = NULL) {
  #df <- summaries |> filter(var == var_name)
  df <- summaries |>
    filter(var == var_name, dataset != "Responses") |>
    mutate(label = as.character(sprintf("%.1f", pct * 100))) # add labels for percentages
  if (var_name == "GenderStatus") {
    df <- df |>
      filter(!group %in% c("Other", "PreferNotToSay")) |>
      mutate(group = forcats::fct_drop(group))
  }

  p <- ggplot(df, aes(x = group, y = pct, fill = dataset)) +
    geom_col(position = position_dodge(width = 0.7)) +
    geom_text(
      aes(label = label),
      position = position_dodge(width = 0.7),
      vjust = -0.3,
      size = 3
    ) +
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    labs(
      x = x_lab %||% var_name,
      y = "Percent",
      fill = "Dataset",
      title = "" #paste(var_name, "distribution")
    ) +
    scale_fill_viridis_d(end = .9) +
    theme_bw() +
    theme(
      axis.text = element_text(size = 14),
      plot.title = element_text(size = 18, face = "bold"),
      axis.title = element_text(size = 16),
      legend.text = element_text(size = 14),
      legend.title = element_blank(),
      panel.grid.major.x = element_blank()
    )

  if (!is.null(file)) {
    ggsave(filename = file, plot = p, width = 8, height = 5)
  }
  p
}


nplot_age <- plot_for_var(
  "AgeGroup",
  x_lab = "Age group",
  file = "op/summary_age.png"
)


nplot_gender <- plot_for_var(
  "GenderStatus",
  x_lab = "Gender",
  file = "op/summary_gender.png"
)
nplot_residency <- plot_for_var(
  "ResidencyStatus",
  x_lab = "Residency status",
  file = "op/summary_residency.png"
)
nplot_urbanrural <- plot_for_var(
  "UrbanRural",
  x_lab = "Urban/Rural",
  file = "op/summary_urbanrural.png"
)

# return a list object for interactive inspection
nresult_demographic_summary <- list(
  summaries = summaries,
  tables = list(
    age = ntables_age,
    gender = ntables_gender,
    residency = ntables_residency,
    urbanrural = ntables_urbanrural
  ),
  plots = list(
    age = nplot_age,
    gender = nplot_gender,
    residency = nplot_residency,
    urbanrural = nplot_urbanrural
  )
)

nresult_demographic_summary


library(tidyverse)

# Create summary showing distribution across three groups for each demographic

# Age distribution
age_summary <- ds |>
  mutate(
    Group = case_when(
      Response ~ "Respondents",
      Subsample & !Response ~ "Non-Respondents (in subsample)",
      !Subsample ~ "Not Surveyed",
      TRUE ~ "Other"
    )
  ) |>
  group_by(Group) |>
  summarise(
    Mean_Age = mean(Age, na.rm = TRUE),
    Median_Age = median(Age, na.rm = TRUE),
    SD_Age = sd(Age, na.rm = TRUE),
    Count = n(),
    .groups = "drop"
  ) |>
  mutate(Pct = Count / sum(Count) * 100) |>
  select(Group, Count, Pct, Mean_Age, Median_Age, SD_Age)

cat("AGE COMPARISON\n")
age_summary

# Gender distribution
cat("\n\nGENDER COMPARISON\n")
gender_summary <- ds |>
  mutate(
    Group = case_when(
      Response ~ "Respondents",
      Subsample & !Response ~ "Non-Respondents (in subsample)",
      !Subsample ~ "Not Surveyed",
      TRUE ~ "Other"
    )
  ) |>
  group_by(Group, GenderStatus) |>
  summarise(Count = n(), .groups = "drop") |>
  group_by(Group) |>
  mutate(Pct = Count / sum(Count) * 100) |>
  arrange(Group, GenderStatus)

gender_summary

# Residency distribution
cat("\n\nRESIDENCY COMPARISON\n")
residency_summary <- ds |>
  mutate(
    Group = case_when(
      Response ~ "Respondents",
      Subsample & !Response ~ "Non-Respondents (in subsample)",
      !Subsample ~ "Not Surveyed",
      TRUE ~ "Other"
    )
  ) |>
  group_by(Group, ResidencyStatus) |>
  summarise(Count = n(), .groups = "drop") |>
  group_by(Group) |>
  mutate(Pct = Count / sum(Count) * 100) |>
  arrange(Group, ResidencyStatus)

residency_summary

# Urban/Rural distribution
cat("\n\nUrban-Rural COMPARISON\n")
urbanrural_summary <- ds |>
  mutate(
    Group = case_when(
      Response ~ "Respondents",
      Subsample & !Response ~ "Non-Respondents (in subsample)",
      !Subsample ~ "Not Surveyed",
      TRUE ~ "Other"
    )
  ) |>
  group_by(Group, UrbanRural) |>
  summarise(Count = n(), .groups = "drop") |>
  group_by(Group) |>
  mutate(Pct = Count / sum(Count) * 100) |>
  arrange(Group, UrbanRural)

urbanrural_summary

# Create comparison groups: Respondents vs Non-Respondents (in subsample only)
ds_comparison <- ds |>
  filter(Subsample) |> # Only compare those who were surveyed
  mutate(
    Responded = Response,
    Age_group = cut(
      Age,
      breaks = c(0, 30, 40, 50, 60, 70, 100),
      labels = c("18-30", "31-40", "41-50", "51-60", "61-70", "70+")
    )
  )

cat("\n========================================\n")
cat("STATISTICAL TESTS FOR RESPONSE BIAS\n")
cat("========================================\n\n")

# AGE: T-TEST
cat("1. AGE: Independent samples t-test\n")
cat("   H0: Mean age of respondents = Mean age of non-respondents\n")
respondent_ages <- ds_comparison |> filter(Responded) |> pull(Age)
non_respondent_ages <- ds_comparison |> filter(!Responded) |> pull(Age)

age_ttest <- t.test(respondent_ages, non_respondent_ages)
cat("   t-statistic:", round(age_ttest$statistic, 4), "\n")
cat("   p-value:", format(age_ttest$p.value, scientific = TRUE), "\n")
cat("   Mean (Respondents):", round(mean(respondent_ages), 2), "\n")
cat("   Mean (Non-respondents):", round(mean(non_respondent_ages), 2), "\n")
cat(
  "   Difference:",
  round(mean(respondent_ages) - mean(non_respondent_ages), 2),
  "years\n"
)
cat(
  "   Result:",
  ifelse(age_ttest$p.value < 0.05, "*** SIGNIFICANT ***", "Not significant"),
  "\n\n"
)

# GENDER: CHI-SQUARE TEST
cat("2. GENDER: Chi-square test of independence\n")
cat("   H0: Gender distribution independent of response status\n")
gender_table <- ds_comparison |>
  group_by(GenderStatus, Responded) |>
  filter(GenderStatus %in% c("Male", "Female")) |>
  summarise(Count = n(), .groups = "drop") |>
  pivot_wider(names_from = Responded, values_from = Count, values_fill = 0)

gender_contingency <- as.matrix(gender_table[, -1])
rownames(gender_contingency) <- gender_table$GenderStatus

gender_chi <- chisq.test(gender_contingency)
cat("   Chi-square statistic:", round(gender_chi$statistic, 4), "\n")
cat("   p-value:", format(gender_chi$p.value, scientific = TRUE), "\n")
cat("   df:", gender_chi$parameter, "\n")
cat(
  "   Result:",
  ifelse(gender_chi$p.value < 0.05, "*** SIGNIFICANT ***", "Not significant"),
  "\n\n"
)

# RESIDENCY: CHI-SQUARE TEST
cat("3. RESIDENCY: Chi-square test of independence\n")
cat("   H0: Residency status independent of response status\n")
residency_table <- ds_comparison |>
  group_by(ResidencyStatus, Responded) |>
  summarise(Count = n(), .groups = "drop") |>
  pivot_wider(names_from = Responded, values_from = Count, values_fill = 0)

residency_contingency <- as.matrix(residency_table[, -1])
rownames(residency_contingency) <- residency_table$ResidencyStatus

residency_chi <- chisq.test(residency_contingency)
cat("   Chi-square statistic:", round(residency_chi$statistic, 4), "\n")
cat("   p-value:", format(residency_chi$p.value, scientific = TRUE), "\n")
cat("   df:", residency_chi$parameter, "\n")
cat(
  "   Result:",
  ifelse(
    residency_chi$p.value < 0.05,
    "*** SIGNIFICANT ***",
    "Not significant"
  ),
  "\n\n"
)

# UrbanRural: CHI-SQUARE TEST
cat("3. Urban-Rural: Chi-square test of independence\n")
cat("   H0: Urban-Rural status independent of response status\n")
urbanrural_table <- ds_comparison |>
  group_by(UrbanRural, Responded) |>
  summarise(Count = n(), .groups = "drop") |>
  pivot_wider(names_from = Responded, values_from = Count, values_fill = 0)

urbanrural_contingency <- as.matrix(urbanrural_table[, -1])
rownames(urbanrural_contingency) <- urbanrural_table$UrbanRural

urbanrural_chi <- chisq.test(urbanrural_contingency)
cat("   Chi-square statistic:", round(urbanrural_chi$statistic, 4), "\n")
cat("   p-value:", format(urbanrural_chi$p.value, scientific = TRUE), "\n")
cat("   df:", urbanrural_chi$parameter, "\n")
cat(
  "   Result:",
  ifelse(
    urbanrural_chi$p.value < 0.05,
    "*** SIGNIFICANT ***",
    "Not significant"
  ),
  "\n\n"
)


ds_comparison |>
  mutate(Responded = ifelse(Responded, "Respondent", "Non-Respondent")) |>
  filter(!is.na(Age_group)) |>
  group_by(Age_group, Responded) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(Age_group) |>
  mutate(pct = n / sum(n)) |>
  mutate(label = sprintf("%.1f%%", pct * 100)) |>
  ggplot(aes(x = Age_group, y = pct, fill = Responded)) +
  geom_col(position = position_dodge(width = 0.7)) +
  geom_text(
    aes(label = label),
    position = position_dodge(width = 0.8),
    vjust = -0.3,
    size = 3
  ) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_viridis_d(begin = 0, end = 0.9) +
  labs(
    title = "",
    x = "Age Group",
    y = "",
    fill = ""
  ) +
  theme_bw()

ggsave(filename = "age_response.png", width = 8, height = 5)


# Gender distribution plot
ds_comparison |>
  mutate(Responded = ifelse(Responded, "Respondent", "Non-Respondent")) |>
  filter(!is.na(GenderStatus)) |>
  filter(GenderStatus %in% c("Female", "Male")) |>
  group_by(GenderStatus, Responded) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(Responded) |>
  mutate(pct = n / sum(n)) |>
  mutate(label = sprintf("%.1f%%", pct * 100)) |>
  ggplot(aes(x = GenderStatus, y = pct, fill = Responded)) +
  geom_col(position = position_dodge(width = 0.8)) +
  geom_text(
    aes(label = label),
    position = position_dodge(width = 0.8),
    vjust = -0.3,
    size = 3
  ) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_viridis_d(begin = 0, end = 0.9) +
  labs(
    title = "",
    x = "Gender",
    y = "Percent",
    fill = ""
  ) +
  theme_bw()

ggsave(filename = "gender_response.png", width = 8, height = 5)


# Residency distribution plot
ds_comparison |>
  mutate(Responded = ifelse(Responded, "Respondent", "Non-Respondent")) |>
  filter(!is.na(ResidencyStatus)) |>
  group_by(ResidencyStatus, Responded) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(Responded) |>
  mutate(pct = n / sum(n)) |>
  mutate(label = sprintf("%.1f%%", pct * 100)) |>
  ggplot(aes(x = ResidencyStatus, y = pct, fill = Responded)) +
  geom_col(position = position_dodge(width = 0.8)) +
  geom_text(
    aes(label = label),
    position = position_dodge(width = 0.7),
    vjust = -0.3,
    size = 3
  ) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_viridis_d(begin = 0, end = 0.9) +
  labs(
    title = "",
    x = "Residency Status",
    y = "Percent",
    fill = ""
  ) +
  theme_bw()

ggsave(filename = "res_response.png", width = 8, height = 5)


# Urban/Rural distribution plot
ds_comparison |>
  mutate(Responded = ifelse(Responded, "Respondent", "Non-Respondent")) |>
  filter(!is.na(UrbanRural)) |>
  group_by(UrbanRural, Responded) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(Responded) |>
  mutate(pct = n / sum(n)) |>
  mutate(label = sprintf("%.1f%%", pct * 100)) |>
  ggplot(aes(x = UrbanRural, y = pct, fill = Responded)) +
  geom_col(position = position_dodge(width = 0.7)) +
  geom_text(
    aes(label = label),
    position = position_dodge(width = 0.7),
    vjust = -0.3,
    size = 3
  ) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_viridis_d(begin = 0, end = 0.9) +
  labs(
    title = "",
    x = "Urban/Rural",
    y = "Percent",
    fill = ""
  ) +
  theme_bw()

ggsave(filename = "ur_response.png", width = 8, height = 5)

cat("========================================\n")
cat("SUMMARY: Significance at α = 0.05\n")
cat("========================================\n")


library(survey)

# Prepare the respondent data with age categories (exclude NAs)
respondents_for_raking <- ds |>
  filter(Response == TRUE, !is.na(Age)) |>
  mutate(
    Age_Category = cut(
      Age,
      breaks = c(0, 30, 40, 50, 60, 70, 100),
      labels = c("18-30", "31-40", "41-50", "51-60", "61-70", "70+"),
      include.lowest = TRUE
    ),
    Resident = ResidencyStatus,
    UrbanRural = UrbanRural
  ) |>
  select(CustomerID, Age_Category, Resident) |>
  as.data.frame()

# Get population target distributions (exclude NAs)
pop_age_dist <- ds |>
  filter(!is.na(Age)) |>
  mutate(
    Age_Category = cut(
      Age,
      breaks = c(0, 30, 40, 50, 60, 70, 100),
      labels = c("18-30", "31-40", "41-50", "51-60", "61-70", "70+"),
      include.lowest = TRUE
    )
  ) |>
  filter(!is.na(Age_Category)) |>
  group_by(Age_Category) |>
  summarise(Freq = n(), .groups = "drop") |>
  as.data.frame()

pop_resident_dist <- ds |>
  group_by(Resident = ResidencyStatus) |>
  summarise(Freq = n(), .groups = "drop") |>
  as.data.frame()

cat("Population Age Distribution:\n")
print(pop_age_dist)
cat("\nPopulation Resident Distribution:\n")
print(pop_resident_dist)

cat("\nRespondents included in raking:", nrow(respondents_for_raking), "\n")

# Create survey design object (unweighted initially)
survey_design <- svydesign(
  ids = ~1, # No clustering
  data = respondents_for_raking,
  weights = ~1 # Start with equal weights
)

set.seed(12345)
# Apply raking to match population distributions
raked_design <- rake(
  survey_design,
  list(~Age_Category, ~Resident),
  list(pop_age_dist, pop_resident_dist),
  control = list(maxit = 200, epsilon = 1)
)

# Extract the raking weights
respondents_for_raking$rake_weight <- weights(raked_design)

cat("\n========================================\n")
cat("RAKING WEIGHTS SUMMARY\n")
cat("========================================\n")
cat("Number of respondents:", nrow(respondents_for_raking), "\n")
cat("Mean weight:", round(mean(respondents_for_raking$rake_weight), 4), "\n")
cat("Min weight:", round(min(respondents_for_raking$rake_weight), 4), "\n")
cat("Max weight:", round(max(respondents_for_raking$rake_weight), 4), "\n")
cat("SD weight:", round(sd(respondents_for_raking$rake_weight), 4), "\n")
cat(
  "Weight range (Max/Min ratio):",
  round(
    max(respondents_for_raking$rake_weight) /
      min(respondents_for_raking$rake_weight),
    2
  ),
  "\n"
)

# Show distribution of weights
cat("\nWeight Distribution:\n")
print(summary(respondents_for_raking$rake_weight))

# Show sample of respondents with weights
cat("\nSample of respondents with raking weights:\n")
print(respondents_for_raking[1:15, ])


# Create a clean data frame with CustomerID and rake_weight
weights_output <- respondents_for_raking |>
  select(CustomerID, rake_weight) |>
  arrange(CustomerID)

# Save to CSV file
write.csv(
  weights_output,
  file = "D:/Survey/raking_weights.csv",
  row.names = FALSE
)

cat("✓ Weights file saved successfully!\n\n")
cat("File location: D:/Survey/raking_weights.csv\n")
cat("Rows:", nrow(weights_output), "\n")
cat("Columns: CustomerID, rake_weight\n\n")

# Show first few rows
cat("Preview:\n")
print(head(weights_output, 10))

cat("\n✓ File is ready to use in your survey analysis!\n")


###############################################
## major variable comparisons
###############################################
setwd("d:/survey/analysis/responsechecks")

load("D:\\Survey\\Data\\DataAggregation1\\aggregateData_20260602.rData")

median_boot <- function(x, nboot = 2000, conf = 0.95) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(c(median = NA_real_, lower = NA_real_, upper = NA_real_))
  }
  boots <- replicate(nboot, median(sample(x, length(x), replace = TRUE)))
  alpha <- (1 - conf) / 2
  c(
    median = median(x),
    lower = as.numeric(quantile(boots, probs = alpha)),
    upper = as.numeric(quantile(boots, probs = 1 - alpha))
  )
}

op <- d %>%
  filter(surveyYear == 2025) %>%
  left_join(
    ds_comparison %>% select(CustomerID, Age_group) %>% distinct(),
    by = c("CustomerID")
  ) %>%
  select(C1Total_days, Age_group)

op %>%
  group_by(Age_group) %>%
  summarise(
    Mean_Days_Fished = mean(C1Total_days, na.rm = TRUE),
    Mean_SE = sd(C1Total_days, na.rm = TRUE) / sqrt(sum(!is.na(C1Total_days))),
    Mean_Upper_CI = Mean_Days_Fished + 1.96 * Mean_SE,
    Mean_Lower_CI = Mean_Days_Fished - 1.96 * Mean_SE,
    Median_Info = list(median_boot(C1Total_days)),
    Count = sum(!is.na(C1Total_days)),
    .groups = "drop"
  ) %>%
  unnest_wider(Median_Info, names_sep = "_") %>%
  rename(
    Median_Days_Fished = Median_Info_median,
    Median_Lower_CI = Median_Info_lower,
    Median_Upper_CI = Median_Info_upper
  ) %>%
  arrange(Age_group) %>%
  filter(!is.na(Age_group)) %>%
  ggplot(aes(x = Age_group, y = Mean_Days_Fished)) +
  geom_line(aes(color = Age_group), group = 1) +
  geom_point(aes(color = Age_group, fill = Age_group), size = 3) +
  geom_errorbar(
    aes(ymin = Mean_Lower_CI, ymax = Mean_Upper_CI, color = Age_group),
    width = 0.2
  ) +
  scale_fill_viridis_d(begin = 0, end = 0.9) +
  scale_color_viridis_d(begin = 0, end = 0.9) +
  labs(
    title = "",
    x = "Age Group",
    y = "Mean Days Fished",
    fill = "",
    color = ""
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    axis.text = element_text(size = 14),
    plot.title = element_text(size = 18, face = "bold"),
    axis.title = element_text(size = 16),
    legend.title = element_blank()
  )

ggsave(filename = "op/mean_days_fished_by_age.png", width = 8, height = 5)

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


##########################################################
###
##########################################################

# r
library(dplyr)
library(survey)
library(ggplot2)
library(tidyr)
library(rlang)
library(viridis)

# 1) recreate op by joining d -> ds for ResidencyStatus (by CustomerID)
op <- d |>
  filter(surveyYear == 2025) |>
  left_join(
    ds |> select(CustomerID, ResidencyStatus) |> distinct(),
    by = "CustomerID"
  ) |>
  # keep respondents with full motivation answers (match earlier pipeline)
  filter(
    motivation_social_AnsweredAll == TRUE,
    motivation_natural_AnsweredAll == TRUE,
    motivation_pp_AnsweredAll == TRUE,
    motivation_resource_AnsweredAll == TRUE
  ) |>
  select(
    C1Total_days,
    starts_with("attitude_"),
    starts_with("motivation_"),
    postWeight,
    ResidencyStatus
  ) |>
  mutate(
    .res_raw = tolower(trimws(as.character(ResidencyStatus))),
    ResidencyGroup = case_when(
      .res_raw %in% c("yes", "y", "resident", "1", "true", "t") ~ "Resident",
      .res_raw %in%
        c(
          "no",
          "n",
          "non-resident",
          "non resident",
          "nonresident",
          "0",
          "false",
          "f"
        ) ~ "Non-resident",
      TRUE ~ NA_character_
    ),
    ResidencyGroup = factor(
      ResidencyGroup,
      levels = c("Resident", "Non-resident")
    )
  ) |>
  select(-.res_raw)

# 2) create survey design (weights = postWeight)
design_op <- svydesign(ids = ~1, weights = ~postWeight, data = op)

# helper: compute weighted mean + 95% CI by ResidencyGroup for a variable
compute_by_res <- function(varname, design = design_op) {
  r <- svyby(
    as.formula(paste0("~", varname)),
    ~ResidencyGroup,
    design,
    svymean,
    na.rm = TRUE
  )
  df <- as.data.frame(r)
  names(df)[2:3] <- c("mean", "se")
  df |>
    mutate(
      var = varname,
      low = mean - qnorm(0.975) * se,
      high = mean + qnorm(0.975) * se
    ) |>
    select(ResidencyGroup, var, mean, se, low, high)
}

# ------------------------------
# A) Days fished — residency groups as fill; x = ResidencyGroup (single scale)
# ------------------------------
out_days <- compute_by_res("C1Total_days", design = design_op)

p_days <- ggplot(
  out_days,
  aes(x = ResidencyGroup, y = mean, fill = ResidencyGroup)
) +
  geom_col(width = 0.5, color = "black", show.legend = FALSE) +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.2) +
  theme_bw() +
  scale_fill_viridis_d(end = 0.9) +
  labs(
    title = "",
    x = "",
    y = "Days Fished"
  ) +
  theme(
    axis.text = element_text(size = 12),
    plot.title = element_text(size = 14, face = "bold")
  )

print(p_days)
ggsave("days_fished_by_residency.png", p_days, width = 6, height = 4, dpi = 300)


# B) Attitude scales — x = scale, grouped by Residency (Resident / Non-resident)
# Filter by _AnsweredAll; plot as line graph
# recreate op with attitude_*_AnsweredAll filters
op_att <- d |>
  filter(surveyYear == 2025) |>
  left_join(
    ds |> select(CustomerID, ResidencyStatus) |> distinct(),
    by = "CustomerID"
  ) |>
  filter(
    attitude_catch_AnsweredAll == TRUE,
    attitude_harvest_AnsweredAll == TRUE,
    attitude_numbers_AnsweredAll == TRUE,
    attitude_size_AnsweredAll == TRUE
  ) |>
  select(
    starts_with("attitude_") & !ends_with("AnsweredAll"),
    postWeight,
    ResidencyStatus
  ) |>
  mutate(
    .res_raw = tolower(trimws(as.character(ResidencyStatus))),
    ResidencyGroup = case_when(
      .res_raw %in% c("yes", "y", "resident", "1", "true", "t") ~ "Resident",
      .res_raw %in%
        c(
          "no",
          "n",
          "non-resident",
          "non resident",
          "nonresident",
          "0",
          "false",
          "f"
        ) ~ "Non-resident",
      TRUE ~ NA_character_
    ),
    ResidencyGroup = factor(
      ResidencyGroup,
      levels = c("Resident", "Non-resident")
    )
  ) |>
  select(-.res_raw)

# recreate design for attitude data
design_att <- svydesign(ids = ~1, weights = ~postWeight, data = op_att)

# get attitude variables (non-*_AnsweredAll)
vars_att <- names(op_att) |> grep("^attitude_", x = _, value = TRUE)

# compute weighted means by ResidencyGroup
out_att <- lapply(vars_att, function(v) {
  r <- svyby(
    as.formula(paste0("~", v)),
    ~ResidencyGroup,
    design_att,
    svymean,
    na.rm = TRUE
  )
  df <- as.data.frame(r)
  names(df)[2:3] <- c("mean", "se")
  df |>
    mutate(
      var = v,
      low = mean - qnorm(0.975) * se,
      high = mean + qnorm(0.975) * se
    ) |>
    select(ResidencyGroup, var, mean, se, low, high)
}) |>
  bind_rows()

out_att <- out_att %>%
  mutate(
    var_label = tools::toTitleCase(gsub("_", " ", gsub("^attitude_", "", var))),
    var_label = factor(var_label, levels = unique(var_label)),
    ResidencyGroup = factor(
      ResidencyGroup,
      levels = c("Resident", "Non-resident")
    )
  )

labels_att <- c(
  "Strongly disagree",
  "Disagree",
  "Neutral",
  "Agree",
  "Strongly agree"
)

p_att_scales <- ggplot(
  out_att,
  aes(x = var_label, y = mean, color = ResidencyGroup, group = ResidencyGroup)
) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = low, ymax = high),
    width = 0.2
  ) +
  scale_y_continuous(breaks = 1:5, labels = labels_att, limits = c(1, 5)) +
  theme_bw() +
  scale_color_viridis_d(end = 0.9) +
  labs(
    title = "",
    x = "",
    y = "",
    color = ""
  ) +
  theme(
    axis.text.x = element_text(angle = 25, hjust = 1),
    axis.text = element_text(size = 12),
    plot.title = element_text(size = 14, face = "bold"),
    panel.grid.major.x = element_blank()
  )

print(p_att_scales)
ggsave(
  "attitude_by_residency_scales_x.png",
  p_att_scales,
  width = 10,
  height = 5,
  dpi = 300
)

# B) Attitude scales — x = Residency, grouped by attitude scale
# Filter by _AnsweredAll; plot as line graph
op_att <- d |>
  filter(surveyYear == 2025) |>
  left_join(
    ds |> select(CustomerID, ResidencyStatus) |> distinct(),
    by = "CustomerID"
  ) |>
  filter(
    attitude_catch_AnsweredAll == TRUE,
    attitude_harvest_AnsweredAll == TRUE,
    attitude_numbers_AnsweredAll == TRUE,
    attitude_size_AnsweredAll == TRUE
  ) |>
  select(
    starts_with("attitude_") & !ends_with("AnsweredAll"),
    postWeight,
    ResidencyStatus
  ) |>
  mutate(
    .res_raw = tolower(trimws(as.character(ResidencyStatus))),
    ResidencyGroup = case_when(
      .res_raw %in% c("yes", "y", "resident", "1", "true", "t") ~ "Resident",
      .res_raw %in%
        c(
          "no",
          "n",
          "non-resident",
          "non resident",
          "nonresident",
          "0",
          "false",
          "f"
        ) ~ "Non-resident",
      TRUE ~ NA_character_
    ),
    ResidencyGroup = factor(
      ResidencyGroup,
      levels = c("Resident", "Non-resident")
    )
  ) |>
  select(-.res_raw)

design_att <- svydesign(ids = ~1, weights = ~postWeight, data = op_att)

vars_att <- names(op_att) |> grep("^attitude_", x = _, value = TRUE)

out_att <- lapply(vars_att, function(v) {
  r <- svyby(
    as.formula(paste0("~", v)),
    ~ResidencyGroup,
    design_att,
    svymean,
    na.rm = TRUE
  )
  df <- as.data.frame(r)
  names(df)[2:3] <- c("mean", "se")
  df |>
    mutate(
      var = v,
      low = mean - qnorm(0.975) * se,
      high = mean + qnorm(0.975) * se
    ) |>
    select(ResidencyGroup, var, mean, se, low, high)
}) |>
  bind_rows()

out_att <- out_att %>%
  mutate(
    var_label = tools::toTitleCase(gsub("_", " ", gsub("^attitude_", "", var))),
    var_label = factor(var_label, levels = unique(var_label)),
    ResidencyGroup = factor(
      ResidencyGroup,
      levels = c("Resident", "Non-resident")
    )
  )

labels_att <- c(
  "Strongly disagree",
  "Disagree",
  "Neutral",
  "Agree",
  "Strongly agree"
)

p_att_scales <- ggplot(
  out_att,
  aes(x = ResidencyGroup, y = mean, color = var_label, group = var_label)
) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = low, ymax = high),
    width = 0.2
  ) +
  scale_y_continuous(breaks = 1:5, labels = labels_att, limits = c(1, 5)) +
  theme_bw() +
  scale_color_viridis_d(end = 0.9) +
  labs(
    title = "Attitude scales by Residency",
    x = "Residency",
    y = "Weighted mean (agreement)",
    color = "Attitude scale"
  ) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    axis.text = element_text(size = 12),
    plot.title = element_text(size = 14, face = "bold"),
    panel.grid.major.x = element_blank()
  )

print(p_att_scales)
ggsave(
  "attitude_by_residency_scales_x.png",
  p_att_scales,
  width = 8,
  height = 5,
  dpi = 300
)

# C) Motivation scales — x = Residency, grouped by motivation scale
# Filter by _AnsweredAll; plot as line graph
op_mot <- d |>
  filter(surveyYear == 2025) |>
  left_join(
    ds |> select(CustomerID, ResidencyStatus) |> distinct(),
    by = "CustomerID"
  ) |>
  filter(
    motivation_social_AnsweredAll == TRUE,
    motivation_natural_AnsweredAll == TRUE,
    motivation_pp_AnsweredAll == TRUE,
    motivation_resource_AnsweredAll == TRUE
  ) |>
  select(
    motivation_social,
    motivation_natural,
    motivation_pp,
    motivation_resource,
    postWeight,
    ResidencyStatus
  ) |>
  mutate(
    .res_raw = tolower(trimws(as.character(ResidencyStatus))),
    ResidencyGroup = case_when(
      .res_raw %in% c("yes", "y", "resident", "1", "true", "t") ~ "Resident",
      .res_raw %in%
        c(
          "no",
          "n",
          "non-resident",
          "non resident",
          "nonresident",
          "0",
          "false",
          "f"
        ) ~ "Non-resident",
      TRUE ~ NA_character_
    ),
    ResidencyGroup = factor(
      ResidencyGroup,
      levels = c("Resident", "Non-resident")
    )
  ) |>
  select(-.res_raw)

design_mot <- svydesign(ids = ~1, weights = ~postWeight, data = op_mot)

vars_mot <- c(
  "motivation_natural",
  "motivation_pp",
  "motivation_resource",
  "motivation_social"
)

out_mot <- lapply(vars_mot, function(v) {
  r <- svyby(
    as.formula(paste0("~", v)),
    ~ResidencyGroup,
    design_mot,
    svymean,
    na.rm = TRUE
  )
  df <- as.data.frame(r)
  names(df)[2:3] <- c("mean", "se")
  df |>
    mutate(
      var = v,
      low = mean - qnorm(0.975) * se,
      high = mean + qnorm(0.975) * se
    ) |>
    select(ResidencyGroup, var, mean, se, low, high)
}) |>
  bind_rows()

out_mot <- out_mot |>
  mutate(
    var_label = case_when(
      var == "motivation_natural" ~ "Natural Environment",
      var == "motivation_pp" ~ "Psychological/Physical",
      var == "motivation_resource" ~ "Fishery Research",
      var == "motivation_social" ~ "Social",
      TRUE ~ gsub("^motivation_", "", var)
    ),
    var_label = factor(
      var_label,
      levels = c(
        "Natural Environment",
        "Psychological/Physical",
        "Fishery Research",
        "Social"
      )
    ),
    ResidencyGroup = factor(
      ResidencyGroup,
      levels = c("Resident", "Non-resident")
    )
  )

labels_mot <- c(
  "Not at all important",
  "Slightly important",
  "Moderately important",
  "Very important",
  "Extremely important"
)

p_mot_scales <- ggplot(
  out_mot,
  aes(x = ResidencyGroup, y = mean, color = var_label, group = var_label)
) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = low, ymax = high),
    width = 0.2
  ) +
  scale_y_continuous(breaks = 1:5, labels = labels_mot, limits = c(1, 5)) +
  theme_bw() +
  scale_color_viridis_d(end = 0.9) +
  labs(
    title = "",
    x = "",
    y = "",
    color = ""
  ) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    axis.text = element_text(size = 12),
    plot.title = element_text(size = 14, face = "bold"),
    panel.grid.major.x = element_blank()
  )

print(p_mot_scales)
ggsave(
  "motivation_by_residency_scales_x.png",
  p_mot_scales,
  width = 8,
  height = 5,
  dpi = 300
)
