# D4ScaleAnalysis — Project Instructions

> **Read this file first in any new conversation.** It carries the standing directive, the
> settled design, and the verified facts, so none of it has to be re-derived (or re-paid for
> in tokens). Companion files: `ANALYSIS_PLAN.md` (executable spec), `PROGRESS.md`
> (decisions, findings, status), `PROMPTS.md` (verbatim prompt log).

---

## 1. What this project is

A standalone, ground-up psychometric analysis of the survey's **`D4` battery** — 13
agree/disagree items asked of anglers about the one type of fish they prefer to fish for.
It exists because `f:/Survey/Analysis/PreferredSpecies/` paused its Chapter 2 (decision
**D46** there) pending an answer to one question: *does the `D4` battery have a sub-scale
structure, and if so what is it?* This report answers that and recommends a scoring scheme.

It is a **sibling project**, not a chapter of the other one. It keeps its own memory files
and renders its own Word document.

### Standing directive, distilled

1. **Voice differs from the other survey reports.** Explanation, discussion, and an explicit
   recommendation **are** wanted here. Still no causal language, and no calling a model
   "good" — report fit statistics against their conventional cutoffs and let them stand.
2. **Never edit upstream.** Nothing in `../CrossTabTables/`, `../TrendTables/`,
   `../BaseFunctions_2025_UPDATED.R`, `../../Data/`, or `../PreferredSpecies/` is modified.
   The single exception granted by the user: appending to `../PreferredSpecies/PROGRESS.md`
   and `../PreferredSpecies/PROMPTS.md`.
3. **Verify code by running it** before claiming it works.
4. **Never drop NAs silently**; report missingness, profile who listwise deletion removes,
   never impute without being asked.
5. **Keep `PROGRESS.md` and `PROMPTS.md` current**, and log every prompt verbatim.
6. **Announce token-saving actions** (save to file, start a new conversation, etc.).

---

## 2. Settled design (do not re-litigate)

Current design is the **pooled two-wave sample with a random development/test split**
(D63, replacing the original wave-based design).

| Item | Decision |
|---|---|
| Deliverable | `D4ScaleReport.rmd` + `D4ScaleFunctions.R`, flat layout, `officedown::rdocx_document` → `D4ScaleReport.docx` |
| Battery | **13 items**, `D4a`–`D4m`, no gaps. `D4e` is real and present in both waves (F14) |
| Universe | `surveyYear %in% c(2018, 2025)`, `!is.na(B1)`, `B1 != "I do not prefer any particular type of fish"` |
| Pooled n | **3,076** — 1,500 from 2018 and 1,576 from 2025; 2,683 complete on all 13 |
| Split | **50/50 random, stratified by wave**, seed 4827, applied to respondents not complete cases → Development **1,538** (1,339 complete), Test **1,538** (1,344 complete) |
| Development half | Chapters 2–7: distributions, correlations, factorability, retention, EFA, item assignment, reliability, and the one respecification |
| Test half | Chapter 8 only, read once |
| Weighting | **None anywhere.** No `postWeight`, no `svydesign`. This is the one survey report that is entirely unweighted, and it says so in Appendix B |
| Correlations | **Polychoric**, `psych::polychoric(smooth = TRUE)` |
| Missing data | **Listwise primary, pairwise sensitivity.** Full missingness table plus a profile of who deletion drops |
| Extraction | minres + oblimin; loadings reported for k−1, k, k+1 |
| Retained k | **3** (D53), and the k+1 solution is carried into Chapter 8 as a competing model rather than dismissed by argument |
| CFA | `lavaan`, `ordered = items`, WLSMV, six models on the test half, each with an admissibility check |
| Seed | **4827**, set before the split and before every stochastic routine |

### Sections and where they live

| Section | Chapter | Sample |
|---|---|---|
| Scope, pooling, split, missing data | 1 | pooled + development |
| Distributions, item means by wave | 2 | development |
| Correlations | 3 | development |
| Factorability (KMO / Bartlett / determinant) | 4 | development |
| Retention (parallel / MAP / VSS / scree) | 5 | development |
| EFA, assignment, stability, development misfit | 6 | development |
| Reliability | 7 | development |
| CFA, dev-vs-test fit, by-wave fit and congruence | 8 | **test** |
| Recommendation and scoring | 9 | pooled (scores only) |
| Appendix A items, Appendix B methodology | — | — |

### The archived design

`D4ScaleReport_waveDesign.rmd` + `D4ScaleFunctions_waveDesign.R` +
`D4ScaleReport_waveDesign.docx` hold the **original** design: EFA on 2025, CFA on 2018.
Both render. The archive sources a **frozen copy** of the functions file, so the live
`D4ScaleFunctions.R` can evolve without breaking it. Do not delete either without asking.

---

## 3. The answer this project produces

Three sub-scales, derived at render time from the fitted development-half loadings rather
than hardcoded:

| Scale | Items | Ordinal alpha | Congeneric omega |
|---|---|---|---|
| Satisfaction | D4i, D4j, D4k, D4l | 0.806 | 0.807 |
| Constraints | D4a *(reversed)*, D4f, D4h, D4m | 0.774 | 0.775 |
| Regulation support | D4c, D4d, D4e | 0.753 | 0.767 |

`D4b` and `D4g` belong to no scale and stay item-level. Scoring: mean of items on the 1–5
metric, `D4a` reversed as 6 − response, scored only for respondents complete on that scale
(the `*_AnsweredAll` convention used elsewhere in the survey reporting).

Two things the held-out half settled that argument could not: moving `D4a` to Satisfaction
makes fit **worse**, and the four-factor solution is **inadmissible** on fresh data. The
best-fitting admissible specification frees the `D4h`–`D4m` residual covariance — a
measurement detail that does not change scale composition.

**This recommendation is not yet signed off by the user.** See `PROGRESS.md` open questions.

---

## 4. Environment facts (verified 2026-09-17)

| Fact | Detail |
|---|---|
| R | 4.4.1, system library at `C:/Program Files/R/R-4.4.1/library` |
| `lavaan` | **Was not installed**, contrary to the original handoff note. Installed **0.7.2 from source** into the personal library `C:/Users/keith.hurley/AppData/Local/R/win-library/4.4`, which R picks up automatically now that it exists (F16) |
| `corrplot` | **Not installed.** Not needed — correlation heatmaps are drawn with `ggplot2` |
| `polycor`, `semTools`, `ggcorrplot` | Not installed. `semTools` would be needed only for formal measurement invariance (Q31) |
| Installed and used | `psych`, `GPArotation`, `officedown`, `officer`, `flextable`, `tidyverse`, `tictoc` |
| Render time | roughly 2–4 minutes; the slow steps are three polychoric matrices, parallel analysis, and eight WLSMV fits |

---

## 5. Inherited conventions kept

- `CreateFlex()` is cloned from `PreferredSpeciesFunctions.R` (itself cloned from
  `2025CrossTabReport.rmd` L50-86), including `paginate(init = TRUE, hdr_ftr = TRUE)`, so
  table styling and page-split behaviour match the other reports.
- Page 1 is deliberately blank for a hand-built title page; the TOC is placed with
  `block_toc()` under `toc: false`.
- Every table is preceded by its own lead-in paragraph so no two tables are adjacent — in
  Word, adjacent flextables merge and duplicate headers.
- R for everything, `ggplot2` for graphics, `<-`, two-space indent, `snake_case` for new
  objects (inherited helpers keep their existing `CamelCase` names).
- Comment intent only.

## 6. Gotchas that cost time once

- **Backticked column names break inline R in `.rmd`.** `` `r x$`My Col`` `` fails to parse.
  Compute the value in a chunk, or index with `x[["My Col"]]` (F22).
- **Factor congruence must be matched, not compared by position.** Factor order is
  arbitrary, so `diag(factor.congruence(a, b))` can report a permutation as a disagreement —
  it produced a nonsense −0.14 once. Match each factor to its best absolute counterpart (F25).
- **`GetQuestion()` hardcodes a `D4` stem ending "during 2018"** for every year (F15). This
  report does not use it; the stem is a constant, `d4.stem`, in `D4ScaleFunctions.R`.
- **Factor solutions are sign- and order-indeterminate.** `NameFactors()` orients and names
  the retained factors from marker items and returns `NULL` if a marker is ambiguous; the
  render stops rather than mislabel a column.
- **Models fitted to different item sets are not comparable on fit.** The four-factor model
  needs a twelfth item, so `CFAFitTable()` prints N and item count per model (F27).
