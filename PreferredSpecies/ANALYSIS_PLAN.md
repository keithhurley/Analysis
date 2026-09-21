# PreferredSpecies Report — Analysis Plan

Approved 2026-09-17. Read together with `AGENTS.md` (directive + inherited methodology) and
`PROGRESS.md` (decision log D1-D17). This file is the executable specification: a new
conversation should be able to start from these three files alone.

**Status:** verification checks V1-V7 were run 2026-09-17 and all pass — results and the
verified `B1` distribution live in `PROGRESS.md`. Everything else below is still a
specification, not a result.

---

## 1. Deliverables

| File | Purpose | Status |
|---|---|---|
| `PreferredSpeciesReport.rmd` | The report. Cloned from `../CrossTabTables/2025CrossTabReport.rmd`, same YAML (`officedown::rdocx_document`, `toc: true`), same `CreateFlex()` styling | **Created 2026-09-17; renders to `PreferredSpeciesReport.docx`** |
| `PreferredSpeciesFunctions.R` | Banner-by-species table wrappers + the design-based contrast helpers | **Created 2026-09-17**; Chapter 1 builders and pairwise contrast helpers done |
| `.gitignore` | Mirrors `CrossTabTables/.gitignore`, plus the rendered output and the inert instrument copy (D37) | **Created 2026-09-17** |

Flat layout in the project root (D17), so cloned relative paths resolve unchanged:
`load("../../Data/DataAggregation1/aggregateData_20260624.rData")`,
`source("../BaseFunctions_2025_UPDATED.R")`.

---

## 2. Banner construction

### 2.1 Species grouping — final, 8 banner columns (D1, D18, D22; counts verified)

**No catch-all column appears anywhere in the banner (D22).** There is no "Other", no
"Other / Unique", and no "Uniques" column. Every banner column is a real, named species group.

| Banner column | `B1` codes folded in | n |
|---|---|---|
| Walleye / Sauger | 9 Walleye / Sauger | 499 |
| Bass | 4 Largemouth bass, 5 Smallmouth bass | 357 |
| No preference | 21 I do not prefer any particular type of fish | 339 |
| Panfish / Sunfish | 6 Bluegill / Sunfish, 7 Crappie, 8 Yellow perch | 236 |
| Catfish | 12 Channel, 13 Blue, 14 Flathead | 228 |
| Trout | 19 Trout | 90 |
| Moronides | 1 Striped bass, 2 Wiper, 3 White bass | 85 |
| Esocids | 10 Northern pike, 11 Muskellunge / Tiger musky | 40 |
| **Banner total** | | **1874** |

Under D23 there are now **two distinct kinds of exclusion**, and they must not be conflated:

| Kind | Who | n | Where they appear |
|---|---|---|---|
| **Out of the report** | `B1` missing | 907 | nowhere — filtered out first |
| **In the report, no banner column** | Paddlefish 14, Common carp 9, Drum 6, Bullhead 4, "Other" 4, Invasive carp 4, Sturgeon 0 | **41** | Overall column only |

Reconciliation, verified in R and asserted in the report's `dataChecks` chunk:
2822 − 907 = **1915** report universe; 1915 − 41 = **1874** banner coverage.

**Yellow perch — resolved by V1.** `gtype` places Yellow perch in Sunfish, matching §2.1 above;
`gtype2` breaks it out standalone. Both encodings exist upstream, so §2.1 is consistent with
`gtype`. Yellow perch remains a Panfish member and a Chapter 1 split candidate.

**Bullhead — removed and banner-dropped (D18).** `B1` = 15 Bullhead (n = 4) is no longer part of
the Catfish group and is no longer a split candidate. It is handled exactly like `B1` = "Other"
and `B1` = `NA` under D7/D9: **no banner column, retained in the Overall column**, and counted in
the §3.1 accounting so the 4 respondents stay visible. Combined Catfish is therefore
Channel + Blue + Flathead, **n = 228**.

### 2.2 Split candidates for Chapter 1 (10 species)

| Genus | Species tested separately |
|---|---|
| Bass | Largemouth, Smallmouth |
| Panfish | Bluegill/Sunfish, Crappie, Yellow perch |
| Esocids | Northern pike, Muskellunge/Tiger musky |
| Catfish | Channel, Blue, Flathead |

Each genus is also carried as a combined reference row.

### 2.3 Universe rules (D23; supersedes D6/D9)

**The `B1` filter comes first, before anything else:**

```r
d <- d %>% filter(surveyYear == 2025) %>% filter(!is.na(B1))   # 2822 -> 1915
```

- **n = 1915** is the report universe. The 907 respondents who left `B1` blank are out of the
  report entirely, not merely out of the banner.
- Each question then keeps the **same universe as in the crosstab report** — including its
  existing gates (`B3*` filtered to respondents who caught that species; `D13*` gated on
  `B2rbt`) and the `*_AnsweredAll` gate below.
- Within the 1915, **41** respondents still get no banner column (Bullhead 4, "Other" 4, and the
  5 unique species 33). They remain in the Overall column, so species columns miss Overall by 41
  rather than by 948. Footnote it; itemize in §3.3.
- **Consequence — the Overall column no longer matches the crosstabs report. Divergence
  accepted (D28).** The estimand changes from "all 2025 anglers" to "2025 anglers who stated a
  preference." Measured divergence: `Resi` 86.7% → 85.3% (−1.39 pp), `attitude_harvest`
  2.26 → 2.19, other scale means shift 0.003–0.019. The **`B1` distribution itself is
  unaffected** — `base.summary.*` already drops `B1 = NA`, so the V7 23/23 match survives
  untouched. This supersedes the value-matching rule in §4 for every column except the `B1`
  distribution; it is disclosed in the Chapter 1 preamble and must be repeated in the appendix.
- `D4*` is asked only of respondents who prefer a species, so the "No preference" column is
  structurally empty there. Footnote as a survey gate, not as missingness.
- **Scale scores carry the crosstab report's `*_AnsweredAll` gate (D19, verified V4).** Every
  `motivation_*` / `attitude_*` table filters to respondents who answered **all** items in that
  sub-scale, exactly as `2025CrossTabReport.rmd` L1382 does:

  ```r
  d %>% filter(get(paste0(i, "_AnsweredAll")) == TRUE)
  ```

  The gate is applied **per scale**, so each scale has its own universe. Under the crosstab
  universe n ran 2418-2497; **under D23 it runs 1653-1715**. Note the gate is a *listwise*
  requirement, not an NA drop we are choosing — it is inherited, and the excluded counts are
  reported.

### 2.5 Final banner — 17 columns, overlapping (D31; resolves D26)

Chapter 1 is signed off and the banner is now fixed. **Bass, Panfish / Sunfish, and Catfish
carry both a combined column and one column per species. Esocids is split outright into
Northern pike and Muskellunge, with no combined Esocids column.**

| # | Column | Level | n |
|---|---|---|---|
| 1 | Walleye / Sauger | Family | 499 |
| 2 | Bass | Family | 357 |
| 3 | — Largemouth bass | Species | 316 |
| 4 | — Smallmouth bass | Species | 41 |
| 5 | Panfish / Sunfish | Family | 236 |
| 6 | — Crappie | Species | 181 |
| 7 | — Bluegill / Sunfish | Species | 43 |
| 8 | — Yellow perch | Species | 12 |
| 9 | Catfish | Family | 228 |
| 10 | — Channel catfish | Species | 151 |
| 11 | — Blue catfish | Species | 27 |
| 12 | — Flathead catfish | Species | 50 |
| 13 | Moronides | Family | 85 |
| 14 | Trout | Family | 90 |
| 15 | Northern pike | Family split | 32 |
| 16 | Muskellunge / Tiger musky | Family split | 8 |
| 17 | No preference | Family | 339 |

⚠️ **The banner is no longer a partition.** A largemouth-bass angler is counted in both the Bass
column and the Largemouth bass column, so:

- column respondent counts **sum to 2,695, not 1,874** — they must never be totalled
  (1,874 distinct + 821 duplicated species rows: Bass 357, Panfish 236, Catfish 228). The
  report computes this live as `nBannerCellSum`; do not hardcode it;
- distinct coverage is still **1,874**, with the same 41 respondents excluded as before;
- each column is its own denominator, so within-column percentages remain correct. Only
  cross-column addition is invalid. Footnote via `caption.banner` on every banner table.

Implementation: `banner.definition` in `PreferredSpeciesFunctions.R` — a tibble of
`Column` / `Type` / `Members`, where `Members` is a list-column of `B1` levels. A single factor
cannot express overlapping membership, so **`AssignBannerGroup()` is retained only for coverage
accounting** (the 8 family groups), and banner tables are built by looping over
`banner.definition` and computing each column on its own subset.

Bullhead never returns (D18). Layout for Chapter 3 (D8) now has a firm 17-column target, which
almost certainly forces transposed or split tables.

### 2.4 Display precision (D21)

The crosstab report rounds means and CIs to 1 decimal, which renders every scale-mean CI as
`+-0` (true width ~±0.037 on the 1-5 scale). Chapter 1 compares species means against one
another, so that precision is unusable.

**Rule:** report the CI to **2 significant figures** and the estimate to the same decimal place
as the CI. Resulting defaults:

| Quantity | Estimate | CI |
|---|---|---|
| Scale means (1-5) | 3 dp | 3 dp |
| `C1Total_days` mean / median | 1 dp | 2 dp |
| Percentages | 1 dp *(unchanged)* | 2 dp |

This is a **display change local to this report**. No upstream value, function, or report is
modified; the underlying numbers are identical to the crosstabs (V4, V7).

---

## 3. Chapter 1 — species grouping determination

### 3.1 Question text

Open the chapter with the verbatim 2025 `B1` wording, pulled from the codebook rather than
retyped: `GetQuestion(q, B1, 2025)`.

### 3.2 Species sample-size and population table — **leads the chapter (D25)**

One row per individual `B1` species (all 22 non-missing levels, not just the 10 split
candidates), with:

| Column | Definition |
|---|---|
| Respondents | raw unweighted n |
| Effective n | Kish `effN = (Σw)²/Σw²` — the quantity that governs CI width |
| Weighted respondents | `Σw × n / Σw_total`, i.e. weights rescaled to sum to the 1915 sample |
| % of angler population | weighted column % ±95% CI |
| Total anglers | population-level expansion, `Σw` ±95% CI |

Reporting effN is a deliberate departure from the crosstab report, which never displays it.
This table subsumes the old "`B1` distribution" table: the `%` column *is* the V7-verified
`base.summary.percent.selectOne(d, B1)` output, so the 23/23 match to the crosstab report's
"Preferred Fish" table (L744-756) is preserved.

**Two quantities in this table are redundant by construction** — `Weighted respondents` =
`% × 1915 / 100`, and `Total anglers` = `% × 234,125 / 100`. They differ only in scale. All are
retained because all were requested (Q19 resolved).

**Population-expansion basis — resolved (D29).** `Total anglers` uses the **rescaled basis**:
weighted % × the full 2025 angler population of **234,125**, so the column sums to that
population (asserted in the report's `dataChecks` chunk). Note that `Σw` over the 1915 `B1`
respondents is only **171,760**, i.e. 73.4% of the population, so this rescaling **assumes that
leaving `B1` blank is unrelated to species preference**. That assumption is untestable with
these data — there is no preference recorded for the 907 who skipped the question — and is
stated in the report body and the appendix.

### 3.3 Banner column sizes and exclusion accounting

Raw n and effN for each of the 8 banner columns (§2.1), plus the itemized 41 respondents inside
the universe who receive no banner column. Minimum-n / power threshold per Q20 and §3.7.

### 3.4 Comparison blocks (one per genus)

Descriptive tables using the inherited functions unmodified, so the arithmetic matches the
crosstab machinery by construction:

| Family | Variables | Function |
|---|---|---|
| Motivation | `motivation_natural`, `motivation_pp`, `motivation_social`, `motivation_resource` | `base.summary.means` |
| Attitude | `attitude_catch`, `attitude_numbers`, `attitude_size`, `attitude_harvest` | `base.summary.means` |
| Effort | `C1Total_days` | `base.summary.means` + `base.summary.medians` (seed 7361) |

Each block shows one row per split-candidate species plus a combined-genus reference row.

Universe per §2.3: the motivation and attitude blocks apply the `*_AnsweredAll == TRUE` gate
(D19); `C1Total_days` uses its crosstab universe unchanged. Precision per §2.4 (D21).

### 3.5 Test blocks (one per genus) — D5, D10, D14, D15

**Design object.** Weights normalized to sum to the sample size before anything else:

```r
w_norm <- postWeight * n / sum(postWeight)
des <- svydesign(ids = ~1, weights = ~w_norm, data = <analysis subset>)
```

**Corrected rationale (D20, from finding F1 — the earlier wording was wrong).** Verified
numerically: with `ids = ~1`, `survey`'s linearization SE is **scale-invariant in the weights**.
Raw `postWeight` and `w_norm` give *identical* SEs (agreement to 5 dp on both a scale mean and a
23-level proportion) and identical `degf()` = 1914. So normalization does **not** rescue the SEs
— it is a no-op safeguard, retained because it makes the weights commensurate with the raw n and
prevents anyone reading `svytotal`-style output as a sample count.

The "SEs ~9x too tight" failure is real, but it belongs to the **manual** Σw-based CI, which is
why the inherited `base.summary.*` functions divide by Kish effN instead of Σw (Appendix B).
That correction has nothing to do with `svydesign()`. Do not repeat the old claim.

**Tests — pairwise only, no omnibus (D32).** The `svyglm` + `regTermTest()` Wald F is **dropped**.
Every row of every test table is a single design-based two-sample comparison:

```r
svyttest(outcome ~ species_pair, des)     # survey's design-based t-test
```

`svychisq()` remains the plan for categorical outcomes if any are added later.

Implementation note: `svyttest()` returns an `htest`, and **`coef()` / `confint()` are not
defined for it** — reading them yields `numeric(0)` and silently collapses the result to zero
rows. Use `tt$estimate` and `tt$conf.int`. `tt$estimate` is **SpeciesB minus SpeciesA**.

**Multiplicity — Bonferroni only (D32).** Bonferroni across the contrasts available for a given
outcome within a given family (D24): **×1** for Bass and Esocids, **×3** for Panfish and
Catfish. Implemented as `pmin(1, p * n_contrasts)` and reported as a `Bonferroni p` column
beside the unadjusted `p`, rather than as a fixed α threshold.

Two consequences of dropping the Wald F, both deliberate:

- D14's 4-outcome family (α = 0.0125) governed the omnibus tests and **no longer applies**.
  Multiplicity across the 8 outcomes within a family is therefore **unadjusted** — see F8.
- `C1Total_days` is no longer "unadjusted" as D14 had it; it now takes the same
  contrast-count adjustment as every other outcome.

**Magnitudes reported next to every p-value** (D15): raw weighted mean difference with 95% CI
and Hedges' g on effective sample sizes. **Model R²/eta² is dropped** along with the omnibus
model that defined it.

### 3.6 Disposition table

One row per split candidate: n, effN, adjusted p per family, magnitudes, and a blank
**decision column for the user**. Splits are never automatic (D5).

### 3.7 Power — computed, then DROPPED from the report (D30)

**Not in the report and not in the code.** The helper functions and the report section were
removed at the user's direction; the user makes the split/combine calls subjectively from the
§3.4 comparison tables instead. The figures are retained here only as a standing caveat on how
to read those comparisons — they are not to be reinstated as tables without a new decision.

Two-sided normal approximation on the effective sample sizes, 80% power.

**Minimum detectable Hedges' g, per within-genus contrast:**

| Genus | Comparison | effN A | effN B | α | Min. detectable g |
|---|---|---|---|---|---|
| Bass | Largemouth vs. Smallmouth | 261.5 | 34.8 | 0.0125 | **0.60** |
| Catfish | Channel vs. Flathead | 118.9 | 40.7 | 0.0167 | **0.59** |
| Panfish | Crappie vs. Bluegill | 144.2 | 34.5 | 0.0167 | **0.61** |
| Catfish | Channel vs. Blue | 118.9 | 22.6 | 0.0167 | **0.74** |
| Catfish | Blue vs. Flathead | 22.6 | 40.7 | 0.0167 | **0.85** |
| Panfish | Crappie vs. Yellow perch | 144.2 | 11.1 | 0.0167 | **1.01** |
| Panfish | Bluegill vs. Yellow perch | 34.5 | 11.1 | 0.0167 | **1.12** |
| Esocids | Northern pike vs. Musky | 26.9 | 7.3 | 0.0125 | **1.40** |

**Required effective n per group, equal groups:**

| Target g | effN (omnibus, α = 0.0125) | effN (pairwise, α = 0.0167) | implied raw n |
|---|---|---|---|
| 0.2 | 558 | 524 | 691 |
| 0.3 | 248 | 233 | 307 |
| 0.5 | 90 | 84 | 112 |
| 0.8 | 35 | 33 | 44 |

Observed effN / raw n across species: 0.66-0.95, median **0.82**.

**Standing caveat for reading §3.4.** *No* within-genus contrast can resolve a conventionally
medium difference (g = 0.5) at 80% power; the best case is g ≈ 0.59. Four contrasts cannot
resolve anything below g ≈ 0.74, and Northern pike vs. Muskellunge cannot resolve anything below
g ≈ 1.40. Two consequences survive the removal of the power tables:

1. **Overlapping confidence intervals in §3.4 are weak evidence of similarity**, not strong
   evidence. For the small species they are wide enough to be consistent with large differences.
   The Muskellunge days-fished row (63.8 ± 50.49, n = 8) is the clearest illustration.
2. If the design-based tests (§3.5) are ever run, a non-significant result will for most genera
   be uninformative rather than evidence of similarity — which is why D15 requires the raw
   difference, its CI, and Hedges' g alongside every p-value.

No minimum-n rule is applied (Q20 resolved; D16 stands).

---

## 4. Chapter 2 — species-linked scale questions (step 2)

`D4*` battery ("Thinking about the one type of fish that you prefer to fish for..."), Likert 1-5
`labels.agree`. Item-level means ±CI and medians ±bootstrap CI by species group, mirroring the
crosstab report's "Preferred Species Questions" section (L761-804). Check `Scales.csv` for any
`D4` sub-scale definition before deciding between item-level and composite presentation.

Candidates to include alongside: `B2*` (species sought) and `B3*` (harvest/release), since both
are species-linked and gain meaning when banner-split by preferred species.

---

## 5. Chapter 3 — full crosstabs by species banner (step 3)

Every question in the crosstab report, in the same order, with `myGroupVar` = collapsed `B1`,
using `base.summary.percent.selectOne`, `base.summary.percent.selectAll`, `base.summary.means`,
`base.summary.medians` unmodified. `B1` itself is the banner and is not crossed with itself.

**Deferred (D8, Q7):** table layout — transpose (species as rows) vs. landscape wide tables vs.
Table A/B split — and whether coverage is exhaustive or curated. Decide once Chapter 1 fixes the
final column count.

---

## 6. Chapters 4-6

- **Step 4 — no chapter of its own (D34).** Visualizations are **interspersed within Chapters
  1-3**, placed beside the question each one illustrates. Use the `TrendTableFunctions.R` helpers
  (`CreatePercPlot`, `CreateMeanPlot`, `CreateMedianPlot`, `CreateLikert_Grouped`) adapted to the
  species banner. Question selection is the user's.
- **Step 5:** guided text development. Assistant supplies numbers only; no interpretive language.
- **Step 6 — appendices.** **Appendix A: Survey Instrument** is **done** (D35): the 2025
  instrument poured in with `block_pour_docx()`. **Appendix B: Statistical Methodology** carries
  over verbatim from `2025CrossTabReport.rmd` L1549-1612, **plus new paragraphs** documenting:
  - **(a)** the design object. State that two *different* variance devices are in play and that
    they are not substitutes: the inherited tables use a **manual Kish-effN** CI (Appendix B's
    existing correction for population-scaled weights), while the new tests use
    **`svydesign(ids = ~1)` linearization**, whose SEs are scale-invariant in the weights.
    Weights are normalized to sum to n as a presentational safeguard, **not** as a variance fix.
    Do **not** write that raw `postWeight` would make the design-based SEs ~9x too tight — it
    would not (verified, F1 / D20). Report the observed agreement between the two devices
    (V6: CI ratio 0.98-1.03 for means; 0.94-1.02 for percentages with n > 80, widening to
    0.82-1.27 below n ≈ 15).
  - **(b)** the design-based pairwise `svyttest()` comparisons, and that **no omnibus Wald F is
    used** (D32) — so no model R²/eta² either. Rao-Scott `svychisq` remains the plan if
    categorical outcomes are added.
  - **(c)** the Bonferroni family definition and its power tradeoff versus Holm (D14, D14a).
  - **(d)** the effect-size measures (D15).
  - **(e)** the two exclusion tiers (D23): `B1 = NA` is excluded from the **report**, while
    Bullhead, "Other", and the five unique species are excluded from the **banner only** and
    remain in Overall — plus why banner columns do not sum to Overall.
  - **(h)** that the banner **overlaps** (D31): family columns contain their species columns, so
    column counts sum to 2,695 against 1,874 distinct respondents and must never be totalled.
  - **(i)** the unadjusted outcome dimension (F8) — Bonferroni covers only the contrasts within
    a single outcome, not the 8 outcomes tested per family.
  - **(f)** the `*_AnsweredAll` listwise gate on scale scores and the per-scale universes it
    creates (D19).
  - **(g)** the increased display precision in Chapter 1 versus the crosstab report, and that it
    is a rounding change only (D21).

---

## 7. Verification checklist — COMPLETE (2026-09-17, V1-V7 all pass)

Full results, the verified `B1` distribution, and the verified collapsed group sizes are recorded
in `PROGRESS.md`. Headline: **zero discrepancies against the crosstabs report** — V4 (8/8 scale
means), V5 (collapsed % exact to 1.8e-15), and V7 (23/23 `B1` cells) all reproduce the rendered
`2025_Angler_Survey_Crosstabs_Final.docx` string-for-string.

Re-run V4/V5/V7 as regression checks after any change to the banner definition or the universe
rules. Any discrepancy is logged in `PROGRESS.md` and raised with the user; upstream reports are
never modified (AGENTS.md rule 4).

---

## 8. Chapters added after this plan was written

This plan was written for steps 1-6 as the user originally framed them, and it is authoritative
only for Chapters 1-3 and the appendices. Two chapters have been added since, neither of them
anticipated here. Read `PROGRESS.md` for their decisions; this section exists so nobody treats the
plan's silence as a statement that they do not exist.

| Chapter | Status | Where it is specified |
|---|---|---|
| 4 — Satisfaction | **Built** 2026-09-18 (D111-D118) | `PROGRESS.md`, "Chapter 4 built" |
| 5 — Angler Type Profiles | **Planned, content not yet defined** (D119) | To be elicited; see the Chapter 5 handoff at the end of `PROGRESS.md` |

Chapter 4 departs from this plan in two ways worth carrying forward. It reverses `A9` so that all
six satisfaction items point the same direction (D113), which is the only variable transformation
anywhere in the report. And it reports paired differences between two items within a respondent
(D114) — a comparison form §3.5 does not cover, computed with `base.summary.means` on a difference
column so that the interval remains the inherited Kish-effN interval rather than a new device.

Chapter 5 is expected to need more of this section than Chapter 4 did. If angler types are
**derived** rather than taken from an existing variable, the report acquires its first modelling
step, and §6's Appendix B list must gain an entry describing how the types were built, on what
universe, with what treatment of the survey weights, and how the solution was validated. The D5
precedent — inference requires a stated plan, a multiplicity policy, and its own appendix section —
applies to that work in full.
