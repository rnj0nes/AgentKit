# manuscript_Driver.R
#
# Lives in R/<Analysis>/ beside its control file. Run it from anywhere. Every
# path resolves from the project root through here::here(), so nothing depends
# on the working directory.

if (!requireNamespace("here",   quietly = TRUE)) install.packages("here")
if (!requireNamespace("quarto", quietly = TRUE)) install.packages("quarto")

analysis <- "Analysis1"    # rename to this folder's name
stem     <- "manuscript"   # the control file is <stem>_Control.qmd
ext      <- "docx"

src_dir <- here::here("R", analysis)
built   <- file.path(src_dir, paste0(stem, "_Control.", ext))

# Render in place, next to the control file.
#
# Do not pass --output-dir. Quarto empties whatever directory it is given
# before writing, and RENDER/ is flat and shared by every analysis in this
# project, so pointing it there would destroy the other analyses' output.
quarto::quarto_render(
  input       = file.path(src_dir, paste0(stem, "_Control.qmd")),
  output_file = basename(built)
)

# Move the build into the flat RENDER/, prefixed by the analysis so two
# subfolders cannot collide on the same name.
render_dir <- here::here("RENDER")
if (!dir.exists(render_dir)) dir.create(render_dir)
flat <- file.path(render_dir, sprintf("%s_%s.%s", analysis, stem, ext))
file.rename(built, flat)

# Write into REPORTS/ with the render date, through LibreOffice. A same-day
# rerun replaces that day's file and leaves earlier dates alone.
#
# Quarto writes DOCX files that Word reports as damaged whenever the document
# holds flextable tables. Word opens the recovered copy under the name
# "Document 1", so the original filename is lost. LibreOffice reads the same
# file without complaint, and writing it back out through LibreOffice's Word
# filter produces a DOCX that Word opens directly. RENDER/ keeps Quarto's own
# output and REPORTS/ gets the version Word accepts.
#
# LibreOffice is optional. Without it the file is copied unchanged and the
# helper prints a note about what installing LibreOffice would buy, so a render
# never fails on this account.
source(file.path(src_dir, "002-Word-safe-docx.R"))

reports_dir <- here::here("REPORTS")
if (!dir.exists(reports_dir)) dir.create(reports_dir)
dated <- file.path(
  reports_dir,
  sprintf("%s_%s_%s.%s", analysis, stem, format(Sys.Date()), ext)
)
converted <- word_safe_docx(flat, dated, quiet = TRUE)

cat("Built", basename(flat), "in RENDER/,",
    if (converted) "re-saved to REPORTS/ as" else "copied unconverted to REPORTS/ as",
    basename(dated), "\n")
