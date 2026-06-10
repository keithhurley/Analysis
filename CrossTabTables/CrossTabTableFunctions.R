# Arrange Tables - takes calculations and lays out table in a dataframe ------
ArrangeTableA <- function(myData, roundDigits = 1, ordered = FALSE) {
  if ("CI" %in% names(myData)) {
    myData <- myData %>%
      mutate(
        Value = round(Value, roundDigits),
        CI = round(CI, roundDigits + 1)
      ) %>%
      mutate(text = paste(Value, "+-", CI, " (", Number, ")", sep = "")) %>%
      select(Response, Group, text, Year) %>%
      distinct() %>%
      spread(Group, text) %>%
      select(-Year)
  } else if ("CIupper" %in% names(myData)) {
    myData <- myData %>%
      mutate(
        Value = round(Value, roundDigits),
        CIupper = round(CIupper, roundDigits),
        CIlower = round(CIlower, roundDigits + 1)
      ) %>%
      mutate(
        text = paste(
          CIlower,
          "/",
          Value,
          "/",
          CIupper,
          " (",
          Number,
          ")",
          sep = ""
        )
      ) %>%
      select(Response, Group, text, Year) %>%
      distinct() %>%
      spread(Group, text) %>%
      select(-Year)
  }

  if (ordered == TRUE) {
    myData <- myData %>%
      separate(Overall, c("val", "deleteMe"), sep = "\\+-", remove = FALSE) %>%
      mutate(val = as.numeric(val)) %>%
      arrange(-val) %>%
      select(-val, -deleteMe)
  }

  myData <- myData %>%
    select(
      Response,
      any_of(c("Overall", "Resident", "Non-Resident", "Male", "Female"))
    )

  # remove NA
  myData[, 2:ncol(myData)] <-
    lapply(myData[, 2:ncol(myData)], function(x) {
      ifelse(is.na(x), "", x)
    })

  return(myData)
}

ArrangeTableB <- function(myData, roundDigits = 1, ordered = FALSE) {
  if ("CI" %in% names(myData)) {
    myData <- myData %>%
      mutate(
        Value = round(Value, roundDigits),
        CI = round(CI, roundDigits + 1)
      ) %>%
      mutate(text = paste(Value, "+-", CI, " (", Number, ")", sep = "")) %>%
      select(Response, Group, text, Year) %>%
      distinct() %>%
      spread(Group, text) %>%
      select(-Year)
  } else if ("CIupper" %in% names(myData)) {
    myData <- myData %>%
      mutate(
        Value = round(Value, roundDigits),
        CIupper = round(CIupper, roundDigits + 1),
        CIlower = round(CIlower, roundDigits + 1)
      ) %>%
      mutate(
        text = paste(
          CIlower,
          "/",
          Value,
          "/",
          CIupper,
          " (",
          Number,
          ")",
          sep = ""
        )
      ) %>%
      select(Response, Group, text, Year) %>%
      distinct() %>%
      spread(Group, text) %>%
      select(-Year)
  }

  if (ordered == TRUE) {
    myData <- myData %>%
      separate(Overall, c("val", "deleteMe"), sep = "\\+-", remove = FALSE) %>%
      mutate(val = as.numeric(val)) %>%
      arrange(-val) %>%
      select(-val, -deleteMe, -Overall)
  }

  # select proper columns
  myData <- myData %>%
    select(
      Response,
      any_of(c(
        "16-24",
        "25-34",
        "35-44",
        "45-54",
        "55-64",
        "65+",
        "65 and older"
      ))
    )

  return(myData)
}

# Create tables for select one questions --------------------------------------

CreateTableA_selectOne_percent <- function(
  myData,
  myQuestion,
  ordered = FALSE
) {
  myQuestion <- enquo(myQuestion)

  #get results
  op <-
    base.summary.percent.selectOne(myData, !!myQuestion, myGroupVar = NA)
  op <-
    rbind(
      op,
      base.summary.percent.selectOne(myData, !!myQuestion, myGroupVar = Resi)
    )
  op <-
    rbind(
      op,
      base.summary.percent.selectOne(myData, !!myQuestion, myGroupVar = E2)
    )

  #create table
  op <- ArrangeTableA(op, ordered = ordered)

  return(op)
}

CreateTableB_selectOne_percent <- function(
  myData,
  myQuestion,
  ordered = FALSE
) {
  myQuestion <- enquo(myQuestion)

  #get results
  op <- base.summary.percent.selectOne(myData, !!myQuestion, myGroupVar = E3)

  if (ordered == TRUE) {
    op <- rbind(
      op,
      base.summary.percent.selectOne(myData, !!myQuestion, myGroupVar = NA)
    )
  }

  #create table
  op <- ArrangeTableB(op, ordered = ordered)

  return(op)
}


# Create tables for select all questions --------------------------------------
CreateTableA_selectAll_percent <-
  function(myData, myQuestions, myAnsweredVar, ordered = FALSE) {
    #myQuestions<-enquo(myQuestions)
    myAnsweredVar <- enquo(myAnsweredVar)

    #get results
    op <-
      base.summary.percent.selectAll(
        myData,
        myQuestions,
        myAnsweredVar = !!myAnsweredVar,
        myGroupVar = NA
      )
    op <-
      rbind(
        op,
        base.summary.percent.selectAll(
          myData,
          myQuestions,
          myAnsweredVar = !!myAnsweredVar,
          myGroupVar = Resi
        )
      )
    op <-
      rbind(
        op,
        base.summary.percent.selectAll(
          myData,
          myQuestions,
          myAnsweredVar = !!myAnsweredVar,
          myGroupVar = E2
        )
      )

    #create table
    op <- ArrangeTableA(op, ordered = ordered)

    return(op)
  }

CreateTableB_selectAll_percent <-
  function(myData, myQuestions, myAnsweredVar, ordered = FALSE) {
    myAnsweredVar <- enquo(myAnsweredVar)

    #get results
    op <-
      base.summary.percent.selectAll(
        myData,
        myQuestions,
        myAnsweredVar = !!myAnsweredVar,
        myGroupVar = E3
      )
    op <- rbind(
      op,
      base.summary.percent.selectAll(
        myData,
        myQuestions,
        myAnsweredVar = !!myAnsweredVar,
        myGroupVar = NA
      )
    )

    #create table
    op <- ArrangeTableB(op, ordered = ordered)

    return(op)
  }

# Create Table For Mean Of Responses --------------------------------------
CreateTableA_means <- function(myData, myQuestions) {
  op <- foreach(i = 1:length(myQuestions), .combine = "rbind") %do%
    {
      base.summary.means(myData, !!rlang::sym(myQuestions[i]), myGroupVar = NA)
    }

  op1 <-
    foreach(i = 1:length(myQuestions), .combine = "rbind") %do%
    {
      base.summary.means(
        myData,
        !!rlang::sym(myQuestions[i]),
        myGroupVar = Resi
      )
    }

  op2 <-
    foreach(i = 1:length(myQuestions), .combine = "rbind") %do%
    {
      base.summary.means(myData, !!rlang::sym(myQuestions[i]), myGroupVar = E2)
    }

  op <- rbind(op, op1, op2)

  #create table
  op <- ArrangeTableA(op)

  return(op)
}

CreateTableB_means <- function(myData, myQuestions) {
  #get results
  op <- foreach(i = 1:length(myQuestions), .combine = "rbind") %do%
    {
      base.summary.means(myData, !!rlang::sym(myQuestions[i]), myGroupVar = E3)
    }

  #create table
  op <- ArrangeTableB(op)

  return(op)
}

#CreateTableA_means(d, c("B3ccf", "B3lmb", "B3crp"))
#CreateTableB_means(d, c("B3ccf", "B3lmb", "B3crp"))

# Create Table For Medians Of Responses --------------------------------------
CreateTableA_medians <- function(myData, myQuestions) {
  op <- foreach(i = 1:length(myQuestions), .combine = "rbind") %do%
    {
      base.summary.medians(
        myData,
        !!rlang::sym(myQuestions[i]),
        myGroupVar = NA
      )
    }

  op1 <-
    foreach(i = 1:length(myQuestions), .combine = "rbind") %do%
    {
      base.summary.medians(
        myData,
        !!rlang::sym(myQuestions[i]),
        myGroupVar = Resi
      )
    }

  op2 <-
    foreach(i = 1:length(myQuestions), .combine = "rbind") %do%
    {
      base.summary.medians(
        myData,
        !!rlang::sym(myQuestions[i]),
        myGroupVar = E2
      )
    }

  op <- rbind(op, op1, op2)
  #create table
  op <- ArrangeTableA(op)

  return(op)
}

CreateTableB_medians <- function(myData, myQuestions) {
  #get results
  op <- foreach(i = 1:length(myQuestions), .combine = "rbind") %do%
    {
      base.summary.medians(
        myData,
        !!rlang::sym(myQuestions[i]),
        myGroupVar = E3
      )
    }

  #create table
  op <- ArrangeTableB(op)

  return(op)
}

#CreateTableA_medians(d, c("B3ccf", "B3lmb", "B3crp"))
#CreateTableB_medians(d, c("B3ccf", "B3lmb", "B3crp"))
