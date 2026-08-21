# ==============================================================================
# Standalone script: quadrant scatter, comprehension-by-quadrant, and weighted
# quadrant prevalence plots, duplicated from 2025RegsReport.rmd for
# presentation formatting.
#
# This is an ISOLATED COPY - editing plot styling/labels/colors here will NOT
# affect the base report (2025RegsReport.rmd). Re-run this whole script after
# any edits; each plot is saved to its own object at the bottom of each
# section so you can tweak just the ggplot layers there.
#
# Figures reproduced (numbering matches 2025RegsReport.rmd):
#   Figure 3 - Two-scale framing (quadrant) scatter vs. single composite
#   Figure 4 - Mean comprehension by policy quadrant
#   Figure 6 - Weighted population prevalence of the four policy quadrants
# ==============================================================================

library(tidyverse)
library(survey)
library(bslib)

# ------------------------------------------------------------------------
# 0. Presentation theme - pull an accent palette (and bg/fg) from the actual
#    bslib Bootswatch theme used in the deck/app, so these plots match it
#    exactly rather than defaulting to a plain ggplot look.
# ------------------------------------------------------------------------

pres_theme <- bs_theme(bootswatch = "darkly")
pres_colors <- bs_get_variables(
  pres_theme,
  c("primary", "secondary", "success", "info", "warning", "danger", "bg", "fg")
)

# Named, in a sensible order for a 4-level quadrant factor
quadrant_palette <- c(
  "Statewide only" = unname(pres_colors["danger"]),
  "Neither" = unname(pres_colors["secondary"]),
  "Wants both" = unname(pres_colors["info"]),
  "Site-specific only" = unname(pres_colors["primary"])
)
accent_color <- "yellow" #unname(pres_colors["primary"])
bg_color <- unname(pres_colors["bg"])
fg_color <- unname(pres_colors["fg"])
grid_color <- scales::alpha(fg_color, 0.15)

theme_presentation <- function(base_size = 32) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(
      plot.background = element_rect(fill = bg_color, colour = NA),
      panel.background = element_rect(fill = bg_color, colour = NA),
      legend.background = element_rect(fill = bg_color, colour = NA),
      legend.key = element_rect(fill = bg_color, colour = NA),
      text = element_text(colour = fg_color),
      plot.title = element_text(
        face = "bold",
        size = rel(1.3),
        colour = fg_color,
        margin = margin(b = 6)
      ),
      plot.subtitle = element_text(
        size = rel(1),
        colour = fg_color,
        margin = margin(b = 8)
      ),
      axis.title = element_text(
        face = "bold",
        size = rel(1.2),
        colour = fg_color
      ),
      axis.text = element_text(size = rel(1), colour = fg_color),
      legend.title = element_text(face = "bold", colour = fg_color),
      legend.text = element_text(size = rel(1), colour = fg_color),
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = grid_color),
      plot.margin = margin(10, 14, 10, 10)
    )
}

# ------------------------------------------------------------------------
# 1. Load data (identical source/paths to 2025RegsReport.rmd)
# ------------------------------------------------------------------------

#setwd("D:/Survey/Analysis/CrossTabTables/")

source("..\\BaseFunctions_2025_UPDATED.R")
source("CrossTabTableFunctions.R")

load(file = "../../Data/DataAggregation1/aggregateData_20260624.rData")
d <- d %>% filter(surveyYear == 2025)
d <- add_scale_scores(d)

q <- read.csv(
  file = "../../Data/DataAggregation1/FactorLevels_aggregated.csv"
) %>%
  filter(Year == 2025)

# ------------------------------------------------------------------------
# 2. Rebuild the quadrant scale scores (mirrors regdev_setup chunk)
# ------------------------------------------------------------------------

reg_items <- paste0("Q31", letters[1:12])

reg_num <- as.data.frame(lapply(d[reg_items], as.integer))
names(reg_num) <- reg_items
cc <- stats::complete.cases(reg_num)
reg_cc <- reg_num[cc, ]

# Empirical scale definitions (from the 3-factor EFA in the base report)
comp_i <- c("Q31e", "Q31g", "Q31h")
site_i <- c("Q31j", "Q31k", "Q31l")
unif_i <- c("Q31a", "Q31b", "Q31d", "Q31f", "Q31i")

comprehension <- rowMeans(reg_cc[, comp_i])
site_score <- rowMeans(reg_cc[, site_i])
uniform_score <- rowMeans(reg_cc[, unif_i])
orientation <- rowMeans(cbind(6 - reg_cc[, unif_i], reg_cc[, site_i]))

af <- data.frame(
  comprehension,
  site_score,
  uniform_score,
  orientation,
  postWeight = d$postWeight[cc],
  stringsAsFactors = FALSE
)

af$quadrant <- factor(
  dplyr::case_when(
    af$uniform_score > 3 & af$site_score > 3 ~ "Wants both",
    af$uniform_score <= 3 & af$site_score > 3 ~ "Site-specific only",
    af$uniform_score > 3 & af$site_score <= 3 ~ "Statewide only",
    TRUE ~ "Neither"
  ),
  levels = c("Statewide only", "Neither", "Wants both", "Site-specific only")
)

# Standalone Item C (excluded from the three scales; kept for its own figure)
af$Q31c <- reg_cc$Q31c

# ------------------------------------------------------------------------
# 3. Figure 3 - Two-scale framing (quadrant) scatter
# ------------------------------------------------------------------------

fig3_quadrant_scatter <- ggplot(af, aes(uniform_score, site_score)) +
  geom_jitter(
    width = .12,
    height = .12,
    alpha = .18,
    size = 1.1,
    colour = accent_color
  ) +
  geom_hline(yintercept = 3, linetype = 2, colour = grid_color) +
  geom_vline(xintercept = 3, linetype = 2, colour = grid_color) +
  geom_abline(
    slope = -1,
    intercept = 6,
    colour = unname(pres_colors["danger"]),
    linewidth = 0.8
  ) +
  labs(
    title = "Two-scale framing",
    x = "Simplification mean",
    y = "Site-specific mean"
  ) +
  theme_presentation(base_size = 48)

fig3_composite_hist <- ggplot(af, aes(orientation)) +
  geom_histogram(binwidth = .25, fill = accent_color, colour = bg_color) +
  geom_vline(xintercept = 3, linetype = 2, colour = grid_color) +
  labs(
    title = "",
    subtitle = "",
    x = "Site-specific mean",
    y = "Number respondents"
  ) +
  theme_presentation(base_size = 32) +
  theme(panel.grid.major = element_blank())

fig3_simplification_hist <- ggplot(af, aes(uniform_score)) +
  geom_histogram(binwidth = .25, fill = accent_color, colour = bg_color) +
  geom_vline(xintercept = 3, linetype = 2, colour = grid_color) +
  labs(
    title = "",
    subtitle = "",
    x = "Simplification mean",
    y = "Number respondents"
  ) +
  theme_presentation(base_size = 32) +
  theme(panel.grid.major = element_blank())

fig3_quadrant_scatter

# ------------------------------------------------------------------------
# 4. Figure 4 - Mean comprehension by policy quadrant
# ------------------------------------------------------------------------

fig4_comprehension_by_quadrant <- af |>
  dplyr::filter(quadrant != "Neither") |>
  dplyr::mutate(
    quad = factor(
      quadrant,
      levels = c(
        "Statewide only",
        "Wants both",
        "Site-specific only"
      )
    )
  ) |>
  ggplot(aes(quad, comprehension)) +
  stat_summary(
    fun.data = mean_cl_normal,
    geom = "errorbar",
    width = 0.15,
    colour = accent_color,
    linewidth = 0.9
  ) +
  stat_summary(fun = mean, geom = "point", size = 3.5, colour = accent_color) +
  scale_y_continuous(limits = c(1, 5), breaks = 1:5) +
  labs(x = NULL, y = "Comprehension scale mean") +
  theme_presentation(base_size = 32) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_blank()
  )

fig4_comprehension_by_quadrant

# ------------------------------------------------------------------------
# 5. Figure 6 - Weighted population prevalence of the four policy quadrants
# ------------------------------------------------------------------------

af$quadrant <- factor(
  af$quadrant,
  levels = c("Site-specific only", "Wants both", "Statewide only", "Neither")
)

des <- svydesign(
  ids = ~1,
  weights = ~postWeight,
  data = af[!is.na(af$postWeight), ]
)
wp <- svymean(~quadrant, des)
wci <- confint(wp)

fig6_weighted_quadrant_bar <- data.frame(
  Quadrant = factor(levels(af$quadrant), levels = levels(af$quadrant)),
  est = 100 * as.numeric(coef(wp)),
  lo = 100 * wci[, 1],
  hi = 100 * wci[, 2]
) |>
  ggplot(aes(Quadrant, est, fill = Quadrant)) +
  geom_col(width = .65, show.legend = FALSE) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .2, colour = fg_color) +
  scale_fill_manual(values = quadrant_palette) +
  labs(x = NULL, y = "Weighted % of anglers") +
  theme_presentation(base_size = 32) +
  theme(panel.grid.major = element_blank())

fig6_weighted_quadrant_bar

# ------------------------------------------------------------------------
# 5b. Item C dot plot - mean agreement with Item C by policy quadrant
#     (excluded from the three scales; reported at the item level only)
# ------------------------------------------------------------------------

fig_itemc_by_quadrant <- af |>
  dplyr::filter(quadrant != "Neither") |>
  dplyr::mutate(
    quad = factor(
      quadrant,
      levels = c(
        "Statewide only",
        "Wants both",
        "Site-specific only"
      )
    )
  ) |>
  dplyr::group_by(quad) |>
  dplyr::summarise(
    m = mean(Q31c),
    se = sd(Q31c) / sqrt(dplyr::n()),
    .groups = "drop"
  ) |>
  ggplot(aes(quad, m)) +
  geom_errorbar(
    aes(ymin = m - 1.96 * se, ymax = m + 1.96 * se),
    width = .15,
    colour = fg_color,
    linewidth = 0.9
  ) +
  geom_point(size = 3.5, colour = accent_color) +
  scale_y_continuous(limits = c(1, 5), breaks = 1:5) +
  labs(x = NULL, y = "Item C mean") +
  theme_presentation(base_size = 32) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_blank()
  )

fig_itemc_by_quadrant

# ------------------------------------------------------------------------
# 6. Export at slide dimensions (10 x 6 in, 300 dpi)
#    bg = "bg_color" so the exported PNG matches the deck background instead
#    of defaulting to a white/transparent canvas that would clash on darkly.
# ------------------------------------------------------------------------

out_dir <- "presentation_figs"
dir.create(out_dir, showWarnings = FALSE)

ggsave(
  file.path(out_dir, "fig3_quadrant_scatter.png"),
  fig3_quadrant_scatter,
  width = 10,
  height = 6,
  units = "in",
  dpi = 300,
  bg = bg_color
)
ggsave(
  file.path(out_dir, "fig3_composite_hist.png"),
  fig3_composite_hist,
  width = 10,
  height = 6,
  units = "in",
  dpi = 300,
  bg = bg_color
)
ggsave(
  file.path(out_dir, "fig3_simplification_hist.png"),
  fig3_simplification_hist,
  width = 10,
  height = 6,
  units = "in",
  dpi = 300,
  bg = bg_color
)
ggsave(
  file.path(out_dir, "fig4_comprehension_by_quadrant.png"),
  fig4_comprehension_by_quadrant,
  width = 10,
  height = 6,
  units = "in",
  dpi = 300,
  bg = bg_color
)
ggsave(
  file.path(out_dir, "fig6_weighted_quadrant_bar.png"),
  fig6_weighted_quadrant_bar,
  width = 10,
  height = 6,
  units = "in",
  dpi = 300,
  bg = bg_color
)
ggsave(
  file.path(out_dir, "fig_itemc_by_quadrant.png"),
  fig_itemc_by_quadrant,
  width = 10,
  height = 6,
  units = "in",
  dpi = 300,
  bg = bg_color
)

# ------------------------------------------------------------------------
# Presentation formatting starts here - tweak titles, colors, themes, etc.
# on the fig3_*, fig4_*, fig6_* objects above without touching the .rmd.
# ------------------------------------------------------------------------
