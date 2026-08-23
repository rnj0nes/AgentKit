# =============================================================================
# R/001-Environment-settings.R
# Project paths and environment settings.
# Prereq: source R/000-Libraries.R first. Run from the project root.
# =============================================================================

# Project root (resolved relative to the .rproj or project root, never absolute)
proj_root <- here::here()

# ---- Project paths ----
path_figures    <- here::here("FIGURES")
path_md         <- here::here("MD")
path_references <- here::here("REFERENCES")
path_r          <- here::here("R")
path_rdata      <- here::here("R", "RDATA")
path_reports    <- here::here("REPORTS")

# ---- Data paths ----
# Add project-specific data file paths here. Keep them project-relative.
# Example:
#   file_data <- here::here("Stata", "DTA", "analytic.dta")

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
for (p in c(path_rdata, path_md, path_figures, path_reports)) {
  dir.create(p, showWarnings = FALSE, recursive = TRUE)
}

cat("\n=== Project environment ready ===\n")
cat("Project root:", proj_root, "\n")
