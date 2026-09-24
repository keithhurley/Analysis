# SUPERSEDED — inserted into `PreferredSpeciesReport.rmd` 2026-09-24 (prompt 120)

> The report's Appendix B section "Angler type profiles in Chapter 5" is now authoritative; it
> computes every figure inline. This file is kept only as the review record and is not maintained.

# DRAFT — Appendix B text for Chapter 5 (latent profile analysis)

> Draft for review (prompt 116). Not yet in `PreferredSpeciesReport.rmd`. Figures are hard-coded
> from the 2026-09-24 console run; when this is moved into the report, each should become an
> inline `r` expression computed from `Ch5LPA_results.rds` and `d`, following the style of the
> existing Appendix B sections. Decision/finding references in brackets are for the user and
> are removed on insertion.

## Angler type profiles in Chapter 5

### The model

Chapter 5 groups anglers using a latent profile analysis, a finite mixture model in which each
respondent is assumed to belong to one of *k* unobserved profiles and, within a profile, each
indicator is normally distributed. The indicators are the eleven scale scores used elsewhere in
this report: the four angler-attitude scales (catch, numbers, size, harvest), the four motivation
scales (physical and psychological, natural environment, social, fishery resource), and the three
regulation scales (comprehension, site-specific, simplification). Within each profile the eleven
indicators are treated as uncorrelated, so each profile is described by eleven means and a set of
variances. [D141, D144]

Models were fitted with the **tidySEM** package (version 0.2.12), function `mx_profiles()`, which
estimates by maximum likelihood in **OpenMx** (version 2.22.11). tidySEM obtains starting values
from a k-means partition, refines them by simulated annealing, and then runs gradient-based
optimization. A fixed random seed (5813) is set before each model so the fits are reproducible.
Starting values come from a single k-means run, and sensitivity of the solution to other starting
values has not been examined. [D151, F68, F70, F78]

### Who was fitted

`Of the 1,915 respondents in the analysis sample, 1,718 (89.7 percent) answered at least seven of the eleven scales and were included in the fit. The threshold was set before fitting. Where a fitted respondent is missing one to four scales, the model uses the scales that were answered (full-information maximum likelihood); no values are imputed. The remaining 197 respondents -- 78 who answered one to six scales and 119 who answered none -- are reported as Unassigned. They are not dropped: they remain in every Chapter 5 column, and Unassigned appears as its own row, so each column's percentages are of all respondents in that column.` [D145, D150, F61]

Each scale score carries the same completeness gate described under *Scale scores and the
completeness gate* above; the scores entering the model and the scores summarized in the profile
figure are the same values.

### Choosing the number of profiles

Two within-profile variance structures were fitted: one in which every profile shares the same
variance for a given indicator (*equal*), and one in which each profile has its own variances
(*varying*). Under both structures, models with one to six profiles were fitted, and the *equal*
structure was then extended to seven and eight profiles because the Bayesian information criterion
was still decreasing at six. [D144, D155]

The number of profiles was chosen by a stated convention rather than a statistical test: among
all fitted models, the one with the lowest BIC, restricted to models in which the smallest profile
holds at least 5 percent of fitted respondents and the relative entropy is at least 0.60. BIC is
computed as

$$BIC = -2\log L + p \ln(n)$$

with *p* the number of estimated parameters and *n* = 1,718. (OpenMx's default summary reports a
different, degrees-of-freedom-adjusted BIC; it was not used.) Relative entropy summarizes how
distinctly respondents are assigned:

$$E = 1 - \frac{\sum_i \sum_j -\hat{p}_{ij} \ln \hat{p}_{ij}}{n \ln k}$$

where $\hat{p}_{ij}$ is respondent *i*'s estimated probability of belonging to profile *j*. It runs
from 0 to 1, with 1 indicating that every respondent is assigned with certainty. Only fits that
OpenMx reports as converged (status code 0 or 1) are eligible. [D143, F69]

`The selected model has six profiles with equal variances: BIC 40,969, relative entropy 0.747, smallest profile 120 respondents (7.0 percent of those fitted). The full table of fitted models is given in Chapter 5.` [F74]

### Models that were fitted but not eligible

`Four fits had a lower BIC than the selected model and were excluded under the convention above.`

`The seven- and eight-profile equal-variance models (BIC 40,775 and 40,717) converged normally, but their smallest profiles hold 4.1 and 3.3 percent of fitted respondents, below the 5 percent floor. Because BIC continued to decrease through eight profiles, the six-profile model is the largest equal-variance model that satisfies the floor rather than the point at which BIC stops improving.` [F76]

`The five- and six-profile varying-variance models (BIC 39,308 and 38,747) did not converge (OpenMx status code 6: first-order optimality conditions not met). Inspection showed the cause. In each, one profile (271 and 277 respondents) contains only respondents whose site-specific regulation score is exactly 5, the top of the scale, among those who answered it (267 of 267 and 273 of 273). That profile's variance on the indicator shrinks toward zero (estimates of 0.0000055 and 0.00000036), and because the normal likelihood increases without limit as a variance approaches zero, the lower BIC of these two models reflects that collapse rather than a better description of the data. A further optimization attempt was not made, since it would search the same unbounded region; placing a lower bound on the variances was considered and not adopted, because it would change the model specification. Both fits are excluded.` [F75, F77, D156]

### Assigning respondents to profiles

`Each fitted respondent is assigned to the profile with the highest estimated membership probability. Assignment is not certain: the average probability of the assigned profile among its members is at least 0.759 for every profile. Certainty also depends on how many scales a respondent answered. Mean assigned-profile probability is 0.839 for respondents who answered all eleven scales (1,373 respondents), 0.799 for those who answered ten (209), and 0.722 for those who answered seven to nine (136); the share assigned with probability below 0.70 is 23.5, 32.1, and 44.9 percent respectively.` [D148]

The profile numbers (Class 1 to Class 6) are arbitrary labels produced by the estimation and carry
no order.

### Weights

The model is fitted **without** the survey weights: each fitted respondent contributes equally to
the estimated profiles. Everything reported from the model is then weighted in the same way as the
rest of this report. The share of each profile in each column is a weighted percentage with the
Kish effective-N confidence interval, and the profile means shown in the Chapter 5 figure are
weighted means with the Kish effective-N confidence interval, computed from the assigned
respondents. These weighted means are therefore not the same quantities as the unweighted means
the model estimated for each profile. Whether the fitting software can carry survey weights into the
estimation was not verified. [D125, D147, F63]

### Reporting floor for species columns

Chapter 5 is the only chapter of this report that withholds columns. Before the model was fitted,
a floor of 30 on the Kish effective sample size was set for species columns, adopting the
effective-sample-size element of the National Center for Health Statistics data presentation
standards for proportions (Parker et al., 2017). Only that element is adopted: the NCHS standard
also calls for a raw sample size of at least 30 and for Korn-Graubard confidence intervals with
width criteria, and this report's intervals are Wald intervals on the Kish effective N, as
described above, with no width criterion applied. [D146, F65]

`Four columns fall below the floor and are not shown in Chapter 5 tables or figures: Northern pike (32 respondents, effective N 26.9), Blue catfish (27, 22.6), Yellow perch (12, 11.1), and Muskellunge / Tiger musky (8, 7.3). The floor is applied to reporting only; these respondents are included in the model fit and in the Overall column. Blue catfish and yellow perch respondents are also contained in the Catfish and Panfish / Sunfish family columns. Northern pike and muskellunge have no family column, so their respondents appear in no displayed Chapter 5 species column.`

Where a profile has no respondents in a displayed column, the percentage is 0 and the Wald
interval has zero width; this is a property of the interval formula, not a measurement of
certainty.

### What is not reported

No significance test is reported in Chapter 5, and the profile shares in different columns are not
formally compared. As in other chapters, the species columns overlap and must not be totalled.

**Reference to add to the report's reference list:** Parker JD, Talih M, Malec DJ, et al. National
Center for Health Statistics data presentation standards for proportions. *Vital and Health
Statistics*, Series 2, No. 175. National Center for Health Statistics; 2017.
