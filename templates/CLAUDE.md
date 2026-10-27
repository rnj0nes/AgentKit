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

# CLAUDE.md

This project follows the AgentKit conventions. Before working, read these
files in order:

1. `AGENTS.md` (the coding and analysis contract)
2. `.github/copilot-instructions.md` (academic writing style, always in force,
   including narrative text inside `.qmd` files)
3. `RULES_AND_LOGS/SESSION_LOGS.md` and `RULES_AND_LOGS/DECISIONS.md` if they exist

For grant and proposal work, also read
`.github/copilot-instructions-proposals.md`, which adds the grant-specific
task and overrides a few base rules for grant documents only.

Before writing code that uses data, read `DATA_DICTIONARY/`. Participant data
is not in this project, and the dictionary is the only description of it an
agent may read.

Two more files are read by task, not on every session. Read
`RULES_AND_LOGS/R_Rules.md` before writing R or QMD, and `RULES_AND_LOGS/Mplus_Rules.md`
before Mplus work. `AGENTS.md` says the same thing under CODING RULE FILES.

VS Code Copilot loads `AGENTS.md` and `.github/copilot-instructions.md`
automatically. Cowork and other agents do not, which is why this file names
them explicitly.

These files are physical copies taken from `_AgentKit` when the project was
created. They do not update automatically. If a shared master changes and you
want the update here, re-copy it by hand.

Outputs render to `REPORTS/`. See `README.md` for the day-to-day workflow.
