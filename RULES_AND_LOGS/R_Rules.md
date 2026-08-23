# R and Quarto Rules

Conventions for R scripts and Quarto content in this project family. Most of
this file applies to any Quarto workflow. Sections marked `(slides)` apply only
to revealjs decks and can be skipped in a manuscript or report project.
Audience: LLM coding agents and future maintainers.

## 1. File roles and ownership

A project holds one or more analyses. Each is a subfolder of `R/` named for the analysis, and it is self-contained: driver, control file, child files, and its own copies of the R starters.

- Driver file in `R/<Analysis>/` runs render end-to-end.
- Control QMD in `R/<Analysis>/` owns slide or section order and includes child QMD files from the same folder.
- Analysis scripts in `R/<Analysis>/*.R` generate model outputs and figures.
- Child slide files in `R/<Analysis>/*.qmd` present narrative, figures, and lightweight tables.

`RENDER/`, `REPORTS/`, `FIGURES/`, and `MD/` are flat at the project root and shared by every analysis. They have no matching subfolders. Anything written there needs a name that will not collide with another analysis, which is why driver output carries the analysis name as a prefix.

## 2. Source order and setup

Each analysis has its own copies of the starters, in its own folder. Name the analysis once at the top of the setup chunk, then build every path from it.

In control QMD setup chunk:

1. Set `analysis` to this folder's name.
2. Source `000-Libraries.R` from that folder.
3. Source `001-Environment-settings.R` from that folder.
4. Source analysis scripts needed to generate referenced assets.

Example:

```r
analysis <- "Project1"
source(here::here("R", analysis, "000-Libraries.R"))
source(here::here("R", analysis, "001-Environment-settings.R"))
source(here::here("R", analysis, "021-Item-Response-Theory-01.R"))
```

Use `here::here()` rather than a path relative to the working directory. Quarto's working directory depends on how the render was invoked, and `here::here()` does not.

`here::here()` needs a root marker. The scaffold puts a `.here` file at the project root, and an `.Rproj` works too. If either is missing or gets deleted, `here()` falls back to the working directory and every path resolves to the wrong place, usually without an error. Check for it first when paths behave strangely.

Keep setup chunk `include: false` unless there is a deliberate pedagogic reason to show code.

## 2.5 Shared helper functions

When a helper function is used across multiple etudes or projects (e.g., `show_out_section.R` for extracting Mplus output blocks), store it as a standalone R file in `R/` and source it from the setup chunk of each Control QMD:

```r
source(here::here("R", "show_out_section.R"))
```

Do not inline the helper definition into analysis scripts. This avoids duplication, simplifies maintenance, and ensures all projects use the same version.

Example: `R/show_out_section.R` extracts and formats sections from Mplus `.out` files into scrollable HTML blocks for revealjs slides. It is sourced by Etudes 06, 08, and 11.

## 3. Path and output rules

- Do not hardcode absolute paths. Build every path with `here::here()`.
- Save generated figures only to `FIGURES/`, which is flat and shared. Section 4 naming keeps analyses from colliding there.
- Save generated markdown/tables only to `MD/` when intended for inclusion. Also flat and shared.
- Save intermediate artifacts and analysis outputs to `R/RDATA/`.
- `TEMPLATES/` holds this project's pandoc reference documents, referenced from control-file YAML as `../../TEMPLATES/reference_<type>.docx`. They are working files and get restyled per project.
- `RENDER/` holds driver output only. Do not write to it yourself and do not read from it as a stable location, because a rerun replaces what is there.
- Finished reports live in `REPORTS/`, copied out of `RENDER/` by the driver with the analysis name and the date in the filename.

## 4. Figure naming, sizing, and devices

Use stable ordered names to match section and figure sequence:

- `NN-XX-short-slug.png`
- `NN-XX-short-slug.pdf`

Example: `021-01-spelling-icc.png`, `025-02-girder-dif-icc-difmagnitude.pdf`.

Recommended defaults for slide-ready plots:

- `fig_width <- 8`
- `fig_height <- 6`
- `dpi <- 300` for PNG

Preferred devices:

- PNG: `ragg::agg_png`
- PDF: `cairo_pdf`

These handle shaped text and multibyte glyphs more reliably than base devices.

## 5. Plot styling consistency

- Compute a single base text size and scale dependent text from it.
- Use explicit color vectors with stable group/item mapping.
- Suppress non-essential legends when labels are drawn on lines.
- Keep axis labels mathematically explicit (for example with `latex2exp::TeX`).
- Add concise subtitle/stat text directly in plot where interpretation depends on it.

## 6. Child QMD slide conventions (slides)

- One conceptual unit per slide.
- Use `::: columns` with explicit widths for side-by-side figure/text slides.
- Use slide-local font scaling via wrapper blocks when needed.
- Include figures with `knitr::include_graphics("FIGURES/<name>")` and set `#| out-width: 100%`.
- Provide `fig-alt` text for non-decorative graphics.

## 7. Table conventions in QMD

- Build compact tables in chunk code and format with `kableExtra`.
- Keep digits and labels readable at slide scale.
- Use explicit item ordering; do not rely on accidental column order.

## 8. Runtime package policy

- `R/000-Libraries.R` may install missing dependencies.
- Analysis scripts in `R/*.R` should fail fast for missing critical packages instead of installing during run.
- If a non-CRAN package is required, state it in script header `Requirements`.

## 9. Special slide type: downloads (slides) (like `R/082-Downloads.qmd`)

Use this pattern for downloadable model files in self-contained revealjs HTML:

- Base64-encode file payloads into data URIs.
- For `.inp` downloads, sanitize `FILE = "...dat";` statements to basename only.
- Keep helper functions inside the slide chunk (`make_download_link`, `sanitize_mplus_inp_text`).
- Render links with `results: asis` and explicit HTML list tags.

Important robustness rule:

- Do not hardcode hashed `.dat` filenames when possible.
- Prefer discovering the `.dat` file at runtime with `list.files()` in the model output directory, matching the input stem.

## 10. Driver file: rendering into RENDER/ and REPORTS/

**Rule: never pass `--output-dir`.**

Quarto 1.7+ silently deletes all pre-existing files in the `--output-dir` directory before writing new output. `RENDER/` is flat and shared by every analysis in the project, so pointing the flag there destroys the other analyses' build output on each render. Pointing it at `REPORTS/` destroys the dated archive. There is no safe target.

Render in place instead, beside the control file, then move and copy.

**Correct pattern for all Driver files:**

```r
analysis <- "Project1"   # this folder's name
stem     <- "slides"     # control file is <stem>_Control.qmd
ext      <- "html"

src_dir <- here::here("R", analysis)
built   <- file.path(src_dir, paste0(stem, "_Control.", ext))

# 1. Build next to the control file. No flag, nothing deleted.
quarto::quarto_render(
  input         = file.path(src_dir, paste0(stem, "_Control.qmd")),
  output_format = "revealjs",
  output_file   = basename(built)
)

# 2. Move into the flat RENDER/, prefixed by the analysis so two subfolders
#    cannot collide.
render_dir <- here::here("RENDER")
if (!dir.exists(render_dir)) dir.create(render_dir)
flat <- file.path(render_dir, sprintf("%s_%s.%s", analysis, stem, ext))
file.rename(built, flat)

# 3. Copy into REPORTS/ with the render date appended.
reports_dir <- here::here("REPORTS")
if (!dir.exists(reports_dir)) dir.create(reports_dir)
file.copy(
  flat,
  file.path(reports_dir,
            sprintf("%s_%s_%s.%s", analysis, stem, format(Sys.Date()), ext)),
  overwrite = TRUE
)
```

A same-day rerun replaces that day's file in `REPORTS/` and leaves earlier dates alone.

Note: `--output REPORTS/filename.html` (path form) is rejected by Quarto 1.7 with *"--output option cannot specify a relative or absolute path"*, so `output_file` takes a bare filename and the move step does the rest.

## 11. LaTeX math display conventions (slides)

### Rendering LaTeX Math in Slides

For display math equations in slides, use the `teximg` chunk format which renders LaTeX as high-quality SVG or PNG images:

```r
```{teximg, echo=FALSE, out.width='40%', fig.align='center', fig.alt='Formula for correlation coefficient rho equals tanh of square root of 8 divided by n'}
\[
  \rho = \text{tanh}\left[\sqrt{8/n}\right]
\]
```
```

**Accessibility Requirement:**

⚠️ **All math equations rendered as images MUST include `fig.alt` text** for screen reader accessibility. The alt text should:

- Describe the equation in plain language
- Be concise but complete
- Use words like "equals", "divided by", "square root", etc.
- Avoid reading LaTeX syntax literally

Examples of good alt text:
- `fig.alt='Regression equation: f-hat equals B times x'`
- `fig.alt='MAP estimate: f-hat subscript MAP equals the argument that maximizes p of f given x'`
- `fig.alt='Variance of factor score is less than variance of true factor'`

**Setup Requirements:**

1. Include the teximg knitr engine in your control QMD file:

```r
```{r}
#| child: "R/KnitrEngine-teximg.QMD"
```
```

2. System dependencies (must be installed):
   - TeX Live/MacTeX (includes `latexmk` and `pdfcrop`)
   - Poppler (for SVG: `brew install poppler`)
   - OR ImageMagick (for PNG: `brew install imagemagick`)

**Benefits:**

- True LaTeX rendering (not MathJax approximation)
- Better control over equation sizing via `out.width`
- Consistent rendering across all output formats
- SVG output for crisp display at any resolution
- Centered display by default

**Options:**

- `fig.alt`: **Required** alt text for accessibility (plain language description of equation)
- `out.width`: Control image width (default: `'70%'`)
- `fig.align`: Alignment (default: `'center'`)
- `svg`: Output as SVG (default: `TRUE`) or PNG (`FALSE`)
- `dpi`: Resolution for PNG output (default: `300`)
- `outdir`: Directory for generated images (default: `'teximg'`)
- `keep`: Keep intermediate files (default: `FALSE`)

Inline math can still use standard `$...$` notation for MathJax rendering.

## 12. Download links in embed-resources slides (slides)

Use this pattern to embed a file as a base64 download link in a self-contained revealjs HTML:

```r
b64 <- jsonlite::base64_enc(readBin(path, "raw", file.info(path)$size))
knitr::asis_output(paste0(
  '<a href="data:application/octet-stream;base64,', b64,
  '" download="filename.dta">⬇ Download filename.dta</a>'
))
```

The chunk must have `#| results: asis`.

**Down-arrow icon:** Use the literal UTF-8 character `⬇` (U+2B07) directly in the string. Do **not** use the HTML entity `&#11123;` (U+2B73) — it renders as tofu in most browsers due to poor font coverage.

**MIME type:** use `application/octet-stream` for binary files (`.dta`, `.dat`); use `text/plain` for plain-text files (`.inp`, `.csv`).

**Chunk ordering:** the labeling/saving step must complete before the `readBin()` call so the download reflects the final file.

## 13. Robustness checks before render

Before final render, verify:

- Every `include_graphics` target exists in `FIGURES/`.
- Output filenames are stable and match slide references.
- Driver renders to `REPORTS/` without manual intervention.

## 14. Child QMD files: no YAML front matter (slides)

Child QMD files included into a Control deck via `{{< include ... >}}` must **not** carry their own YAML front matter (no `---` block at the top). The Control file's YAML must be the single source of truth for deck-level metadata (title, author, date, format, theme, `include-in-header`, etc.).

Rationale: when Quarto merges metadata from included children, a child's `title:` silently overrides the Control's `title:` in the rendered output. Other deck-level keys can be clobbered the same way. Removing YAML from children makes the Control's metadata unambiguously authoritative.

Formatting/CSS that controls code-window scrolling and slide layout (e.g., `.reveal pre { max-height: 55vh }`) lives in the Control's `include-in-header` block, **not** in child YAML.

## 15. Section-title slides: level-2 heading with styled span (slides)

To introduce a major section inside a deck (the visual equivalent of a level-1 heading), use a level-2 heading with an inline styled span instead of `#`:

```
## [Metric Invariance Model]{style="font-size: 2em; text-align: center;"}
```

Rationale: level-1 headings (`#`) create a new revealjs section/title-slide structure that breaks slide-to-PDF export (printing). A level-2 heading keeps the slide flat and printable, while the styled span gives it visual weight equivalent to a section divider.

Note: `text-align: center` typically has no effect on a level-2 heading in revealjs (the heading's container does the centering), but it is retained for clarity of intent and in case of theme changes.

## 16. Slide headers: level-2 only (`##`) (slides)

In a revealjs QMD slide deck, **every slide title must use a level-2 header (`##`)**. Never use level-1 (`#`), level-3 (`###`), or deeper headings as slide titles.

- `#` creates a revealjs section/title-slide structure that breaks PDF export (printing).
- `###` and below do not create new slides in revealjs — they render as in-slide subheadings (plain bold text), not new slide boundaries.

If you need a visually prominent section-divider slide, use a level-2 heading with a styled span (see rule above). If you need a subheading *within* a slide, use `###` or a bold paragraph — but do not expect it to start a new slide.
