# Chapter 5 — latent profile analysis layer (D140-D148).
# Sourced after PreferredSpeciesFunctions.R. Replaces the fitting layer of
# Ch5Functions.R (k-means, D120), which stays on disk until this renders (F66).

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

Ch5LPAModelNames <- function(classes = ch5.lpa.classes) {
  as.vector(outer(ch5.lpa.variances, classes, paste, sep = "_"))
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

# Fits whichever of the 1-6 x 2 grid is not already saved for this frame.
# tidySEM runs simulated annealing on every mixture (~11 min for equal_2
# alone, single-threaded, F68), so models are spread across workers; the
# estimator itself is unchanged (D151).
Ch5LPAFitGrid <- function(frame, classes = ch5.lpa.classes) {
  key <- digest_frame(frame)
  dir.create(ch5.lpa.fit.dir, showWarnings = FALSE)
  grid <- expand.grid(
    variances = ch5.lpa.variances,
    classes = classes,
    stringsAsFactors = FALSE
  )
  grid$name <- paste0(grid$variances, "_", grid$classes)
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
