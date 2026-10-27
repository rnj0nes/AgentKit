# =============================================================================
# R/<Analysis>/003-Data-paths.R
# Reads this project's data locations from a paths file kept outside the
# project, and provides data_path() for building file paths inside them.
#
# The paths file is ~/.agentkit/data_paths/<Project>.txt, where <Project> is
# the name of the project root folder. Set the environment variable
# AGENTKIT_DATA_PATHS to use a different folder. The file holds one KEY=path
# line for each location. Lines starting with # are comments.
#
#   SOURCE=/path/to/data/as/received
#   DERIVED=/path/to/kept/datasets
#   WORK=/path/to/interim/files
#   SHARE_DATA=/path/to/data/approved/for/sharing
#   MPLUS=/path/to/mplus/runs
#
# SHARE_DATA may be left empty when the project shares no data.
#
# If the file does not exist yet, or holds only comments, this file still
# loads, and data_path() stops with a template on first use. If the file exists, it is checked when this
# file loads: every key present, and the SOURCE location reachable.
#
# No project file ever holds a data location. Messages from this file name the
# key that failed, never the location itself.
#
# Prereq: source 000-Libraries.R first.
# =============================================================================

.agentkit_keys <- c("SOURCE", "DERIVED", "WORK", "SHARE_DATA", "MPLUS")

.agentkit_paths_file <- function() {
  dir <- Sys.getenv("AGENTKIT_DATA_PATHS", file.path("~", ".agentkit", "data_paths"))
  file.path(path.expand(dir), paste0(basename(here::here()), ".txt"))
}

.agentkit_template <- function() {
  paste0(
    "Create it with these lines, filled in for this machine:\n\n",
    paste0("  ", .agentkit_keys, "=", collapse = "\n"),
    "\n\nSHARE_DATA may be left empty. See AGENTS.md, Project invariants."
  )
}

.agentkit_read_paths <- function() {
  pf <- .agentkit_paths_file()
  if (!file.exists(pf)) {
    stop("Data paths file not found: ", pf, "\n", .agentkit_template(), call. = FALSE)
  }
  lines <- trimws(readLines(pf, warn = FALSE))
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]
  # The scaffold writes this file with every line commented out. Until a line
  # is filled in, the project counts as having no data locations yet.
  if (!length(lines)) return(NULL)
  eq    <- regexpr("=", lines, fixed = TRUE)
  bad   <- eq < 2
  if (any(bad)) {
    stop("Data paths file has a line without KEY=path: line(s) ",
         paste(which(bad), collapse = ", "), " of ", pf, call. = FALSE)
  }
  keys <- trimws(substr(lines, 1, eq - 1))
  vals <- trimws(substr(lines, eq + 1, nchar(lines)))
  vals <- path.expand(vals)
  out  <- setNames(as.list(vals), keys)

  missing <- setdiff(.agentkit_keys, keys)
  if (length(missing)) {
    stop("Data paths file lacks: ", paste(missing, collapse = ", "), "\n",
         .agentkit_template(), call. = FALSE)
  }
  empty <- setdiff(.agentkit_keys[!nzchar(unlist(out[.agentkit_keys]))], "SHARE_DATA")
  if (length(empty)) {
    stop("Data paths file leaves these locations empty: ",
         paste(empty, collapse = ", "), call. = FALSE)
  }
  # SOURCE must already exist, because code never creates it. The others are
  # created on first use.
  if (!dir.exists(out$SOURCE)) {
    stop("The SOURCE location in ", basename(pf), " does not exist on this ",
         "machine. Check that line, and check that any drive or disk image ",
         "holding the data is mounted.", call. = FALSE)
  }
  for (k in c("DERIVED", "WORK", "MPLUS")) {
    if (!dir.exists(out[[k]])) dir.create(out[[k]], recursive = TRUE)
  }
  if (nzchar(out$SHARE_DATA) && !dir.exists(out$SHARE_DATA)) {
    stop("The SHARE_DATA location in ", basename(pf), " does not exist. ",
         "Create it by hand, or leave the line empty.", call. = FALSE)
  }
  out[.agentkit_keys]
}

# A project with no paths file yet, or one with every line still commented
# out, still loads, so a new project renders. The first call to data_path()
# then stops with the template.
.agentkit_paths <- if (file.exists(.agentkit_paths_file())) .agentkit_read_paths() else NULL

# data_path("SOURCE", "hcap.dta") returns the full path to that file.
# data_path("WORK") returns the location itself.
data_path <- function(key, ...) {
  if (is.null(.agentkit_paths)) {
    stop("No data locations set. Fill in the paths file: ",
         .agentkit_paths_file(), "\n", .agentkit_template(), call. = FALSE)
  }
  key <- toupper(key)
  if (!key %in% .agentkit_keys) {
    stop("Unknown data location '", key, "'. Use one of: ",
         paste(.agentkit_keys, collapse = ", "), call. = FALSE)
  }
  loc <- .agentkit_paths[[key]]
  if (!nzchar(loc)) {
    stop("This project has no ", key, " location. Its line in the paths file ",
         "is empty.", call. = FALSE)
  }
  if (length(list(...)) == 0) loc else file.path(loc, ...)
}

# Copies the .out files from an Mplus run folder in MPLUS back into the project
# at R/MPLUS_OUTPUT/<run_id>/, where agents may read them. The .inp, .dat, and
# .h5 files stay outside. Extracted tables go to RESULTS/ through
# save_result(), not here.
mplus_return_out <- function(run_id) {
  run_dir <- data_path("MPLUS", run_id)
  dest    <- here::here("R", "MPLUS_OUTPUT", run_id)
  dir.create(dest, showWarnings = FALSE, recursive = TRUE)
  outs <- list.files(run_dir, pattern = "\\.out$", full.names = TRUE)
  file.copy(outs, dest, overwrite = TRUE)
  invisible(file.path(dest, basename(outs)))
}

if (is.null(.agentkit_paths)) {
  cat("No data locations set for project", basename(here::here()),
      "yet; data_path() will stop until the paths file is filled in\n")
} else {
  cat("Data locations loaded for project", basename(here::here()), "\n")
}
