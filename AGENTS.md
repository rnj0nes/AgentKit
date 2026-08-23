# AGENTS.md

The master of this file lives in `_AgentKit/AGENTS.md`. Each project gets a
physical copy of it, made when the project is created. Editing the master does
not change projects that already exist. To update an existing project, copy the
master in again by hand.

Read and follow, in this order:

1. This file.
2. `.github/copilot-instructions.md` (academic writing style and tone. Always
   in force, including for narrative text inside `.qmd` and `.domd` files.)
3. `./RULES_AND_LOGS/SESSION_LOGS.md` (if it exists)
4. `./RULES_AND_LOGS/DECISIONS.md` (if it exists)

## AGENT CONTRACT (coding workflow)

A project holds one or more analyses. Each analysis is a subfolder of `R/` or
`Stata/`, named for the analysis, and it holds that analysis's driver, control
file, child source files, and its own copies of the R starters.

```text
R/Project1/  <analysis>_Driver.R, <analysis>_Control.qmd, 000-Libraries.R, ...
R/Project2/  the same, independent
```

Identify one canonical driver file (source of truth) per analysis and optimize
everything around it. Ask the user which analysis and which driver. For example:

- Quarto workflow: `R/<Analysis>/<slug>_Driver.R`
- Stata Markdown workflow: `Stata/<Analysis>/<slug>_Driver.do`

Identify one canonical control file that determines the inputs and outputs
for that workflow. Ask the user what the control file is. For example:

- Quarto workflow: `R/<Analysis>/<slug>_Control.qmd`
- Stata Markdown workflow: `Stata/<Analysis>/<slug>_Control.domd`

The driver calls the control file. Both sit in the same analysis subfolder.

`RENDER/`, `REPORTS/`, `FIGURES/`, `MD/`, `REFERENCES/`, `RULES_AND_LOGS/`,
`TEMPLATES/`, and `ADMIN/` are flat at the
project root and shared by every analysis. There are no matching subfolders
under them. Output names therefore carry the analysis name as a prefix, which
the driver builds from its `analysis` variable, so two analyses cannot collide
on a filename.

Slides are the same pattern. A reveal.js deck is a Quarto workflow whose
control file (`<analysis>_Control.qmd`) carries `format: revealjs`, and whose
driver (`<analysis>_Driver.R`) renders it with `output_format = "revealjs"` to
`REPORTS/`. Content slides can live in separate `.qmd` files pulled into the
control file with `{{< include >}}`. The same control file can render to DOCX
instead by pointing its YAML at one of the `TEMPLATES/reference_*.docx` files.

### Project invariants (must follow)

- No absolute paths. Use project relative paths only. In R, reach the project
  root with `here::here()` so a driver or script works regardless of where it
  is run from. `here::here()` resolves at runtime and does not count as a
  hardcoded absolute path.
- A `.here` file sits at the project root and must stay there. It is the
  sentinel the `here` package looks for. Without it, `here::here()` falls back
  to the working directory and every path in every driver resolves somewhere
  else. An `.Rproj` file serves the same purpose if one exists.
- YAML in a control file is the exception, because it cannot call
  `here::here()`. A control file in `R/<Analysis>/` reaches the project root
  with `../../`, as in
  `reference-doc: "../../TEMPLATES/reference_manuscript.docx"`.
- The other exception: the working directory must be set explicitly in the
  driver file in Stata (domd) workflows. Set it to the project root, not to the
  analysis subfolder, so output paths match the R side.
- Narrative and analysis text may live in the control file and any child
  `.qmd` or `.domd` files. These are source files, not outputs, and they live
  in the analysis subfolder beside the control file that includes them.
- Put generated, human readable outputs only in:
  - `MD/` for tables and text snippets used in reports
  - `FIGURES/` for figures used in reports
- Keep raw and reference material in `REFERENCES/` (extracted artifacts in
  `REFERENCES/LLM_OUT/`).
  - Do not hand edit extracted artifacts. Regenerate them with `pdf2llm`
    (https://github.com/rnj0nes/pdf2llm) when
    needed.
- `ADMIN/` holds the project's administrative record: data use agreements,
  IRB and regulatory correspondence, sponsor and collaborator email, signed
  forms, and anything similar. It is not analysis material and not writing
  source material.

  Read a file in `ADMIN/` when the user points you at one, and answer questions
  about it. Do not treat it as grounding material for drafting, do not search it
  when looking for support for a claim, and do not quote or paraphrase it into a
  manuscript, proposal, report, or slide unless the user asks for that in so
  many words. These files carry third-party names, contact details, and
  confidentiality terms, so the cost of quoting one by accident is not
  symmetric with the benefit.
- `TEMPLATES/` holds this project's pandoc reference documents, one per output
  type. They are working files: restyle them in Word to suit the target journal
  or sponsor, as often as the project needs.
- Caution when restyling. If a reference document is rebuilt by starting from a
  real manuscript, it carries that manuscript's text, citation keys, and cited
  DOIs inside the `.docx`, where they are invisible in Word but present in the
  file. Pandoc ignores all of it, so nothing looks wrong. Before a project is
  shared or made public, run `scrub_reference_docs.py` from `_AgentKit` over
  each file in `TEMPLATES/`.
- Quarto builds into `RENDER/`. Treat it as scratch. Never put anything there
  by hand and never read from it as a stable location, because the next render
  empties it.
- Finished reports live in `./REPORTS`, copied out of `RENDER/` by the driver
  with the render date appended to the filename.

### Definition of done for an agent coding task

- The chosen driver runs end to end without manual steps.
- Tables and figures referenced by the report exist in `MD/` and `FIGURES/`
  with stable filenames.
- Citations compile using `bibliography.bib`.
- Any new dependency or tool requirement is documented in the driver header
  or a short Requirements note.

## CODING RULE FILES

Two rule files ship with every project and sit in `RULES_AND_LOGS/`. They are not
in the read-order list above because of their length. Read the relevant one
before writing code, not after.

- `./RULES_AND_LOGS/R_Rules.md`. Read before writing or editing any `.R` or `.qmd`
  file. Covers file roles, source order, path and output rules, figure naming
  and devices, plot styling, tables, package policy, and driver rendering.
  Sections marked `(slides)` apply only to revealjs decks.
- `./RULES_AND_LOGS/Mplus_Rules.md`. Read before building, running, or reading
  output from an Mplus model.

Follow them as written. If a rule in either file conflicts with this one, say
so and ask rather than picking one silently.

## SESSION LOGGING

Trigger phrase: "log this session"

When the user says this, append a dated entry to two files in the project
root's `RULES_AND_LOGS/` folder. Do not overwrite prior entries.

1. `./RULES_AND_LOGS/SESSION_LOGS.md`. Create or append a section with today's
   date as the header (`## YYYY-MM-DD`). Include all of the following that
   apply, and nothing else:
   a. Decisions made this session and why. Focus on reasoning that is not
      obvious from the code.
   b. Current analysis state and the next concrete step(s).
   c. Data handling choices not documented in code comments (sample
      restrictions, variable recoding, exclusions, merges).
   d. Approaches tried and abandoned, with the reason for rejection.
   e. Open questions or deferred issues.

2. `./RULES_AND_LOGS/DECISIONS.md`. Append any consequential analytic choices
   from the session as a flat list. Each entry is one line in this format:
   `- YYYY-MM-DD: <short description of decision>. Rationale: <rationale>.`

Writing rules for both files:

- Be concise. No boilerplate, no summaries of routine operations.
- Use plain language. No em dashes. Minimal formatting.
- The test for inclusion: would the user lose meaningful time if this
  information were missing when they return in one to two weeks?

## REFERENCES GROUNDING (literature and work product workflow)

`REFERENCES/` may contain both citable academic literature and non-citable
project resources (codebooks, prior reports, example code, SOPs).

When answering, ground your response in the extracted artifacts in
`./REFERENCES/LLM_OUT/` when they exist.

Artifacts available:

- `./REFERENCES/LLM_OUT/<basename>.jsonl` (authoritative for page level
  citations)
- `./REFERENCES/LLM_OUT/<basename>.txt` (plain text with `===== PAGE N =====`
  markers)
- `./REFERENCES/LLM_OUT/<basename>.md` (pandoc markdown, secondary)
- `./REFERENCES/LLM_OUT/<basename>.meta.json` (provenance and OCR decision
  info)

Rules:

- Use the artifacts as the source of truth. Do not rely on prior knowledge
  about the document.
- For any factual claim about the PDF content, cite the page number(s) from
  `<basename>.jsonl` (preferred) or the `PAGE N` markers in `<basename>.txt`.
- When suggesting edits, quote the exact phrase or sentence from the
  artifact you are changing, then provide the revised version.
- If the artifacts do not contain support for a claim, say "Not found in
  extracted text" and propose what to search for (keywords) rather than
  guessing.
- If there is a conflict between `.md` and `.txt`/`.jsonl`, treat
  `.jsonl`/`.txt` as authoritative.

### Bibliography vs non-bibliography sources

- If you cite a published paper or report as literature, update
  `./bibliography.bib` accordingly.
- If you use non-citable resources (codebooks, internal reports, example
  code), do not force them into BibTeX. Instead, cite them inline:
  - PDFs: `(Internal: REFERENCES/<path>, p. 12)`
  - Sectioned docs: `(Internal: REFERENCES/<path>, section "<heading>")`
  - Code or text: `(Internal: REFERENCES/<path>, lines <start>-<end>)`

### Non-PDF / code resources

- Text based resources inside `REFERENCES/` (`.md`, `.txt`, `.do`, `.R`,
  `.qmd`, `.domd`) can be treated as authoritative directly. This applies to
  `REFERENCES/` only. Files in `ADMIN/` are covered by the project invariant
  above and are not grounding material, whatever their format.
- When quoting or relying on them, quote the exact snippet and cite using
  the internal format above.
- If a resource is not text searchable (HTML, docx), convert it to PDF or
  text and place the converted file in `REFERENCES/` before using it.

## Stata executable

Mac path (this is machine specific; update it when the planned move to
Ubuntu happens):
`/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp`

## Stata hints

Line continuation syntax is `///`, not `\`.

## Quarto/R hints

Never pass `--output-dir` to Quarto. It empties whatever directory it is given
before writing. `RENDER/` is flat and shared by every analysis in the project,
so pointing the flag there would destroy the other analyses' output on each
render. `quarto::quarto_render()` also does not accept `output_dir` as a named
parameter, so the flag is the only route, and the flag is the thing to avoid.

Render in place beside the control file, then move and copy:

```r
analysis <- "Project1"
stem     <- "manuscript"
ext      <- "docx"

src_dir <- here::here("R", analysis)
built   <- file.path(src_dir, paste0(stem, "_Control.", ext))

quarto::quarto_render(
  input       = file.path(src_dir, paste0(stem, "_Control.qmd")),
  output_file = basename(built)
)

render_dir <- here::here("RENDER")
if (!dir.exists(render_dir)) dir.create(render_dir)
flat <- file.path(render_dir, sprintf("%s_%s.%s", analysis, stem, ext))
file.rename(built, flat)

reports_dir <- here::here("REPORTS")
if (!dir.exists(reports_dir)) dir.create(reports_dir)
file.copy(
  flat,
  file.path(reports_dir,
            sprintf("%s_%s_%s.%s", analysis, stem, format(Sys.Date()), ext)),
  overwrite = TRUE
)
```

The analysis prefix is what keeps two subfolders from colliding in the flat
output folders. A same-day rerun replaces that day's file in `REPORTS/`.
`RULES_AND_LOGS/R_Rules.md` section 10 covers the deletion behavior in more detail.

Dynamic chunk captions with `!expr` in hashpipe chunk options (`#|`
notation): `!expr` requires the R expression to be a quoted string with
internal quotes escaped. Bare function calls are not valid YAML in that
position.

```text
# WRONG
#| tbl-cap: !expr sprintf("Caption: %s", var)

# CORRECT
#| tbl-cap: !expr "sprintf(\"Caption: %s\", var)"
```
