# PreferredSpecies report: text audit (2026-09-30)

Scope: all narrative text in the rendered `PreferredSpeciesReport.docx` (render of 2026-09-30, `DocxCounts()` 98 / 96 / 10 / 0). Line numbers refer to `PreferredSpeciesReport.rmd` as it stood at the audit. **No report files were changed.** This file is the only output.

Method: rendered prose (395 paragraphs, about 137,000 characters, roughly 20,000 words, tables and figures excluded) was read in full. Suspect numbers were checked against the rendered tables. Family-card text was audited from its source (`fam.text`, L2409-2415) because the cards are not extractable as paragraphs.

Contents: 1 Synopsis, 2 Accuracy findings, 3 Consistency findings, 4 Style and depth, 5 Register of interpretive statements (expert-opinion audit), 6 Polish recommendations, 7 Limits of this audit.

---

## 1. Synopsis of the textual part

| Part | rmd lines | What the text does |
|---|---|---|
| Chapter 1, Species groupings | 131-426 | States the universe (1,915 of 2,822), why the list is grouped, the four selection rules, five candidate families with one paragraph each, and the final 15-column banner. Live figures via `ch1Helpers`. Interpretive voice is concentrated in the rules rationale (L172) and the Moronides and Esocids verdicts (L330, L364). |
| Chapter 2, Scale questions | 427-855 | Orientation paragraph, then 13 items with a table, figures and two short paragraphs each (26 paragraphs, hard-coded, not edited in Step 5). Closing section "Reading Across the Items" (L836-854) is live, asserted and uses the interval rule. |
| Chapter 3, Crosstabs | 856-1682 | Preamble with the reading rule, then 22 sections with one lead paragraph each (live, asserted). Mostly lists of interval-screened separations, with a short interpretive clause in about half. |
| Chapter 4, Satisfaction | 1683-1965 | Interpretive introduction, six-item matrix, size-vs-number comparisons for catch and harvest, and the new "Caught versus allowed" section. Live and asserted. Contains the most management-pointed text (Wiper). |
| Chapter 5, Angler type profiles | 1966-2466 | Introduction (new, L2024-2028), LPA technical front matter, six profile descriptions (two paragraphs each, photo, persona sketch), class-by-species table, family figure and six family cards with management implications, closing caveat (L2458). Live and asserted. |
| Appendix B | 2472-2720 | Methods, including the Step 5 reading rule, paired comparisons and the Chapter 5 model. Numbers-only voice. |

Storyline a reader takes away, stated as the text states it: a few species dominate (Walleye/Sauger, Largemouth bass, No preference about 60%); anglers broadly support regulations, more for numbers than size, and will trade harvest for size more readily than the reverse; Walleye/Sauger anglers are the least satisfied with success and the most harvest-oriented; Wiper anglers are size-oriented and rate what they may keep below what they catch; Bass anglers are release-oriented and size-focused; No preference anglers are the least engaged. Chapter 5 recasts the same anglers as six attitude profiles and shows every species mixes all six.

No chapter ties these threads together, and there is no front summary (see 4 and 6).

---

## 2. Accuracy findings

**Status 2026-10-01: A1 to A12 done** (PROGRESS D223, D229). Q58 was settled by trimming E25, E26, E40, E41, the Trout card, and removing E18 (D230); the register entries below describe the text as it stood at the audit.

Severity: **High** = a number or claim contradicts the report's own tables; **Medium** = overstated or loosely stated; **Low** = wording.

| # | Sev | Location | Finding | Suggested fix |
|---|---|---|---|---|
| A1 | High | Ch2, "If I could catch larger fish..." paragraph, L644 | Text says overall mean **3.6**; the table and the Chapter 2 closing section (L844) both give **3.5** (3.5 ± 0.06). Agree 52% and disagree 14% match the table. | Change 3.6 to 3.5. |
| A2 | High | Ch2, size and number "allowed to harvest" paragraphs, L764-766 | Northern pike D4j is written **3.0** ("lowest (3.0; 38% agree, 40% disagree)" and "about equally (3.0 each)"). The table gives **2.9 ± 0.42**; Chapter 2 closing (L850) and Chapter 4 (L1832) say 2.9. Agree and disagree shares do match. | Change to 2.9; the "about equally" comparison becomes 3.0 caught against 2.9 allowed (caught value not re-checked). |
| A3 | High | Appendix B, "The rule is not applied everywhere", L2609 | Says every narrative value in Chapters 1-4 comes from the same objects as the tables and is checked at build. The 26 Chapter 2 per-item paragraphs are hard-coded numbers inside `paste0()`, with no live values and no assertions. A1 and A2 are the direct consequence. | Either make the 26 paragraphs live and asserted, or reword L2609 to exclude them explicitly. |
| A4 | Medium | Ch3, Satisfaction, L1328 | "The same ordering appears in the preferred-fish satisfaction item in Chapter 2." Only the low end matches (Walleye/Sauger). The high end differs: Chapter 3 lists Wiper, Bluegill/Sunfish, Trout; the Chapter 2 success item has White bass, Trout, Channel catfish highest (Chapter 4 L1808 confirms). | Say Walleye/Sauger is lowest on both and drop "same ordering". |
| A5 | Medium | Ch3, Methods L1449 and Ice Fishing L1455 | Ice Fishing is said to "repeat" the Methods ice-fishing result. They are two items (Methods N = 1,865; Ice Fishing N = 1,845). Values differ slightly (overall 17.7 and 17.8; Panfish 32.6 and 32.1; Walleye/Sauger 26.3 and 27.4). Northern pike separates only in Ice Fishing (41.1 ± 18.8), not in Methods (32.7 ± 17.7). | Say "agrees in direction with" and note pike separates only in the direct question. |
| A6 | Medium | Appendix B, scale gate, L2547 | "Across the eight scales used here ... 1,653 to 1,715." The report uses eleven scales (three regulation scales included). The range is unchanged across all eleven (Overall rows: 1,653 to 1,715), so only the count and the first sentence are stale. | Replace "eight" with "eleven" and mention regulation scores. |
| A7 | Medium | Ch2 per-item, "below the midpoint" phrasing, L668, L740, L788 | Several paragraphs call a group "the only group averaging below the scale midpoint" (or "joined below ... only by") while a neighbouring group prints as 3.0 (the midpoint), for example pike 3.0 and Largemouth bass 3.0 in the size-caught item (L740), Channel catfish 3.0 in the harder-to-catch item (L668), and Walleye/Sauger 3.0 in the number-caught item (L788). Probably true at two decimals but reads as a contradiction. Not re-checked against unrounded means. | Show two decimals where a group is called below 3.0, or reword. |
| A8 | Medium | Ch5 introduction, L2024-2028 (mine) | "in proportions that differ by species" is weak for Catfish: no profile's share differs from Overall by 5 points or more (the card says so). "some anglers who prefer walleye fish to fill the freezer" also reads as "walleye fish". | "in proportions that vary across groups, more for some than others"; "some anglers who prefer walleye keep fish for the freezer". |
| A9 | Low | Ch2 opening question text (rendered; the period is added at build, not typed in the `.rmd`) | Double punctuation in the question text: "...during 2025?." | Strip the trailing period added after the question mark. |
| A10 | Low | Ch2 orientation paragraph, L524 | "Chapter 4 returns to those five as a set": Chapter 4 handles six items (A9 plus five D4). | "returns to those five, with the season item (A9), as a set". |
| A11 | Low | Ch2, L446 and the routing note that follows | One paragraph says the preferred-species question was "not a strict gate" on the battery; the next says the battery "was routed to anglers who named a preferred species". Both are true for different gates but read as a conflict. | Name the two gates separately (blank B1 versus the No preference answer). |
| A12 | Low | Ch3, Conservation Officer L1375 | "above the overall (28%)" reads as if 28% were the overall rate (19%). | "(28%, against 19% overall)". |

Checked and found consistent: universe counts (1,915 / 2,822 / 907 / 60 / 1,855), population figures (234,125 and 171,760, 0.734 rescale), selection-rule counts (9/27/27 tests, 3 of 27, 3 of 9), 6 + 6 + 3 = 15 banner, Chapter 4 paired figures against Chapter 2 and 3, Chapter 5 class shares against Chapter 3 overall rates (days 30.2, ice 17.7%, sonar 14.5%, guide 8.1%, age 46.0), the Appendix B fitted-respondent arithmetic (1,373 + 209 + 136 = 1,718; 78 + 119 = 197), and the Chapter 5 model exclusions (7 and 8 equal, 5 and 6 varying).

---

## 3. Consistency findings

**Status 2026-10-01: C1 to C12 done** (scale names use the printed table and figure labels; see PROGRESS D225 to D228). C8 is fixed locally in `PreferredSpeciesFunctions.R`, so the crosstab files are untouched. Line numbers elsewhere in this file predate that pass and have shifted.

| # | Topic | Detail | Suggested fix |
|---|---|---|---|
| C1 | Scale names | The same scales carry different names by chapter. Chapter 3 headings: Psychological and Physiological, Uniform Preference, Site-Specific Support, Fishery Resource. Chapter 5 text and cards: challenge and relaxation, physical and psychological (report-only override, D180), Simplification, catch outcomes. | Pick one name per scale and add a one-row glossary, or use the Chapter 3 names throughout. |
| C2 | Species formatting | Chapter 2 per-item text writes "Walleye/Sauger", "Bluegill/Sunfish", "Panfish/Sunfish"; the rest of the report writes "Walleye / Sauger" etc. | Normalise once the per-item text is made live. |
| C3 | Decimal precision | Per-item text mixes one and two decimals ("3.05 each" beside "Smallmouth (3.1)"; 4.05; 3.15; 3.21). | One rule: one decimal, two only when needed to separate ties, stated once. |
| C4 | Negative zero | Chapter 4 prints "-0.00 ± 0.04" (L1908) and "0.00 ± 0.04" in the next paragraph. | Normalise the sign in the formatter. |
| C5 | Dashes (D205: none) | 3 em dashes: L932 (Chapter 3 preamble), L1217 (Techniques), L1248 (Access). About 10 en dashes used as parenthetical dashes, mainly in the Chapter 2 per-item text. | Replace with commas, colons or sentence breaks. |
| C6 | Repeated phrasing | "worth having in view when wiper length limits are reviewed" appears in Chapter 2 (L848) and Chapter 4 (L1960). "The direction is more dependable than the size" appears twice in Chapter 4. 11 of the 13 second paragraphs in Chapter 2 open with "No group's change between 2018 and 2025 was large enough to appear in the figure above." | Keep each once, or vary. The Chapter 2 opener could become one chapter-level sentence. |
| C7 | Spelling variety | British forms ("programme", "licence", "organised", "favour", "behaviour") alongside US forms ("favorite", "organizes", "favorably"). The audience and the survey are Nebraska. | Standardise on US spelling. |
| C8 | Inherited caption defects | "+-" for plus-minus; missing full stop before "These results were weighted" in the median caption and before "Reverse-scored items" text; contrast-table caption printed twice per family in Chapter 1 (once generic, once prefixed "Days fished, same species comparisons."). The first three come from read-only `CrossTabTableFunctions.R`. | Override locally in the report, or accept and note. Do not edit the crosstab files. |
| C9 | Two reads of priorities | Chapter 2 numbers-over-size item (L620) infers that catching fish at all matters more than catching bigger ones. The closing section (L844) says anglers give up harvest for size more readily than the reverse. Different items, but a reader meets both. | Reconcile in the closing section in one sentence. |
| C10 | No preference caution | Per-item text treats No preference results as patterns (for example D4a 3.4 versus 3.2, 50 respondents). The closing section (L854) says the row describes a small self-selected subset. | Carry the caution to the first per-item mention. |
| C11 | Class 6 size | 7.0% of fitted respondents (n = 120, Appendix B) and 6.0% of respondents (weighted, Chapter 5). Class 5 has n = 311 but a smaller weighted share than Class 3 (n = 292). Correct, but two bases are in play. | One sentence in the profile key explaining weighted share versus fitted count. |
| C12 | Forward references | Chapter 3 Park Entry Permit says "in the Methods section" without saying it is later in the chapter. | "later in this chapter". |

---

## 4. Style and depth

**Depth is uneven.**
- Chapters 1, 4 and the Chapter 2 closing section are interpretive, specific and asserted. Chapter 3 gives each section one lead paragraph: accurate, but mostly a list of separations with an occasional interpretive clause.
- The Chapter 2 per-item paragraphs are the weakest link: formulaic, static, unasserted, and the only place with wrong numbers (A1, A2).
- Chapter 5 front matter (model choice, certainty, means) is technical and reaches the interpretive material only after a long run. The new introduction helps; the six profile descriptions carry the substance.

**No cross-chapter synthesis.** The threads are all present but never joined. Example of what is currently left to the reader: Walleye/Sauger anglers are the least satisfied with success (Ch2, Ch4), concentrate in the harvest-minded Class 1, and are the boat, sonar and out-of-state group (Ch3, Ch5). There is also no front summary for administrators.

**Density.** Several paragraphs exceed 150 words (Ch1 L172; Ch3 Waterbody, Methods; each Chapter 5 second persona paragraph with about ten "X% against Y% overall" pairs). The "against Z overall" pattern appears about 60 times in Chapter 5.

**Tone.** Mostly plain and natural, as D205 asks. Phrases that lean stronger than the screens support: "sharp" (L1300, "sharper paired comparison"), "strongly supports" (L848), "most consequential single figure in the chapter" (L846), "far larger than that ... can be trusted" (L1962).

---

## 5. Register of interpretive statements (for expert audit)

Statements that go beyond reciting an estimate or describing a screened separation. Type key: **M** management implication or recommendation-like; **P** persona or label; **I** inference about cause or meaning not measured by the survey; **J** analyst judgement about method or strength of evidence. Basis: what in the report the statement rests on. Risk: my view of how far it exceeds that basis (Low, Moderate, Higher).

### Chapter 1

| ID | Line | Statement (short) | Type | Basis | Risk |
|---|---|---|---|---|---|
| E1 | 148 | Answers of the No preference group describe a segment "species-specific management does not reach directly". | M | Definition of the group | Low |
| E2 | 164 | Walleye, largemouth bass, crappie and channel catfish programmes each speak to a measurable share; rare species held by too few to describe "however locally important". | M | Weighted shares, n | Low |
| E3 | 172 | Bonferroni "leans toward combining"; a family that fails does so "on strong evidence"; a family that passes may hide undetected differences. | J | Test design, n as low as 8 | Low |
| E4 | 228 | Largemouth and smallmouth point estimates "sit close together", so Bass is combined. | J | 9 contrasts, smallest adjusted p 0.399, n = 41 | Low |
| E5 | 262 | Yellow perch's inclusion "rests on the absence of contrary evidence"; the Panfish column "will largely reflect crappie anglers". | J | n = 12; 181 of 236 | Low |
| E6 | 296 | Catfish homogeneity "supports treating catfish as a single constituency for programme-level purposes". | M | Smallest adjusted p 0.795 | Moderate |
| E7 | 330 | Wiper as "size-oriented, release-inclined"; White bass "more harvest-oriented". | P | Three adjusted contrasts (resource motivation, size attitude, harvest attitude) | Moderate; "release-inclined" is inferred from a lower harvest-attitude score |
| E8 | 364 | Muskellunge: "a small, highly engaged, size-focused constituency that pike anglers do not describe well"; differences clear the threshold "regardless" of n = 8. | I, J | Three adjusted contrasts on 8 respondents | Higher; estimates from n = 8 that clear a strict threshold tend to be inflated |
| E9 | 423 | Family columns are "the appropriate reference for programme-level questions"; species columns show whether the family "conceals variation worth acting on". | M | Design of the banner | Low |

### Chapter 2

| ID | Line | Statement (short) | Type | Basis | Risk |
|---|---|---|---|---|---|
| E10 | 548 | Walleye/Sauger gap "may point to a difference in how reliably each species can be caught rather than ... how much anglers enjoy the pursuit". | I | Item means only | Moderate |
| E11 | 620 | Tilt toward numbers regulations "may indicate that ... catching fish at all matters more than catching bigger ones". | I | Two item means, unscreened | Moderate; see C9 |
| E12 | 670 | "Broad, shallow drift toward agreement" (harder to catch, 2018 to 2025). | I | 3.2 to 3.3, no group change shown | Moderate |
| E13 | 718 | Travel distance and shortage of places "may be two readings of the same underlying access picture". | I | Rank overlap across two items | Moderate |
| E14 | 766 | Wiper "complaint ... is with the rules rather than the fish". | I, M | Size caught 4.0 against allowed 3.3 | Moderate; later supported by the Chapter 4 paired result |
| E15 | 790 | Number caught "weighs at least as heavily" as size in overall success. | I | Rank overlap across items | Moderate |
| E16 | 844 | "Anglers want more and bigger fish, and will give up harvest to gain size more readily than they will give up size to gain harvest." | I | Two item means with intervals apart | Moderate |
| E17 | 846 | Walleye/Sauger "discontent is with catch rates and access rather than with harvest rules"; below-neutral success "is the most consequential single figure in the chapter". | I, J | Non-separation on four items; paired result in Ch 4 | Higher for the superlative; moderate for the rest |
| E18 | 848 | Wiper is "size-oriented outlier", "a tension worth having in view when wiper length limits are reviewed". | M | Chapter 4 paired size gap, n = 35 | Moderate (Q58) |
| E19 | 850 | Pike: "a size-focused reading: a group unwilling to give up size and dissatisfied with the size the rules let it keep". | I | Two screened separations, n = 31 | Moderate |
| E20 | 852 | Bluegill/Sunfish "least constrained constituency". | P | Five screened separations, n = 40 | Low to moderate |
| E21 | 854 | No preference row "describes a small, self-selected subset". | J | 50 of 339 answered | Low |

### Chapter 3

| ID | Line | Statement (short) | Type | Basis | Risk |
|---|---|---|---|---|---|
| E22 | 1111 | Out-of-state rates "consistent with the travel distances they report". | I | Two screened results | Low |
| E23 | 1149 | Park permit separation "tracks the boat-oriented groups". | I | Cross-section comparison | Low |
| E24 | 1248 | Pike: "little private-water access in this group". | I | 87% public-only, n = 25 | Low to moderate |
| E25 | 1300 | Medians separate "local-water constituencies from travelling ones, which bears on where a regulation change would actually be felt". | M | Distance medians | Moderate |
| E26 | 1356 | Sonar uptake concentrates in boat-borne groups, "so any future rule on the technology would land unevenly". | M | Sonar rates by group | Moderate |
| E27 | 1375 | Officer contact "consistent with the two groups' effort and boat use". | I | Cross-section comparison | Low |
| E28 | 1429 | Effort concentrates in bass and catfish; No preference "the most casual segment of the licence base". | P | Days fished | Moderate |
| E29 | 1455 | Ice-fishing ordering "maps onto the species reachable through the ice". | I | Species ecology, not measured | Moderate; relies on outside knowledge |
| E30 | 1477 | "The companionship motive is shared across species preferences." | I | Non-separation on the social scale | Moderate; absence of a screened difference is not evidence of sameness (the report says so elsewhere) |
| E31 | 1538 | Pike low on uniform rules "consistent with a group fishing a small set of specialized waters". | I | One screened separation | Higher; speculative mechanism |
| E32 | 1598 | Bass "most release-oriented constituency"; walleye and white bass "most harvest-oriented". | P | Attitude scale means | Low to moderate |
| E33 | 1652 | Group differences elsewhere "are therefore partly demographic as well as behavioural". | I | Two screened gender separations | Higher; "therefore" is stronger than the evidence |
| E34 | 1664 | Age gradient "worth holding alongside" effort and attitude results "when deciding whether a group contrast reflects the species or the cohort". | J | Age means | Low |

### Chapter 4

| ID | Line | Statement (short) | Type | Basis | Risk |
|---|---|---|---|---|---|
| E35 | 1794 | "Managers usually want to know how satisfied anglers are, but one satisfaction score does not say what is behind it." | J | Framing | Low |
| E36 | 1814 | "On average, then, the harvest side draws less complaint than the catch side." | I | Two paired overall differences | Moderate; the allowed items may be rated higher for reasons other than satisfaction with the rules |
| E37 | 1832 | Bass "cares about size and is less satisfied with the size it catches". | I | Ch 3 attitude plus size-caught mean | Low to moderate |
| E38 | 1884 | For Wiper, Flathead, Catfish, Walleye/Sauger "the weaker side of the catch is how many fish they get". | I | Paired differences, unadjusted | Moderate |
| E39 | 1912 | Catch differences "look like a signal about fishery performance" while harvest-rule satisfaction is "fairly even". | M | Paired differences, non-flags | Moderate |
| E40 | 1956 | "Where anglers are dissatisfied, the place to look first is the fishery." | M | 6 and 11 of 15 groups flagged, unadjusted | Moderate to higher; nested, overlapping groups |
| E41 | 1960 | Wiper shortfall "is a question about length limits more than about the fishery, and worth having in view when wiper length limits are reviewed." | M | Paired size gap +0.67 ± 0.40, n = 33 | Higher; single group, post hoc (disclosed in Appendix B) |
| E42 | 1962 | Overall pattern "can be trusted" because flagged groups far outnumber chance. | J | 30 unadjusted comparisons | Moderate; informal multiplicity argument |

### Chapter 5

| ID | Line | Statement (short) | Type | Basis | Risk |
|---|---|---|---|---|---|
| E43 | 2024-2028 | "A species column is a mixture of people"; "managing for a species therefore means serving a mix of angler types." | I, M | All six profiles present in every family group | Low |
| E44 | `Ch5LPA.R` (ch5.class.labels) | Six profile labels (harvest-minded, relaxed, regulation-savvy catch-and-release sport, all-in enthusiast, low-involvement, conservation-minded purist). | P | Eleven scale scores | Moderate; labels assign meaning beyond the scores (text says so, L2239) |
| E45 | 2251 | Class 1 persona: "fishes for a meal, measures a trip by what goes in the cooler, finds a patchwork of lake-specific rules confusing". | P, I | Harvest and regulation scales only | Higher; no catch-to-eat or rule-confusion item per se |
| E46 | 2263 | Class 2 persona: "goes for the day out, the company and the water; a fishless trip is not a failed trip". | P, I | Outdoors 3.8, social 3.8 against overall 3.7 and 3.6 | Higher; persona stronger than "slightly above average" |
| E47 | 2275 | Class 3 persona: "often a bass angler", who "lets it go". | P, I | Low harvest attitude; Bass 30% of the class | Moderate to higher; 70% are not bass anglers; harvest attitude is not observed release |
| E48 | 2287 | Class 4 persona: "fishing is a central hobby: every reason to go matters". | P | Highest on all four motivations | Low to moderate |
| E49 | 2299 | Class 5 persona: "fishing is incidental"; caution that low ratings may reflect scale use. | P, J | Lowest motivations | Low (caution stated) |
| E50 | 2311 | Class 6 persona: "values the experience and well-managed waters over the catch"; "catching and keeping fish are close to irrelevant to it". | P, I | Attitude means 1.6 to 2.4 on a 1 to 5 scale | Higher; 2.4 on size is not "close to irrelevant" |
| E51 | 2409-2415 | Six family-card paragraphs, each ending in a management implication: Walleye/Sauger (harvest opportunity, plain-language limits), Bass (receptive to size-focused rules), Panfish (balance harvest and experience), Catfish ("management for the general angler"), Trout (access and stocking timing over catch rates), No preference (recruitment and retention). | M | SD departures, profile shares, small n for Trout | Moderate to higher; flagged as interpretive at L2458; Trout rests on small n |
| E52 | 2432 | "Differences of emphasis rather than of kind." | J | No family dominated by one profile | Low |
| E53 | 2458 | Implications are interpretive; shares are associations. | J | Caveat | Low |

### Appendix B (methodological judgements)

| ID | Line | Statement (short) | Type | Risk |
|---|---|---|---|---|
| E54 | 2587 | Bonferroni over Holm "for simplicity"; Tukey "not valid here"; Benjamini-Hochberg unsuited to go/no-go decisions. | J | Low |
| E55 | 2605 | The interval screen "is more conservative than a two-sided test at the 5 percent level" for a single comparison. | J | Low; a standard result when the intervals are of similar width, depends on width ratio (the text says so) |
| E56 | 2709 | Treating assigned profile as known "tends to make the profiles look more alike ... differences are more likely understated than overstated". | J | Moderate; direction is typical for misclassification but not checked here |

Counts: 56 entries (some carry two types). Highest-risk cluster: E8, E31, E33, E41, E45, E46, E50, E51.

---

## 6. Polish recommendations (in priority order)

1. **Fix A1 and A2, and decide A3.** Two wrong numbers sit in hard-coded text. Best fix is to make the 26 Chapter 2 per-item paragraphs live and asserted like the rest (also resolves C2, C3, C5, C6 and A7). Otherwise correct the numbers and reword the Appendix B sentence.
2. **Correct A4 to A6, A8, A10 to A12.** Short wording edits.
3. **Add a front summary and a closing synthesis.** One page each: the four or five findings an administrator should carry away, and the cross-chapter thread per group (Walleye/Sauger, Wiper, Bass, Pike, No preference). Chapter 5 closing synthesis was deliberately not added; a report-level one would cover it.
4. **Settle Q58.** Management-pointed lines are in E6, E9, E14, E18, E25, E26, E39 to E41 and E51. Options: keep as drafted, trim to a plain statement of the finding, or move them to one "Implications" section so the expert audit has one place to look.
5. **Temper the Higher-risk persona and inference lines** (E8, E31, E33, E41, E45, E46, E50). For example replace "therefore partly demographic" with "and women are a larger share of two groups", and "close to irrelevant" with "rated low".
6. **One naming pass** (C1) and **one spelling and dash pass** (C5, C7).
7. **Inherited caption defects** (C8): fix locally or note as accepted.
8. **Consider trimming Chapter 5 persona second paragraphs** to the four or five largest contrasts, pointing to the table for the rest.

Housekeeping noticed, not acted on: `PreferredSpeciesReport - Copy.rmd` (46 KB, dated 2026-09-18) sits in the project folder, alongside the 199 KB live `.rmd`. `git status` from the shell failed with a "dubious ownership" error on `F:/Survey/Analysis` (file system does not record ownership); nothing was changed.

---

## 7. Limits of this audit

- Rendered prose was read; the docx was **not opened in Word**, so layout, landscape sections, icons and card appearance are unchecked (Q22 remains open).
- Family-card text was audited from source, not from the rendered cards.
- Numbers quoted in live text are assumed correct where the build asserts them; I re-checked only the items named in section 2 against the rendered tables. The Chapter 2 per-item paragraphs (26) were checked selectively, not exhaustively: A1 and A2 were found by cross-reading, so others may exist. A full check needs the paragraphs made live.
- Accuracy here means agreement between text and the report's own tables. Whether the survey items measure what the interpretive statements say they do is for the expert reviewer.
- I did not judge statements as significant or causal; the register records how far each goes beyond its stated basis.
