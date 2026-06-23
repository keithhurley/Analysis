# BaseFunctions_2025_UPDATED.R - Version with pre-calculated weights
# These functions have been updated to work with postWeight column
# that is pre-calculated during data preprocessing

library(tidyverse)
library(survey)
library(foreach)

# ============================================================================
# FUNCTION 1: base.summary.rake.loop
# ============================================================================
# Simplified pass-through function - weights are pre-calculated in postWeight column
# This maintains backward compatibility with existing code

base.summary.rake.loop <- function(myData, myRakeVars, myPopDists) {
  # With weights now pre-calculated and stored in the postWeight column,
  # this function is simplified to a pass-through for backward compatibility.
  # The actual raking/weighting was performed during data preprocessing.
  return(myData)
}

# ============================================================================
# FUNCTION 2: base.loaddata
# ============================================================================

base.loaddata <- function(myYears, myVenues, includeComments = FALSE) {
  mydata <- read.csv("../../Data/surveyData_20180116.csv")

  if (2018 %in% myYears) {
    op <- base.getBosrData()
    mydata <- bind_rows(op, mydata)
  }

  mydata <- mydata %>%
    filter(surveyYear %in% myYears) %>%
    filter(venue %in% myVenues)

  myAngData <- read.csv(file = "../../Data/Anglers.csv") %>%
    select(ID, "wgs84_X" = X, "wgs84_Y" = Y) %>%
    right_join(mydata, by = c("ID" = "licenseUID"))

  if (includeComments == FALSE) {
    mydata <- mydata %>% dplyr::select(-F2, -F3)
  }

  # NOTE: The following functions were deleted as they are no longer needed
  # mydata <- base.data.corrections(mydata, myYears)
  # mydata <- base.create.aggregate.variables(mydata, myYears)
  # mydata <- base.data.createFactors(mydata)

  return(mydata)
}

# ============================================================================
# FUNCTION 3: base.loaddata.factorlevels
# ============================================================================

base.loaddata.factorlevels <- function() {
  factorData <- read.csv(file = "..\\..\\Data\\FactorLevels.csv", header = TRUE)
  return(factorData)
}

# ============================================================================
# FUNCTION 4: base.cancelRake
# ============================================================================

base.cancelRake <- function() {
  rakeVars_bkup <<- rakeVars
  rakeVars <<- data.frame(surveyYear = c(0001), rakeVar = c("age_group"))
}

# ============================================================================
# FUNCTION 5: base.restoreRake
# ============================================================================

base.restoreRake <- function() {
  rakeVars <<- rakeVars_bkup
}

# ============================================================================
# FUNCTION 6: base.summary.percent.selectOne
# ============================================================================
# UPDATED: Now uses pre-calculated postWeight instead of calling base.summary.rake

base.summary.percent.selectOne <- function(
  mydata,
  myQuestion,
  myGroupVar = NA
) {
  #enquo arguments
  myQuestion <- enquo(myQuestion)
  myGroupVar <- enquo(myGroupVar)

  #get initial data...include grouping variable if passed.
  if (!is.na(quo_name(myGroupVar))) {
    qData <- mydata %>%
      mutate(group = !!myGroupVar) %>%
      select(surveyYear, !!myQuestion, group, postWeight)
  } else {
    qData <- mydata %>%
      select(surveyYear, !!myQuestion, postWeight) %>%
      mutate(group = "Overall")
  }

  #filter for NAs
  qData <- qData %>%
    filter(!is.na(!!myQuestion)) %>%
    filter(!is.na(group))

  # postWeight is pre-calculated in the dataset
  # Ensure it exists; if not, use unweighted approach (weight = 1)
  if (!"postWeight" %in% names(qData)) {
    qData$postWeight <- 1
  }

  #calculate total weighted responses and summarise by group
  qData <- qData %>%
    select(surveyYear, group, response = !!myQuestion, postWeight) %>%
    group_by(surveyYear, group, response) %>%
    summarise(
      num = sum(postWeight, na.rm = TRUE),
      numRespondents = n(),
      .groups = "drop_last"
    ) %>%
    mutate(
      totNum = sum(num, na.rm = TRUE),
      totRespondents = sum(numRespondents, na.rm = TRUE)
    ) %>%
    mutate(perc = num / totNum * 100) %>%
    mutate(
      ci = round(
        (1.96 * (sqrt((perc / 100) * (1 - (perc / 100)) / totNum))) *
          100,
        4
      )
    ) %>%
    dplyr::select(
      Year = surveyYear,
      Group = group,
      Response = response,
      Value = perc,
      CI = ci,
      Number = numRespondents
    )

  return(qData %>% ungroup())
}

# ============================================================================
# FUNCTION 7: base.summary.percent.selectAll
# ============================================================================
# UPDATED: Now uses pre-calculated postWeight, removed raking call

base.summary.percent.selectAll <- function(
  mydata,
  myQuestions,
  myAnsweredVar,
  myGroupVar = NA
) {
  #enquo arguments
  myQuestion <- enquo(myQuestions)
  myAnsweredVar <- enquo(myAnsweredVar)
  myGroupVar <- enquo(myGroupVar)

  #get initial data...include grouping variable if passed.
  if (!is.na(quo_name(myGroupVar))) {
    qData <- mydata %>%
      filter(!!myAnsweredVar == TRUE) %>%
      select(
        surveyYear,
        group = !!quo_name(myGroupVar),
        !!myQuestion,
        postWeight
      )
  } else {
    qData <- mydata %>%
      filter(!!myAnsweredVar == TRUE) %>%
      mutate(group = "Overall") %>%
      select(surveyYear, group, !!myQuestion, postWeight)
  }

  #filter for NA's
  qData <- qData %>%
    filter(!is.na(group))

  # postWeight is pre-calculated in the dataset
  # Ensure it exists; if not, use unweighted approach
  if (!"postWeight" %in% names(qData)) {
    qData$postWeight <- 1
  }

  # Summarize by group and response using postWeight
  qData <- qData %>%
    pivot_longer(
      cols = -c(surveyYear, group, postWeight),
      names_to = "variable",
      values_to = "value"
    ) %>%
    filter(!is.na(value)) %>%
    group_by(surveyYear, group, variable, value) %>%
    summarise(
      num = sum(postWeight, na.rm = TRUE),
      numRespondents = n(),
      .groups = "drop_last"
    ) %>%
    mutate(totNum = sum(num, na.rm = TRUE)) %>%
    mutate(perc = num / totNum * 100) %>%
    mutate(
      ci = round(
        (1.96 * (sqrt((perc / 100) * (1 - (perc / 100)) / totNum))) *
          100,
        4
      )
    ) %>%
    ungroup() %>%
    filter(trimws(as.character(value)) != "Unchecked") %>%
    mutate(Response = as.character(value)) %>%
    group_by(Response) %>%
    mutate(
      Response = if (n_distinct(variable) > 1) {
        paste0(Response, " (", variable, ")")
      } else {
        Response
      }
    ) %>%
    ungroup() %>%
    dplyr::select(
      Year = surveyYear,
      Group = group,
      Response,
      Value = perc,
      CI = ci,
      Number = numRespondents
    )

  return(qData %>% ungroup())
}

# ============================================================================
# FUNCTION 8: base.summary.means
# ============================================================================
# UPDATED: Now uses pre-calculated postWeight instead of raking

base.summary.means <- function(
  mydata,
  myQuestion,
  myGroupVar = NA
) {
  #enquo arguments
  myQuestion <- enquo(myQuestion)
  myGroupVar <- enquo(myGroupVar)

  #get initial data...include grouping variable if passed.
  if (!is.na(quo_name(myGroupVar))) {
    qData <- mydata %>%
      mutate(group = !!myGroupVar) %>%
      select(surveyYear, !!myQuestion, group, postWeight)
  } else {
    qData <- mydata %>%
      select(surveyYear, !!myQuestion, postWeight) %>%
      mutate(group = "Overall")
  }

  #filter for NAs
  qData <- qData %>%
    filter(!is.na(!!myQuestion)) %>%
    filter(!is.na(group))

  # postWeight is pre-calculated in the dataset
  # Ensure it exists; if not, use unweighted approach
  if (!"postWeight" %in% names(qData)) {
    qData$postWeight <- 1
  }

  # Calculate weighted mean by group
  qData <- qData %>%
    mutate(!!quo_name(myQuestion) := as.numeric(!!myQuestion)) %>%
    select(surveyYear, group, value = !!myQuestion, postWeight) %>%
    group_by(surveyYear, group) %>%
    summarise(
      mean = weighted.mean(value, w = postWeight, na.rm = TRUE),
      sd = sqrt(sum(
        (postWeight / sum(postWeight)) *
          (value - weighted.mean(value, w = postWeight, na.rm = TRUE))^2,
        na.rm = TRUE
      )),
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(
      se = sd / sqrt(n),
      ci = round(1.96 * se, 4)
    ) %>%
    dplyr::select(
      Year = surveyYear,
      Group = group,
      Value = mean,
      CI = ci,
      Number = n
    ) %>%
    mutate(Response = quo_name(myQuestion))

  return(qData)
}

# ============================================================================
# FUNCTION 9: base.summary.medians
# ============================================================================
# UPDATED: Now uses pre-calculated postWeight and weighted.quantile function

base.summary.medians <- function(
  mydata,
  myQuestion,
  myGroupVar = NA
) {
  #enquo arguments
  myQuestion <- enquo(myQuestion)
  myGroupVar <- enquo(myGroupVar)

  #get initial data...include grouping variable if passed.
  if (!is.na(quo_name(myGroupVar))) {
    qData <- mydata %>%
      mutate(group = !!myGroupVar) %>%
      select(surveyYear, !!myQuestion, group, postWeight)
  } else {
    qData <- mydata %>%
      select(surveyYear, !!myQuestion, postWeight) %>%
      mutate(group = "Overall")
  }

  #filter for NAs
  qData <- qData %>%
    filter(!is.na(!!myQuestion)) %>%
    filter(!is.na(group))

  # postWeight is pre-calculated in the dataset
  # Ensure it exists; if not, use unweighted approach
  if (!"postWeight" %in% names(qData)) {
    qData$postWeight <- 1
  }

  # Calculate weighted median and quartiles by group using weighted.quantile
  qData <- qData %>%
    mutate(!!quo_name(myQuestion) := as.numeric(!!myQuestion)) %>%
    select(surveyYear, group, value = !!myQuestion, postWeight) %>%
    group_by(surveyYear, group) %>%
    summarise(
      q1 = weighted.quantile(value, w = postWeight, probs = 0.25, na.rm = TRUE),
      median = weighted.quantile(
        value,
        w = postWeight,
        probs = 0.5,
        na.rm = TRUE
      ),
      q3 = weighted.quantile(value, w = postWeight, probs = 0.75, na.rm = TRUE),
      min = min(value, na.rm = TRUE),
      max = max(value, na.rm = TRUE),
      n = n(),
      .groups = "drop"
    ) %>%
    dplyr::select(
      Year = surveyYear,
      Group = group,
      Q1 = q1,
      Median = median,
      Q3 = q3,
      Min = min,
      Max = max,
      N = n
    ) %>%
    mutate(Response = quo_name(myQuestion))

  return(qData)
}

# ============================================================================
# FUNCTION 10: weighted.quantile (HELPER FUNCTION - KEEP)
# ============================================================================
# This helper function calculates weighted quantiles and is used by base.summary.medians

weighted.quantile <- function(x, w, probs = c(0.25, 0.5, 0.75), na.rm = TRUE) {
  if (missing(w)) {
    w <- rep(1, length(x))
  }

  if (na.rm) {
    mask <- !is.na(x) & !is.na(w)
    x <- x[mask]
    w <- w[mask]
  }

  ord <- order(x)
  x <- x[ord]
  w <- w[ord]

  # Normalize weights to sum to 1
  w <- w / sum(w, na.rm = TRUE)

  # Calculate cumulative weights
  Fx <- cumsum(w)

  # Calculate quantiles
  result <- numeric(length(probs))
  for (i in 1:length(probs)) {
    p <- probs[i]
    if (p < 0 || p > 1) {
      result[i] <- NA
    } else {
      left <- max(which(Fx <= p))
      if (length(left) == 0) {
        result[i] <- x[1]
      } else if (Fx[left] == p) {
        result[i] <- x[left]
      } else {
        right <- left + 1
        if (right > length(x)) {
          result[i] <- x[length(x)]
        } else {
          y <- x[left] +
            (x[right] - x[left]) * (p - Fx[left]) / (Fx[right] - Fx[left])
          if (is.finite(y)) result[i] <- y
        }
      }
    }
  }

  names(result) <- paste0(format(100 * probs, trim = TRUE), "%")
  return(result)
}

# Create Function to get question text ------------------------------------
GetQuestion <- function(myQuestionFactors, myField, myYear) {
  myField <- enquo(myField)

  if (rlang::quo_text(myField) %in% c("C2", "E1", "D14", "D3", "D4")) {
    switch(
      rlang::quo_text(myField),
      C2 = {
        op <- "Indicate the importance for each item as a reason why you fish."
      },
      E1 = {
        op <- "Indicate how much you agree with each of the following statements about fishing."
      },
      D14 = {
        op <- "Thinking about your fishing in Nebraska during 2018, how often are each of the following statements true?"
      },
      D3 = {
        op <- "Please complete the following statements."
      },
      D4 = {
        op <- "Thinking about the one type of fish that you prefer to fish for, how much do you agree or disagree with the following about your fishing in Nebraska during 2018?."
      }
    )
  } else {
    op <- myQuestionFactors %>%
      filter(str_detect(.$Field, rlang::quo_text(myField)) & Year == myYear) %>%
      pull(Question) %>%
      unique() %>%
      as.character()
  }

  return(op[1])
}

# ============================================================================
# FUNCTION: add_scale_scores
# ============================================================================
# Build subscale score columns from RAW (unreversed) item factors, reversing
# any item flagged Reversed == TRUE in Scales.csv before averaging. Recreates
# each subscale existing variable name (VarName) plus a <VarName>_AnsweredAll
# completeness flag, so the existing means/medians/CI table functions consume
# correctly-reversed scores without further changes.
#
# Reversal uses each item number of response levels: for a k-level item, a
# stored code v becomes (k + 1) - v. For factor columns k is nlevels(); for
# numeric columns k falls back to the observed maximum.
add_scale_scores <- function(
  mydata,
  scalesFile = "../../Data/DataAggregation1/Scales.csv"
) {
  scales <- read.csv(scalesFile, stringsAsFactors = FALSE)
  scales$Reversed <- as.logical(scales$Reversed)

  for (vn in unique(scales$VarName)) {
    defn    <- scales[scales$VarName == vn, ]
    fields  <- defn$Field
    revFlds <- defn$Field[defn$Reversed]

    present <- fields[fields %in% names(mydata)]
    if (length(present) == 0) {
      warning(sprintf("Scale %s: no item columns present; skipped.", vn))
      next
    }
    if (!setequal(present, fields)) {
      warning(sprintf(
        "Scale %s: missing item columns: %s",
        vn,
        paste(setdiff(fields, present), collapse = ", ")
      ))
    }

    num <- as.data.frame(lapply(present, function(f) {
      x <- mydata[[f]]
      v <- suppressWarnings(as.numeric(x))
      if (f %in% revFlds) {
        k <- if (is.factor(x)) nlevels(x) else max(v, na.rm = TRUE)
        v <- (k + 1) - v
      }
      v
    }))
    names(num) <- present

    answeredAll <- rowSums(is.na(num)) == 0
    mydata[[paste0(vn, "_AnsweredAll")]] <- answeredAll
    mydata[[vn]] <- ifelse(answeredAll, rowMeans(num, na.rm = TRUE), NA_real_)
  }

  mydata
}

# ============================================================================
# FUNCTION: scale_reversed_items / ReversedItemsNote
# ============================================================================
# Return reverse-scored item codes for a scale, subscale, or variable name,
# for use in scale-table header text. scope is matched against ScaleName,
# SubScaleName, and VarName.
scale_reversed_items <- function(
  scope,
  scalesFile = "../../Data/DataAggregation1/Scales.csv",
  collapse = ", "
) {
  scales <- read.csv(scalesFile, stringsAsFactors = FALSE)
  scales$Reversed <- as.logical(scales$Reversed)
  hits <- scales[
    scales$ScaleName %in% scope |
      scales$SubScaleName %in% scope |
      scales$VarName %in% scope,
  ]
  paste(unique(hits$Field[hits$Reversed]), collapse = collapse)
}

# Formatted note for table headers. Returns "" (or none) when nothing reversed.
ReversedItemsNote <- function(
  scope,
  scalesFile = "../../Data/DataAggregation1/Scales.csv",
  prefix = "Reverse-scored items: ",
  none = ""
) {
  items <- scale_reversed_items(scope, scalesFile)
  if (nchar(items) == 0) {
    return(none)
  }
  paste0(prefix, items)
}

# ============================================================================
# END OF FILE
# ============================================================================
