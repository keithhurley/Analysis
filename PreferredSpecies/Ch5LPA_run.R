# Fits the Chapter 5 LPA grid and builds Ch5LPA_results.rds. Run detached so
# a console restart cannot kill it (the first attempt died that way):
#   system2(file.path(R.home("bin"), "Rscript.exe"), "Ch5LPA_run.R",
#           stdout = "Ch5LPA_job.out", stderr = "Ch5LPA_job.out", wait = FALSE)
# Resumable: models already saved in Ch5LPA_fits/ for the current data are
# skipped. Progress is appended to Ch5LPA_fit.log.

suppressPackageStartupMessages(library(tidyverse))
source("../BaseFunctions_2025_UPDATED.R")
source("../CrossTabTables/CrossTabTableFunctions.R")
source("PreferredSpeciesFunctions.R")
source("Ch5LPA.R")

load("../../Data/DataAggregation1/aggregateData_20260624.rData")
d <- d |>
  filter(surveyYear == 2025) |>
  filter(!is.na(B1)) |>
  add_scale_scores() |>
  Ch5LPAGate()
stopifnot(nrow(d) == 1915, sum(d$lpa_fitted) == 1718)

lpa_frame <- Ch5LPAFrame(d)
Ch5LPAFitGrid(lpa_frame)
Ch5LPABuildResults(lpa_frame)
cat("Results built", format(Sys.time()), "\n", file = ch5.lpa.log, append = TRUE)
