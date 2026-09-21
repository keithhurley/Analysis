# ==========================================================================
# Chapter 5 -- Angler type profiles
# ==========================================================================
# Sourced last, after PreferredSpeciesFunctions.R. Self-contained on purpose:
# the Ch5 builders carry their own row set (types, not the 17 preferred
# groups), so every D4RowSpec call site in Chapters 1-4 is untouched (D130).
#
# Every cluster statistic comes from calling the inherited base.summary.*
# functions on a cluster subset, so the weighting, Kish effective N and CI
# arithmetic are the report's existing ones and not a second implementation.

ch5.seed <- 4817
ch5.k.range <- 2:6
ch5.min.cluster <- 15 # D124: a stated convention, not a published standard
ch5.min.fit.n <- 60 # D123
ch5.alpha <- 0.20 # D127: a stated permissive screen, not a 0.05 test
ch5.gap.B <- 50 # bootstrap replicates for the gap statistic
ch5.max.ext.plots <- 5 # D129

ch5.nopref <- "I do not prefer any particular type of fish"

# D136: the Overall fit covers everyone who named a preferred species. It is
# still not the union of the group fits, because B1 answers that receive no
# banner column (bullhead, drum, carp, paddlefish, other) are included here.
Ch5OverallMembers <- function(mydata) {
  setdiff(unique(as.character(mydata$B1)), ch5.nopref)
}

# --- Clustering inputs (D121, amended) ------------------------------------
# Thirteen measures that already share the 1-5 agree metric, used
# untransformed and unstandardized: when measures share a scale, z-scoring
# inflates whichever ones happen to have the least spread. Days fished was
# removed from the inputs (it is a behavioural count, not a cognitive
# ordinal measure) and is reported as a profiled characteristic instead.
ch5.input.vars <- tibble::tribble(
  ~Field, ~Block, ~Fallback,
  "attitude_catch", "Attitude", "Attitude: catch",
  "attitude_numbers", "Attitude", "Attitude: numbers",
  "attitude_size", "Attitude", "Attitude: size",
  "attitude_harvest", "Attitude", "Attitude: harvest",
  "motivation_pp", "Motivation", "Motivation: personal pleasure",
  "motivation_natural", "Motivation", "Motivation: nature",
  "motivation_social", "Motivation", "Motivation: social",
  "motivation_resource", "Motivation", "Motivation: resource",
  "reg_comprehension", "Regulations", "Regulations: comprehension",
  "reg_sitesupport", "Regulations", "Regulations: site support",
  "reg_uniform", "Regulations", "Regulations: uniformity",
  "D4j", "Preferred species (inputs)", "Size allowed to harvest",
  "D4l", "Preferred species (inputs)", "Number allowed to harvest"
)

ch5.input.blocks <- c(
  "Attitude",
  "Motivation",
  "Regulations",
  "Preferred species (inputs)"
)

# D4 a-i, k, m: every D4 item except the two that are clustering inputs.
ch5.d4.display <- paste0("D4", c(letters[1:9], "k", "m"))

# Blocks whose rows carry an omnibus p and are subject to the screen. One
# combined Holm family across both.
ch5.tested.blocks <- c("Preferred-species items", "Other characteristics")

ch5.block.order <- c(ch5.input.blocks, ch5.tested.blocks)

Ch5InputLabel <- function(field, fallback, labels) {
  op <- ScaleLabel(field, labels)
  if_else(op == field, fallback, op)
}

# --- Row specs ------------------------------------------------------------
# The inputs carry no p, because differences on them are produced by the
# clustering itself (D127).
Ch5InputSpec <- function(labels) {
  ch5.input.vars %>%
    transmute(
      Field,
      Display = "mean1",
      Test = "mean",
      Gate = NA_character_,
      Value = NA_character_,
      Label = Ch5InputLabel(Field, Fallback, labels),
      Block
    )
}

Ch5D4Spec <- function(codebook) {
  tibble(
    Field = ch5.d4.display,
    Display = "mean1",
    Test = "mean",
    Gate = NA_character_,
    Value = NA_character_,
    Label = purrr::map_chr(
      ch5.d4.display,
      function(f) str_trunc(trimws(ItemQuestionText(f, codebook)), 74)
    ),
    Block = "Preferred-species items"
  )
}

# Six A4 fields exist as columns but hold no 2025 data at all; they are
# dropped here and reported by Ch5DroppedFields() rather than disappearing.
Ch5AllNAFields <- function(mydata, fields) {
  fields[purrr::map_lgl(fields, function(f) all(is.na(mydata[[f]])))]
}

Ch5A4Fields <- function(mydata) {
  setdiff(grep("^A4[a-zA-Z]+$", names(mydata), value = TRUE), "A4_Answered")
}

Ch5DroppedFields <- function(mydata) {
  cand <- c(Ch5A4Fields(mydata), c("A5bank", "A5boat", "A5kayak", "A5ice"))
  drop <- Ch5AllNAFields(mydata, cand)
  tibble(
    Field = drop,
    Label = purrr::map_chr(drop, function(f) levels(mydata[[f]])[2])
  )
}

# Display: pct = weighted percent, pctpos = percent with a count above zero,
#          mean1 = weighted mean to 1 dp, median = weighted median with the
#          inherited bootstrap limits.
# Where the displayed statistic is a median the test runs on log1p of the
# same variable, which is disclosed in the table note.
Ch5ExternalSpec <- function(mydata) {
  base <- tibble::tribble(
    ~Field, ~Display, ~Test, ~Gate, ~Value, ~Label,
    # Days fished is a profiled characteristic, not an input (D121 amended).
    # The C1_AnsweredAll gate matches how Chapter 3 reports this total.
    "C1Total_days", "mean1", "mean", "C1_AnsweredAll", NA,
    "Total days fished (January-October)",
    "A11", "pct", "prop", NA, "Yes", "Fished outside Nebraska",
    "A12", "pct", "prop", "A11yes", "Yes",
    "Took a boat when fishing out of state",
    "A10", "pct", "prop", NA, "Yes",
    "Fished a water requiring a Park Entry Permit",
    "A13_corrected", "pctpos", "prop", NA, NA,
    "Fished at least one tournament",
    "A17Pub_corrected", "pct", "prop", NA, "Yes",
    "Used public lands and access",
    "A17Priv_corrected", "pct", "prop", NA, "Yes",
    "Used private lands and access",
    "A7_miles", "median", "logmean", NA, NA,
    "Distance to favorite water (one-way miles)",
    "A8_miles", "median", "logmean", NA, NA,
    "Distance to most visited water (one-way miles)",
    "A9rev", "mean1", "mean", NA, NA,
    "Satisfaction with 2025 fishing (1-5, higher is more satisfied)",
    "Q16", "pct", "prop", NA, "Yes", "Used live-imaging sonar",
    "Q18a_corrected", "pctpos", "prop", NA, NA,
    "Took at least one guided trip in Nebraska",
    "Q18b_corrected", "pctpos", "prop", NA, NA,
    "Took at least one guided trip outside Nebraska",
    "E2", "pct", "prop", NA, "Female", "Female",
    "Age", "mean1", "mean", NA, NA, "Mean age (years)"
  )

  # Select-all families: the label is the field's own checked level, so it is
  # the instrument's wording rather than mine.
  selAll <- function(fields, gate) {
    tibble(
      Field = fields,
      Display = "pct",
      Test = "prop",
      Gate = gate,
      Value = NA_character_,
      Label = purrr::map_chr(fields, function(f) levels(mydata[[f]])[2])
    )
  }

  bind_rows(
    base,
    selAll(Ch5A4Fields(mydata), "A4_Answered"),
    selAll(c("A5bank", "A5boat", "A5kayak", "A5ice"), "A5_Answered")
  ) %>%
    mutate(Block = "Other characteristics") %>%
    filter(!Field %in% Ch5AllNAFields(mydata, Field))
}

Ch5Spec <- function(mydata, codebook, labels) {
  bind_rows(
    Ch5InputSpec(labels),
    Ch5D4Spec(codebook),
    Ch5ExternalSpec(mydata)
  )
}

# --- Input matrix ---------------------------------------------------------
# No transform and no standardization: the 13 inputs already share the 1-5
# metric (D4j and D4l are the numeric codes of the five agree levels, which
# is how Chapters 2 and 4 treat them).
Ch5InputFrame <- function(mydata) {
  mydata %>% transmute(across(all_of(ch5.input.vars$Field), as.numeric))
}

Ch5Complete <- function(mydata) {
  rowSums(is.na(Ch5InputFrame(mydata))) == 0
}

# Retained for the profile figure, which standardizes for display only. A
# zero-variance column would make scale() return NaN.
Ch5Scale <- function(x) {
  op <- scale(as.matrix(x))
  op[, apply(as.matrix(x), 2, sd) == 0] <- 0
  op
}

# --- Fit inventory --------------------------------------------------------
Ch5FitInventory <- function(mydata) {
  purrr::pmap_dfr(
    D4RowSpec(includeOverall = TRUE),
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      mem <- if (is.null(Members)) Ch5OverallMembers(mydata) else Members
      sub <- mydata %>% filter(as.character(B1) %in% mem)
      nc <- sum(Ch5Complete(sub))
      tibble(
        Order = Order,
        Group = RawLabel,
        IndentedLabel = IndentedLabel,
        Type = Type,
        Raw_n = nrow(sub),
        Clusterable_n = nc,
        Retention = 100 * nc / nrow(sub),
        kCap = min(max(ch5.k.range), floor(nc / ch5.min.cluster)),
        Eligible = nc >= ch5.min.fit.n
      )
    }
  )
}

# --- Choice of k (D124, amended to the mode of five methods) --------------
# Normalized elbow: both axes rescaled to [0, 1], k furthest from the chord
# joining the ends of the curve. Rescaling matters, because an unnormalized
# chord distance depends on the units of WSS.
Ch5Elbow <- function(wss, ks, kRange = ch5.k.range) {
  if (length(ks) < 3) {
    return(max(ks))
  }
  kn <- (ks - min(ks)) / diff(range(ks))
  wn <- (wss - min(wss)) / diff(range(wss))
  dd <- abs(kn + wn - 1) / sqrt(2)
  cand <- ks %in% kRange
  ks[cand][which.max(dd[cand])]
}

# Five criteria, then the mode. Ties break toward the smaller k; the
# minimum-type-size floor overrides the mode; and because two of the five
# criteria can favour k = 1, the mode is floored at 2 with that fact
# recorded rather than hidden.
Ch5KSelect <- function(X, kRange = ch5.k.range, seed = ch5.seed, gapB = ch5.gap.B) {
  ks <- 1:max(kRange)
  n <- nrow(X)
  dm <- dist(X)

  kms <- purrr::map(ks, function(k) {
    set.seed(seed)
    kmeans(X, centers = k, nstart = 50, iter.max = 100)
  })
  wss <- purrr::map_dbl(kms, "tot.withinss")

  diagnostics <- tibble(
    k = ks,
    WSS = wss,
    WSSPct = 100 * wss / wss[1],
    MinSize = purrr::map_dbl(kms, function(m) min(m$size)),
    Silhouette = c(
      NA_real_,
      purrr::map_dbl(ks[-1], function(k) {
        mean(cluster::silhouette(kms[[k]]$cluster, dm)[, 3])
      })
    ),
    CH = c(
      NA_real_,
      purrr::map_dbl(ks[-1], function(k) {
        ((wss[1] - wss[k]) / (k - 1)) / (wss[k] / (n - k))
      })
    )
  )

  set.seed(seed)
  gp <- cluster::clusGap(
    X,
    FUN = function(x, k) kmeans(x, k, nstart = 25, iter.max = 100),
    K.max = max(kRange),
    B = gapB,
    verbose = FALSE
  )
  diagnostics$Gap <- as.numeric(gp$Tab[, "gap"])
  kGap <- cluster::maxSE(
    gp$Tab[, "gap"],
    gp$Tab[, "SE.sim"],
    method = "Tibs2001SEmax"
  )

  bic <- tryCatch(
    suppressWarnings(mclust::mclustBIC(
      X,
      G = ks,
      modelNames = c("EII", "VII", "EEI", "VVI"),
      verbose = FALSE
    )),
    error = function(e) NULL
  )
  if (is.null(bic)) {
    diagnostics$BIC <- NA_real_
    kBIC <- NA_integer_
  } else {
    best <- apply(bic, 1, function(r) {
      if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE)
    })
    diagnostics$BIC <- as.numeric(best[match(ks, as.integer(names(best)))])
    kBIC <- ks[which.max(diagnostics$BIC)]
  }

  picks <- c(
    Elbow = Ch5Elbow(wss, ks, kRange),
    Silhouette = diagnostics$k[which.max(diagnostics$Silhouette)],
    CH = diagnostics$k[which.max(diagnostics$CH)],
    Gap = as.integer(kGap),
    BIC = as.integer(kBIC)
  )
  picks <- picks[!is.na(picks)]

  tb <- table(picks)
  agree <- max(tb)
  kMode <- min(as.integer(names(tb)[tb == agree]))
  modeBelowRange <- kMode < min(kRange)
  kUse <- max(kMode, min(kRange))
  while (
    kUse > min(kRange) &&
      diagnostics$MinSize[diagnostics$k == kUse] < ch5.min.cluster
  ) {
    kUse <- kUse - 1
  }

  list(
    diagnostics = diagnostics,
    picks = picks,
    kMode = kMode,
    agree = as.integer(agree),
    kUse = kUse,
    modeBelowRange = modeBelowRange,
    steppedDown = kUse < max(kMode, min(kRange)),
    kms = kms
  )
}

# --- The fit --------------------------------------------------------------
Ch5Fit <- function(
  mydata,
  groupLabel,
  members = NULL,
  kRange = ch5.k.range,
  seed = ch5.seed
) {
  mem <- if (is.null(members)) Ch5OverallMembers(mydata) else members
  grp <- mydata %>% filter(as.character(B1) %in% mem)
  keep <- Ch5Complete(grp)
  X <- as.matrix(Ch5InputFrame(grp[keep, , drop = FALSE]))

  kCap <- min(max(kRange), floor(nrow(X) / ch5.min.cluster))
  sel <- Ch5KSelect(X, kRange = kRange[kRange <= kCap], seed = seed)
  km <- sel$kms[[sel$kUse]]

  # Types are numbered by descending weighted share, so Type 1 is always the
  # largest and the numbering is not an artefact of kmeans' internal order.
  ord <- tibble(cl = km$cluster, w = grp$postWeight[keep]) %>%
    group_by(cl) %>%
    summarise(W = sum(w), .groups = "drop") %>%
    arrange(desc(W)) %>%
    mutate(new = row_number())
  typeLevels <- paste("Type", seq_len(sel$kUse))

  grp$Ch5type <- factor(NA_character_, levels = typeLevels)
  grp$Ch5type[keep] <- typeLevels[ord$new[match(km$cluster, ord$cl)]]
  grp$Ch5typeAll <- factor(
    if_else(
      is.na(as.character(grp$Ch5type)),
      "Unassigned",
      as.character(grp$Ch5type)
    ),
    levels = c(typeLevels, "Unassigned")
  )

  list(
    group = groupLabel,
    raw = grp,
    fitdata = grp[keep, , drop = FALSE],
    X = X,
    k = sel$kUse,
    kMode = sel$kMode,
    agree = sel$agree,
    picks = sel$picks,
    kCap = kCap,
    modeBelowRange = sel$modeBelowRange,
    steppedDown = sel$steppedDown,
    varExplained = 100 *
      (1 -
        sel$diagnostics$WSS[sel$diagnostics$k == sel$kUse] /
          sel$diagnostics$WSS[1]),
    diagnostics = sel$diagnostics,
    typeLevels = typeLevels
  )
}

# --- Diagnostics table ----------------------------------------------------
# One per species section. The final column names which criteria favour each
# k, so the mode and how thin its support is are both visible.
Ch5DiagTable <- function(fit) {
  fit$diagnostics %>%
    filter(k >= min(ch5.k.range)) %>%
    transmute(
      k = as.character(k),
      `WSS (% of k=1)` = formatC(WSSPct, format = "f", digits = 1),
      `Avg. silhouette` = formatC(Silhouette, format = "f", digits = 3),
      `Calinski-Harabasz` = formatC(CH, format = "f", digits = 1),
      `Gap statistic` = formatC(Gap, format = "f", digits = 3),
      `Best BIC` = if_else(
        is.na(BIC),
        "\u2014",
        formatC(BIC, format = "f", digits = 0)
      ),
      `Smallest type (n)` = FmtCount(MinSize),
      `Criteria favouring this k` = purrr::map_chr(k, function(kk) {
        nm <- names(fit$picks)[fit$picks == kk]
        if (length(nm) == 0) "\u2014" else paste(nm, collapse = ", ")
      })
    )
}

# --- Size table -----------------------------------------------------------
# The denominator is the RAW group, not the clusterable subset, so the
# percent column sums to 100 with the Unassigned row and no respondent
# disappears (D122). Population estimates are sums of postWeight on the same
# expansion basis as Chapter 1 (D29).
Ch5SizeTable <- function(fit) {
  pct <- base.summary.percent.selectOne(fit$raw, !!sym("Ch5typeAll")) %>%
    as_tibble()
  wts <- fit$raw %>%
    group_by(Ch5typeAll) %>%
    summarise(Pop = sum(postWeight), .groups = "drop") %>%
    transmute(Type = as.character(Ch5typeAll), Pop)

  pct %>%
    transmute(
      Type = as.character(Response),
      Respondents = Number,
      Percent = FmtPct(Value, CI)
    ) %>%
    left_join(wts, by = "Type") %>%
    transmute(
      `Angler type` = Type,
      `Respondents (n)` = FmtCount(Respondents),
      `Percent of group` = Percent,
      `Estimated anglers` = FmtCount(Pop)
    )
}

# --- Row statistics -------------------------------------------------------
Ch5Subset <- function(dat, gate) {
  if (is.na(gate)) {
    return(dat)
  }
  if (gate == "A11yes") {
    return(dat %>% filter(A11 == "Yes"))
  }
  dat %>% filter(.data[[gate]] == TRUE)
}

# Numeric outcome for the test, aligned to the displayed statistic.
Ch5TestVar <- function(x, display, value) {
  if (display == "pct") {
    if (!is.na(value)) {
      return(as.numeric(as.character(x) == value))
    }
    return(as.numeric(as.character(x) != "Unchecked"))
  }
  if (display == "pctpos") {
    return(as.numeric(x > 0))
  }
  if (display == "median") {
    return(log1p(as.numeric(x)))
  }
  as.numeric(x)
}

# Design-based Wald test that the weighted mean of the outcome is equal
# across types. With k > 2 this is exactly the "at least two types differ"
# question, so no pairwise contrasts are needed.
Ch5Omnibus <- function(dat, y) {
  tryCatch(
    {
      dd <- dat %>% mutate(ch5_y = y) %>% filter(!is.na(ch5_y))
      dd$Ch5type <- droplevels(dd$Ch5type)
      if (
        nlevels(dd$Ch5type) < 2 ||
          min(table(dd$Ch5type)) < 2 ||
          sd(dd$ch5_y) == 0
      ) {
        return(NA_real_)
      }
      des <- svydesign(ids = ~1, weights = ~postWeight, data = dd)
      m <- svyglm(ch5_y ~ Ch5type, design = des)
      as.numeric(regTermTest(m, ~Ch5type)$p)[1]
    },
    error = function(e) NA_real_
  )
}

# One long row per (variable x column), with the omnibus p attached once per
# variable. Columns are Overall plus the numbered types.
Ch5ProfileLong <- function(fit, spec, codebook, labels) {
  cols <- c("Overall", fit$typeLevels)

  purrr::pmap_dfr(
    spec,
    function(Field, Display, Test, Gate, Value, Label, Block) {
      dat <- Ch5Subset(fit$fitdata, Gate) %>%
        filter(!is.na(.data[[Field]]))
      if (nrow(dat) == 0) {
        return(NULL)
      }

      p <- if (Block %in% ch5.tested.blocks) {
        Ch5Omnibus(dat, Ch5TestVar(dat[[Field]], Display, Value))
      } else {
        NA_real_
      }

      purrr::map_dfr(cols, function(cl) {
        sub <- if (cl == "Overall") {
          dat
        } else {
          dat %>% filter(as.character(Ch5type) == cl)
        }
        if (nrow(sub) == 0) {
          return(tibble(Column = cl, Cell = "", Value = NA_real_, N = 0L))
        }

        if (Display %in% c("pct", "pctpos")) {
          sub$ch5_ind <- factor(
            if_else(Ch5TestVar(sub[[Field]], Display, Value) == 1, "Yes", "No"),
            levels = c("Yes", "No")
          )
          pc <- base.summary.percent.selectOne(sub, !!sym("ch5_ind")) %>%
            as_tibble()
          hit <- pc %>% filter(as.character(Response) == "Yes")
          v <- if (nrow(hit) == 0) 0 else hit$Value
          ci <- if (nrow(hit) == 0) 0 else hit$CI
          tibble(Column = cl, Cell = FmtPct(v, ci), Value = v, N = nrow(sub))
        } else if (Display == "median") {
          md <- base.summary.medians(sub, !!sym(Field)) %>% as_tibble()
          tibble(
            Column = cl,
            Cell = paste0(
              formatC(md$Value[1], format = "f", digits = 0),
              " (",
              formatC(md$CIlower[1], format = "f", digits = 0),
              "-",
              formatC(md$CIupper[1], format = "f", digits = 0),
              ")"
            ),
            Value = md$Value[1],
            N = nrow(sub)
          )
        } else {
          sub2 <- sub %>% mutate(ch5_num = as.numeric(.data[[Field]]))
          mn <- base.summary.means(sub2, !!sym("ch5_num")) %>% as_tibble()
          tibble(
            Column = cl,
            Cell = FmtMeanD4(mn$Value[1], mn$CI[1]),
            Value = mn$Value[1],
            N = nrow(sub)
          )
        }
      }) %>%
        mutate(
          Field = Field,
          Label = Label,
          Block = Block,
          Display = Display,
          P = p
        )
    }
  )
}

# Holm across the one combined tested family. n is the number of tests
# actually run -- p.adjust's default would also count variables whose test
# could not be computed.
Ch5Meta <- function(long) {
  meta <- long %>%
    filter(Column == "Overall") %>%
    distinct(Field, Block, Label, P, N)
  tested <- meta %>%
    filter(Block %in% ch5.tested.blocks) %>%
    mutate(PAdj = p.adjust(P, method = "holm", n = max(sum(!is.na(P)), 1)))
  bind_rows(
    meta %>% filter(!Block %in% ch5.tested.blocks) %>% mutate(PAdj = NA_real_),
    tested
  )
}

Ch5ProfileTable <- function(long, meta = Ch5Meta(long), alpha = ch5.alpha) {
  wide <- long %>%
    select(Field, Column, Cell) %>%
    pivot_wider(names_from = Column, values_from = Cell)

  meta %>%
    mutate(
      Keep = if_else(
        Block %in% ch5.tested.blocks,
        !is.na(PAdj) & PAdj < alpha,
        TRUE
      ),
      Block = factor(Block, levels = ch5.block.order)
    ) %>%
    filter(Keep) %>%
    left_join(wide, by = "Field") %>%
    arrange(Block) %>%
    transmute(
      Block = as.character(Block),
      Characteristic = Label,
      across(any_of(c("Overall", paste("Type", 1:6)))),
      N = FmtCount(N),
      p = if_else(is.na(PAdj), "\u2014", FmtP(PAdj))
    )
}

# --- Figures --------------------------------------------------------------
# The elbow curve behind the chosen k, as a share of the k = 1 within-cluster
# sum of squares.
Ch5ElbowPlot <- function(fit, titleText = NULL) {
  p <- ggplot(
    fit$diagnostics %>% filter(k >= min(ch5.k.range)),
    aes(x = k, y = WSSPct)
  ) +
    geom_vline(
      xintercept = fit$k,
      colour = "grey60",
      linetype = "22",
      linewidth = 0.5
    ) +
    geom_line(linewidth = 0.5) +
    geom_point(size = 1.8) +
    scale_x_continuous(breaks = min(ch5.k.range):max(ch5.k.range)) +
    labs(
      x = "Number of types (k)",
      y = "Within-cluster sum of squares (% of k = 1)",
      subtitle = paste0(
        "Dashed line marks the k used: ",
        fit$k,
        ". Criteria favouring each k are listed in the diagnostics table."
      )
    ) +
    theme_minimal(base_size = 9) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(size = 9.5, face = "bold"),
      plot.subtitle = element_text(size = 7, face = "italic")
    )

  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 80))
  }
  p
}

# Standardized input profile. The clustering used the untransformed 1-5
# values; standardization here is for display only, so 13 measures with
# different means can be read on one axis.
Ch5ProfilePlot <- function(fit, labels, titleText = NULL) {
  lab <- ch5.input.vars %>%
    transmute(Field, Block, Label = Ch5InputLabel(Field, Fallback, labels))

  df <- as_tibble(Ch5Scale(fit$X)) %>%
    mutate(Ch5type = fit$fitdata$Ch5type, w = fit$fitdata$postWeight) %>%
    pivot_longer(
      all_of(ch5.input.vars$Field),
      names_to = "Field",
      values_to = "Z"
    ) %>%
    group_by(Ch5type, Field) %>%
    summarise(Z = weighted.mean(Z, w), .groups = "drop") %>%
    left_join(lab, by = "Field") %>%
    mutate(
      Block = factor(Block, levels = ch5.input.blocks),
      Label = factor(Label, levels = rev(lab$Label))
    )

  p <- ggplot(df, aes(x = Z, y = Label, colour = Ch5type)) +
    geom_vline(xintercept = 0, colour = "grey70", linewidth = 0.4) +
    geom_point(size = 2) +
    scale_colour_viridis_d(begin = 0.15, end = 0.8) +
    facet_grid(rows = vars(Block), scales = "free_y", space = "free_y") +
    labs(
      x = "Weighted mean, standardized for display (0 = group mean)",
      y = NULL,
      colour = NULL
    ) +
    theme_minimal(base_size = 9) +
    theme(
      axis.text.y = element_text(hjust = 0),
      panel.grid.major.y = element_blank(),
      legend.position = "top",
      strip.text.y = element_text(angle = 0, size = 7.5),
      plot.title = element_text(size = 9.5, face = "bold")
    )

  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 80))
  }
  p
}

# Dumbbell: each type against the group overall, for the external
# characteristics that survived the screen. One figure per sub-section, at
# most ch5.max.ext.plots panels, chosen by the largest relative spread
# across types (D129).
Ch5ExternalPlot <- function(
  long,
  meta = Ch5Meta(long),
  alpha = ch5.alpha,
  maxPanels = ch5.max.ext.plots,
  titleText = NULL
) {
  pass <- meta %>%
    filter(Block == "Other characteristics", !is.na(PAdj), PAdj < alpha)
  if (nrow(pass) == 0) {
    return(NULL)
  }

  ext <- long %>% filter(Field %in% pass$Field)

  spread <- ext %>%
    filter(Column != "Overall") %>%
    group_by(Field) %>%
    summarise(
      Spread = diff(range(Value, na.rm = TRUE)),
      Scale = mean(abs(Value), na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(Rel = if_else(Scale > 0, Spread / Scale, 0)) %>%
    arrange(desc(Rel)) %>%
    slice_head(n = maxPanels)

  df <- ext %>%
    filter(Field %in% spread$Field) %>%
    mutate(Label = str_wrap(Label, width = 34))
  ov <- df %>% filter(Column == "Overall") %>% select(Label, Ref = Value)
  df <- df %>% filter(Column != "Overall") %>% left_join(ov, by = "Label")

  p <- ggplot(df, aes(y = fct_rev(Column))) +
    geom_segment(
      aes(x = Ref, xend = Value, yend = fct_rev(Column)),
      colour = "grey60",
      linewidth = 0.5
    ) +
    geom_point(aes(x = Ref), colour = "grey45", size = 1.6) +
    geom_point(aes(x = Value, colour = Column), size = 2.1) +
    scale_colour_viridis_d(begin = 0.15, end = 0.8, guide = "none") +
    facet_wrap(~Label, scales = "free_x", ncol = 2) +
    labs(x = "Weighted estimate (grey point is the group overall)", y = NULL) +
    theme_minimal(base_size = 9) +
    theme(
      axis.text.y = element_text(hjust = 0),
      panel.grid.major.y = element_blank(),
      strip.text = element_text(size = 7.5),
      plot.title = element_text(size = 9.5, face = "bold")
    )

  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 80))
  }
  p
}
