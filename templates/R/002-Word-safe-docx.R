# 002-Word-safe-docx.R
#
# Re-saves a rendered DOCX through LibreOffice so Word opens it without the
# "unreadable content" recovery prompt.
#
# Quarto writes DOCX files that Word flags as damaged when the document holds
# flextable tables. Word still opens the file after you click Yes, but it opens
# a recovered copy under the name "Document 1", so the original filename is
# lost. LibreOffice reads the same file without complaint. Writing it back out
# through LibreOffice's own Word filter produces a file Word accepts directly.
#
# This script does not change the document. It re-encodes it.
#
# LibreOffice is optional. Without it the file is copied unchanged and a note
# explains what installing LibreOffice would buy. A render never fails because
# LibreOffice is missing or misbehaving, so a collaborator who has never heard
# of LibreOffice still gets a dated document in REPORTS/.
#
# Two ways to use it.
#
#   From a driver:
#     source(file.path(src_dir, "002-Word-safe-docx.R"))
#     converted <- word_safe_docx(flat, dated, quiet = TRUE)
#
#   From a shell, to test one file:
#     Rscript 002-Word-safe-docx.R input.docx output.docx
#
# The command line form is strict on purpose. It exists to tell you whether the
# conversion works on this machine, so it reports an error rather than quietly
# falling back to a copy.


# Locate the LibreOffice command line binary.
#
# LibreOffice on macOS installs inside the application bundle and does not put
# soffice on the PATH, so check the bundle first. Set the SOFFICE environment
# variable to override this search.
find_soffice <- function() {
  override <- Sys.getenv("SOFFICE", unset = "")
  if (nzchar(override)) {
    if (!file.exists(override)) {
      stop("SOFFICE is set to a path that does not exist: ", override,
           call. = FALSE)
    }
    return(override)
  }

  candidates <- c(
    "/Applications/LibreOffice.app/Contents/MacOS/soffice",
    path.expand("~/Applications/LibreOffice.app/Contents/MacOS/soffice"),
    Sys.which("soffice"),
    Sys.which("libreoffice")
  )
  found <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(found) == 0) {
    stop("LibreOffice not found. Install it, or set the SOFFICE environment ",
         "variable to the soffice binary. Searched:\n  ",
         paste(candidates[nzchar(candidates)], collapse = "\n  "),
         call. = FALSE)
  }
  found[1]
}


# Confirm a file is a readable DOCX rather than a zero byte stub or a partial
# write. A DOCX is a zip archive holding word/document.xml, so listing the
# archive tests both facts at once.
check_docx <- function(path, label) {
  if (!file.exists(path)) {
    stop(label, " does not exist: ", path, call. = FALSE)
  }
  if (file.size(path) == 0) {
    stop(label, " is empty: ", path, call. = FALSE)
  }
  entries <- tryCatch(
    utils::unzip(path, list = TRUE)$Name,
    error = function(e) character(0)
  )
  if (!("word/document.xml" %in% entries)) {
    stop(label, " is not a readable DOCX: ", path, call. = FALSE)
  }
  invisible(TRUE)
}


# Run the conversion. Stops on any problem, so the caller decides whether a
# problem is fatal or something to fall back from.
convert_via_soffice <- function(input, output) {
  soffice <- find_soffice()

  # LibreOffice refuses to start a headless conversion while another
  # LibreOffice process holds the default user profile. Point this run at a
  # throwaway profile so an open LibreOffice window does not block the render.
  work    <- tempfile("word_safe_docx_")
  outdir  <- file.path(work, "out")
  profile <- file.path(work, "profile")
  dir.create(outdir, recursive = TRUE)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)

  args <- c(
    paste0("-env:UserInstallation=file://", profile),
    "--headless",
    "--norestore",
    "--convert-to", shQuote("docx:MS Word 2007 XML"),
    "--outdir", shQuote(outdir),
    shQuote(input)
  )

  # Blank the dynamic linker search path for the child process. R sets
  # LD_LIBRARY_PATH to its own library directories, LibreOffice inherits it,
  # and LibreOffice then loads R's libraries instead of its own and refuses to
  # start. Blanking the variable for this one command fixes that and leaves
  # the R session untouched.
  log <- suppressWarnings(
    system2(soffice, args,
            env    = c("LD_LIBRARY_PATH=", "DYLD_LIBRARY_PATH="),
            stdout = TRUE, stderr = TRUE, timeout = 180)
  )
  status <- attr(log, "status")
  if (!is.null(status) && status != 0) {
    stop("LibreOffice failed with status ", status, ".\n",
         paste(log, collapse = "\n"), call. = FALSE)
  }

  # LibreOffice reports success in its exit status even when it writes nothing,
  # so verify the file it was supposed to produce.
  produced <- file.path(
    outdir,
    paste0(tools::file_path_sans_ext(basename(input)), ".docx")
  )
  check_docx(produced, "LibreOffice output")

  # Copy rather than rename. The temporary folder and the project folder can
  # sit on different volumes, and file.rename fails across a volume boundary.
  if (!file.copy(produced, output, overwrite = TRUE)) {
    stop("Could not write the converted file to ", output, call. = FALSE)
  }
  check_docx(output, "Converted file")
  invisible(TRUE)
}


# The fallback: the plain copy the driver used to make.
plain_copy <- function(input, output) {
  if (normalizePath(input, mustWork = FALSE) ==
      normalizePath(output, mustWork = FALSE)) {
    return(invisible(TRUE))
  }
  if (!file.copy(input, output, overwrite = TRUE)) {
    stop("Could not copy ", input, " to ", output, call. = FALSE)
  }
  invisible(TRUE)
}


notify_missing <- function(output) {
  message(
    "\n",
    "LibreOffice is not installed, so ", basename(output), " in REPORTS/ is\n",
    "Quarto's own DOCX.\n",
    "\n",
    "If that document holds tables, Word will report it as damaged and open a\n",
    "recovered copy named \"Document 1\" rather than your file. The document is\n",
    "not corrupt. Word reads part of what Quarto writes more strictly than\n",
    "other programs do, and re-saving the file through LibreOffice produces a\n",
    "version Word opens directly.\n",
    "\n",
    "LibreOffice is free, and nothing else in this project needs it:\n",
    "  https://www.libreoffice.org/download/\n",
    "\n",
    "Install it and render again, and this step happens on its own. If it is\n",
    "already installed somewhere this script did not look, set the SOFFICE\n",
    "environment variable to the soffice binary.\n"
  )
}


notify_failed <- function(output, detail) {
  message(
    "\n",
    "LibreOffice is installed but did not convert the file, so ",
    basename(output), "\n",
    "in REPORTS/ is Quarto's own DOCX and Word may report it as damaged.\n",
    "\n",
    "This is not the ordinary missing-LibreOffice case. Check that LibreOffice\n",
    "opens on this machine, then render again. The error was:\n",
    "\n",
    detail, "\n"
  )
  warning("LibreOffice conversion failed. REPORTS/ holds the unconverted DOCX.",
          call. = FALSE)
}


# Write input to output, through LibreOffice when that is possible.
#
# Returns TRUE when the file was converted and FALSE when it was copied
# unchanged, so a driver can say which happened. Set fallback = FALSE to make
# any problem an error instead.
word_safe_docx <- function(input, output = input, quiet = FALSE,
                           fallback = TRUE) {
  input <- normalizePath(input, mustWork = FALSE)

  # The input check stays strict either way. A render that produced an
  # unreadable file is a different problem, and copying it forward would hide
  # it rather than work around it.
  check_docx(input, "Input")

  target_dir <- dirname(output)
  if (!dir.exists(target_dir)) dir.create(target_dir, recursive = TRUE)

  soffice <- tryCatch(find_soffice(), error = function(e) e)
  if (inherits(soffice, "error")) {
    if (!fallback) stop(conditionMessage(soffice), call. = FALSE)
    plain_copy(input, output)
    notify_missing(output)
    return(invisible(FALSE))
  }

  result <- tryCatch(convert_via_soffice(input, output), error = function(e) e)
  if (inherits(result, "error")) {
    if (!fallback) stop(conditionMessage(result), call. = FALSE)
    plain_copy(input, output)
    notify_failed(output, conditionMessage(result))
    return(invisible(FALSE))
  }

  if (!quiet) {
    cat("Re-saved", basename(input), "through LibreOffice as",
        basename(output), "\n")
  }
  invisible(TRUE)
}


# Command line entry point. Sourcing the file defines the functions and runs
# nothing. This form is strict, because its job is to tell you whether the
# conversion works here.
if (sys.nframe() == 0L && !interactive()) {
  argv <- commandArgs(trailingOnly = TRUE)
  if (length(argv) < 1 || length(argv) > 2) {
    stop("Usage: Rscript 002-Word-safe-docx.R input.docx [output.docx]",
         call. = FALSE)
  }
  word_safe_docx(argv[1], if (length(argv) == 2) argv[2] else argv[1],
                 fallback = FALSE)
}
