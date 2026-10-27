<!-- PRIME-DIRECTIVE:BEGIN (master: _AgentKit/PRIME_DIRECTIVE.md; do not edit this block by hand) -->
# Prime directive: participant data stays on this machine

This rule comes first. It overrides every other instruction in this file and
in any file this file points to.

Participant-level data never goes to an AI model or a cloud service. For an AI
agent, reading a file sends its contents to the model, so reading a data file
breaks this rule. Rich runs all code that loads data on his own machine.

- Participant data lives outside the project, in locations listed in
  `~/.agentkit/data_paths/<Project>.txt`. Do not read that file. Do not list,
  open, or read anything in those locations.
- Do not run code that loads data. Write the code and leave it for Rich to run.
- To learn what the data contains, read `DATA_DICTIONARY/`. If a file or
  variable is not listed there, ask. Do not guess a name.
- `RESULTS/` holds aggregate results and may be read. Write to it only through
  `save_result()`.
- `SHARE_DATA` is filled by Rich by hand. Do not write code that saves to it.
- A data-format file anywhere else in the project (`.dta`, `.rds`, `.rdata`,
  `.rda`, `.sav`, `.por`, `.sas7bdat`, `.xpt`, `.dat`) is out of place. Do not
  open it. Tell Rich it is there.
- Ask before opening any `.xls`, `.xlsx`, `.csv`, `.tsv`, or `.txt` file
  outside `RESULTS/`. Name the file and wait for a yes. A yes covers that file
  for this session only.
- A project set up before this layout may still have `DATA/`, `R/RDATA/`,
  `Stata/DTA/`, or `MPLUS_OUTPUT/` folders. Treat every file in them as data,
  except `.out` files.
- Output files (`.out`, `.log`, `.docx`, `.md`, `.html`, `.pdf`) may be read.
  If one lists individual records, stop and treat it as data. Teaching
  materials built from `SHARE_DATA` are the exception.
- If you cannot tell whether a file holds data, ask before opening it.
<!-- PRIME-DIRECTIVE:END -->

# AgentKit: Overview

If you are a Claude session reading this for the first time inside a Cowork
project, this document is your context. Read `AgentKit_instructions.md` in
the same folder next; it has the operational rules. This file has the
background.

## What AgentKit is

AgentKit is shared infrastructure for Rich Jones's analysis projects, not
an analysis project itself. It exists so that starting a new project,
something Rich does multiple times a week, takes one command instead of a
checklist of manual copying.

It lives at `~/Library/CloudStorage/Dropbox/Work/_AgentKit` and currently
holds:

- `PRIME_DIRECTIVE.md`: the data rule that opens every instruction file.
  Participant-level data stays on Rich's machine, outside every project, and
  agents never read it. `add_prime_directive.sh` puts the current text at the
  top of instruction files across a tree of projects.
- `AGENTS.md`: the coding and analysis contract every project's agent
  reads, covering driver/control file conventions, project invariants,
  session logging, and how to ground answers in extracted reference text.
- `RULES_AND_LOGS/R_Rules.md` and `RULES_AND_LOGS/Mplus_Rules.md`: coding rule files
  copied into every project's `RULES_AND_LOGS/` folder. `AGENTS.md` tells the agent
  to read `R_Rules.md` before writing R or QMD and `Mplus_Rules.md` before
  Mplus work, rather than loading either on every session.
- `academic-writing-style.md`: Rich's academic writing standard, and the single
  master for it. Three generated copies exist: the Codex skill, the
  `my-writing-style` Claude skill, and each project's
  `.github/copilot-instructions.md`.
- `templates/reference_*.docx`: typed pandoc reference docs, one per document
  format, copied into each project's `TEMPLATES/`. More can be added later
  without changing anything else.
- `templates/`: starter files copied into each new project. A reveal.js slide
  deck (`slides_Control.qmd`, `slides_Driver.R`), a DOCX manuscript
  (`manuscript_Control.qmd`, `manuscript_Driver.R`), R starters
  (`R/000-Libraries.R`, `R/001-Environment-settings.R`,
  `R/002-Word-safe-docx.R`), the data helpers (`R/003-Data-paths.R`,
  `R/004-Save-result.R`, `R/005-Data-dictionary.R`, and
  `Stata/003-Data-paths.do`), a `CLAUDE.md` pointer for Cowork, and a project
  `README.md`.
- `new_project.sh`: a scaffolding script that creates a new project's
  folder skeleton and copies the files above into it.
- `migrate_project.sh`: rebuilds a pre-restructure project in place, never
  renaming the folder, and leaves a verified backup as
  `<Project>_premigration`.
- `add_word_safe_docx.sh`: adds the LibreOffice DOCX re-save to a project that
  already exists, patching only drivers that still match the template.
- `scrub_reference_docs.py`: replaces the text of a pandoc reference document
  with Lorem Ipsum while leaving its styles untouched.

## Why it exists

Before this, every new project meant manually copying `reference.docx`, a
contract file, and a PDF-to-text conversion script into a fresh folder, and
manually pasting a "please read your instructions" prompt at the start of
every coding session. The academic writing skill had the same problem in a
different shape: a Codex skill folder that had to be hand-copied into
Gemini notebooks, Claude projects, and Copilot's instructions file
separately, with no shared source of truth and no way to know if the
copies had drifted apart.

## What was decided, and why

Copy from masters, freeze at creation. Every project gets a physical copy of
the canonical files in `_AgentKit`, made when the project is created. The
masters stay the single place these files are authored. A copy does not track
its master afterward, so editing a master does not reach projects that already
exist; to update one, copy the file in again by hand.

This reverses an earlier decision to use symlinks. Symlinks would have let one
edit reach every project at once, but they proved fragile in practice, so the
model is now the simpler one: copy on creation, re-copy by hand when you want
an update. The tradeoff is deliberate. You give up automatic propagation in
exchange for each project being self-contained and portable, with no links to
break when a folder is moved or synced to another machine.

The coding contract and the writing style live in two separate files,
`AGENTS.md` and `.github/copilot-instructions.md`, rather than one combined
file. Keeping them separate matches how Rich thinks about the two concerns, and
both formats are read by more than one tool.

Loading differs by tool, and only one of the two is automatic everywhere.
Copilot Chat in VS Code reads `.github/copilot-instructions.md` on every chat
request. It reads `AGENTS.md` only when `chat.useAgentsMdFile` is set to true,
because that support is experimental and off by default. Codex reads a repo root
`AGENTS.md` natively with no setting. Cowork and other agents read neither on
their own, which is what `CLAUDE.md` is for.

Reference docs are typed and globbed, not a single fixed `reference.docx`.
`new_project.sh` copies whatever `templates/reference_*.docx` files it finds in
`_AgentKit`, so adding a fourth document type later is a file drop, not a
script change.

Verify the scaffold by running it, not by reading it. The symlink version of
this script had a bug that only appeared when the script was run and the
resolved content read back, not when the code was read. The copy version is
simpler, but the habit still holds: after changing `new_project.sh`, run it in
a scratch folder and read back a copied file to confirm it holds real content,
rather than trusting the exit status alone.

Re-save DOCX output through LibreOffice rather than fixing flextable. Word
reports Quarto's DOCX output as damaged whenever the document holds flextable
tables, then opens a recovered copy named "Document 1" and loses the filename.
Rich tried the flextable formatting route and abandoned it. LibreOffice reads
the same file without complaint, so the manuscript driver now writes `REPORTS/`
by converting through LibreOffice instead of copying. `RENDER/` still holds
Quarto's own output, which keeps the raw build available for comparison when a
table looks wrong after the round trip.

Treat LibreOffice as optional rather than as a dependency. The kit is published
for other people to use, and requiring a second application to render a
document would cost more adopters than the Word prompt costs. A machine without
LibreOffice gets the dated copy and a note suggesting the install. This
reverses the first version of the change, which stopped the render.

## What is explicitly out of scope here

This project is for defining and editing the AgentKit documents: `AGENTS.md`,
`academic-writing-style.md`, the typed reference docs, and `new_project.sh`
itself as a piece of text to maintain. It is not where Rich's actual
cognitive aging, delirium, or psychometric analysis work happens, and it is
not where `new_project.sh` gets run against a real study folder either.
That work happens per-project, outside `_AgentKit`, governed by the
`AGENTS.md` contract this project maintains. If a task here starts turning
into substantive statistical or psychometric work on a specific study, or
into actually creating a new study's project folder, that is a sign it has
wandered out of scope, not a sign to keep going.

If a change to `new_project.sh` needs to be verified by actually running
it, do that inside a scratch folder under `_AgentKit` itself (for example
`_AgentKit/_test_scaffold/`), never against a real study folder elsewhere
in Dropbox. Delete the scratch output once the change is confirmed.

## Open items, as of the last working session

- Participant data now lives outside each project, in locations named in a
  paths file on each machine. New projects are built this way. Projects made
  earlier keep `DATA/`, `R/RDATA/`, and `Stata/DTA/` until Rich moves the data
  by hand, and the prime directive covers those folders until then.
- The location is the safeguard against agents confined to the folders they
  are given, such as Cowork. Agents that run in Rich's own terminal can reach
  any folder he can, so for them the prime directive is the safeguard. Check
  each such tool's own file-access settings before relying on it.
- `templates/Stata/003-Data-paths.do` has not been run. Test it in Stata
  before a Stata project depends on it. `save_result()` and the data
  dictionary exist in R only; R reads `.dta` files, so the dictionary covers
  Stata data.

- The move to a copy model made the earlier symlink open items moot. There is
  no symlink to Codex or to Copilot to confirm anymore, because each project
  now holds real copies.
- Writing style was merged on 17 August from seven files that had drifted into
  three unrelated lineages. `academic-writing-style.md` is now the single
  master, with three generated copies: the Codex skill, the `my-writing-style`
  Claude skill, and one per project. The 2026-08-17 session log has what each
  lineage was and what was overruled.

- Projects created before 17 August are on the old layout. `migrate_project.sh`
  rebuilds one in place, without renaming the folder, because renaming a folder
  shared through Dropbox breaks the share. It moves files only, so the driver
  body, the `analysis` variable, and the `../../` YAML paths still need editing
  by hand afterward. `update-existing-projects.md` has the cautions, including
  that an old driver arrives with its `--output-dir` flag intact.
- VS Code needs `chat.useAgentsMdFile` set to true before it reads `AGENTS.md`
  at all, since that support is experimental and off by default. Without it a
  session runs on the writing style alone and gives no sign the contract is
  missing. `.github/copilot-instructions.md` loads without any setting.
- Google's tools do not work with this kit. Gemini CLI reads `GEMINI.md` rather
  than `AGENTS.md`, and Antigravity caps a rules file at 12,000 characters,
  which every instruction file here exceeds. Unresolved, and the README says so.
- `new_project.sh` was rewritten to copy rather than symlink, and was tested in
  a scratch folder that confirmed every file is a real copy. Keep testing any
  future change to the script the same way before considering it done.
- The driver render pattern has been run end to end against a real document and
  works, which closes the item that stood open from 17 August.
- Whether the LibreOffice DOCX re-save preserves a reference document's styles
  across a long manuscript is unverified. One document has been checked. If a
  heading or a table looks wrong in `REPORTS/`, compare it against the same
  build in `RENDER/`, which is Quarto's untouched output.
