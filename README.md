# AgentKit

Shared configuration for the AI agents I use in research. This repository holds the contracts those agents read, the scaffolding that installs them into a new project (one command, run from anywhere), and the record of what each piece does and why it is shaped that way.

An agent that does not know a researcher's conventions will invent them (plausibly, and differently in every session). Writing the conventions down once, in files the agent loads before it does anything else, is the whole idea. Everything below is a consequence of taking that seriously.

This README describes the folders in this repository and in a project it scaffolds, the contract and rule files that govern agent work, the scripts that create and maintain projects, and the changes another researcher would make before using this structure as their own.

## Repository layout

```text
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

```text
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
│   └── Analysis1/                   Stata analysis folder
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

The kit separates the rules an agent should know at the beginning of every task from the rules it needs only when a particular method or document type is involved. Loading every rule file at once makes the standing instructions hard to locate, while leaving them implicit asks the agent to invent a convention that should have been decided in advance.

`AGENTS.md` is the coding and analysis contract. It establishes that each analysis has one driver and one control file in the same folder; that drivers render first to `RENDER/` and then make dated copies in `REPORTS/`; that R code reaches the project root through `here::here()`; and that requests to "log this session" create a dated account of consequential work. It also requires that claims about a reference document be grounded in extracted text from that document, rather than in what the model may happen to know about the source.

`academic-writing-style.md` is the writing contract. It becomes `.github/copilot-instructions.md` in each new project and asks the agent, in that order, to be right, to be understood, and to sound like me. Its account of voice is measured from approximately 85,000 words of my published work over 24 years. The measures are deliberately concrete: sentence-length distribution, use of parenthetical qualification, citation placement, and related features that a writer can inspect, rather than general descriptions that every writer could plausibly claim to meet. **I do not think it is wise to use an AI tool to do academic writing.** I believe writing is learning and thinking, so I want to keep that activity for myself. Also practically: in my experience text output produced by an AI Agent, regardless of which Agent, is consistently identified as AI-generated by [pangram.com](pangram.com). Quillbot humanize text gets flagged as AI-generated text that has attempted to be humanized by Pangram. By now generated text likely contains a watermark (a signal encoded into word choice that identifies text as AI-generated, see [https://www.anthropic.com/news/claude-text-watermark](https://www.anthropic.com/news/claude-text-watermark)). For serious academic work, ask the AI Agent to output an outline only instead of full paragraphs for prose output. Write the prose yourself. Ask your Agent to critique what you have written without offering rewrite suggestions.

The two files under `RULES_AND_LOGS/` are read when their methods are in use. `R_Rules.md` covers file roles, source order, figure production, and the Quarto rendering pattern. `Mplus_Rules.md` describes the R-to-Mplus-to-H5 workflow through MplusAutomation, including the parts where Mplus's naming and saved-score behavior can otherwise create quiet errors. They are long enough that an agent reads the relevant one before it writes code, rather than carrying both through every ordinary session.

Two pointer files solve tool-specific loading problems. `templates/CLAUDE.md` tells Claude Code and Cowork, which do not automatically read repository instructions, which files to read and in what order. `templates/copilot-instructions-proposals.md` is the grant-writing adjunct. Copilot does not load it automatically, so a proposal project appends it to the base instruction file or names it explicitly in the conversation.

The two log files, `SESSION_LOGS.md` and `DECISIONS.md`, preserve the reasoning that the contracts themselves cannot carry without becoming historical narratives. New projects begin without entries. The first time a user says "log this session," the agent adds a concise dated account of the decisions, data-handling choices, abandoned approaches, and next steps to the first file, and a one-line version of each consequential analytic decision to the second. In this repository, the same files record the history of AgentKit.

`AgentKit_overview.md` and `AgentKit_instructions.md` are different. They are for an agent maintaining this repository, not for an agent working inside a scaffolded project. The first explains why the kit has this form; the second sets the operational limits for changing it.

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
proposal work loads a second one alongside it (`grant-proposal-writing`).

Positron is built on Code OSS and has its own AI system, Posit Assistant, with
chat, next-edit suggestions, and agentic tools. Its current releases configure
model providers through `providers.json`, and the `ai.enabled` setting turns
off its AI features. Positron has also shipped GitHub Copilot completions. But
I have not found documentation establishing that Posit Assistant, or a GitHub
Copilot extension installed in Positron, automatically reads either
`AGENTS.md` or `.github/copilot-instructions.md`. Treat that as unverified.
Before relying on this kit in Positron, test one narrow task: ask the assistant
which project instruction files it read, then ask it to report the canonical
driver and control-file conventions. Record the result here or in the project's
session log. The same test should confirm whether the agent can create and
modify workspace files, run the canonical driver, and read the resulting
rendered output.

RStudio users should create or open an RStudio Project in the root of the
scaffolded AgentKit folder, not in `R/`, `R/<Analysis>/`, or any output folder.
The resulting `.Rproj` file belongs beside `.here`, `AGENTS.md`, and
`bibliography.bib`. RStudio then uses the project root as its working directory,
which agrees with the `here::here()` paths used throughout this kit, while the
analysis-specific source files remain in `R/<Analysis>/`. An `.Rproj` file also
serves as a root marker for `here`, although the scaffold retains `.here` so
the project continues to work in R, Quarto, and other editors that do not open
RStudio Projects.

RStudio is not an AI-free alternative. Current RStudio releases offer Posit
Assistant and Next Edit Suggestions through Posit AI, an optional subscription
service. Posit Assistant can read live R-session context and run code, which
makes it potentially useful for the analysis work this kit organizes. I have
not found documentation showing that it automatically reads `AGENTS.md` or
`.github/copilot-instructions.md`, so an RStudio user who enables Posit AI
should run the same narrow instruction-loading test described above before
assuming that this project's contracts are in force. A user who does not enable
Posit AI can use the folder layout, R/Quarto templates, and RStudio Project
without any agent integration.

Google's tools do not work here, for structural reasons rather than fixable
ones. Gemini CLI reads `GEMINI.md` rather than `AGENTS.md`, so nothing in a
scaffolded project loads. Antigravity does read `AGENTS.md`, but it caps a rules
file at 12,000 characters, and every instruction file in this kit runs past that
(the writing standard near 30,000, the coding contract at 12,400, the two rule
files at 13,800 and 12,600). A file that loads and silently truncates is worse
than one that fails to load, because the sections carrying the positive
requirements and the self-check sit at the end and would be the first to go.

## Folder notes

The repository has only three folders that contain material an adopter will normally change. `REFERENCES/Jones_Writing_Samples/` holds the articles, unpublished grant text, and study-asset inventory from which the writing standard was developed. The folder is gitignored because the source material is not all mine to distribute; the standard quotes the portions a reader needs to understand how it was derived. `RULES_AND_LOGS/` contains the two coding rules and the record of decisions that shaped the kit. `templates/` holds the files that become a new project: the driver and control-file pairs, the R starters, the project README and `CLAUDE.md`, the proposal adjunct, and the typed pandoc reference documents. Adding a new reference-document type requires only a new `reference_<type>.docx` in this folder, because the scaffold searches for that pattern rather than naming a fixed set of files.

The analysis folders in a scaffolded project are self-contained. `R/<Analysis>/` holds an analysis's driver, control file, child source files, and copies of the R starters; `Stata/<Analysis>/` follows the same pattern. A project with a second analysis adds a sibling folder rather than a second driver to the first one. The root-level output folders stay shared and flat. `FIGURES/` and `MD/` hold generated assets that reports include. `RENDER/` is scratch, and only drivers write there. Quarto may empty an output directory before rendering, so a driver renders into `RENDER/`, then moves the result and copies a dated version to `REPORTS/`. The analysis prefix in the filename is what prevents a manuscript and a slide deck, or two analyses, from overwriting each other in a flat folder.

`REFERENCES/` is for source material and nothing else. When a PDF is relevant to the analysis or writing, `pdf2llm` creates page-marked text, JSONL, and provenance information under `REFERENCES/LLM_OUT/`; the grounding rules read those files rather than the PDF itself (see [https://github.com/rnj0nes/pdf2llm](https://github.com/rnj0nes/pdf2llm)). `ADMIN/` is deliberately separate. It holds data-use agreements, IRB and regulatory correspondence, sponsor and collaborator email, and signed forms. An agent may read one of those files when asked, but it does not use `ADMIN/` as literature or carry names and confidential details from it into a draft unless the user requests that directly.

`TEMPLATES/` contains the reference documents that pandoc uses for DOCX styles. They are working files, so each project can restyle its own copy to match a journal or sponsor. A reference document built by opening a real manuscript in Word carries the manuscript text and metadata inside the `.docx`, even when the displayed body has been changed. Run `scrub_reference_docs.py` before sharing such a file. Finally, `.here` is an empty root marker for the R `here` package. It is intentionally boring, but it matters: without it, `here::here()` falls back to the working directory and a driver can place every file somewhere other than the project it was meant to run.

## How it is put together

**Each project owns its files.** A project holds physical copies of the masters, frozen when it is created, and does not track them afterward. That makes it self-contained and portable (nothing to resolve when a folder moves, syncs to another machine, or is handed to someone else). Updating an existing project means copying the changed master in by hand, which `update-existing-projects.md` documents.

**One master per concern.** The writing standard has exactly one authoring location, and every other copy (the Codex skill, each project's `.github/copilot-instructions.md`) carries a header saying it is generated and will be overwritten. The failure this prevents is subtle. It is not two files diverging (which is visible the moment anyone compares them), but a person resolving a difference between two files by copying one over the other, without first checking which of them holds content the other lacks.

**Voice is measured, not described.** The structural targets are numeric because vague ones are unusable: median sentence length 22 to 26 words; standard deviation above 14; about 20% of sentences past 35 words and about 15% under 10; parentheses near 20 per thousand words, most of them carrying qualifications rather than citations. The ban list can only subtract (a draft satisfying every prohibition may still be flat prose belonging to nobody), so those targets, and the self-check that tests for them, carry the positive requirements.

**Some tasks suspend the standard.** When I ask for an outline I intend to write the prose myself, and any phrasing the agent supplies is phrasing I will absorb without noticing, so the outlining mode turns off the phrase banks and the sentence targets and requires fragments (noun phrases, verb stems) that cannot be pasted into a document. Reasoning discipline stays on, as does the requirement to carry citations, verbatim numbers, and marked gaps (the facts I would otherwise have to look up again).

**Behavior is confirmed by running.** Reading a script confirms what it intends. Running it and reading the result back confirms what it does, which is a different question, and the gap between them is where a scaffold copies files with correct names and empty contents, or a path scheme resolves everywhere except where it should (silently, because a fallback is not an error).

## Using the scripts

The scripts do different jobs, and it is useful to keep their scope clear. `new_project.sh` starts a new project from the current masters. `migrate_project.sh` changes the layout of an existing, older AgentKit project. `scrub_reference_docs.py` removes hidden text and metadata from a reference document. None is an update mechanism for every project you have ever made; projects own copies of the masters, and that choice is deliberate.

`new_project.sh` scaffolds a new project. Before its first use, edit the `AGENT_KIT` variable near the top to point to your copy of this repository, make the script executable with `chmod +x new_project.sh`, and put it on your `PATH` if you want to invoke it from anywhere. Then run either of these commands:

```zsh
new_project.sh RethinkingClassification
new_project.sh RethinkingClassification ~/Library/CloudStorage/Dropbox/Work
```

The first form creates the project inside the current directory; the second takes an explicit parent directory. The script refuses to overwrite an existing folder, reports the files it copied, and ends by naming the work that remains project-specific: rename `Analysis1`, set the `analysis` value in the drivers and controls, add references, and build a bibliography. If VS Code's `code` command is available, it opens the new folder.

`migrate_project.sh` rebuilds a project made before the August 2026 restructure onto the current layout, without ever renaming or replacing the project folder. That restraint matters for Dropbox-shared projects, where renaming the folder breaks the share. Run it from the project's parent directory:

```zsh
migrate_project.sh HCAP25
migrate_project.sh HCAP25 ~/Library/CloudStorage/Dropbox/Work
```

The script first makes a sibling backup, verifies that backup by file count and byte total, and asks for confirmation before it empties the original folder. `update-existing-projects.md` describes what moves where and the one driver setting, `--output-dir`, that can destroy finished work if it remains in an old driver. The migration script refuses a folder that lacks `AGENTS.md`, because a non-AgentKit project should be scaffolded rather than rebuilt, and it refuses a project already on the current layout.

`scrub_reference_docs.py` replaces the visible text in a pandoc reference `.docx` with Lorem Ipsum and clears its document properties, while leaving the parts pandoc reads for formatting (`styles.xml`, `numbering.xml`, `settings.xml`, and the theme) byte-identical:

```zsh
python3 scrub_reference_docs.py TEMPLATES/reference_manuscript.docx TEMPLATES/reference_manuscript_scrubbed.docx
```

Run it on a new output path, as above, whenever you have restyled a real manuscript in Word and plan to share the resulting reference document. Such a file may carry source-manuscript text, citation keys, and cited DOIs invisibly; pandoc's ignoring the body at render time does not remove those contents from the file.

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
the grounding workflow reads, and it is [available on GitHub](https://github.com/rnj0nes/pdf2llm) (MIT). It needs Poppler and python3, with
`ocrmypdf`, `tesseract`, and pandoc for scanned documents. Everything except the
grounding workflow works without it.

## Making this your own

`AgentKit_overview.md` explains the background of the kit, `AgentKit_instructions.md` governs maintenance work here, and `VS-Code-workflow.md` describes the day-to-day workflow in more detail. The logs under `RULES_AND_LOGS/` document the decisions behind the current structure. But the starting point for an adopter is simpler: retain the separation of standing contracts, task-specific rules, templates, and a record of decisions; replace the content that belongs to me.

Begin with `AGENTS.md`. Change the driver and control-file conventions if your work needs a different arrangement, revise the folder names if you have a better reason than familiarity to use different ones, and replace the Stata executable path near the end of the file. That path is specific to one Mac installation. Then edit `RULES_AND_LOGS/R_Rules.md` and `Mplus_Rules.md` to reflect the R, Quarto, and Mplus conventions your own work requires. A researcher who does not use Mplus may remove its rule file altogether; a researcher who uses Python rather than R should replace the R rule file with a corresponding Python contract rather than preserving a rule set that nobody will follow.

Replace `academic-writing-style.md` wholesale. Mine is based on a measured sample of my own work. Yours may be measured from your writing, or it may state preferences directly; either is more useful than inheriting my sentence lengths, parentheticals, and prohibitions. The next project scaffolded from your copy will receive that file as `.github/copilot-instructions.md`, so this is the one change that determines how ordinary prose sounds across the projects you create.

Restyle the `reference_*.docx` files to match the journals, funders, or internal formats you actually use. Then point `AGENT_KIT` in both shell scripts to the location of your clone. These are masters rather than shared live files: existing projects do not update when you edit the kit. Copy a changed contract or template into a project when you want that project to receive the revision.

The shell scripts do not run under PowerShell or `cmd`. On Windows, use WSL and run them from its Linux shell, or use Git Bash with a sufficiently complete POSIX environment (`find`, `cp -R`, and `wc` are required by the migration script). Both scripts run under bash despite their zsh shebangs; `migrate_project.sh` is written in a portable POSIX subset. R, Quarto, and pandoc are cross-platform. `scrub_reference_docs.py` is plain Python 3 and runs wherever Python does.

Finally, `pdf2llm` is separate from AgentKit. It supplies the page-marked extraction workflow under `REFERENCES/LLM_OUT/` and needs Poppler and Python, with `ocrmypdf`, Tesseract, and pandoc for scanned documents. The rest of the kit works without it.

## Status

Working infrastructure, in active use, not a finished product. The session log names what is untested at any given moment (at the time of writing, the driver render pattern, which has been verified as correctly installed but not yet run against a real document), and there is usually something.
