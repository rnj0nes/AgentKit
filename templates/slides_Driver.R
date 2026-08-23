# slides_Driver.R
#
# Lives in R/<Analysis>/ beside its control file. Run it from anywhere. Every
# path resolves from the project root through here::here(), so nothing depends
# on the working directory.

if (!requireNamespace("here",   quietly = TRUE)) install.packages("here")
if (!requireNamespace("quarto", quietly = TRUE)) install.packages("quarto")

analysis <- "Analysis1"   # rename to this folder's name
stem     <- "slides"      # the control file is <stem>_Control.qmd
ext      <- "html"

src_dir <- here::here("R", analysis)
built   <- file.path(src_dir, paste0(stem, "_Control.", ext))

# Render in place, next to the control file.
#
# Do not pass --output-dir. Quarto empties whatever directory it is given
# before writing, and RENDER/ is flat and shared by every analysis in this
# project, so pointing it there would destroy the other analyses' output.
quarto::quarto_render(
  input         = file.path(src_dir, paste0(stem, "_Control.qmd")),
  output_format = "revealjs",
  output_file   = basename(built)
)

# Move the build into the flat RENDER/, prefixed by the analysis so two
# subfolders cannot collide on the same name.
render_dir <- here::here("RENDER")
if (!dir.exists(render_dir)) dir.create(render_dir)
flat <- file.path(render_dir, sprintf("%s_%s.%s", analysis, stem, ext))
file.rename(built, flat)

# Images are embedded (embed-resources: true), so any supporting folder Quarto
# leaves beside the control file is disposable. Remove only that folder, never
# the project's FIGURES/.
support <- file.path(src_dir, paste0(stem, "_Control_files"))
if (dir.exists(support)) unlink(support, recursive = TRUE)

# Copy into REPORTS/ with the render date. A same-day rerun replaces that day's
# file and leaves earlier dates alone.
reports_dir <- here::here("REPORTS")
if (!dir.exists(reports_dir)) dir.create(reports_dir)
dated <- file.path(
  reports_dir,
  sprintf("%s_%s_%s.%s", analysis, stem, format(Sys.Date()), ext)
)
file.copy(flat, dated, overwrite = TRUE)

cat("Built", basename(flat), "in RENDER/, copied to REPORTS/ as",
    basename(dated), "\n")
