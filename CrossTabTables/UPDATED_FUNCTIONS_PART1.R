base.summary.rake.loop <- function(myData, myRakeVars, myPopDists) {
  # With weights now pre-calculated and stored in the postWeight column,
  # this function is simplified to a pass-through for backward compatibility.
  # The actual raking/weighting was performed during data preprocessing.
  return(myData)
}



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
