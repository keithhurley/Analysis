# PreferredSpecies Report — Progress & Decisions

Last updated: 2026-09-18

## Status

| Step | Description | Status |
|---|---|---|
| 0 | Map the inherited crosstab/trend methodology | **Done** — recorded in `AGENTS.md` |
| 0b | Write the analysis plan | **Done** — `ANALYSIS_PLAN.md`, approved 2026-09-17 |
| 1 | Determine species groupings (→ Chapter 1) | **Done.** `PreferredSpeciesReport.docx` renders with 23 tables: question text, species sample-size/population table, 17-column banner + exclusions, and per-family descriptive comparisons plus Bonferroni pairwise contrasts. Split decisions made (D31); tests settled (D32). No disposition table needed |
| 2 | Analyze the scale questions about the chosen species (`D4*`) | **Built and rendering (2026-09-18).** All 13 items (`D4a`-`D4m`): table + 3 figures (stacked percent, ordered means, 2018-2025 slope) + 2 interpretive paragraphs each. Item-level, not composite (D63) — the sibling D4 psychometric report's sub-scale recommendation was declined. **The summary-paragraph wordsmithing pass (prompt 52) is done — all 26 paragraphs verified against recomputed data and re-worded; nine unsupported claims corrected (see the closing section of this file). Chapter 2 is complete pending the user's read-through.** |
| 3 | Crosstab all remaining questions by species group | **Handoff written (prompt 56)** — start in a fresh conversation with the prompt at the end of this file. Q7 (question coverage) must be resolved with the user before any code |
| 4 | Select questions for data visualization | Not started. **No chapter of its own (D34)** — figures go inside Chapters 1-3 beside the question each illustrates |
| 5 | Guided text development with the user | Not started |
| 6 | Appendices | **Done.** Appendix A is a blank placeholder for the hand-pasted instrument (D36); Appendix B drafted with 5 inherited + 7 new sections (D38). Appendix B needs a read-through for wording |

## Decisions made

| # | Decision | Date |
|---|---|---|
| D1 | Species grouping starts from the 9 candidate groups (Bass, Moronides, Panfish/Sunfish, Walleye/Sauger, Esocids, Catfish, Trout, Other/Unique, No preference). | 2026-09-17 |
| D2 | **Chapter 1 is a grouping-justification chapter.** Run the multi-species genera both split and combined — the 2 bass, 3 panfish, 2 esocids, 3 catfish — and compare within group using questions that make sense (motivation means, attitude means, total days fished), plus sample sizes, to judge whether any species merits standalone analysis. | 2026-09-17 |
| D3 | Output is **`.rmd` + `officedown::rdocx_document`**, cloned from `2025CrossTabReport.rmd` — not Quarto — to guarantee parity of page breaks, TOC, and flextable styling with the existing reports. | 2026-09-17 |
| D4 | Maintain `AGENTS.md`, `PROGRESS.md`, and `PROMPTS.md`, updating them as work proceeds. | 2026-09-17 |
| D5 | **Full design-based tests throughout Chapter 1.** The user retains final go/no-go on each individual species split — Chapter 1 is a decision packet, not an automatic rule. This is the first inferential statistics in the project and requires a new methodology-appendix paragraph. | 2026-09-17 |
| D6 | **Universe mirrors the crosstabs exactly, per question:** `surveyYear == 2025`, each question keeps the same universe as in the crosstab report; the only added restriction is a non-missing `B1` for banner assignment. Overall column is expected to match the crosstabs. | 2026-09-17 |
| D7 | Banner categories: "I do not prefer any particular type of fish" gets its **own column**; `B1` = "Other" is **dropped**; `B1` = `NA` is **dropped**. Counts of all dropped records are still reported in the Chapter 1 sample-size accounting so nothing is invisible. Scope of the drop (banner-only vs. report-wide) is open — see Q1. | 2026-09-17 |
| D8 | Table layout (transpose vs. landscape vs. A/B split) deferred until the final column count is known at the end of Chapter 1. Leaning transpose. | 2026-09-17 |
| D9 | "Other" and `NA` are dropped **from the banner only** — those respondents remain in the Overall column, so Overall reconciles with the crosstabs report. Species columns therefore will not sum to Overall; footnote it. | 2026-09-17 |
| D10 | Tests use `survey` package objects built on **weights normalized to sum to n** (`w_norm = postWeight * n / sum(postWeight)`), never raw `postWeight` (which would give SEs ~9x too tight). Rao-Scott `svychisq` for categorical, `svyglm` + `regTermTest` Wald F for means, with pairwise contrasts. Agreement with the report's Kish-effN CIs to be verified numerically and any gap reported. | 2026-09-17 |
| D11 | Chapter 1 outcomes: motivation scales (`motivation_natural/pp/social/resource`), attitude scales (`attitude_catch/numbers/size/harvest`), and `C1Total_days` (weighted mean + weighted median). Motivation items do exist for 2025 and appear in the crosstabs analysis; they may need recalculation — must reproduce the crosstab values exactly. | 2026-09-17 |
| D12 | **Bullhead** is both a species-specific split candidate **and** retained within the combined Catfish group (4 ictalurid split candidates: channel, blue, flathead, bullhead). | 2026-09-17 |
| D13 | Multiplicity adjustment is applied **within family**; each family presents its own series of results across the genera. | 2026-09-17 |
| D14 | **Bonferroni** adjustment (user's explicit choice, superseding an initial Holm recommendation), family = one outcome set within one genus (**4 tests**): the 4 motivation scales within a genus, and separately the 4 attitude scales within a genus. `C1Total_days` stands alone, unadjusted. Implementation: `p.adjust(p, method = "bonferroni")`, i.e. every p-value compared to 0.0125. | 2026-09-17 |
| D14a | Methods note for the appendix: Bonferroni and Holm rest on identical assumptions, so Bonferroni is uniformly dominated by Holm on power — anything Bonferroni declares different, Holm also would. Bonferroni was chosen for simplicity of exposition. Because adjustment already biases the chapter toward combining species, this choice biases marginally further toward combining. Tukey HSD was rejected as invalid here (unequal group sizes, weighted design, no design-based studentized range); Benjamini-Hochberg was rejected because FDR control suits screening rather than go/no-go decisions. | 2026-09-17 |
| D15 | Report **all three** magnitude measures next to each p-value: raw weighted mean difference ± 95% CI, Hedges' g, and model R²/eta². For `C1Total_days` also report the median difference, given right skew. Rationale: with small species n, a null result must be distinguishable from an uninformative one. | 2026-09-17 |
| D16 | **No minimum-n threshold.** Chapter 1 reports raw n and Kish effN for every species; each split/combine call is the user's, per D5. (For reference, the only precedent in the project is `minimumPerGroupVar = 20` inside the Likert plotting helper, which is not part of the table pipeline.) | 2026-09-17 |
| D17 | **Flat folder layout**, matching `CrossTabTables/`: `PreferredSpeciesReport.rmd` + `PreferredSpeciesFunctions.R` in the project root, so the cloned relative paths (`../../Data/DataAggregation1/...`, `source("../BaseFunctions_2025_UPDATED.R")`) carry over unchanged. Departs from the global `R/`+`analysis/`+`output/` convention by deliberate choice. | 2026-09-17 |
| D18 | **Bullhead removed** from the Catfish group *and* from the Chapter 1 species analysis (n = 4). Handled like `B1` = "Other" under D7/D9: no banner column, retained in Overall, itemized in the §3.1 accounting. Supersedes D12. Combined Catfish = Channel + Blue + Flathead, n = 228. Split candidates drop from 11 to 10. | 2026-09-17 |
| D19 | **Inherit the `*_AnsweredAll == TRUE` gate** for all scale-score tables, matching `2025CrossTabReport.rmd` L1382. Applied per scale, so each scale carries its own universe (n = 2418-2497 in 2025). Required for the Overall column to match (resolves F4). | 2026-09-17 |
| D20 | **Appendix wording corrected** (resolves F1). The design object keeps normalized weights, but the appendix must state the true reason: `survey` linearization SEs are scale-invariant in the weights, so normalization is a presentational safeguard, not a variance fix. The "~9x too tight" failure belongs only to the manual Σw CI that Kish effN corrects. The old claim must not be repeated. | 2026-09-17 |
| D21 | **Chapter 1 uses higher display precision** than the crosstab report, whose 1-decimal rounding renders every scale-mean CI as `+-0`. Rule: CI to 2 significant figures, estimate to the same decimal place — scale means 3 dp, `C1Total_days` 1 dp / CI 2 dp, percentages 1 dp / CI 2 dp. Rounding change only; no upstream value, function, or report is touched. | 2026-09-17 |
| D23 | **The `B1` filter is the first analytic filter.** `filter(surveyYear == 2025) %>% filter(!is.na(B1))`, 2822 → **1915**. The 907 respondents who left `B1` blank are out of the report entirely, not just out of the banner. Supersedes D6/D9. ⚠️ Breaks the Overall-column match with the crosstabs (Q17); the `B1` distribution itself is unaffected. | 2026-09-17 |
| D24 | **Pairwise contrasts confirmed:** Bonferroni across the **3 contrasts per outcome within a genus**, α = 0.05/3 = **0.0167**. Applies to Panfish and Catfish. The 2-species genera (Bass, Esocids) have a single contrast that is the omnibus test, adjusted in the 4-outcome family at α = 0.0125. Resolves Q14. | 2026-09-17 |
| D25 | **The species sample-size table leads Chapter 1**, immediately after the verbatim `B1` question text. One row per species with: respondents (raw n), effective n (Kish), weighted respondents, % of angler population ±CI, and total anglers (population expansion) ±CI. Subsumes the old standalone `B1` distribution table; the `%` column is the V7-verified output, so the crosstab match is preserved. | 2026-09-17 |
| D26 | **The banner expands conditionally.** It starts as the 8 family groups; where Chapter 1 finds a within-genus difference *and* n suffices, that genus's individual species are added as banner columns **alongside** the retained family column. The Chapter 3 column count is therefore unknown until Chapter 1 is signed off — the reason D8 layout stays deferred. Bullhead never returns. | 2026-09-17 |
| D27 | **`CrossTabTables/CrossTabTableFunctions.R` is sourced read-only** by this report to inherit caption text and table wrappers verbatim instead of duplicating them. Source order: `BaseFunctions_2025_UPDATED.R`, then `CrossTabTableFunctions.R`, then `PreferredSpeciesFunctions.R` (last, so local definitions win). Verified: sourcing has no side effects and does not change the working directory. Nothing upstream is modified. | 2026-09-17 |
| D28 | **The Overall-column divergence from the crosstabs is accepted** (resolves Q17). Overall = "2025 anglers who stated a preference." Disclosed in the Chapter 1 preamble; must also go in the appendix. The `B1` distribution still matches the crosstabs exactly (V7). This narrows the §4 value-matching rule to the `B1` distribution alone. | 2026-09-17 |
| D29 | **Population expansion uses the rescaled basis** (resolves Q18): weighted % × 234,125, so `Total anglers` sums to the full 2025 angler population. Assumes skipping `B1` is unrelated to species preference — untestable with these data, disclosed in the report body and appendix. The within-respondents basis (Σw = 171,760) is not shown. | 2026-09-17 |
| D30 | **Power analysis dropped** from the report and the code (resolves Q20). No minimum-n rule; D16 stands. The user makes split/combine calls subjectively from the §3.4 comparison tables. Figures retained in `ANALYSIS_PLAN.md` §3.7 as a standing caveat only — see F6. | 2026-09-17 |
| D31 | **Final banner: 17 overlapping columns.** Esocids is **split outright** into Northern pike and Muskellunge with no combined column; Bass, Panfish / Sunfish, and Catfish keep their combined column **and** gain one column per species; Walleye, Trout, Moronides, and No preference stay as single columns. Resolves D26. The banner is no longer a partition — counts sum to **2,695** vs. 1,874 distinct (1,874 + 821 duplicated species rows: Bass 357, Panfish 236, Catfish 228), so column counts must never be totalled. *Corrected 2026-09-17: an earlier figure of 2,632 in this log was an arithmetic slip; the report now computes the sum live as `nBannerCellSum` rather than hardcoding it.* Implemented via the `banner.definition` list-column tibble, since a factor cannot express overlapping membership. | 2026-09-17 |
| D32 | **Wald F dropped; Bonferroni-only pairwise tests.** No `svyglm` + `regTermTest()` omnibus. Each test row is a `svyttest()` design-based two-sample comparison with a `Bonferroni p` column (×1 for Bass/Esocids, ×3 for Panfish/Catfish). Consequences: D14's 4-outcome family no longer applies, so multiplicity across the 8 outcomes is unadjusted (F8); `C1Total_days` now takes the contrast adjustment rather than standing alone; model R²/eta² is dropped with the omnibus model. Resolves Q21. | 2026-09-17 |
| D33 | **Table pagination and front matter.** `CreateFlex()` now ends with `paginate(init = TRUE, hdr_ftr = TRUE)`, so every table repeats its header row across page splits and keeps rows with the header (verified: 23 `tblHeader` entries in `document.xml`). Every table is also preceded by its own lead-in paragraph, so no two tables are adjacent — adjacent tables were merging in Word, which is what produced the duplicated/misplaced headers. Page 1 is left blank for a hand-built title page, and the TOC is placed with `block_toc()` under `toc: false` because the YAML route emits the TOC ahead of all body content and would land it on the reserved page. | 2026-09-17 |
| D34 | **There is no visualizations chapter.** Step 4 of the plan produces figures interspersed within Chapters 1-3 beside the questions they illustrate, not collected into a chapter of their own. The former "Chapter 4: Visualizations" heading is removed. | 2026-09-17 |
| D35 | **Appendix A is the survey instrument; the methodology appendix becomes Appendix B.** The instrument is poured in with `block_pour_docx()` from `../../Design/Anglers Survey_v6.docx` — the 2025 instrument, since this report uses 2025 data only. `block_pour_docx()` rejects paths containing spaces, so the report copies the source to a space-free `SurveyInstrument_2025.docx` in the project folder at render time (refreshed only when the source is newer). `Design/` is never modified. | 2026-09-17 |
| D36 | **Appendix A is a blank placeholder — the instrument is pasted in by hand.** The `block_pour_docx()` embed is removed, along with the render-time copy step. This matches `2025CrossTabReport.rmd` L1545-1547, where Appendix A is likewise just a heading between two page breaks. F10 and F11 are consequently moot but retained as a record. `SurveyInstrument_2025.docx` is no longer generated; the copy left on disk is inert and can be deleted. | 2026-09-17 |
| D37 | **`.gitignore` added**, mirroring `CrossTabTables/.gitignore` plus `~$*.docx`, the inert instrument copy, and `PreferredSpeciesReport.docx`. ⚠️ Note the divergence: `CrossTabTables/` **tracks** its rendered `.docx` drafts. If drafts of this report need to be circulated through git, un-ignore the output. | 2026-09-17 |
| D38 | **Appendix B drafted.** The five inherited sections (weighting, percentage CIs, mean CIs, median CIs, reverse-coded daggers) are carried over verbatim from `2025CrossTabReport.rmd` L1549-1610. Seven new sections cover the analysis sample and the two exclusion tiers, the `*_AnsweredAll` gate, population expansions and their assumption, the overlapping banner, the `svyttest` comparisons with the scale-invariance correction and the dropped omnibus, multiplicity including the unadjusted outcome dimension, effect sizes, and display precision. All figures are inline R rather than hardcoded. | 2026-09-17 |
| D39 | **`SurveyInstrument_2025.docx` deleted** at the user's direction. The source, `f:/Survey/Design/Anglers Survey_v6.docx`, is untouched. Nothing in the report references it; `.gitignore` retains the entry so a stray copy cannot be committed. | 2026-09-17 |
| D22 | **No catch-all column anywhere in the banner.** The "Other / Unique" group (Drum, Sturgeon, Common carp, Invasive carp, Paddlefish, n = 33) is dropped from the banner along with `B1` = "Other" and Bullhead; all remain in Overall only. "No preference" **is** retained as a column. Banner = **8 columns, n = 1874**; banner-excluded = **948** (verified: 1874 + 948 = 2822). Supersedes the 9-group list in D1. | 2026-09-17 |
| D40 | **Chapter 2 is item-level, not composite.** `Scales.csv` contains **zero `D4` rows**, so `add_scale_scores()` produces no `D4` composite and no `D4*_AnsweredAll` variable. **D19's listwise gate therefore does not apply to Chapter 2** — the gate exists only for scales defined in `Scales.csv` (`C2`, `E1`, `D1`, `D3`, `Q31`). Whether a composite is defensible is deferred to the standalone D4 report (D46). | 2026-09-17 |
| D41 | **Chapter 2 percent tables: one table per item (option A).** 13 tables, each transposed — rows = Overall + the 17 banner columns in §2.5 order with species indented under their family; columns = the five `labels.agree` categories + N. | 2026-09-17 |
| D42 | **Chapter 2 means: a single matrix table, no medians.** Rows = Overall + 17 banner groups, columns = the 13 `D4` items, cells = mean ±CI at 3 dp (D21). Medians are **dropped** — the crosstab report's D4 section has none, and on a 1-5 Likert the weighted median is an integer for most cells. | 2026-09-17 |
| D43 | **Transposed layout across the whole report; landscape where needed (resolves Q23).** Species/family in rows, responses in columns, in Chapter 2 and Chapter 3 alike. | 2026-09-17 |
| D44 | **`B2*` and `B3*` go in Chapter 3, in crosstab-report question order.** Chapter 2 stays a clean `D4` battery. | 2026-09-17 |
| D45 | **Chapter 2 Overall row** covers the chapter's universe and sits at the top of every table; the "No preference" row is retained. ⚠️ Amended by F13 — that row is **not** structurally empty. | 2026-09-17 |
| D46 | **Chapter 2 is paused** pending a new standalone report, `f:/Survey/Analysis/D4ScaleAnalysis/`, doing a ground-up psychometric analysis of the `D4` battery (correlations, factorability, EFA, loadings, consistency, CFA) and recommending whether a sub-scale construct exists. Chapter 2 resumes once that recommendation lands, since it decides D40's item-level-versus-composite question. That project keeps its own `AGENTS.md`, `PROGRESS.md`, `PROMPTS.md`, and `ANALYSIS_PLAN.md`. | 2026-09-17 |

## Open questions (awaiting user)

| # | Question |
|---|---|
| Q7 | **Question coverage for step 3** — every question in the crosstab report, in the same order, or a subset? (Deferred with layout, D8.) |
| Q22 | **Outcome-dimension multiplicity** (F8) — leave unadjusted, or Bonferroni over all contrasts within a family? Flagged, not implemented. |
| ~~Q23~~ | **RESOLVED → D43.** Transposed layout everywhere, landscape where needed. |
| Q24 | **Appendix A heading year.** Currently "Appendix A - Nebraska Licensed Angler Survey (Paper Version)", with no year. `2025CrossTabReport.rmd` L1545 calls it the *2026* survey and cites Hurley 2026, while our data is `surveyYear == 2025` and `Data/` holds a "Fishing Nebraska 2025-2026 Methodology Report". Which year belongs in the heading? |
| Q25 | **Appendix B read-through.** The inherited "roughly 9x too tight" passage (correct for the manual Σw CI) sits a few paragraphs from the new statement that this does *not* apply to `svydesign`. Both are accurate but could read as contradictory on a skim. Reword, or leave? |

### Resolved 2026-09-17

| # | Question | Resolution |
|---|---|---|
| Q9 | Step 1 execution | V1-V7 run, all pass |
| Q10 | F1 — appendix wording | Corrected → D20 |
| Q11 | F2 — display precision | Raised for Chapter 1 → D21 |
| Q12 | F3 — Bullhead | Removed from group and analysis → D18 |
| Q13 | F4 — `*_AnsweredAll` gate | Inherited, added to plan → D19 |
| Q15 | Bullhead destination | Banner-drop, Overall only → D18 |
| Q16 | "Other / Unique" group | Dropped from banner; "No preference" retained → D22 |
| Q14 | Pairwise contrast adjustment | 3 contrasts per outcome per genus, α = 0.0167 → D24 |
| Q17 | Overall vs. crosstabs | Divergence accepted → D28 |
| Q18 | Population-expansion basis | Rescaled to all anglers → D29 |
| Q19 | Redundant size-table columns | Keep all; all were requested |
| Q20 | Minimum-n rule | Power analysis dropped, no threshold → D30 |
| Q21 | Are the §3.5 tests still wanted? | Yes — pairwise Bonferroni only, Wald F dropped → D32 |

## Findings, round 2

| # | Finding |
|---|---|
| F6 | **Chapter 1's comparisons are underpowered, and this survives the removal of the power tables (D30).** No within-genus contrast can resolve g = 0.5 at 80% power; best case g ≈ 0.59 (Channel vs. Flathead), worst g ≈ 1.40 (Northern pike vs. Muskellunge). Practical effect on how §3.4 must be read: **overlapping CIs are weak evidence of similarity, not strong evidence.** Clearest illustration in the rendered draft — Muskellunge mean days fished 63.8 ± 50.49 (n = 8), median 3.0/22.7/138.0. |
| F7 | **`PreferredSpeciesFunctions.R` is auto-reformatted on write** in this workspace, so exact-string edits against a remembered version fail. Re-read the file or rewrite it whole when editing. |
| F8 | **Multiplicity across outcomes is now unadjusted (consequence of D32).** Bonferroni is applied only across the contrasts within a single outcome. Each family is tested on 8 scale outcomes plus days fished, so a family with 3 species now carries 27 comparisons with no adjustment across the outcome dimension. Under the old plan D14 covered that dimension via the omnibus family at α = 0.0125. If outcome-level control is wanted, the natural fix is Bonferroni over all contrasts within a family (×24 for Panfish/Catfish, ×8 for Bass/Esocids) — flagged, not implemented. |
| F10 | **`block_pour_docx()` rejects file paths containing spaces.** The instrument lives at `Design/Anglers Survey_v6.docx`. Handled by copying to a space-free `SurveyInstrument_2025.docx` in the project folder at render time; the source in `Design/` is untouched. The copy is a generated artifact and should be gitignored. |
| F11 | **Poured content is an altChunk — it only materializes when the .docx is opened in Word.** Verified: `document.xml` holds an `altChunk` reference and the package contains `word/SurveyInstrument_2025.docx` (665,886 bytes, byte-identical to source), but `officer::docx_summary()` reports 0 tables after the Appendix A heading. LibreOffice and docx parsers will show nothing there. Consequence: the instrument's page count is unknown until opened, and **the TOC must be refreshed in Word** (right-click → Update Field) before it lists anything from Appendix A. |
| F9 | **`svyttest()` returns an `htest` with no `coef()` / `confint()` methods.** Calling them returns `numeric(0)`, which silently collapses a `tibble()` row to zero rows rather than erroring — the failure mode looks like "the table is empty" with no message. Use `tt$estimate` / `tt$conf.int`. Caught during implementation; fixed. |
| F12 | **`D4` is not strictly gated on `B1` in the delivered data. 582 respondents answered at least one `D4` item but left `B1` blank** (2025: 1,567 answered both; 348 answered `B1` only; 582 answered `D4` only; 325 answered neither). Consequence for Chapter 2: under D23 those 582 are out of the report entirely, so the Chapter 2 Overall column rests on ~1,567 respondents where the crosstab report's D4 tables rest on ~2,045-2,127. This is a larger divergence than the one measured in D28 and is specific to `D4`. Nothing upstream changed; reported, not fixed. |
| F13 | **The "No preference" column is not structurally empty. 50 of the 339 "No preference" respondents answered at least one `D4` item.** The handoff note asserting a hard survey gate is approximately but not exactly right — 85% did skip the battery. The footnote must say the battery was *routed away from* these respondents and that the 50 who answered anyway are retained/reported, rather than claiming the cell is empty by design. Amends D45. |
| F14 | **The `D4` battery has 13 items, not 12.** `D4e` ("If I could catch larger fish, I would be willing to harvest fewer of my preferred fish.") is present in the codebook for both 2018 and 2025 and has 2,098 non-missing 2025 responses. An earlier note in this conversation claiming `D4e` was absent from the 2025 codebook was wrong — it came from an `awk` parse that broke on a quoted field containing a comma. `read.csv` is authoritative. Item letters run a-m with **no gaps**. |
| F15 | **`GetQuestion()` hardcodes the `D4` stem.** `BaseFunctions_2025_UPDATED.R` L575 special-cases `C2`, `E1`, `D14`, `D3`, and `D4`, returning a fixed battery stem via `switch()` rather than reading the codebook. So the legacy 2002 `D4` row ("What time of day do you usually fish for catfish?") cannot contaminate the Chapter 2 caption, and there is no bare `D4` column in `d` for `contains("D4")` to sweep in. |

## Verification checks V1-V7 — RUN 2026-09-17, all PASS

Run against `aggregateData_20260624.rData`, `BaseFunctions_2025_UPDATED.R`, and the rendered
`../CrossTabTables/2025_Angler_Survey_Crosstabs_Final.docx` (read with `officer::docx_summary`).
2025 file: **n = 2822** rows.

| # | Check | Result |
|---|---|---|
| V1 | `gtype`/`gtype2` survive into `d` | **PASS.** Both present. `gtype` == the plan's §2.1 grouping exactly (Bass, Moronides, Sunfish, Walleye-Sauger, Esocids, Catfish, Trout, Uniques, Anything). `gtype` puts **Yellow perch in Sunfish**; `gtype2` breaks Yellow perch out as its own level. `B1` = "Other" maps to `gtype` = `NA`. |
| V2 | 2025 `B1` frequencies | **PASS.** Non-missing `B1` = **1915**; `NA` = **907**; "Other" = **4**; **Sturgeon = 0** respondents. Kish effN for the `B1` table = **1525.4** on raw n = 1915. |
| V3 | `C2` motivation items exist for 2025 | **PASS.** All 16 `Motivations` items (C2a,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q) and all 16 `Attitudes` E1 items present, ~2480-2610 non-missing each. Not historical-only. |
| V4 | `add_scale_scores()` reproduces crosstab values | **PASS, 8/8 exact.** All four `motivation_*` and all four `attitude_*` Overall cells match the rendered docx string-for-string. |
| V5 | Collapsed group % = sum of component % | **PASS.** Max abs difference 1.8e-15 (floating point); n differences exactly 0 across all 10 collapsed groups. |
| V6 | Design-based CIs vs. Kish-effN CIs | **PASS with caveats** — see "Findings" below. Means agree to 4 dp, CI ratio 0.98-1.03. Percentages: point estimates identical; CI ratio 0.94-1.02 for cells with n > 80, widening to 0.82-1.27 for cells with n < 15. |
| V7 | Overall column matches crosstab report | **PASS, 23/23 exact** on the `B1` "Preferred Fish" table, formatted cell string identical. |

### Verified 2025 `B1` distribution (weighted %, ±95% CI, raw n)

| Response | % | ±CI | n | | Response | % | ±CI | n |
|---|---|---|---|---|---|---|---|---|
| Walleye / Sauger | 23.8 | 2.1 | 499 | | Blue catfish | 1.7 | 0.6 | 27 |
| Largemouth bass | 18.1 | 1.9 | 316 | | Paddlefish | 1.1 | 0.5 | 14 |
| No preference | 17.9 | 1.9 | 339 | | Striped bass | 0.7 | 0.4 | 11 |
| Crappie | 8.3 | 1.4 | 181 | | Muskellunge / Tiger musky | 0.6 | 0.4 | 8 |
| Channel catfish | 7.0 | 1.3 | 151 | | Yellow perch | 0.5 | 0.3 | 12 |
| Trout | 4.6 | 1.1 | 90 | | Common carp | 0.4 | 0.3 | 9 |
| Flathead catfish | 2.7 | 0.8 | 50 | | Drum | 0.4 | 0.3 | 6 |
| Smallmouth bass | 2.6 | 0.8 | 41 | | Invasive carp | 0.4 | 0.3 | 4 |
| Wiper | 2.5 | 0.8 | 35 | | Other *(banner-excluded)* | 0.3 | 0.3 | 4 |
| White bass | 2.2 | 0.7 | 39 | | Bullhead | 0.2 | 0.2 | 4 |
| Bluegill / Sunfish | 2.0 | 0.7 | 43 | | Sturgeon | 0.0 | 0.0 | 0 |
| Northern pike | 2.0 | 0.7 | 32 | | | | | |

### V5 record — collapsed group sizes as tested (the pre-D18/D22 9-group list)

Kept as the verification record. Catfish here still includes Bullhead (n = 232).

| Group | % | n | Group | % | n |
|---|---|---|---|---|---|
| Walleye / Sauger | 23.8 | 499 | Trout | 4.6 | 90 |
| Bass | 20.7 | 357 | Esocids | 2.6 | 40 |
| No preference | 17.9 | 339 | Other / Unique | 2.4 | 33 |
| Catfish | 11.6 | 232 | Other *(excluded)* | 0.3 | 4 |
| Panfish / Sunfish | 10.8 | 236 | | | |
| Moronides | 5.4 | 85 | | | |

### FINAL banner — 8 columns (D18 + D22, verified in R 2026-09-17)

| Banner column | n | | Retained in Overall only | n |
|---|---|---|---|---|
| Walleye / Sauger | 499 | | `B1` missing | 907 |
| Bass | 357 | | Paddlefish | 14 |
| No preference | 339 | | Common carp | 9 |
| Panfish / Sunfish | 236 | | Drum | 6 |
| Catfish *(Channel+Blue+Flathead)* | 228 | | Bullhead | 4 |
| Trout | 90 | | Other | 4 |
| Moronides | 85 | | Invasive carp | 4 |
| Esocids | 40 | | Sturgeon | 0 |
| **Banner total** | **1874** | | **Total** | **948** |

Reconciliation verified: 1874 + 948 = 2822 = full 2025 file. Of the 1915 respondents with
non-missing `B1`, 1874 get a banner column and 41 do not.

## Findings — all resolved 2026-09-17

F1 → D20 (appendix wording corrected) · F2 → D21 (higher precision in Chapter 1) ·
F3 → D18 (Bullhead removed) · F4 → D19 (`*_AnsweredAll` gate inherited) · F5 → no action needed.
Original text retained below for the record.


| # | Finding |
|---|---|
| F1 | **D10's stated rationale is wrong, though its instruction is harmless.** For `svydesign(ids = ~1, ...)`, the linearized SE of `svymean`/`svyglm` is **scale-invariant in the weights**: raw `postWeight` and normalized `w_norm` give *identical* SEs (verified to 5 dp on both a mean and a 23-level proportion), and `degf()` = 1914 either way. The "~9x too tight" failure mode is real **only** for the manual Σw-based CI that Appendix B corrects with Kish effN — it does not apply to the `survey` package. Normalizing changes nothing, so D10's procedure can stand, but the **appendix wording must be corrected** or it will state something false. |
| F2 | **Scale-mean CIs round to `0.0` at the crosstab report's display precision.** Every `motivation_*`/`attitude_*` Overall cell renders as e.g. `3.3+-0 (2469)`; the true CI is ~±0.037. Chapter 1 compares species means against each other, so it needs **more decimals** (suggest mean to 2 dp, CI to 3 dp). This is a display change local to this report and does not alter any upstream value. |
| F3 | **Sturgeon has 0 respondents in 2025** and **Bullhead has 4** (effN smaller still). Per D16 there is no minimum-n rule, but the Bullhead split candidate will produce an uninformative test. Confirm Bullhead stays a split candidate. |
| F4 | **Crosstab scale means filter on `*_AnsweredAll == TRUE`** (`2025CrossTabReport.rmd` L1382). This gate is not yet written into `ANALYSIS_PLAN.md` §3.3 but must be inherited for Chapter 1 or the Overall column will not match. |
| F5 | **Yellow perch:** `gtype` = Sunfish (matches the plan), `gtype2` = standalone. Both encodings already exist upstream, so the plan's placement is consistent with `gtype`. No conflict; noting for the record. |

## Discrepancies found vs. the crosstabs report

**No unintended discrepancies.** Every value checked at verification time (V4, V5, V7)
reproduced the rendered crosstab report exactly, and nothing upstream has been modified.

**One deliberate divergence, by decision:** under D23 the report universe excludes the 907
respondents who left `B1` blank, so the Overall column estimates "anglers who stated a
preference" rather than "all licensed anglers" and does **not** match the crosstabs (D28
accepted this). Measured: `Resi` −1.39 pp, `attitude_harvest` 2.26 → 2.19, other scale means
shift 0.003–0.019. The `B1` distribution still matches 23/23. Do not report this as a bug.

---

## Prompt for the next conversation (D4 scale analysis) — USE THIS ONE

Chapter 2 is paused (D46). The next conversation builds the standalone D4 psychometric report.
**Before starting: reload the Positron window (or open the workspace at
`f:/Survey/Analysis/D4ScaleAnalysis`) so the assistant can write there.** The folder exists and
holds only a copied `.gitignore`; the assistant was blocked from writing to it because the
workspace root was `PreferredSpecies` and a mid-conversation folder add does not register.

Everything below is already decided — do not re-litigate it.

| Item | Decision |
|---|---|
| Deliverable | `D4ScaleReport.rmd` + `D4ScaleFunctions.R` in `f:/Survey/Analysis/D4ScaleAnalysis/`, flat layout, `officedown::rdocx_document` → Word |
| Battery | **13 items**, `D4a`-`D4m`, no gaps; `D4e` is real and present in both waves |
| 2025 universe | `surveyYear == 2025`, `!is.na(B1)`, `B1 != "I do not prefer any particular type of fish"` → **n = 1,576**; listwise complete on all 13 = **1,365** |
| 2018 universe (CFA) | same rule → **n = 1,500**; listwise complete = **1,318** |
| Correlations | **Polychoric, unweighted**, throughout. No `postWeight` anywhere in this report |
| Missing data | **Listwise primary, pairwise sensitivity**; report the full missingness table and profile who is dropped |
| Sections | All eight: distributions, correlations, factorability (KMO/Bartlett/determinant), retention (parallel/MAP/scree/VSS), EFA (oblique, k-1/k/k+1), reliability (ordinal alpha, congeneric omega, item-rest, alpha-if-dropped), CFA on 2018, recommendation |
| Extraction | minres with oblimin; report loadings for the retained solution plus one either side |
| CFA | `lavaan`, `ordered = items`, WLSMV; compare the EFA-derived model against 1-factor and alternatives |
| Voice | Explanations, discussion, and a recommendation **are** wanted here (unlike the crosstab reports), but no causal language and no calling a model "good" — report fit statistics against their conventional cutoffs |
| Seed | 4827 |
| Packages | `psych` 2.6.3, `GPArotation`, `lavaan` 0.6.21, `corrplot` are installed. `polycor`, `semTools`, `ggcorrplot` are **not**, and are not needed |

Verified facts, do not re-derive: items are factors with levels Strongly Disagree → Strongly
Agree, so `as.numeric()` gives 1-5 matching the upstream convention; there is no bare `D4`
column, and `GetQuestion()` hardcodes the `D4` stem (F15); 2025 item missingness is 18.8-21.3%
within `B1` responders, evenly spread.

```
Build the D4 scale analysis report in f:/Survey/Analysis/D4ScaleAnalysis/.

Read ../PreferredSpecies/PROGRESS.md section "Prompt for the next conversation (D4 scale
analysis)" first — it carries every settled decision, the verified sample sizes, and the
findings F12-F15. Do not re-derive them and do not re-run the sizing checks.

Create AGENTS.md, ANALYSIS_PLAN.md, PROGRESS.md, D4ScaleFunctions.R, and D4ScaleReport.rmd in
that folder, then render to Word. PROMPTS.md still needs creating too; copy the prompt log
entries from ../PreferredSpecies/PROMPTS.md prompts 33-35 plus this one.

Do not modify anything in ../CrossTabTables/, ../TrendTables/, ../BaseFunctions_2025_UPDATED.R,
../../Data/, or ../PreferredSpecies/ beyond appending to its PROGRESS.md and PROMPTS.md.

Verify the code runs before telling me it works.
```

## D46 follow-up — the D4 scale report is built (appended 2026-09-17)

The sibling project commissioned by D46 is complete and rendering:
`f:/Survey/Analysis/D4ScaleAnalysis/` holds `AGENTS.md`, `ANALYSIS_PLAN.md`, `PROGRESS.md`,
`PROMPTS.md`, `D4ScaleFunctions.R`, `D4ScaleReport.rmd`, and the rendered
`D4ScaleReport.docx`. Its decisions are numbered D47-D62 and its findings F16-F24, continuing
these series. **Nothing in this project was changed** apart from this section and prompt 36
in `PROMPTS.md`.

**Design note (updated 2026-09-17).** That project was rebuilt at the user's direction. The
first version ran the EFA on 2025 and the CFA on 2018; the current version **pools both
waves (n = 3,076) and splits them 50/50 at random, stratified by wave**, deriving everything
on a development half and testing once on a held-out half. The wave dimension is retained as
a check: the retained model is fitted separately within each wave of the test half. The v1
report is archived and still renders (`D4ScaleReport_waveDesign.rmd`).

**Its answer to D40's item-level-versus-composite question:** the battery supports **three
correlated sub-scales**, not one composite and not 13 unrelated items.

| Sub-scale | Items | Ordinal alpha | Congeneric omega |
|---|---|---|---|
| Satisfaction | D4i, D4j, D4k, D4l | 0.806 | 0.807 |
| Constraints | D4a *(reversed)*, D4f, D4h, D4m | 0.774 | 0.775 |
| Regulation support | D4c, D4d, D4e | 0.753 | 0.767 |

`D4b` and `D4g` load on nothing and stay item-level. Scoring: mean of the scale's items on
the 1-5 metric, `D4a` as 6 minus the response, scored only when the respondent is complete
within that scale — the same `*_AnsweredAll` convention D19 inherits for the other scales.
The composition is identical under both designs; only the reliability coefficients shifted
slightly with the sample.

Qualifications that travel with the recommendation: no confirmatory model reached the
conventional RMSEA cutoff (best admissible 0.116; misfit concentrates in the `D4h`/`D4m`
content overlap); `D4a`'s placement is data-driven and contradicts its face content, though
the held-out test does prefer it; and the scales were derived on both waves pooled while
this report is 2025 only. Two questions the held-out design settled that the earlier one
could not: the four-factor alternative is **inadmissible** on fresh data, and moving `D4a`
to Satisfaction makes fit worse.

**Chapter 2 remains paused** until the user signs off — Q26-Q31 in the sibling project's
`PROGRESS.md`. If signed off, Chapter 2 becomes three weighted sub-scale means across the
17-column banner plus two item-level tables, and **D40 is superseded**. Note the universe
difference to handle at that point: the psychometric work excluded the "no preference"
respondents entirely, while this report's banner keeps that column.

## Prompt for the next conversation (Chapter 2) — SUPERSEDED, see D46

Paste this to start fresh. Restart R first — the session that built Chapter 1 still holds stale
objects from removed code (`MinDetectableG`, `RequiredSizeTable`, `caption.power`, a `res`
try-error), and they will mask the current definitions.

```
Start Chapter 2 of the PreferredSpecies report — step 2, the species-linked scale questions.

First read AGENTS.md, PROGRESS.md, and ANALYSIS_PLAN.md in f:/Survey/Analysis/PreferredSpecies.
They carry the standing directive, the inherited methodology, decisions D1-D39, findings F1-F11,
and the executable spec. Do not re-derive any of it and do not re-run the V1-V7 checks; they
passed. Chapter 1 and both appendices are finished and rendering — do not change them. Do not
modify anything in CrossTabTables/, TrendTables/, BaseFunctions*, or Data/DataAggregation1/.

Chapter 2 covers the D4 battery ("Thinking about the one type of fish that you prefer to fish
for..."), Likert 1-5 on labels.agree, reported across the 17-column banner defined in
ANALYSIS_PLAN sections 2.1 and 2.5. Mirror the crosstab report's "Preferred Species Questions"
section (2025CrossTabReport.rmd L761-804) for item coverage and caption wording.

Before writing any code, answer these for me:
1. Does Scales.csv define a D4 sub-scale, and so should this be item-level, composite, or both?
2. How should 17 banner columns be laid out? Q23 is open and blocks Chapter 2 and Chapter 3
   both. Give me the options with their tradeoffs.
3. Do B2* (species sought) and B3* (harvest/release) belong in Chapter 2 or Chapter 3?
4. Does the D4 universe differ from the crosstab report's in any way beyond the B1 filter (D23)?

Three things already settled that are easy to get wrong: D4 is gated on preferring a species, so
the "No preference" column is structurally empty — footnote it as a survey gate, not as
missingness. Scale scores need the *_AnsweredAll listwise gate per scale (D19). Banner columns
overlap and must never be totalled (D31).

Technician voice: give me the numbers, no interpretation and no significance language. Keep
PROGRESS.md and PROMPTS.md updated as you go, and log this prompt verbatim in PROMPTS.md.
```

---

## Chapter 2 resumed — 2026-09-18

The D4 psychometric report (D46) is finished and the user has **declined its sub-scale
recommendation**. Chapter 2 is unpaused and item-level, so D40 stands and the three-factor
structure from `../D4ScaleAnalysis/` plays no part in this report.

| # | Decision | Date |
|---|---|---|
| D63 | **Chapter 2 is pure item-level in questionnaire order.** `D4a`–`D4m`, no composites and no reference to the sub-scale structure. Supersedes the conditional in the D46 follow-up note. | 2026-09-18 |
| D64 | **One table per item, one caption per item — 13 tables.** Supersedes D41 (13 percent tables) and D42 (a single means matrix): percents and means are combined, so each item is self-contained. Rows = Overall then all 17 banner columns with species indented; columns = the five `labels.agree` categories as `% ±CI`, then `Mean ±CI`, then N. 8 columns, portrait, no landscape and no family/species split needed — which is what dissolved the width problem the user raised. | 2026-09-18 |
| D65 | **Medians and figures stay out of Chapter 2.** Medians dropped per D42's reasoning (integer-valued on a 1-5 Likert, absent from the crosstab report's D4 section). Figures deferred to step 4. | 2026-09-18 |
| D66 | **No dagger and no reverse-scoring on `D4a`.** Nothing in Chapter 2 is composited, so there is nothing to reverse; the codebook's `Reversed` flag is `FALSE` for the `D4` items in any case. Note this differs from `../D4ScaleAnalysis/`, which reverses `D4a` for its Constraints scale. | 2026-09-18 |
| D67 | **No missingness table.** Per-cell N only (each row carries the raw count answering that item). | 2026-09-18 |
| D68 | **"No preference" is treated as a discrete species choice**, not as a routed-away artefact. The row stays in every Chapter 2 table and reports the 50 respondents who answered the battery anyway (F13). `caption.d4gate` states the routing without claiming the cell is empty. | 2026-09-18 |
| D69 | **Per-item non-missing filter inherited.** Each table applies `filter(!is.na(item))` within each row group, exactly as `2025CrossTabReport.rmd` L768 does. No listwise gate — there is no `D4*_AnsweredAll` variable (D40). | 2026-09-18 |

### New code (2026-09-18)

Appended to `PreferredSpeciesFunctions.R`:

| Object | Role |
|---|---|
| `caption.d4item` | Cell-content caption for the per-item tables |
| `caption.d4gate` | The F13-compliant routing note for the "No preference" row |
| `d4.items` | `paste0("D4", letters[1:13])` |
| `ItemQuestionText(item, codebook)` | Item wording from `q$Question` keyed by `q$Field` |
| `D4ItemTable(mydata, item, categories)` | The per-item table; loops `banner.definition`, computes each row on its own subset |

`PreferredSpeciesReport.rmd`: new `d4Setup` chunk with `stopifnot` on 13 items / 5 categories,
the Chapter 2 preamble disclosing F12, and the `D4a` section. `nD4AnyAll2025` / `nD4AnyNoB1` are
captured in `getData` **before** the `B1` filter so the F12 divergence is quoted from live
figures.

### Findings

| # | Finding |
|---|---|
| F25 | **Item text is in `q$Question`, not `q$Field`.** The codebook stores the item wording in the `Question` column and the variable name (`D4a`…`D4m`) in `Field`; there is no row whose `Question` equals `"D4a"`. `GetQuestion(q, D4, 2025)` returns only the battery stem (F15), so per-item captions need `ItemQuestionText()`. |
| F26 | **`Number` from `base.summary.percent.selectOne()` is per response category.** The respondent count for a group is `sum(pct$Number)`, which matches `base.summary.means()`'s `Number` exactly (verified: `D4a` Overall 1,555 both ways). |
| F27 | **`\uXXXX` escapes are illegal inside backticked names in R.** `rename(\`Mean \u00b1 CI\` = Mean)` is a parse error, not a runtime one, so it kills the whole `source()`. Assign through `names(op)[...] <-` instead. |
| F28 | **`officer::docx_summary()` in the installed flextable/officer build emits one row per table cell with `doc_index` incrementing per cell**, so counting distinct `doc_index` values does not count tables. Verify table counts from `word/document.xml` instead — `grep -c tblHeader` is reliable (24 after adding `D4a`); note `grep '<w:tbl>'` returns 0 because the element carries attributes. |

### Verification — D4a prototype (run 2026-09-18, all pass)

| Check | Result |
|---|---|
| Table shape | 18 rows (Overall + 17 banner columns) × 8 columns |
| Overall N | 1,555 = `sum(!is.na(d$D4a))` |
| Bass row N | 341 = direct count of largemouth + smallmouth answering `D4a` (banner Bass is 357, so 16 did not answer the item) |
| "No preference" row | N = 50, matching F13 |
| Render | `PreferredSpeciesReport.docx` rebuilt clean; 24 tables; the `D4a` header row appears once |

### Status

| Step | State |
|---|---|
| 2 — Chapter 2 | **In progress.** `D4a` built, rendered, and awaiting the user's approval of the format. `D4b`–`D4m` are held until then |

### Chapter 2 built out — 2026-09-18

| # | Decision | Date |
|---|---|---|
| D70 | **The 13 item sections are written out explicitly, not looped.** One `## D4x` heading, one italic item-text paragraph, one caption, one chunk per item. A `results='asis'` loop would have collapsed the lead-in paragraphs that D33 requires between tables and complicated `paginate()`. Verbose but matches the crosstab report's structure. | 2026-09-18 |
| D71 | **Zero-percent cells keep the `0.0 ± 0.00` form** for now. Flagged to the user as a possible dash/blank substitution; not changed without instruction. | 2026-09-18 |

**Verification — full Chapter 2 (run 2026-09-18, all pass).** All 13 tables are 18 rows x 8
columns; every Overall N equals a direct `sum(!is.na(d[[item]]))`; every item's wording resolves
from the codebook rather than falling back to the field name; no row group returned empty.

| Item | Overall N | No preference N |
|---|---|---|
| D4a | 1,555 | 50 |
| D4b | 1,507 | 50 |
| D4c | 1,541 | 49 |
| D4d | 1,533 | 49 |
| D4e | 1,533 | 48 |
| D4f | 1,528 | 49 |
| D4g | 1,534 | 49 |
| D4h | 1,519 | 48 |
| D4i | 1,533 | 48 |
| D4j | 1,524 | 49 |
| D4k | 1,533 | 49 |
| D4l | 1,525 | 49 |
| D4m | 1,524 | 48 |

Rendered `PreferredSpeciesReport.docx` in 33 s: **36 tables** (23 Chapter 1 + 13 Chapter 2),
13 `Mean ± CI` header rows, and headings `D4a`-`D4m` all present.

| Step | State |
|---|---|
| 2 — Chapter 2 | **Done pending read-through.** All 13 item tables built, verified, and rendering. Next open items: Chapter 3 (step 3), figures (step 4), guided text (step 5) |

### Chapter 2 figures — D4a prototype (2026-09-18)

| # | Decision | Date |
|---|---|---|
| D72 | **Two figures per D4 item, placed immediately after that item's table.** (1) Horizontal 100% stacked bar: rows = table order (Overall + 17 banner columns, species indented), fill = response category, viridis discrete, `position_stack(reverse = TRUE)` so Strongly Disagree sits leftmost. (2) Vertical bar + 95% CI error bar: banner columns only (no Overall), ordered highest mean to lowest, single flat viridis fill (no fill mapping — the group is already on the x-axis, so mapping it to fill too would dual-encode). Both axis labels carry the row's own item-level N, e.g. "Muskellunge / Tiger musky (n=8)". | 2026-09-18 |

**Implementation notes / findings:**

| # | Finding |
|---|---|
| F29 | **`geom_col()`'s default stack order is reversed on a horizontal bar.** With `aes(x = value, y = group, fill = response)`, the last factor level draws leftmost, not the first — opposite of the table's left-to-right response order. Fixed with `geom_col(position = position_stack(reverse = TRUE))`. |
| F30 | **`scale_y_continuous(limits = c(1,5))` silently deletes `geom_col` bars whose baseline (0) falls outside the limits**, leaving only the error bars on the plot with a `Removed N rows` warning — not an error, easy to miss. Fixed with `coord_cartesian(ylim = c(1,5))`, which clips the view instead of dropping the geom. | 2026-09-18 |

New code in `PreferredSpeciesFunctions.R`: `D4RowSpec()`, `D4PercentLong()`, `D4MeansLong()`,
`D4PercentStackPlot()`, `D4MeansOrderedPlot()`. `library(ggplot2)` added to the file's header.
`PreferredSpeciesReport.rmd`: two chunks added after the `D4a` table only (`d4aPercentPlot`,
`d4aMeansPlot`, each with explicit `fig.width`/`fig.height`); `D4b`-`D4m` untouched pending
approval.

**Verification:** render succeeds in ~31s; `word/media/` gained exactly 2 PNGs; table count
unchanged at 36 (`tblHeader` count); both figures' underlying data reconciled against
`D4ItemTable(d, "D4a", ...)` before plotting (Overall N 1,555, No preference N 50, per-species
means matching the table to 3 dp).

**Status:** D4a figures built and rendered; D4b-D4m figures held pending the user's review of
format, stacking order, and label style.

### Chapter 2 figures, round 2 — items 1-8 (2026-09-18)

| # | Decision | Date |
|---|---|---|
| D73 | **Eight figure-format fixes applied to `D4PercentStackPlot()`/`D4MeansOrderedPlot()`, verified on `D4a`:** (1) legend forced to one row (smaller legend text/key, no `guide_legend(nrow=2)`, chunk width raised to 7.5in to match the report's page-width default); (4) both plots take a `titleText` argument, wired to `ItemQuestionText(item, q)`, wrapped at 100 chars; (5) fill palette is `viridis(5)` with Neutral replaced by `grey80`, the other four levels unchanged (`D4FillColors()`); (6) means plot y-axis title changed to "Mean response (1 = Strongly Disagree ... 5 = Strongly Agree)" — corrected "Strong" to "Strongly" for consistency with the "Strongly Agree" endpoint, flagged to the user; (7) stacked-plot axis text left-justified (`hjust = 0`), which was the actual fix — the indentation was already being generated, right-justification was hiding it; (8) the lead-in caption paragraphs before each figure are removed, since the title now carries that role. Items 2 and 3 required no code change (user confirmed current behavior is correct). | 2026-09-18 |

**Verification:** re-rendered; `word/media/` still holds exactly 2 PNGs, `tblHeader` count
unchanged at 36. Confirmed against a dimension-matched `ggsave()` test that the wrapped means
y-axis title does not clip at the chunk's actual 7.5x5in size (it clipped only in the console
preview's smaller default device).

**Caught mid-session:** an unrelated console command reloaded the raw, all-year `aggregateData`
into the session's `d`, silently overwriting the report-scoped 1,915-row universe. The first
retest of the updated stacked plot showed Overall N = 4,552 and bars summing past 100% before
this was caught and `d` was rebuilt from the `getData` chunk's exact steps. Not a code defect —
a console-state hazard worth flagging for future interactive testing sessions.

### Item 9 — 2018 slope figure and per-item summary (2026-09-18)

**Housekeeping note:** items 1, 4, 5, 6, 7, and 8 of prompt 46 were already implemented earlier
in this session and logged as D73 (see above). This entry covers only item 9, which was left as
untested console prototypes (`D4SlopeData`, `d2018`, `sd_d4a`) — not yet in `PreferredSpeciesFunctions.R`,
not yet in the `.rmd`, not yet logged, not yet shown to the user. That prototype's `D4SlopeData`
silently embedded a CI-overlap suppression rule (comment-labeled "D75") that was never disclosed
or approved. It has been superseded by an explicit, disclosed decision below.

| # | Decision | Date |
|---|---|---|
| D74 | **2018 data is pulled into this report for the first time**, via a `d2018` snapshot taken in `getData` before `d` is filtered to 2025: `d %>% filter(surveyYear == 2018, !is.na(B1))` (n = 1,792). This is a scope expansion beyond D6/D23 ("2025 data only"), made solely to support the Chapter 2 slope figure — Chapters 1 and 3 remain 2025-only. `TrendTableFunctions.R` was read (read-only, no changes) to confirm the convention: 2018's `postWeight` is a real, year-specific weight (sum ≈ 1,860, mean ≈ 1.0), on a different scale than 2025's population-raked weight (sum ≈ 171,760, mean ≈ 90), but this does not affect weighted means or their Kish-effN CIs, both scale-invariant to the weight's overall magnitude (same fact already established for `svydesign` in D20; here it applies to the manual Kish-effN calculation directly). Verified: every banner species string used in `banner.definition$Members` and the `D4a`-`D4m` factor levels are identical between the 2018 and 2025 codebooks — no relabeling risk. | 2026-09-18 |
| D75 | **The slope figure shows a group only when its 2018 and 2025 95% confidence intervals do not overlap** — the user's explicit, disclosed choice (superseding the undisclosed prototype rule of the same effect). Scope is Overall + all 17 banner rows (unlike the means-ordered figure, which excludes Overall). No error bars are drawn; the CI already did its filtering work. A `plot.caption` on every slope figure states the rule. ⚠️ **Re-verified 2026-09-18 after the D80 bugfix, which changes this count.** Before the fix, Overall could never qualify (it was silently excluded from every slope figure regardless of this rule — see D80), so the count below is the corrected one. Across the 13 items, **6 rows across 5 items** now qualify: `D4b` Blue catfish; `D4f` **Overall**; `D4g` Moronides; `D4l` Moronides; `D4m` Flathead catfish **and Overall**. The other 8 items — `D4a`, `D4c`, `D4d`, `D4e`, `D4h`, `D4i`, `D4j`, `D4k` — show zero qualifying rows and render a placeholder message instead of an empty chart. | 2026-09-18 |
| D76 | **"No preference" is excluded from the slope comparison only**, not from the item tables or the other two figures. Finding: in 2018, 224 of 292 "No preference" respondents (77%) answered `D4a`; in 2025 only 50 of 339 (15%) did, indicating the battery was routed to that group much more strictly in 2025. A 2018-2025 comparison on that row would partly reflect the routing change rather than a change in attitude. Disclosed to the user before building; this exclusion is implemented inside `D4SlopeData()` so no caller can forget it. | 2026-09-18 |
| D77 | **A one-time, explicit exception to the report's no-interpretation rule**, scoped to a short closing paragraph after each item's slope figure. The user's own words: "this represents a one-time exception from the no-interpretation rule." Applies only to this paragraph in Chapter 2 — the rest of the report (tables, other captions, Chapters 1 and 3) keeps the technician voice unchanged. The user's own global style rule against "significant/meaningful/causal" language is still honored within this exception; the paragraph reports concrete numbers (range of banner means, widest CI, slope-figure outcome, No-preference response count) without evaluative language. Format is a short prose paragraph, not a table or bulleted callout — drafted for `D4a`, pending the user's read before it is replicated for `D4b`-`D4m`. | 2026-09-18 |

**New code:** `D4SlopeData()`, `caption.d4slope`, `D4SlopePlot()` in `PreferredSpeciesFunctions.R`;
`D4MeansLong()` gained an `includeOverall` parameter (default `FALSE`, preserving the means-figure
behavior) so the slope figure could reuse it with Overall included. All three plot title calls'
`str_wrap()` width dropped from 100 to 60 after `D4b`'s 90-character title visibly overflowed the
plot at width 100 (`D4g` at 103 characters, the longest item, wraps to two lines cleanly at 60).
`PreferredSpeciesReport.rmd`: `getData` gained the `d2018` snapshot; `dataChecks` gained a
stopifnot block verifying cross-year label and factor-level identity; `D4a` gained the slope chunk
and the summary paragraph.

**Verification:** render succeeds in ~34s; images in `word/media/` for `D4a` now number 3 (stack,
means, slope); table count unchanged at 36; the cross-year `stopifnot` checks pass (zero banner
species missing from `d2018$B1`, identical `D4a` factor levels both years). Both slope-plot code
paths tested directly: `D4a` (0 qualifying rows) renders the placeholder message; `D4b` (1
qualifying row, Blue catfish) renders a labeled line without truncation.

**Status:** `D4a` now carries all three figures plus the summary paragraph. `D4b`-`D4m` held
pending the user's review of the slope figure and the summary paragraph's tone/format.

### Eight D4a refinements (2026-09-18)

| # | Decision | Date |
|---|---|---|
| D78 | **Eight fixes to the `D4a` prototype, applied ahead of finishing `D4b`-`D4m`.** (1) `D4ItemTable`'s Mean column moved from `FmtMean` (3 dp/3 dp) to a new `FmtMeanD4` (1 dp/2 dp) — `FmtMean` itself is untouched, since Chapter 1's scale-mean tables deliberately keep 3 dp (D21) for species-vs-species contrasts; (2) all three figure chunks' `fig.width` dropped from 7.5in to 6.5in, matching the Word document's actual printable width (Letter, 1in margins) — the report had been rendering wider than the page; (3) both the means-ordered and slope figures' y-axis title shortened to "Mean response," with the 1-5 scale key moved into a `plot.subtitle` at 7pt italic (`d4.scale.key`, shared by both); (4)-(5) the no-qualifying-groups placeholder and the slope caption now use the user's exact wording, with no mention of the No-preference exclusion in either (that reasoning stays in D76, out of the figure) and both wrapped via `str_wrap()` so they can't overflow the panel; (6) the closing paragraph is longer and openly interpretive — differences in means and percent agree/disagree across preferred groups and between years, with plain-language readings of what they may indicate — and drops the CI-width and routing/sample-size commentary that the earlier draft (D77) had leaned on; (7) each item's `##` heading is now the item's own text (`` `r ItemQuestionText(...)` ``) instead of its field code, and the now-redundant italic paragraph beneath it is removed; (8) "banner group"/"banner columns" reworded to "preferred groups" throughout Chapter 2's own text (the Chapter 2 preamble and the two D75 strings) — Chapter 1's established "banner" terminology (D31 and its captions) is untouched, since this feedback was scoped to Chapter 2 and renaming Chapter 1 would be an unrequested scope change; flagged for the user's awareness. | 2026-09-18 |
| D79 | **The one-time interpretation exception (D77) is broadened**, per explicit instruction: no CI-width commentary, no routing/sample-size framing, longer and more interpretive, actively describing what the largest mean/percentage differences across preferred groups and across years may indicate. The user's own global style rule against causal language is still honored (no claims of proof or causation; hedged with "may point to," "suggests"), but comparative/evaluative language ("considerably more satisfied," "the largest contrast") is now in bounds for this one paragraph, per the user's request. Still scoped to this closing paragraph only — the rest of Chapter 2 (tables, captions) stays in technician voice. | 2026-09-18 |

**Rendering incident (unrelated to content):** `rmarkdown::render()` failed twice with a
misleading Lua-filter error (`pagebreak.lua:28: attempt to call a nil value (global
'pandocAvailable')`). Root cause, confirmed by direct testing: `PreferredSpeciesReport.docx` was
open elsewhere (Word or a preview pane) and locked for writing; pandoc's error reporting surfaced
an unrelated Lua-filter message instead of a plain permission error on at least one attempt.
Worked around by knitting with `run_pandoc = FALSE`, converting the resulting `.knit.md` to a
side file (`PreferredSpeciesReport_new.docx`) with a direct `pandoc` call, verifying its content,
then moving it over the original once the user confirmed the file was closed. The normal
`rmarkdown::render()` pipeline was re-confirmed working immediately afterward — nothing about the
render setup itself needed a permanent fix. Flagged here in case the same symptom recurs: check
for a file lock before suspecting the Lua filter or pandoc installation.

**Verification:** table Mean column confirmed at 1 dp/2 dp (e.g. `3.2 ± 0.06`); all three figures
confirmed at the new width via direct plot calls; slope placeholder and caption text confirmed
exact and non-overflowing after adding `str_wrap()` to the placeholder (the caption already fit
in one line); heading confirmed showing item text; render succeeds end-to-end (36 tables, 3
images for `D4a`).

**Status:** `D4a` now reflects all eight fixes. `D4b`-`D4m` held pending the user's read of the
rewritten, more interpretive closing paragraph and the other seven changes.

### Chapter 2 completed — D4b-D4m built; two bugs found and fixed (2026-09-18)

| # | Decision | Date |
|---|---|---|
| D80 | **Bug found and fixed: `D4MeansLong(..., includeOverall = TRUE)` never actually included Overall.** Its filter was `mydata %>% filter(as.character(B1) %in% Members)` unconditionally; for the Overall row `Members` is `NULL`, and `x %in% NULL` is always `FALSE`, so the Overall row silently returned zero rows and was dropped by the existing `nrow(sub) == 0` guard — with no error, no warning. Consequence: every `D4SlopePlot()` call since D75/D76 was built has been missing Overall as a candidate row, contrary to the user's explicit instruction ("include all groups (genus/species/overall)"). Fixed to match `D4PercentLong`'s existing `if (!is.null(Members))` guard. **Re-verified against the already-approved `D4a`: unaffected** (Overall still doesn't qualify there). Two items gain an Overall line that didn't exist before the fix: `D4f` and `D4m`, both items where the whole survey population's mean moved enough between years to clear the non-overlap threshold on its own. | 2026-09-18 |
| D81 | **"Preferred group(s)" replaces "banner group(s)"/"the banner" report-wide**, per explicit instruction (supersedes the Chapter-2-only scoping in D78). Changed: the Chapter 1 "Preferred Groups" heading and its three lead-in paragraphs, the Appendix B "The preferred groups, and why columns do not sum" heading and its two paragraphs, the exclusion-accounting paragraph, `caption.banner`, and two table column headers rendered in Chapter 1 — `BannerSizeTable()`'s `` `Banner column` `` and `BannerExclusionTable()`'s `` `Excluded from banner` `` are now `` `Preferred group` `` and `` `Excluded from preferred groups` ``. Internal R identifiers are unchanged (`banner.definition`, `AssignBannerGroup()`, `nBanner`, `B1banner`, code comments, etc.) — those are developer-facing and renaming them would be a large, risk-bearing refactor for no reader-visible benefit. Verified zero occurrences of "banner" anywhere in the rendered document's visible text. | 2026-09-18 |
| D82 | **Percent-plot x-axis: the "Percent" axis title is dropped; tick labels carry a "%" suffix instead** (`scale_x_continuous(labels = function(x) paste0(x, "%"))`). | 2026-09-18 |
| D83 | **Chapter 2 completed: `D4b`-`D4m` built to the same template as the approved `D4a`** — item-text heading, table (1 dp/2 dp means), stacked percent plot, means-ordered plot, slope plot, two interpretive paragraphs. All 12 paragraphs are grounded in computed statistics (top/bottom preferred-group means, percent agree/disagree, within-family spreads, largest 2018-2025 movements) gathered before writing, not fabricated. Two items' second paragraph notes a rare Overall-level shift (`D4f`, `D4m`) rather than only a single-group one — a direct, correct consequence of the D80 fix. | 2026-09-18 |

**Verification:** full render succeeds (~55s); document holds exactly 36 tables (23 Chapter 1 +
13 Chapter 2, unchanged) and 39 images (13 items x 3, up from 3); 13 `Mean ± CI` table headers;
zero literal `D4a`-`D4m` field-code headings remain (all replaced by item text, per D78's
extension); zero "banner" occurrences anywhere in the rendered document.

**Status:** Chapter 2 is functionally complete (13 items, each with a table and three figures).
Remaining Chapter 2 work is a user read-through of `D4b`-`D4m`'s new interpretive paragraphs,
mirroring the review `D4a` already received. Step 3 (Chapter 3 crosstabs) and step 5 (further
guided text) remain open.

### D75/D76 re-verification after the D80 bugfix (2026-09-18)

Requested re-check, run against the current (fixed) `D4MeansLong()`:

| Check | Result |
|---|---|
| Qualifying-row count, all 13 items | **6 rows across 5 items** (was wrongly logged as 4 rows/4 items before the fix) — corrected directly in the D75 entry above rather than left stale |
| `D4f` | Gains **Overall** as its only qualifying row (2018 mean 3.191 → 2025 mean 3.334); previously 0 qualifying rows |
| `D4m` | Gains **Overall** (2018 mean 2.932 → 2025 mean 3.065) alongside its pre-existing Flathead catfish row; now 2 qualifying rows, was 1 |
| `D4b`, `D4g`, `D4l` | Unchanged — Overall does not qualify for these; same single non-Overall row as before |
| `D4a` (already shown to and approved by the user) | **Unaffected** — still 0 qualifying rows, placeholder message unchanged |
| `D76`'s "No preference" exclusion | Unaffected by D80 — that exclusion is a `RawLabel != "No preference"` filter inside `D4SlopeData()`, independent of the Members/NULL bug |
| Rendered document | `PreferredSpeciesReport.docx` (mtime 11:50, after both the D80 fix and the `D4b`-`D4m` build) already reflects the corrected 6-row/5-item result — **no re-render needed**, only the `PROGRESS.md` log text was stale |
| Visual spot-check | `D4f` and `D4m` slope figures regenerated directly: both show the expected line(s) with correct end-labels and no visual collision between the two lines in `D4m` |

No further code change required — this was a documentation correction, not a code fix (the code fix was D80). `D75`'s table above is now the authoritative count.

---

## Handoff decision (2026-09-18)

| # | Decision | Date |
|---|---|---|
| D84 | **The Chapter 2 summary-paragraph wordsmithing pass moves to a new conversation**, at the user's direction, using a different model ("fable"). Scope is narrow and explicit: re-evaluate, confirm, add to, and wordsmith the two closing paragraphs per item (`D4a`-`D4m`) only. Nothing else in the report is in scope for that pass — not the tables, not the three figures per item, not their captions, not Chapter 1, not the appendices. The next conversation should read this file's handoff prompt below rather than re-deriving context. | 2026-09-18 |

## Prompt for the next conversation (Chapter 2 summary wordsmithing) — EXECUTED as prompt 52, see the closing section below

Paste this to start the new conversation. **Restart R first** — this session accumulated dozens
of stale intermediate objects from verification work (`cmp`, `cmpl`, `sd_d4a`, `overlapSurvey`,
`overlapSurvey2`, `qualSurvey`, `m18`, `m25`, and similar), and a fresh session avoids any
confusion between those and anything the new conversation computes.

```
Continue the PreferredSpecies report. Read AGENTS.md, PROGRESS.md, and PROMPTS.md in
f:/Survey/Analysis/PreferredSpecies first -- they carry the standing directive, the inherited
methodology, decisions D1-D84, and findings F1-F30. Do not re-derive any of it and do not re-run
past verification checks (V1-V7, D75/D76's re-check); they passed.

Chapters 1 and 2 are built and rendering (36 tables, 39 images). Do not touch Chapter 1, the
appendices, or anything in Chapter 2 except the task below.

Task: for each of the 13 D4 items (D4a-D4m) in Chapter 2 of PreferredSpeciesReport.rmd,
re-evaluate, confirm, add to, and wordsmith the two closing summary paragraphs. Each item's
paragraphs are the last two `` `r paste0(...)` `` inline-R blocks before the next `##` heading,
immediately following that item's three figure chunks (`d4xPercentPlot`/`d4xMeansPlot`/
`d4xSlopePlot`). Headings show the item's own text, not its D4-letter code (D78) -- use
ItemQuestionText("D4a", q) etc. to match a heading back to its item if needed.

Ground rules, already settled -- do not re-litigate:
- This is the ONE authorized exception to the report's technician-voice, no-interpretation
  rule (D77, D79), and it is scoped ONLY to these paragraphs. Do not extend interpretive
  language to any table, caption, or heading elsewhere in the report.
- Every factual claim (a mean, a percentage, a year-over-year change, a "highest"/"lowest"
  group) must be verified against the actual data before it goes in the text -- recompute with
  D4PercentLong(d, item, d4.categories), D4MeansLong(d, item, includeOverall = TRUE/FALSE), and
  D4SlopeData(d, d2018, item) exactly as the current paragraphs were written. Never fabricate or
  round-guess a number.
- Keep the user's persistent global style rule in force even inside this exception: no
  "significant", "meaningful", or causal claims. Hedge with "may indicate"/"suggests", not
  certainty.
- No routing, sample-size, or CI-width commentary in these paragraphs (D79) -- percentages are
  fine without n; raw n counts are not.
- D4MeansLong(..., includeOverall = TRUE) was bugged until today (D80) and is now fixed --
  Overall is a valid candidate in cross-year comparisons for every item, not just D4f and D4m.

Render and verify after editing (table count 36, image count 39 should not change), and keep
PROGRESS.md and PROMPTS.md updated as you go, logging this prompt verbatim in PROMPTS.md.
```

## Chapter 2 summary wordsmithing pass — completed (2026-09-18, prompt 52)

All 26 closing paragraphs (13 items x 2) were re-verified against freshly recomputed
`D4PercentLong()` / `D4MeansLong(includeOverall = TRUE)` / `D4SlopeData()` output (dump kept in
`verify_d4.txt`, a scratch file safe to delete). Most claims held; nine did not and were
corrected:

| Item | Problem found | Fix |
|---|---|---|
| D4a ¶1 | "largest contrast among preferred groups" — the Trout (3.59) vs Yellow perch (2.38) gap is larger than the cited Walleye-vs-Trout gap | Scoped to "among the larger preferred groups" |
| D4b ¶1 | Trout named "alongside" pike/musky as disagreeing most — Flathead (51%) and Yellow perch (50%) both disagree more than Trout (46%) | Rewritten: pike/musky lowest means (2.4), Flathead/Yellow perch next-highest disagreement |
| D4g ¶1 | Largemouth called "leaning toward harvest" — its mean is 2.73, leaning toward size; and the LM-SM gap (0.33) called "one of the largest within-family splits" — it is not | Rewritten: both bass species lean toward size, Smallmouth (2.4) more sharply |
| D4g ¶2 | Moronides 2025 (2.65) called "roughly neutral" — it leans toward size | "from leaning toward harvest opportunity (3.2) to leaning toward size (2.6)" |
| D4h ¶1 | "meaningfully" (banned word); "among the only groups where agreement outweighs disagreement" — Moronides, Trout, and N. pike also qualify | Rewritten without the word; extremes stated by mean, Yellow perch's 0% disagreement noted |
| D4j ¶1 | Marginal claim stated flatly — pike disagreement leads agreement by only 40% vs 38% | "edges out", with both percentages shown |
| D4k ¶1 | "only catfish group where disagreement clearly outweighs agreement" — Blue catfish also has disagreement (37%) over agreement (27%) | Rewritten: Flathead has the item's highest disagreement (50%); Blue also leans toward dissatisfaction |
| D4l ¶1 | Musky "shared dissatisfaction" — musky is 0% disagree / 84% neutral; its low mean comes from neutrality | Rewritten: pike genuinely dissatisfied (~30% disagree), musky overwhelmingly neutral |
| D4m ¶1, ¶2 | Two battery-wide superlatives falsified elsewhere: strongest agreement anywhere (D4d musky: 100% agree, mean 4.87) and largest movement anywhere (D4b Blue catfish +1.07 > Flathead's +0.81) | Both scoped to "on this item"; the D4b comparison acknowledged explicitly |

The remaining paragraphs were confirmed and extended with verified figures (2018/2025 means for
cited movements, Walleye/Sauger's 56% agreement on D4f, Trout's rise on D4e/D4f/D4h, unanimity of
Muskellunge agreement on D4d, within-family size-satisfaction spread on D4i, Moronides/Yellow
perch rises on D4b, Bluegill/Blue catfish rises on D4d). Every parenthetical 1-dp mean whose
underlying value sat near a .x5 boundary was pinned by direct recomputation before citing
(D4c pike 4.0, D4g Walleye 3.2 / Moronides 2.6, D4l pike 3.1 / musky 3.2, D4m Yellow perch 3.5);
where 1-dp rounding stayed ambiguous (D4j pike 2.95) the text uses a change magnitude ("about
half a point") instead of a level.

Scope held to D77/D79: interpretive language only in these paragraphs; no
significant/meaningful/causal wording; no routing, raw-n, or CI-width commentary; hedges
("may point to", "suggests", "appear to") retained.

**Verification:** full render succeeds; 36 tables and 39 images, both unchanged; no chunk,
figure, caption, heading, or table was touched — only the 26 inline-R paragraph strings.

**Status:** Chapter 2 done pending user read-through. Next open steps: 3 (crosstabs by species),
5 (guided text). Token-saving note: start Chapter 3 in a fresh conversation off this file.

## Cross-year commentary restricted to slope-plot groups (2026-09-18, prompts 54-55)

| # | Decision | Date |
|---|---|---|
| D85 | **A group's 2018-2025 change may be discussed in an item's summary paragraphs only if that group appears in the item's slope figure** (i.e., its 2018 and 2025 95% CIs do not overlap, per D75). Consequence: the 8 items with no qualifying rows (`D4a`, `D4c`, `D4d`, `D4e`, `D4h`, `D4i`, `D4j`, `D4k`) carry no group-level change commentary at all — their second paragraph opens with a one-sentence statement that no group qualified, then pivots to a new, verified 2025-only perspective. The 5 items with qualifying rows keep change commentary for those rows only: `D4b` Blue catfish; `D4f` Overall; `D4g` Moronides; `D4l` Moronides; `D4m` Flathead catfish + Overall (the `D4m` reference to Blue catfish's `D4b` shift is retained since that shift is itself plot-qualified). | 2026-09-18 |

New 2025-only perspectives added (each verified against the recomputed `verify` list before writing):
`D4a` No-preference group's above-average satisfaction and largest neutral share; `D4c` support
firmness (≥3:1 supporters-to-opponents in every group but Yellow perch; zero neutral Muskellunge
responses); `D4d` numbers-vs-size regulation comparison across items (pike the main exception);
`D4e` internal consistency with the `D4g` harvest-versus-size item; `D4h` rank alignment with the
`D4m` water-availability item; `D4i` polarized pike vs. heavily neutral Blue catfish/Trout; `D4j`
allowed-size vs. caught-size comparison with Moronides the one clear exception; `D4k` ranking
mirror of the `D4a` overall-success item.

**Verification:** render succeeds (after clearing a Word file lock, same symptom as the D78
incident); 36 tables and 39 images, both unchanged; all 13 rewritten second paragraphs confirmed
present in the rendered `document.xml`. `verify_d4.txt` deleted at the user's direction (prompt 53).

## Prompt for the next conversation (Chapter 3 crosstabs) — USE THIS ONE

**Restart R first** — the current session carries stale wordsmithing objects (`verify`, `cites`,
`out`, `results`, `it`, `item`) that a fresh session avoids. Then paste:

```
Continue the PreferredSpecies report -- Chapter 3 (crosstabs by preferred group). Read AGENTS.md,
PROGRESS.md, and PROMPTS.md in f:/Survey/Analysis/PreferredSpecies first -- they carry the
standing directive, the inherited methodology, decisions D1-D85, and findings F1-F30. Do not
re-derive any of it and do not re-run past verification checks; they passed.

State of the report: Chapters 1 and 2 are complete and rendering (36 tables, 39 images). Do not
touch them or the appendices.

Task: plan, then build, Chapter 3 -- the remaining survey questions crosstabbed by the 17
preferred-group rows (banner.definition, Overall row first), following Chapter 2's transposed
table pattern (D43; landscape where a question's response set is too wide). Plan before code:
first resolve open question Q7 with me (full crosstab-report question coverage in the same order,
or a subset), then confirm the per-question-type table formats (selectOne %, selectAll %,
means/medians for numerics, scale scores with their *_AnsweredAll gates per D19), display
precision, and which questions warrant interspersed figures (D34) -- no code or file writes until
I give the go-ahead.

Ground rules, already settled -- do not re-litigate:
- Technician voice throughout Chapter 3. The D77/D79 interpretation exception was scoped to
  Chapter 2's closing paragraphs only and does not extend here.
- Reuse base.summary.* and the D4ItemTable/D4RowSpec looping pattern over banner.definition
  unmodified; never edit anything upstream (CrossTabTables/, BaseFunctions*, Data/).
- The 17 preferred-group rows overlap (D31) -- never total them. Keep the D33 lead-in paragraph
  before every table. Displayed N is always raw, unweighted.
- B2*/B3* belong in Chapter 3 in crosstab-report question order (D44); D13* is gated on B2rbt.
- Universe stays surveyYear == 2025 with !is.na(B1), n = 1,915 (D23); each question keeps its own
  non-missing filter as in the crosstab report.

Render and verify after each build increment (table/image counts against the 36-table/39-image
baseline plus what Chapter 3 adds), and keep PROGRESS.md and PROMPTS.md updated as you go,
logging every prompt verbatim in PROMPTS.md.
```

## Chapter 3 built — 2026-09-18 (prompts 57-58)

Q7 is resolved. The user supplied the coverage list explicitly and answered the five design
questions in prompt 58.

| # | Decision | Date |
|---|---|---|
| D86 | **Chapter 3 coverage is the user's explicit 21-section list**, in 2025 Crosstabs report order: A11, A12, A10, tournaments, A4, A5, A6, Q11, A17 access, A7, A8, A9, Q16, E7, Q18 guides, C1 total days, Q26 ice (yes/no only), C2 motivations, Q31 regulations, E1 attitudes, E2 gender, E3 age. **`B2*`, `B3*`, and `D13*` are excluded outright** at the user's direction — this supersedes D44, which had placed `B2`/`B3` in this chapter. Also absent, because they were not requested: A1 permit type, A2/A3 did-you-fish, Q23 low water, the month-by-month `C1` tables, and the `Q27`-`Q29` ice-fishing detail. | 2026-09-18 |
| D87 | **The tournament count distribution table is dropped** (user's option (i)). Transposed it would need one column per integer count. The section keeps two tables: the derived `fishedTourney` percentage, and the weighted mean of `A13_corrected` among anglers with at least one tournament, matching the crosstab report's first and third tables. | 2026-09-18 |
| D88 | **Battery tables are grouped by `Scales.csv` sub-scale.** C2 (17 items) -> 4 sub-scale tables of 4 plus one table for the unassigned item (`C2b`); Q31 (12) -> 3 sub-scale tables of 3/3/5 plus `Q31c`; E1 (16) -> 4 tables of 4, nothing unassigned. Scale scores then get their own tables with the `*_AnsweredAll` gates (D19): motivations in two tables mirroring the crosstab report (pp/natural/social/resource, then noncatch/catch), regulations one, attitudes one. Transposing the full batteries was impossible — 17, 12, and 16 item columns. | 2026-09-18 |
| D89 | **Gender and age are weighted here**, unlike the 2025 Crosstabs report, which forces `postWeight = 1` for `E2` and `E3`. The user's explicit call. Each of the two captions states the divergence so a reader comparing the reports is not surprised. Adds a second, smaller item to the D28 list of accepted differences from the crosstabs. | 2026-09-18 |
| D90 | **Two sample-size conventions coexist.** Single-question tables keep Chapter 2's single `N` column, since every response column shares one denominator. Battery, scale-score, median, and indicator tables put the count inside each cell after the interval — `3.4 +- 0.06 (1,704)` — because each column carries its own universe (per-item missingness, an `*_AnsweredAll` gate, or a different subset). The per-cell form is the inherited `ArrangeTableA` convention. | 2026-09-18 |
| D91 | **Chapter 3 figures are held** until the user has reviewed the tables (step 4 stays open). | 2026-09-18 |
| D92 | **Landscape is implemented with `block_section()` brackets** — `sect_portrait()` before a wide run and `sect_landscape()` after it, defined in the `ch3Setup` chunk, since officedown applies a section's properties to the content *preceding* the break. Seven landscape sections: A5 methods, A6 techniques, A17 access, the A7 and A8 band tables, the two guided-trip tables, and the Q31 Uniform Preference table. Everything else is portrait. | 2026-09-18 |
| D93 | **Chapter 3 display precision.** Percentages 1 dp with a 2 dp interval (`FmtPct`); means 1 dp / 2 dp (`FmtMeanD4`, extended to `FmtMeanN`); day medians 1 dp; distance medians 0 dp, since `A7_miles`/`A8_miles` are band midpoints. | 2026-09-18 |

### New code

`PreferredSpeciesFunctions.R` gained a Chapter 3 block: captions (`caption.ch3selectone`,
`caption.ch3selectall`, `caption.ch3means`, `caption.ch3medians`, `caption.ch3indicator`,
`caption.ch3rows`), formatters (`FmtMeanN`, `FmtMedianN`), label helpers (`Ch3ItemLabel`,
`SubScaleFields`, `UnassignedFields`), and six table builders — `Ch3SelectOneTable`,
`Ch3SelectAllTable`, `Ch3MeansTable`, `Ch3MediansTable`, `Ch3IndicatorTable`,
`Ch3MeansSpecTable`. All of them loop `D4RowSpec(includeOverall = TRUE)` unmodified, so the row
set and indentation are identical to Chapter 2's and cannot drift. Nothing upstream was touched.

`PreferredSpeciesReport.rmd` gained the `ch3Setup` chunk (layout helpers, field sets, the
`Scales.csv` read as `s`, the relabeled `dTourney`, and a `stopifnot` on battery sizes) and 21
sections holding 40 tables.

### Findings

| # | Finding |
|---|---|
| F31 | **The codebook's reversal flags for `Q31` belong to a scale this report does not use.** `q$Reversed` marks `Q31a/b/d/f/i`, but `Scales.csv` assigns those reversals to `reg_orientation` (ScaleName `RegulationsBipolar`); the three reported sub-scales — comprehension, site support, uniform — contain no reverse-coded item, and `ReversedItemsNote("Regulations")` correctly returns an empty string. Daggering column headers from the codebook would therefore have marked five items misleadingly. `Ch3ItemLabel()` now takes the reversed set explicitly, keyed to the scale being displayed; verified 0 daggers across the Q31 tables and 4 across the E1 tables (`E1a`, `E1k`, `E1f`, `E1l`). |
| F32 | **Six of the twelve `A4` fields carry no 2025 data** (`A4priv`, `A4OWl`, `A4park`, `A4pits`, `A4pub`, `A4OWr`, all 0 non-missing). They drop out of the percentage calculation on their own, exactly as they do in the crosstab report, leaving six waterbody columns. `A5` and `A6` have eight live fields each, which is what forced those two tables into landscape. |
| F33 | **The tournament and guided-trip tables are thin once split 18 ways.** Only 49 respondents fished a tournament, 49 hired a guide in Nebraska, and 128 hired one outside it. In the tournament mean table 5 of 18 rows are empty; in the guided-trip means table 31 of 108 cells are empty. The cells that remain often rest on single-digit counts, which the per-cell N makes visible. Flagged for the user — no suppression rule was applied (D16 stands). |
| F34 | **Large `cat >> file << EOF` heredocs silently truncate in this workspace's bash.** A ~230-line append to `PreferredSpeciesFunctions.R` was cut mid-function with only a warning; the file had to be truncated back and rebuilt in ~80-line pieces. Append in small blocks and check `wc -l` after each. |

### Verification — Chapter 3 (run 2026-09-18, all pass)

| Check | Result |
|---|---|
| Render | Succeeds end to end; **76 tables** (36 baseline + 40 Chapter 3), **39 images** (unchanged, no figures added), 7 landscape sections |
| Table accounting | 8 (increment 1) + 13 (increment 2) + 19 (increment 3) = 40, matching the section-by-section plan |
| Row shape | Every builder returns 18 rows — Overall plus the 17 preferred groups, species indented |
| `A11` Overall N | 1,884 = `sum(!is.na(d$A11))` |
| `A11` Bass row N | 352 = direct count of largemouth + smallmouth answering `A11` |
| `A11` Overall percent | 44.1% Yes = direct weighted proportion (44.13) |
| `A4` Overall N | 1,858 = `sum(d$A4_Answered == TRUE)`, the select-all denominator |
| Days fished Overall mean | 30.2 = `weighted.mean(C1Total_days, postWeight)` on the gated universe (30.205) |
| Dagger placement | 0 across the Q31 tables, 4 across the E1 tables (F31) |

### Status

| Step | State |
|---|---|
| 3 — Chapter 3 | **Built and rendering.** 21 sections, 40 tables. Awaiting the user's read-through, especially the seven landscape pages and the sparse tournament/guide tables (F33) |
| 4 — figures | Open; deliberately held until the tables are reviewed (D91) |
| 5 — guided text | Not started |

### Gender/age caption amendment (2026-09-18, prompt 59)

| # | Decision | Date |
|---|---|---|
| D94 | **The gender and age captions no longer mention the crosstabs report.** D89's substance is unchanged — both questions remain weighted here while the 2025 Crosstabs report presents them unweighted — but the captions now state only "Percentages are weighted, as they are throughout this report." The divergence stays documented in D89 and in this file rather than in the report body. | 2026-09-18 |

### Raw OOXML at the start of Chapter 3 — fixed (2026-09-18, prompt 60)

| # | Finding |
|---|---|
| F35 | **An orphan ```` ``` ```` fence on line 639, left over from the Chapter 2 wordsmithing pass, opened a verbatim block that swallowed the start of Chapter 3.** Everything from the chapter heading to the first table was passed through as literal text: the `# Chapter 3` heading rendered with its hash instead of as Heading 1 (so it was also missing from the table of contents), the HTML comment rendered as visible `<!-- ... -->`, and the first flextable's entire OOXML rendered as a wall of text — what the user saw on page 71. The fence was inert while Chapter 3 was only comments, which is why it survived the Chapter 2 verification passes. `block_section()` was **not** the cause; an isolated test confirmed inline `` `r block_section(...)` `` emits a proper `w:sectPr` and no escaped markup. Fixed by deleting the single stray line; opener and closer fence counts now balance at 122 each. This is the only edit made to the Chapter 2 region and it touched no content. |

**Verification after the fix:** render succeeds; **0** leaked-markup text runs (a scan for `w:tblPr`, `w:sectPr`, `w:pgSz`, or an escaped HTML comment inside any `w:t` element), 76 tables, 39 images, 7 landscape sections, and the Chapter 3 heading now carries the `Titre1` style with a TOC bookmark.

### Chapter 3 review fixes, round 1 (2026-09-18, prompts 61-62)

| # | Decision | Date |
|---|---|---|
| D95 | **Waterbody types (A4) moves to landscape.** The portrait break now sits before the section heading, so A4 shares a landscape run with Methods; Techniques keeps its own. Landscape section count is unchanged at 7. | 2026-09-18 |
| D96 | **The motivation "items outside the four sub-scales" section is removed** (`C2b`, the lone unassigned item). Chapter 3 table count drops from 40 to 39 and the document from 76 to 75. `UnassignedFields()` stays in `PreferredSpeciesFunctions.R` and is still used by the Regulations battery. ⚠️ Open: the analogous Regulations section holding `Q31c` (3.19.4) was **not** removed — the instruction named only the motivation one. Asked; awaiting the user. | 2026-09-18 |
| D97 | **The sentence "Each column carries its own universe, so counts differ across a row." is dropped from `caption.ch3means`.** The per-cell N still appears in every such table; only the explanatory sentence is gone. | 2026-09-18 |
| D98 | **D33's no-adjacent-tables rule extended to sub-headings.** The two motivation scale-score tables in 3.18.6 sat back to back under one heading, and Word merged them — the second table carried the first's header across the page break, the same failure D33 diagnosed. A lead-in paragraph now separates them. A scan of the whole chapter confirmed no other pair of table chunks is adjacent; the sub-scale tables were already separated by their own `###` headings. | 2026-09-18 |

**Verification (run 2026-09-18 after the render):** 75 tables, 39 images, 7 landscape sections, 0
leaked-markup text runs. The removed caption sentence and the `C2b` heading are both absent from
the rendered document; the new lead-in paragraph is present; the Regulations `Q31c` heading is
still present as expected. Section orientation confirmed positionally from `document.xml`:
Waterbody Types, Methods, Techniques, and Uniform Preference resolve to landscape, Crowding to
portrait.

**Render note:** the first attempt failed with `pandoc document conversion failed with error 1`
because `~$eferredSpeciesReport.docx` was present — the document was open in Word. Same symptom as
the D78 incident; checking for the lock file is the fastest diagnosis.

| # | Decision | Date |
|---|---|---|
| D99 | **Section 3.19.4, "Items outside the three regulation sub-scales" (`Q31c`), stays.** Resolves the open item flagged in D96: the removal in D96 was scoped to the motivation battery only. Consequence, recorded deliberately: the two batteries are handled asymmetrically — every `Q31` item is reported, while `C2b` is not. No code or render change was required, since 3.19.4 was never removed; the current `PreferredSpeciesReport.docx` (75 tables, 39 images, 7 landscape sections) already reflects the final state. | 2026-09-18 |

## Handoff before the figures phase (2026-09-18, prompt 64)

| # | Decision | Date |
|---|---|---|
| D100 | **Step 4 (figures) moves to a new conversation.** Chapter 3's table build is finished and verified, so the figure work starts from a clean context. Restart R first — the build session accumulated scratch objects from verification (`hits`, `xml`, `x`, `p`, `pre`, `m`, `leaks`, `t_a11`, `t_a4`, `t_att`, `t_days`, `t_g`, `t_t`, `a4`, `bassIDs`, `td`, `v1`, `need`, `chk`) that a fresh session avoids. | 2026-09-18 |

### State at handoff

`PreferredSpeciesReport.docx`: **75 tables, 39 images, 7 landscape sections, 0 leaked markup.**
Chapters 1-3 and both appendices are built and rendering. Chapter 3 holds 21 sections and 39
tables. All 39 existing images belong to Chapter 2 (13 D4 items x 3 figures); Chapter 3 has none.

### What the figures phase has to decide first

1. **Which questions get figures.** D34 puts them beside the question they illustrate, not in a
   chapter of their own, and D91 held them until the tables were read. Candidates raised earlier
   and never chosen: A9 satisfaction (stacked percent), Q11 crowding (stacked percent), A9 and
   `C1Total_days` (means-ordered), the four motivation scale scores, the four attitude scale
   scores, and A4 waterbody types (grouped bars). Chapter 1 and Chapter 2 figures are settled and
   out of scope.
2. **The Chapter 2 plot helpers are D4-specific and cannot be reused as they stand.**
   `D4PercentStackPlot()`, `D4MeansOrderedPlot()`, and `D4SlopePlot()` all take an item name, read
   `d4.categories`, and hardcode the 1-5 agreement scale key (`d4.scale.key`). Chapter 3 figures
   need generalized versions — a real piece of work, not a call-site change. The row spec
   (`D4RowSpec`) and the fill palette (`D4FillColors`) do generalize as they are.
3. **No cross-year figures in Chapter 3 unless the user extends D74.** The 2018 snapshot (`d2018`)
   was pulled in solely for the Chapter 2 slope figures; Chapters 1 and 3 are 2025-only.
4. **Sizing.** Portrait figures are 6.5in wide (D78, matching the printable width); the seven
   landscape sections could take a wider figure, which is a new decision if a figure lands there.
5. **Voice.** Technician throughout. The D77/D79 interpretation exception was scoped to Chapter 2's
   closing paragraphs and does not extend to Chapter 3 figure captions or any accompanying text.

### Prompt for the next conversation (Chapter 3 figures) — USE THIS ONE

```
Continue the PreferredSpecies report -- step 4, figures for Chapter 3. Read AGENTS.md,
PROGRESS.md, and PROMPTS.md in f:/Survey/Analysis/PreferredSpecies first; they carry the standing
directive, the inherited methodology, decisions D1-D100, and findings F1-F35. Do not re-derive any
of it and do not re-run past verification checks; they passed.

State of the report: Chapters 1-3 and both appendices are built and rendering -- 75 tables, 39
images, 7 landscape sections. Do not touch Chapter 1, Chapter 2, the appendices, or any Chapter 3
table.

Task: plan, then build, the Chapter 3 figures. Plan before code: propose which questions warrant a
figure and what kind, confirm sizing and placement, and get my go-ahead before writing code or
files. See "What the figures phase has to decide first" at the end of PROGRESS.md -- in
particular, the Chapter 2 plot helpers are D4-specific and will need generalizing, and Chapter 3
is 2025-only unless I say otherwise.

Ground rules, already settled -- do not re-litigate:
- Technician voice. The D77/D79 interpretation exception was scoped to Chapter 2's closing
  paragraphs only.
- Figures go beside the question they illustrate (D34); there is no visualizations chapter.
- Rows/groups are the 17 preferred groups plus Overall, via D4RowSpec, and they overlap (D31) --
  never total them. Displayed N is always raw, unweighted.
- Never edit anything upstream (CrossTabTables/, BaseFunctions*, Data/).
- Portrait figures are 6.5in wide (D78).

Render and verify after each build increment against the 75-table / 39-image baseline, and keep
PROGRESS.md and PROMPTS.md updated, logging every prompt verbatim in PROMPTS.md.
```

## Chapter 3 figures built — 2026-09-18 (prompts 65-67)

Step 4 is complete for Chapter 3. Fourteen figures were added; no table, caption, or section
was changed, and nothing in Chapters 1-2, the appendices, or upstream was touched.

| # | Decision | Date |
|---|---|---|
| D101 | **Chapter 3 carries 14 figures**, chosen from the candidate list at the end of the pre-figure handoff. Included: A11 and A12 out-of-state rates, tournament participation, Q11 crowding (stacked), A7 and A8 distance medians, A9 satisfaction (stacked **and** ordered mean, two figures), Q16 sonar, Q26 ice, C1 total days fished, and the motivation (4), regulation (3), and attitude (4) scale-score facet figures. **Excluded by the user:** the A4/A5/A6 select-all dot grids. **Excluded by me and accepted:** the guided-trip block and the tournament-count mean, because F33 leaves 31 of 108 and 5 of 18 cells empty and a figure would mostly plot absence. | 2026-09-18 |
| D102 | **No text accompanies a Chapter 3 figure** (user's explicit choice). Each figure follows its table directly, with the question text carried in the plot title and any scale key in an italic subtitle. The two-paragraph Chapter 2 pattern is not repeated — D77/D79 stays scoped to Chapter 2. | 2026-09-18 |
| D103 | **Uniform 6.5in width** for every Chapter 3 figure, including the ones whose section is landscape. Heights: 5in for the sorted dot plots, 6in for stacked percent, 7.5in for a 4-facet scale figure, 5in for the 3-facet one. | 2026-09-18 |
| D104 | **Sorted dot plots drop the species indent; facet plots keep it.** In the point-and-interval figures rows are sorted by the estimate, which destroys the family/species nesting, so labels are the plain `RawLabel` plus the row's raw N — the same choice `D4MeansOrderedPlot` already made. The scale-score facet figures keep table order and the indent, because sorting per facet would stop rows lining up across panels. | 2026-09-18 |
| D105 | **The scale-score facet figures carry no N in their row labels.** Each scale applies its own `*_AnsweredAll` gate (D19), so a row's count differs from panel to panel and a single label N would be wrong for three of four panels. The counts are in the scale-score table immediately above each figure, per cell (D90). This is the only figure type in the report without N on the label. | 2026-09-18 |
| D106 | **Intervals are never clipped to the response scale.** The axis argument was implemented as `expand_limits()` rather than `coord_cartesian()`, so passing `c(1, 5)` guarantees the full 1-5 scale is visible *and* an interval running past an endpoint still shows. Percent intervals are likewise drawn as computed: a Wald interval that crosses 0 or 100 on a small group stays visible rather than being silently trimmed. | 2026-09-18 |
| D107 | **A dashed grey reference line marks the Overall value** on every sorted dot plot, and Overall is also plotted as its own point. Descriptive only; no threshold or target is implied. | 2026-09-18 |

### New code — `PreferredSpeciesFunctions.R` (1,369 -> 1,663 lines)

A "Chapter 3 figures" block at the end of the file:

- `Ch3RowStat(mydata, gate, statFun)` — walks `D4RowSpec(includeOverall = TRUE)` and applies
  `statFun` to each row's subset, with the same filtering the Chapter 3 tables use. `statFun`
  returning `NULL` drops the row, so an empty subset is a visibly missing group rather than a
  fabricated zero.
- `Ch3RateLong()`, `Ch3MeanLong()`, `Ch3MedianLong()` — long-format data built on `Ch3RowStat`,
  calling `base.summary.percent.selectOne`, `base.summary.means`, and `base.summary.medians`
  unmodified. The median helper carries the asymmetric bootstrap limits through as computed.
- `Ch3DotPlot()` — shared renderer for the sorted point-and-interval figures.
- `Ch3RatePlot()`, `Ch3MeanPlot()`, `Ch3MedianPlot()` — thin wrappers over the above.
- `Ch3StackPlot()` — supplies the variable's own factor levels and delegates to
  `D4PercentStackPlot()`. **No generalization was needed:** `D4PercentLong()` and
  `D4PercentStackPlot()` already take the categories as arguments and read nothing from the
  calling environment, contrary to the handoff note; only `D4MeansOrderedPlot` was genuinely
  D4-bound (it hardcodes the 1-5 axis and reads `d4.scale.key`), and `Ch3MeanPlot` replaces it
  for Chapter 3 rather than modifying it.
- `Ch3ScaleFacetPlot()` — one panel per scale, rows in table order, `*_AnsweredAll` gates applied
  per scale.

Chapter 2's `D4RowSpec()` and `D4FillColors()` are reused unmodified, so the Chapter 3 figures
cannot drift from the Chapter 3 tables or from Chapter 2's row set. Nothing upstream was touched.

### Verification — Chapter 3 figures (run 2026-09-18, all pass)

| Check | Baseline | Result |
|---|---|---|
| Tables | 75 | **75** — unchanged, no table disturbed |
| Images | 39 | **53** = 39 + 14 |
| Landscape sections | 7 | **7** — unchanged |
| Leaked markup | 0 | **0** |
| Row completeness | 18 | **18 rows in all 11 figure datasets checked** (Overall + 17 groups); no group silently dropped |
| A11 figure vs table | 44.1%, n = 1,884 | matches (44.13, 1,884) |
| Days fished figure vs table | 30.2 | matches (30.205) |
| A9 mean figure vs table | 2.3 +- 0.06, n = 1,871 | matches (2.2648 +- 0.0555) |
| Tournament figure vs table | 3.0 +- 0.86, n = 1,908 | matches (3.05 +- 0.864) |
| Interval clipping | none permitted | motivation facets: 0 of 72 intervals outside 1-5; axis uses `expand_limits`, so any future overrun stays visible |

Render was clean both increments; the only console output was pandoc's `--highlight-style`
deprecation warning, which predates this work.

### Status

| Step | State |
|---|---|
| 3 — Chapter 3 tables | Done (39 tables) |
| 4 — figures | **Done.** 14 Chapter 3 figures; Chapters 1-2 figures unchanged. Awaiting the user's read-through |
| 5 — guided text | Not started — the only remaining step |

### Open for the user

1. **Read-through of the 14 figures**, especially the three scale-score facet figures: 18 rows x
   4 panels at 6.5in is the densest layout in the report, and the row labels are small.
2. **The excluded figures** (guided trips, tournament-count mean, A4/A5/A6 select-all grids) can be
   added later; the helpers for the first two already exist and a select-all grid would need one
   more (`Ch3SelectAllGrid`).
3. Q24 and Q25 from the earlier list are still open (Appendix A heading year; Appendix B wording).

### Mean age added to the Chapter 3 age table (2026-09-18, prompt 68)

| # | Decision | Date |
|---|---|---|
| D108 | **The age table gains a weighted mean-age column, taken from the continuous `Age` variable, not from `E3`.** Averaging the `E3` band factor the way `includeMean = TRUE` does elsewhere would have returned a mean band index (1-6), not a mean age, so `Ch3SelectOneTable()` gained an optional `meanVar` (and `meanLabel`) argument; the default reproduces the previous behaviour exactly and the A9 table was regression-checked as unchanged. The column is weighted, consistent with D89's treatment of age and gender in this report. No upstream counterpart exists — the 2025 Crosstabs report presents the `E3` distribution only, unweighted, and reports no mean age — so there is nothing to match and nothing to reconcile. | 2026-09-18 |

**Denominator, checked rather than assumed.** `Age` and `E3` are non-missing on exactly the same
1,777 respondents, and every reported age falls inside its own band (16-24 spans 19-24, 65+ spans
65-89), so `E3` is derived from `Age`. The single-N convention (D90) therefore still holds and the
mean needs no separate per-cell count. The age chunk now asserts
`identical(is.na(d$Age), is.na(d$E3))`, so if that ever stops holding the render stops instead of
printing a caption claim that has become false.

**Worth noting for the write-up:** the weighted mean age is **46.0 ± 0.88** against an unweighted
mean of **53.7**. The gap is expected — the rake targets age group and residency — but it is large,
and any text drawing on this column should quote the weighted figure.

**Verification (run 2026-09-18):** render clean; **75 tables, 53 images, 7 landscape sections**, all
unchanged; the `Mean age ± CI` header and the `46.0 ± 0.88` Overall cell are both present in
`document.xml`; the A9 mean column is byte-identical to before the change (Overall 2.3 ± 0.06,
Trout 1.8 ± 0.21).

### Rendered drafts are now tracked (2026-09-18, prompt 69)

| # | Decision | Date |
|---|---|---|
| D109 | **`PreferredSpeciesReport.docx` is tracked in git**, so drafts can be circulated through the repository. Supersedes the exclusion in D37. Implemented as a `!PreferredSpeciesReport.docx` negation in the project `.gitignore`, because the repo-root `.gitignore` ignores `*.docx` across all of `Analysis/` (F36); the root rule was deliberately not touched, so no other project's behaviour changes. The other `.gitignore` entries are unchanged — build artifacts (`.verify2/`, `.verifytmp/`), Word lock files, and the inert `SurveyInstrument_2025.docx` from D39 all stay ignored. Practical consequence: the ~550 KB binary is re-committed in full on every render, so the repository will grow with each draft. | 2026-09-18 |

| # | Finding |
|---|---|
| F36 | **D37's premise was wrong: `CrossTabTables/` does not track its rendered `.docx`.** `git ls-files CrossTabTables` returns no Word document. The repo-root `.gitignore` at `F:/Survey/Analysis` ignores `*.docx` (along with `*.pdf`, `*.png`, and `*.jpg`) for the entire repository, so no project in `Analysis/` has ever tracked rendered output. The "divergence" D37 flagged therefore never existed, and D109's tracking of this report's `.docx` is a genuine *departure* from repo practice rather than a return to it. Nothing was changed in `CrossTabTables/` or in the root `.gitignore`. |

## Handoff before Chapter 4 — 2026-09-18 (prompt 70)

| # | Decision | Date |
|---|---|---|
| D110 | **A new Chapter 4 is planned, and its content is not yet defined.** It is *not* the old "Chapter 4: Visualizations" that D34 removed — that decision stands, and figures continue to sit beside the questions they illustrate. The new chapter is a fresh analysis the user has in mind; the next conversation must elicit it rather than infer it. Step 5 (guided text development) is deferred until after Chapter 4, since new material would otherwise need wordsmithing twice. | 2026-09-18 |

### State at handoff

`PreferredSpeciesReport.docx`: **75 tables, 53 images, 7 landscape sections, 0 leaked markup.**
Renders clean end to end. Everything below is built, verified, and signed off except where noted.

| Part | Content |
|---|---|
| Chapter 1 | Species groupings — 23 tables, design-based pairwise contrasts, the decision packet behind the 17-group banner |
| Chapter 2 | The `D4` battery — 13 items, each with a table and 3 figures (39 images), plus 26 interpretive paragraphs |
| Chapter 3 | 21 sections, 39 tables, 14 figures. The age table gained a weighted mean-age column (D108) |
| Appendix A | Blank placeholder; the instrument is pasted in by hand (D36) |
| Appendix B | Statistical methodology, 12 sections. Needs a wording read-through (Q25) |

**Structural facts that are settled and must not be re-derived:**

1. Universe is `filter(surveyYear == 2025)` then `filter(!is.na(B1))` → **n = 1,915** (D23). The
   Overall column deliberately does not match the 2025 Crosstabs report (D28); only the `B1`
   distribution does.
2. The 17-group banner **overlaps and is not a partition** (D31). Family rows contain their own
   species rows; counts sum to 2,695 against 1,874 distinct. Never total a column or a row set.
3. Displayed N is always the **raw, unweighted** count. CIs use Kish effective N.
4. No significance testing anywhere except Chapter 1, which uses `svyttest()` with Bonferroni
   across contrasts (D24, D32).

### What is reusable, and what is not

Everything in `PreferredSpeciesFunctions.R` (1,663 lines) is available to Chapter 4 unmodified:

| Layer | Functions |
|---|---|
| Row set | `D4RowSpec(includeOverall)`, `banner.definition`, `AssignBannerGroup()` |
| Table builders | `Ch3SelectOneTable()` (now with optional `meanVar`), `Ch3SelectAllTable()`, `Ch3MeansTable()`, `Ch3MediansTable()`, `Ch3IndicatorTable()`, `Ch3MeansSpecTable()` |
| Figure layer | `Ch3RowStat()` and the `Ch3RateLong/MeanLong/MedianLong()` trio, `Ch3DotPlot()`, `Ch3RatePlot()`, `Ch3MeanPlot()`, `Ch3MedianPlot()`, `Ch3StackPlot()`, `Ch3ScaleFacetPlot()` |
| Inference | `PairwiseContrasts()`, `ContrastTable()`, `EffortContrastTable()` — Chapter 1 only so far |
| Formatting | `CreateFlex()`, `FmtPct/FmtMean/FmtMeanD4/FmtMeanN/FmtMedianN/FmtCount/FmtP` |

`Ch3RowStat(mydata, gate, statFun)` is the general extension point: hand it any summariser that
returns a one-row tibble and it walks the banner correctly, with the same filtering the tables
use. A genuinely new statistic should be added there rather than in a bespoke loop.

**Upstream stays read-only.** `CrossTabTables/`, `TrendTables/`, `BaseFunctions_2025_UPDATED.R`,
and `Data/` are never edited, no matter what Chapter 4 needs.

### What Chapter 4 has to settle first

Work these with the user before writing code. Each has a default inherited from Chapters 1-3, so
the question is whether Chapter 4 keeps it or departs — and a departure needs to be recorded.

1. **What the analysis is.** Not inferable from anything on disk. Elicit it.
2. **Universe.** Default is the report universe, n = 1,915 (D23). A different universe means the
   Overall row is no longer comparable to Chapters 1-3, which has to be disclosed the way D28
   discloses the divergence from the crosstabs.
3. **Row set.** Default is `D4RowSpec(includeOverall = TRUE)` — Overall plus the 17 overlapping
   preferred groups. If Chapter 4 needs a different grouping, it is a new decision, and the
   overlap warning (D31) may or may not still apply.
4. **Inference.** Chapters 2-3 are purely descriptive; only Chapter 1 tests anything. If Chapter 4
   involves tests or models, the multiplicity plan must be explicit (see D14/D24/D32 and the
   still-open Q22), and Appendix B needs a new section — that is the precedent D5 set.
5. **Cross-year.** 2025-only unless extended. The `d2018` snapshot exists in the setup chunk and
   was pulled in for the Chapter 2 slope figures alone (D74/D76).
6. **Output conventions.** Transposed layout (D43), display precision (D93), the two N conventions
   (D90), captions assembled from the `caption.ch3*` strings, `CreateFlex()` for every table.
7. **Placement and orientation.** Chapter 4 goes after Chapter 3 and before `# Appendix A`; the
   appendices are lettered, so nothing renumbers. The last section break in the document is the
   landscape bracket before Days Fished, so new content inherits **portrait** — wide material
   needs the `sect_portrait()` / `sect_landscape()` bracket idiom (D92).
8. **Appendix B.** Decide whether the chapter introduces anything the methodology appendix must
   describe.

### Workflow gotchas that have each cost time at least once

| Gotcha | Handling |
|---|---|
| `PreferredSpeciesFunctions.R` is auto-reformatted on write (F7) | Re-read before editing; never edit against a remembered version |
| Large `cat >> file << EOF` heredocs silently truncate (F34) | Append in blocks of ~80 lines and check `wc -l` after each |
| A stray code fence swallowed a whole chapter (F35) | Keep opener/closer fence counts balanced; scan after big edits |
| Render fails with `pandoc ... error 1` | Check for `~$eferredSpeciesReport.docx` — the document is open in Word |
| Two adjacent tables merge in Word, duplicating headers (D33, D98) | Every table gets its own lead-in paragraph, including under sub-headings |
| `block_section()` describes the section that **ends** at that point (D92) | Bracket wide runs: portrait break before, landscape break after |
| `git` refuses with "dubious ownership" | Use `git -c safe.directory=F:/Survey/Analysis ...`; the global config was deliberately left alone |
| Every file warns `LF will be replaced by CRLF` | Benign today; a `.gitattributes` with `* text=auto` would settle it |

**Restart R before starting.** This session accumulated scratch objects that a fresh session
avoids: `p1`-`p5`, `figRows`, `ageTbl`, `v`, `f`, `A17Label`, and the chunk-local frames
`dTourney`, `dDays`, `dAccess`, `dHiredGuide`, `dQ18means`.

**Git state:** branch `master`, remote `keithhurley/Analysis`, clean and pushed through `cf6d6e4`.
The rendered `.docx` is tracked now (D109), so a render should be committed alongside its source.

### Still open, independent of Chapter 4

| # | Item |
|---|---|
| Q22 | Outcome-dimension multiplicity in Chapter 1 (F8) — flagged, not implemented |
| Q24 | Appendix A heading year — 2025 or 2026 |
| Q25 | Appendix B wording: the inherited "roughly 9x too tight" passage reads as contradicting the newer scale-invariance note |
| — | Step 5, guided text development, for Chapters 1-3 |
| — | Figures deliberately excluded (D101): guided trips, the tournament-count mean, and the A4/A5/A6 select-all grids |

### Prompt for the next conversation (Chapter 4) — USE THIS ONE

```
Continue the PreferredSpecies report -- a new Chapter 4. Read AGENTS.md, PROGRESS.md, and
PROMPTS.md in f:/Survey/Analysis/PreferredSpecies first; they carry the standing directive, the
inherited methodology, decisions D1-D110, and findings F1-F36. Do not re-derive any of it and do
not re-run past verification checks; they passed.

State of the report: Chapters 1-3 and both appendices are built, verified, and rendering -- 75
tables, 53 images, 7 landscape sections, 0 leaked markup. Restart R before you begin. Do not
touch Chapters 1-3, the appendices, or any existing table or figure.

Chapter 4 is a new analysis I have in mind and have not described to you yet. Do NOT infer it
from ANALYSIS_PLAN.md or from the removed "Chapter 4: Visualizations" heading -- D34 stands and
figures continue to sit beside the question they illustrate. Ask me what the chapter is. Then
plan before code: no code execution and no file writing until I give the go-ahead.

Drive the conversation from "What Chapter 4 has to settle first" near the end of PROGRESS.md --
universe, row set, whether any inferential statistics are involved, cross-year scope, output
conventions, placement and orientation, and whether Appendix B needs a new section. Tell me where
Chapter 4 would depart from what Chapters 1-3 already do, rather than quietly adopting a default.

Ground rules, already settled -- do not re-litigate:
- Technician voice. Report the numbers; I interpret them. The D77/D79 interpretation exception
  was scoped to Chapter 2's closing paragraphs only.
- Universe is surveyYear == 2025 with !is.na(B1), n = 1,915 (D23), unless I say otherwise.
- Rows are Overall plus the 17 preferred groups via D4RowSpec, and they overlap (D31) -- never
  total them. Displayed N is always raw and unweighted; CIs use Kish effective N.
- Transposed layout, landscape only where needed (D43); block_section brackets per D92.
- Reuse base.summary.* and the Ch3* builders unmodified. Ch3RowStat() is the extension point for
  a new statistic.
- Never edit anything upstream (CrossTabTables/, TrendTables/, BaseFunctions*, Data/).
- Portrait figures are 6.5in wide (D78/D103).

Render and verify after each build increment against the 75-table / 53-image / 7-landscape
baseline, and keep PROGRESS.md and PROMPTS.md updated, logging every prompt verbatim in
PROMPTS.md. The rendered .docx is tracked in git now (D109), so commit it alongside the source.
Use `git -c safe.directory=F:/Survey/Analysis ...` -- plain git refuses in this repo.
```

## Chapter 4 defined — satisfaction (2026-09-18, prompt 71)

### Carried into this file at the user's direction (the handoff item that was missed)

> One thing I did not do: the new baseline is 75 tables / 53 images / 7 landscape, and the
> checklist item on inference notes that any testing in Chapter 4 needs a multiplicity plan and an
> Appendix B section — the precedent D5 set for Chapter 1. If Chapter 4 turns out to be modelling
> work, that's the item worth settling first.

**Verification baseline for every Chapter 4 increment: 75 tables / 53 images / 7 landscape
sections / 0 leaked markup.** Any change to those counts must be attributable to Chapter 4 alone.

| # | Decision | Date |
|---|---|---|
| D111 | **Chapter 4 is satisfaction.** It collects the satisfaction items scattered through the report into one place: the main satisfaction question (`A9`, Chapter 3) and the satisfaction items in the preferred-species battery (`D4`, Chapter 2). Three questions: (1) are the answers internally consistent, (2) which preferred groups show a gap between satisfaction with **size** and satisfaction with **numbers**, and (3) which show no gap. Chapters 1-3, both appendices, and every existing table and figure are untouched — Chapter 4 repeats material by design rather than moving it. | 2026-09-18 |
| D112 | **Inference is permitted in Chapter 4** — the user's explicit second exception to the no-interpretation rule, after D77/D79 scoped the first one to Chapter 2's closing paragraphs. Per the D5 precedent, any test carries an explicit multiplicity plan and a matching new section in Appendix B. | 2026-09-18 |

### Chapter 4 built — 2026-09-18 (prompts 72-76)

| # | Decision | Date |
|---|---|---|
| D113 | **A9 is reversed in Chapter 4** as `6 - as.numeric(A9)`, so every column runs low to high satisfaction alongside the D4 items. Subtraction from a constant does not change the spread, so the interval is unchanged and Chapter 3's overall `2.3 +- 0.06` appears here as `3.7 +- 0.06`. The reconciliation is stated in the chapter preamble and again in Appendix B, so a reader comparing chapters is not left to infer it. Chapter 3 is untouched. | 2026-09-18 |
| D114 | **Chapter 4 runs no significance test.** The user was offered design-based paired `svyttest` comparisons with Bonferroni across the 17 groups, and separately a two-tier interval figure carrying the same information, and declined both: *"don't care about testing....want to just show the dumbell plot."* D112's permission stands but is unused. Paired differences are reported as a weighted mean +- CI, produced by `base.summary.means` on a difference column so the interval is the same Kish-effN interval used everywhere else in the report. The no-adjustment position is disclosed in the captions and in Appendix B. | 2026-09-18 |
| D115 | **Gap columns carry 2 dp**, against the 1 dp used for the means beside them (D93). The overall catch gap is 0.07 and would print as 0.1 next to an interval of 0.06. `FmtMeanGap()` implements it; no other precision changes. | 2026-09-18 |
| D116 | **Six items, not more.** A9, D4a, D4i, D4j, D4k, D4l. The trade-off items (D4b, D4e, D4g) and the constraint items (D4f, D4h, D4m) were offered and declined — *"the top 6 should be used...not the other."* They stay in Chapter 2 only. | 2026-09-18 |
| D117 | **Reliability appears as one footnote line scoped to D4i-D4l**, the four items the sibling `D4ScaleAnalysis` report validated as a Satisfaction sub-scale. Weighted raw alpha on this report's sample is **0.762** (n = 1,506) against that report's ordinal alpha of 0.806 on its own pooled, no-preference-excluded sample. **No composite score is built**, here or anywhere in the report (D40/D63 hold). A9 and D4a are explicitly excluded from the coefficient: A9 asks about the season rather than the preferred fish, and the sibling report places D4a with the constraint items, reversed. | 2026-09-18 |
| D118 | **The dumbbell is the chapter's figure form.** Two figures, one per pair, rows sorted by the gap with the indent dropped and raw N on the label (D104), full 1-5 axis via `expand_limits` (D106), 6.5in wide (D103). The gap-forest alternative, with and without two-tier intervals, was drafted and rejected. | 2026-09-18 |

#### Structure

Six tables and two figures, placed after Chapter 3 and before Appendix A, plus one new Appendix B
section ("Satisfaction comparisons in Chapter 4") and one added paragraph under Display precision.

| Section | Content |
|---|---|
| 4.1 The satisfaction items | Inventory: verbatim question text, short name, which chapter reports it in full, N, overall mean |
| 4.2 Satisfaction by preferred group | 18 rows x 6 items, `Ch3MeansTable()` reused unmodified. **Landscape** |
| 4.3 Consistency between the items | Respondent-level weighted correlations (n = 1,489 complete on all six), then rank correlations between the 17 group means |
| 4.4 Size and numbers: the fish anglers catch | `D4i` vs `D4k` gap table + dumbbell |
| 4.5 Size and numbers: the fish anglers may harvest | `D4j` vs `D4l` gap table + dumbbell |

#### New code — `PreferredSpeciesFunctions.R` (1,684 -> 2,006 lines)

`ch4.sat.items`, `FmtMeanGap`, `Ch4AddSatVars`, `Ch4ItemTable`, `FormatCorrMatrix`,
`Ch4CorrComplete`, `Ch4CorrTable`, `Ch4GroupMeans`, `Ch4GroupCorrTable`, `Ch4GapTable`,
`Ch4DumbbellPlot`, `Ch4Alpha`, `Ch4GapNumbers`, `Ch4GapNames`. Every one loops
`D4RowSpec(includeOverall = TRUE)` and calls `base.summary.means` unmodified, so Chapter 4 cannot
drift from Chapters 2-3. The six-item matrix needed no new builder at all — `Ch3MeansTable()`
already does exactly that job. Nothing upstream was touched.

#### Findings

| # | Finding |
|---|---|
| F37 | **A9 and the D4 items point in opposite directions.** A9 is 1 = Very satisfied to 5 = Very dissatisfied; every D4 item is 1 = Strongly Disagree to 5 = Strongly Agree. Tabling them together untransformed would have put two opposite meanings in one row. Handled by D113. |
| F38 | **The six items are not one dimension.** Respondent-level correlations split into a catch block (A9 reversed, D4a, D4i, D4k) and a harvest-allowed block (D4j-D4l = 0.57), with D4l correlating 0.18 with A9 reversed and 0.18 with D4a. Raw alpha across all six is 0.798, which looks respectable and conceals the split — the reason D117 scopes the coefficient to the four validated items instead. |
| F39 | **At group level, general satisfaction tracks numbers caught, not harvest limits.** Spearman correlations between the 17 group means: A9 reversed with D4k = 0.85 and with D4a = 0.83, but with D4j = 0.30 and D4l = 0.28. D4a with D4l is -0.03. Descriptive only — 17 overlapping groups, no standard error. |
| F40 | **A backticked column name cannot contain a `\uXXXX` escape** — R fails at parse with "\uxxxx sequences not supported inside backticks". The plus-or-minus in a column header has to come from a string constant used as a dynamic name (`!!ch4.lab.diffci := ...`), which is what the Chapter 4 builders do. |
| F41 | **The leaked-markup scan needs a stricter regex than the obvious one.** `<w:t[^>]*>` also matches `<w:tbl>`, and a self-closing `<w:t xml:space="preserve"/>` lets `.*?</w:t>` run on into real markup; both produce false positives (95 and 2 respectively on a clean document). The correct pattern is `<w:t(?: [^>]*[^/>])?>.*?</w:t>`. |

#### Verification — Chapter 4 (run 2026-09-18, all pass)

| Check | Baseline | Result |
|---|---|---|
| Render | clean | clean; only the pre-existing pandoc `--highlight-style` warning |
| Tables | 75 | **81** = 75 + 6 |
| Images | 53 | **55** = 53 + 2 |
| Landscape sections | 7 | **8** = 7 + 1 (the 4.2 matrix) |
| Leaked markup | 0 | **0** (with the F41 regex) |
| A9 reversal exact | — | `all(A9rev + as.numeric(A9) == 6)` and identical missingness, asserted in `ch4Setup` |
| A9 reconciliation | Ch 3: 2.3 +- 0.06 | Ch 4 prints 3.7 +- 0.06 (1,871); Chapter 3's cell is unchanged in the rendered file |
| Row completeness | 18 | 18 rows in the matrix, both gap tables, and both figure datasets |
| Gap interval vs. design-based | — | Kish-effN interval matches `svyttest` on the same difference: overall 0.07 +- 0.06 vs. [0.015, 0.126]; Flathead 0.57 +- 0.32 vs. [0.233, 0.907] |

**New baseline: 81 tables / 55 images / 8 landscape sections / 0 leaked markup.**

#### Result, for the user's read-through

Unadjusted, reading each difference interval against zero. **Fish caught:** size rated above
numbers for Flathead catfish, Blue catfish, Moronides, Catfish, and Walleye / Sauger; numbers rated
above size for Largemouth bass and Bass; the other 10 groups overlap zero. **Fish that may be
harvested:** only Muskellunge (n = 8) above and No preference below; 15 of 17 overlap zero. Overall
the two pairs are 0.07 +- 0.06 and -0.00 +- 0.04.

## Handoff before Chapter 5 — 2026-09-21 (prompt 77)

| # | Decision | Date |
|---|---|---|
| D119 | **A new Chapter 5, "Angler Type Profiles", is planned, and its content is not yet defined.** The title is all that exists. As with D110 before Chapter 4, the next conversation must elicit the chapter rather than infer it — in particular it must not assume that "angler type" means a cluster analysis, an existing variable, or a published typology. Step 5 (guided text development) is deferred again, for the same reason it was deferred before Chapter 4: new material would otherwise need wordsmithing twice. | 2026-09-21 |

### State at handoff

`PreferredSpeciesReport.docx`: **81 tables, 55 images, 8 landscape sections, 0 leaked markup.**
Renders clean end to end. Everything below is built and verified except where noted.

| Part | Content |
|---|---|
| Chapter 1 | Species groupings — 23 tables, design-based pairwise contrasts, the decision packet behind the 17-group banner |
| Chapter 2 | The `D4` battery — 13 items, each with a table and 3 figures, plus 26 interpretive paragraphs |
| Chapter 3 | 21 sections, 39 tables, 14 figures |
| Chapter 4 | Satisfaction — 6 tables, 2 dumbbell figures, descriptive only (D114) |
| Appendix A | Blank placeholder; the instrument is pasted in by hand (D36) |
| Appendix B | Statistical methodology, 14 sections. Still needs a wording read-through (Q25) |

**Environment.** The R session was restarted after the Chapter 4 build and is clean — no scratch
objects to avoid this time. `PreferredSpeciesReport.rmd` showed as modified in the editor while
`git` saw no change, so the editor may be holding **unsaved buffer edits**; check the file on disk
against the buffer before editing it.

**Git.** Branch `master`, remote `keithhurley/Analysis`. Working tree clean apart from
`.posit/assistant/settings.json`. ⚠️ The Chapter 4 commit `15b7a17` is **local and unpushed** — the
user has not been asked. Do not push without asking (house rule).

**Placement and orientation.** Chapter 4 ends at the `## Size and numbers: the fish anglers may
harvest` section; `# Appendix A` follows. Chapter 5 goes between them, so nothing renumbers. The
last `block_section()` in the document is now the `sect_landscape()` bracket closing the 4.2
matrix, and everything after it falls to the body-level portrait section — so new content inherits
**portrait**, and wide material needs its own `sect_portrait()` / `sect_landscape()` bracket (D92).
Re-verify the landscape count after the first Chapter 5 render rather than assuming it.

### Structural facts that are settled and must not be re-derived

1. Universe is `filter(surveyYear == 2025)` then `filter(!is.na(B1))` → **n = 1,915** (D23). The
   Overall column deliberately does not match the 2025 Crosstabs report (D28).
2. The 17-group banner **overlaps and is not a partition** (D31). Never total a column or row set.
3. Displayed N is always the **raw, unweighted** count. CIs use Kish effective N.
4. Significance testing exists only in Chapter 1 (`svyttest` + Bonferroni, D24/D32). Chapter 4 was
   granted an inference exception and **declined to use it** (D112/D114).

### What is reusable

`PreferredSpeciesFunctions.R` is 2,006 lines and everything in it is available unmodified:

| Layer | Functions |
|---|---|
| Row set | `D4RowSpec(includeOverall)`, `banner.definition`, `AssignBannerGroup()` |
| Table builders | `Ch3SelectOneTable()` (optional `meanVar`), `Ch3SelectAllTable()`, `Ch3MeansTable()`, `Ch3MediansTable()`, `Ch3IndicatorTable()`, `Ch3MeansSpecTable()` |
| Figures | `Ch3RowStat()`, `Ch3RateLong/MeanLong/MedianLong()`, `Ch3DotPlot()`, `Ch3RatePlot()`, `Ch3MeanPlot()`, `Ch3MedianPlot()`, `Ch3StackPlot()`, `Ch3ScaleFacetPlot()`, `Ch4DumbbellPlot()` |
| Chapter 4 layer | `ch4.sat.items`, `Ch4AddSatVars()`, `Ch4ItemTable()`, `Ch4CorrTable()`, `FormatCorrMatrix()`, `Ch4GroupMeans()`, `Ch4GroupCorrTable()`, `Ch4GapTable()`, `Ch4GapNumbers()`, `Ch4GapNames()`, `Ch4Alpha()` |
| Inference | `PairwiseContrasts()`, `ContrastTable()`, `EffortContrastTable()` — Chapter 1 only |
| Formatting | `CreateFlex()`, `FmtPct/FmtMean/FmtMeanD4/FmtMeanN/FmtMedianN/FmtMeanGap/FmtCount/FmtP` |

Three of these generalize past their original chapter and are the natural extension points:
`Ch3RowStat(mydata, gate, statFun)` walks the banner with any one-row summariser;
`Ch3MeansTable(mydata, vars, colLabels)` builds any rows-by-items matrix of weighted means, which
is what Chapter 4's six-item matrix turned out to need with no new code at all; and
`FormatCorrMatrix()` renders any correlation matrix as a lower triangle.

**Every one of them assumes the D4RowSpec row set.** If Chapter 5's rows are angler types rather
than preferred species, they need a row-spec argument rather than a hardcoded call — a real change
to the table layer, and the first one this report has needed. Plan it deliberately: parameterizing
`D4RowSpec` out of the builders touches Chapters 2, 3 and 4, so the safer route is a parallel
`Ch5RowSpec()` plus Chapter 5 builders that take a spec argument, leaving the existing call sites
untouched. Whichever route is chosen, re-render and check the 81/55/8/0 baseline immediately.

**Upstream stays read-only.** `CrossTabTables/`, `TrendTables/`, `BaseFunctions_2025_UPDATED.R`,
and `Data/` are never edited, no matter what Chapter 5 needs.

### What Chapter 5 has to settle first

1. **What an "angler type" is, and where the types come from.** Nothing on disk answers this.
   Three broad possibilities with very different consequences: types read off an existing variable
   (residency, gear, avidity band, preferred species itself); types **derived** by segmenting
   anglers on attitude, motivation, or behaviour measures; or types imported from a published
   typology and operationalized here. Ask; do not pick.
2. **If the types are derived, this is the report's first modelling work.** That is precisely the
   case the user flagged in prompt 71, and it stops being hypothetical. Settle before any code: the
   inputs, the universe, how survey weights enter the segmentation, how the number of types is
   chosen, how the solution is validated, and how instability is disclosed. Appendix B gains a
   section (the D5 precedent), and if anything is tested, a multiplicity plan comes with it.
3. **The row set — the biggest departure yet.** Every table in Chapters 1-4 is keyed to the 17
   overlapping preferred groups. Chapter 5 can profile types on their own, crosstab type against
   preferred species, or add type as a second banner. Only the middle option keeps the report's
   spine, and it is also the sparsest: 17 preferred groups against k types on n = 1,915 will leave
   many cells in single digits, as F33 already showed for a far coarser split.
4. **Universe.** Default is n = 1,915 (D23). A typology built on scale scores will carry listwise
   gates (D19) and shrink it; if the chapter's Overall row stops being comparable to Chapters 1-4,
   say so in the chapter and in Appendix B the way D28 discloses the crosstabs divergence.
5. **Weights.** Every estimate in this report is weighted. Segmentation methods take weights
   inconsistently, and some ignore them. Whatever is decided for the type assignment itself, the
   profile tables that follow must still be weighted, and any gap between the two must be stated.
6. **Cross-year.** 2025 only unless extended. `d2018` exists in the setup chunk and was pulled in
   for the Chapter 2 slope figures alone (D74/D76).
7. **Output conventions.** Transposed layout (D43), display precision (D93/D115), the two N
   conventions (D90), `CreateFlex()` for every table, a lead-in paragraph before every table so no
   two tables are adjacent (D33/D98), portrait figures 6.5in wide (D78/D103).

### Candidate raw material — a menu to ask about, NOT an inference about the chapter

Listed so the next conversation can put concrete options in front of the user. Which, if any, of
these belong in Chapter 5 is entirely the user's call.

| Family | Variables | Verified in use? |
|---|---|---|
| Attitude scale scores | `attitude_catch`, `attitude_numbers`, `attitude_size`, `attitude_harvest` (from `E1`) | Yes — Chapter 3 §3.20.5 |
| Motivation scale scores | `motivation_natural`, `motivation_pp`, `motivation_social`, `motivation_resource` (from `C2`) | Yes — Chapter 3 §3.18.5 |
| Regulation scale scores | `reg_comprehension`, `reg_sitesupport`, `reg_uniform` (from `Q31`) | Yes — Chapter 3 §3.19.5 |
| Barrier scale scores | `barriers_access`, `barriers_time`, `barriers_social`, `barriers_knowledge`, `barriers_cost` | **No** — listed in `AGENTS.md` §3 but used nowhere in this report; confirm they exist before proposing them |
| `D4` sub-scales | Satisfaction, Constraints, Regulation support — derived and held-out tested by the sibling `D4ScaleAnalysis` project | Not in this report (D40/D63 keep it item-level) |
| Avidity and effort | `C1Total_days`, `C1Jan`…`C1Oct`, `A13_corrected` tournaments, `Q18a`/`Q18b` guide days | Yes — Chapter 3 |
| Behaviour | `A4` waterbody types, `A5` methods, `A6` techniques, `Q16` sonar, `Q26` ice | Yes — Chapter 3 |
| Harvest orientation | `B3*` keep/release per species | **No** — excluded from Chapter 3 outright by D86, but present in the data |
| Species preference | `B1`, the 17 groups, `gtype`/`gtype2` | Yes — the report's spine |
| Demographics | `Resi`, `E2`, `E3`, `Age` | Yes — Chapter 3 |

All scale scores are created by `add_scale_scores(d)` at render time from `Scales.csv`; they are
not stored in the saved data. Each carries its own `*_AnsweredAll` listwise gate (D19).

### Workflow gotchas that have each cost time at least once

| Gotcha | Handling |
|---|---|
| `PreferredSpeciesFunctions.R` is auto-reformatted on write (F7) | Re-read before editing; never edit against a remembered version |
| Large `cat >> file << EOF` heredocs silently truncate (F34) | Append in blocks of ~80 lines and check `wc -l` after each |
| A backticked column name cannot hold a `\uXXXX` escape (F40) | Use a string constant as a dynamic name: `!!ch4.lab.diffci := ...` |
| The obvious leaked-markup regex gives false positives (F41) | Use `<w:t(?: [^>]*[^/>])?>.*?</w:t>`; `<w:t[^>]*>` also matches `<w:tbl>` |
| Counting tables in `document.xml` | `<w:tbl>` never appears; match `<w:tbl[ >]` or count `<w:tblPr>` |
| A stray code fence swallowed a whole chapter (F35) | Keep opener/closer fence counts balanced; scan after big edits |
| Render fails with `pandoc ... error 1` | Check for `~$eferredSpeciesReport.docx` — the document is open in Word |
| Two adjacent tables merge in Word (D33, D98) | Every table gets its own lead-in paragraph, including under sub-headings |
| `block_section()` describes the section that **ends** at that point (D92) | Bracket wide runs: portrait break before, landscape break after |
| `git` refuses with "dubious ownership" | Use `git -c safe.directory=F:/Survey/Analysis ...` |

### Still open, independent of Chapter 5

| # | Item |
|---|---|
| Q22 | Outcome-dimension multiplicity in Chapter 1 (F8) — flagged, not implemented |
| Q24 | Appendix A heading year — 2025 or 2026 |
| Q25 | Appendix B wording: the inherited "roughly 9x too tight" passage reads as contradicting the newer scale-invariance note |
| Q32 | **Chapter 4 reliability presentation** — currently one footnote line scoped to `D4i`-`D4l` (D117); the user was offered a full reliability table and the question was not answered explicitly |
| — | Step 5, guided text development, now covering Chapters 1-4 |
| — | The unpushed Chapter 4 commit `15b7a17` |
| — | Figures deliberately excluded (D101): guided trips, the tournament-count mean, the A4/A5/A6 select-all grids |

### Prompt for the next conversation (Chapter 5) — USE THIS ONE

```
Continue the PreferredSpecies report -- a new Chapter 5, "Angler Type Profiles". Read AGENTS.md,
PROGRESS.md, and PROMPTS.md in f:/Survey/Analysis/PreferredSpecies first; they carry the standing
directive, the inherited methodology, decisions D1-D119, and findings F1-F41. Do not re-derive any
of it and do not re-run past verification checks; they passed.

State of the report: Chapters 1-4 and both appendices are built, verified, and rendering -- 81
tables, 55 images, 8 landscape sections, 0 leaked markup. Do not touch Chapters 1-4, the
appendices, or any existing table or figure.

Chapter 5 is an analysis I have in mind and have not described to you yet. The title is all you
have. Do NOT assume "angler type" means a cluster analysis, an existing variable, or a published
typology -- ask me what the chapter is. Then plan before code: no code execution and no file
writing until I give the go-ahead.

Drive the conversation from "What Chapter 5 has to settle first" near the end of PROGRESS.md.
Start with what defines an angler type and where the types come from, because everything else
follows from it. Then the row set -- every table in Chapters 1-4 is keyed to the 17 overlapping
preferred groups via D4RowSpec, and a type-based row set is the largest structural departure this
report has taken; tell me what it would cost before we commit to it. Tell me where Chapter 5 would
depart from what Chapters 1-4 already do rather than quietly adopting a default.

If the types turn out to be derived rather than read off an existing variable, this is the
report's first modelling work. Settle the inputs, the universe, how the survey weights enter, how
the number of types is chosen, how the solution is validated, and what Appendix B must say --
before any code. That is the D5 precedent and it is the item I flagged before Chapter 4.

Ground rules, already settled -- do not re-litigate:
- Technician voice. Report the numbers; I interpret them. The D77/D79 interpretation exception was
  scoped to Chapter 2's closing paragraphs only.
- Universe is surveyYear == 2025 with !is.na(B1), n = 1,915 (D23), unless I say otherwise.
- The preferred groups overlap (D31) -- never total them. Displayed N is always raw and
  unweighted; CIs use Kish effective N.
- Transposed layout, landscape only where needed (D43); block_section brackets per D92. New
  content at the end of Chapter 4 inherits portrait.
- Reuse base.summary.* and the Ch3*/Ch4* builders. Ch3RowStat() and Ch3MeansTable() are the
  extension points; note that all of them assume the D4RowSpec row set.
- Never edit anything upstream (CrossTabTables/, TrendTables/, BaseFunctions*, Data/).
- Portrait figures are 6.5in wide (D78/D103).

Render and verify after each build increment against the 81-table / 55-image / 8-landscape /
0-leaked-markup baseline, using the F41 regex for the markup scan. Keep PROGRESS.md and PROMPTS.md
updated, logging every prompt verbatim in PROMPTS.md. The rendered .docx is tracked in git (D109),
so commit it alongside the source; use `git -c safe.directory=F:/Survey/Analysis ...` because
plain git refuses in this repo. Note that the Chapter 4 commit 15b7a17 is still unpushed -- ask me
before pushing anything.
```

---

## Chapter 5 defined and templated — 2026-09-21 (prompts 78-91)

### Decisions

| # | Decision | Date |
|---|---|---|
| D120 | **Chapter 5 is a per-group k-means angler-type profile.** One sub-section per eligible preferred group, plus an Overall fit. Not an existing variable, not a published typology — derived, so the D5 precedent applies in full | 2026-09-21 |
| D121 | **Inputs: 14, uncentred**, z-scored within each fit; `C1Total_days` enters as `log1p`. The 4 attitude, 4 motivation and 3 regulation scale scores, days fished, and `D4j` + `D4l` (the two "allowed to harvest" items). Centring was tested and rejected (F43) | 2026-09-21 |
| D122 | **Universe: complete on all 14 → 1,155 of 1,915 (60.3%).** Respondents missing any input are carried as an `Unassigned` row, never dropped; the percent denominator is the **raw** group, so each size table sums to 100 | 2026-09-21 |
| D123 | **Eligibility: ≥ 60 clusterable respondents** → 9 groups + Overall = 10 fits. "No preference" is excluded (31 of 339, 9%) because `D4j`/`D4l` ask about a preferred fish — a structural exclusion, not a chance one | 2026-09-21 |
| D124 | **k by a normalized elbow rule** on within-cluster SS (both axes rescaled to [0,1], k furthest from the end-to-end chord), candidates 2-6, **minimum 15 respondents per type**, k stepped down if the floor binds. The floor is a stated convention, not a published standard — it is mine, and the only in-house precedent is `minimumPerGroupVar = 20` in the upstream plotting code | 2026-09-21 |
| D125 | Clustering is **unweighted**; every reported number is **weighted**, Kish effN intervals, raw displayed N. The gap is disclosed | 2026-09-21 |
| D126 | **Superseded.** `fpc`/`clusterboot` was installed and used during planning; at the user's direction **neither silhouette nor bootstrap Jaccard is reported**, and the render no longer depends on `fpc` | 2026-09-21 |
| D127 | **One combined Holm family** over the 11 `D4` display items and the 24 external characteristics, screened at **alpha = 0.20**. Clustering inputs are always shown and carry **no p** — the clustering produces those differences by construction. This supersedes the original "always include D4 a-i, k, m" | 2026-09-21 |
| D128 | Profile table is **landscape**, `value ± CI` cells, with `N` and `p` columns; `Block` is the merge column | 2026-09-21 |
| D129 | Three figures per fit: elbow curve, standardized input profile, and **one** dumbbell figure holding at most 5 panels (chosen by largest relative spread across types). Note this is one faceted figure, not five separate ones | 2026-09-21 |
| D130 | Chapter 5's code lives in its own **`Ch5Functions.R`**, sourced after `PreferredSpeciesFunctions.R`. **No `D4RowSpec` call site in Chapters 1-4 was touched** | 2026-09-21 |
| D131 | The Overall fit uses all 1,155 clusterable respondents, including "No preference" and unbannered `B1` answers, so it is **not** the union of the group fits | 2026-09-21 |
| D133 | Distance rows **display** a weighted median with bootstrap limits but are **tested** on `log1p` of the same variable, because design-based rank tests do not extend cleanly past two groups. Disclosed in the table note | 2026-09-21 |
| D134 | Six `A4` waterbody fields hold **no 2025 data at all** and are excluded from the tested characteristics, reported in the chapter text rather than silently dropped | 2026-09-21 |
| D135 | **The render baseline is corrected to 79 tables / 55 images / 7 landscape / 0 leaked markup** (see F45). The 81/55/8/0 figure quoted throughout this file predates commit `17cf703` | 2026-09-21 |

### Findings

| # | Finding |
|---|---|
| F42 | Scale scores are `NA` **exactly** when their `*_AnsweredAll` gate fails — `NA_n == GateFail_n` for all 11. The D19 listwise gate and `is.na()` are the same filter here, so no separate gating code is needed for Chapter 5 |
| F43 | **Centring does not improve separation.** Across raw, respondent-centred-11, centred-13 and centred-13-plus-level, average silhouette sits between 0.086 and 0.129 and declines monotonically in k, in both fits tested. The weak separation is not an acquiescence artefact |
| F44 | **Weak separation is intrinsic.** The chosen solutions explain 19.1% to 24.5% of total SS and the WSS curve declines smoothly with no kink. These types are reproducible partitions of a continuum that differ in degree, not naturally separated groups. Stated in the chapter intro |
| F45 | **The 81/55/8/0 baseline was stale.** Commit `17cf703` "commenting out chapter 4 stuff" suppressed **2 tables and 1 landscape section**. Commented-out markdown still contains the literal text `CreateFlex(` and `sect_landscape()`, so a source-level grep counts them while Word never sees them — count rendered output, not call sites |
| F46 | `base.summary.medians()` returns `CIlower`/`CIupper`, **not** `Lower`/`Upper`. Getting this wrong fails silently: the cells come back empty with only an "unknown column" warning |
| F47 | `A7_miles`/`A8_miles` are banded (5, 15.5, 30.5, 50.5, 80.5, 175.5), so weighted medians land on band midpoints and the bootstrap limits are coarse — one limit can equal the estimate |
| F48 | `p.adjust()`'s default `n` counts `NA` entries, which would inflate the Holm family by variables whose test could not be run. Chapter 5 passes `n = sum(!is.na(P))` explicitly |
| F49 | Installing `fpc` pulled 8 dependencies (`modeltools`, `DEoptimR`, `mclust`, `flexmix`, `prabclus`, `diptest`, `robustbase`, `kernlab`). None are needed by the render now that stability is unreported |

### Fits and their k

| Fit | Clusterable n | k cap | k used | Var. explained |
|---|---|---|---|---|
| Overall | 1,155 | 6 | 3 | 20.8% |
| Walleye / Sauger | 359 | 6 | 3 | 21.0% |
| Bass | 259 | 6 | 3 | 21.5% |
| Largemouth bass | 230 | 6 | 3 | 20.9% |
| Panfish / Sunfish | 160 | 6 | 3 | 23.8% |
| Catfish | 160 | 6 | 3 | 23.2% |
| Crappie | 124 | 6 | 3 | 24.0% |
| Channel catfish | 99 | 6 | 3 | 24.5% |
| Moronides | 64 | 4 | 2 | 19.1% |
| Trout | 60 | 4 | 2 | 19.8% |

Not fit: Smallmouth bass (29), Bluegill / Sunfish (29), Northern pike (26), Blue catfish (21),
Flathead catfish (40), Yellow perch (7), Muskellunge (7), No preference (31).

### New code — `Ch5Functions.R` (new file, ~600 lines)

`Ch5Spec()` / `Ch5InputSpec()` / `Ch5D4Spec()` / `Ch5ExternalSpec()` build the row spec;
`Ch5InputFrame()`, `Ch5Complete()`, `Ch5Scale()` build the input matrix; `Ch5FitInventory()`,
`Ch5Elbow()`, `Ch5Fit()` do the fitting; `Ch5SizeTable()`, `Ch5ProfileLong()`, `Ch5Meta()`,
`Ch5ProfileTable()` build the tables; `Ch5ElbowPlot()`, `Ch5ProfilePlot()`, `Ch5ExternalPlot()`
the figures. Every statistic routes through `base.summary.percent.selectOne()`,
`base.summary.means()` or `base.summary.medians()` on a cluster subset, so the weighting and CI
arithmetic are the inherited ones.

### Verification — Chapter 5 template (run 2026-09-21, all pass)

| Check | Result |
|---|---|
| Render | 3.1 min, no errors |
| Tables | 82 = 79 baseline + 3 |
| Images | 58 = 55 baseline + 3 |
| Landscape sections | 8 = 7 baseline + 1 |
| Leaked markup (F41 regex) | 0 |
| Source-level deltas | `CreateFlex(` 81→84, `sect_landscape()` 8→9, `sect_portrait()` 6→7 |
| Chunk `stopifnot` | `nrow(d)` unchanged; types + Unassigned = raw group in every fit; k within cap; every reported type ≥ 15 |
| Walleye profile | 25 rows shown; 35 characteristics tested, 11 pass at 0.20 |

### Status

Chapter 5 intro, the "Coverage of the fourteen inputs" section, and the **Walleye / Sauger
sub-section** are built and rendering. The sub-section pattern is: lead-in, size table, elbow
figure, profile figure, landscape profile table, dumbbell figure.

### Open for the user

| # | Item |
|---|---|
| Q33 | **Appendix B has no clustering section yet** (D132 was intended and is not written). It needs: the 14 inputs, log1p and standardization, the elbow rule and the size floor as stated conventions, the unweighted-fit/weighted-reporting gap, complete-case retention, the circularity of input p-values, the combined Holm family at 0.20, and the continuum caveat from F44 |
| Q34 | Placement of the Overall fit — assumed to **close** the chapter, since "place it first" was declined |
| Q35 | Whether the terse `Labels.csv` row labels ("Catch Something", "Physical and psycological", "Total (Jan-Oct)") are acceptable in Chapter 5. They are Chapter 3's labels, so they are consistent; one contains a typo in the source data, which is upstream and not mine to change |
| — | The remaining **9 sub-sections**, once the Walleye template is approved |
| — | Step 5, guided text development, now covering Chapters 1-5 |
| — | Unpushed commits: `15b7a17` (Ch4), `17cf703` (comment-out), and this one |

---

## Chapter 5 input-set exploration — 2026-09-21 (prompts 92-104)

**Status: PAUSED on an open decision. Do not build report text until Q36 is answered.**

⚠️ **Working-tree warning.** `Ch5Functions.R` implements the 13-input Likert spec (uncentred,
common metric, unstandardized, no days fished, mode-of-five k rule, per-section diagnostics
table, Overall universe excluding No preference). The **chapter text in the .rmd is stale** — it
still describes fourteen inputs, `log1p` and within-fit standardization. **Rendering now would
produce correct tables under incorrect prose.** Commit `1db56bb` is the last fully consistent
state.

### The question that drove this

The user asked whether clustering could be improved, whether other questions would be better
inputs, whether k should come from a mode of several methods, and what happens without days
fished. Ten configurations were tested. **No report content was written for any of them.**

### Every configuration tested, and what it gave

| # | Input set | Vars | Method | Overall n | k | Silhouette | Verdict |
|---|---|---|---|---|---|---|---|
| A | 11 scales + log1p days + D4j/D4l, z-scored | 14 | k-means | 1,155 | 3 (elbow) / 2 (mode) | 0.096-0.114 | the `1db56bb` build |
| B | A with respondent-centred Likert (3 variants) | 14-15 | k-means | 1,155 | 2 | 0.086-0.129 | centring buys nothing |
| C | 11 scale scores only, z-scored | 11 | k-means | — | 2 | 0.139 | ARI 0.50 vs A |
| D | 13 Likert, common metric, **unstandardized** | 13 | k-means | 1,124 | **2 in all 10 fits** | 0.123 | current code |
| E | PCA to 80% of variance | 8 | k-means | — | 2 | 0.139 | ARI 0.91 vs A |
| F | A with blocks weighted equally | 14 | k-means | — | 2 | 0.154 | ARI 0.19 vs A |
| G | 11 scales + all 13 D4 items | 24 | k-means | 1,094 | 2 | 0.108 | Trout 59, loses a fit |
| H | **13 D4 items only** | 13 | k-means | **1,365** | 2 in all 10 | — | best cognitive set |
| I | A4/A5/A6 + flags + access + days + miles | 32 | Gower + PAM | 1,135 | 2 | 0.186-0.241 | split is pond + private access |
| J | days, miles, tournament, guide, livescope, access | 7 | k-means | 1,172 | 3-6 | 0.22-0.60 | outlier isolation |
| K | days, miles, access, reg_uniform, reg_sitesupport | 6 | k-means | 1,107 | 2-6 free, **3 fixed** | 0.209-0.301 | best behavioural set |

### Findings

| # | Finding |
|---|---|
| F50 | **Every attitudinal configuration returns k = 2** under the mode rule, and the gap statistic favours k = 1 in most fits. The reason is structural: a unimodal cloud always admits a first split and never a second. Searching further attitudinal sets is not expected to change this |
| F51 | ARI between configurations is near zero — **0.01** between the 13- and 11-input sets on the same respondents, **0.07** between the 13- and 24-input sets. The input decision, not the data, determines who is in which type |
| F52 | The k = 2 solutions are **not** acquiescence splits. Mean per-input gap is 0.66-0.84 SD against an overall level gap of only 0.09-0.54 SD, and in Panfish, Crappie and Trout the inputs split roughly half-and-half in direction |
| F53 | **Behavioural/binary sets re-derive their own inputs.** Set I split on pond use (77pt) and private access (57pt); set J produced Type = tournament (100%), Type = guide (100%), Type = no public access; set K produced access × days. High silhouette here is not evidence of emergent structure |
| F54 | Rare binaries (tournament 3.4%, guide 6.4%) create **outlier-isolation clusters** — Catfish 167/10 and Channel catfish 110/4 — which violate the 15 floor at k = 2 with no remedy |
| F55 | **Fixing k removes a large instability.** Under free selection set K gave Bass k = 2 and Largemouth k = 6 on 88% the same anglers; at fixed k = 3 they give 119/115/26 and 118/90/22. Agreement counts of 1-2 of 5 mean the "mode" is often just the tie-break |
| F56 | `reg_uniform` and `reg_sitesupport` **do not differentiate** the set-K clusters (means within 0.19 across types) while costing ~250 respondents of retention |
| F57 | `mclust` BIC picks 3-6 components on every set. It fits density shape, not separation, and it drives the mode whenever the other criteria disagree; removing it sends the tie-break to the gap statistic's k = 1. Consider excluding it from any vote |
| F58 | `Scales.csv` in this project contains **no D4 rows**; the D4 sub-scales live in the sibling `D4ScaleAnalysis` project. Using them would cross a project boundary and reverse D40/D63 |
| F59 | Dropping `D4j`/`D4l` raises retention by 218, of which **190 is the No preference group alone**. No species group becomes newly eligible. Under behavioural sets No preference becomes eligible and **Trout falls below 60** |
| F60 | The set-K k = 3 solution clears the 15 floor in 9 of 10 fits; only Moronides fails (45/15/7) |

### Decisions

| # | Decision | Date |
|---|---|---|
| D136 | The Overall fit's universe **excludes No preference**: everyone who named a preferred species. 1,576 raw, 1,124 clusterable under set D. Still not the union of the group fits, since unbannered `B1` answers are included | 2026-09-21 |
| D137 | **Silhouette and bootstrap Jaccard are not reported**; `fpc` therefore leaves the render. A per-species-section diagnostics table carries k, WSS %, silhouette, Calinski-Harabasz, gap, BIC, smallest type size and which criteria favour each k. Superseded in part by Q36 — the user later asked for silhouette and gap in that table, so it now holds everything **except** Jaccard | 2026-09-21 |
| D138 | k comes from the **mode of five criteria** (elbow, silhouette, Calinski-Harabasz, gap, mclust BIC), ties to the smaller k, 15-per-type floor as an override, agreement count reported. See F55/F57 before relying on it | 2026-09-21 |
| D139 | A **rule-based typology** (waterbody × craft × access, giving 4-5 comparable types across all 17 groups with no k selection) was drafted, costed and **declined by the user** | 2026-09-21 |

### Q36 — the open decision

Four candidates, all one edit plus one render away. Nothing is committed under any of them.

1. **days + distance + access, k = 3 fixed** (set K minus the inert regulation scales). Stable k,
   9 of 10 fits clear the floor, silhouette 0.21-0.30, highest retention of the behavioural sets.
   Types are access × effort and should be described as such.
2. **Set K as tested**, keeping the regulation scales on substantive grounds despite F56.
3. **13 D4 items, k = 2** (set H). The only family whose types are genuine multivariate patterns
   rather than restatements of inputs. Best retention (1,365), all ten groups, gap statistic
   supportive in three fits.
4. A further set the user names.

**Methodological note to carry forward:** ten configurations in, choosing inputs by which yields
better separation is a specification search. Whatever is chosen needs a **substantive**
justification in Appendix B — these measures define an angler type for management purposes — not a
metric one, or the chapter reads as tuned.

### Also still open from the previous session

Q33 (Appendix B has no clustering section), Q34 (Overall fit placement), Q35 (terse `Labels.csv`
row labels), the nine remaining sub-sections, and step 5 guided text.

---

## Handoff — Chapter 5 paused on Q36 (2026-09-22, prompt 105)

**One sentence: Chapter 5's machinery is built and working, its Walleye template renders, and the
whole chapter is blocked on a single unanswered question — which questions define an angler
type (Q36).**

### Read this before anything else

⚠️ **Do not render, and do not treat the current .docx as current.** `Ch5Functions.R` implements
the 13-input Likert spec; the chapter prose in `PreferredSpeciesReport.rmd` still describes the
*previous* 14-input spec (fourteen measures, `log1p`, within-fit standardization, days fished as
an input, the elbow rule). A render today produces correct tables under incorrect text. Commit
`1db56bb` is the last fully consistent state; `600af04` is the current WIP.

⚠️ **The render baseline is 79 tables / 55 images / 7 landscape / 0 leaked markup**, not the
81/55/8/0 quoted in older sections of this file. Commit `17cf703` commented out Chapter 4 content
and suppressed 2 tables and 1 landscape section (F45). Commented-out markdown still contains the
literal text `CreateFlex(` and `sect_landscape()`, so **count rendered output, not call sites**.

⚠️ **Do not re-run the input-set exploration.** Ten configurations are recorded in the previous
section with retention, k, silhouette and verdict. The conclusion is stable and re-deriving it is
pure cost.

### State at handoff

| Part | State |
|---|---|
| `Ch5Functions.R` | Complete and working. Fits, k selection, size table, profile table, diagnostics table, three figure builders |
| Chapter 5 intro + "Coverage of the fourteen inputs" | Written, renders, **prose now stale** |
| Walleye sub-section | Built and verified under the old spec: 25 profile rows, 11 of 35 characteristics passing |
| Nine remaining sub-sections | Not written, deliberately — they were held back pending Q36 |
| Appendix B clustering section | Not written (Q33) |
| Chapters 1-4, appendices | Untouched throughout. No `D4RowSpec` call site was modified |

Last verified render (old spec): 3.1 min, 82 tables / 58 images / 8 landscape / 0 leaked markup,
i.e. +3/+3/+1/0 against the corrected baseline.

**Git.** Branch `master`, remote `keithhurley/Analysis`. Three unpushed commits: `15b7a17` (Ch4),
`17cf703` (comment-out), `1db56bb` and `600af04` (Ch5). **Never push without asking.** Use
`git -c safe.directory=F:/Survey/Analysis ...`; plain git refuses. Only `.posit/assistant/settings.json`
is left dirty, and it is not ours to commit.

### Q36 — the decision that unblocks everything

Four candidates, detailed in the previous section. In short: **days + distance + access at fixed
k = 3** (stable, 9 of 10 fits clear the floor, silhouette 0.21-0.30, types are access × effort);
the same plus the two regulation scales (which F56 shows are inert); **13 D4 items at k = 2** (the
only family whose types are genuine multivariate patterns rather than restatements of the inputs);
or a set the user names.

The governing trade-off, which does not need re-deriving: **attitudinal inputs give two weakly
separated but genuine types; behavioural inputs give more, better separated types that turn out to
be the binary flags fed in.** Whatever is chosen needs a *substantive* justification in Appendix B,
not a metric one — ten configurations in, a metric justification reads as tuned.

### How to switch input sets — the whole recipe

This is a small, localized edit. Everything downstream is input-agnostic.

| To change | Edit |
|---|---|
| Which variables define types | `ch5.input.vars` (Field / Block / Fallback) and `ch5.input.blocks` |
| Transforms | `Ch5InputFrame()` — currently plain `as.numeric`, no transform |
| Standardization | `Ch5Fit()` uses `as.matrix(Ch5InputFrame(...))` raw. **Mixed-metric inputs need `Ch5Scale()` instead**, which also guards the zero-variance columns that occur in small fits |
| Variables moving between blocks | A variable that stops being an input must be **added to `Ch5ExternalSpec()`**, and one that becomes an input must be **removed** from it, or it will be both circular and tested |
| Fixed k instead of the mode | `Ch5Fit()` calls `Ch5KSelect()`; add a `kFixed` argument that bypasses `sel$kUse`. Keep the 15-per-type floor check |
| Figure facets | `Ch5ProfilePlot()` facets on `ch5.input.blocks` |

**Then the prose must follow.** The three inline paragraphs after the `ch5Setup` chunk name the
input count, the transform, the standardization, the k rule, the exclusions and the
variance-explained range. The "Coverage of the fourteen inputs" heading also names a count. None of
it updates itself.

### Order of work for the next conversation

1. Get Q36 answered. Nothing else is worth doing first.
2. Make the localized code edit above; refit and print k, sizes and floor compliance for all fits
   **before** writing any prose. Fitting all ten takes 15-30 seconds.
3. Rewrite the three intro paragraphs and the coverage heading to match.
4. Rebuild the Walleye sub-section, render, verify against 79/55/7/0, and stop for a read-through.
5. Only then generate the remaining nine sub-sections. Generate them with an R script that splices
   into the .rmd between sentinel comments rather than hand-writing ~450 lines — the pattern is
   lead-in, size table, elbow figure, profile figure, landscape profile table, dumbbell figure, and
   it is identical per species.
6. Appendix B clustering section (Q33), then step 5 guided text across Chapters 1-5.

### Workflow gotchas, each of which has cost time at least once

| Gotcha | Handling |
|---|---|
| `scale()` returns `NaN` on a zero-variance column, and `kmeans` then fails with "NA/NaN/Inf in foreign function call" | Use `Ch5Scale()`. Constant binaries do occur in the smaller fits (e.g. `tourn` in Moronides) |
| `base.summary.medians()` returns `CIlower`/`CIupper`, **not** `Lower`/`Upper` | Getting it wrong fails silently — empty cells and only a warning |
| `p.adjust()`'s default `n` counts `NA` entries | Pass `n = sum(!is.na(P))` explicitly, as `Ch5Meta()` does |
| `mclust::Mclust()` errors with "could not find function mclustBIC" without the package attached | Call `mclust::mclustBIC()` directly and read the best G off the matrix. Do **not** `library(mclust)` — it masks `purrr::map` |
| `clusGap()`'s internal k-means defaults to `iter.max = 10` and warns about non-convergence | Pass `FUN = function(x, k) kmeans(x, k, nstart = 25, iter.max = 100)` |
| Six `A4` fields are entirely `NA` in 2025 | Already handled by `Ch5AllNAFields()`; reported via `Ch5DroppedFields()` rather than vanishing |
| `PreferredSpeciesFunctions.R` is auto-reformatted on write (F7) | Re-read before editing. This is why the Ch5 layer is a separate file |
| Large heredoc appends silently truncate (F34) | Use the write/edit tools, not `cat >> file << EOF` |
| The obvious leaked-markup regex gives false positives (F41) | Use `<w:t(?: [^>]*[^/>])?>.*?</w:t>` and then search the extracted runs |
| `block_section()` describes the section that **ends** at that point (D92) | Portrait break before a wide table, landscape break after |
| Render fails with `pandoc ... error 1` | Check for `~$eferredSpeciesReport.docx` — the document is open in Word |
| Two adjacent tables merge in Word (D33/D98) | Every table gets its own lead-in paragraph |

### Still open, independent of Q36

| # | Item |
|---|---|
| Q33 | Appendix B has no clustering section. Needs: inputs, transforms, standardization, the k rule as a stated convention, the size floor as a stated convention, the unweighted-fit/weighted-reporting gap, complete-case retention, the circularity of input p-values, the combined Holm family at 0.20, and the continuum caveat (F50) |
| Q34 | Placement of the Overall fit — assumed to close the chapter, since "place it first" was declined |
| Q35 | Terse `Labels.csv` row labels ("Catch Something", "Physical and psycological", "Total (Jan-Oct)"). They are Chapter 3's labels, so they are at least consistent; one contains an upstream typo that is not ours to fix |
| Q22 | Outcome-dimension multiplicity in Chapter 1 (F8) — flagged, never implemented |
| Q24 | Appendix A heading year — 2025 or 2026 |
| Q25 | Appendix B wording: the inherited "roughly 9x too tight" passage reads as contradicting the newer scale-invariance note |
| Q32 | Chapter 4 reliability presentation — offered as a full table, never answered explicitly |
| — | Step 5, guided text development, now covering Chapters 1-5 |
| — | Four unpushed commits |

### Prompt for the next conversation (Chapter 5, resuming) — SUPERSEDED by the LPA section below

```
Resume the PreferredSpecies report, Chapter 5 "Angler Type Profiles". Read AGENTS.md and the two
most recent sections of PROGRESS.md in f:/Survey/Analysis/PreferredSpecies -- the input-set
exploration and the handoff. They carry the standing directive, decisions D1-D139, findings
F1-F60, and the open question Q36. Do not re-derive any of it and do not re-run the ten input-set
configurations; they are recorded with their results.

Three things to know before you touch anything. The report must NOT be rendered as it stands:
Ch5Functions.R implements the 13-input spec while the chapter prose still describes the old
14-input spec, so a render gives correct tables under wrong text. The render baseline is 79
tables / 55 images / 7 landscape / 0 leaked markup, not the 81/55/8/0 quoted in older sections.
And Chapters 1-4 and both appendices are finished and must not be touched.

Chapter 5 is blocked on one decision, Q36: which questions define an angler type. Ask me for it
first and do not assume an answer. The candidates and the trade-off behind them are in
PROGRESS.md -- attitudinal inputs give two weakly separated but genuine types, behavioural inputs
give more and better separated types that re-derive the flags fed in. Once I answer, follow the
"Order of work for the next conversation" section: localized code edit, refit and show me k and
cluster sizes BEFORE writing prose, update the three intro paragraphs, rebuild the Walleye
sub-section, render, verify, and stop for my read-through before generating the other nine.

Ground rules, settled, do not re-litigate:
- Technician voice. Report the numbers; I interpret them.
- Universe is surveyYear == 2025 with !is.na(B1), n = 1,915 (D23). The Overall fit excludes No
  preference (D136).
- The preferred groups overlap (D31) -- never total them. Displayed N is raw and unweighted; CIs
  use Kish effective N. Clustering is unweighted, all reporting is weighted, and the gap is
  disclosed.
- One combined Holm family at alpha = 0.20 over the D4 items and the other characteristics;
  clustering inputs always shown with no p because they are circular (D127).
- Landscape profile tables with value +- CI (D128); block_section brackets per D92; portrait
  figures 6.5in wide.
- Reuse the Ch5* layer; it is input-agnostic apart from the handful of places listed in the
  switch-input-sets recipe.
- Never edit anything upstream (CrossTabTables/, TrendTables/, BaseFunctions*, Data/).

Keep PROGRESS.md and PROMPTS.md current, logging every prompt verbatim. The rendered .docx is
tracked (D109), so commit it alongside the source; use `git -c safe.directory=F:/Survey/Analysis
...`. There are four unpushed commits -- ask me before pushing anything. Tell me when an action
would save tokens (save to file, start a new conversation).
```

---

## Chapter 5 redesigned — latent profile analysis (2026-09-22, prompts 106-108)

**One sentence: k-means clustering is abandoned for Chapter 5 (Q36 never resolved); it is replaced
by ONE latent profile analysis on the whole universe, with class membership crosstabbed by the 17
preferred-species columns. All design questions Q37-Q45 are answered below. No code has been written
yet; the console was used read-only.**

⚠️ **Context-loss incident.** Prompts 106-107 were a console-only discussion and the questions
Q37-Q45 were never written to this file — only the user's answers reached `PROMPTS.md`. The next
conversation had to ask the user to re-paste the transcript. **Rule from now on: record design
questions here at the moment they are posed, not at handoff.**

### Design (replaces D120's per-species fits)

One mixture model on all 1,915 respondents (subject to D145). Types are therefore defined once and
are directly comparable across species. Chapter 5 output per species column becomes: share of each
latent class (weighted %, Kish CI, raw N), plus an Unassigned share. Profile/characteristic tables
describe the classes for the whole universe, not per species.

### Questions posed and answered

| # | Question | Answer (prompts 107-108) |
|---|---|---|
| Q37 | Adopt the one-fit design in place of D120? | **Yes** |
| Q38 | Indicators: 13 D4 items, behavioural, or mixed? | **11 scale scores**: `attitude_catch/numbers/size/harvest`, `motivation_natural/pp/social/resource`, `reg_comprehension/sitesupport/uniform` |
| Q39 | 5 categories or collapsed to 3? | "Do not collapse" — **moot**: the indicators are continuous means, so the model is LPA, not LCA |
| Q40 | Install `poLCA`? | `poLCA` OK but `tidySEM` preferred. **Only `tidySEM` installed** — `poLCA` cannot take continuous indicators |
| Q41 | Universe 1,576 or all 1,915 with No preference as a column? | **All 1,915; No preference is a column** |
| Q42 | Enumeration rule: BIC subject to 5% smallest-class floor and 0.60 entropy, labelled a convention? | **Yes.** (User wrote "Q24 agreed"; confirmed in prompt 108 to mean Q42) |
| Q43 | Reporting floor for species columns? | **30 on Kish effective N**, cite NCHS after confirming (confirmed, F65). **Suppress** columns below it (prompt 110, D146) |
| Q44 | Within-class variance/covariance structure? | **Assistant's recommendation adopted** (D144) |
| Q45 | Minimum scales answered to be fitted? | **At least 7 of 11** |

### Decisions

| # | Decision | Date |
|---|---|---|
| D140 | **D120 is replaced**: one fit on the whole universe, class membership crosstabbed by species. D136 (Overall fit excludes No preference) is superseded — there is no separate Overall fit and No preference is a banner column | 2026-09-22 |
| D141 | **Indicators are the 11 derived scale scores** (Q38). Because they are continuous, the model is a **Gaussian mixture / latent profile analysis** fitted with `tidySEM::mx_profiles()` on `OpenMx`. `tidySEM` 0.2.12 and `OpenMx` 2.22.11 installed 2026-09-22 (`OpenMx` did not arrive as a dependency and was installed separately). `poLCA` not installed | 2026-09-22 |
| D142 | **Universe: all 1,915** (`surveyYear == 2025`, `!is.na(B1)`), No preference included as a column (Q41) | 2026-09-22 |
| D143 | **Enumeration convention (Q42):** among candidate fits, choose the minimum BIC **subject to** smallest class ≥ 5% of fitted cases and entropy ≥ 0.60. Stated in Appendix B as a convention, not a test | 2026-09-22 |
| D144 | **Variance structure (Q44):** fit 1-6 classes under two structures — `variances = "equal", covariances = "zero"` and `variances = "varying", covariances = "zero"`. Apply D143 across both; report both in the diagnostics table. Free covariances rejected (77 extra parameters per class; 462 at k = 6) | 2026-09-22 |
| D145 | **Inclusion (Q45): fitted cases must have ≥ 7 of the 11 scales answered → 1,718 fitted.** The 197 others (78 with 1-6 scales, 119 with 0) are reported as **Unassigned**, never dropped from the species columns. Within the 1,718, partial missingness is handled by FIML in `OpenMx` | 2026-09-22 |
| D146 | **Reporting floor (Q43): 30 on Kish effective N**, decided **before** fitting so it cannot be tuned to the results. Affected columns: Northern pike (26.9), Blue catfish (22.6), Yellow perch (11.1), Muskellunge / Tiger musky (7.3). **Option C — SUPPRESS those four columns in Chapter 5 tables and figures (user, prompt 110); 13 species columns shown.** Suppression is reporting-only: those respondents stay in the LPA fit. Blue catfish and Yellow perch respondents remain visible inside the Catfish and Panfish / Sunfish family columns; Northern pike and Muskellunge are "Species (family split)" with no family column in the 17, so their respondents appear in no displayed Chapter 5 species column (they still count in the overall class sizes). This departs from Chapters 1-4 (which suppress nothing) and must be disclosed in Appendix B and in a Chapter 5 table note naming the suppressed columns and their effN. Assistant had recommended B (flag). Citation: Parker JD, Talih M, Malec DJ, et al. *National Center for Health Statistics Data Presentation Standards for Proportions.* Vital Health Stat 2(175), 2017. Appendix B must disclose that only the effective-sample-size element is adopted; this report's intervals are Wald on Kish effN, not Korn-Graubard, and the CI-width criteria are not applied | 2026-09-22 |
| D147 | **Weights:** D125 stands — fit unweighted, report weighted, disclose the gap. `OpenMx::mxData()` has a `weight` argument; whether `mx_profiles()` passes it through is unverified (F63). Revisit only if verified cheaply | 2026-09-22 |
| D148 | **Assignment:** modal posterior class. Report entropy, mean posterior of the assigned class, and assignment certainty by scales-answered band (11 / 10 / 7-9) | 2026-09-22 |

### Findings

| # | Finding |
|---|---|
| F61 | **Scale-score completeness (of 11):** 11 → 1,373; 10 → 209; 7-9 → 136; 1-6 → 78; 0 → 119. Cumulative at ≥ 7: **1,718** (89.7% of 1,915) |
| F62 | **Banner raw n / Kish effN:** Walleye 499/402.3; Bass 357/296.1; No preference 339/272.3; Largemouth 316/261.5; Panfish 236/189.1; Catfish 228/180.7; Crappie 181/144.2; Channel cat 151/118.9; Trout 90/70.2; Moronides 85/66.1; Flathead 50/40.7; Bluegill 43/34.5; Smallmouth 41/34.8; Northern pike 32/26.9; Blue cat 27/22.6; Yellow perch 12/11.1; Muskellunge 8/7.3. From `BannerSizeTable(d)` |
| F63 | `mx_profiles()` weight passthrough to `mxData(weight = )` **unverified** |
| F64 | The 11 scale scores are **configuration C** of the input-set exploration (k-means k = 2, silhouette 0.139). LPA is a different model, not a re-run; F57 (mclust BIC chose 3-6 components on earlier sets) is the closer precedent |
| F65 | NCHS citation confirmed (web, 2026-09-22): standard requires sample size **and** effective sample size ≥ 30, plus Korn-Graubard CI-width criteria (absolute ≥ 0.30 suppress; relative > 130% suppress when absolute width is 0.05-0.30) |
| F66 | `Ch5Functions.R` (k-means, 13 D4 inputs) is **obsolete** under D140-D141. Its table/figure builders may still be reusable for size, profile, diagnostics and dumbbell output once fed LPA class assignments; its fitting layer is not |

### Console recipe used (read-only, reproduces F61/F62)

```r
source("../BaseFunctions_2025_UPDATED.R"); source("../CrossTabTables/CrossTabTableFunctions.R")
source("PreferredSpeciesFunctions.R")
load("../../Data/DataAggregation1/aggregateData_20260624.rData")
d <- d |> filter(surveyYear == 2025) |> filter(!is.na(B1)) |> add_scale_scores()
d$B1banner <- AssignBannerGroup(d$B1); stopifnot(nrow(d) == 1915)
lpa_vars <- c(attitude.vars, motivation.vars, "reg_comprehension", "reg_sitesupport", "reg_uniform")
d$n_scales <- rowSums(!is.na(d[, lpa_vars]))
```

### Order of work for the next conversation

1. ~~Confirm D146 flag-vs-suppress~~ — **done: suppress** (prompt 110). All Q37-Q45 closed; start at step 2.
2. New file `Ch5LPA.R` (leave `Ch5Functions.R` in place until the replacement renders): input frame
   with the ≥ 7 gate, `mx_profiles()` grid 1-6 × 2 structures, D143 selection, posterior
   assignment, class-by-species table via `base.summary.percent.selectOne(d, class, B1banner)`.
3. **Print the diagnostics grid (BIC, entropy, smallest class %) and the selected k to the console
   and stop for the user before any prose.** Fitting 12 mixtures on 1,718 × 11 should take under a
   few minutes; if `OpenMx` is slow, reduce `nstart`-equivalents rather than the grid.
4. Rewrite Chapter 5 intro prose (still describes the 14-input k-means spec — see the previous
   handoff warning), build the tables/figures, render, verify against **79/55/7/0** plus the
   Chapter 5 increment. *(This line was found truncated at "79/5" on 2026-09-22, prompt 111 —
   the F34 heredoc truncation; completed here from the handoff baseline above.)*

---

## Chapter 5 step 2 — `Ch5LPA.R` built, grid fitting (2026-09-22, prompt 111)

### New file `Ch5LPA.R` (sourced after `PreferredSpeciesFunctions.R`)

| Function | Role |
|---|---|
| `ch5.lpa.*` constants | 11 indicators, ≥ 7 gate, classes 1-6, `equal`/`varying` variances, 5% / 0.60 thresholds, seed **5813**, effN floor 30, cache path |
| `Ch5LPAGate()` | adds `lpa_n_scales`, `lpa_fitted`; row order preserved |
| `Ch5LPAFrame()` | 11 numeric columns, gated rows, NAs left for FIML |
| `Ch5LPAFitOne()` / `Ch5LPAFitGrid()` | one `mx_profiles()` call per structure × k, seed set per model, run on a PSOCK cluster (one worker per model); stops if any fit is `NULL`; progress to `Ch5LPA_fit.log` |
| `Ch5LPARunOrLoad()` | caches fits to `Ch5LPA_fits.rds`, keyed on a fingerprint of the fitted frame, so the render never refits |
| `Ch5LPADiagnostics()` | per fit: parameters, LL, **BIC = −2LL + p·ln(n)**, relative entropy, smallest class n and %, min mean posterior, status, D143 pass flags |
| `Ch5LPASelect()` | D143: min BIC among admissible fits across both structures |
| `Ch5LPAAssign()` | modal class → `lpa_class` factor (`Class 1..k`, `Unassigned`), `lpa_maxpost` |
| `Ch5LPACertainty()` | D148 bands 11 / 10 / 7-9 |
| `Ch5ClassBySpeciesLong()` | numeric class × 17 overlapping columns + Overall via `D4RowSpec()` and `base.summary.percent.selectOne()`, with column N, Kish effN, D146 `Suppressed` flag. `Ch3SelectOneTable(d, "lpa_class")` gives the formatted version unchanged |

### Decisions

| # | Decision | Date |
|---|---|---|
| D149 | Class-by-species uses the 17-column `D4RowSpec()` walk, **not** `base.summary.percent.selectOne(d, class, B1banner)` as the previous order-of-work said: `B1banner` is the 8-level non-overlapping factor and would not produce the species columns | 2026-09-22 |
| D150 | Column % in the class-by-species table are of **all** respondents in the column, with `Unassigned` as a level (D145: never dropped) | 2026-09-22 |
| D151 | The 12 fits run **in parallel** (one PSOCK worker per model). The estimator is unchanged — tidySEM's own `mx_profiles()` → `run_mx()` with its hard-coded simulated annealing — so the plan's fallback (reduce starts) was not needed | 2026-09-22 |

### Findings

| # | Finding |
|---|---|
| F67 | **`tidySEM::run_mx()` returns `NULL` with only a message unless `OpenMx` is attached** (`library(OpenMx)`, not `requireNamespace`). The first grid ran 72 min, produced 12 `NULL`s and a 351-byte cache. `Ch5LPA.R` now attaches `OpenMx` (masks `Matrix::%&%`, `expm`) and `Ch5LPAFitGrid()` stops on any `NULL` |
| F68 | `run_mx()` wraps every mixture in `mxComputeSimAnnealing()` before `mxRun()`. **`equal_2` alone took 11.4 min** single-threaded, status 0, −2LL ≈ 42,584.6. OpenMx reports 1 thread on this machine; 28 cores detected |
| F69 | `summary(fit)$BIC.Mx` is OpenMx's df-adjusted BIC (−93,320.9 for `equal_2`), **not** −2LL + p·ln(n). Diagnostics compute the conventional form explicitly |
| F70 | `mixture_starts()` initializes k ≥ 2 from a **single** `kmeans()` run on kNN-imputed data (no `nstart`), so starts depend on the seed; local-optimum sensitivity is untested |

### Status (superseded — see prompt 112 below)

Grid launched 18:33 as a background `callr` job. It died ~18:38 when the console session was
restarted (F71); only the two k = 1 fits completed.

---

## Chapter 5 step 2 — persistence and detached rerun (2026-09-23, prompt 112)

User: track the fits and save whatever is needed so the grid never has to be rerun; seed
sensitivity (F70) deferred.

### Decisions

| # | Decision | Date |
|---|---|---|
| D152 | **Storage.** Each model is saved on completion to `Ch5LPA_fits/<variances>_<k>.rds` (`list(key, fit, fitted_at)`); a rerun skips any model already saved for the same frame fingerprint, so the grid is resumable. `Ch5LPABuildResults()` distils them into **`Ch5LPA_results.rds`** (per model: −2LL, parameters, N, status, posterior matrix, modal class, `omxGetParameters()`, `table_results()`). **The report reads only the results file via `Ch5LPALoadResults()`, which never fits.** Tracked in git: `Ch5LPA.R`, `Ch5LPA_run.R`, `Ch5LPA_results.rds`, `Ch5LPA_fit.log`. **Ignored: `Ch5LPA_fits/`** because every `MxModel` embeds the 1,718 × 11 respondent-level data and the repo currently holds no respondent-level data — pending user confirmation. Also ignored: `Ch5LPA_job.out`, and the empty `Ch5LPA_fits.rds` from F67 (can be deleted; not deleted without asking) | 2026-09-23 |
| D153 | **Fitting is launched only through `Ch5LPA_run.R`, detached:** `system2(file.path(R.home("bin"), "Rscript.exe"), "Ch5LPA_run.R", stdout = "Ch5LPA_job.out", stderr = "Ch5LPA_job.out", wait = FALSE)`. Survives console restarts. Rerunning the same command resumes | 2026-09-23 |

### Findings

| # | Finding |
|---|---|
| F71 | A `callr::r_bg()` job is killed when the parent R session ends; the restart overnight killed the first parallel grid after k = 1 |
| F72 | `class_prob(fit, type = "individual")$individual` posterior columns are **not** named `CPROB*`; for k = 1 the column name is blank. `Ch5LPAPosterior()` now takes every column except `predicted` and names them `class1..k` |
| F73 | k = 1 under both structures: 22 parameters, −2LL 44,240, BIC 44,404, identical as expected |

### Status

Detached grid started **2026-09-23 21:50**, fitting the 10 models k = 2-6 × 2 structures (k = 1 already
saved). Progress: `readLines("Ch5LPA_fit.log")`; the last line reads "Results built" when done. Then:
`models <- Ch5LPALoadResults(Ch5LPAFrame(d)); lpa_diag <- Ch5LPADiagnostics(models); Ch5LPASelect(lpa_diag)`,
show the grid, **stop for the user**, commit `Ch5LPA_results.rds`. *(Done — see prompt 113.)*

---

## Chapter 5 step 3 — diagnostics grid (2026-09-24, prompt 113)

Grid finished 2026-09-23 23:27; results built 23:27:44. Wall time per model (parallel): 30 min
(`equal_2`) to 97 min (`varying_6`).

| Model | p | LL | BIC | Entropy | Smallest n | Smallest % | Min mean post. | Status | Admissible |
|---|---|---|---|---|---|---|---|---|---|
| equal_1 | 22 | −22,120 | 44,404 | — | 1,718 | 100.0 | — | 0 | yes |
| equal_2 | 34 | −21,292 | 42,838 | 0.707 | 805 | 46.9 | 0.912 | 0 | yes |
| equal_3 | 46 | −20,881 | 42,105 | 0.724 | 394 | 22.9 | 0.851 | 0 | yes |
| equal_4 | 58 | −20,507 | 41,446 | 0.761 | 303 | 17.6 | 0.853 | 0 | yes |
| equal_5 | 70 | −20,286 | 41,092 | 0.750 | 262 | 15.3 | 0.799 | 0 | yes |
| **equal_6** | 82 | −20,179 | **40,969** | 0.747 | 120 | 7.0 | 0.759 | 0 | **yes — selected** |
| varying_1 | 22 | −22,120 | 44,404 | — | 1,718 | 100.0 | — | 0 | yes |
| varying_2 | 45 | −21,223 | 42,781 | 0.723 | 754 | 43.9 | 0.908 | 0 | yes |
| varying_3 | 68 | −20,775 | 42,056 | 0.746 | 436 | 25.4 | 0.867 | 0 | yes |
| varying_4 | 91 | −20,430 | 41,538 | 0.771 | 297 | 17.3 | 0.848 | 0 | yes |
| varying_5 | 114 | −19,229 | 39,308 | 0.836 | 244 | 14.2 | 0.859 | **6** | no |
| varying_6 | 137 | −18,863 | 38,747 | 0.822 | 228 | 13.3 | 0.800 | **6** | no |

`equal_6` class sizes (modal): 362 / 347 / 292 / 286 / 311 / 120.

### Findings

| # | Finding |
|---|---|
| F74 | **D143 selects `equal_6`.** BIC decreases monotonically with k in both structures through k = 6, so the selected model sits at the **upper edge of the D144 grid**; the D143 floors (5%, 0.60) do not bind anywhere in the grid |
| F75 | `varying_5` and `varying_6` return **OpenMx status 6** (first-order optimality conditions not met) and are excluded by `Admissible` (status 0/1 only). Both have lower BIC than every admissible fit; had they counted, `varying_6` would be selected |

### Decisions

| # | Decision | Date |
|---|---|---|
| D154 | `Ch5LPA_fits/` (12 files, 6.0 MB) and `Ch5LPA_results.rds` (0.77 MB) **both tracked** (user, prompt 113), reversing the D152 exclusion. The repo now holds respondent-level scale scores (no identifiers) inside the saved models. Empty `Ch5LPA_fits.rds` deleted (user-approved) | 2026-09-24 |

### Open for the user

| # | Question |
|---|---|
| Q46 | ~~BIC minimum at the grid edge (F74): accept `equal_6` or extend to k = 7+?~~ **Answered prompt 114 → D155** |
| Q47 | Status-6 fits (F75): keep excluded, or attempt a rescue refit (e.g., `mxTryHard` from the saved estimates) before selection? |

---

## Chapter 5 step 3b — grid extended to equal_7, equal_8 (2026-09-24, prompt 114)

### Decisions

| # | Decision | Date |
|---|---|---|
| D155 | **Grid extended under `equal` variances only, to k = 7 and 8** (answers Q46). `varying` stays at 1-6. `Ch5LPA.R`: new constant `ch5.lpa.extend.equal <- 7:8`; new `Ch5LPAGridSpec()` returns the explicit 14-model list; `Ch5LPAModelNames()` and `Ch5LPAFitGrid()` read it (the `classes` argument is gone). Same seed (5813), estimator, frame and D143 selection rule. The 12 saved fits have a matching fingerprint and were skipped (dry run checked 12 saved, 2 to fit) | 2026-09-24 |

### Status

Detached job launched **2026-09-24 10:54** (D153 command, stdout to `Ch5LPA_job_k78.out`; `.gitignore` pattern widened to `Ch5LPA_job*.out`). Fitting `equal_7`, `equal_8` on 2 workers. When `Ch5LPA_fit.log` ends in a new "Results built" line, `Ch5LPA_results.rds` holds 14 models. Then: `Ch5LPADiagnostics(Ch5LPALoadResults(lpa_frame))`, `Ch5LPASelect()`, show the grid, **stop for the user**. If BIC is still falling at `equal_8`, the edge issue (F74) recurs, so flag it and don't extend again unasked. Q47 (status-6 `varying_5/6`) is still open, and the selection is conditional on it. *(Done — job finished 11:54 in 60 min, both status 0; see prompt 115.)*

---

## Chapter 5 step 3c — extended grid results and Q47 diagnosis (2026-09-24, prompt 115)

| Model | p | BIC | Entropy | Smallest % | Min mean post. | Status | Admissible |
|---|---|---|---|---|---|---|---|
| equal_6 | 82 | 40,969 | 0.747 | 7.0 | 0.759 | 0 | **yes — still selected** |
| equal_7 | 94 | 40,775 | 0.766 | 4.1 | 0.776 | 0 | no (5% floor) |
| equal_8 | 106 | 40,717 | 0.769 | 3.3 | 0.788 | 0 | no (5% floor) |

### Findings

| # | Finding |
|---|---|
| F76 | **The D143 5% floor binds at k = 7 and 8** (it did not bind anywhere in the 1-6 grid, F74). BIC keeps falling through `equal_8`; `equal_6` is the largest admissible `equal` model, so the selection no longer depends on where the grid ends |
| F77 | **`varying_5` and `varying_6` are degenerate (boundary) solutions, not just unconverged.** In each, one class's variance on `reg_sitesupport` (indicator 10) has collapsed: `v510` = 5.5e-6, `v610` = 3.6e-7, gradient ≈ 1.5e8 on that parameter. Variances are unbounded below. The class (`varying_5` class 5, n = 271; `varying_6` class 6, n = 277) has **every non-missing member at exactly 5** on `reg_sitesupport` (267/267, 273/273), the scale ceiling. The likelihood has no upper bound as that variance goes to 0, so their lower BIC (F75) comes from the singularity |
| F78 | The saved fits' compute plan is plain SLSQP gradient descent (tidySEM runs `mxComputeSimAnnealing()` first, then sets `x@compute <- NULL` before `mxRun`), so any `mxTryHard` rescue starts from the saved estimates without re-annealing |

### Q47 — no refit run; decision needed

A plain `mxTryHard` rescue (the request) would jitter around the same singularity. If it returned status 0 it would pass `Admissible` and win selection on an artifact, so it was **not run** until the user chooses: keep excluded (documented as degenerate), plain `mxTryHard` anyway, or refit `varying` with a variance lower bound (a spec change that needs Appendix B disclosure).

### Git

`safe.directory` exception added for `F:/Survey/Analysis` (global config, user-requested). Ch5 changes committed; `.posit/assistant/settings.json` left out of the commit (not Ch5).
