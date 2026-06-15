summarise(
      num            = sum(postWeight, na.rm = TRUE),
      numRespondents = n(),
      .groups = "drop_last"
    ) %>%
    mutate(
      totNum         = sum(num, na.rm = TRUE),
      totRespondents = sum(numRespondents, na.rm = TRUE)
    ) %>%
    mutate(perc = num / totNum * 100) %>%
    mutate(
      ci = round(
        (1.96 * (sqrt((perc / 100) * (1 - (perc / 100)) / totRespondents))) * 100,
        4
      )
    ) %>%
    dplyr::select(
      Year     = surveyYear,
      Group    = group,
      Response = response,
      Value    = perc,
      CI       = ci,
      Number   = totRespondents
    )

  return(qData %>% ungroup())
}

# ============================================================================
# FUNCTION 7:with existing code

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

# FUNCTION 4: base.cancelRake
# ============================================================================

base.cancelRake <- function() {
  # No operation needed - weights are pre-calculated in postWeight column
  # This function is kept for backward compatibility with existing reports
  invisible(NULL)
}

# ============================================================================
# FUNCTION 5: base.restoreRake
# ============================================================================

base.restoreRake <- function() {
  # No operation needed - weights are pre-calculated in postWeight column
  # This function is kept for backward compatibility with existing reports
  invisible(NULL)
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
    summarise(num = sum(postWeight, na.rm = TRUE), .groups = "drop_last") %>%
    mutate(totNum = sum(num, na.rm = TRUE)) %>%
    mutate(perc = num / totNum * 100) %>%
    mutate(
      ci = round(
        (1.96 * (sqrt((perc / 100) * (1 - (perc / 100)) / totNum))) * 100,
        4
      ),
      num = ceiling(num)
    ) %>%
    dplyr::select(
      Year = surveyYear,
      Group = group,
      Response = response,
      Value = perc,
      CI = ci,
      Number = num
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
  # Capture raw respondent counts per group before pivot
  groupCounts <- qData %>%
    group_by(surveyYear, group) %>%
    summarise(totRespondents = n(), .groups = "drop")

  qData <- qData %>%
    pivot_longer(
      cols = -c(surveyYear, group, postWeight),
      names_to = "variable",
      values_to = "value"
    ) %>%
    filter(!is.na(value)) %>%
    group_by(surveyYear, group, variable, value) %>%
    summarise(num = sum(postWeight, na.rm = TRUE), .groups = "drop_last") %>%
    mutate(totNum = sum(num, na.rm = TRUE)) %>%
    mutate(perc = num / totNum * 100) %>%
    left_join(groupCounts, by = c("surveyYear", "group")) %>%
    mutate(
      ci = round(
        (1.96 * (sqrt((perc / 100) * (1 - (perc / 100)) / totRespondents))) * 100,
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
      Year     = surveyYear,
      Group    = group,
      Response,
      Value    = perc,
      CI       = ci,
      Number   = totRespondents
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
    mutate(Response = quo_name(myQuestion)) %>%
    dplyr::select(
      Year = surveyYear,
      Group = group,
      Response,
      Value = mean,
      CI = ci,
      Number = n
    )

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
    mutate(Response = rlang::quo_name(myQuestion))

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
# END OF FILE
# ============================================================================
