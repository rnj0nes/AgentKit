# AgentKit: Instructions

Read `AgentKit_overview.md` in this same folder first if you have not
already. This file is the operational half; that one is the background.

## Scope

This project is for defining and editing the AgentKit documents:
`AGENTS.md`, `academic-writing-style.md`, the typed `templates/reference_*.docx`
files, the `templates/` starters, and the scripts. Treat all of it as text to
maintain, not as a tool to run against a real study. Do not create or modify a study's
project folder from here, and do not do statistical, psychometric, or
manuscript work on an actual dataset from here. If a task drifts toward
either of those, say so and ask whether it belongs in a different
workspace before continuing.

## Where things live

- `_AgentKit/AGENTS.md`: the coding and analysis contract.
- `_AgentKit/RULES_AND_LOGS/R_Rules.md` and `_AgentKit/RULES_AND_LOGS/Mplus_Rules.md`:
  coding rule files copied into every project's `RULES_AND_LOGS/`. `AGENTS.md`
  names them and says when to read each one.
- `_AgentKit/VS-Code-workflow.md`: the long-form workflow write-up, covering
  one-time setup, folder layout, and the day-to-day cycle.
- `_AgentKit/migrate_project.sh`: rebuilds a pre-restructure project in place.
  The folder is never renamed or replaced, because renaming a Dropbox-shared
  folder breaks the share. It backs the project up to a sibling, verifies the
  backup by file count and byte total, asks, empties the folder while keeping
  the folder, builds the current structure inside it, copies content back, and
  names the backup `<Project>_premigration` only on success. A failure after
  the erase restores the contents in place. Moves files and never edits their
  contents. This is not the `update_project.sh` rejected on 2 July: that would
  have re-synced masters continuously, and this runs once per project and then
  refuses.
- `_AgentKit/update-existing-projects.md`: how to run the migration, what moves
  where, and what still needs a human afterward.
- `_AgentKit/add_word_safe_docx.sh`: adds the LibreOffice DOCX re-save to a
  project that already exists. It copies `002-Word-safe-docx.R` into every
  analysis folder and patches each DOCX driver. It matches the two statements
  it replaces, the `file.copy(flat, dated, overwrite = TRUE)` call and the
  closing `cat()`, rather than the whole block, because real drivers carry
  their own headers and comments. A driver holding that call zero times or more
  than once is reported and left alone with the replacement text printed. A
  driver whose closing message was rewritten still gets the call patched, and
  the script says the message may no longer read true. Every driver it touches is
  backed up to `<name>.bak` first. It changes no rule files, running it twice
  is safe, and it upgrades a driver still on the first version of the pattern,
  the one that stopped the render when LibreOffice was missing. It reports
  whether LibreOffice is installed but never requires it. This is a one-shot script for one change, so it does not
  reverse the freeze-at-creation model.
- `_AgentKit/README.md`: entry point for the public GitHub repo. Explains the
  method and the reasoning rather than restating the contracts.
- `_AgentKit/.gitignore`: keeps `REFERENCES/Jones_Writing_Samples/` out of the
  repo. That folder holds published articles, unpublished grant text, and a
  study asset inventory, all of which stay local. Anything added there is
  private by default, so put new reference material elsewhere if it should be
  public.
- `_AgentKit/academic-writing-style.md`: the writing style standard, and the
  single master for it. Three generated copies exist and are overwritten from
  it, never edited in place: the Codex skill's `references/style-profile.md`,
  the `my-writing-style` Claude skill, and each project's
  `.github/copilot-instructions.md`.

  Grant and proposal writing has its own standard in the
  `grant-proposal-writing` skill, which cites part numbers from this file. Add
  parts at the end rather than renumbering existing ones.
- `_AgentKit/templates/reference_*.docx`: typed pandoc reference docs, copied
  into each project's `TEMPLATES/` folder.
- `_AgentKit/templates/copilot-instructions-proposals.md`: the grant adjunct,
  generated from the `grant-proposal-writing` skill and copied into each
  project's `.github/`. Regenerate it from the skill when that skill changes.
- `_AgentKit/templates/`: starter files copied into each new project (slide
  deck, manuscript, R starters, `CLAUDE.md`, project `README.md`).
- `_AgentKit/templates/R/002-Word-safe-docx.R`: re-saves a rendered DOCX
  through LibreOffice. Word reports Quarto's DOCX output as damaged whenever
  the document holds flextable tables, and opens the recovered copy under the
  name "Document 1", losing the filename. LibreOffice reads the same file and
  writes it back out in a form Word accepts. `manuscript_Driver.R` sources this
  file and calls `word_safe_docx()` in place of copying into `REPORTS/`, so
  `RENDER/` keeps Quarto's own output and `REPORTS/` gets the version Word
  opens. LibreOffice is optional. Without it the file is copied unchanged and
  the helper prints a note suggesting the install, so someone adopting the kit
  is never blocked by a dependency they have not heard of.
- `_AgentKit/new_project.sh`: the scaffolding script, maintained here as
  source code, not run here against a real project.

## Standing rules

Edit the master files here directly. There is no separate draft copy to merge
back later. Note the change in model: projects now hold physical copies made at
creation, not symlinks, so editing a master does not reach projects that already
exist. When a change to a master should reach an existing project, copy the file
in again by hand.

Never invent or guess content for `AGENTS.md`, `academic-writing-style.md`,
or `SKILL.md`. These encode Rich's actual working preferences and prior
decisions. If something is missing or ambiguous, ask rather than filling
the gap with a plausible-sounding default.

If a change to `new_project.sh` needs to be checked by actually running it,
do that inside `_AgentKit/_test_scaffold/`, never against a real study
folder, and delete the scratch output once the change is confirmed. Read the
copied files back and confirm they hold real content, not just the exit status
of the command that created them. An empty or wrong copy can be created without
any error, so reading the result back is what actually confirms the change.

Before relying on any host-level tool from inside a task here (a CLI like
`code`, an application like Stata or Word, anything outside plain file
read/write), confirm it is actually reachable from wherever this task is
executing rather than assuming it behaves like a normal Terminal session
on Rich's Mac.

Keep changes to `AGENTS.md` and `academic-writing-style.md` consistent
with Rich's writing preferences: short to moderate sentences, active voice,
no em dashes, minimal formatting, one claim per paragraph. This applies to
edits made to these files themselves, not only to the prose they describe.

## Common tasks

Add a new reference doc type: create `reference_<type>.docx` in
`_AgentKit/templates/`. No other file needs to change; `new_project.sh` globs for
`reference_*.docx` rather than naming them individually.

Update the coding contract: edit `AGENTS.md` in place. This changes the master
only. Projects created earlier keep their own copy, so mention the change out
loud and note that existing projects need a manual re-copy to pick it up.

Update the writing style: edit `academic-writing-style.md` in place. The same
copy note applies. Then regenerate all three copies: the Codex skill's
`references/style-profile.md`, and the `my-writing-style` Claude skill, both of
which hold nothing of their own, and any project you want current. Missing the
`my-writing-style` skill is the easy mistake, because the
`grant-proposal-writing` skill loads it as the base standard, so a stale copy
silently degrades every grant drafting session.

Revise `new_project.sh`: edit the script, then verify the change using the
scratch-folder process above before treating the task as finished.

Add the DOCX re-save to an existing project: run `add_word_safe_docx.sh` from
that project's own session, not from here. Its argument is a path and defaults
to the current folder, so run it inside the project with no argument, or pass a
path from anywhere. This is deliberately unlike `migrate_project.sh`, which
takes a project name plus a parent directory. This workspace does not modify a study's project folder. The script
reports which drivers it patched and which it left alone, and the project's
`R_Rules.md` stays behind the master until you copy it in by hand.

Audit AgentKit for problems: check that `_AgentKit` contains exactly the files
it should, that `new_project.sh` is executable, and that `templates/` holds the
current starter files. Since the model is copies rather than symlinks, there is
no link to resolve.

For writing style, check that the Codex skill's `references/style-profile.md`
and the `my-writing-style` Claude skill both match `academic-writing-style.md`.
Both are generated copies, so any difference means the master changed and the
copy was not refreshed. Regenerate rather than merging the two.

Also check that `templates/copilot-instructions-proposals.md` still matches the
`grant-proposal-writing` skill it was generated from, and that the base part
numbers the grant skill cites still resolve in `academic-writing-style.md`.
