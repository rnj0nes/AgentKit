# =============================================================================
# R/<Analysis>/004-Save-result.R
# save_result() is the only way code writes to RESULTS/. RESULTS/ sits inside
# the project, where agents read it, so it must hold aggregate results only.
#
# save_result() writes these kinds of object:
#   - a data frame or matrix, written as <name>.csv
#   - a named vector of values, written as <name>.csv
#   - a list of the above, written as <name>.txt (printed) and <name>.rds
# Pass rds = TRUE to also keep an .rds copy of a data frame, matrix, or vector.
#
# It refuses two things:
#   - Fitted model objects, and anything else that is not a data frame,
#     matrix, vector, or list of those. Many model objects (lm, glm, lavaan,
#     MplusAutomation output) carry a copy of the data. Save a table of
#     estimates instead, such as broom::tidy(fit).
#   - Any table with a column named in DATA_DICTIONARY/ID_VARIABLES.txt.
#     Results never identify participants.
#
# The checks catch mistakes. They do not prove a table holds no participant
# data, so a table of one row per participant is still wrong here even
# without an ID column.
#
# Prereq: source 000-Libraries.R first.
# =============================================================================

.agentkit_id_vars <- function() {
  f <- here::here("DATA_DICTIONARY", "ID_VARIABLES.txt")
  if (!file.exists(f)) {
    stop("DATA_DICTIONARY/ID_VARIABLES.txt is missing. Create it with one ",
         "participant ID variable name per line, so save_result() can check ",
         "results for them.", call. = FALSE)
  }
  ids <- trimws(readLines(f, warn = FALSE))
  ids[nzchar(ids) & !startsWith(ids, "#")]
}

.agentkit_allowed <- function(x) {
  if (is.data.frame(x)) return(TRUE)
  if (is.matrix(x) && is.atomic(x)) return(TRUE)
  if (is.atomic(x) && is.null(dim(x))) {
    # Plain atomic vectors and factors. Classed vectors such as Date pass too.
    return(TRUE)
  }
  if (is.list(x) && identical(class(x), "list")) {
    return(all(vapply(x, .agentkit_allowed, logical(1))))
  }
  FALSE
}

.agentkit_id_hits <- function(x, ids) {
  ids_l <- tolower(ids)
  hits  <- character(0)
  if (is.data.frame(x) || is.matrix(x)) {
    hits <- colnames(x)[tolower(colnames(x)) %in% ids_l]
  } else if (is.list(x)) {
    for (el in x) hits <- c(hits, .agentkit_id_hits(el, ids))
  } else if (!is.null(names(x))) {
    hits <- names(x)[tolower(names(x)) %in% ids_l]
  }
  unique(hits)
}

.agentkit_bad_class <- function(x) {
  if (is.list(x) && identical(class(x), "list")) {
    for (el in x) if (!.agentkit_allowed(el)) return(.agentkit_bad_class(el))
  }
  paste(class(x), collapse = "/")
}

save_result <- function(x, name, rds = FALSE) {
  if (!is.character(name) || length(name) != 1 ||
      !grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", name) || grepl("\\.(csv|rds|txt)$", name)) {
    stop("save_result(): name must be a plain file stub such as ",
         "'Analysis1_or_table', with no folder and no extension.", call. = FALSE)
  }
  if (!.agentkit_allowed(x)) {
    stop("save_result(): refused an object of class '",
         .agentkit_bad_class(x), "'. Model objects can carry a copy ",
         "of the data. Save a table of estimates instead, for example ",
         "broom::tidy(fit).", call. = FALSE)
  }
  hits <- .agentkit_id_hits(x, .agentkit_id_vars())
  if (length(hits)) {
    stop("save_result(): refused '", name, "' because it holds the ",
         "participant ID variable(s) ", paste(hits, collapse = ", "),
         ". Results must not identify participants.", call. = FALSE)
  }

  dir <- here::here("RESULTS")
  dir.create(dir, showWarnings = FALSE)
  written <- character(0)

  if (is.data.frame(x) || is.matrix(x) || is.atomic(x)) {
    tab <- if (is.atomic(x) && is.null(dim(x))) {
      data.frame(name = if (is.null(names(x))) seq_along(x) else names(x),
                 value = unname(x), stringsAsFactors = FALSE)
    } else {
      as.data.frame(x, stringsAsFactors = FALSE)
    }
    f <- file.path(dir, paste0(name, ".csv"))
    utils::write.csv(tab, f, row.names = is.matrix(x) && !is.null(rownames(x)))
    written <- f
    if (rds) {
      f2 <- file.path(dir, paste0(name, ".rds"))
      saveRDS(x, f2)
      written <- c(written, f2)
    }
  } else {
    f  <- file.path(dir, paste0(name, ".txt"))
    f2 <- file.path(dir, paste0(name, ".rds"))
    writeLines(utils::capture.output(print(x)), f)
    saveRDS(x, f2)
    written <- c(f, f2)
  }
  cat("Saved", paste(basename(written), collapse = ", "), "to RESULTS/\n")
  invisible(written)
}
