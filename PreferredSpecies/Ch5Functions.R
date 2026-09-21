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

# --- Clustering inputs (D121, uncentred) ----------------------------------
# Fallback labels apply only where Labels.csv carries none, so a missing
# label never blanks a row.
ch5.input.vars <- tibble::tribble(
  ~Field, ~Block, ~Transform, ~Fallback,
  "attitude_catch", "Attitude", "none", "Attitude: catch",
  "attitude_numbers", "Attitude", "none", "Attitude: numbers",
  "attitude_size", "Attitude", "none", "Attitude: size",
  "attitude_harvest", "Attitude", "none", "Attitude: harvest",
  "motivation_pp", "Motivation", "none", "Motivation: personal pleasure",
  "motivation_natural", "Motivation", "none", "Motivation: nature",
  "motivation_social", "Motivation", "none", "Motivation: social",
  "motivation_resource", "Motivation", "none", "Motivation: resource",
  "reg_comprehension", "Regulations", "none", "Regulations: comprehension",
  "reg_sitesupport", "Regulations", "none", "Regulations: site support",
  "reg_uniform", "Regulations", "none", "Regulations: uniformity",
  "C1Total_days", "Effort", "log1p", "Total days fished",
  "D4j", "Preferred species (inputs)", "none", "Size allowed to harvest",
  "D4l", "Preferred species (inputs)", "none", "Number allowed to harvest"
)

ch5.input.blocks <- c(
  "Attitude",
  "Motivation",
  "Regulations",
  "Effort",
  "Preferred species (inputs)"
)

# D4 a-i, k, m: every D4 item except the two that are clustering inputs.
ch5.d4.display <- paste0("D4", c(letters[1:9], "k", "m"))

# Blocks whose rows carry an omnibus p and are subject to the screen. One
# combined Holm family across both, at the user's direction, which supersedes
# the earlier rule that the D4 items were always shown.
ch5.tested.blocks <- c("Preferred-species items", "Other characteristics")

ch5.block.order <- c(ch5.input.blocks, ch5.tested.blocks)

Ch5InputLabel <- function(field, fallback, labels) {
  op <- ScaleLabel(field, labels)
  if_else(op == field, fallback, op)
}

# --- Row specs ------------------------------------------------------------
# The inputs, displayed on their own untransformed scale: log1p is a fitting
# device, not a reporting one. No p, because differences on the inputs are
# produced by the clustering itself (D127).
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
Ch5InputFrame <- function(mydata) {
  op <- mydata %>%
    transmute(across(all_of(ch5.input.vars$Field), as.numeric)) %>%
    mutate(C1Total_days = log1p(C1Total_days))
  op[, ch5.input.vars$Field]
}

Ch5Complete <- function(mydata) {
  rowSums(is.na(Ch5InputFrame(mydata))) == 0
}

# A zero-variance column can occur in the smaller fits; scale() would return
# NaN and silently poison the whole distance calculation.
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
      sub <- if (is.null(Members)) {
        mydata
      } else {
        mydata %>% filter(as.character(B1) %in% Members)
      }
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

# --- Choice of k (D124, amended) ------------------------------------------
# Normalized elbow: both axes are rescaled to [0, 1] and the chosen k is the
# point furthest from the chord joining the ends of the curve. Rescaling
# matters -- an unnormalized chord distance depends on the units of WSS.
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

# --- The fit --------------------------------------------------------------
Ch5Fit <- function(
  mydata,
  groupLabel,
  members = NULL,
  kRange = ch5.k.range,
  seed = ch5.seed
) {
  grp <- if (is.null(members)) {
    mydata
  } else {
    mydata %>% filter(as.character(B1) %in% members)
  }
  keep <- Ch5Complete(grp)
  X <- Ch5Scale(Ch5InputFrame(grp[keep, , drop = FALSE]))

  kCap <- min(max(kRange), floor(nrow(X) / ch5.min.cluster))
  ks <- 1:max(2, min(max(kRange), kCap))
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
    MeetsFloor = purrr::map_dbl(kms, function(m) min(m$size)) >= ch5.min.cluster
  )

  kElbow <- Ch5Elbow(wss, ks, kRange)
  kUse <- kElbow
  while (kUse > min(kRange) && diagnostics$MinSize[diagnostics$k == kUse] < ch5.min.cluster) {
    kUse <- kUse - 1
  }
  km <- kms[[kUse]]

  # Types are numbered by descending weighted share, so Type 1 is always the
  # largest and the numbering is not an artefact of kmeans' internal order.
  ord <- tibble(cl = km$cluster, w = grp$postWeight[keep]) %>%
    group_by(cl) %>%
    summarise(W = sum(w), .groups = "drop") %>%
    arrange(desc(W)) %>%
    mutate(new = row_number())
  typeLevels <- paste("Type", seq_len(kUse))

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
    k = kUse,
    kElbow = kElbow,
    kCap = kCap,
    steppedDown = kUse < kElbow,
    varExplained = 100 * (1 - wss[kUse] / wss[1]),
    diagnostics = diagnostics,
    typeLevels = typeLevels
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
  p <- ggplot(fit$diagnostics, aes(x = k, y = WSSPct)) +
    geom_vline(
      xintercept = fit$k,
      colour = "grey60",
      linetype = "22",
      linewidth = 0.5
    ) +
    geom_line(linewidth = 0.5) +
    geom_point(size = 1.8) +
    scale_x_continuous(breaks = fit$diagnostics$k) +
    labs(
      x = "Number of types (k)",
      y = "Within-cluster sum of squares (% of k = 1)"
    ) +
    theme_minimal(base_size = 9) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(size = 9.5, face = "bold"),
      plot.subtitle = element_text(size = 7, face = "italic")
    ) +
    labs(subtitle = paste0("Dashed line marks the k used: ", fit$k))

  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 80))
  }
  p
}

# Standardized input profile: the shape of each type across the 14 inputs.
# Points are weighted means of the z-scored inputs -- the fit is unweighted,
# everything reported is weighted (D125).
Ch5ProfilePlot <- function(fit, labels, titleText = NULL) {
  lab <- ch5.input.vars %>%
    transmute(Field, Block, Label = Ch5InputLabel(Field, Fallback, labels))

  df <- as_tibble(fit$X) %>%
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
      x = "Weighted mean, standardized within this fit (0 = group mean)",
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
# most ch5.max.ext.plots panels, chosen by the largest relative spread across
# types (D129).
ch5.max.ext.plots <- 5

Ch5ExternalPlot <- function(
  long,
  meta = Ch5Meta(long),
  alpha = ch5.alpha,
  maxPanels = ch5.max.ext.plots,
  titleText = NULL
) {
  pass <- meta %>%
    filter(
      Block == "Other characteristics",
      !is.na(PAdj),
      PAdj < alpha
    )
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
