# Chapter renumbering: new Chapter 4 (Species Sought)

New numbering: 1 Groupings, 2 Scale questions, 3 Crosstabs, **4 Species Sought (new)**, 5 Satisfaction (was 4), 6 Angler Type Profiles (was 5). Appendices unchanged.

Line numbers are from `PreferredSpeciesReport.rmd` after the edits and are a guide only. Search for the 'Old text' in your draft. Each snippet shows 55 characters before and 45 after the change (inline R code is shown with backticks as apostrophes).

**Order matters when doing find and replace by hand:** change 5 to 6 first, then 4 to 5. Otherwise old Chapter 4 text becomes 5 and is then wrongly bumped to 6. Do not use replace-all on 'Chapter 4' or 'Chapter 5' without checking each hit.

## 1. Headings

| Old | New |
|---|---|
| `# Chapter 5: Angler Type Profiles` | `# Chapter 6: Angler Type Profiles` |
| `# Chapter 4: Satisfaction` | `# Chapter 5: Satisfaction` |
| (none) | `# Chapter 4: Species Sought` inserted after the end of Chapter 3 (before the Satisfaction heading), the last Chapter 3 section being 'Age' |
| Appendix B: `## Satisfaction comparisons in Chapter 4` | `## Satisfaction comparisons in Chapter 5` |
| Appendix B: `## Angler type profiles in Chapter 5` | `## Angler type profiles in Chapter 6` |

## 2. Text references (old text -> new text)

| Line | Old text | New text |
|---|---|---|
| 32 | # Chapter 5 is the latent profile analysis (D140-D156).  | # Chapter 6 is the latent profile analysis (D140-D156).  |
| 725 |  size and number allowed to be harvested (D4i to D4l); Chapter 4 returns to those five, together with the sea |  size and number allowed to be harvested (D4i to D4l); Chapter 5 returns to those five, together with the sea |
| 1121 | rteen items by preferred group, under the same rule as Chapters 3 and 4: a group is described as differing from the  | rteen items by preferred group, under the same rule as Chapters 3 and 5: a group is described as differing from the  |
| 1125 | ther than with harvest rules; the paired comparison in Chapter 4 places it more precisely, in the number of f | ther than with harvest rules; the paired comparison in Chapter 5 places it more precisely, in the number of f |
| 1127 | l by this screen, but the sharper paired comparison in Chapter 4 shows them to be the only group that rates t | l by this screen, but the sharper paired comparison in Chapter 5 shows them to be the only group that rates t |
| 1619 | t on the preferred-fish success item in Chapter 2, and Chapter 4 examines the satisfaction items as a set. | t on the preferred-fish success item in Chapter 2, and Chapter 5 examines the satisfaction items as a set. |
| 2045 | # Chapter 4: Satisfaction | # Chapter 5: Satisfaction |
| 2072 | # Long tables behind the Chapter 4 narrative, built by the same function as the | # Long tables behind the Chapter 5 narrative, built by the same function as the |
| 2338 | # Chapter 5: Angler Type Profiles | # Chapter 6: Angler Type Profiles |
| 2342 | # reweighted, so nothing in Chapters 1-4 changes. The model is never fitted | # reweighted, so nothing in Chapters 1-5 changes. The model is never fitted |
| 2396 | Chapters 1 to 4 divided every question in the survey by the  | Chapters 1 to 5 divided every question in the survey by the  |
| 2402 | effective N and raw unweighted counts displayed, as in Chapters 1 to 4.")' | effective N and raw unweighted counts displayed, as in Chapters 1 to 5.")' |
| 2981 | The narrative in Chapters 3 and 4 describes a preferred group as different fro | The narrative in Chapters 3 and 5 describes a preferred group as different fro |
| 2981 | reby shown to be typical. Within-angler differences in Chapter 4 (size against numbers, and caught against allo | reby shown to be typical. Within-angler differences in Chapter 5 (size against numbers, and caught against allo |
| 2987 | g Across the Items, applies the interval screen above. Chapter 5 is described in its own section below. In Ch | g Across the Items, applies the interval screen above. Chapter 6 is described in its own section below. In Ch |
| 2987 | e. Chapter 5 is described in its own section below. In Chapters 1 to 4 every value quoted in the narrative is compu | e. Chapter 6 is described in its own section below. In Chapters 1 to 5 every value quoted in the narrative is compu |
| 2989 | ## Satisfaction comparisons in Chapter 4 | ## Satisfaction comparisons in Chapter 5 |
| 2991 | 'r paste0("Chapter 4 reports no new estimator. Its group means ar | 'r paste0("Chapter 5 reports no new estimator. Its group means ar |
| 2993 |  runs from 1, Strongly Disagree, to 5, Strongly Agree. Chapter 4 reports A9 as 6 minus the recorded response  |  runs from 1, Strongly Disagree, to 5, Strongly Agree. Chapter 5 reports A9 as 6 minus the recorded response  |
| 2993 | 0.06 in Chapter 3 appears as 3.7 plus or minus 0.06 in Chapter 4.")' | 0.06 in Chapter 3 appears as 3.7 plus or minus 0.06 in Chapter 5.")' |
| 2997 | 'r paste0("Chapter 4 also compares what each angler catches with  | 'r paste0("Chapter 5 also compares what each angler catches with  |
| 2999 | 'r paste0("No significance test is reported in Chapter 4, and no adjustment for multiple comparisons  | 'r paste0("No significance test is reported in Chapter 5, and no adjustment for multiple comparisons  |
| 3001 | ## Angler type profiles in Chapter 5 | ## Angler type profiles in Chapter 6 |
| 3037 | 'r paste0("Chapter 5 groups anglers using a latent profile analys | 'r paste0("Chapter 6 groups anglers using a latent profile analys |
| 3043 | Unassigned. They are not dropped: they remain in every Chapter 5 row, and Unassigned appears as its own colum | Unassigned. They are not dropped: they remain in every Chapter 6 row, and Unassigned appears as its own colum |
| 3045 | tering the model are the same values summarized in the Chapter 5 profile figures and profile means table.")' | tering the model are the same values summarized in the Chapter 6 profile figures and profile means table.")' |
| 3061 | e fitted). The full table of fitted models is given in Chapter 5.")' | e fitted). The full table of fitted models is given in Chapter 6.")' |
| 3075 | ve-N confidence interval, and the profile means in the Chapter 5 figures and profile means table are weighted | ve-N confidence interval, and the profile means in the Chapter 6 figures and profile means table are weighted |
| 3079 | 'r paste0("Chapter 5 is the only chapter of this report that with | 'r paste0("Chapter 6 is the only chapter of this report that with |
| 3081 | , " rows fall below the floor and are not shown in the Chapter 5 tables: ", paste0(ch5.appb.supp$Column, " (" | , " rows fall below the floor and are not shown in the Chapter 6 tables: ", paste0(ch5.appb.supp$Column, " (" |
| 3081 | amily row, so their respondents appear in no displayed Chapter 5 species row. ") else "", "Where a profile ha | amily row, so their respondents appear in no displayed Chapter 6 species row. ") else "", "Where a profile ha |
| 3085 | 'r paste0("The Chapter 5 table of profiles on other survey questions  | 'r paste0("The Chapter 6 table of profiles on other survey questions  |
| 3091 | 'r paste0("No significance test is reported in Chapter 5, and the profile shares in different rows ar | 'r paste0("No significance test is reported in Chapter 6, and the profile shares in different rows ar |
| 3097 | "For the same reason, the paired difference columns in Chapter 4 carry two decimal places rather than the one | "For the same reason, the paired difference columns in Chapter 5 carry two decimal places rather than the one |

## 3. Unchanged on purpose

- All references to Chapters 1, 2 and 3 alone, including 'Chapters 1-3' (Chapter 3 intro, the Chapter 5 setup comment), 'Chapters 2 and 3' (Appendix B) and 'reported in Chapter 3' (Chapter 5 and 6 text).
- Chunk names and function names (`ch4Setup`, `ch4TextHelpers`, `Ch4*`, `Ch5LPA.R`, `Ch5Images.R`): identifiers, not reader-facing.
- Captions and notes in `PreferredSpeciesFunctions.R` that say 'Chapter 3' or 'Chapter 2' (A9 note, inventory table).

## 4. Code comments (not reader-facing)

| File | Old | New |
|---|---|---|
| `PreferredSpeciesFunctions.R` (~1254) | 'Chapter 4 and 5 figures' | 'Chapter 5 and 6 figures' |
| `PreferredSpeciesFunctions.R` (~1975) | 'a Chapter 4 cell' | 'a Chapter 5 cell' |
| `Ch5LPA.R` lines 1, 50, 817 | 'Chapter 5' | 'Chapter 6' |
| `Ch5Images.R` line 1, `Ch5LPA_run.R` line 1 | 'Chapter 5' | 'Chapter 6' |
| `.gitignore` lines 21, 25 | 'Chapter 5' | 'Chapter 6' |
| `PreferredSpeciesReport.rmd` line 32 | 'Chapter 5 is the latent profile analysis' | 'Chapter 6 is ...' (included in the table above) |

## 5. Project documents (not yet updated)

`AGENTS.md` (sections 0 and 6), `PROGRESS.md` and `TEXT_AUDIT.md` still use the old numbering. Add a decision entry rather than rewriting history.

## 6. Effects to check after inserting

- Render baseline (`DocxCounts()`) changes only when the new chapter adds tables and figures. Renumbering alone leaves 98 / 85 / 10 / 0.
- If the new chapter uses the interval rule, 'Chapters 3 and 5' (lines 1121 and 2981) becomes 'Chapters 3, 4 and 5'. Currently it does not apply the rule (top three shown regardless of intervals).
- Cross-chapter statements 'Chapters 1 to 5' (three places) now include the new chapter. Confirm that wording suits it.
