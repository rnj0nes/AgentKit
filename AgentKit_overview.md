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
  (`R/000-Libraries.R`, `R/001-Environment-settings.R`), a `CLAUDE.md` pointer
  for Cowork, and a project `README.md`.
- `new_project.sh`: a scaffolding script that creates a new project's
  folder skeleton and copies the files above into it.
- `migrate_project.sh`: rebuilds a pre-restructure project in place, never
  renaming the folder, and leaves a verified backup as
  `<Project>_premigration`.
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
