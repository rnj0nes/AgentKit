# =============================================================================
# R/000-Libraries.R
# Install (if needed) and load packages used across the project.
# =============================================================================

options(repos = c(CRAN = "https://cran.r-project.org"))

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

install_github_if_missing <- function(pkg, repo) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install_if_missing("devtools")
    devtools::install_github(repo, quiet = TRUE)
  }
}

# Core packages for a QMD/R workflow. Add project-specific packages as needed.
for (pkg in c("here", "tidyverse", "knitr", "kableExtra", "quarto")) {
  install_if_missing(pkg)
}

library(here)        # project-relative paths
library(tidyverse)   # data wrangling and visualization
library(knitr)       # dynamic report generation
library(kableExtra)  # tables

# ---- Analysis packages (uncomment when the analysis phase begins) ----
# for (pkg in c("haven", "lavaan", "mirt", "MplusAutomation", "skimr",
#               "ragg", "ggplot2", "geomtextpath", "latex2exp")) {
#   install_if_missing(pkg)
# }
# install_github_if_missing("RNJmisc", "rnj0nes/RNJmisc")
# install_github_if_missing("mplush5", "dougtommet/mplush5")
# install_github_if_missing("DIFMagnitude", "rnj0nes/DIFMagnitude")
