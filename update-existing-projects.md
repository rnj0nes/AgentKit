# Updating projects created before 17 August 2026

A project made before that date has the old layout: drivers and control files at
the project root, reference documents loose beside them, no `RULES_AND_LOGS/`,
no `TEMPLATES/`, no `RENDER/`, no `ADMIN/`, and no `.here`. Its `AGENTS.md` and
writing style are older masters.

`migrate_project.sh` rebuilds such a project without ever renaming or replacing
the folder. That matters because a project folder shared through Dropbox loses
its share the moment it is renamed, and everyone it is shared with loses access.

This is not the `update_project.sh` rejected on 2 July. That would have re-synced
masters into projects continuously, which freeze-at-creation exists to avoid.
This runs once per project and then refuses to run again.

## Read this before running it

**Make the project available offline first.** In Finder, right-click the project
and choose Make Available Offline, then wait for it to finish. Dropbox
online-only files copy as placeholders rather than content, and a backup of
placeholders is not a backup. The script compares file count and byte total
between the project and its backup and refuses to erase anything if they differ,
so this failure is caught rather than silent, but it is better prevented.

**Run it when nobody else is working in the folder.** Every file is deleted and
recreated at a new path. Collaborators will see the whole project disappear and
come back, which is alarming mid-edit and can collide with their own changes.

**The backup is not disposable yet.** `<Project>_premigration` appears beside the
project and holds everything the original contained, including the old contracts
that the current masters replace. Delete it only after a successful render.

**Check your drivers for `--output-dir` first.** See the section below. It is the
one thing in this process that can destroy finished work rather than merely
inconvenience you.

## Running it

```zsh
cd ~/Library/CloudStorage/Dropbox/Work
~/Library/CloudStorage/Dropbox/Work/_AgentKit/migrate_project.sh HCAP25
```

It lists the control files it finds, proposes an analysis name from the first,
and waits. Then it copies the project to a backup, reports the file count and
byte total it matched, and asks before doing anything irreversible. Answering
anything other than yes cancels and removes the partial backup.

What happens after you confirm:

1. The folder's contents are erased. The folder itself stays, so the share holds.
2. The current structure is built inside it.
3. Your content is copied back from the backup into its new places.
4. Anything unrecognized returns to its old relative path and is listed by name.
5. The backup is named `<Project>_premigration`, which only happens on success.

If any step after the erase fails, the contents are restored from the backup in
place, the folder is still never removed, and the script exits non-zero.

## What moves where

| From the old project | To |
| --- | --- |
| root `*_Control.qmd`, `*_Driver.R` | `R/<analysis>/` |
| `R/*.R`, `R/*.qmd` | `R/<analysis>/` |
| anything deeper under `R/`, apart from `RDATA/` and `MPLUS_OUTPUT/` | its old relative path, and listed in the summary |
| root `*_Control.domd`, `*_Driver.do`, `Stata/*.do` | `Stata/<analysis>/` |
| root `reference_*.docx` | `TEMPLATES/`, overwriting the fresh copies |
| `REFERENCES/SESSION_LOGS.md`, `DECISIONS.md` | `RULES_AND_LOGS/` |
| `REFERENCES/` PDFs and `LLM_OUT/` | `REFERENCES/`, unchanged |
| `FIGURES/`, `MD/`, `EXCALIDRAW/`, `REPORTS/`, `ADMIN/` | same names, unchanged |
| `R/RDATA/`, `R/MPLUS_OUTPUT/`, `Stata/DTA/` | same names, unchanged |
| `bibliography.bib`, `*.rproj` | project root |
| anything else | its old relative path, and listed in the summary |

Seven files are deliberately not carried back, because the current masters
replace them: `AGENTS.md`, `CLAUDE.md`, `README.md`,
`.github/copilot-instructions.md`, `.github/copilot-instructions-proposals.md`,
`R_Rules.md`, and `Mplus_Rules.md`. The two rules files are dropped from either
of their possible homes, `REFERENCES/` or `RULES_AND_LOGS/`. The backup still has
them if you want to compare.

## What it does not do

It changes no file contents. Moving files is safe to automate and rewriting your
manuscript sources is not, so the script prints a checklist instead:

1. Set `analysis` and `stem` in your driver, and adopt the current driver body
   from `_AgentKit/templates/manuscript_Driver.R` or `slides_Driver.R`.
2. Set `analysis` in the control file's setup chunk, and source the starters
   through `here::here("R", analysis, ...)`.
3. Prefix root-level YAML paths with `../../`, covering `reference-doc` and
   `bibliography`. YAML cannot call `here::here()`, so these stay literal.
4. Fix `{{< include >}}` paths, since child `.qmd` files are siblings now.

## The `--output-dir` hazard

Quarto deletes everything in its output directory before it writes. This is
default behaviour, it produces no warning, and the render that triggers it looks
like it succeeded.

Old drivers passed `quarto_args = c("--output-dir", "REPORTS")`. Running one of
those now empties `REPORTS/`, which under the current layout is a dated archive
of every version you have built. One run destroys the lot.

Find them before running anything:

```zsh
grep -rln -- '--output-dir' ~/Library/CloudStorage/Dropbox/Work --include='*Driver.R'
```

Migration does not fix this, because the script does not edit file contents. Your
old driver comes across exactly as it was, flag included. Replace the driver body
before you render.

The current pattern passes no such flag at all. It renders beside the control
file, moves the result into `RENDER/`, and copies a dated version into `REPORTS/`.
`RENDER/` is the only folder anything is allowed to clear, and nothing clears it
wholesale.

Reports already lost to an old driver are not recoverable here. Check Dropbox
version history if one is missing.

## Finishing

Render once. Confirm output appears in `RENDER/` and a dated copy in `REPORTS/`.
Then delete `<Project>_premigration` yourself. Until you do, two copies of the
project exist, which is the point.
