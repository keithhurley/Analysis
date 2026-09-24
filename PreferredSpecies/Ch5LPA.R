# Chapter 5 — latent profile analysis layer (D140-D148).
# Sourced after PreferredSpeciesFunctions.R. Replaces Ch5Functions.R (k-means,
# D120), deleted 2026-09-24 (prompt 120); recoverable from git history.

# tidySEM's run_mx() silently returns NULL unless OpenMx is on the search path
# (F67): 72 minutes of starting-value work, no estimates, no error.
library(OpenMx)

ch5.lpa.vars <- c(
  attitude.vars,
  motivation.vars,
  "reg_comprehension",
  "reg_sitesupport",
  "reg_uniform"
)

ch5.lpa.min.scales <- 7 # D145
ch5.lpa.classes <- 1:6 # D144
ch5.lpa.variances <- c("equal", "varying") # D144; covariances always "zero"
# D155 (Q46): BIC was still falling at the k = 6 edge, so extend equal only
ch5.lpa.extend.equal <- 7:8
ch5.lpa.min.class.prop <- 0.05 # D143
ch5.lpa.min.entropy <- 0.60 # D143
ch5.lpa.seed <- 5813 # k-means starting values inside mixture_starts() are random
ch5.lpa.cache <- "Ch5LPA_results.rds"
ch5.lpa.unassigned <- "Unassigned"

# D146: reporting-only suppression, decided before fitting
ch5.effn.floor <- 30

# Adds the gate columns. Row order of d is preserved so assignments can be
# written back by position.
Ch5LPAGate <- function(mydata) {
  stopifnot(all(ch5.lpa.vars %in% names(mydata)))
  mydata$lpa_n_scales <- rowSums(!is.na(mydata[, ch5.lpa.vars]))
  mydata$lpa_fitted <- mydata$lpa_n_scales >= ch5.lpa.min.scales
  mydata
}

# Indicator frame for the fit: only the 11 scale columns, as plain numeric,
# gated rows only. Remaining NAs are left for OpenMx FIML (D145).
Ch5LPAFrame <- function(mydata) {
  out <- as.data.frame(mydata[mydata$lpa_fitted, ch5.lpa.vars])
  out[] <- lapply(out, as.numeric)
  out
}

# Storage (D152). Full MxModels embed the respondent-level data, so they live
# in a local folder, one file per model; the report reads only the slim
# results file, which carries everything Chapter 5 needs.
ch5.lpa.fit.dir <- "Ch5LPA_fits"
ch5.lpa.log <- "Ch5LPA_fit.log"

# The full model list: D144's 1-6 x both structures, plus D155's equal-only
# extension. Not a full cross, so it is listed explicitly.
Ch5LPAGridSpec <- function() {
  grid <- rbind(
    expand.grid(
      variances = ch5.lpa.variances,
      classes = ch5.lpa.classes,
      stringsAsFactors = FALSE
    ),
    data.frame(variances = "equal", classes = ch5.lpa.extend.equal)
  )
  grid$name <- paste0(grid$variances, "_", grid$classes)
  stopifnot(!anyDuplicated(grid$name))
  grid
}

Ch5LPAModelNames <- function() {
  Ch5LPAGridSpec()$name
}

Ch5LPAFitPath <- function(name) {
  file.path(ch5.lpa.fit.dir, paste0(name, ".rds"))
}

# TRUE if a saved fit exists for this model AND was fitted to this frame
Ch5LPAHasFit <- function(name, key) {
  p <- Ch5LPAFitPath(name)
  file.exists(p) && identical(readRDS(p)$key, key)
}

# One model. Self-contained so it can run on a PSOCK worker; saves its own
# result the moment it finishes, so an interrupted grid loses nothing. The
# seed is set per model so each fit is reproducible regardless of scheduling.
Ch5LPAFitOne <- function(frame, variances, classes, seed, key, path, logFile) {
  library(OpenMx)
  t0 <- Sys.time()
  set.seed(seed)
  fit <- tidySEM::mx_profiles(
    data = frame,
    classes = classes,
    variances = variances,
    covariances = "zero"
  )
  status <- if (is.null(fit)) "NULL" else fit$output$status$code
  if (!is.null(fit)) {
    saveRDS(list(key = key, fit = fit, fitted_at = Sys.time()), path)
  }
  cat(
    sprintf(
      "%s %s_%d done in %.1f min, status %s\n",
      format(Sys.time(), "%H:%M"),
      variances,
      classes,
      as.numeric(difftime(Sys.time(), t0, units = "mins")),
      status
    ),
    file = logFile,
    append = TRUE
  )
  status
}

# Fits whichever model in Ch5LPAGridSpec() is not already saved for this frame.
# tidySEM runs simulated annealing on every mixture (~11 min for equal_2
# alone, single-threaded, F68), so models are spread across workers; the
# estimator itself is unchanged (D151).
Ch5LPAFitGrid <- function(frame) {
  key <- digest_frame(frame)
  dir.create(ch5.lpa.fit.dir, showWarnings = FALSE)
  grid <- Ch5LPAGridSpec()
  grid <- grid[!vapply(grid$name, Ch5LPAHasFit, logical(1), key = key), ]

  cat(
    "Grid started",
    format(Sys.time()),
    "- fitting",
    nrow(grid),
    "models:",
    paste(grid$name, collapse = ", "),
    "\n",
    file = ch5.lpa.log,
    append = TRUE
  )
  if (nrow(grid) == 0) {
    return(invisible(character(0)))
  }

  cl <- parallel::makePSOCKcluster(nrow(grid))
  on.exit(parallel::stopCluster(cl), add = TRUE)
  status <- parallel::clusterMap(
    cl,
    Ch5LPAFitOne,
    variances = grid$variances,
    classes = grid$classes,
    path = Ch5LPAFitPath(grid$name),
    MoreArgs = list(
      frame = frame,
      seed = ch5.lpa.seed,
      key = key,
      logFile = ch5.lpa.log
    ),
    .scheduling = "dynamic"
  )
  cat(
    "Grid finished",
    format(Sys.time()),
    "\n",
    file = ch5.lpa.log,
    append = TRUE
  )
  failed <- grid$name[unlist(status) == "NULL"]
  if (length(failed) > 0) {
    stop("LPA fits returned NULL: ", paste(failed, collapse = ", "))
  }
  invisible(grid$name)
}

# Everything downstream needs from one fit, without the embedded data
Ch5LPASlim <- function(fit, name) {
  s <- summary(fit)
  pp <- Ch5LPAPosterior(fit)
  est <- tryCatch(
    as.data.frame(tidySEM::table_results(fit, columns = NULL)),
    error = function(e) NULL
  )
  list(
    Model = name,
    Variances = strsplit(name, "_")[[1]][1],
    Classes = ncol(pp$post),
    Minus2LL = s$Minus2LogLikelihood,
    Parameters = s$estimatedParameters,
    N = nrow(pp$post),
    Status = fit$output$status$code,
    post = pp$post,
    modal = pp$modal,
    parameters = OpenMx::omxGetParameters(fit),
    estimates = est
  )
}

# Builds the slim results file from the saved fits. Errors, rather than
# fitting, if any model is missing: fitting is only ever done deliberately
# through Ch5LPA_run.R.
Ch5LPABuildResults <- function(frame, path = ch5.lpa.cache) {
  key <- digest_frame(frame)
  nm <- Ch5LPAModelNames()
  missing <- nm[!vapply(nm, Ch5LPAHasFit, logical(1), key = key)]
  if (length(missing) > 0) {
    stop(
      "No saved fit for: ",
      paste(missing, collapse = ", "),
      ". Run Ch5LPA_run.R."
    )
  }
  models <- lapply(nm, function(x) Ch5LPASlim(readRDS(Ch5LPAFitPath(x))$fit, x))
  names(models) <- nm
  saveRDS(list(key = key, models = models, built_at = Sys.time()), path)
  models
}

# What the report calls. Never fits.
Ch5LPALoadResults <- function(frame, path = ch5.lpa.cache) {
  if (file.exists(path)) {
    res <- readRDS(path)
    if (identical(res$key, digest_frame(frame))) {
      return(res$models)
    }
    message(
      "Ch5 LPA results are stale for the current data; rebuilding from saved fits."
    )
  }
  Ch5LPABuildResults(frame, path)
}

# Cheap content fingerprint without adding a digest dependency
digest_frame <- function(frame) {
  c(
    n = nrow(frame),
    p = ncol(frame),
    names = paste(names(frame), collapse = ","),
    sum = format(sum(as.matrix(frame), na.rm = TRUE), digits = 15),
    na = sum(is.na(frame))
  )
}

# Modal-class posterior matrix for one fit (D148)
Ch5LPAPosterior <- function(fit) {
  cp <- tidySEM::class_prob(fit, type = "individual")$individual
  # Posterior columns are unnamed for k = 1, so select by exclusion
  post <- as.matrix(cp[, colnames(cp) != "predicted", drop = FALSE])
  colnames(post) <- paste0("class", seq_len(ncol(post)))
  list(post = post, modal = as.integer(cp[, "predicted"]))
}

# Relative entropy (1 = perfect separation); NA for k = 1
Ch5Entropy <- function(post) {
  k <- ncol(post)
  if (k < 2) {
    return(NA_real_)
  }
  p <- pmax(post, .Machine$double.xmin)
  1 - sum(-post * log(p)) / (nrow(post) * log(k))
}

# One row per fit. Computed from the posteriors directly so the D143
# quantities are defined here rather than depending on table_fit() column
# names; BIC/LL/parameters come from OpenMx.
Ch5LPADiagnostics <- function(models) {
  purrr::map_dfr(models, function(m) {
    k <- m$Classes
    sizes <- tabulate(m$modal, nbins = k)
    tibble(
      Model = m$Model,
      Variances = m$Variances,
      Classes = k,
      Parameters = m$Parameters,
      LL = -m$Minus2LL / 2,
      # summary()$BIC.Mx is OpenMx's df-adjusted form (F69); use the conventional one
      BIC = m$Minus2LL + m$Parameters * log(m$N),
      Entropy = Ch5Entropy(m$post),
      SmallestClassN = min(sizes),
      SmallestClassProp = min(sizes) / m$N,
      MinMeanPosterior = if (k < 2) {
        NA_real_
      } else {
        min(sapply(seq_len(k), function(j) mean(m$post[m$modal == j, j])))
      },
      StatusCode = m$Status
    )
  }) %>%
    mutate(
      PassSize = SmallestClassProp >= ch5.lpa.min.class.prop,
      # k = 1 has no entropy; it is admissible by definition
      PassEntropy = Classes == 1 | Entropy >= ch5.lpa.min.entropy,
      Admissible = PassSize & PassEntropy & StatusCode %in% c(0, 1)
    )
}

# D143: minimum BIC among admissible fits, across both structures
Ch5LPASelect <- function(diag) {
  sel <- diag %>%
    filter(Admissible) %>%
    slice_min(BIC, n = 1, with_ties = FALSE)
  stopifnot(nrow(sel) == 1)
  sel$Model
}

# Writes the modal class back onto the full universe. Ungated rows become
# "Unassigned" and are kept (D145), never dropped.
Ch5LPAAssign <- function(mydata, model) {
  pp <- model
  k <- ncol(pp$post)
  stopifnot(length(pp$modal) == sum(mydata$lpa_fitted))

  cls <- rep(NA_integer_, nrow(mydata))
  cls[mydata$lpa_fitted] <- pp$modal
  maxpost <- rep(NA_real_, nrow(mydata))
  maxpost[mydata$lpa_fitted] <- pp$post[cbind(seq_along(pp$modal), pp$modal)]

  lvls <- c(paste("Class", seq_len(k)), ch5.lpa.unassigned)
  mydata$lpa_class <- factor(
    if_else(is.na(cls), ch5.lpa.unassigned, paste("Class", cls)),
    levels = lvls
  )
  mydata$lpa_maxpost <- maxpost
  mydata
}

# D148: assignment certainty by scales-answered band
Ch5LPACertainty <- function(mydata) {
  mydata %>%
    filter(lpa_fitted) %>%
    mutate(
      Band = cut(
        lpa_n_scales,
        breaks = c(6, 9, 10, 11),
        labels = c("7-9", "10", "11")
      )
    ) %>%
    group_by(Band) %>%
    summarise(
      N = n(),
      MeanMaxPosterior = mean(lpa_maxpost),
      ShareBelow70 = mean(lpa_maxpost < 0.70),
      .groups = "drop"
    )
}

# Numeric long class-by-species table over the 17 overlapping columns plus
# Overall (D31: never total these). Includes Unassigned as a class level, so
# column % are of all respondents in the column. Kish effN is the whole
# column's, for the D146 floor.
Ch5ClassBySpeciesLong <- function(mydata, var = "lpa_class") {
  spec <- D4RowSpec(includeOverall = TRUE)
  purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      base.summary.percent.selectOne(sub, !!sym(var)) %>%
        as_tibble() %>%
        transmute(
          Order = Order,
          Column = RawLabel,
          Type = Type,
          Class = as.character(Response),
          Number,
          Value,
          CI
        ) %>%
        mutate(
          ColumnN = nrow(sub),
          ColumnEffN = Kish(sub$postWeight),
          Suppressed = ColumnEffN < ch5.effn.floor & Type != "Overall"
        )
    }
  )
}

# ---- Report builders (prompt 117) ------------------------------------------

ch5.domain.levels <- c("Attitudes", "Motivations", "Regulations")

Ch5LPADomain <- function(var) {
  factor(
    case_when(
      str_starts(var, "attitude") ~ "Attitudes",
      str_starts(var, "motivation") ~ "Motivations",
      str_starts(var, "reg_") ~ "Regulations"
    ),
    levels = ch5.domain.levels
  )
}

# The D143 reason for each exclusion is printed in the table itself, so the
# reader does not need Appendix B to see why a lower-BIC model was passed over.
Ch5LPAEligibility <- function(diag, selected) {
  case_when(
    diag$Model == selected ~ "Yes (selected)",
    diag$Admissible ~ "Yes",
    !diag$StatusCode %in% c(0, 1) ~ paste0(
      "No: not converged (status ",
      diag$StatusCode,
      ")"
    ),
    !diag$PassSize ~ "No: smallest profile below 5%",
    !diag$PassEntropy ~ "No: entropy below 0.60"
  )
}

Ch5LPADiagnosticsTable <- function(diag, selected) {
  diag$Eligible <- Ch5LPAEligibility(diag, selected)
  diag %>%
    arrange(Variances, Classes) %>%
    transmute(
      Variances = str_to_sentence(Variances),
      Profiles = as.character(Classes),
      Parameters = as.character(Parameters),
      `Log-likelihood` = formatC(LL, format = "f", digits = 1, big.mark = ","),
      BIC = formatC(BIC, format = "f", digits = 1, big.mark = ","),
      `Relative entropy` = if_else(
        is.na(Entropy),
        "\u2014",
        formatC(Entropy, format = "f", digits = 3)
      ),
      `Smallest profile n (%)` = paste0(
        FmtCount(SmallestClassN),
        " (",
        formatC(100 * SmallestClassProp, format = "f", digits = 1),
        "%)"
      ),
      `Lowest mean assigned probability` = if_else(
        is.na(MinMeanPosterior),
        "\u2014",
        formatC(MinMeanPosterior, format = "f", digits = 3)
      ),
      `OpenMx status` = as.character(StatusCode),
      Eligible
    )
}

# F77: locates the collapsed variance in a varying-variance fit. OpenMx names
# class-j variances v<j><indicator>, which parses unambiguously while k <= 9.
Ch5LPASpike <- function(model, frame) {
  p <- model$parameters
  v <- p[grepl("^v[0-9]+$", names(p))]
  nm <- names(which.min(v))
  stopifnot(model$Classes <= 9)
  cls <- as.integer(substr(nm, 2, 2))
  ind <- as.integer(substring(nm, 3))
  x <- frame[[ind]][model$modal == cls]
  top <- max(frame[[ind]], na.rm = TRUE)
  tibble(
    Model = model$Model,
    Class = cls,
    Variable = names(frame)[ind],
    Variance = min(v),
    ClassN = length(x),
    Answered = sum(!is.na(x)),
    AtMax = sum(x == top, na.rm = TRUE),
    Max = top
  )
}

Ch5LPACertaintyTable <- function(mydata) {
  Ch5LPACertainty(mydata) %>%
    arrange(desc(Band)) %>%
    transmute(
      `Scales answered (of 11)` = as.character(Band),
      `Respondents (n)` = FmtCount(N),
      `Mean probability of assigned profile` = formatC(
        MeanMaxPosterior,
        format = "f",
        digits = 3
      ),
      `Assigned with probability below 0.70` = paste0(
        formatC(100 * ShareBelow70, format = "f", digits = 1),
        "%"
      )
    )
}

# D146: the formatted table is the Chapter 3 select-one layout, unchanged,
# with the below-floor rows removed.
Ch5ClassBySpeciesTable <- function(mydata, long) {
  hidden <- D4RowSpec(includeOverall = TRUE) %>%
    filter(RawLabel %in% long$Column[long$Suppressed]) %>%
    pull(IndentedLabel)
  Ch3SelectOneTable(mydata, "lpa_class") %>%
    filter(!`Preferred species` %in% hidden)
}

Ch5SuppressedNote <- function(long) {
  s <- long %>%
    filter(Suppressed) %>%
    distinct(Order, Column, ColumnN, ColumnEffN) %>%
    arrange(Order)
  paste0(
    "Preferred-species rows below the effective-N floor of ",
    ch5.effn.floor,
    " are not shown (",
    nrow(s),
    " rows): ",
    paste0(
      s$Column,
      " (",
      FmtCount(s$ColumnN),
      " respondents, effective N ",
      formatC(s$ColumnEffN, format = "f", digits = 1),
      ")",
      collapse = "; "
    ),
    ". Their respondents are included in the model fit and in the Overall row."
  )
}

# Weighted means by assigned profile (D147: fit unweighted, report weighted).
# Overall is every respondent in the universe who has the scale, so it is the
# Chapter 3 Overall value; Unassigned respondents count there only.
Ch5LPAProfileLong <- function(mydata, labels) {
  k <- nlevels(mydata$lpa_class) - 1
  groups <- c("Overall", paste("Class", seq_len(k)))
  expand_grid(Class = groups, var = ch5.lpa.vars) %>%
    purrr::pmap_dfr(function(Class, var) {
      sub <- mydata %>% filter(!is.na(.data[[var]]))
      if (Class != "Overall") {
        sub <- sub %>% filter(lpa_class == Class)
      }
      base.summary.means(sub, !!sym(var)) %>%
        as_tibble() %>%
        transmute(Class = Class, var = var, N = Number, Value, CI)
    }) %>%
    mutate(
      Class = factor(Class, levels = groups),
      Scale = factor(
        ScaleLabel(var, labels),
        levels = ScaleLabel(ch5.lpa.vars, labels)
      ),
      Domain = Ch5LPADomain(var)
    )
}

Ch5LPAProfileTable <- function(prof) {
  prof %>%
    arrange(Domain, Scale) %>%
    mutate(cell = FmtMeanN(Value, CI, N)) %>%
    select(Domain, Scale, Class, cell) %>%
    pivot_wider(names_from = Class, values_from = cell) %>%
    mutate(Domain = as.character(Domain), Scale = as.character(Scale))
}

Ch5LPAProfileLinePlot <- function(prof, titleText) {
  dat <- prof %>%
    filter(Class != "Overall") %>%
    mutate(Class = droplevels(Class))
  dodge <- position_dodge(width = 0.5)
  ggplot(dat, aes(Scale, Value, colour = Class, group = Class)) +
    geom_line(position = dodge) +
    geom_pointrange(
      aes(ymin = Value - CI, ymax = Value + CI),
      position = dodge,
      size = 0.2
    ) +
    facet_grid(~Domain, scales = "free_x", space = "free_x") +
    scale_y_continuous(limits = c(1, 5)) +
    labs(
      title = titleText,
      x = NULL,
      y = "Weighted mean (1-5) \u00b1 95% CI",
      colour = NULL
    ) +
    theme_bw() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    )
}

# ---- Profile descriptions (D161) ---------------------------------------------
# Standardized deviation of each class mean from the Overall mean, in Overall
# weighted SD units. The prose pulls every number through these helpers, so it
# cannot drift from the profile table.
Ch5LPAStd <- function(prof, mydata) {
  sdw <- vapply(
    ch5.lpa.vars,
    function(v) {
      k <- !is.na(mydata[[v]])
      WeightedSD(mydata[[v]][k], mydata$postWeight[k])
    },
    numeric(1)
  )
  ov <- prof %>% filter(Class == "Overall") %>% select(var, Overall = Value)
  prof %>%
    filter(Class != "Overall") %>%
    left_join(ov, by = "var") %>%
    mutate(
      Class = as.character(Class),
      Z = (Value - Overall) / unname(sdw[var])
    )
}

Ch5Cell <- function(std, cls, v) {
  r <- std[std$Class == paste("Class", cls) & std$var == v, ]
  stopifnot(nrow(r) == 1)
  r
}

Ch5M <- function(std, cls, v) {
  formatC(Ch5Cell(std, cls, v)$Value, format = "f", digits = 1)
}

Ch5MZ <- function(std, cls, v) {
  r <- Ch5Cell(std, cls, v)
  paste0(
    formatC(r$Value, format = "f", digits = 1),
    ", ",
    sprintf("%+.2f", r$Z),
    " SD"
  )
}

# Class that holds the extreme mean on one scale
Ch5Extreme <- function(std, v, fun) {
  x <- std[std$var == v, ]
  as.integer(str_remove(x$Class[fun(x$Value)], "Class "))
}

Ch5Share <- function(long, cls, column, ci = TRUE) {
  r <- long[long$Class == paste("Class", cls) & long$Column == column, ]
  stopifnot(nrow(r) == 1)
  out <- paste0(formatC(r$Value, format = "f", digits = 1), "%")
  if (ci) {
    paste0(out, " \u00b1 ", formatC(r$CI, format = "f", digits = 1))
  } else {
    out
  }
}

# ---- Class comparisons on other questions (D163) ------------------------------
# Adds the derived indicators the comparison table needs. Universes follow the
# Chapter 3 tables: select-all items are gated on their *_Answered flag, the
# guide indicator reproduces the Chapter 3 construction, and days fished uses
# the C1_AnsweredAll gate.
Ch5LPACompareData <- function(mydata) {
  a4 <- mydata$A4_Answered %in% TRUE
  a5 <- mydata$A5_Answered %in% TRUE
  mydata %>%
    mutate(
      cmpDays = if_else(C1_AnsweredAll %in% TRUE, C1Total_days, NA_real_),
      cmpTourney = fishedTourney,
      cmpGuide = if_else(
        is.na(hiredGuide),
        NA,
        (!is.na(Q18a) & Q18a > 0) | (!is.na(Q18b) & Q18b > 0)
      ),
      cmpBoat = if_else(a5, as.character(A5boat) == "Motorized boat", NA),
      cmpKayak = if_else(a5, as.character(A5kayak) == "Kayak/Canoe", NA),
      cmpIce = if_else(a5, as.character(A5ice) == "Ice fishing", NA),
      cmpOutState = if_else(is.na(A11), NA, as.character(A11) == "Yes"),
      cmpPark = if_else(is.na(A10), NA, as.character(A10) == "Yes"),
      # User-specified combination (prompt 123): any of the three river/stream types
      cmpStream = if_else(
        a4,
        as.character(A4mo) == "Missouri River" |
          as.character(A4plat) == "Platte River" |
          as.character(A4riv) == "Other streams, rivers, and canals",
        NA
      ),
      cmpPrivate = if_else(
        is.na(A17Priv_corrected),
        NA,
        as.character(A17Priv_corrected) == "Yes"
      ),
      cmpMiles = A8_miles,
      cmpSatisfaction = as.numeric(A9),
      cmpLiveScope = if_else(is.na(Q16), NA, as.character(Q16) == "Yes"),
      cmpFemale = if_else(is.na(E2), NA, as.character(E2) == "Female"),
      cmpAge = Age
    )
}

ch5.compare.spec <- tribble(
  ~var              , ~Kind    , ~Label                                                                           , ~digits ,
  "cmpDays"         , "mean"   , "Days fished in 2025, mean"                                                      ,       1 ,
  "cmpDays"         , "median" , "Days fished in 2025, median"                                                    ,       1 ,
  "cmpTourney"      , "pct"    , "Fished at least one tournament, %"                                              ,       1 ,
  "cmpGuide"        , "pct"    , "Hired a fishing guide, %"                                                       ,       1 ,
  "cmpBoat"         , "pct"    , "Fished from a motorized boat, %"                                                ,       1 ,
  "cmpKayak"        , "pct"    , "Fished from a kayak or canoe, %"                                                ,       1 ,
  "cmpIce"          , "pct"    , "Ice fished, %"                                                                  ,       1 ,
  "cmpStream"       , "pct"    , "Fished the Missouri River, Platte River, or other streams and rivers, %"        ,       1 ,
  "cmpPark"         , "pct"    , "Fished a water requiring a Park Entry Permit, %"                                ,       1 ,
  "cmpPrivate"      , "pct"    , "Used private areas to fish or launch, %"                                        ,       1 ,
  "cmpOutState"     , "pct"    , "Fished outside Nebraska, %"                                                     ,       1 ,
  "cmpMiles"        , "median" , "One-way miles to most visited water, median"                                    ,       0 ,
  "cmpSatisfaction" , "mean"   , "Overall fishing satisfaction, mean (1 = Very satisfied, 5 = Very dissatisfied)" ,       1 ,
  "cmpLiveScope"    , "pct"    , "Used live-imaging sonar, %"                                                     ,       1 ,
  "cmpFemale"       , "pct"    , "Female, %"                                                                      ,       1 ,
  "cmpAge"          , "mean"   , "Age, mean"                                                                      ,       1
)

# Overall is every respondent in the universe (the Chapter 3 Overall value);
# Unassigned respondents appear there only, never as a column (prompt 123).
Ch5LPACompareLong <- function(mydata, spec = ch5.compare.spec) {
  k <- nlevels(mydata$lpa_class) - 1
  groups <- c("Overall", paste("Class", seq_len(k)))
  purrr::pmap_dfr(spec, function(var, Kind, Label, digits) {
    purrr::map_dfr(groups, function(g) {
      sub <- mydata %>% filter(!is.na(.data[[var]]))
      if (g != "Overall") {
        sub <- sub %>% filter(lpa_class == g)
      }
      out <- if (Kind == "pct") {
        sub[[var]] <- factor(sub[[var]], levels = c(FALSE, TRUE))
        pct <- base.summary.percent.selectOne(sub, !!sym(var)) %>% as_tibble()
        hit <- pct %>% filter(as.character(Response) == "TRUE")
        tibble(
          Value = if (nrow(hit) == 0) 0 else hit$Value,
          CI = if (nrow(hit) == 0) 0 else hit$CI,
          Lower = NA_real_,
          Upper = NA_real_
        )
      } else if (Kind == "mean") {
        mn <- base.summary.means(sub, !!sym(var)) %>% as_tibble()
        tibble(Value = mn$Value, CI = mn$CI, Lower = NA_real_, Upper = NA_real_)
      } else {
        md <- base.summary.medians(sub, !!sym(var)) %>% as_tibble()
        tibble(
          Value = md$Value,
          CI = NA_real_,
          Lower = md$CIlower,
          Upper = md$CIupper
        )
      }
      out %>%
        mutate(
          Class = g,
          var = var,
          Kind = Kind,
          Label = Label,
          digits = digits,
          N = nrow(sub)
        )
    })
  }) %>%
    mutate(
      Class = factor(Class, levels = groups),
      Label = factor(Label, levels = unique(spec$Label))
    )
}

Ch5LPACompareTable <- function(cmp) {
  cmp %>%
    mutate(
      cell = case_when(
        Kind == "pct" ~ paste0(FmtPct(Value, CI), " (", FmtCount(N), ")"),
        Kind == "mean" ~ FmtMeanN(Value, CI, N),
        TRUE ~ purrr::pmap_chr(
          list(Lower, Value, Upper, N, digits),
          function(lo, v, up, n, dg) FmtMedianN(lo, v, up, n, dg)
        )
      )
    ) %>%
    select(Label, Class, cell) %>%
    pivot_wider(names_from = Class, values_from = cell) %>%
    mutate(Label = as.character(Label)) %>%
    rename(Measure = Label)
}

# Species mix of each class: weighted % of the class preferring each family
# group, against the same % among all assigned respondents. Unbannered B1
# answers are kept as their own level rather than dropped.
Ch5LPAClassMix <- function(mydata) {
  fit <- mydata %>%
    filter(lpa_fitted) %>%
    mutate(
      Family = forcats::fct_na_value_to_level(factor(B1banner), "Other species")
    )
  k <- nlevels(mydata$lpa_class) - 1
  groups <- c("All assigned", paste("Class", seq_len(k)))
  purrr::map_dfr(groups, function(g) {
    sub <- if (g == "All assigned") fit else fit %>% filter(lpa_class == g)
    base.summary.percent.selectOne(sub, Family) %>%
      as_tibble() %>%
      transmute(Class = g, Family = as.character(Response), Number, Value, CI)
  }) %>%
    group_by(Family) %>%
    mutate(Baseline = Value[Class == "All assigned"]) %>%
    ungroup()
}

# Prose helpers for the comparison paragraphs. cls is a class number or "Overall".
Ch5CmpRow <- function(cmp, cls, v, kind) {
  g <- if (is.numeric(cls)) paste("Class", cls) else cls
  r <- cmp[as.character(cmp$Class) == g & cmp$var == v & cmp$Kind == kind, ]
  stopifnot(nrow(r) == 1)
  r
}

Ch5CmpFmt <- function(cmp, cls, v, kind) {
  r <- Ch5CmpRow(cmp, cls, v, kind)
  switch(
    kind,
    pct = paste0(formatC(r$Value, format = "f", digits = 1), "%"),
    mean = formatC(r$Value, format = "f", digits = 1),
    median = formatC(r$Value, format = "f", digits = r$digits)
  )
}

# Class holding the extreme value on one comparison row
Ch5CmpRank <- function(cmp, v, kind, fun) {
  x <- cmp[
    as.character(cmp$Class) != "Overall" & cmp$var == v & cmp$Kind == kind,
  ]
  as.integer(str_remove(as.character(x$Class[fun(x$Value)]), "Class "))
}

# D164: a family group is named when it makes up at least this many percentage
# points more of a class than of all assigned respondents.
ch5.mix.gap <- 5

Ch5MixCaveat <- function(mix, cls) {
  x <- mix %>%
    filter(Class == paste("Class", cls), Value - Baseline >= ch5.mix.gap) %>%
    arrange(desc(Value - Baseline))
  if (nrow(x) == 0) {
    return("")
  }
  f <- function(v) formatC(v, format = "f", digits = 1)
  parts <- paste0(
    x$Family,
    " (",
    f(x$Value),
    "% of the profile, against ",
    f(x$Baseline),
    "% of all assigned respondents)"
  )
  joined <- if (length(parts) <= 2) {
    paste(parts, collapse = " and ")
  } else {
    paste0(paste(head(parts, -1), collapse = ", "), ", and ", tail(parts, 1))
  }
  paste0(
    "Its species mix leans toward ",
    joined,
    ", so differences on questions that vary by species may partly reflect that mix rather than the profile itself."
  )
}

Ch5LPAProfileFacetPlot <- function(prof, titleText) {
  dat <- prof %>%
    filter(Class != "Overall") %>%
    mutate(Class = droplevels(Class))
  ref <- prof %>% filter(Class == "Overall")
  ggplot(dat, aes(Class, Value)) +
    geom_hline(
      data = ref,
      aes(yintercept = Value),
      linetype = "dashed",
      colour = "grey50"
    ) +
    geom_pointrange(aes(ymin = Value - CI, ymax = Value + CI), size = 0.2) +
    facet_wrap(
      ~ Domain + Scale,
      ncol = 4,
      labeller = label_wrap_gen(width = 25, multi_line = FALSE)
    ) +
    scale_x_discrete(labels = function(x) str_remove(x, "Class ")) +
    scale_y_continuous(limits = c(1, 5)) +
    labs(
      title = titleText,
      x = "Profile",
      y = "Weighted mean (1-5) \u00b1 95% CI",
      caption = "Dashed line: Overall weighted mean"
    ) +
    theme_bw()
}
