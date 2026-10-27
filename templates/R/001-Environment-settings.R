# =============================================================================
# R/001-Environment-settings.R
# Project paths and environment settings.
# Prereq: set `analysis` to this folder's name, then source 000-Libraries.R.
# =============================================================================

# Project root (resolved relative to the .rproj or project root, never absolute)
proj_root <- here::here()

# ---- Project paths ----
path_figures    <- here::here("FIGURES")
path_md         <- here::here("MD")
path_references <- here::here("REFERENCES")
path_r          <- here::here("R")
path_reports    <- here::here("REPORTS")
path_results    <- here::here("RESULTS")
path_mplus_out  <- here::here("R", "MPLUS_OUTPUT")

# ---- Data locations ----
# Participant data lives outside the project. 003-Data-paths.R reads this
# project's locations from ~/.agentkit/data_paths/<Project>.txt and provides
# data_path(). 004-Save-result.R provides save_result(), the only way code
# writes to RESULTS/. 005-Data-dictionary.R keeps DATA_DICTIONARY/ current and
# reads a data file only when its entry is missing or out of date.
# Examples:
#   d <- haven::read_dta(data_path("SOURCE", "analytic.dta"))
#   saveRDS(d_clean, data_path("WORK", "analytic_clean.rds"))
#   save_result(broom::tidy(fit), paste0(analysis, "_model1"))
if (!exists("analysis")) {
  stop("Set `analysis` to this folder's name before sourcing ",
       "001-Environment-settings.R.", call. = FALSE)
}
source(here::here("R", analysis, "003-Data-paths.R"))
source(here::here("R", analysis, "004-Save-result.R"))
source(here::here("R", analysis, "005-Data-dictionary.R"))
update_data_dictionary()

# ---- Color palette (project branding) ----
I <- 0.85   # intensity multiplier for RGB channels
mk_col <- function(r, g, b, I = 1) {
  r <- pmin(255, pmax(0, round(r * I)))
  g <- pmin(255, pmax(0, round(g * I)))
  b <- pmin(255, pmax(0, round(b * I)))
  rgb(r, g, b, maxColorValue = 255)
}
color_red     <- mk_col(237,  28,  36, I)
color_brown   <- mk_col( 78,  54,  41, I)
color_gold    <- mk_col(255, 199, 144, I)
color_skyblue <- mk_col( 89, 203, 232, I)
color_emerald <- mk_col(  0, 179, 152, I)
color_navy    <- mk_col(  0,  60, 113, I)
color_taupe   <- mk_col(183, 176, 156, I)

# ---- Create output directories if missing ----
for (p in c(path_results, path_md, path_figures, path_reports)) {
  dir.create(p, showWarnings = FALSE, recursive = TRUE)
}

cat("\n=== Project environment ready ===\n")
cat("Project root:", proj_root, "\n")
