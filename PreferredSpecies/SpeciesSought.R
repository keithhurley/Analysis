# Chapter 4 -- species sought (B2) ------------------------------------------
# Builders for the "Species Sought" chapter. Sourced by the report after
# PreferredSpeciesFunctions.R; it reuses D4RowSpec(), banner.definition,
# family.candidates, FmtPct(), FmtCount() and the base.summary.* functions
# unmodified, so every percentage and interval uses the same arithmetic as the
# other chapters.
#
# B2xx is the "tried to catch" flag (lakes/reservoirs/ponds OR rivers/streams/
# canals). The B2xx_no field records an explicit "No" and is not used. Every B2
# table is gated on B2_Answered, as in the crosstabs report.

# One row per named species, in B1 level order. Species names are the B1 names
# so the family definitions in family.candidates apply directly.
sought.map <- tibble::tribble(
  ~Field    , ~Species                    ,
  "B2stb"   , "Striped bass"              ,
  "B2wpr"   , "Wiper"                     ,
  "B2whb"   , "White bass"                ,
  "B2lmb"   , "Largemouth bass"           ,
  "B2smb"   , "Smallmouth bass"           ,
  "B2sun"   , "Bluegill / Sunfish"        ,
  "B2crp"   , "Crappie"                   ,
  "B2ywp"   , "Yellow perch"              ,
  "B2wae"   , "Walleye / Sauger"          ,
  "B2ntp"   , "Northern pike"             ,
  "B2musk"  , "Muskellunge / Tiger musky" ,
  "B2ccf"   , "Channel catfish"           ,
  "B2bcf"   , "Blue catfish"              ,
  "B2fcf"   , "Flathead catfish"          ,
  "B2bh"    , "Bullhead"                  ,
  "B2fwd"   , "Drum"                      ,
  "B2stur"  , "Sturgeon"                  ,
  "B2carp"  , "Common carp"               ,
  "B2aCarp" , "Invasive carp"             ,
  "B2rbt"   , "Trout"                     ,
  "B2pdf"   , "Paddlefish"
)

# Answers that are not a species: reported in the population table, never
# ranked and never counted.
sought.special <- tibble::tribble(
  ~Field  , ~Species              ,
  "B2any" , "Fished for anything" ,
  "B2oth" , "Other"
)

# The base B2 fields, selected as 2025CrossTabReport.rmd L1143 does.
SoughtFields <- function(mydata) {
  mydata %>%
    dplyr::select(contains("B2")) %>%
    dplyr::select(-contains("_")) %>%
    dplyr::select(-contains("Answered")) %>%
    names()
}

# Response text used by base.summary.percent.selectAll -> display species name.
SoughtLabelLookup <- function(mydata) {
  fields <- c(sought.map$Field, sought.special$Field)
  species <- c(sought.map$Species, sought.special$Species)
  labels <- vapply(
    fields,
    function(f) {
      lv <- setdiff(unique(as.character(mydata[[f]])), c("Unchecked", NA))
      stopifnot(length(lv) == 1)
      lv
    },
    character(1)
  )
  setNames(species, labels)
}

# Table 4.1: every answer, Overall, expanded to the angler population the same
# way Chapter 1 expands the preferred-species percentages (SpeciesSizeTable).
SoughtPopulationTable <- function(mydata, popTotalAll) {
  lookup <- SoughtLabelLookup(mydata)
  base.summary.percent.selectAll(
    mydata,
    SoughtFields(mydata),
    B2_Answered
  ) %>%
    as_tibble() %>%
    transmute(
      Species = unname(lookup[Response]),
      Respondents = Number,
      Percent = Value,
      PercentCI = CI,
      TotalAnglers = Percent / 100 * popTotalAll,
      TotalAnglersCI = PercentCI / 100 * popTotalAll
    ) %>%
    mutate(NotSpecies = Species %in% sought.special$Species) %>%
    arrange(NotSpecies, desc(Percent), desc(Respondents)) %>%
    select(-NotSpecies)
}

ArrangeSoughtPopulationTable <- function(tbl) {
  tbl %>%
    transmute(
      `Species sought` = Species,
      Respondents = FmtCount(Respondents),
      `% of angler population` = FmtPct(Percent, PercentCI),
      `Total anglers` = FmtCount(TotalAnglers, TotalAnglersCI)
    )
}

# Species a preferred column does not compete with itself on: the column's own
# members plus every other species in the same Chapter 1 candidate family, even
# where the family did not combine into a column (so Wiper and White bass both
# exclude all three Moronides).
SoughtExcluded <- function(members) {
  fam <- family.candidates$Family[family.candidates$Species %in% members]
  unique(c(
    members,
    family.candidates$Species[family.candidates$Family %in% fam]
  ))
}

# Long table behind Table 4.2: the top n named species sought by each row group,
# outside that group's family. Overall excludes nothing. Ranking is by the
# weighted percentage; ties fall back to the raw count.
SoughtTopLong <- function(mydata, n = 3) {
  lookup <- SoughtLabelLookup(mydata)
  spec <- D4RowSpec(includeOverall = TRUE)

  purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      excluded <- character(0)
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
        excluded <- SoughtExcluded(Members)
      }
      nAnswered <- sum(sub$B2_Answered == TRUE, na.rm = TRUE)
      fields <- sought.map$Field[!sought.map$Species %in% excluded]

      base.summary.percent.selectAll(sub, fields, B2_Answered) %>%
        as_tibble() %>%
        transmute(
          Species = unname(lookup[Response]),
          Respondents = Number,
          Percent = Value,
          PercentCI = CI
        ) %>%
        arrange(desc(Percent), desc(Respondents)) %>%
        slice_head(n = n) %>%
        mutate(
          Rank = row_number(),
          Group = RawLabel,
          Label = IndentedLabel,
          N = nAnswered,
          Excluded = paste(excluded, collapse = "; ")
        )
    }
  )
}

SoughtTopTable <- function(topLong) {
  topLong %>%
    mutate(
      Cell = paste0(Species, ": ", FmtPct(Percent, PercentCI)),
      RankName = paste("Rank", Rank)
    ) %>%
    select(Label, N, RankName, Cell) %>%
    tidyr::pivot_wider(names_from = RankName, values_from = Cell) %>%
    mutate(N = FmtCount(N)) %>%
    rename(`Preferred species` = Label)
}

# Respondent-level count of named species sought, excluding the respondent's
# own preferred species. "Fished for anything" and "Other" are not counted.
# NA where B2 was not answered; the NAs are kept, never dropped.
SoughtAddCount <- function(mydata) {
  sought <- vapply(
    sought.map$Field,
    function(f) as.character(mydata[[f]]) != "Unchecked",
    logical(nrow(mydata))
  )
  own <- match(as.character(mydata$B1), sought.map$Species)
  ownSought <- rep(0, nrow(mydata))
  hasOwn <- !is.na(own)
  ownSought[hasOwn] <- sought[cbind(which(hasOwn), own[hasOwn])]

  mydata$n_other_sought <- if_else(
    mydata$B2_Answered %in% TRUE,
    rowSums(sought) - ownSought,
    NA_real_
  )
  mydata
}

# Long table behind Table 4.3: mean (Kish-effN interval) and median (inherited
# bootstrap interval) of n_other_sought for each row group.
SoughtCountLong <- function(mydata) {
  spec <- D4RowSpec(includeOverall = TRUE)

  purrr::pmap_dfr(
    spec,
    function(RawLabel, IndentedLabel, Type, Members, Order) {
      sub <- mydata
      if (!is.null(Members)) {
        sub <- sub %>% filter(as.character(B1) %in% Members)
      }
      sub <- sub %>% filter(B2_Answered %in% TRUE, !is.na(n_other_sought))

      mn <- base.summary.means(sub, n_other_sought) %>% as_tibble()
      md <- base.summary.medians(sub, n_other_sought) %>% as_tibble()
      tibble(
        Group = RawLabel,
        Label = IndentedLabel,
        N = nrow(sub),
        Mean = mn$Value,
        MeanCI = mn$CI,
        MedianLower = md$CIlower,
        Median = md$Value,
        MedianUpper = md$CIupper
      )
    }
  )
}

SoughtCountTable <- function(countLong) {
  op <- countLong %>%
    transmute(
      `Preferred species` = Label,
      N = FmtCount(N),
      Mean = FmtMeanD4(Mean, MeanCI),
      Median = formatC(Median, format = "f", digits = 1),
      `Median 95% CI` = paste0(
        formatC(MedianLower, format = "f", digits = 1),
        " to ",
        formatC(MedianUpper, format = "f", digits = 1)
      )
    )
  names(op)[names(op) == "Mean"] <- "Mean \u00b1 95% CI"
  op
}

caption.soughtpop <-
  "Respondents is the raw unweighted number of anglers who said they tried to catch the species in 2025. The percentage is of anglers who answered the species-sought question, with a 95 percent confidence interval. Total anglers applies that percentage to the full weighted 2025 angler population. Rows overlap, because an angler can try to catch many species, and must not be totalled."
caption.soughttop <-
  "Cells give the three species most often sought, other than the group's own family, as the weighted percentage of the row group who said they tried to catch the species, with a 95 percent confidence interval. A group's own family is every species in the same Chapter 1 candidate family as its preferred species (Wiper and White bass exclude all three of Striped bass, Wiper and White bass). The Overall row excludes nothing. Answers of fishing for anything and Other are not ranked. N is the raw unweighted number of respondents in the row group who answered the question."
caption.soughtcount <-
  "Cells summarize the number of named species each angler tried to catch, not counting the angler's own preferred species or the answers of fishing for anything and Other. The mean has a 95 percent confidence interval; the median has the 1,000-replicate weighted bootstrap 95 percent confidence limits. N is the raw unweighted number of respondents in the row group who answered the question."
