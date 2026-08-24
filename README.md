# AgentKit

Shared configuration for the AI agents I use in research. This repository holds the contracts those agents read, the scaffolding that installs them into a new project (one command, run from anywhere), and the record of what each piece does and why it is shaped that way.

An agent that does not know a researcher's conventions will invent them (plausibly, and differently in every session). Writing the conventions down once, in files the agent loads before it does anything else, is the whole idea. Everything below is a consequence of taking that seriously.

This README covers, in order: the folders in this repository and in a project it scaffolds; the contract, rule, and log files and what each one says; notes on what every folder is for; how to run the `.sh` and `.py` files; and how to adapt the kit if you are not me.

## Repository layout

```
_AgentKit/
├── AGENTS.md                        contract: driver/control conventions, invariants, logging, grounding
├── academic-writing-style.md        contract: writing standard (becomes .github/copilot-instructions.md)
├── AgentKit_overview.md             background, for an agent maintaining the kit itself
├── AgentKit_instructions.md         operating rules, for an agent maintaining the kit itself
├── VS-Code-workflow.md              day-to-day workflow, long form
├── update-existing-projects.md      how to run migrate_project.sh, and what it moves where
├── new_project.sh                   scaffolds a new project from the files below
├── migrate_project.sh               rebuilds a pre-August-2026 project onto the current layout
├── scrub_reference_docs.py          replaces a reference .docx's text with Lorem Ipsum
├── .gitignore                       excludes REFERENCES/Jones_Writing_Samples/ and test scratch
├── README.md                        this file
├── REFERENCES/
│   └── Jones_Writing_Samples/       source material for the writing standard; local only, gitignored
├── RULES_AND_LOGS/
│   ├── R_Rules.md                   R/Quarto conventions, copied into every project
│   ├── Mplus_Rules.md               Mplus/MplusAutomation conventions, copied into every project
│   ├── SESSION_LOGS.md              dated log of work on this kit itself
│   └── DECISIONS.md                 one-line decision record for this kit itself
└── templates/
    ├── CLAUDE.md                    pointer file, copied to every project's CLAUDE.md
    ├── README.md                    generic project README, copied to every project's README.md
    ├── copilot-instructions-proposals.md   grant adjunct, copied to .github/ but not auto-loaded
    ├── manuscript_Control.qmd / manuscript_Driver.R    QMD-to-DOCX starter pair
    ├── slides_Control.qmd / slides_Driver.R            QMD-to-revealjs starter pair
    ├── reference_manuscript.docx    pandoc reference doc for manuscripts
    ├── reference_proposal.docx      pandoc reference doc for proposals
    ├── reference_report.docx        pandoc reference doc for reports
    └── R/
        ├── 000-Libraries.R          installs/loads the R packages every project needs
        └── 001-Environment-settings.R
```

## Project layout (what `new_project.sh` builds)

Running the script produces this skeleton. It is documented in full in the
project's own `README.md` (`templates/README.md` here, before it is copied).

```
<ProjectName>/
├── .here                            root marker here::here() needs; never delete
├── AGENTS.md                        copy of the contract, frozen at creation
├── CLAUDE.md                        copy of the pointer file
├── README.md                        copy of the project README
├── bibliography.bib                 empty; ask your agent to build it from REFERENCES/
├── .github/
│   ├── copilot-instructions.md              copy of academic-writing-style.md
│   └── copilot-instructions-proposals.md    grant adjunct, named explicitly when needed
├── R/
│   ├── RDATA/                       flat, shared .rds/.RData storage
│   ├── MPLUS_OUTPUT/                flat, shared Mplus output
│   └── Analysis1/                   one folder per analysis; rename this one
│       ├── 000-Libraries.R
│       ├── 001-Environment-settings.R
│       ├── manuscript_Control.qmd / manuscript_Driver.R
│       └── slides_Control.qmd / slides_Driver.R
├── Stata/
│   ├── DTA/
│   ├── MPLUS_OUTPUT/
│   └── Analysis1/                   Stata mirror of the R analysis folder
├── REFERENCES/
│   └── LLM_OUT/                     pdf2llm output: page-marked text, JSONL, metadata
├── RENDER/                          driver output; scratch, emptied on every render
├── REPORTS/                         dated, named copies of finished renders
├── FIGURES/                         flat, shared generated figures
├── MD/                              flat, shared generated tables and text snippets
├── EXCALIDRAW/
│   └── figure-1.excalidraw.svg
├── ADMIN/                           agreements, IRB/regulatory mail, signed forms
├── RULES_AND_LOGS/
│   ├── R_Rules.md
│   ├── Mplus_Rules.md
│   ├── SESSION_LOGS.md              created the first time you say "log this session"
│   └── DECISIONS.md                 created the first time you say "log this session"
└── TEMPLATES/
    └── reference_*.docx             one per output type found in _AgentKit/templates/
```

## Contracts, rules, and logs

Each file below encodes one decision so an agent does not have to guess it. Two load in every session, two load only when the task calls for them, and the rest exist to point an agent at the first four or to record what has already been decided.

- **`AGENTS.md`** (loads every session). The coding and analysis contract: one driver per analysis, calling one control file, both in the same folder; where generated output goes (`RENDER/` as scratch, `REPORTS/` as the dated, kept copy); the rule that a project uses only relative paths, reached with `here::here()`; the session-logging trigger ("log this session"); and the requirement that any claim about a source document be grounded in text extracted from that document, not in the model's prior familiarity with it.
- **`academic-writing-style.md`** (loads every session, as each project's `.github/copilot-instructions.md`). The writing standard, in priority order: be right, be understood, sound like me. Reasoning discipline comes first, because a fluent causal overclaim does more damage than an awkward sentence that names its own assumptions. The voice section is measured from about 85,000 words of my published work spanning 24 years, and states its targets as numbers (median sentence length, how often a sentence runs long or short, how often a parenthetical appears) rather than as adjectives any writer would claim to satisfy.
- **`RULES_AND_LOGS/R_Rules.md`** (loads when the task is R or Quarto). File roles and ownership, source order, figure naming and devices, the driver render pattern that avoids Quarto's directory-emptying `--output-dir`.
- **`RULES_AND_LOGS/Mplus_Rules.md`** (loads when the task is Mplus). The R-to-Mplus-to-H5 run structure through MplusAutomation, variable-naming truncation gotchas, and how to read Bayes factor scores back into R.
- **`templates/copilot-instructions-proposals.md`** (named explicitly, not auto-loaded). The grant-writing adjunct. Copilot only auto-loads `copilot-instructions.md` and `AGENTS.md`, so a grant project either appends this file to the writing standard or names it in chat.
- **`templates/CLAUDE.md`** (read manually by Claude Code and Cowork, which load nothing on their own). A pointer, in order, to `AGENTS.md`, then `.github/copilot-instructions.md`, then `RULES_AND_LOGS/SESSION_LOGS.md` and `DECISIONS.md` if they exist, then the two rule files by task.
- **`RULES_AND_LOGS/SESSION_LOGS.md`** and **`RULES_AND_LOGS/DECISIONS.md`** (created on request, not shipped with content). Empty in a freshly scaffolded project; the first time you say "log this session," a dated narrative entry goes in the first and a one-line decision goes in the second. In this repository, they hold the build history of the kit itself, and are worth reading if you want the reasoning behind a choice rather than just the choice.
- **`AgentKit_overview.md`** and **`AgentKit_instructions.md`** (read only by an agent working on this kit, never copied into a project). Background and operating rules for maintaining AgentKit itself, kept separate from the contracts a project actually uses.

## Which tools load these files

Three, and each loads these files differently. A fourth does not work at all.

VS Code with Copilot Chat reads `.github/copilot-instructions.md` on every
request without any setup. It reads `AGENTS.md` only when `chat.useAgentsMdFile`
is set to true, because that support is experimental and off by default. Turn it
on, or the coding contract never loads and nothing tells you it is missing
(right-click in the Chat view and choose Diagnostics to see what actually
loaded).

Codex reads a repo root `AGENTS.md` natively with no setting to enable, so a
scaffolded project works immediately, and the writing standard installs once as
a personal skill (in `~/.codex/skills/`) rather than once per project.

Claude Code and Cowork read neither file on their own, which is what the
project's `CLAUDE.md` is for, since it names the files and the order to read
them. The writing standard is also a Claude skill (`my-writing-style`), and
grant work loads a second one alongside it (`grant-proposal-writing`).

Google's tools do not work here, for structural reasons rather than fixable
ones. Gemini CLI reads `GEMINI.md` rather than `AGENTS.md`, so nothing in a
scaffolded project loads. Antigravity does read `AGENTS.md`, but it caps a rules
file at 12,000 characters, and every instruction file in this kit runs past that
(the writing standard near 30,000, the coding contract at 12,400, the two rule
files at 13,800 and 12,600). A file that loads and silently truncates is worse
than one that fails to load, because the sections carrying the positive
requirements and the self-check sit at the end and would be the first to go.

## Folder notes

In this repository:

- **`REFERENCES/Jones_Writing_Samples/`**: the source material the writing standard was measured from (published articles, unpublished grant text, a study asset inventory). Gitignored; not all of it is mine to redistribute, and the standard itself quotes what a reader needs.
- **`RULES_AND_LOGS/`**: the two coding rule files, plus this kit's own session log and decision record. A project gets its own copy of the same folder, minus the log files, which start empty.
- **`templates/`**: everything `new_project.sh` copies into a new project (contracts and pointer files aside, which live at the repository root). Add a fourth reference-doc type by dropping `reference_<type>.docx` here; nothing else needs to change, since the script globs for the pattern.

In a scaffolded project, the folders that are not self-explanatory:

- **`R/<Analysis>/`** and **`Stata/<Analysis>/`**: one self-contained folder per analysis (driver, control file, child files, its own copies of the R starters). Add a second analysis as a sibling folder; do not put two analyses' drivers in one folder.
- **`RENDER/`**: scratch. Quarto empties whatever `--output-dir` it is given before writing, so nothing renders straight to `REPORTS/`; the driver renders here, then moves and copies. Never read from it as a stable location and never write to it by hand.
- **`REPORTS/`**: the kept output, one dated file per render, named with the analysis prefix so two analyses sharing this flat folder never collide.
- **`FIGURES/`** and **`MD/`**: generated assets a report includes, flat and shared the same way.
- **`REFERENCES/`**: source material only, nothing else. Run `pdf2llm` on a new PDF to populate `REFERENCES/LLM_OUT/`, which the grounding rule in `AGENTS.md` reads from.
- **`ADMIN/`**: the project's administrative record (data use agreements, IRB correspondence, signed forms). An agent reads a file here on request but never treats it as source material and never quotes it into a document unasked, because it carries other people's names and confidentiality terms.
- **`TEMPLATES/`**: this project's pandoc reference docs. Working files, restyle them in Word to match a journal or sponsor; run `scrub_reference_docs.py` before sharing the project if you rebuilt one from a real manuscript.
- **`.here`**: an empty sentinel file. Its only job is to give `here::here()` something to resolve against, so every driver finds the project root regardless of the working directory it was launched from. Deleting it does not raise an error; it just makes every path resolve somewhere else.

## How it is put together

**Each project owns its files.** A project holds physical copies of the masters, frozen when it is created, and does not track them afterward. That makes it self-contained and portable (nothing to resolve when a folder moves, syncs to another machine, or is handed to someone else). Updating an existing project means copying the changed master in by hand, which `update-existing-projects.md` documents.

**One master per concern.** The writing standard has exactly one authoring location, and every other copy (the Codex skill, each project's `.github/copilot-instructions.md`) carries a header saying it is generated and will be overwritten. The failure this prevents is subtle. It is not two files diverging (which is visible the moment anyone compares them), but a person resolving a difference between two files by copying one over the other, without first checking which of them holds content the other lacks.

**Voice is measured, not described.** The structural targets are numeric because vague ones are unusable: median sentence length 22 to 26 words; standard deviation above 14; about 20% of sentences past 35 words and about 15% under 10; parentheses near 20 per thousand words, most of them carrying qualifications rather than citations. The ban list can only subtract (a draft satisfying every prohibition may still be flat prose belonging to nobody), so those targets, and the self-check that tests for them, carry the positive requirements.

**Some tasks suspend the standard.** When I ask for an outline I intend to write the prose myself, and any phrasing the agent supplies is phrasing I will absorb without noticing, so the outlining mode turns off the phrase banks and the sentence targets and requires fragments (noun phrases, verb stems) that cannot be pasted into a document. Reasoning discipline stays on, as does the requirement to carry citations, verbatim numbers, and marked gaps (the facts I would otherwise have to look up again).

**Behavior is confirmed by running.** Reading a script confirms what it intends. Running it and reading the result back confirms what it does, which is a different question, and the gap between them is where a scaffold copies files with correct names and empty contents, or a path scheme resolves everywhere except where it should (silently, because a fallback is not an error).

## Using the scripts

All three are shell or Python, run from a terminal. None of them touches anything outside the project folder you name.

**`new_project.sh`** scaffolds a new project. One-time setup: open the script and edit the `AGENT_KIT` variable near the top to point at wherever you keep your own clone, `chmod +x new_project.sh`, and put it on your `PATH`. After that:

```zsh
new_project.sh RethinkingClassification
new_project.sh RethinkingClassification ~/Library/CloudStorage/Dropbox/Work
```

The first form creates the project inside the current directory; the second takes an explicit parent directory. The script refuses to run if the target folder already exists, and it prints what it copied and what still needs a human (renaming `Analysis1`, adding a bibliography) at the end. If VS Code's `code` command is on your `PATH`, it opens the new folder automatically.

**`migrate_project.sh`** rebuilds a project made before the August 2026 restructure onto the current layout, without ever renaming or replacing the project folder (renaming a folder shared through Dropbox breaks the share). Run it from the project's parent directory:

```zsh
migrate_project.sh HCAP25
migrate_project.sh HCAP25 ~/Library/CloudStorage/Dropbox/Work
```

It backs the project up to a sibling folder first, verifies the backup by file count and byte total, and asks for confirmation before doing anything irreversible. Read `update-existing-projects.md` before running it once, since it covers what moves where and the one driver setting (`--output-dir`) that can destroy finished work if left in place. It refuses to run against a project that has no `AGENTS.md`, or one that is already on the current layout.

**`scrub_reference_docs.py`** replaces the visible text of a pandoc reference `.docx` with Lorem Ipsum, and clears its document properties, while leaving the parts pandoc actually reads (`styles.xml`, `numbering.xml`, `settings.xml`, the theme) byte-identical:

```zsh
python3 scrub_reference_docs.py TEMPLATES/reference_manuscript.docx TEMPLATES/reference_manuscript_scrubbed.docx
```

Run it on any reference document you built by restyling a real manuscript in Word, before that document goes into a public or shared repository. A reference doc built this way carries the source manuscript's text, its citation keys, and every DOI it cited, invisibly, and pandoc's ignoring the body at render time does not stop the file itself from containing it.

## What is not here

The documents the writing standard was measured from. They are published articles (several under publisher copyright), unpublished grant text, and an inventory of a live study's assets, so they are not all mine to post. The standard quotes what a reader needs.

An update script. Propagating a changed master to every existing project automatically was considered and rejected in favour of self-contained projects, and the manual commands in `update-existing-projects.md` are the cost of that choice.

The pandoc reference documents are here, but their text is Lorem Ipsum. Pandoc reads a reference document for its style definitions and ignores the body, so `scrub_reference_docs.py` replaces every run of text and clears the document properties while leaving the parts pandoc actually uses (`styles.xml`, `numbering.xml`, `settings.xml`, and the theme) byte-identical. Content hides in three places in a `.docx`, and each needs its own pass: the run text; the bookmark names and hyperlink anchors, which carry citation keys such as `ref-Cohen1988`; and the relationships file, which lists the DOI of every work the document cited.

## What you need installed

R, the Quarto CLI, and pandoc, of which the `here` package matters most, since
every path in every driver resolves through it and a project without its `.here`
marker will silently resolve them all somewhere else. `R/000-Libraries.R`
installs the R packages it needs on first run (`here`, `tidyverse`, `knitr`,
`kableExtra`, `quarto`), so R itself is the only piece you place by hand.

Stata and Mplus are needed only by the workflows that use them, and the Stata
binary path in `AGENTS.md` is machine specific.

One thing referenced here lives in its own repository. `pdf2llm` converts a PDF
into the page-marked text, JSONL, and metadata under `REFERENCES/LLM_OUT/` that
the grounding workflow reads, and it is at
https://github.com/rnj0nes/pdf2llm (MIT). It needs Poppler and python3, with
`ocrmypdf`, `tesseract`, and pandoc for scanned documents. Everything except the
grounding workflow works without it.

## Making this your own

`AgentKit_overview.md` gives the background, `AgentKit_instructions.md` gives the rules for maintaining the kit, and `VS-Code-workflow.md` walks through the day-to-day cycle at length. `RULES_AND_LOGS/SESSION_LOGS.md` and `RULES_AND_LOGS/DECISIONS.md` hold the reasoning behind each choice (in more detail than this file, and in the order the choices were actually made).

What should transfer to your own copy is the structure, not the content: two always-read contracts, rule files read when the task calls for them, a scaffold that installs both, and a written record of decisions. Nothing about my ban list or my sentence-length targets should survive into yours.

**Change the coding rules.** Rewrite `AGENTS.md` in place: your own driver/control conventions if they differ, your own folder names if you want different ones, and the Stata binary path near the bottom, which is machine specific and currently mine. Edit `RULES_AND_LOGS/R_Rules.md` and `RULES_AND_LOGS/Mplus_Rules.md` for your own file-naming and modeling conventions, or delete either if you never use R/Quarto or Mplus.

**Change the writing rules.** Replace `academic-writing-style.md` wholesale. Mine is measured from my own published work; write yours from a sample of your own, or state stylistic preferences directly if you would rather not measure. Whatever you put there becomes every project's `.github/copilot-instructions.md` on the next scaffold.

**Change the document templates.** Restyle `templates/reference_*.docx` in Word to match the journals or sponsors you actually submit to. If you build one by opening a real manuscript and stripping the text, run `scrub_reference_docs.py` over it before it goes anywhere near a shared or public repository.

**Point the scaffold at your own copy.** Edit the `AGENT_KIT` variable near the top of `new_project.sh` (and `migrate_project.sh`, which calls it) to the path where you keep your clone.

**Running it on Windows.** Both scripts declare a zsh shebang, and `migrate_project.sh` is deliberately written in the portable POSIX subset, so both also run under bash. Neither runs under a native Windows shell (PowerShell or cmd). On Windows, install WSL and run the scripts from its Linux shell, or use Git Bash if it has enough of a POSIX environment for `find`, `cp -R`, and `wc`. R, Quarto, and pandoc themselves are cross-platform and need no such workaround; only these two shell scripts do. `scrub_reference_docs.py` is plain Python 3 and runs unmodified anywhere Python does.

**If you use Stata or Mplus**, update the executable path in your copy of `AGENTS.md`; both are hardcoded to a local install location that will not exist on another machine.

**If you use `pdf2llm`** for the reference-grounding workflow, it is a separate repository with its own dependencies (Poppler, python3, and for scanned documents `ocrmypdf`, `tesseract`, and pandoc); nothing else here requires it.

## Status

Working infrastructure, in active use, not a finished product. The session log names what is untested at any given moment (at the time of writing, the driver render pattern, which has been verified as correctly installed but not yet run against a real document), and there is usually something.
