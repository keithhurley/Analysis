options(stringsAsFactors = FALSE)
library(dplyr)
library(tidyr)
library(tibble)
library(forcats)
library(purrr)
library(foreach)
library(survey)
library(ggplot2)
library(grid)
library(stringr)

# Captions ----------------------------------------------------------------
# The inherited captions come from CrossTabTables/CrossTabTableFunctions.R,
# which this report sources read-only (D27). Only the ones below are new.
caption.sizes <-
  "Respondents is the raw unweighted count. Effective n is the Kish effective sample size, (sum w)^2 / sum(w^2), which is the quantity that governs confidence interval width. Weighted respondents rescales the survey weights to sum to the analysis sample."
caption.comparison <-
  "Rows are the individual species within the family group, followed by the family group as a whole. The family row is computed on the same respondents as the species rows above it, so it is their weighted combination rather than a separate sample."
caption.banner <-
  "Family columns contain the species columns listed beneath them, so a respondent who prefers largemouth bass is counted in both the Bass column and the Largemouth bass column. Preferred-group columns therefore overlap and do not sum to the analysis sample."
caption.contrasts <-
  "Each row compares two species on the outcome named. Difference is the weighted mean of the second species minus the first, with a 95% confidence interval; it is a design-based comparison on weights rescaled to the sample size. g is Hedges' g computed on effective sample sizes. Bonferroni p multiplies the unadjusted p-value by the number of species comparisons available within that family for that outcome."

# Banner definition -------------------------------------------------------
# Family groups (ANALYSIS_PLAN.md 2.1; D18, D22) used for coverage accounting.
banner.levels <- c(
  "Walleye / Sauger",
  "Bass",
  "No preference",
  "Panfish / Sunfish",
  "Catfish",
  "Trout",
  "Moronides",
  "Esocids"
)

# The displayed banner (D31). Families that Chapter 1 broke out carry BOTH a
# combined column and one column per species, so the columns overlap. Esocids
# is split outright and has no combined column.
banner.definition <- tibble(
  Column = c(
    "Walleye / Sauger",
    "Bass",
    "Largemouth bass",
    "Smallmouth bass",
    "Panfish / Sunfish",
    "Crappie",
    "Bluegill / Sunfish",
    "Yellow perch",
    "Catfish",
    "Channel catfish",
    "Blue catfish",
    "Flathead catfish",
    "Moronides",
    "Trout",
    "Northern pike",
    "Muskellunge / Tiger musky",
    "No preference"
  ),
  # "Split" marks Northern pike and Muskellunge, which replaced the Esocids
  # family column outright (D31) and so have no parent column to sit under.
  Type = c(
    "Family",
    "Family",
    "Species",
    "Species",
    "Family",
    "Species",
    "Species",
    "Species",
    "Family",
    "Species",
    "Species",
    "Species",
    "Family",
    "Family",
    "Split",
    "Split",
    "Family"
  ),
  Members = list(
    "Walleye / Sauger",
    c("Largemouth bass", "Smallmouth bass"),
    "Largemouth bass",
    "Smallmouth bass",
    c("Crappie", "Bluegill / Sunfish", "Yellow perch"),
    "Crappie",
    "Bluegill / Sunfish",
    "Yellow perch",
    c("Channel catfish", "Blue catfish", "Flathead catfish"),
    "Channel catfish",
    "Blue catfish",
    "Flathead catfish",
    c("Striped bass", "Wiper", "White bass"),
    "Trout",
    "Northern pike",
    "Muskellunge / Tiger musky",
    "I do not prefer any particular type of fish"
  )
)

# Genus -> species map for the within-family comparisons (D18 removed Bullhead)
genus.species <- tribble(
  ~Genus              , ~Species                    ,
  "Bass"              , "Largemouth bass"           ,
  "Bass"              , "Smallmouth bass"           ,
  "Panfish / Sunfish" , "Crappie"                   ,
  "Panfish / Sunfish" , "Bluegill / Sunfish"        ,
  "Panfish / Sunfish" , "Yellow perch"              ,
  "Esocids"           , "Northern pike"             ,
  "Esocids"           , "Muskellunge / Tiger musky" ,
  "Catfish"           , "Channel catfish"           ,
  "Catfish"           , "Blue catfish"              ,
  "Catfish"           , "Flathead catfish"
)

genus.levels <- unique(genus.species$Genus)

motivation.vars <- c(
  "motivation_pp",
  "motivation_natural",
  "motivation_social",
  "motivation_resource"
)

attitude.vars <- c(
  "attitude_catch",
  "attitude_numbers",
  "attitude_size",
  "attitude_harvest"
)

# Collapse B1 into the 8 family groups. Anything outside them becomes NA, which
# is what defines "receives no banner column" for the coverage accounting.
AssignBannerGroup <- function(B1) {
  g <- fct_collapse(
    B1,
    "Bass" = c("Largemouth bass", "Smallmouth bass"),
    "Moronides" = c("Striped bass", "Wiper", "White bass"),
    "Panfish / Sunfish" = c("Bluegill / Sunfish", "Crappie", "Yellow perch"),
    "Walleye / Sauger" = "Walleye / Sauger",
    "Esocids" = c("Northern pike", "Muskellunge / Tiger musky"),
    "Catfish" = c("Channel catfish", "Blue catfish", "Flathead catfish"),
    "Trout" = "Trout",
    "No preference" = "I do not prefer any particular type of fish"
  )

  factor(
    if_else(as.character(g) %in% banner.levels, as.character(g), NA_character_),
    levels = banner.levels
  )
}

# Generic helpers ---------------------------------------------------------
Kish <- function(w) {
  if (length(w) == 0 || sum(w) == 0) {
    return(0)
  }
  (sum(w)^2) / sum(w^2)
}

WeightedSD <- function(x, w) {
  m <- weighted.mean(x, w, na.rm = TRUE)
  sqrt(sum((w / sum(w)) * (x - m)^2, na.rm = TRUE))
}

# D21: CI to 2 significant figures, estimate to the same decimal place.
FmtPct <- function(value, ci) {
  paste0(
    formatC(value, format = "f", digits = 1),
    " \u00b1 ",
    formatC(ci, format = "f", digits = 2)
  )
}

FmtCount <- function(x, ci = NULL) {
  op <- formatC(round(x), format = "d", big.mark = ",")
  if (!is.null(ci)) {
    op <- paste0(
      op,
      " \u00b1 ",
      formatC(round(ci), format = "d", big.mark = ",")
    )
  }
  op
}

FmtMean <- function(value, ci) {
  paste0(
    formatC(value, format = "f", digits = 3),
    " \u00b1 ",
    formatC(ci, format = "f", digits = 3)
  )
}

# Chapter 2 item tables use coarser precision than Chapter 1's scale-mean
# comparisons (D21 justified 3 dp there specifically for species-vs-species
# contrasts); the user asked for 1 dp / 2 dp here instead.
FmtMeanD4 <- function(value, ci) {
  paste0(
    formatC(value, format = "f", digits = 1),
    " \u00b1 ",
    formatC(ci, format = "f", digits = 2)
  )
}

FmtP <- function(p) {
  if_else(p < 0.001, "<0.001", formatC(p, format = "f", digits = 3))
}

# Flextable rendering -----------------------------------------------------
# Cloned verbatim from 2025CrossTabReport.rmd L50-86 so styling matches.
CreateFlex <- function(x, mergeOnFirst = FALSE) {
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
    width(j = 1, width = 1.2) %>%
    set_table_properties(layout = "autofit", width = 1) %>%
    # D33: repeat the header row when a table splits across a page, and keep
    # body rows with the header so a table cannot orphan its header at a page
    # break. Without this, consecutive tables and page splits produced the
    # duplicated/misplaced header rows the user reported.
    paginate(init = TRUE, hdr_ftr = TRUE)

  myFlex
}

# Species sample-size and population table (ANALYSIS_PLAN.md 3.2) ---------
#
# Percent and its CI are taken straight from base.summary.percent.selectOne so
# they are identical by construction to the crosstab report's Preferred Fish
# table (verified V7, 23/23 cells). Every other column is a rescaling of that
# same percentage, so nothing here can drift from the crosstabs.
#
# popTotalAll is the weighted 2025 angler population over ALL respondents,
# including those who left B1 blank. D29 reports expansions on this basis,
# which assumes B1 item non-response is unrelated to species preference.
SpeciesSizeTable <- function(mydata, popTotalAll) {
  pctTbl <- base.summary.percent.selectOne(mydata, B1) %>%
    as_tibble() %>%
    transmute(
      Species = Response,
      Respondents = Number,
      Percent = Value,
      PercentCI = CI
    )

  effTbl <- mydata %>%
    filter(!is.na(B1)) %>%
    group_by(Species = B1, .drop = FALSE) %>%
    summarise(EffectiveN = Kish(postWeight), .groups = "drop")

  nAnalysis <- sum(!is.na(mydata$B1))

  pctTbl %>%
    left_join(effTbl, by = "Species") %>%
    mutate(
      WeightedRespondents = Percent / 100 * nAnalysis,
      WeightedRespondentsCI = PercentCI / 100 * nAnalysis,
      TotalAnglers = Percent / 100 * popTotalAll,
      TotalAnglersCI = PercentCI / 100 * popTotalAll
    ) %>%
    arrange(desc(Respondents))
}

ArrangeSpeciesSizeTable <- function(sizeTbl) {
  sizeTbl %>%
    transmute(
      Species = as.character(Species),
      Respondents = FmtCount(Respondents),
      `Effective n` = formatC(EffectiveN, format = "f", digits = 1),
      `Weighted respondents` = FmtCount(
        WeightedRespondents,
        WeightedRespondentsCI
      ),
      `% of angler population` = FmtPct(Percent, PercentCI),
      `Total anglers` = FmtCount(TotalAnglers, TotalAnglersCI)
    )
}

# Banner column sizes (3.3). Columns overlap, so there is no total row; the
# distinct-coverage figure is reported separately in the report text.
BannerSizeTable <- function(mydata) {
  banner.definition %>%
    rowwise() %>%
    mutate(
      Respondents = sum(as.character(mydata$B1) %in% Members),
      EffectiveN = Kish(mydata$postWeight[as.character(mydata$B1) %in% Members])
    ) %>%
    ungroup() %>%
    transmute(
      `Preferred group` = if_else(
        Type == "Species",
        paste0("   ", Column),
        Column
      ),
      Level = recode(
        Type,
        "Family" = "Family group",
        "Species" = "Species within family",
        "Split" = "Species (family split)"
      ),
      Respondents = FmtCount(Respondents),
      `Effective n` = formatC(EffectiveN, format = "f", digits = 1)
    )
}

# The respondents inside the report universe who receive no banner column.
BannerExclusionTable <- function(mydata) {
  excluded <- mydata %>%
    filter(!is.na(B1), is.na(B1banner)) %>%
    group_by(`Excluded from preferred groups` = B1, .drop = FALSE) %>%
    summarise(Respondents = n(), .groups = "drop") %>%
    filter(Respondents > 0 | `Excluded from preferred groups` == "Sturgeon") %>%
    arrange(desc(Respondents)) %>%
    mutate(
      `Excluded from preferred groups` = as.character(
        `Excluded from preferred groups`
      )
    )

  bind_rows(
    excluded,
    tibble(
      `Excluded from preferred groups` = "Total",
      Respondents = sum(excluded$Respondents)
    )
  ) %>%
    mutate(Respondents = FmtCount(Respondents))
}

# Within-family comparison blocks (ANALYSIS_PLAN.md 3.4) ------------------

# Display label for a derived scale score, from Labels.csv. Falls back to the
# variable name so a missing label never silently blanks a column header.
ScaleLabel <- function(varName, labels) {
  op <- labels$Label[match(varName, labels$Response)]
  if_else(is.na(op), varName, op)
}

SpeciesInGenus <- function(genus) {
  genus.species$Species[genus.species$Genus == genus]
}

# Rows = each species in the genus, then the genus as a whole. Columns = the
# outcome scales. The genus row is base.summary.means() with no group variable
# on the SAME subset, so it is the weighted combination of the rows above it.
#
# Each outcome carries its own *_AnsweredAll gate (D19), so n can differ
# between columns; that is inherited behaviour, not a bug.
GenusMeansTable <- function(mydata, genus, outcomeVars, labels) {
  species <- SpeciesInGenus(genus)
  rowOrder <- c(species, paste("All", genus))

  cols <- lapply(outcomeVars, function(v) {
    gate <- paste0(v, "_AnsweredAll")

    sub <- mydata %>%
      filter(as.character(B1) %in% species) %>%
      filter(.data[[gate]] == TRUE)

    bind_rows(
      base.summary.means(sub, !!sym(v), myGroupVar = B1) %>%
        mutate(Group = as.character(Group)),
      base.summary.means(sub, !!sym(v)) %>%
        mutate(Group = paste("All", genus))
    ) %>%
      as_tibble() %>%
      transmute(
        Group,
        !!ScaleLabel(v, labels) := paste0(
          FmtMean(Value, CI),
          " (",
          Number,
          ")"
        )
      )
  })

  Reduce(function(a, b) full_join(a, b, by = "Group"), cols) %>%
    mutate(Group = factor(Group, levels = rowOrder)) %>%
    arrange(Group) %>%
    rename(Species = Group) %>%
    mutate(Species = as.character(Species))
}

# Days fished. Universe copied from 2025CrossTabReport.rmd L976: non-missing
# C1Total_days and C1_AnsweredAll. Median CI is the inherited 1000-rep weighted
# bootstrap at seed 7361, formatted lower/median/upper as in ArrangeTableA.
GenusEffortTable <- function(mydata, genus) {
  species <- SpeciesInGenus(genus)
  rowOrder <- c(species, paste("All", genus))

  sub <- mydata %>%
    filter(as.character(B1) %in% species) %>%
    filter(!is.na(C1Total_days) & C1_AnsweredAll == TRUE)

  means <- bind_rows(
    base.summary.means(sub, C1Total_days, myGroupVar = B1) %>%
      mutate(Group = as.character(Group)),
    base.summary.means(sub, C1Total_days) %>%
      mutate(Group = paste("All", genus))
  ) %>%
    as_tibble() %>%
    transmute(
      Group,
      `Mean days fished` = paste0(
        formatC(Value, format = "f", digits = 1),
        " \u00b1 ",
        formatC(CI, format = "f", digits = 2),
        " (",
        Number,
        ")"
      )
    )

  medians <- bind_rows(
    base.summary.medians(sub, C1Total_days, myGroupVar = B1) %>%
      mutate(Group = as.character(Group)),
    base.summary.medians(sub, C1Total_days) %>%
      mutate(Group = paste("All", genus))
  ) %>%
    as_tibble() %>%
    transmute(
      Group,
      `Median days fished` = paste0(
        formatC(CIlower, format = "f", digits = 1),
        "/",
        formatC(Value, format = "f", digits = 1),
        "/",
        formatC(CIupper, format = "f", digits = 1),
        " (",
        Number,
        ")"
      )
    )

  full_join(means, medians, by = "Group") %>%
    mutate(Group = factor(Group, levels = rowOrder)) %>%
    arrange(Group) %>%
    transmute(
      Species = as.character(Group),
      `Mean days fished`,
      `Median days fished`
    )
}

# Pairwise species contrasts (ANALYSIS_PLAN.md 3.5; D32) ------------------
#
# One design-based two-sample comparison per species pair per outcome. No
# omnibus Wald F: dropped at the user's direction (D32), so there is no model
# R-squared / eta-squared either. Weights are rescaled to the pair's sample
# size before svydesign(); note this is presentational, since survey's
# linearization SEs are scale-invariant in the weights (D20).
#
# Bonferroni multiplies the raw p by the number of contrasts available within
# that family for that outcome (D24): 1 for Bass and Esocids, 3 for Panfish
# and Catfish.
PairwiseContrasts <- function(mydata, genus, outcomeVar, gate = NULL) {
  species <- SpeciesInGenus(genus)

  sub <- mydata %>%
    filter(as.character(B1) %in% species)

  if (!is.null(gate)) {
    sub <- sub %>% filter(.data[[gate]] == TRUE)
  }

  sub <- sub %>% filter(!is.na(.data[[outcomeVar]]))

  pairs <- combn(species, 2, simplify = FALSE)

  op <- map_dfr(pairs, function(p) {
    s <- sub %>% filter(as.character(B1) %in% p)

    # A pair with an empty arm cannot be compared; report it rather than error.
    if (length(unique(as.character(s$B1))) < 2) {
      return(tibble(
        Genus = genus,
        Outcome = outcomeVar,
        SpeciesA = p[1],
        SpeciesB = p[2],
        nA = sum(as.character(s$B1) == p[1]),
        nB = sum(as.character(s$B1) == p[2]),
        Difference = NA_real_,
        CIlower = NA_real_,
        CIupper = NA_real_,
        G = NA_real_,
        P = NA_real_
      ))
    }

    s$grp <- factor(as.character(s$B1), levels = p)
    s$w_norm <- s$postWeight * nrow(s) / sum(s$postWeight)
    s$outcome <- as.numeric(s[[outcomeVar]])

    des <- svydesign(ids = ~1, weights = ~w_norm, data = s)
    tt <- svyttest(outcome ~ grp, des)

    a <- s %>% filter(grp == p[1])
    b <- s %>% filter(grp == p[2])
    effA <- Kish(a$postWeight)
    effB <- Kish(b$postWeight)
    sdA <- WeightedSD(a$outcome, a$postWeight)
    sdB <- WeightedSD(b$outcome, b$postWeight)

    sPooled <- sqrt(
      ((effA - 1) * sdA^2 + (effB - 1) * sdB^2) / (effA + effB - 2)
    )
    hedgesJ <- 1 - 3 / (4 * (effA + effB) - 9)

    tibble(
      Genus = genus,
      Outcome = outcomeVar,
      SpeciesA = p[1],
      SpeciesB = p[2],
      nA = nrow(a),
      nB = nrow(b),
      # svyttest returns an htest; coef()/confint() are not defined for it, so
      # read the components directly. estimate is SpeciesB minus SpeciesA.
      Difference = as.numeric(tt$estimate),
      CIlower = as.numeric(tt$conf.int[1]),
      CIupper = as.numeric(tt$conf.int[2]),
      G = as.numeric(tt$estimate) / sPooled * hedgesJ,
      P = as.numeric(tt$p.value)
    )
  })

  op %>%
    mutate(
      Contrasts = sum(!is.na(P)),
      PBonferroni = pmin(1, P * Contrasts)
    )
}

ContrastTable <- function(mydata, genus, outcomeVars, labels, gated = TRUE) {
  map_dfr(outcomeVars, function(v) {
    PairwiseContrasts(
      mydata,
      genus,
      v,
      gate = if (gated) paste0(v, "_AnsweredAll") else NULL
    )
  }) %>%
    transmute(
      Outcome = ScaleLabel(Outcome, labels),
      Comparison = paste(SpeciesA, "vs.", SpeciesB),
      n = paste0(nA, " / ", nB),
      Difference = paste0(
        formatC(Difference, format = "f", digits = 3),
        " (",
        formatC(CIlower, format = "f", digits = 3),
        ", ",
        formatC(CIupper, format = "f", digits = 3),
        ")"
      ),
      g = formatC(G, format = "f", digits = 2),
      `p` = FmtP(P),
      `Bonferroni p` = FmtP(PBonferroni)
    )
}

EffortContrastTable <- function(mydata, genus) {
  PairwiseContrasts(mydata, genus, "C1Total_days", gate = "C1_AnsweredAll") %>%
    transmute(
      Comparison = paste(SpeciesA, "vs.", SpeciesB),
      n = paste0(nA, " / ", nB),
      `Difference in days` = paste0(
        formatC(Difference, format = "f", digits = 1),
        " (",
        formatC(CIlower, format = "f", digits = 1),
        ", ",
        formatC(CIupper, format = "f", digits = 1),
        ")"
      ),
      g = formatC(G, format = "f", digits = 2),
      `p` = FmtP(P),
      `Bonferroni p` = FmtP(PBonferroni)
    )
}

# Chapter 2: the D4 battery, one table per item (D63) ---------------------
caption.d4item <-
  "Cells are the weighted percentage of the row group giving that response, with a 95 percent confidence interval. Mean scores the five responses from 1 (Strongly Disagree) to 5 (Strongly Agree). N is the raw unweighted number of respondents in the row group who answered the item."
caption.d4gate <-
  "The battery was routed to anglers who named a preferred species, so respondents in the No preference row were not asked these items; the few who answered anyway are reported as they stand rather than dropped."

d4.items <- paste0("D4", letters[1:13])

# Item wording lives in the codebook's Question column keyed by Field. The
# battery stem is separate and comes from GetQuestion(q, D4, ...), which
# hardcodes it rather than reading the codebook (F15).
ItemQuestionText <- function(item, codebook) {
  txt <- unique(trimws(as.character(codebook$Question[codebook$Field == item])))
  txt <- txt[!is.na(txt) & nzchar(txt)]
  if (length(txt) == 0) item else txt[1]
}

# Rows = Overall then every banner column; columns = the response categories,
# the item mean, and the respondent count. Each row is computed on its own
# subset, which is what allows family rows to overlap their species rows (D31).
# Groups with no respondents answering the item return blank cells rather than
# being dropped, so a routed-away or empty group stays visible.
D4ItemTable <- function(mydata, item, categories = NULL) {
  if (is.null(categories)) {
    categories <- levels(mydata[[item]])
  }

  rowSpec <- bind_rows(
    tibble(RowLabel = "Overall", Members = list(NULL)),
    banner.definition %>%
      transmute(
        RowLabel = if_else(Type == "Species", paste0("   ", Column), Column),
        Members
      )
  )

  op <- map2_dfr(
    rowSpec$RowLabel,
    rowSpec$Members,
    function(rowLabel, members) {
      sub <- mydata
      if (!is.null(members)) {
        sub <- sub %>% filter(as.character(B1) %in% members)
      }
      sub <- sub %>% filter(!is.na(.data[[item]]))

      blank <- set_names(rep("", length(categories)), categories)

      if (nrow(sub) == 0) {
        return(as_tibble(c(
          list(Group = rowLabel),
          as.list(blank),
          list(Mean = "", N = "0")
        )))
      }

      pct <- base.summary.percent.selectOne(sub, !!sym(item)) %>% as_tibble()
      mn <- base.summary.means(sub, !!sym(item)) %>% as_tibble()

      cells <- blank
      idx <- match(as.character(pct$Response), categories)
      cells[idx[!is.na(idx)]] <- FmtPct(pct$Value, pct$CI)[!is.na(idx)]

      as_tibble(c(
        list(Group = rowLabel),
        as.list(cells),
        list(
          Mean = FmtMeanD4(mn$Value, mn$CI),
          N = FmtCount(sum(pct$Number))
        )
      ))
    }
  )

  names(op)[names(op) == "Group"] <- "Preferred species"
  names(op)[names(op) == "Mean"] <- paste0("Mean \u00b1 CI")
  op
}

# Chapter 2 figures (D72) --------------------------------------------------
# One row spec shared by both plot data-builders below, so the row set and
# order can never drift apart between the percent and means figures.
D4RowSpec <- function(includeOverall) {
  spec <- banner.definition %>%
    transmute(
      RawLabel = Column,
      IndentedLabel = if_else(Type == "Species", paste0("   ", Column), Column),
      Type,
      Members
    )
  if (includeOverall) {
    spec <- bind_rows(
      tibble(
        RawLabel = "Overall",
        IndentedLabel = "Overall",
        Type = "Overall",
        Members = list(NULL)
      ),
      spec
    )
  }
  spec$Order <- seq_len(nrow(spec))
  spec
}

# Long-format percent data for the stacked bar figure: one row per
# group x response category. N is the row's own respondent count for THIS
# item (not the fixed banner size), since a small item-level N is what
# produces the thin/degenerate bars for the smallest groups.
D4PercentLong <- function(mydata, item, categories) {
  spec <- D4RowSpec(includeOverall = TRUE)
  purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      sub <- sub %>% filter(!is.na(.data[[item]]))
      if (nrow(sub) == 0) {
        return(tibble(
          Order = Order,
          RawLabel = RawLabel,
          IndentedLabel = IndentedLabel,
          Type = Type,
          N = 0L,
          Response = factor(categories, levels = categories),
          Value = NA_real_,
          CI = NA_real_
        ))
      }
      pct <- base.summary.percent.selectOne(sub, !!sym(item)) %>% as_tibble()
      tibble(
        Order = Order,
        RawLabel = RawLabel,
        IndentedLabel = IndentedLabel,
        Type = Type,
        N = sum(pct$Number),
        Response = factor(as.character(pct$Response), levels = categories),
        Value = pct$Value,
        CI = pct$CI
      )
    }
  )
}

# Long-format means data. Banner columns only by default (17 rows, Overall
# excluded, matching the means-ordered figure); includeOverall = TRUE adds the
# Overall row too, used by the 2018-2025 slope figure (D76).
D4MeansLong <- function(mydata, item, includeOverall = FALSE) {
  spec <- D4RowSpec(includeOverall = includeOverall)
  purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      # D80 bugfix: Members is NULL for the Overall row. Filtering
      # unconditionally by `B1 %in% Members` matched zero rows in that case
      # (`x %in% NULL` is always FALSE), so includeOverall = TRUE never
      # actually produced an Overall row -- silently, via the nrow(sub) == 0
      # branch below. D4PercentLong already guarded this correctly; this
      # brings D4MeansLong in line with it.
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      sub <- sub %>% filter(!is.na(.data[[item]]))
      if (nrow(sub) == 0) {
        return(NULL)
      }
      mn <- base.summary.means(sub, !!sym(item)) %>% as_tibble()
      tibble(
        RawLabel = RawLabel,
        Type = Type,
        N = mn$Number,
        Mean = mn$Value,
        CI = mn$CI
      )
    }
  )
}

# Response-category fill palette (D73): viridis across the five levels, with
# Neutral swapped for a light neutral gray at the user's request. The other
# four levels keep the exact colors viridis(5) would have assigned them.
D4FillColors <- function(categories) {
  cols <- viridisLite::viridis(length(categories))
  neutralIdx <- which(categories == "Neutral")
  if (length(neutralIdx) == 1) {
    cols[neutralIdx] <- "grey80"
  }
  set_names(cols, categories)
}

# Horizontal 100% stacked bar, rows in table order (Overall on top, species
# indented under family), fill = response category.
#
# D73: axis text is left-justified so the species indent (leading spaces) is
# actually visible -- right-justified text (the default) pins every label's
# last character to the axis, which hides a leading indent entirely.
D4PercentStackPlot <- function(mydata, item, categories, titleText = NULL) {
  df <- D4PercentLong(mydata, item, categories) %>%
    mutate(
      Label = paste0(
        IndentedLabel,
        " (n=",
        formatC(N, format = "d", big.mark = ","),
        ")"
      )
    )

  labelOrder <- df %>% distinct(Order, Label) %>% arrange(Order) %>% pull(Label)
  df <- df %>% mutate(Label = factor(Label, levels = rev(labelOrder)))

  p <- ggplot(df, aes(x = Value, y = Label, fill = Response)) +
    # reverse = TRUE: geom_col's default stacking otherwise puts the last
    # factor level (Strongly Agree) leftmost on a horizontal bar, opposite
    # of the table's left-to-right response order.
    geom_col(width = 0.7, position = position_stack(reverse = TRUE)) +
    scale_fill_manual(
      values = D4FillColors(categories),
      name = NULL,
      breaks = categories
    ) +
    scale_x_continuous(
      expand = expansion(mult = c(0, 0.02)),
      labels = function(x) paste0(x, "%")
    ) +
    labs(x = NULL, y = NULL) +
    theme_minimal(base_size = 9) +
    theme(
      legend.position = "bottom",
      legend.text = element_text(size = 7.5),
      legend.key.size = unit(0.35, "cm"),
      legend.margin = margin(t = -4),
      axis.text.y = element_text(hjust = 0),
      plot.title = element_text(size = 9.5, face = "bold")
    )

  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 60))
  }
  p
}

# 2018-2025 slope data (D76). Includes Overall alongside the 17 banner rows
# (unlike the means-ordered figure); "No preference" is excluded here only --
# in 2018, 224 of 292 No-preference respondents answered a given D4 item,
# against 50 of 339 in 2025, indicating the battery was routed to that group
# very differently between waves, so a year-over-year comparison on that row
# would partly reflect routing rather than attitude (flagged to the user,
# accepted). Overlap/Reason let the caller (D4SlopePlot) decide what to draw
# and what to footnote; nothing is silently dropped from the returned tibble.
D4SlopeData <- function(mydata2025, mydata2018, item) {
  d25 <- D4MeansLong(mydata2025, item, includeOverall = TRUE) %>%
    mutate(Year = 2025)
  d18 <- D4MeansLong(mydata2018, item, includeOverall = TRUE) %>%
    mutate(Year = 2018)

  bind_rows(d25, d18) %>%
    filter(RawLabel != "No preference") %>%
    select(RawLabel, Type, Year, N, Mean, CI) %>%
    pivot_wider(
      names_from = Year,
      values_from = c(N, Mean, CI),
      names_sep = "_"
    ) %>%
    mutate(
      Overlap = !((Mean_2018 + CI_2018) < (Mean_2025 - CI_2025) |
        (Mean_2025 + CI_2025) < (Mean_2018 - CI_2018)),
      Reason = case_when(
        is.na(Mean_2018) ~ "no 2018 respondents answered this item",
        is.na(Mean_2025) ~ "no 2025 respondents answered this item",
        Overlap ~ "2018 and 2025 confidence intervals overlap",
        TRUE ~ NA_character_
      )
    )
}

# D78: exact wording from the user. No mention of the No preference
# exclusion here -- that reasoning stays in PROGRESS.md (D76), out of the
# figure. str_wrap guards against overflow if this text is ever lengthened.
caption.d4slope <- "*Only groups with non-overlapping 95% CI values between years are shown"
placeholder.d4slope <- "No group showed non-overlapping confidence intervals between 2018 and 2025."

# The 1-5 scale key that used to sit in the y-axis title now lives in a
# small italic subtitle instead (D78), shared with the means-ordered plot.
d4.scale.key <- "(1 = Strongly Disagree ... 5 = Strongly Agree)"

# Slope graph, one line per qualifying group, no error bars (per the user's
# instruction -- the CI already did its work as the inclusion filter).
D4SlopePlot <- function(mydata2025, mydata2018, item, titleText = NULL) {
  sd <- D4SlopeData(mydata2025, mydata2018, item)
  qualifying <- sd %>% filter(!is.na(Overlap), !Overlap)

  p <- ggplot() +
    scale_x_continuous(breaks = c(2018, 2025), limits = c(2016.5, 2032)) +
    coord_cartesian(ylim = c(1, 5), clip = "off") +
    scale_y_continuous(breaks = 1:5) +
    labs(
      x = NULL,
      y = "Mean response",
      subtitle = d4.scale.key,
      caption = str_wrap(caption.d4slope, width = 100)
    ) +
    theme_minimal(base_size = 9) +
    theme(
      plot.title = element_text(size = 9.5, face = "bold"),
      plot.subtitle = element_text(size = 7, face = "italic"),
      plot.caption = element_text(size = 7, hjust = 0),
      plot.margin = margin(t = 5, r = 80, b = 5, l = 5),
      legend.position = "none"
    )

  if (nrow(qualifying) == 0) {
    p <- p +
      annotate(
        "text",
        x = 2021.5,
        y = 3,
        label = str_wrap(placeholder.d4slope, width = 40),
        size = 3,
        fontface = "italic"
      )
  } else {
    long <- qualifying %>%
      transmute(
        RawLabel,
        Label = paste0(RawLabel, " (2018 n=", N_2018, "; 2025 n=", N_2025, ")")
      ) %>%
      left_join(
        bind_rows(
          qualifying %>% transmute(RawLabel, Year = 2018, Mean = Mean_2018),
          qualifying %>% transmute(RawLabel, Year = 2025, Mean = Mean_2025)
        ),
        by = "RawLabel"
      )

    endLabels <- long %>% filter(Year == 2025)

    p <- p +
      geom_line(
        data = long,
        aes(x = Year, y = Mean, color = RawLabel),
        linewidth = 0.9
      ) +
      geom_point(
        data = long,
        aes(x = Year, y = Mean, color = RawLabel),
        size = 2
      ) +
      geom_text(
        data = endLabels,
        aes(x = 2025.5, y = Mean, label = Label, color = RawLabel),
        hjust = 0,
        size = 3
      ) +
      scale_color_viridis_d(begin = 0.3, end = 0.8)
  }

  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 60))
  }
  p
}

# Vertical bar + 95% CI error bar, banner columns only, ordered highest mean
# (left) to lowest (right). Single flat viridis fill; no fill mapping, since
# the group is already on the x-axis and mapping it to fill too would
# dual-encode the same variable.
D4MeansOrderedPlot <- function(mydata, item, titleText = NULL) {
  flatColor <- viridisLite::viridis(1, begin = 0.45)

  df <- D4MeansLong(mydata, item) %>%
    mutate(
      Label = paste0(
        RawLabel,
        " (n=",
        formatC(N, format = "d", big.mark = ","),
        ")"
      )
    ) %>%
    mutate(Label = fct_reorder(Label, Mean, .desc = TRUE))

  p <- ggplot(df, aes(x = Label, y = Mean)) +
    geom_col(fill = flatColor, width = 0.7) +
    geom_errorbar(aes(ymin = Mean - CI, ymax = Mean + CI), width = 0.25) +
    # coord_cartesian clips the view at the Likert floor/ceiling without
    # dropping geom_col's bar (which is drawn from a baseline of 0) the way
    # scale_y_continuous(limits=...) would.
    coord_cartesian(ylim = c(1, 5)) +
    scale_y_continuous(breaks = 1:5) +
    # The 1-5 scale key moved from the axis title into a small italic
    # subtitle -- the full title made the axis label too long.
    labs(x = NULL, y = "Mean response", subtitle = d4.scale.key) +
    theme_minimal(base_size = 9) +
    theme(
      axis.text.x = element_text(angle = 40, hjust = 1),
      plot.title = element_text(size = 9.5, face = "bold"),
      plot.subtitle = element_text(size = 7, face = "italic")
    )

  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 60))
  }
  p
}


# Chapter 3: crosstabs of the remaining questions by preferred group ------
#
# Row set is identical to Chapter 2's: Overall first, then the 17 preferred
# groups with species indented under their family (D4RowSpec, reused
# unmodified). Every row is computed on its own subset, so family rows contain
# their species rows and rows must never be totalled (D31).
#
# Two N conventions coexist by design (D90): single-question tables carry one
# N column, as in Chapter 2, because every response column shares a
# denominator; battery and indicator tables carry N inside each cell, the
# inherited ArrangeTableA convention, because each column has its own universe.
caption.ch3selectone <-
  "Cells are the weighted percentage of the row group giving that response, with a 95 percent confidence interval. N is the raw unweighted number of respondents in the row group who answered the question."
caption.ch3selectall <-
  "Cells are the weighted percentage of the row group that selected each option, with a 95 percent confidence interval. Respondents could select more than one option, so a row does not sum to 100 percent. N is the raw unweighted number of respondents in the row group who answered the question."
caption.ch3means <-
  "Cells are the weighted mean for the row group with a 95 percent confidence interval, followed by the raw unweighted number of respondents contributing to that cell."
caption.ch3medians <-
  "Cells are the lower 95 percent confidence limit, the weighted median, and the upper 95 percent confidence limit, followed by the raw unweighted number of respondents. Median confidence limits come from the inherited 1,000-replicate weighted bootstrap."
caption.ch3indicator <-
  "Each column is a separate indicator computed on its own universe: cells are the weighted percentage of the row group falling in that category, with a 95 percent confidence interval, followed by the raw unweighted number of respondents in that column's universe. Columns overlap and must not be totalled."
caption.ch3rows <-
  "Rows are the preferred groups from Chapter 1, with individual species indented beneath the family group that contains them. Family rows include the respondents in their species rows, so rows overlap and must not be totalled."

FmtMeanN <- function(value, ci, n) {
  paste0(FmtMeanD4(value, ci), " (", FmtCount(n), ")")
}

FmtMedianN <- function(lower, value, upper, n, digits = 1) {
  paste0(
    formatC(lower, format = "f", digits = digits),
    "/",
    formatC(value, format = "f", digits = digits),
    "/",
    formatC(upper, format = "f", digits = digits),
    " (",
    FmtCount(n),
    ")"
  )
}

# Item text for a battery column header, daggered when the item is reverse
# coded WITHIN THE SCALE BEING DISPLAYED (inherited convention,
# 2025CrossTabReport.rmd L1467). Reversal is a property of the scale, not of
# the item: the codebook flags Q31a/b/d/f/i as reversed, but only for the
# bipolar orientation scale, which this report does not use (F31). Passing the
# reversed set explicitly keeps that distinction visible at the call site.
Ch3ItemLabel <- function(field, codebook, reversedFields = character(0)) {
  txt <- ItemQuestionText(field, codebook)
  if (field %in% reversedFields) paste0(txt, " \u2020") else txt
}

SubScaleFields <- function(scales, scaleName, subScaleName) {
  scales %>%
    filter(ScaleName == scaleName, SubScaleName == subScaleName) %>%
    pull(Field) %>%
    unique() %>%
    sort()
}

# Battery items that no sub-scale of the named scale claims, so they can be
# shown in their own table instead of disappearing from the report.
UnassignedFields <- function(scales, scaleName, allFields) {
  sort(setdiff(allFields, unique(scales$Field[scales$ScaleName == scaleName])))
}

# Single select-one question. One N column; an optional mean column for
# ordinal scales, matching Chapter 2's combined percent-and-mean layout (D64).
#
# meanVar takes the mean from a different variable than the one tabulated,
# which is what the age table needs: averaging the E3 band factor would return
# a mean band index, not a mean age. The single N column stays honest only
# while the two variables share their missingness, so the caller is expected to
# assert that (the age section does).
Ch3SelectOneTable <- function(
  mydata,
  var,
  categories = NULL,
  includeMean = FALSE,
  meanVar = NULL,
  meanLabel = "Mean \u00b1 CI"
) {
  if (is.null(categories)) {
    categories <- levels(mydata[[var]])
  }
  spec <- D4RowSpec(includeOverall = TRUE)

  op <- purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      sub <- sub %>% filter(!is.na(.data[[var]]))

      blank <- set_names(rep("", length(categories)), categories)
      if (nrow(sub) == 0) {
        return(as_tibble(c(
          list(Group = IndentedLabel),
          as.list(blank),
          if (includeMean) list(Mean = "") else NULL,
          list(N = "0")
        )))
      }

      pct <- base.summary.percent.selectOne(sub, !!sym(var)) %>% as_tibble()
      cells <- blank
      idx <- match(as.character(pct$Response), categories)
      cells[idx[!is.na(idx)]] <- FmtPct(pct$Value, pct$CI)[!is.na(idx)]

      meanCell <- NULL
      if (includeMean) {
        mv <- if (is.null(meanVar)) var else meanVar
        mnSub <- sub %>% filter(!is.na(.data[[mv]]))
        meanCell <- if (nrow(mnSub) == 0) {
          list(Mean = "")
        } else {
          mn <- base.summary.means(mnSub, !!sym(mv)) %>% as_tibble()
          list(Mean = FmtMeanD4(mn$Value, mn$CI))
        }
      }

      as_tibble(c(
        list(Group = IndentedLabel),
        as.list(cells),
        meanCell,
        list(N = FmtCount(sum(pct$Number)))
      ))
    }
  )

  names(op)[names(op) == "Group"] <- "Preferred species"
  if (includeMean) {
    names(op)[names(op) == "Mean"] <- meanLabel
  }
  op
}

# Select-all battery. Columns are the checked labels ordered by the Overall
# row's percentage descending (the crosstab report's ordered = TRUE). The row
# denominator is the answered-flag count, as base.summary.percent.selectAll
# itself uses.
Ch3SelectAllTable <- function(mydata, fields, answeredVar) {
  spec <- D4RowSpec(includeOverall = TRUE)

  RowPct <- function(sub) {
    base.summary.percent.selectAll(sub, fields, !!sym(answeredVar)) %>%
      as_tibble()
  }

  categories <- RowPct(mydata) %>%
    arrange(desc(Value)) %>%
    pull(Response) %>%
    as.character()

  op <- purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      nAnswered <- sum(sub[[answeredVar]] == TRUE, na.rm = TRUE)

      blank <- set_names(rep("", length(categories)), categories)
      if (nAnswered == 0) {
        return(as_tibble(c(
          list(Group = IndentedLabel),
          as.list(blank),
          list(N = "0")
        )))
      }

      pct <- RowPct(sub)
      cells <- blank
      idx <- match(as.character(pct$Response), categories)
      cells[idx[!is.na(idx)]] <- FmtPct(pct$Value, pct$CI)[!is.na(idx)]

      as_tibble(c(
        list(Group = IndentedLabel),
        as.list(cells),
        list(N = FmtCount(nAnswered))
      ))
    }
  )

  names(op)[names(op) == "Group"] <- "Preferred species"
  op
}

# Means matrix: one column per variable, N inside each cell. gates is an
# optional vector of *_AnsweredAll columns applied per variable (D19); NA
# means the variable keeps only its own non-missing filter, as the crosstab
# report's raw-item batteries do.
Ch3MeansTable <- function(mydata, vars, colLabels = NULL, gates = NULL) {
  if (is.null(colLabels)) {
    colLabels <- vars
  }
  spec <- D4RowSpec(includeOverall = TRUE)

  cols <- purrr::map(seq_along(vars), function(i) {
    v <- vars[i]
    gate <- if (is.null(gates)) NA_character_ else gates[i]

    purrr::pmap_dfr(
      spec,
      function(RawLabel, IndentedLabel, Type, Members, Order) {
        sub <- mydata
        if (!is.null(Members)) {
          sub <- sub %>% filter(as.character(B1) %in% Members)
        }
        if (!is.na(gate)) {
          sub <- sub %>% filter(.data[[gate]] == TRUE)
        }
        sub <- sub %>% filter(!is.na(.data[[v]]))

        if (nrow(sub) == 0) {
          return(tibble(Group = IndentedLabel, Cell = ""))
        }
        mn <- base.summary.means(sub, !!sym(v)) %>% as_tibble()
        tibble(
          Group = IndentedLabel,
          Cell = FmtMeanN(mn$Value, mn$CI, mn$Number)
        )
      }
    ) %>%
      set_names(c("Group", colLabels[i]))
  })

  op <- Reduce(function(a, b) left_join(a, b, by = "Group"), cols)
  names(op)[names(op) == "Group"] <- "Preferred species"
  op
}

# Weighted medians with the inherited bootstrap CI, N inside each cell.
Ch3MediansTable <- function(
  mydata,
  vars,
  colLabels = NULL,
  gates = NULL,
  digits = 1
) {
  if (is.null(colLabels)) {
    colLabels <- vars
  }
  spec <- D4RowSpec(includeOverall = TRUE)

  cols <- purrr::map(seq_along(vars), function(i) {
    v <- vars[i]
    gate <- if (is.null(gates)) NA_character_ else gates[i]

    purrr::pmap_dfr(
      spec,
      function(RawLabel, IndentedLabel, Type, Members, Order) {
        sub <- mydata
        if (!is.null(Members)) {
          sub <- sub %>% filter(as.character(B1) %in% Members)
        }
        if (!is.na(gate)) {
          sub <- sub %>% filter(.data[[gate]] == TRUE)
        }
        sub <- sub %>% filter(!is.na(.data[[v]]))

        if (nrow(sub) == 0) {
          return(tibble(Group = IndentedLabel, Cell = ""))
        }
        md <- base.summary.medians(sub, !!sym(v)) %>% as_tibble()
        tibble(
          Group = IndentedLabel,
          Cell = FmtMedianN(md$CIlower, md$Value, md$CIupper, md$Number, digits)
        )
      }
    ) %>%
      set_names(c("Group", colLabels[i]))
  })

  op <- Reduce(function(a, b) left_join(a, b, by = "Group"), cols)
  names(op)[names(op) == "Group"] <- "Preferred species"
  op
}

# Indicator table: each column is the percentage of one category of one
# variable, computed on that column's own data frame. Used where the crosstab
# report stacks several differently-gated indicators into one table (the
# public/private access block and the guided-trip block).
#
# specs: list of list(label = , data = , var = , value = ).
Ch3IndicatorTable <- function(specs) {
  spec <- D4RowSpec(includeOverall = TRUE)

  cols <- purrr::map(specs, function(sp) {
    purrr::pmap_dfr(
      spec,
      function(RawLabel, IndentedLabel, Type, Members, Order) {
        sub <- sp$data
        if (!is.null(Members)) {
          sub <- sub %>% filter(as.character(B1) %in% Members)
        }
        sub <- sub %>% filter(!is.na(.data[[sp$var]]))

        if (nrow(sub) == 0) {
          return(tibble(Group = IndentedLabel, Cell = ""))
        }

        pct <- base.summary.percent.selectOne(sub, !!sym(sp$var)) %>%
          as_tibble() %>%
          filter(as.character(Response) == as.character(sp$value))

        cell <- if (nrow(pct) == 0) {
          paste0("0.0 \u00b1 0.00 (", FmtCount(nrow(sub)), ")")
        } else {
          paste0(FmtPct(pct$Value, pct$CI), " (", FmtCount(nrow(sub)), ")")
        }
        tibble(Group = IndentedLabel, Cell = cell)
      }
    ) %>%
      set_names(c("Group", sp$label))
  })

  op <- Reduce(function(a, b) left_join(a, b, by = "Group"), cols)
  names(op)[names(op) == "Group"] <- "Preferred species"
  op
}

# Means for columns that each have their own subset, the means counterpart of
# Ch3IndicatorTable. Used for the guided-trip block, where every column is a
# different universe of anglers and a different day count.
#
# specs: list of list(label = , data = , var = ).
Ch3MeansSpecTable <- function(specs) {
  spec <- D4RowSpec(includeOverall = TRUE)

  cols <- purrr::map(specs, function(sp) {
    purrr::pmap_dfr(
      spec,
      function(RawLabel, IndentedLabel, Type, Members, Order) {
        sub <- sp$data
        if (!is.null(Members)) {
          sub <- sub %>% filter(as.character(B1) %in% Members)
        }
        sub <- sub %>% filter(!is.na(.data[[sp$var]]))

        if (nrow(sub) == 0) {
          return(tibble(Group = IndentedLabel, Cell = ""))
        }
        mn <- base.summary.means(sub, !!sym(sp$var)) %>% as_tibble()
        tibble(
          Group = IndentedLabel,
          Cell = FmtMeanN(mn$Value, mn$CI, mn$Number)
        )
      }
    ) %>%
      set_names(c("Group", sp$label))
  })

  op <- Reduce(function(a, b) left_join(a, b, by = "Group"), cols)
  names(op)[names(op) == "Group"] <- "Preferred species"
  op
}


# Chapter 3 figures ------------------------------------------------------
#
# Every figure walks the same D4RowSpec(includeOverall = TRUE) row set as the
# Chapter 3 tables, with the same per-row filtering, so a figure and the table
# it sits under are computed on identical subsets and cannot drift. Rows
# overlap (D31) and are never totalled; labels carry the row's own raw
# unweighted N.
#
# The Chapter 2 plot helpers were not reusable as they stood: D4MeansOrderedPlot
# hardcodes the 1-5 agreement axis and reads d4.scale.key from the calling
# environment. These take the axis limits and scale key as arguments instead.
# D4PercentLong / D4PercentStackPlot were already generic (categories are
# arguments), so the stacked figures delegate to them rather than duplicating.

# Walks the banner rows, applying statFun to each row's subset. statFun returns
# a one-row tibble or NULL; NULL drops the row, so an empty subset shows up as a
# missing group rather than as a fabricated zero.
Ch3RowStat <- function(mydata, gate = NULL, statFun) {
  spec <- D4RowSpec(includeOverall = TRUE)
  purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      if (!is.null(gate) && !is.na(gate)) {
        sub <- sub %>% filter(.data[[gate]] == TRUE)
      }
      res <- statFun(sub)
      if (is.null(res) || nrow(res) == 0) {
        return(NULL)
      }
      bind_cols(
        tibble(
          Order = Order,
          RawLabel = RawLabel,
          IndentedLabel = IndentedLabel,
          Type = Type
        ),
        res
      )
    }
  )
}

# Percentage of each row group giving one named response, matching the
# corresponding table cell. A group that answered but never chose the response
# is a true 0, so it is kept rather than dropped.
Ch3RateLong <- function(mydata, var, value, gate = NULL) {
  Ch3RowStat(mydata, gate, function(sub) {
    sub <- sub %>% filter(!is.na(.data[[var]]))
    if (nrow(sub) == 0) {
      return(NULL)
    }
    pct <- base.summary.percent.selectOne(sub, !!sym(var)) %>% as_tibble()
    hit <- pct %>% filter(as.character(Response) == as.character(value))
    tibble(
      N = sum(pct$Number),
      Value = if (nrow(hit) == 0) 0 else hit$Value,
      CI = if (nrow(hit) == 0) 0 else hit$CI
    )
  })
}

Ch3MeanLong <- function(mydata, var, gate = NULL) {
  Ch3RowStat(mydata, gate, function(sub) {
    sub <- sub %>% filter(!is.na(.data[[var]]))
    if (nrow(sub) == 0) {
      return(NULL)
    }
    mn <- base.summary.means(sub, !!sym(var)) %>% as_tibble()
    tibble(N = mn$Number, Value = mn$Value, CI = mn$CI)
  })
}

# Bootstrap limits come back asymmetric, so Lower/Upper are carried through as
# computed rather than rebuilt from a single +-CI.
Ch3MedianLong <- function(mydata, var, gate = NULL) {
  Ch3RowStat(mydata, gate, function(sub) {
    sub <- sub %>% filter(!is.na(.data[[var]]))
    if (nrow(sub) == 0) {
      return(NULL)
    }
    md <- base.summary.medians(sub, !!sym(var)) %>% as_tibble()
    tibble(
      N = md$Number,
      Value = md$Value,
      Lower = md$CIlower,
      Upper = md$CIupper
    )
  })
}

# Shared renderer for the point-and-interval figures. Rows are sorted by the
# estimate rather than kept in table order, so the family/species indent is
# dropped here (the nesting is not readable once the order is broken); the
# table above each figure carries the indented row set. The dashed line marks
# the Overall value, which is also plotted as its own point.
#
# Intervals are drawn as computed and are not clamped to the axis: a Wald
# interval that runs past 0 or 100 percent on a small group is a fact about the
# estimate and stays visible.
Ch3DotPlot <- function(
  df,
  xLab,
  titleText = NULL,
  subtitleText = NULL,
  percentAxis = FALSE,
  xExpand = NULL,
  xBreaks = waiver()
) {
  pointColor <- viridisLite::viridis(1, begin = 0.45)

  overallValue <- df %>% filter(Type == "Overall") %>% pull(Value)

  df <- df %>%
    mutate(
      Label = paste0(
        RawLabel,
        " (n=",
        formatC(N, format = "d", big.mark = ","),
        ")"
      ),
      Label = fct_reorder(Label, Value)
    )

  p <- ggplot(df, aes(x = Value, y = Label))

  if (length(overallValue) == 1) {
    p <- p +
      geom_vline(
        xintercept = overallValue,
        linetype = "dashed",
        linewidth = 0.3,
        colour = "grey50"
      )
  }

  p <- p +
    geom_linerange(aes(xmin = Lower, xmax = Upper), linewidth = 0.4) +
    geom_point(size = 1.9, colour = pointColor) +
    labs(x = xLab, y = NULL) +
    theme_minimal(base_size = 9) +
    theme(
      axis.text.y = element_text(hjust = 0),
      panel.grid.major.y = element_blank(),
      plot.title = element_text(size = 9.5, face = "bold"),
      plot.subtitle = element_text(size = 7, face = "italic")
    )

  p <- p +
    scale_x_continuous(
      breaks = xBreaks,
      labels = if (percentAxis) function(x) paste0(x, "%") else waiver()
    )

  # Expands the axis to show the full response scale rather than clipping to
  # it: a confidence interval that runs past the scale endpoint stays visible.
  if (!is.null(xExpand)) {
    p <- p + expand_limits(x = xExpand)
  }
  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 60))
  }
  if (!is.null(subtitleText)) {
    p <- p + labs(subtitle = subtitleText)
  }
  p
}

Ch3RatePlot <- function(
  mydata,
  var,
  value,
  xLab,
  titleText = NULL,
  gate = NULL
) {
  Ch3RateLong(mydata, var, value, gate) %>%
    mutate(Lower = Value - CI, Upper = Value + CI) %>%
    Ch3DotPlot(xLab = xLab, titleText = titleText, percentAxis = TRUE)
}

Ch3MeanPlot <- function(
  mydata,
  var,
  xLab,
  titleText = NULL,
  subtitleText = NULL,
  gate = NULL,
  xExpand = NULL,
  xBreaks = waiver()
) {
  Ch3MeanLong(mydata, var, gate) %>%
    mutate(Lower = Value - CI, Upper = Value + CI) %>%
    Ch3DotPlot(
      xLab = xLab,
      titleText = titleText,
      subtitleText = subtitleText,
      xExpand = xExpand,
      xBreaks = xBreaks
    )
}

Ch3MedianPlot <- function(
  mydata,
  var,
  xLab,
  titleText = NULL,
  subtitleText = NULL,
  gate = NULL
) {
  Ch3MedianLong(mydata, var, gate) %>%
    Ch3DotPlot(xLab = xLab, titleText = titleText, subtitleText = subtitleText)
}

# Stacked-percent figure for any single select-one question. D4PercentStackPlot
# is already general -- it takes the response categories and reads nothing from
# the calling environment -- so this only supplies the categories from the
# variable's own factor levels, keeping the column order identical to the table
# above it.
Ch3StackPlot <- function(mydata, var, categories = NULL, titleText = NULL) {
  if (is.null(categories)) {
    categories <- levels(mydata[[var]])
  }
  D4PercentStackPlot(mydata, var, categories, titleText = titleText)
}

# Scale scores side by side, one facet per scale, rows in table order so a row
# is the same group in every facet. Unlike the sorted dot plots, order is not
# by value -- each facet would sort differently and the rows would stop lining
# up -- so the family/species indent is kept here.
#
# Labels carry no N: each scale applies its own *_AnsweredAll gate (D19), so a
# row's count differs from facet to facet. The counts are in the scale-score
# table directly above each of these figures, per cell (D90).
Ch3ScaleFacetPlot <- function(
  mydata,
  vars,
  labels,
  gates = NULL,
  xLab = "Mean scale score",
  titleText = NULL,
  subtitleText = NULL,
  xExpand = NULL,
  xBreaks = waiver(),
  ncol = 2
) {
  pointColor <- viridisLite::viridis(1, begin = 0.45)

  df <- purrr::map_dfr(seq_along(vars), function(i) {
    Ch3MeanLong(
      mydata,
      vars[i],
      gate = if (is.null(gates)) NULL else gates[i]
    ) %>%
      mutate(Scale = labels[i])
  })

  rowOrder <- D4RowSpec(includeOverall = TRUE)$IndentedLabel

  df <- df %>%
    mutate(
      Lower = Value - CI,
      Upper = Value + CI,
      Scale = factor(Scale, levels = labels),
      Label = factor(IndentedLabel, levels = rev(rowOrder))
    )

  p <- ggplot(df, aes(x = Value, y = Label)) +
    geom_linerange(aes(xmin = Lower, xmax = Upper), linewidth = 0.4) +
    geom_point(size = 1.6, colour = pointColor) +
    facet_wrap(~Scale, ncol = ncol, labeller = label_wrap_gen(width = 30)) +
    scale_x_continuous(breaks = xBreaks) +
    labs(x = xLab, y = NULL) +
    theme_minimal(base_size = 9) +
    theme(
      axis.text.y = element_text(hjust = 0),
      panel.grid.major.y = element_blank(),
      panel.spacing.x = unit(0.6, "cm"),
      strip.text = element_text(size = 8, face = "bold"),
      plot.title = element_text(size = 9.5, face = "bold"),
      plot.subtitle = element_text(size = 7, face = "italic")
    )

  # Expands the axis to show the full response scale rather than clipping to
  # it: a confidence interval that runs past the scale endpoint stays visible.
  if (!is.null(xExpand)) {
    p <- p + expand_limits(x = xExpand)
  }
  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 70))
  }
  if (!is.null(subtitleText)) {
    p <- p + labs(subtitle = subtitleText)
  }
  p
}

# ============================================================================
# CHAPTER 4 - SATISFACTION (D111)
# ============================================================================
# Collects the satisfaction measures that Chapters 2 and 3 report separately.
# Nothing is recomputed differently here: the same base.summary.* functions and
# the same D4RowSpec row set are used, so a Chapter 4 cell and its Chapter 2 or
# 3 counterpart are the same number by construction. The single transformation
# is A9, reversed so every column in the chapter runs the same direction (D113).

ch4.sat.items <- tibble::tibble(
  Field = c("A9rev", "D4a", "D4i", "D4j", "D4k", "D4l"),
  Source = c("A9", "D4a", "D4i", "D4j", "D4k", "D4l"),
  Short = c(
    "Season overall",
    "Success",
    "Size caught",
    "Size harvestable",
    "Number caught",
    "Number harvestable"
  ),
  Reported = c("Chapter 3", rep("Chapter 2", 5))
)

# Differences between two items are small relative to the 1 dp used elsewhere
# (D93): the overall catch gap is 0.07, which 1 dp would render as 0.1 next to
# an interval of 0.06. Gap columns therefore carry 2 dp (D115).
FmtMeanGap <- function(value, ci) {
  paste0(
    formatC(value, format = "f", digits = 2),
    " \u00b1 ",
    formatC(ci, format = "f", digits = 2)
  )
}

ch4.lab.meanci <- "Overall mean \u00b1 CI"
ch4.lab.diffci <- "Difference \u00b1 CI"

caption.ch4a9 <-
  "A9 appears here as 6 minus the recorded response, so that every item in this chapter runs the same way and a higher score is always more satisfied. Chapter 3 reports A9 on its recorded scale, where 1 is Very satisfied. The two are the same estimate with the same confidence interval: the overall 2.3 plus or minus 0.06 in Chapter 3 is 3.7 plus or minus 0.06 here."
caption.ch4corr <-
  "Cells are weighted Pearson correlations on the respondents who answered all six items. They are descriptive: no test and no adjustment for multiple comparisons is reported."
caption.ch4groupcorr <-
  "Cells are Spearman rank correlations between the 17 preferred-group means, one observation per group, taken from the table above. The groups overlap, because a family row contains its own species rows, so these summarise that table rather than estimate a population quantity; no standard error or test is reported."
caption.ch4gap <-
  "Both mean columns and the difference are computed on the same respondents, those who answered both items, so the difference is a paired comparison and equals the difference of the two means shown. Intervals are 95 percent and are built exactly as every other mean interval in this report. They are not adjusted for the number of groups compared."

# A9 reversed, plus the two paired differences as their own numeric columns so
# that base.summary.means gives the difference the same Kish-effN interval it
# gives any other mean, rather than a second interval formula appearing in the
# report.
Ch4AddSatVars <- function(mydata) {
  mydata %>%
    mutate(
      A9rev = 6 - as.numeric(A9),
      satGapCatch = as.numeric(D4i) - as.numeric(D4k),
      satGapHarvest = as.numeric(D4j) - as.numeric(D4l)
    )
}

Ch4ItemTable <- function(mydata, codebook) {
  purrr::pmap_dfr(ch4.sat.items, function(Field, Source, Short, Reported) {
    sub <- mydata %>% filter(!is.na(.data[[Field]]))
    mn <- base.summary.means(sub, !!sym(Field)) %>% as_tibble()
    tibble(
      Item = Source,
      `Question text` = ItemQuestionText(Source, codebook),
      `Short name` = Short,
      `Also in` = Reported,
      N = FmtCount(mn$Number),
      !!ch4.lab.meanci := FmtMeanD4(mn$Value, mn$CI)
    )
  })
}

# Lower triangle only: the upper triangle repeats it and doubles the reading
# effort in a table this wide.
FormatCorrMatrix <- function(S, labels) {
  S <- round(S, 2)
  S[upper.tri(S)] <- NA_real_
  out <- as.data.frame(S)
  names(out) <- labels
  out <- out %>%
    mutate(across(
      everything(),
      ~ if_else(is.na(.x), "", formatC(.x, format = "f", digits = 2))
    ))
  bind_cols(tibble(Item = labels), out)
}

Ch4CorrComplete <- function(mydata, fields = ch4.sat.items$Field) {
  x <- mydata %>% mutate(across(all_of(fields), as.numeric))
  sum(complete.cases(x[, fields]))
}

Ch4CorrTable <- function(
  mydata,
  fields = ch4.sat.items$Field,
  labels = ch4.sat.items$Short
) {
  x <- mydata %>% mutate(across(all_of(fields), as.numeric))
  keep <- complete.cases(x[, fields])
  m <- as.matrix(x[keep, fields])
  S <- stats::cov.wt(m, wt = x$postWeight[keep], cor = TRUE)$cor
  FormatCorrMatrix(S, labels)
}

# Weighted group means as numbers rather than formatted cells, so the
# group-level correlation and the dumbbell figures read the same values the
# matrix table prints.
Ch4GroupMeans <- function(mydata, fields = ch4.sat.items$Field) {
  spec <- D4RowSpec(includeOverall = TRUE)
  purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      vals <- purrr::map_dbl(fields, function(v) {
        s2 <- sub %>% filter(!is.na(.data[[v]]))
        if (nrow(s2) < 3) {
          return(NA_real_)
        }
        base.summary.means(s2, !!sym(v))$Value[1]
      })
      bind_cols(
        tibble(RawLabel = RawLabel, Type = Type, N = nrow(sub)),
        as_tibble(set_names(as.list(vals), fields))
      )
    }
  )
}

Ch4GroupCorrTable <- function(
  groupMeans,
  fields = ch4.sat.items$Field,
  labels = ch4.sat.items$Short
) {
  m <- groupMeans %>%
    filter(Type != "Overall") %>%
    select(all_of(fields)) %>%
    as.matrix()
  S <- cor(m, method = "spearman", use = "pairwise.complete.obs")
  FormatCorrMatrix(S, labels)
}

# Paired comparison of two items within each preferred group. The universe is
# respondents who answered BOTH items, so the two means and their difference
# describe the same people and the difference column is not the difference of
# two independently gated estimates.
Ch4GapTable <- function(mydata, v1, v2, lab1, lab2) {
  spec <- D4RowSpec(includeOverall = TRUE)
  purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      sub <- sub %>%
        filter(!is.na(.data[[v1]]), !is.na(.data[[v2]])) %>%
        mutate(gapv = as.numeric(.data[[v1]]) - as.numeric(.data[[v2]]))

      if (nrow(sub) == 0) {
        return(tibble(
          `Preferred species` = IndentedLabel,
          !!lab1 := "",
          !!lab2 := "",
          !!ch4.lab.diffci := "",
          N = ""
        ))
      }

      m1 <- base.summary.means(sub, !!sym(v1)) %>% as_tibble()
      m2 <- base.summary.means(sub, !!sym(v2)) %>% as_tibble()
      mg <- base.summary.means(sub, gapv) %>% as_tibble()

      tibble(
        `Preferred species` = IndentedLabel,
        !!lab1 := FmtMeanD4(m1$Value, m1$CI),
        !!lab2 := FmtMeanD4(m2$Value, m2$CI),
        !!ch4.lab.diffci := FmtMeanGap(mg$Value, mg$CI),
        N = FmtCount(mg$Number)
      )
    }
  )
}

# Rows are sorted by the gap, which destroys the family/species nesting, so the
# indent is dropped and the raw N goes on the label (D104).
Ch4DumbbellPlot <- function(
  mydata,
  v1,
  v2,
  lab1,
  lab2,
  titleText = NULL,
  subtitleText = NULL
) {
  spec <- D4RowSpec(includeOverall = TRUE)
  df <- purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      sub <- sub %>% filter(!is.na(.data[[v1]]), !is.na(.data[[v2]]))
      if (nrow(sub) < 3) {
        return(NULL)
      }
      tibble(
        RawLabel = RawLabel,
        N = nrow(sub),
        V1 = base.summary.means(sub, !!sym(v1))$Value[1],
        V2 = base.summary.means(sub, !!sym(v2))$Value[1]
      )
    }
  )

  df <- df %>%
    mutate(
      Label = paste0(
        RawLabel,
        " (n=",
        formatC(N, format = "d", big.mark = ","),
        ")"
      ),
      Label = fct_reorder(Label, V1 - V2)
    )

  cols <- set_names(
    viridisLite::viridis(2, begin = 0.25, end = 0.7),
    c(lab1, lab2)
  )

  p <- ggplot(df, aes(y = Label)) +
    geom_segment(
      aes(x = V2, xend = V1, yend = Label),
      colour = "grey60",
      linewidth = 0.5
    ) +
    geom_point(aes(x = V2, colour = lab2), size = 1.9) +
    geom_point(aes(x = V1, colour = lab1), size = 1.9) +
    scale_colour_manual(values = cols, breaks = c(lab1, lab2)) +
    scale_x_continuous(breaks = 1:5) +
    expand_limits(x = c(1, 5)) +
    labs(x = "Weighted mean response", y = NULL, colour = NULL) +
    theme_minimal(base_size = 9) +
    theme(
      axis.text.y = element_text(hjust = 0),
      panel.grid.major.y = element_blank(),
      legend.position = "top",
      plot.title = element_text(size = 9.5, face = "bold"),
      plot.subtitle = element_text(size = 7, face = "italic")
    )

  if (!is.null(titleText)) {
    p <- p + labs(title = str_wrap(titleText, width = 70))
  }
  if (!is.null(subtitleText)) {
    p <- p + labs(subtitle = subtitleText)
  }
  p
}

# Raw (covariance) alpha. Reported only as a descriptive footnote: the chapter
# builds no composite score, and the sibling D4ScaleAnalysis report is the
# authority on what this battery measures.
Ch4Alpha <- function(mydata, fields, weighted = TRUE) {
  x <- mydata %>% mutate(across(all_of(fields), as.numeric))
  keep <- complete.cases(x[, fields])
  m <- as.matrix(x[keep, fields])
  S <- if (weighted) {
    stats::cov.wt(m, wt = x$postWeight[keep])$cov
  } else {
    stats::cov(m)
  }
  k <- ncol(m)
  list(k = k, n = nrow(m), alpha = k / (k - 1) * (1 - sum(diag(S)) / sum(S)))
}

# Same paired quantities as Ch4GapTable, unformatted, so the chapter's summary
# sentences are computed at render time rather than transcribed from a table.
Ch4GapNumbers <- function(mydata, v1, v2) {
  spec <- D4RowSpec(includeOverall = TRUE)
  purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      sub <- sub %>%
        filter(!is.na(.data[[v1]]), !is.na(.data[[v2]])) %>%
        mutate(gapv = as.numeric(.data[[v1]]) - as.numeric(.data[[v2]]))
      if (nrow(sub) == 0) return(NULL)
      mg <- base.summary.means(sub, gapv) %>% as_tibble()
      tibble(
        RawLabel = RawLabel,
        Type = Type,
        N = mg$Number,
        Gap = mg$Value,
        CI = mg$CI
      )
    }
  )
}

# Comma-separated group names whose interval excludes zero in one direction,
# for use inline in the chapter text.
Ch4GapNames <- function(gapNumbers, direction = c("positive", "negative")) {
  direction <- match.arg(direction)
  sel <- gapNumbers %>% filter(Type != "Overall", abs(Gap) > CI)
  sel <- if (direction == "positive") {
    sel %>% filter(Gap > 0) %>% arrange(desc(Gap))
  } else {
    sel %>% filter(Gap < 0) %>% arrange(Gap)
  }
  if (nrow(sel) == 0) return("none")
  paste(sel$RawLabel, collapse = ", ")
}
