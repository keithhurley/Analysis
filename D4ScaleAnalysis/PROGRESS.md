# D4ScaleAnalysis — Progress, Decisions, Findings

Last updated: 2026-09-17

Decision and finding numbering continues the `../PreferredSpecies/` series (D1–D46,
F1–F15) so cross-references between the two linked projects stay unambiguous.

## Status

| Step | Description | Status |
|---|---|---|
| 0 | Project files (`AGENTS.md`, `ANALYSIS_PLAN.md`, `PROGRESS.md`, `PROMPTS.md`) | **Done**, updated for the pooled-split design |
| 1 | `D4ScaleFunctions.R` | **Done.** ~35 functions, all exercised by the render |
| 2 | `D4ScaleReport.rmd`, Chapters 1–9 + Appendices A and B | **Done (design v2).** Pooled two waves, random 50/50 stratified development/test split |
| 3 | Render verified | **Done 2026-09-17.** Both `D4ScaleReport.docx` and the archived `D4ScaleReport_waveDesign.docx` render clean |
| 4 | User sign-off on the recommendation | **Open** — Q26, Q29, Q30, Q31 remain; Q27 and Q28 answered by the held-out test |
| 5 | Hand back to `../PreferredSpecies/` Chapter 2 (unblocks D46) | Blocked on step 4 |

## Design history

**v1 (archived).** EFA on the 2025 wave, CFA on the 2018 wave. Files kept and renderable:
`D4ScaleReport_waveDesign.rmd`, `D4ScaleFunctions_waveDesign.R`,
`D4ScaleReport_waveDesign.docx`. The archived report sources the frozen functions copy so
the live functions file can evolve.

**v2 (current).** Both waves pooled (n = 3,076), split 50/50 at random, stratified by wave.
Development half carries all decisions; the test half is read once, in Chapter 8.

## Decisions

| # | Decision | Date |
|---|---|---|
| D47 | **Standalone sibling project** at `f:/Survey/Analysis/D4ScaleAnalysis/`, flat layout, own memory files, `.rmd` + `officedown::rdocx_document`. | 2026-09-17 |
| D48 | ~~2025-only universe with 2018 reserved for CFA~~ — **superseded by D63.** Universe rule itself is unchanged: year, `!is.na(B1)`, `B1 != "no particular type"`. | 2026-09-17 |
| D49 | **Nothing is weighted.** No `postWeight`, no `svydesign` anywhere. Disclosed in Chapter 1 and Appendix B. | 2026-09-17 |
| D50 | **Polychoric correlations throughout**, `smooth = TRUE`. | 2026-09-17 |
| D51 | **Listwise deletion primary, pairwise as sensitivity.** Full missingness table, items-answered distribution, and a profile of who deletion drops. No imputation. | 2026-09-17 |
| D52 | **Seed 4827** before every stochastic routine, now including the development/test split. | 2026-09-17 |
| D53 | **Retain k = 3.** Criteria span 2–5 (F19). Under v2 the retention argument is settled empirically: k = 4 is carried into Chapter 8 as a competing model and proves inadmissible on held-out data (F26). | 2026-09-17 |
| D54 | **Assignment is derived at render time**, not typed in: largest absolute loading ≥ 0.40. The CFA syntax is built from the same object, so confirmatory models cannot drift from the exploratory solution. | 2026-09-17 |
| D55 | **`D4b` and `D4g` are unassigned** and stay item-level. Per-item MSA 0.49 and 0.59 in the development half; largest loadings 0.27 and 0.36. | 2026-09-17 |
| D56 | **`D4a` goes to Constraints, reverse-scored.** Under v2 this is no longer a judgment call: the held-out comparison prefers it to the Satisfaction placement (CFI 0.910 vs 0.903, RMSEA 0.133 vs 0.138). Cost of dropping D4a entirely: Constraints alpha 0.774 → 0.736. | 2026-09-17 |
| D57 | ~~CFA on the 2018 wave~~ — **superseded by D63.** CFA now runs on the held-out half of the pooled sample, with a by-wave fit check retaining the time dimension. | 2026-09-17 |
| D58 | **The four-factor solution is rejected, now on held-out evidence** rather than on stability grounds. It is inadmissible on the test half (negative latent variance) and its fourth factor rests on two loosely related items (D4g, D4i). | 2026-09-17 |
| D59 | **The `D4h ~~ D4m` respecification is reported and is now legitimate**, because under v2 it is identified in the development half (residual-covariance MI 189.0) and tested on the untouched half, where it is the best-fitting admissible model (CFI 0.933, RMSEA 0.116). It does not change scale composition. | 2026-09-17 |
| D60 | **Scoring convention:** mean of the scale's items on the 1–5 metric, reverse items as 6 − response, scored only for respondents complete within that scale. Applied to the pooled sample in Chapter 9. | 2026-09-17 |
| D61 | **`lavaan` installed to the personal library** (F16), version 0.7.2 from source. `corrplot` absent; heatmaps use `ggplot2`. | 2026-09-17 |
| D62 | **The battery stem is a constant** (`d4.stem`) rather than a `GetQuestion()` call (F15). Still needs checking against the 2025 instrument (Q30). | 2026-09-17 |
| D63 | **Pooled two-wave sample with a random development/test split**, at the user's direction, replacing the wave-based design. 50/50, **stratified by survey year**, seed 4827, assigned to respondents rather than complete cases. Development 1,538 (1,339 complete); Test 1,538 (1,344 complete). Rationale for stratifying: an unstratified split could leave one half wave-heavy, reintroducing the confound the pooling was meant to remove. | 2026-09-17 |
| D64 | **The wave dimension is retained as a check, not as the design** (user's choice among three options). Chapter 2 compares item means by wave; Chapter 8 fits the retained model separately within each wave of the test half and reports loading congruence. This is explicitly *not* a measurement-invariance test, and the report says so. | 2026-09-17 |
| D65 | **The v1 files are kept alongside v2** (user's choice). The archived report sources `D4ScaleFunctions_waveDesign.R`, a frozen copy, so it stays renderable as the live functions file changes. Both rendered `.docx` files are gitignored. | 2026-09-17 |
| D66 | **Descriptives live on the development half**, not the pooled sample. Item distributions, the by-wave item comparison, correlations, factorability, retention, EFA, and reliability all use the development half; only the sample accounting in Chapter 1 and the final scale scores in Chapter 9 use the pooled sample. Reason: with ordinal WLSMV the item thresholds are part of the model, so examining test-half marginals would be a mild leak. | 2026-09-17 |
| D67 | **Development-half misfit is located deliberately in Chapter 6**, before the test half is opened, so that any respecification it suggests can be tested out of sample. This is the structural advantage v2 has over v1, where the respecification could only be fitted on the data that suggested it. | 2026-09-17 |
| D68 | **Model fit is reported with N and item count per model**, because the four-factor model requires a twelfth item and its fit statistics therefore rest on a different observed-variable set (F27). | 2026-09-17 |

## Findings

| # | Finding |
|---|---|
| F16 | **`lavaan` and `corrplot` were not installed**, contrary to the original handoff note. `lavaan` 0.7.2 installed from source into `C:/Users/keith.hurley/AppData/Local/R/win-library/4.4`; R adds that path automatically now that it exists. Version differs from the 0.6.21 the handoff named. |
| F17 | **Item missingness in this universe is 4.5–7.6 %, not the 18.8–21.3 % quoted in the original handoff.** The larger figure was computed over all `B1` responders, including respondents the battery routes past. Response to the battery is close to all-or-nothing: in the pooled sample 2,683 of 3,076 answered all 13 items and 108 answered none. |
| F18 | **Listwise deletion is not a neutral thinning.** In the development half the 199 dropped respondents are markedly older (44.1 % aged 65+ vs 27.6 %), fish far fewer days (median 8 vs 21), and are more than twice as likely to have skipped the age question (11.1 % vs 4.6 %). |
| F19 | **The retention criteria disagree widely** on the development half: parallel analysis 5, MAP 3, VSS complexity 1 → 2, VSS complexity 2 → 3, empirical BIC 5, Kaiser 4. Note `psych`'s printed VSS summary can disagree with the underlying `cfit` vector; the table uses the vector. |
| F20 | **No CFA model reaches the conventional RMSEA cutoff.** Best admissible is 0.116 (three factors with the freed residual) against a 0.06 reference; SRMR reaches 0.070–0.077 for the three-factor models. Misfit concentrates in one item pair, `D4h` ("travel too far") with `D4m` ("not enough places") — overlapping content rather than diffuse misspecification. |
| F21 | ~~**The four-factor solution is at the boundary of admissibility**~~ — **does not hold under v2.** On the pooled development half the reduced-item refit gives largest loadings of 0.88 at k = 3 and 0.90 at k = 4, with no Heywood case. The case against four factors is now the held-out CFA (F26), not EFA instability. Retained as a record of a claim that changed with the design. |
| F22 | **Backticked column names break inline R in `.rmd`.** `` `r x$`My Col`` `` fails knitr's inline parser with an unhelpful "unexpected end of input". Fix: compute in a chunk, or use `x[["My Col"]]`. |
| F23 | **Factor solutions are sign- and order-indeterminate**, so hardcoded column naming is a latent mislabelling bug. Handled by `NameFactors()` plus a `stopifnot`. |
| F24 | **EFA and CFA factor correlations differ in magnitude** — Satisfaction with Constraints is −0.41 in the development oblimin solution and −0.67 in the confirmatory model. Direction and interpretation agree; the gap is the usual one between a rotated solution that absorbs cross-loadings and a simple-structure model that forces them to zero. Not a discrepancy to fix. |
| F25 | **Congruence must be matched, not compared by position.** `diag(factor.congruence(a, b))` reported a lowest congruence of **−0.140** between the listwise and pairwise solutions purely because the factors came back in a different order. Fixed by matching each factor to its best absolute counterpart; the true value is 1.000. This bug would have been invisible in v1, where the orders happened to coincide — a reminder that a "sensible-looking" diagnostic can be silently wrong. |
| F26 | **The four-factor model fails on held-out data.** It is inadmissible on the test half (negative estimated latent variance) with CFI 0.905 on 12 items. Its fourth factor pairs D4g ("harvest opportunity matters more than size") with D4i ("satisfied with size caught"), which is not an obvious construct. This is the clearest single payoff of the split design: in v1 the analogous model looked like the *better* option on fit alone. |
| F27 | **Models on different item sets are not comparable on fit.** The four-factor model needs D4g, so it is fitted to 12 items and 1,369 cases while the others use 11 items and 1,373. `CFAFitTable()` now prints N and item count per model. |
| F28 | **Fit does not shrink from development to test.** The retained model reaches CFI 0.892 / RMSEA 0.139 in the development half and 0.910 / 0.133 in the test half. A structure defined by three content blocks visible in the raw correlations has little sample-specific detail to overfit. |
| F29 | **The two waves cannot be checked for repeat respondents.** 2018 carries `licenseUID` and `OwnerCustomerUID`; 2025 carries `CustomerID` and `ID`. Zero overlap, no crosswalk, so whether an angler answered both waves is unknown. Repeat respondents would appear in both halves of the split and modestly flatter the replication. Disclosed in Chapter 1, Chapter 9, and Appendix B; not adjusted for. |

## Verification record (2026-09-17, design v2)

| Check | Result |
|---|---|
| Pooled and wave sizes | **PASS.** 3,076 = 1,500 (2018) + 1,576 (2025); asserted in the render |
| Split balance | Development 1,538 (2018: 750, 2025: 788); Test 1,538 (750, 788); complete 1,339 / 1,344 |
| Factorability (development) | KMO 0.760; Bartlett χ²(78) = 5874.4, p < 0.001; determinant 0.0122 |
| EFA fit (development) | k = 2 RMSEA 0.149 / TLI 0.599; k = 3 0.115 / 0.761; k = 4 0.099 / 0.823 |
| Factor correlations (development) | Constraints–Satisfaction −0.41; Satisfaction–Regulation 0.15; Constraints–Regulation 0.03 |
| Reliability (development) | Satisfaction α 0.806 ω 0.807; Constraints α 0.774 ω 0.775; Regulation support α 0.753 ω 0.767 |
| Alpha if dropped | D4a → 0.736 (Constraints); D4e → 0.782 (Regulation support) |
| Reduced-item refit | Largest absolute loading 0.88 at k = 3, 0.90 at k = 4 — no Heywood case |
| CFA on test half (WLSMV, scaled) | 1-factor CFI 0.488 / RMSEA 0.306; 2-factor 0.856 / 0.164; **3-factor 0.910 / 0.133 / SRMR 0.077**; D4a-on-Satisfaction 0.903 / 0.138; freed residual 0.933 / 0.116; 4-factor 0.905 / 0.129 **inadmissible** |
| Development vs test fit | 0.892 / 0.139 vs 0.910 / 0.133 — no shrinkage |
| By-wave fit (test half) | 2018 N = 675, CFI 0.911 / RMSEA 0.139; 2025 N = 698, CFI 0.908 / RMSEA 0.128; all admissible |
| By-wave loading congruence | 1.000 on all three factors |
| Listwise vs pairwise (development) | Median absolute correlation difference 0.007, max 0.029, lowest matched congruence 1.000 |
| Scale scores (pooled) | Satisfaction 3.37 (n = 2,858); Constraints 2.96 (n = 2,823); Regulation support 3.71 (n = 2,862) |
| Renders | **PASS.** `D4ScaleReport.docx` (v2) and `D4ScaleReport_waveDesign.docx` (v1) both render without error |

## Open questions (awaiting user)

| # | Question |
|---|---|
| Q26 | **Sign off the three sub-scales?** If yes, `../PreferredSpecies/` Chapter 2 resumes with 3 sub-scale means by species group plus 2 item-level tables, and that project's D40 is superseded. |
| ~~Q27~~ | **ANSWERED by the held-out test.** `D4a` stays on Constraints, reverse-scored: moving it to Satisfaction worsens fit on every index. |
| ~~Q28~~ | **ANSWERED by the held-out test.** The four-factor catch/harvest split is rejected — inadmissible on fresh data. |
| Q29 | **`D4e` in Regulation support.** Dropping it raises ordinal alpha from 0.753 to 0.782, leaving a two-item scale of D4c + D4d. Keep three items or take the cleaner two? |
| Q30 | **Battery stem wording.** The inherited `GetQuestion()` hardcodes "...during 2018" for every year. Appendix A uses that stem with the year clause removed. What is the exact instrument wording? |
| Q31 | **Formal measurement invariance across waves** is still not tested — Chapter 8 checks that the same model describes both waves and that loadings are congruent, which is weaker. Adding configural/metric/scalar comparisons needs `semTools`. In scope? |
| Q32 | **Adopt the freed `D4h`–`D4m` residual as the reported measurement model?** It is the best-fitting admissible specification and was validated out of sample, but it changes nothing about how the scales are scored. Report it as the model, or keep it as a footnote? |

## Prompt for the next conversation

Restart R first; this session holds the full analysis objects.

```
Resume Chapter 2 of the PreferredSpecies report using the D4 sub-scale structure.

Read f:/Survey/Analysis/D4ScaleAnalysis/AGENTS.md and PROGRESS.md for the recommendation
(three sub-scales: Satisfaction, Constraints with D4a reversed, Regulation support; D4b and
D4g item-level), then f:/Survey/Analysis/PreferredSpecies/AGENTS.md, PROGRESS.md, and
ANALYSIS_PLAN.md for the report it feeds. Do not re-run the psychometric analysis.

Chapter 2 becomes: three weighted sub-scale means by the 17-column banner (matrix table,
transposed per D43), plus item-level percentage tables for D4b and D4g. Sub-scale scores use
the scoring rule in D60 -- mean of items on the 1-5 metric, D4a reversed, scored only when
complete within the scale -- and are weighted with postWeight through base.summary.means()
like every other mean in that report.

Two universe differences to handle: the scales were derived on 2018 and 2025 pooled while
that report is 2025 only, and the psychometric work excluded "no preference" respondents
while that report's banner keeps that column.

Do not modify anything in CrossTabTables/, TrendTables/, BaseFunctions*, Data/, or
D4ScaleAnalysis/. Keep PROGRESS.md and PROMPTS.md current and log this prompt verbatim.
```
