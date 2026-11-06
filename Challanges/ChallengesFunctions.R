# Challenges report functions
# Table/caption helpers specific to the Challenges report go here.
# Shared caption text, labels, and CreateTableA_/CreateTableB_ builders are
# inherited from CrossTabTableFunctions.R (sourced read-only in the .rmd).

options(stringsAsFactors = FALSE)
library(dplyr)
library(tidyr)
library(foreach)
library(ggplot2)

# Report-specific captions -------------------------------------------------
caption.waterbody <-
  "Breakdown is by type of water body fished during 2025 (not mutually exclusive; respondents who fished more than one water body type appear in more than one column)."
caption.urbanrural <-
  "Urban/Rural is determined by the respondent's home ZIP code."
caption.gatedA12 <-
  "Restricted to respondents who reported fishing in a state other than Nebraska during the given year. A small number of respondents answered this question despite reporting that they had not fished out of state (or left that question blank); those responses were treated as missing for this report."
caption.gatedA3 <-
  "Restricted to respondents who reported that they did NOT fish in Nebraska during 2025. A small number of respondents answered this question despite reporting that they did fish; those responses were treated as missing for this report."

# Derived variables ---------------------------------------------------------

# Urban/Rural label from the existing `urban` (logical, ZIP-based) column.
AddUrbanRural <- function(mydata) {
  mydata %>%
    mutate(
      UrbanRural = factor(
        ifelse(is.na(urban), NA, ifelse(urban, "Urban", "Rural")),
        levels = c("Urban", "Rural")
      )
    )
}

# Non-exclusive waterbody-type group columns from the A4 checkbox battery.
# Each column is NA unless the respondent checked that type, matching the
# pattern base.summary.percent.selectAll uses to build Table A/B breakdowns.
AddWaterbodyGroups <- function(mydata) {
  mydata %>%
    mutate(
      WB_LakesReservoirs = ifelse(
        trimws(as.character(A4lr)) == "Unchecked" | is.na(A4lr),
        NA,
        "Lakes and Reservoirs"
      ),
      WB_PondsSandpits = ifelse(
        trimws(as.character(A4pond)) == "Unchecked" | is.na(A4pond),
        NA,
        "Ponds and Sandpits"
      ),
      WB_RiversStreamsCanals = ifelse(
        trimws(as.character(A4riv)) == "Unchecked" | is.na(A4riv),
        NA,
        "Rivers, Streams, and Canals"
      ),
      WB_SandhillLakes = ifelse(
        trimws(as.character(A4sand)) == "Unchecked" | is.na(A4sand),
        NA,
        "Sandhill Lakes"
      )
    )
}

waterbody.group.levels <- c(
  "Lakes and Reservoirs",
  "Ponds and Sandpits",
  "Rivers, Streams, and Canals",
  "Sandhill Lakes"
)

# A12 (brought a boat/watercraft out of state) is only meaningful among
# respondents who said Yes to A11 (fished out of state). A small number of
# respondents answered A12 despite A11 = No/NA (skip-pattern noise); those are
# set to NA here rather than silently included. Documented in the report text.
GateA12 <- function(mydata) {
  mydata %>%
    mutate(
      A12_gated = factor(
        ifelse(!is.na(A11) & A11 == "Yes", as.character(A12), NA),
        levels = levels(A12)
      )
    )
}

# A3 (main reason didn't fish) is only meaningful among respondents who said
# No to A2 (did you fish in Nebraska). A small number answered A3 despite
# A2 = Yes; those are set to NA here. Documented in the report text.
GateA3 <- function(mydata) {
  mydata %>%
    mutate(
      A3_gated = factor(
        ifelse(!is.na(A2) & A2 == "No", as.character(A3), NA),
        levels = levels(A3)
      )
    )
}

# Generic table arranger for non-standard group sets (waterbody type,
# urban/rural) that ArrangeTableA/B (hard-coded to Resi/E2/E3 levels) don't
# cover. Mirrors their CI-formatting logic.
ArrangeTableGeneric <- function(
  myData,
  groupLevels,
  roundDigits = 1,
  ordered = FALSE
) {
  myData <- myData %>%
    mutate(
      Value = round(Value, roundDigits),
      CI = round(CI, roundDigits)
    ) %>%
    mutate(text = paste(Value, "+-", CI, " (", Number, ")", sep = "")) %>%
    select(Response, Group, text, Year) %>%
    distinct() %>%
    spread(Group, text) %>%
    select(-Year)

  # Yes/No response categories always display Yes first, No second.
  respKey <- trimws(tolower(as.character(myData$Response)))
  if (setequal(respKey, c("yes", "no"))) {
    myData <- myData %>%
      mutate(.order = match(respKey, c("yes", "no"))) %>%
      arrange(.order) %>%
      select(-.order)
  }

  myData <- myData %>%
    select(Response, any_of(groupLevels))

  if (ncol(myData) > 1 && nrow(myData) > 0) {
    myData[, 2:ncol(myData)] <- lapply(
      myData[, 2:ncol(myData), drop = FALSE],
      function(x) ifelse(is.na(x), "", x)
    )
  }

  myData
}

# Table C: breakdown by waterbody type fished (2025 only; requires the
# respondent to have fished and reported a waterbody type).
CreateTableC_waterbody_selectOne_percent <- function(
  myData,
  myQuestion,
  ordered = FALSE
) {
  myQuestion <- enquo(myQuestion)
  wbVars <- c(
    "WB_LakesReservoirs",
    "WB_PondsSandpits",
    "WB_RiversStreamsCanals",
    "WB_SandhillLakes"
  )

  op <- foreach(v = wbVars, .combine = "rbind") %do%
    {
      base.summary.percent.selectOne(
        myData,
        !!myQuestion,
        myGroupVar = !!rlang::sym(v)
      )
    }

  ArrangeTableGeneric(
    op,
    groupLevels = waterbody.group.levels,
    ordered = ordered
  )
}

# Table D: breakdown by urban/rural home ZIP code.
CreateTableD_urbanrural_selectOne_percent <- function(
  myData,
  myQuestion,
  ordered = FALSE
) {
  myQuestion <- enquo(myQuestion)
  op <- base.summary.percent.selectOne(
    myData,
    !!myQuestion,
    myGroupVar = UrbanRural
  )
  ArrangeTableGeneric(op, groupLevels = c("Urban", "Rural"), ordered = ordered)
}

# Narrative helper: pull a single weighted estimate (with CI and N) out of a
# long-format base.summary.percent.selectOne() result for inline reporting.
FmtPct <- function(df, response, group = "Overall", digits = 1) {
  row <- df %>%
    filter(
      trimws(as.character(Response)) == trimws(response),
      trimws(as.character(Group)) == trimws(group)
    )
  if (nrow(row) == 0) {
    return(NA_character_)
  }
  sprintf(
    paste0("%.", digits, "f%% (\u00b1%.", digits, "f, n=%d)"),
    row$Value[1],
    row$CI[1],
    row$Number[1]
  )
}

# Plots -----------------------------------------------------------------

# Weighted percent by response category, stacked by group (e.g. age, waterbody
# type). Built directly from base.summary.percent.selectOne() output
# (Year/Group/Response/Value/CI/Number), so weighting matches the tables
# exactly. No error bars: with segments stacked, a whisker on one segment
# reflects only that segment's own CI and not the others it's stacked on top
# of, which reads as more precise than it is; the CI for each segment is
# reported in the accompanying table and text instead.
CreateStackedPercPlot <- function(
  mydata,
  groupLevels = NULL,
  responseLevels = NULL,
  label_y = "Percent of Respondents",
  label_x = NULL
) {
  op <- mydata
  if (!is.null(groupLevels)) {
    op <- op %>%
      filter(Group %in% groupLevels) %>%
      mutate(Group = factor(Group, levels = groupLevels))
  }
  if (!is.null(responseLevels)) {
    op <- op %>%
      filter(Response %in% responseLevels) %>%
      mutate(Response = factor(Response, levels = responseLevels))
  }

  ggplot(op, aes(x = Group, y = Value, fill = Response)) +
    geom_col(position = position_stack(reverse = TRUE)) +
    scale_fill_viridis_d(begin = 0.1, end = 0.9) +
    labs(y = label_y, x = label_x, fill = NULL) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      axis.text.x = element_text(angle = 30, hjust = 1)
    )
}

# Weighted percent by response category, with 95% CI error bars, faceted by
# group (e.g. age). Built directly from base.summary.percent.selectOne()
# output (Year/Group/Response/Value/CI/Number), so weighting and variance
# (Kish-effective-N CI) match the tables exactly.
CreateGroupedPercPlot <- function(
  mydata,
  groupLevels = NULL,
  label_y = "Percent of Respondents",
  label_x = NULL
) {
  op <- mydata
  if (!is.null(groupLevels)) {
    op <- op %>%
      filter(Group %in% groupLevels) %>%
      mutate(Group = factor(Group, levels = groupLevels))
  }

  ggplot(op, aes(x = Group, y = Value, fill = Group)) +
    geom_col() +
    geom_errorbar(
      aes(ymin = pmax(Value - CI, 0), ymax = Value + CI),
      width = 0.3
    ) +
    facet_wrap(~Response) +
    scale_fill_viridis_d(begin = 0.3, end = 0.8) +
    labs(y = label_y, x = label_x) +
    theme_minimal() +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 30, hjust = 1)
    )
}

# Weighted percent trend across survey years for a single response category,
# with 95% CI error bars/ribbon.
CreateYearTrendPlot <- function(mydata, label_y = "Percent of Respondents") {
  ggplot(mydata, aes(x = Year, y = Value)) +
    geom_line(linewidth = 1.2, color = viridis::viridis(1, begin = 0.3)) +
    geom_point(size = 3, color = viridis::viridis(1, begin = 0.3)) +
    geom_errorbar(
      aes(ymin = pmax(Value - CI, 0), ymax = Value + CI),
      width = 1
    ) +
    labs(y = label_y, x = "Survey Year") +
    theme_minimal()
}
