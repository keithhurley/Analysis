# PreferredSpecies Report — Project Instructions

> **Read this file first in any new conversation.** It carries the standing directive,
> the inherited methodology, and the verified facts about the upstream pipeline so that
> none of it has to be re-derived (and re-paid for in tokens).
> Companion files: `PROGRESS.md` (decisions + step status), `PROMPTS.md` (verbatim prompt log).

---

## 1. Standing directive (from the user, verbatim)

> I'm ready to start a new analysis report from the survey. The calculations need to be
> handled (weighted, sample size report, confidence intervals, etc) like they have been for
> the crosstabs and trends report; this report will be a look at the survey responses broken
> down by responses to the question "What type of fish did you PREFER to fish for?"; do NOT
> do any code or file writing untill I give the go ahead.....first we need to iterate and plan
> the analysis and report so please act as a data analysis technition; do not include any
> interpretation of the results but instead focus on providing the numbers for me to examine;
> I recommend we follow the following order of events: .......1) determine appropiate species
> groupings to allow us to condense the list of species to a more manageable list by collapsing
> like species; 2) analyze the scale of questions that refer to the chosen species; 3) produce
> crosstab tables like in the crosstab reports for the rest of the questions but using the
> species list instead of the demographics as in the crosstab reports; 4) choose appropiate
> questions that display interesting results to further display with data visualizations;
> 5) allow me to complete guided text development to complete the report; 6) include the same
> appendix that we used in the crosstab report describing the statistical analysis.....all
> values used in this report will also need to match those found in the crosstabs report but
> DO NOT CHANGE ANYTHING in the crosstabs report or project to make things match, instead
> inform me of any differences and ask for guidance............please add this prompt into a
> agent.md file for use by this project regardless of which conversation I'm in; use a similar
> file to track our work so everything doesn't have to constantly be passed as context and
> tokens......before we start with step 1 ask me any clarifying questions or provide any
> additional thoughts or ideas that may be useful.......once we have a plan we will produce
> the .qmd file....always inform me of actions to conserve tokens (i.e. start new conversation,
> save as file, etc)

> also please keep a file in the project folder of all prompts submitted

### Operating rules distilled from the above

1. **Plan before code.** No code execution and no file writing without explicit go-ahead.
2. **Technician voice.** Report numbers. No interpretation, no "significant", "meaningful",
   "striking", or causal language. The user does the interpreting.
3. **Inherit the methodology.** Weighting, sample-size reporting, and CI construction must
   follow the crosstabs/trends reports exactly — reuse the existing functions, do not rewrite
   the math.
4. **Never edit upstream.** Do not modify anything in `CrossTabTables/`, `TrendTables/`, the
   `BaseFunctions*` files, or `Data/DataAggregation1/`. If a number here disagrees with the
   crosstabs report, **report the discrepancy and ask** — never "fix" the other report.
5. **Announce token-saving actions** (save to file, start a new conversation, etc.).
6. **Keep `PROGRESS.md` and `PROMPTS.md` current** as work proceeds.

---

## 2. Inherited methodology (verified from source)

| Element | Implementation | Source |
|---|---|---|
| Data object | `d`, one row per respondent | `aggregateData_20260624.rData` |
| Data path | `../../Data/DataAggregation1/aggregateData_20260624.rData` | `2025CrossTabReport.rmd` L36-37 |
| Year filter | `d <- d %>% filter(surveyYear == 2025)` | same |
| Weight column | `postWeight` — pre-computed upstream, merged from `2025_raking_weights.csv` (`rake_weight`) | `AggregateData.R` L328-334 |
| Weighting approach | **Manual** weighted proportions/means. No `svydesign`/`svymean` in the 2025 path; `base.summary.rake.loop()` is a pass-through | `BaseFunctions_2025_UPDATED.R` |
| Effective N (Kish) | `effN = (Σw)² / Σw²` | `BaseFunctions_2025_UPDATED.R` L153, L281, L377 |
| Percent CI | `1.96 * sqrt(p(1-p)/effN) * 100` (Wald) | same |
| Mean CI | `SE = SD_w / sqrt(effN)`; `CI = 1.96 * SE` | same |
| Median CI | 1000-rep weighted bootstrap, 2.5/97.5 percentiles, **seed 7361** | `weighted_median_boot_ci()` L483-514 |
| Displayed N | **raw, unweighted** respondent count — never weighted N | Appendix B |
| Why effN | 2025 weights sum to population (~234,000; mean weight ~83); raw Σw would make CIs ~9× too tight | Appendix B |
| Significance tests | **None anywhere** in the crosstab/trend pipeline | verified by search |
| Small-cell suppression | **None** in the crosstab/trend pipeline (`LikertPlotFunctions.R` uses `minimumPerGroupVar = 20`, but that is plotting-only) | verified by search |
| Rendering | `flextable` + `theme_zebra()`, wrapped by local `CreateFlex()` | `2025CrossTabReport.rmd` L50-86 |
| Output | `officedown::rdocx_document` → Word, `toc: true` | YAML of both reports |

### Core statistics functions — `f:/Survey/Analysis/BaseFunctions_2025_UPDATED.R`

```r
base.summary.percent.selectOne(mydata, myQuestion, myGroupVar = NA)                      # L85-173
base.summary.percent.selectAll(mydata, myQuestions, myAnsweredVar, myGroupVar = NA)      # L180-313
base.summary.means(mydata, myQuestion, myGroupVar = NA)                                  # L326-391
base.summary.medians(mydata, myQuestion, myGroupVar = NA, n_boot = 1000, boot_seed = 7361) # L403-470
```

`myGroupVar` is the banner variable. **This is the hinge for the whole report:** passing a
collapsed `B1` as `myGroupVar` reproduces the crosstab arithmetic by construction.

### Table-assembly wrappers — `f:/Survey/Analysis/CrossTabTables/CrossTabTableFunctions.R`

```r
CreateTableA_selectOne_percent(myData, myQuestion, ordered = FALSE)   # L336-361; Overall + Resi + E2
CreateTableB_selectOne_percent(myData, myQuestion, ordered = FALSE)   # L363-384; E3 age groups
CreateTableA/B_selectAll_percent(...)
CreateTableA/B_means(...)
CreateTableA/B_medians(...)
ArrangeTableA / ArrangeTableB(...)                                    # L149-332; long -> wide, "Value±CI (N)"
```

Crosstab banners are **only** `Resi` (Resident/Non-Resident), `E2` (Gender), `E3` (age:
16-24, 25-34, 35-44, 45-54, 55-64, 65+), each alongside an Overall column. Percentages are
**column %** within banner group. This report substitutes species groups for those banners.

### Supporting files

| File | Role |
|---|---|
| `f:/Survey/Data/DataAggregation1/FactorLevels_aggregated.csv` | de-facto codebook: `Type,Question,Field,Year,Value,Label,Reversed`; loaded as `q` |
| `f:/Survey/Data/DataAggregation1/Labels.csv` | display labels; loaded as `l` |
| `f:/Survey/Data/DataAggregation1/Scales.csv` | Likert sub-scale definitions; loaded as `s`; drives `add_scale_scores(d)` |
| `f:/Survey/Data/DataAggregation1/AggregateData.R` | build pipeline (do not modify) |
| `f:/Survey/Analysis/CrossTabTables/2025CrossTabReport.rmd` | structural template + Appendix B |
| `f:/Survey/Analysis/TrendTables/TrendTableFunctions.R` | `CreateFt()`, `CreatePercPlot()`, `CreateMeanPlot()`, `CreateMedianPlot()`, `CreateLikert_Grouped()` |

---

## 3. Key variables

### `B1` — the banner question

Single-select (`SelectOne`). 2025 text: *"Which type of fish do you prefer to fish for in
Nebraska?"* Levels (`FactorLevels_aggregated.csv` L534-556):

| Code | Label | Code | Label |
|---|---|---|---|
| 1 | Striped bass | 13 | Blue catfish |
| 2 | Wiper | 14 | Flathead catfish |
| 3 | White bass | 15 | Bullhead |
| 4 | Largemouth bass | 16 | Drum |
| 5 | Smallmouth bass | 17 | Sturgeon |
| 6 | Bluegill / Sunfish | 18 | Common carp |
| 7 | Crappie | 23 | Invasive carp |
| 8 | Yellow perch | 19 | Trout |
| 9 | Walleye / Sauger | 20 | Paddlefish |
| 10 | Northern pike | 22 | Other |
| 11 | Muskellunge / Tiger musky | 21 | I do not prefer any particular type of fish |
| 12 | Channel catfish | | |

Reported in the crosstab report under "# Preferred Fish" (L744-756) via
`CreateTableA/B_selectOne_percent(d, B1, ordered = TRUE)`.

An existing coarse aggregation, `gtype`/`gtype2` (Bass, Catfish, Sunfish, Walleye-Sauger,
Moronides, Esocids, Trout, Uniques, Anything), is defined in
`f:/Survey/Data/DataAggregation1/BaseFunctions.R` L831-870. **Verified present in the saved `d`**
(check V1, 2026-09-17): `gtype` puts Yellow perch in Sunfish and maps `B1` = "Other" to `NA`;
`gtype2` breaks Yellow perch out standalone. Sturgeon has 0 respondents in 2025.

### Species-linked question batteries

| Variable | Type | Content |
|---|---|---|
| `D4*` | Likert 1-5 (`labels.agree`) | agree/disagree *about the preferred fish* — "Thinking about the one type of fish that you prefer to fish for..." Crosstab report L761-804 |
| `B2*` (`B2ccf`, `B2carp`, `B2wpr`, `B2ywp`, `B2any`, + `_lrp`/`_rsc`/`_no`) | SelectAll | species the respondent tried to catch. Crosstab L1138-1179 |
| `B3*` | SelectOne | harvest/release per species (Kept All → Kept None), gated on having caught it. Crosstab L1184-1215 |
| `D13*` (`lrp`,`rsc`,`oga`,`tr`) | SelectAll | trout locations, gated on `B2rbt == "Trout"` |

### Other questions available for banner-by-species crosstabbing

- **SelectOne:** A1 permit type, A2 did you fish, A3 why not, A7/A8 distance (banded),
  A9 satisfaction, A10 park permit, A11/A12 out-of-state, Q11 crowding, Q16 sonar,
  E7 conservation officer, Q23_1/2/3 low water, E2 gender, E3/age.
- **SelectAll:** A4 waterbody types, A5 methods, A6 techniques.
- **Likert batteries / scales:** E1 angler attitudes (reversed items E1a, E1f, E1k, E1l),
  D4 preferred-species, C2 motivations, Q31 regulations (`Q31a`–`Q31l`).
- **Numeric:** A13 tournament count, Q18a/b guide days, `C1Jan`…`C1Oct`, `C1Total_days`,
  `A7_miles`/`A8_miles`.
- **Derived scale scores** via `add_scale_scores()`: `attitude_catch/numbers/size/harvest`,
  `motivation_natural/pp/social/resource`, `barriers_access/time/social/knowledge/cost`,
  `reg_comprehension/sitesupport/uniform`.

---

## 4. Value-matching rule — NARROWED, see D23/D28

⚠️ **This section has been superseded in part.** The report universe is now `surveyYear == 2025`
**and `!is.na(B1)`** (n = 1,915; D23), so the Overall column estimates "anglers who stated a
preference" rather than "all licensed anglers". It therefore **no longer matches the crosstabs
report**, and that divergence is **accepted and deliberate** (D28) — do not try to reconcile it
and do not treat it as a discrepancy.

**Exactly one thing still matches, and must keep matching:** the **`B1` distribution** itself
(collapsed group % equals the sum of its component %). It is invariant to the `B1` filter because
`base.summary.*` already drops `B1 = NA`. Verified 23/23 cells against the rendered crosstabs
(check V7).

Every species-banner cell is new and has no counterpart to match. Reusing the `base.summary.*`
functions unmodified makes the arithmetic identical by construction, so any *unexpected*
discrepancy will trace to a universe/grouping choice or a codebook label change — **report it and
ask**, never change the other report.

---

## 5. House conventions (user's global preferences)

- R for cleaning, wrangling, and models; `ggplot2` for graphics; `<-`, two-space indent, `snake_case`.
- Comment intent only; never restate code in comments.
- State assumptions behind every join and filter.
- **Never drop NAs**; add a check after every major data step; never alter data to pass a check.
- Never overwrite raw data; never delete files/outputs without asking.
- Verify code by running it before claiming it works; say so if it wasn't run.
- Target folder layout: `data/raw/` (never modified), `data/derived/`, `R/`, `analysis/`, `output/`.
  **Superseded for this project by D17: flat layout in the project root.**

---

## 6. Build state (as of 2026-09-18)

| File | Role |
|---|---|
| `PreferredSpeciesReport.rmd` | The report. Renders to `PreferredSpeciesReport.docx` |
| `PreferredSpeciesFunctions.R` | Banner definition, table builders, pairwise contrast helpers |
| `.gitignore` | Ignores build artifacts and Word lock files. **The rendered `.docx` IS tracked** (D109), via a negation against the repo-root `*.docx` rule (F36) |

**Source order in the setup chunk** (do not reorder — local definitions must win):
`../BaseFunctions_2025_UPDATED.R`, then `../CrossTabTables/CrossTabTableFunctions.R`
(read-only, for inherited captions and wrappers), then `PreferredSpeciesFunctions.R`.

| Step | State |
|---|---|
| 1 — species groupings (Chapter 1) | **Done.** 23 tables, renders clean |
| 2 — species-linked scale questions (Chapter 2) | **Done.** 13 items, each with a table, 3 figures, and 2 verified summary paragraphs; item-level, not composite (D63) |
| 3 — crosstabs by species (Chapter 3) | **Done.** 21 sections, 39 tables, coverage per D86. The age table carries a weighted mean-age column (D108) |
| 4 — visualizations | **Done.** No chapter of its own (D34) — 39 figures in Chapter 2, 14 in Chapter 3 (D101) |
| 5 — guided text development | Not started. **Deferred again, until after Chapter 5** (D110, D119) |
| 6 — appendices | **Done.** Appendix A blank for hand-pasted instrument; Appendix B drafted, wording read-through still open (Q25) |
| **Chapter 4 — Satisfaction** | **Done 2026-09-18 (D111-D118).** Six items (`A9` reversed, `D4a`, `D4i`, `D4j`, `D4k`, `D4l`) in one place: inventory, a landscape matrix by group, respondent- and group-level correlations, and the size-vs-numbers paired comparison for the catch pair and the harvest pair. 6 tables, 2 dumbbell figures |
| **Chapter 5 — Angler Type Profiles** | **Planned 2026-09-21, content not yet defined (D119).** The title is all that exists. Elicit it — do not assume "angler type" means clustering, an existing variable, or a published typology. If the types are *derived*, this is the report's first modelling work and the D5 precedent applies in full. See the Chapter 5 handoff at the end of `PROGRESS.md` |

**Render baseline: 81 tables / 55 images / 8 landscape sections / 0 leaked markup** (was 75/53/7
before Chapter 4). Verify every increment against it. Use the F41 regex for the leaked-markup
scan — the obvious one gives false positives.

**Inference (D112/D114):** Chapter 4 was granted an exception to the no-inference rule, and it
**goes unused** — the user declined significance testing and chose a descriptive dumbbell figure.
Paired differences are weighted means with the standard Kish-effN interval, unadjusted, disclosed
in Appendix B. If testing is ever added, the D5 precedent still applies: a stated multiplicity plan
and its own Appendix B section.

Three structural facts that are easy to get wrong and are already settled:

1. **Universe:** `filter(surveyYear == 2025)` then `filter(!is.na(B1))` → **n = 1,915** (D23).
2. **The banner overlaps and is not a partition** (D31): 17 columns, family columns contain their
   own species columns, counts sum to 2,695 against 1,874 distinct. Never total them.
3. **Scale scores carry the `*_AnsweredAll` listwise gate** per scale (D19), or the Overall
   column will not reproduce.

Read `PROGRESS.md` for decisions D1-D119, findings F1-F41, and open questions; `ANALYSIS_PLAN.md`
for the executable spec (written for steps 1-3; §8 records that Chapters 4 and 5 sit outside it).
