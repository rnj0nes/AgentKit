# Project README

This project was scaffolded from AgentKit. It supports four kinds of work:
literature and research support, brainstorming grounded in your references,
slide decks (QMD to reveal.js), and manuscripts (QMD to DOCX). The data
analysis path (QMD to R to DOCX) uses the same structure and is ready when you
are.

Read `CLAUDE.md` and `AGENTS.md` before starting. They tell any agent how to
behave in this project. `.github/copilot-instructions.md` holds your writing
style and is always in force.

## What is where

- `AGENTS.md`: the coding and analysis contract.
- `.github/copilot-instructions.md`: your academic writing style.
- `.github/copilot-instructions-proposals.md`: the grant adjunct. Copilot does
  not load it on its own, so for a grant project either append it to
  `copilot-instructions.md` or name it in chat when drafting proposal text.
  Ignore it otherwise.
- `CLAUDE.md`: a short pointer so Cowork and other agents load the two files
  above, which they do not read automatically the way VS Code Copilot does.
- `R/<Analysis>/`: one folder per analysis, holding its driver, its control
  file, its child `.qmd` files, and its own copies of the R starters
  (`000-Libraries.R` and `001-Environment-settings.R`, which load first). Add a
  second analysis as a sibling folder. `Stata/<Analysis>/` mirrors this.
- `TEMPLATES/`: this project's pandoc reference docs, one per output type.
  They are working files, so restyle them in Word to suit the journal or
  sponsor. If you rebuild one starting from a real manuscript, it will carry
  that manuscript's text and citations invisibly inside the file, so run
  `scrub_reference_docs.py` from `_AgentKit` over it before sharing the project.
- `RENDER/`: driver output, flat and shared by every analysis. Nothing else
  writes here and a rerun replaces what is there.
- `REPORTS/`: finished output, also flat and shared. The driver copies each
  build out of `RENDER/` with the analysis name and the render date, so
  `Project1_manuscript_2026-02-26.docx` sits beside last week's version and
  beside `Project2_slides_2026-02-26.html`.
- `REFERENCES/`: your source material, and nothing else. Extracted text lands
  in `REFERENCES/LLM_OUT/` after you run `pdf2llm`.
- `RULES_AND_LOGS/`: `R_Rules.md` covers R and Quarto conventions and
  `Mplus_Rules.md` covers Mplus, so read whichever the task calls for before
  writing code. `SESSION_LOGS.md` and `DECISIONS.md` appear here the first time
  you say "log this session".
- `MD/`, `FIGURES/`, `EXCALIDRAW/`: generated tables, figures, and diagrams,
  flat and shared across analyses.
- `ADMIN/`: the project's administrative record. Data use agreements, IRB and
  regulatory correspondence, sponsor and collaborator email, signed forms. Your
  agent will read a file here if you point it at one, but it will not use this
  folder as source material and will not quote it into a document unless you
  ask for that directly. These files carry other people's names and
  confidentiality terms.
- `bibliography.bib`: citations. Ask your agent to build it from `REFERENCES/`.
- `.here`: the root marker `here::here()` needs. Do not delete it. Without it
  every path in every driver silently resolves to the wrong folder.

These files are copies, not links. They were taken from `_AgentKit` when the
project was created and they do not update on their own. If a shared master
changes and you want the change here, copy it in by hand.

## First steps

1. Rename `R/Analysis1/` to your analysis name, then set the `analysis` line at
   the top of each `Driver.R` and each `Control.qmd` in that folder to match.
2. Put your source PDFs in `REFERENCES/`, give them short names such as
   `Jones-2003.pdf`, then run `pdf2llm` on them so the extracted text lands in
   `REFERENCES/LLM_OUT/`. The tool is at https://github.com/rnj0nes/pdf2llm,
   and the kit workflow doc has the usage.
3. Ask your agent to build `bibliography.bib` from `REFERENCES/`, in APA or AMA
   style, citing specific page numbers when needed.

## Literature, research, and brainstorming

Your agent grounds its answers in the extracted text under
`REFERENCES/LLM_OUT/`, not in prior knowledge about a document. For any factual
claim about a source, it cites the page number. If the extracted text does not
support a claim, it says so rather than guessing. This is set out in the
REFERENCES GROUNDING section of `AGENTS.md`.

For brainstorming, point the agent at the relevant references first, then ask.
Grounded ideas beat ungrounded ones, and the citations let you check them.

## Slides (QMD to reveal.js)

The deck is `R/<Analysis>/slides_Control.qmd`. It carries the reveal.js YAML and
the CSS you use, and it pulls in content slides with `{{< include >}}`. Write
each topic as its own file in the same folder, such as `031-my-topic.qmd`, using
`##` to start each slide. Include the files in the control file in the order you
want them shown.

Render with:

```r
source(here::here("R", "<Analysis>", "slides_Driver.R"))
```

Output is a single self-contained HTML file, built in `RENDER/` and copied to
`REPORTS/` with the date appended. Images are embedded, so the file travels on
its own.

The title-slide watermark is commented out in the control file's YAML, because
the scaffold does not create the image and Quarto fails rather than warns on a
missing background. To use one, drop an image at `FIGURES/watermark.png` and
uncomment the four `title-slide-attributes` lines.

## Manuscripts (QMD to DOCX)

The manuscript is `R/<Analysis>/manuscript_Control.qmd`. Its YAML points at
`../../TEMPLATES/reference_manuscript.docx` for formatting. Render with:

```r
source(here::here("R", "<Analysis>", "manuscript_Driver.R"))
```

To produce a proposal or an internal report from the same source, change
`reference-doc` in the YAML to `../../TEMPLATES/reference_proposal.docx` or
`../../TEMPLATES/reference_report.docx` and render again.

## Data analysis (QMD to R to DOCX), when you get there

Put analysis code in your analysis folder, following the numbered convention
(`000-Libraries.R`, `001-Environment-settings.R`, then your analysis steps).
Write tables to `MD/` and figures to `FIGURES/` with stable filenames, then
refer to them from the manuscript control file. Because those folders are shared
by every analysis, use names that will not collide. The definition of done for a
coding task is in `AGENTS.md`: the driver runs end to end, the tables and
figures exist, and citations compile.

## Logging your work

Say "log this session" and the agent appends a dated entry to
`RULES_AND_LOGS/SESSION_LOGS.md` and `RULES_AND_LOGS/DECISIONS.md`. Use this at the end
of a working session so you do not lose the reasoning when you return.
