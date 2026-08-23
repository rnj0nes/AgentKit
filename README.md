# AgentKit

Shared configuration for the AI agents I use in research. This repository holds the contracts those agents read, the scaffolding that installs them into a new project (one command, run from anywhere), and the record of what each piece does and why it is shaped that way.

An agent that does not know a researcher's conventions will invent them (plausibly, and differently in every session). Writing the conventions down once, in files the agent loads before it does anything else, is the whole idea. Everything below is a consequence of taking that seriously.

## What an agent reads

Two files load in every session.

`AGENTS.md` is the coding and analysis contract. It fixes the driver and control file conventions (one driver per analysis, calling one control file, both in the same folder), says where generated output goes, sets the rules for logging a session, and requires that any claim about a source document be grounded in text extracted from that document rather than in the model's prior familiarity with it.

`academic-writing-style.md` is the writing standard, and it has three jobs in priority order: be right, be understood, sound like me. Reasoning discipline comes first, because a fluent causal overclaim does more damage than an awkward sentence that names its own assumptions, and because the failures that cost a researcher most (fabricated citations, unsupported synthesis, statistical significance read as scientific importance) are failures of reasoning rather than of style. The voice section, which is measured from about 85,000 words of my published work spanning 24 years (two documents externally verified as human-written, several machine-written passages scored against them), and which states its structural targets as numbers rather than in adjectives any writer would claim to satisfy, governs wherever the measurement disagrees with what I would have said my preferences were.

Two files load when the task calls for them. `RULES_AND_LOGS/R_Rules.md` covers R and Quarto conventions (file roles, source order, figure naming and devices, the driver render pattern), and `RULES_AND_LOGS/Mplus_Rules.md` covers running Mplus from R through MplusAutomation. They run to about 600 lines together, so an agent reads whichever one the task calls for before writing code, rather than carrying both through every session.

## Which tools this targets

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

## Project layout

`new_project.sh` creates a project folder and copies the current masters into it. Each analysis then lives in its own subfolder of `R/` or `Stata/`, holding everything it needs (driver, control file, child source files, and its own copies of the R starters), so that a project running three analyses keeps three self-contained units rather than one crowded root.

The output folders sit flat at the project root and are shared by every analysis: `RENDER/` for driver output; `REPORTS/` for dated copies; `FIGURES/` and `MD/` for the assets a report includes. Because they are shared, driver output carries the analysis name as a prefix, which is how `Project1_manuscript_2026-08-17.docx` and `Project2_manuscript_2026-08-17.docx` sit in one folder without collision.

R code reaches the project root through `here::here()`, which resolves against a `.here` marker written at the top of every project, so a driver works from any working directory. YAML in a control file cannot call a function, so those few paths (the pandoc reference document, the bibliography, a slide watermark) are literal and reach the root with `../../`.

## How it is put together

**Each project owns its files.** A project holds physical copies of the masters, frozen when it is created, and does not track them afterward. That makes it self-contained and portable (nothing to resolve when a folder moves, syncs to another machine, or is handed to someone else). Updating an existing project means copying the changed master in by hand, which `update-existing-projects.md` documents.

**One master per concern.** The writing standard has exactly one authoring location, and every other copy (the Codex skill, each project's `.github/copilot-instructions.md`) carries a header saying it is generated and will be overwritten. The failure this prevents is subtle. It is not two files diverging (which is visible the moment anyone compares them), but a person resolving a difference between two files by copying one over the other, without first checking which of them holds content the other lacks.

**Voice is measured, not described.** The structural targets are numeric because vague ones are unusable: median sentence length 22 to 26 words; standard deviation above 14; about 20% of sentences past 35 words and about 15% under 10; parentheses near 20 per thousand words, most of them carrying qualifications rather than citations. The ban list can only subtract (a draft satisfying every prohibition may still be flat prose belonging to nobody), so those targets, and the self-check that tests for them, carry the positive requirements.

**Some tasks suspend the standard.** When I ask for an outline I intend to write the prose myself, and any phrasing the agent supplies is phrasing I will absorb without noticing, so the outlining mode turns off the phrase banks and the sentence targets and requires fragments (noun phrases, verb stems) that cannot be pasted into a document. Reasoning discipline stays on, as does the requirement to carry citations, verbatim numbers, and marked gaps (the facts I would otherwise have to look up again).

**Behavior is confirmed by running.** Reading a script confirms what it intends. Running it and reading the result back confirms what it does, which is a different question, and the gap between them is where a scaffold copies files with correct names and empty contents, or a path scheme resolves everywhere except where it should (silently, because a fallback is not an error).

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

## Adapting it

`AgentKit_overview.md` gives the background, `AgentKit_instructions.md` gives the rules for maintaining the kit, and `VS-Code-workflow.md` walks through the day-to-day cycle at length. `RULES_AND_LOGS/SESSION_LOGS.md` and `RULES_AND_LOGS/DECISIONS.md` hold the reasoning behind each choice (in more detail than this file, and in the order the choices were actually made).

To use it, replace the contents of `AGENTS.md` and `academic-writing-style.md` with your own conventions, restyle the reference documents in Word to match your journals, and point the `AGENT_KIT` variable in `new_project.sh` at your copy. Run `scrub_reference_docs.py` over any reference document you build from one of your own manuscripts before committing it. What should transfer is the structure: two always-read contracts; rule files read when the task calls for them; a scaffold that installs both; and a written record of the decisions. My ban list and my sentence length distribution will not transfer, and should not.

## Status

Working infrastructure, in active use, not a finished product. The session log names what is untested at any given moment (at the time of writing, the driver render pattern, which has been verified as correctly installed but not yet run against a real document), and there is usually something.
