# D4ScaleAnalysis — Analysis Plan

Executable spec for `D4ScaleReport.rmd`. Written from the built report, so it describes what
the code does, not an intention. Section numbers map to report chapters.

Design: **both waves pooled, split at random into a development half and a test half.**
The earlier wave-based design (EFA on 2025, CFA on 2018) is archived as
`D4ScaleReport_waveDesign.rmd`; see D63 in `PROGRESS.md`.

---

## 1. Data, universe, and split

| Step | Code | Result |
|---|---|---|
| Load | `../../Data/DataAggregation1/aggregateData_20260624.rData` → `d` | one row per respondent, all waves |
| Codebook | `../../Data/DataAggregation1/FactorLevels_aggregated.csv` → `q`; `ItemText(q, 2025)` | `Item` + `Text` for `D4a`–`D4m` |
| Universe | `BuildD4Universe(d, c(2018, 2025))`: year in waves, `!is.na(B1)`, `B1 != "I do not prefer any particular type of fish"` | **3,076** (2018: 1,500; 2025: 1,576) |
| Items | `ItemMatrix()` — `as.numeric()` on the 13 factors | 1 = Strongly Disagree … 5 = Strongly Agree |
| Split | `SplitSample(prop = 0.5, seed = 4827)` — random within `surveyYear` | Development **1,538**, Test **1,538** |
| Listwise | `complete.cases()` | Development **1,339**, Test **1,344**, pooled 2,683 |

**Assumptions stated in the report body, not just here.**

1. The `B1 != "no particular type"` condition is a *routing* condition, not an analytic
   exclusion: the battery's referent does not exist for those respondents. A minority of
   them answered anyway and are excluded because the referent of their answers is unknown.
2. **Item structure is stable across waves.** Pooling averages the two waves if it is not.
   Checked descriptively in §2 (item means by wave) and at model level in §8 (retained
   model fitted within each wave, plus loading congruence). Both checks are after the fact.
3. **Respondents are distinct across waves.** Untestable: 2018 carries `licenseUID` /
   `OwnerCustomerUID`, 2025 carries `CustomerID` / `ID`, with zero overlap and no crosswalk.
   Repeat respondents could fall in both halves and flatter the replication. Disclosed, not
   adjusted for.

**Checks** (`dataChecks` chunk, `stopifnot`): all 13 items present; pooled n = 3,076; wave
sizes 1,500 and 1,576; halves sum to the pooled n and differ by at most 1; factor levels
identical to `d4.response.levels`. The render aborts if the delivered data moves.

**Discipline:** the test half is read exactly once, in §8. Every decision — number of
factors, item assignment, threshold, the single freed residual — is made on the development
half.

## 2. Weighting

None. `postWeight` is never referenced. Stated in Chapter 1 and Appendix B so no figure in
this report is mistaken for a population estimate.

## 3. Chapter-by-chapter spec

### Chapter 1 — scope, sample, design
`SplitTable()` (wave × half, respondents and complete cases), `MissingnessTable()` on the
pooled sample, `CompletenessTable()` (items answered per respondent),
`DroppedProfileTable()` on the development half (complete vs dropped on residency, sex, age
65+, median days fished, missing age), `SensitivityTable()` (listwise vs pairwise: median
and max absolute correlation difference, minimum matched Tucker congruence).

### Chapter 2 — distributions
`DistributionTable()` and `DistributionPlot()` on the development half.
`WaveItemTable()`: per-item mean, SD, and N by wave with the difference — descriptive only,
no tests, because 13 of them would invite reading noise as signal.

### Chapter 3 — correlations
`PolychoricMatrix()` on the development listwise sample; `CorrelationPlot()` heatmap with
printed coefficients; `CorrelationTable()`. Block magnitudes quoted inline from `R`.

### Chapter 4 — factorability
`FactorabilityTable()`: overall KMO, Bartlett chi-square/df/p, determinant, largest and
smallest absolute off-diagonal. `ItemMSATable()`: per-item MSA.

### Chapter 5 — retention
`ParallelAnalysis()` computed once and passed to both `RetentionTable()` (parallel, MAP,
VSS-1, VSS-2, empirical BIC, Kaiser) and `ScreePlot()`. Criteria disagree; k = 3 is retained
and k = 4 is carried to §8 as a competing model rather than argued away.

### Chapter 6 — EFA
`FitEFA()` at k−1, k, k+1 (`fm = "minres"`, `rotate = "oblimin"`). `AlignLoadings()` orients
each factor so its largest loading is positive. `NameFactors()` names and re-orients the
retained solution from marker items (`d4.markers`: Satisfaction ← D4j, Constraints ← D4f,
Regulation support ← D4c) and returns `NULL` — halting the render — if a marker fails to
identify exactly one factor. `EFAFitTable()`, `LoadingsTable()`, `FactorCorrelationTable()`.
`AssignItems()` assigns each item to the factor holding its largest absolute loading when
that loading ≥ `d4.loading.threshold` (0.40). The same rule is applied to the k+1 solution
under generic factor labels, producing `assignment4` for §8. A stability refit on the
assigned items only reports the largest absolute loading at k and k+1 (a value ≥ 1.0 would
be a Heywood case).

**Development misfit, deliberately located here:** the retained structure is fitted as a
CFA *within the development half* (`fitDev`), and `ResidualTable()` plus the residual-
covariance modification indices identify `D4h`–`D4m`. Freeing that covariance is therefore
specified on development data and tested on the untouched half — not a post-hoc repair.

### Chapter 7 — reliability
`AlignedSubmatrix()` sign-aligns reverse-scored items; `psych::alpha()` on the polychoric
submatrix gives ordinal alpha, item-rest correlations, and alpha-if-dropped;
`CongenericOmega()` computes omega from a one-factor minres solution as
$$\omega = \frac{(\sum\lambda)^2}{(\sum\lambda)^2 + \sum(1-\lambda^2)}$$
directly, avoiding `psych::omega()`'s undefined-omega-hierarchical warning. The report notes
that the `D4h`–`D4m` overlap inflates the Constraints coefficients somewhat.

### Chapter 8 — CFA on the test half
`CFASyntax()` builds lavaan syntax **from the fitted assignment**, ordering each factor's
indicators so the largest positive loading is the marker. Six models:

| Model | Items | Purpose |
|---|---|---|
| One factor | 11 | is the battery one thing? |
| Two factors | 11 | Satisfaction + Constraints merged |
| Three factors (retained) | 11 | the §6 solution |
| Three factors, D4a on Satisfaction | 11 | tests the one ambiguous assignment |
| Three factors, `D4h ~~ D4m` freed | 11 | development-derived respecification |
| Four factors | **12** | the k+1 solution; needs D4g, so fit is not directly comparable |

`FitCFA()` uses `ordered = names(cfaData)`, `estimator = "WLSMV"`. `CFAFitTable()` reports
N, item count, scaled chi-square, df, CFI, TLI, RMSEA, SRMR, and **Admissible** from
`lavInspect(f, "post.check")`. Then `devTestTable` (retained model on both halves, to check
for shrinkage), `WaveFitTable()` and `WaveCongruenceTable()` (retained model within each
wave of the test half), `ResidualTable()`, `CFALoadingTable()`,
`CFAFactorCorrelationTable()`.

**Check:** every item in the four-factor model is a `D4` item, and the by-wave table has one
row per wave.

### Chapter 9 — recommendation
Scale definition table; `ScaleScores()` on the **pooled** sample (mean of items, reverse
items as 6 − response, scored only when complete within the scale); `ScaleScoreTable()`;
correlations among the scores; qualifications.

### Appendices
A — item wording, assignment, response coding. B — methodology: no weighting and why,
pooling and its two assumptions, the split and what it does and does not establish, why the
earlier wave design was replaced, polychoric rationale, missing data, extraction and
rotation, sign/naming and congruence-matching conventions, threshold convention, retention
criteria, reliability coefficients, WLSMV and admissibility, comparability across item sets,
reproducibility.

## 4. Display conventions

Correlations, loadings, means, SD, skew, kurtosis, MSA: 2 dp. Reliability coefficients,
CFI/TLI/RMSEA/SRMR, congruence: 3 dp. Percentages: 1 dp. p-values: `<0.001` or 3 dp.
Chi-square: 1 dp. Counts: comma-grouped integers.

## 5. What this plan deliberately does not do

- No weighted estimation, no design objects, no population expansion.
- No imputation, no item deletion beyond reporting which items fail to load.
- **No formal measurement-invariance test** across waves. §8 checks that the same model
  describes both waves and that loadings are congruent; constraining loadings and thresholds
  and comparing fit would require `semTools` and is flagged as a possible extension (Q31).
- No modification-index-driven respecification beyond the single `D4h ~~ D4m` covariance,
  which is specified on development data and tested out of sample.
- No claim of generalization beyond these respondents: the split tests replication across
  respondents, not across populations, modes, or future waves.
