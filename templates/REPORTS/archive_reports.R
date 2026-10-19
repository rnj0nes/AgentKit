#!/usr/bin/env Rscript
#
# archive_reports.R
#
# Moves older copies of each report out of REPORTS/ and into REPORTS/Archive/,
# so REPORTS/ holds only the newest copy of every report. Nothing is deleted.
#
# Usage, from a terminal on macOS, Windows, or Linux:
#   Rscript archive_reports.R                  # run inside REPORTS/
#   Rscript REPORTS/archive_reports.R          # run from the project root
#   Rscript archive_reports.R <folder>         # archive some other folder
#
# Without an argument the script works on the folder it sits in, not the
# folder the terminal is in. Base R only; no packages are needed.
#
# How a report is recognised. Every file name is read as
#   <stub>_<YYYY-MM-DD>[_<HHMM>][_<tag>].<ext>
# for example MS_Appendix_1_2026-10-17_0851_edited.docx has stub
# MS_Appendix_1, date 2026-10-17, time 0851, tag edited, extension docx.
# Files with the same stub, tag, and extension are copies of one report.
# A plain render (no tag) and an edited copy (tag "edited") are different
# reports, so each keeps its own newest copy. The newest copy is the latest
# date in the name, then the latest time. A copy with no time sorts before a
# copy with a time on the same date. File modification times are ignored,
# because Dropbox and other sync tools rewrite them.
#
# Extensions handled: .docx, .html, .pdf, .pptx. Files that do not match the
# pattern (no date, other extensions, Word lock files beginning "~$") are left
# where they are.
#
# An HTML report that is not self-contained has a companion folder named
# <name>_files. That folder moves with its HTML file.
#
# Name clashes. If Archive/ already holds a file of the same name, the moved
# copy gets _1 before the extension (then _2, and so on). A companion _files
# folder takes the same number, and the links inside the moved HTML file are
# rewritten to point at the renamed folder.

exts <- c("docx", "html", "pdf", "pptx")
pattern <- paste0(
  "^(.+)_([0-9]{4}-[0-9]{2}-[0-9]{2})",   # stub, date
  "(?:_([0-9]{4}))?",                     # optional time, HHMM
  "(?:_([A-Za-z][A-Za-z0-9-]*))?",        # optional tag, e.g. edited
  "\\.(", paste(exts, collapse = "|"), ")$"
)

# ---- which folder ----------------------------------------------------------

script_dir <- function() {
  arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg) == 1) {
    return(dirname(normalizePath(sub("^--file=", "", arg), mustWork = FALSE)))
  }
  NA_character_
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 1) {
  reports_dir <- args[1]
} else {
  reports_dir <- script_dir()
  if (is.na(reports_dir)) reports_dir <- getwd()
}
reports_dir <- normalizePath(reports_dir, mustWork = FALSE)
if (!dir.exists(reports_dir)) {
  stop("Folder not found: ", reports_dir, call. = FALSE)
}
archive_dir <- file.path(reports_dir, "Archive")

# ---- read the file names ---------------------------------------------------

all_names <- list.files(reports_dir, all.files = FALSE, no.. = TRUE)
is_file <- !dir.exists(file.path(reports_dir, all_names))
names_in <- all_names[is_file & !startsWith(all_names, "~$")]

m <- regmatches(names_in, regexec(pattern, names_in, perl = TRUE,
                                  ignore.case = TRUE))
matched <- lengths(m) == 6
if (!any(matched)) {
  cat("No dated reports found in", reports_dir, "\n")
  quit(save = "no", status = 0)
}

parts <- do.call(rbind, m[matched])
reports <- data.frame(
  file = parts[, 1],
  stub = parts[, 2],
  date = parts[, 3],
  time = parts[, 4],              # "" when absent
  tag  = parts[, 5],              # "" when absent
  ext  = tolower(parts[, 6]),
  stringsAsFactors = FALSE
)
reports$family <- paste0(reports$stub,
                         ifelse(reports$tag == "", "", paste0(" [", reports$tag, "]")),
                         ".", reports$ext)
reports$family_key <- tolower(reports$family)

# ---- helpers ---------------------------------------------------------------

companion_dir <- function(dir, file) {
  file.path(dir, paste0(tools::file_path_sans_ext(file), "_files"))
}

# First name in Archive/ that clashes with neither a file nor, for HTML, a
# _files folder: name.ext, then name_1.ext, name_2.ext, ...
free_name <- function(file, check_companion) {
  base <- tools::file_path_sans_ext(file)
  ext  <- tools::file_ext(file)
  n <- 0
  repeat {
    cand <- if (n == 0) file else sprintf("%s_%d.%s", base, n, ext)
    taken <- file.exists(file.path(archive_dir, cand)) ||
      (check_companion && dir.exists(companion_dir(archive_dir, cand)))
    if (!taken) return(cand)
    n <- n + 1
  }
}

# Rename, falling back to copy-then-remove when rename fails (for example,
# across drives on Windows). Returns TRUE on success.
move_path <- function(from, to) {
  if (isTRUE(file.rename(from, to))) return(TRUE)
  if (dir.exists(from)) {
    tmp <- file.path(dirname(to), basename(from))
    if (tmp != to && file.exists(tmp)) return(FALSE)
    ok <- isTRUE(file.copy(from, dirname(to), recursive = TRUE))
    if (ok && tmp != to) ok <- isTRUE(file.rename(tmp, to))
    if (ok) unlink(from, recursive = TRUE)
    return(ok && !dir.exists(from))
  }
  ok <- isTRUE(file.copy(from, to, overwrite = FALSE, copy.date = TRUE))
  if (ok) ok <- isTRUE(file.remove(from))
  ok
}

# Point an HTML file's links at a renamed companion folder.
relink_html <- function(html, old_dir, new_dir) {
  size <- file.info(html)$size
  txt <- readChar(html, size, useBytes = TRUE)
  new <- gsub(paste0(old_dir, "/"), paste0(new_dir, "/"), txt,
              fixed = TRUE, useBytes = TRUE)
  if (!identical(new, txt)) writeChar(new, html, eos = NULL, useBytes = TRUE)
}

# ---- decide and move -------------------------------------------------------

moved <- 0
failed <- 0
kept <- character(0)

for (key in sort(unique(reports$family_key))) {
  fam <- reports[reports$family_key == key, ]
  fam <- fam[order(fam$date, fam$time, fam$file), ]
  newest <- fam[nrow(fam), ]
  kept <- c(kept, newest$file)
  old <- fam[-nrow(fam), , drop = FALSE]
  if (nrow(old) == 0) next

  if (!dir.exists(archive_dir)) dir.create(archive_dir)
  cat(sprintf("\n%s: keeping %s\n", newest$family, newest$file))

  for (f in old$file) {
    src <- file.path(reports_dir, f)
    src_files <- companion_dir(reports_dir, f)
    has_companion <- tolower(tools::file_ext(f)) == "html" && dir.exists(src_files)

    target <- free_name(f, check_companion = has_companion)
    ok <- move_path(src, file.path(archive_dir, target))
    note <- if (target == f) "" else sprintf(" (renamed %s)", target)

    if (ok && has_companion) {
      dst_files <- companion_dir(archive_dir, target)
      ok <- move_path(src_files, dst_files)
      if (ok && target != f) {
        relink_html(file.path(archive_dir, target),
                    basename(src_files), basename(dst_files))
      }
      note <- paste0(note, " with its _files folder")
    }

    if (ok) {
      moved <- moved + 1
      cat(sprintf("  moved   %s%s\n", f, note))
    } else {
      failed <- failed + 1
      cat(sprintf("  FAILED  %s (is it open in another program?)\n", f))
    }
  }
}

cat(sprintf("\n%d report(s) kept, %d older cop%s moved to Archive/",
            length(kept), moved, if (moved == 1) "y" else "ies"))
if (failed > 0) cat(sprintf(", %d could not be moved", failed))
cat(".\n")
quit(save = "no", status = if (failed > 0) 1 else 0)
