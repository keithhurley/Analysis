options(stringsAsFactors = FALSE)
library(dplyr)
library(tidyr)
library(tibble)
library(purrr)
library(stringr)
library(ggplot2)
library(psych)
library(GPArotation)
library(lavaan)

# Constants ---------------------------------------------------------------
# 13 items, a-m, no gaps (F14). D4e is real and present in both waves.
d4.items <- paste0("D4", letters[1:13])

d4.seed <- 4827

# Battery stem. Held here rather than fetched with the inherited GetQuestion(),
# which hardcodes a D4 stem ending "...during 2018" for every year (F15) and
# would misdate the 2025 battery.
d4.stem <- paste(
  "Thinking about the one type of fish that you prefer to fish for,",
  "how much do you agree or disagree with the following about your",
  "fishing in Nebraska?"
)

d4.response.levels <- c(
  "Strongly Disagree",
  "Disagree",
  "Neutral",
  "Agree",
  "Strongly Agree"
)

# Marker items used to orient and name the retained factors. Chosen from the
# 2025 EFA so that the factor a marker defines is unambiguous, and so that each
# factor is oriented in the direction its name implies.
d4.markers <- c(
  "Satisfaction" = "D4j",
  "Constraints" = "D4f",
  "Regulation support" = "D4c"
)

# Loading magnitude below which an item is treated as unassigned.
d4.loading.threshold <- 0.40

# Short tags used for latent variables in the lavaan syntax.
d4.factor.tags <- c(
  "Satisfaction" = "SAT",
  "Constraints" = "CON",
  "Regulation support" = "REG",
  "Fishing experience" = "EXP",
  "General" = "GEN"
)

# Captions ----------------------------------------------------------------
caption.unweighted <-
  "All statistics in this report are unweighted. Survey weights are not used anywhere in the psychometric analysis; the object of interest is the covariance structure among items, not a population estimate."
caption.polychoric <-
  "Correlations are polychoric, which treats each five-point item as a coarsened continuous variable rather than an interval score."
caption.listwise <-
  "Computed on respondents who answered all 13 items (listwise deletion). A pairwise-deletion sensitivity check is reported in Chapter 1."
caption.loadings <-
  "Pattern coefficients from a minimum-residual extraction with oblimin (oblique) rotation. Coefficients of 0.40 or larger in absolute value are the ones used for item assignment; smaller ones are printed rather than blanked so cross-loadings stay visible. h2 is the communality, the share of an item's variance the factors account for."
caption.fit <-
  "Fit statistics are the scaled (robust) versions produced by WLSMV estimation with items declared ordinal. Conventional cutoffs sometimes cited are CFI and TLI of 0.95 or above, RMSEA of 0.06 or below, and SRMR of 0.08 or below; they are reference points, not tests."
caption.cutoffs <-
  "Reference points commonly cited for these statistics: KMO of 0.60 is the usual floor for proceeding and 0.80 is often called meritorious; a determinant above 0.00001 indicates the matrix is not singular; Bartlett's test asks only whether the matrix differs from an identity matrix and is close to automatic at this sample size."

# Universe ----------------------------------------------------------------
# Same rule in both waves: the year, a non-missing preferred species, and a
# species preference other than "no particular type". The last condition is a
# survey-routing condition rather than an analytic exclusion: the D4 battery
# asks about "the one type of fish that you prefer", so it is not defined for
# respondents who named no preference.
BuildD4Universe <- function(mydata, year) {
  mydata %>%
    filter(
      surveyYear == year,
      !is.na(B1),
      B1 != "I do not prefer any particular type of fish"
    )
}

# Items as numeric 1-5. The factor levels run Strongly Disagree -> Strongly
# Agree, so as.numeric() reproduces the upstream 1-5 coding.
ItemMatrix <- function(mydata, items = d4.items) {
  mydata %>%
    select(all_of(items)) %>%
    mutate(across(everything(), as.numeric)) %>%
    as.data.frame()
}

# Item wording from the codebook. GetQuestion() hardcodes the D4 battery stem
# (F15), so item text has to come from the Field/Question pair directly.
ItemText <- function(questionFactors, year, items = d4.items) {
  questionFactors %>%
    filter(Field %in% items, Year == year) %>%
    distinct(Field, Question) %>%
    transmute(Item = Field, Text = trimws(Question)) %>%
    arrange(match(Item, items))
}

# Generic helpers ---------------------------------------------------------
Fmt2 <- function(x) formatC(x, format = "f", digits = 2)
Fmt3 <- function(x) formatC(x, format = "f", digits = 3)
Fmt1 <- function(x) formatC(x, format = "f", digits = 1)

FmtP <- function(p) {
  if_else(p < 0.001, "<0.001", formatC(p, format = "f", digits = 3))
}

# Flextable rendering -----------------------------------------------------
# Cloned from PreferredSpeciesFunctions.R, which clones 2025CrossTabReport.rmd
# L50-86, so table styling matches the rest of the survey reporting.
CreateFlex <- function(x, mergeOnFirst = FALSE, firstColWidth = 1.2) {
  require(officer)
  require(flextable)

  bigborder <- officer::fp_border(color = "black", width = 1.5)
  smallborder <- officer::fp_border(color = "black", width = 1.0)

  myFlex <- flextable(x) %>%
    theme_zebra()

  if (mergeOnFirst == TRUE) {
    myFlex <- myFlex %>%
      merge_v(j = 1, part = "body")
    myFlex <- myFlex %>%
      border(
        border.bottom = smallborder,
        i = rle(cumsum(myFlex$body$spans$columns[, 1]))$values,
        part = "body"
      )
  }

  myFlex <- myFlex %>%
    border(
      border.bottom = bigborder,
      border.top = bigborder,
      part = "header"
    ) %>%
    border(
      border.bottom = bigborder,
      i = nrow(myFlex$body$spans$rows),
      part = "body"
    ) %>%
    padding(j = 1, padding.left = 3) %>%
    align(align = "left", part = "all") %>%
    fontsize(part = "header", size = 10) %>%
    fontsize(part = "body", size = 8) %>%
    bold(part = "header") %>%
    width(j = 1, width = firstColWidth) %>%
    set_table_properties(layout = "autofit", width = 1) %>%
    # Repeat the header row across page splits and keep body rows with the
    # header, matching the PreferredSpecies report (D33 there).
    paginate(init = TRUE, hdr_ftr = TRUE)

  myFlex
}

# Chapter 1: sample and missing data --------------------------------------
MissingnessTable <- function(itemsMat, itemText) {
  n <- nrow(itemsMat)

  tibble(
    Item = names(itemsMat),
    Answered = vapply(itemsMat, function(x) sum(!is.na(x)), integer(1)),
    Missing = vapply(itemsMat, function(x) sum(is.na(x)), integer(1))
  ) %>%
    left_join(itemText, by = "Item") %>%
    transmute(
      Item,
      Statement = Text,
      `% missing` = Fmt1(Missing / n * 100),
      Answered = formatC(Answered, format = "d", big.mark = ","),
      Missing = formatC(Missing, format = "d", big.mark = ",")
    ) %>%
    relocate(`% missing`, .after = Missing)
}

# How many items each respondent answered. Distinguishes "skipped the battery"
# from "skipped an item", which the per-item rates above cannot.
CompletenessTable <- function(itemsMat) {
  answered <- rowSums(!is.na(itemsMat))
  n <- length(answered)

  tibble(`Items answered` = answered) %>%
    count(`Items answered`) %>%
    complete(`Items answered` = 0:ncol(itemsMat), fill = list(n = 0)) %>%
    arrange(desc(`Items answered`)) %>%
    transmute(
      `Items answered` = as.character(`Items answered`),
      Respondents = formatC(n, format = "d", big.mark = ","),
      `%` = Fmt1(n / .env$n * 100),
      `Cumulative %` = Fmt1(cumsum(n) / .env$n * 100)
    )
}

# Who the listwise analysis drops. Reported so the deletion is visible rather
# than assumed ignorable; no imputation is performed and no case is altered.
DroppedProfileTable <- function(mydata, itemsMat) {
  prof <- mydata %>%
    mutate(
      .complete = complete.cases(itemsMat),
      .group = if_else(.complete, "Listwise complete", "Dropped")
    )

  Share <- function(v, target) {
    tapply(
      as.character(v) == target,
      prof$.group,
      function(x) mean(x, na.rm = TRUE) * 100
    )
  }

  rows <- list(
    tibble(
      Characteristic = "Respondents",
      Dropped = formatC(sum(!prof$.complete), format = "d", big.mark = ","),
      Complete = formatC(sum(prof$.complete), format = "d", big.mark = ",")
    ),
    tibble(
      Characteristic = "% resident",
      Dropped = Fmt1(Share(prof$Resi, "Resident")["Dropped"]),
      Complete = Fmt1(Share(prof$Resi, "Resident")["Listwise complete"])
    ),
    tibble(
      Characteristic = "% male",
      Dropped = Fmt1(Share(prof$E2, "Male")["Dropped"]),
      Complete = Fmt1(Share(prof$E2, "Male")["Listwise complete"])
    ),
    tibble(
      Characteristic = "% aged 65 and older",
      Dropped = Fmt1(Share(prof$E3, "65 and older")["Dropped"]),
      Complete = Fmt1(Share(prof$E3, "65 and older")["Listwise complete"])
    ),
    tibble(
      Characteristic = "Median days fished",
      Dropped = Fmt1(median(
        prof$C1Total_days[!prof$.complete],
        na.rm = TRUE
      )),
      Complete = Fmt1(median(prof$C1Total_days[prof$.complete], na.rm = TRUE))
    ),
    tibble(
      Characteristic = "% missing age",
      Dropped = Fmt1(mean(is.na(prof$E3[!prof$.complete])) * 100),
      Complete = Fmt1(mean(is.na(prof$E3[prof$.complete])) * 100)
    )
  )

  bind_rows(rows)
}

# Chapter 2: item distributions -------------------------------------------
DistributionTable <- function(mydata, itemText, items = d4.items) {
  long <- mydata %>%
    select(all_of(items)) %>%
    pivot_longer(everything(), names_to = "Item", values_to = "Response") %>%
    filter(!is.na(Response))

  pct <- long %>%
    count(Item, Response) %>%
    group_by(Item) %>%
    mutate(pct = n / sum(n) * 100) %>%
    ungroup() %>%
    select(-n) %>%
    mutate(
      Response = factor(
        as.character(Response),
        levels = d4.response.levels
      )
    ) %>%
    pivot_wider(
      names_from = Response,
      values_from = pct,
      values_fill = 0
    ) %>%
    mutate(across(-Item, Fmt1))

  stats <- long %>%
    mutate(v = as.numeric(Response)) %>%
    group_by(Item) %>%
    summarise(
      N = n(),
      Mean = mean(v),
      SD = sd(v),
      Skew = psych::skew(v),
      Kurtosis = psych::kurtosi(v),
      .groups = "drop"
    )

  pct %>%
    left_join(stats, by = "Item") %>%
    left_join(itemText, by = "Item") %>%
    arrange(match(Item, items)) %>%
    transmute(
      Item,
      Statement = Text,
      `Strongly Disagree`,
      Disagree,
      Neutral,
      Agree,
      `Strongly Agree`,
      N = formatC(N, format = "d", big.mark = ","),
      Mean = Fmt2(Mean),
      SD = Fmt2(SD),
      Skew = Fmt2(Skew),
      Kurtosis = Fmt2(Kurtosis)
    )
}

DistributionPlot <- function(mydata, items = d4.items) {
  mydata %>%
    select(all_of(items)) %>%
    pivot_longer(everything(), names_to = "Item", values_to = "Response") %>%
    filter(!is.na(Response)) %>%
    mutate(
      Item = factor(Item, levels = rev(items)),
      Response = factor(as.character(Response), levels = d4.response.levels)
    ) %>%
    count(Item, Response) %>%
    group_by(Item) %>%
    mutate(pct = n / sum(n) * 100) %>%
    ungroup() %>%
    ggplot(aes(x = pct, y = Item, fill = Response)) +
    geom_col() +
    scale_fill_brewer(palette = "RdYlBu") +
    labs(
      x = "Percent of respondents answering the item",
      y = NULL,
      fill = NULL
    ) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom")
}

# Chapter 3: correlations -------------------------------------------------
# Polychoric correlations. smooth = TRUE lets psych repair a matrix that is not
# positive definite; whether it had to is reported alongside the matrix.
PolychoricMatrix <- function(itemsMat) {
  set.seed(d4.seed)
  suppressWarnings(psych::polychoric(itemsMat, smooth = TRUE)$rho)
}

CorrelationTable <- function(R) {
  as.data.frame(round(R, 2)) %>%
    rownames_to_column("Item") %>%
    mutate(across(-Item, ~ formatC(.x, format = "f", digits = 2)))
}

CorrelationPlot <- function(R) {
  as.data.frame(R) %>%
    rownames_to_column("ItemA") %>%
    pivot_longer(-ItemA, names_to = "ItemB", values_to = "r") %>%
    mutate(
      ItemA = factor(ItemA, levels = rownames(R)),
      ItemB = factor(ItemB, levels = rev(rownames(R)))
    ) %>%
    ggplot(aes(x = ItemA, y = ItemB, fill = r)) +
    geom_tile() +
    geom_text(aes(label = formatC(r, format = "f", digits = 2)), size = 2.4) +
    scale_fill_gradient2(limits = c(-1, 1)) +
    labs(x = NULL, y = NULL, fill = "Polychoric r") +
    theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank())
}

# Listwise vs pairwise sensitivity. Compares the two correlation matrices
# directly, then compares the factor solutions they produce using Tucker's
# congruence coefficient (0.95 and above is conventionally read as the same
# factor; 0.85 to 0.94 as a fair match).
SensitivityTable <- function(Rlist, Rpair, nList, nPair, k) {
  dif <- abs(Rlist[lower.tri(Rlist)] - Rpair[lower.tri(Rpair)])

  fList <- FitEFA(Rlist, nList, k)
  fPair <- FitEFA(Rpair, nPair, k)
  cong <- diag(psych::factor.congruence(
    AlignLoadings(fList),
    AlignLoadings(fPair)
  ))

  tibble(
    Comparison = c(
      "Median absolute difference between correlations",
      "Largest absolute difference between correlations",
      "Lowest factor congruence across the retained factors",
      "Respondents contributing (listwise)",
      "Respondents contributing (pairwise, minimum item pair)"
    ),
    Value = c(
      Fmt3(median(dif)),
      Fmt3(max(dif)),
      Fmt3(min(cong)),
      formatC(nList, format = "d", big.mark = ","),
      formatC(nPair, format = "d", big.mark = ",")
    )
  )
}

# Chapter 4: factorability ------------------------------------------------
FactorabilityTable <- function(R, nObs) {
  kmo <- psych::KMO(R)
  bart <- psych::cortest.bartlett(R, n = nObs)

  tibble(
    Diagnostic = c(
      "Kaiser-Meyer-Olkin overall MSA",
      "Bartlett chi-square",
      "Bartlett degrees of freedom",
      "Bartlett p-value",
      "Determinant of the correlation matrix",
      "Largest absolute off-diagonal correlation",
      "Smallest absolute off-diagonal correlation"
    ),
    Value = c(
      Fmt3(kmo$MSA),
      Fmt1(bart$chisq),
      formatC(bart$df, format = "d"),
      FmtP(bart$p.value),
      formatC(det(R), format = "g", digits = 3),
      Fmt2(max(abs(R[lower.tri(R)]))),
      Fmt2(min(abs(R[lower.tri(R)])))
    )
  )
}

ItemMSATable <- function(R, itemText) {
  kmo <- psych::KMO(R)

  tibble(Item = names(kmo$MSAi), MSA = as.numeric(kmo$MSAi)) %>%
    left_join(itemText, by = "Item") %>%
    transmute(Item, Statement = Text, MSA = Fmt2(MSA)) %>%
    arrange(match(Item, rownames(R)))
}

# Chapter 5: how many factors ---------------------------------------------
# fa.parallel() is the slow step and is needed by both the table and the scree
# plot, so it is computed once and passed in.
ParallelAnalysis <- function(R, nObs, nIter = 100) {
  set.seed(d4.seed)
  suppressWarnings(psych::fa.parallel(
    R,
    n.obs = nObs,
    fa = "fa",
    fm = "minres",
    n.iter = nIter,
    plot = FALSE
  ))
}

RetentionTable <- function(R, nObs, par, nMax = 6) {
  set.seed(d4.seed)
  v <- suppressWarnings(psych::vss(
    R,
    n.obs = nObs,
    n = nMax,
    rotate = "oblimin",
    fm = "minres",
    plot = FALSE
  ))

  tibble(
    Criterion = c(
      "Parallel analysis (factors above simulated eigenvalues)",
      "Velicer MAP minimum",
      "Very Simple Structure, complexity 1 maximum",
      "Very Simple Structure, complexity 2 maximum",
      "Empirical BIC minimum",
      "Eigenvalues greater than one (Kaiser)"
    ),
    `Factors indicated` = as.character(c(
      par$nfact,
      which.min(v$map),
      which.max(v$cfit.1),
      which.max(v$cfit.2),
      which.min(v$vss.stats$eBIC),
      sum(eigen(R)$values > 1)
    ))
  )
}

ScreePlot <- function(par) {
  tibble(
    Factor = seq_along(par$fa.values),
    Observed = par$fa.values,
    Simulated = par$fa.sim
  ) %>%
    pivot_longer(-Factor, names_to = "Series", values_to = "Eigenvalue") %>%
    ggplot(aes(
      x = Factor,
      y = Eigenvalue,
      colour = Series,
      linetype = Series
    )) +
    geom_line() +
    geom_point() +
    geom_hline(yintercept = 0, linewidth = 0.3) +
    scale_x_continuous(breaks = seq_along(par$fa.values)) +
    labs(
      x = "Factor number",
      y = "Eigenvalue of the reduced correlation matrix",
      colour = NULL,
      linetype = NULL
    ) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom")
}

# Chapter 6: EFA ----------------------------------------------------------
FitEFA <- function(R, nObs, k) {
  set.seed(d4.seed)
  suppressWarnings(psych::fa(
    R,
    nfactors = k,
    n.obs = nObs,
    rotate = "oblimin",
    fm = "minres"
  ))
}

# fa() returns factors in an arbitrary sign and order. For display, flip each
# factor so its largest loading is positive; the rotation is unaffected.
AlignLoadings <- function(faObj) {
  L <- unclass(faObj$loadings)
  flip <- apply(L, 2, function(col) sign(col[which.max(abs(col))]))
  sweep(L, 2, flip, "*")
}

AlignedPhi <- function(faObj) {
  L <- unclass(faObj$loadings)
  flip <- apply(L, 2, function(col) sign(col[which.max(abs(col))]))
  phi <- faObj$Phi
  if (is.null(phi)) {
    return(NULL)
  }
  diag(flip) %*% phi %*% diag(flip)
}

# Name the retained factors from their marker items, and orient each factor so
# the marker loads positively. Returns NULL names if a marker is ambiguous, so
# the caller can stop rather than mislabel a column.
NameFactors <- function(L, markers = d4.markers) {
  owner <- vapply(
    markers,
    function(it) which.max(abs(L[it, ])),
    integer(1)
  )

  if (anyDuplicated(owner) > 0 || length(owner) != ncol(L)) {
    return(NULL)
  }

  nm <- character(ncol(L))
  nm[owner] <- names(markers)
  flip <- rep(1, ncol(L))
  flip[owner] <- sign(L[markers, owner][cbind(
    seq_along(markers),
    seq_along(markers)
  )])

  list(names = nm, loadings = sweep(L, 2, flip, "*"), flip = flip)
}

LoadingsTable <- function(L, faObj, itemText, factorNames = NULL) {
  if (is.null(factorNames)) {
    factorNames <- paste("Factor", seq_len(ncol(L)))
  }

  as.data.frame(L) %>%
    setNames(factorNames) %>%
    rownames_to_column("Item") %>%
    mutate(h2 = as.numeric(faObj$communality[Item])) %>%
    left_join(itemText, by = "Item") %>%
    relocate(Statement = Text, .after = Item) %>%
    mutate(across(where(is.numeric), Fmt2))
}

FactorCorrelationTable <- function(phi, factorNames = NULL) {
  if (is.null(factorNames)) {
    factorNames <- paste("Factor", seq_len(ncol(phi)))
  }

  as.data.frame(round(phi, 2)) %>%
    setNames(factorNames) %>%
    mutate(Factor = factorNames) %>%
    relocate(Factor) %>%
    mutate(across(-Factor, ~ formatC(.x, format = "f", digits = 2)))
}

EFAFitTable <- function(faList) {
  map_dfr(names(faList), function(nm) {
    f <- faList[[nm]]
    tibble(
      Solution = nm,
      `Degrees of freedom` = formatC(f$dof, format = "d"),
      RMSEA = Fmt3(f$RMSEA[1]),
      TLI = Fmt3(f$TLI),
      RMSR = Fmt3(f$rms),
      `Cumulative variance explained (%)` = Fmt1(
        sum(f$Vaccounted["Proportion Var", ]) * 100
      )
    )
  })
}

# Item-to-factor assignment from the retained solution. An item goes to the
# factor carrying its largest absolute loading, provided that loading clears
# the threshold; otherwise it is unassigned and reported as such.
AssignItems <- function(L, factorNames, threshold = d4.loading.threshold) {
  tibble(
    Item = rownames(L),
    Factor = factorNames[apply(abs(L), 1, which.max)],
    Loading = apply(L, 1, function(r) r[which.max(abs(r))])
  ) %>%
    mutate(
      Assigned = abs(Loading) >= threshold,
      Scale = if_else(Assigned, Factor, NA_character_),
      Sign = sign(Loading)
    )
}

AssignmentTable <- function(assignment, itemText) {
  assignment %>%
    left_join(itemText, by = "Item") %>%
    transmute(
      Item,
      Statement = Text,
      `Largest loading` = Fmt2(Loading),
      `Assigned to` = if_else(
        Assigned,
        if_else(Sign < 0, paste0(Factor, " (reverse scored)"), Factor),
        "Unassigned"
      )
    )
}

# Chapter 7: reliability --------------------------------------------------
# Sign-align a polychoric submatrix so reverse-scored items point the same way
# as the rest of their scale, then compute reliability on that submatrix.
AlignedSubmatrix <- function(R, items, signs) {
  Rs <- R[items, items, drop = FALSE]
  D <- diag(signs, nrow = length(signs))
  out <- D %*% Rs %*% D
  dimnames(out) <- list(items, items)
  out
}

# Congeneric (McDonald's) omega from a one-factor solution on the aligned
# submatrix. Computed directly from the loadings rather than via psych::omega(),
# which warns that omega-hierarchical is undefined for a single factor.
CongenericOmega <- function(Rs, nObs) {
  set.seed(d4.seed)
  f <- suppressWarnings(psych::fa(
    Rs,
    nfactors = 1,
    n.obs = nObs,
    fm = "minres"
  ))
  lambda <- as.numeric(f$loadings[, 1])
  sumL <- sum(lambda)
  sumL^2 / (sumL^2 + sum(1 - lambda^2))
}

ScaleReliabilityTable <- function(R, assignment, nObs) {
  scales <- assignment %>% filter(Assigned)

  map_dfr(unique(scales$Scale), function(sc) {
    sub <- scales %>% filter(Scale == sc)
    Rs <- AlignedSubmatrix(R, sub$Item, sub$Sign)
    a <- suppressWarnings(psych::alpha(Rs, n.obs = nObs))

    tibble(
      Scale = sc,
      Items = paste(sub$Item, collapse = ", "),
      k = nrow(sub),
      `Ordinal alpha` = Fmt3(a$total$raw_alpha),
      `Congeneric omega` = Fmt3(CongenericOmega(Rs, nObs)),
      `Mean item-rest r` = Fmt2(mean(a$item.stats$r.drop)),
      `Lowest item-rest r` = Fmt2(min(a$item.stats$r.drop))
    )
  })
}

ItemReliabilityTable <- function(R, assignment, nObs, itemText) {
  scales <- assignment %>% filter(Assigned)

  map_dfr(unique(scales$Scale), function(sc) {
    sub <- scales %>% filter(Scale == sc)
    Rs <- AlignedSubmatrix(R, sub$Item, sub$Sign)
    a <- suppressWarnings(psych::alpha(Rs, n.obs = nObs))

    tibble(
      Scale = sc,
      Item = sub$Item,
      Reversed = if_else(sub$Sign < 0, "Yes", "No"),
      `Item-rest r` = Fmt2(a$item.stats$r.drop),
      `Alpha if dropped` = Fmt3(a$alpha.drop$raw_alpha)
    )
  }) %>%
    left_join(itemText, by = "Item") %>%
    relocate(Statement = Text, .after = Item)
}

# Chapter 8: CFA ----------------------------------------------------------
# Build lavaan syntax from the retained assignment. Within each factor the
# item with the largest positive loading is listed first so that lavaan's
# marker-variable scaling orients the factor the way the scale is named.
CFASyntax <- function(assignment, merge = NULL) {
  a <- assignment %>%
    filter(Assigned) %>%
    mutate(Scale = if (is.null(merge)) Scale else recode(Scale, !!!merge))

  a %>%
    group_by(Scale) %>%
    arrange(desc(Loading * Sign), .by_group = TRUE) %>%
    summarise(
      line = paste0(
        d4.factor.tags[first(Scale)],
        " =~ ",
        paste(Item, collapse = " + ")
      ),
      .groups = "drop"
    ) %>%
    pull(line) %>%
    paste(collapse = "\n")
}

FitCFA <- function(model, cfaData) {
  suppressWarnings(lavaan::cfa(
    model,
    data = cfaData,
    ordered = names(cfaData),
    estimator = "WLSMV"
  ))
}

CFAFitTable <- function(fitList) {
  map_dfr(names(fitList), function(nm) {
    f <- fitList[[nm]]
    m <- lavaan::fitMeasures(
      f,
      c(
        "chisq.scaled",
        "df.scaled",
        "cfi.scaled",
        "tli.scaled",
        "rmsea.scaled",
        "srmr"
      )
    )

    tibble(
      Model = nm,
      `Scaled chi-square` = Fmt1(m[["chisq.scaled"]]),
      df = formatC(m[["df.scaled"]], format = "d"),
      CFI = Fmt3(m[["cfi.scaled"]]),
      TLI = Fmt3(m[["tli.scaled"]]),
      RMSEA = Fmt3(m[["rmsea.scaled"]]),
      SRMR = Fmt3(m[["srmr"]]),
      Admissible = if_else(
        isTRUE(suppressWarnings(lavaan::lavInspect(f, "post.check"))),
        "Yes",
        "No"
      )
    )
  })
}

CFALoadingTable <- function(fit, itemText) {
  lavaan::standardizedSolution(fit) %>%
    filter(op == "=~") %>%
    transmute(
      Factor = lhs,
      Item = rhs,
      `Standardized loading` = Fmt2(est.std),
      SE = Fmt3(se),
      `z` = Fmt1(z)
    ) %>%
    left_join(itemText, by = "Item") %>%
    relocate(Statement = Text, .after = Item)
}

CFAFactorCorrelationTable <- function(fit) {
  cors <- lavaan::lavInspect(fit, "cor.lv")

  as.data.frame(round(cors, 2)) %>%
    rownames_to_column("Factor") %>%
    mutate(across(-Factor, ~ formatC(.x, format = "f", digits = 2)))
}

# Chapter 9: the recommended scores ---------------------------------------
# Scale scores as the mean of their items on the 1-5 metric, reverse-scoring
# any item the EFA assigned with a negative loading. Scored only for
# respondents who answered every item in that scale, matching the
# *_AnsweredAll convention the survey reports already use.
ScaleScores <- function(mydata, assignment) {
  scales <- assignment %>% filter(Assigned)

  out <- mydata
  for (sc in unique(scales$Scale)) {
    sub <- scales %>% filter(Scale == sc)
    m <- as.matrix(ItemMatrix(mydata, sub$Item))
    m <- sweep(m, 2, sub$Sign, "*")
    m <- sweep(m, 2, if_else(sub$Sign < 0, 6, 0), "+")
    out[[sc]] <- if_else(rowSums(is.na(m)) == 0, rowMeans(m), NA_real_)
  }
  out
}

ScaleScoreTable <- function(scored, assignment) {
  scales <- unique(assignment$Scale[assignment$Assigned])

  map_dfr(scales, function(sc) {
    v <- scored[[sc]]
    tibble(
      Scale = sc,
      Items = sum(assignment$Assigned & assignment$Scale == sc),
      `Respondents scored` = formatC(
        sum(!is.na(v)),
        format = "d",
        big.mark = ","
      ),
      `Not scored` = formatC(sum(is.na(v)), format = "d", big.mark = ","),
      Mean = Fmt2(mean(v, na.rm = TRUE)),
      SD = Fmt2(sd(v, na.rm = TRUE)),
      Minimum = Fmt2(min(v, na.rm = TRUE)),
      Maximum = Fmt2(max(v, na.rm = TRUE))
    )
  })
}

ScaleScoreCorrelationTable <- function(scored, assignment) {
  scales <- unique(assignment$Scale[assignment$Assigned])
  m <- scored %>% select(all_of(scales))
  cm <- cor(m, use = "pairwise.complete.obs")

  as.data.frame(round(cm, 2)) %>%
    rownames_to_column("Scale") %>%
    mutate(across(-Scale, ~ formatC(.x, format = "f", digits = 2)))
}

# Largest residual correlations, which is where a rejected model's misfit
# concentrates. Reported instead of a full modification-index dump.
ResidualTable <- function(fit, topN = 8) {
  res <- lavaan::residuals(fit, type = "cor")$cov
  res[upper.tri(res, diag = TRUE)] <- NA

  as.data.frame(res) %>%
    rownames_to_column("ItemA") %>%
    pivot_longer(-ItemA, names_to = "ItemB", values_to = "Residual") %>%
    filter(!is.na(Residual)) %>%
    arrange(desc(abs(Residual))) %>%
    slice_head(n = topN) %>%
    transmute(
      `Item pair` = paste(ItemA, "with", ItemB),
      `Residual correlation` = Fmt2(Residual)
    )
}
