#!/usr/bin/env zsh
#
# new_project.sh
#
# Scaffolds a new AI-agent-supported analysis project by COPYING the canonical
# files kept in _AgentKit into the new project folder.
#
# Copies, not symlinks. Each project owns its own files, and they freeze at
# creation. An earlier version of this script used symlinks so that editing a
# master updated every project at once. That turned out to be fragile in
# practice, so the model is now simpler: copy on creation, and if a master
# later changes and you want the update in an existing project, copy it in by
# hand.
#
# Usage:
#   new_project.sh <ProjectName> [parent-dir]
#
# Examples:
#   new_project.sh RethinkingClassification
#   new_project.sh RethinkingClassification ~/Library/CloudStorage/Dropbox/Work
#
# If parent-dir is omitted, the project is created inside the current directory.
#
# One time setup before first use:
#   1. Edit AGENT_KIT below to point at your _AgentKit folder.
#   2. chmod +x new_project.sh
#   3. Place it on your PATH (e.g. the same bin folder pdf2llm.sh lives in).

set -euo pipefail
setopt null_glob 2>/dev/null || true   # zsh; harmless no-op under bash

# --- edit this one line if you move or rename _AgentKit ---
AGENT_KIT="${AGENT_KIT:-$HOME/Library/CloudStorage/Dropbox/Work/_AgentKit}"
# ------------------------------------------------------------

PROJECT_NAME="${1:?Usage: new_project.sh <ProjectName> [parent-dir]}"
PARENT_DIR="${2:-$PWD}"
PROJECT_DIR="$PARENT_DIR/$PROJECT_NAME"

# Participant data lives outside the project. Each machine keeps one paths file
# per project here, read by 003-Data-paths.R and 003-Data-paths.do. Override
# with AGENTKIT_DATA_PATHS, which the helpers honour too.
DATA_PATHS_DIR="${AGENTKIT_DATA_PATHS:-$HOME/.agentkit/data_paths}"
PATHS_FILE="$DATA_PATHS_DIR/$PROJECT_NAME.txt"

if [[ ! -d "$AGENT_KIT" ]]; then
  echo "Error: _AgentKit not found at $AGENT_KIT" >&2
  echo "Edit the AGENT_KIT variable at the top of this script." >&2
  exit 1
fi

if [[ -e "$PROJECT_DIR" ]]; then
  echo "Error: $PROJECT_DIR already exists." >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# --- folder skeleton ---
# No DATA/, R/RDATA/, or Stata/DTA/: data lives outside the project, in the
# locations named in the paths file. RESULTS/ holds aggregate results only, and
# DATA_DICTIONARY/ describes the data without holding any.
for d in RENDER REPORTS EXCALIDRAW FIGURES REFERENCES RULES_AND_LOGS ADMIN MD RESULTS DATA_DICTIONARY R Stata TEMPLATES .github; do
  mkdir -p "$d"
done
mkdir -p REFERENCES/LLM_OUT R/MPLUS_OUTPUT Stata/MPLUS_OUTPUT
touch EXCALIDRAW/figure-1.excalidraw.svg bibliography.bib

# Manifest for the DERIVED location. AGENTS.md requires an entry for every kept
# dataset. It lives in the project and names files, never their location.
cat > RULES_AND_LOGS/DATA_MANIFEST.md <<'MANIFEST'
# DERIVED data manifest

Datasets this project builds and keeps for reuse or sharing, in the DERIVED
location named in the paths file. Each is built only from SOURCE or DERIVED
files. Add a row whenever a file is added, and update its row whenever the file
is rebuilt.

| File | Written by (driver) | Inputs | Last built |
| --- | --- | --- | --- |
MANIFEST

# Hand-written files in DATA_DICTIONARY/. 005-Data-dictionary.R writes the
# other files there and never touches these two.
cat > DATA_DICTIONARY/ID_VARIABLES.txt <<'IDS'
# Participant ID variables, one name per line. save_result() refuses any table
# holding one of these, and the data dictionary reports how each identifies
# rows. Lines starting with # are comments.
IDS

cat > DATA_DICTIONARY/STUDY_NOTES.md <<'NOTES'
# Study notes

Written by hand. The generated files in this folder describe each data file's
structure and distributions. This file holds what they cannot: study design,
which variables are outcomes and exposures, how waves map to dates, sample
restrictions, and known data problems.
NOTES

# Root marker for the here package. Drivers and control files live in
# R/<Analysis>/ and reach the project root with here::here(), which needs a
# sentinel at the top. Without this, here() falls back to the working directory
# and every path in every driver resolves to the wrong place.
touch .here

# Each analysis gets its own subfolder under R/ (or Stata/), holding its driver,
# its control file, and its own copies of the R starters. RENDER/ and REPORTS/
# stay flat at the project root and are shared by every analysis.
ANALYSIS="Analysis1"
mkdir -p "R/$ANALYSIS" "Stata/$ANALYSIS"

# --- copy the contract and writing style (physical copies, not symlinks) ---
# AGENTS.md already opens with the prime directive. The two Copilot files are
# generated from masters that do not carry it, so it is prepended here. Copilot
# loads copilot-instructions.md on every request, and AGENTS.md only when a
# setting is on, so the Copilot file must carry the rule itself.
cp "$AGENT_KIT/AGENTS.md" "AGENTS.md"
{ cat "$AGENT_KIT/PRIME_DIRECTIVE.md"; echo; cat "$AGENT_KIT/academic-writing-style.md"; } \
  > ".github/copilot-instructions.md"

# --- copy the coding rule files AGENTS.md points at ---
cp "$AGENT_KIT/RULES_AND_LOGS/R_Rules.md"     "RULES_AND_LOGS/R_Rules.md"
cp "$AGENT_KIT/RULES_AND_LOGS/Mplus_Rules.md" "RULES_AND_LOGS/Mplus_Rules.md"

# --- copy every typed reference doc into the project's TEMPLATES/ ---
# These are working files, not shared constants. Each project restyles its own
# copies, often more than once, which is why every project gets its own set.
LINKED_REFS=()
for ref in "$AGENT_KIT"/templates/reference_*.docx; do
  # An unmatched glob stays literal under bash, and the null_glob setopt above
  # only applies under zsh. Skip anything that is not a real file.
  [[ -e "$ref" ]] || continue
  name="$(basename "$ref")"
  cp "$ref" "TEMPLATES/$name"
  LINKED_REFS+=("TEMPLATES/$name")
done

# --- copy project templates ---
cp "$AGENT_KIT/templates/CLAUDE.md" "CLAUDE.md"
cp "$AGENT_KIT/templates/README.md" "README.md"

# The grant adjunct ships alongside the base writing standard but does not load
# on its own, because Copilot auto-loads only copilot-instructions.md and
# AGENTS.md. A project that turns out to involve grant writing appends this file
# to copilot-instructions.md, or names it in chat. A project that never writes a
# grant ignores it.
{ cat "$AGENT_KIT/PRIME_DIRECTIVE.md"; echo; cat "$AGENT_KIT/templates/copilot-instructions-proposals.md"; } \
  > ".github/copilot-instructions-proposals.md"

# Drivers, control files, and the R starters go inside the analysis subfolder,
# not the project root.
cp "$AGENT_KIT/templates/slides_Control.qmd"           "R/$ANALYSIS/slides_Control.qmd"
cp "$AGENT_KIT/templates/slides_Driver.R"              "R/$ANALYSIS/slides_Driver.R"
cp "$AGENT_KIT/templates/manuscript_Control.qmd"       "R/$ANALYSIS/manuscript_Control.qmd"
cp "$AGENT_KIT/templates/manuscript_Driver.R"          "R/$ANALYSIS/manuscript_Driver.R"
cp "$AGENT_KIT/templates/R/000-Libraries.R"            "R/$ANALYSIS/000-Libraries.R"
cp "$AGENT_KIT/templates/R/001-Environment-settings.R" "R/$ANALYSIS/001-Environment-settings.R"

# The manuscript driver sources this one to re-save its DOCX through
# LibreOffice, which is what stops Word reporting flextable output as damaged.
cp "$AGENT_KIT/templates/R/002-Word-safe-docx.R"       "R/$ANALYSIS/002-Word-safe-docx.R"

# Data helpers. 001-Environment-settings.R sources all three.
cp "$AGENT_KIT/templates/R/003-Data-paths.R"           "R/$ANALYSIS/003-Data-paths.R"
cp "$AGENT_KIT/templates/R/004-Save-result.R"          "R/$ANALYSIS/004-Save-result.R"
cp "$AGENT_KIT/templates/R/005-Data-dictionary.R"      "R/$ANALYSIS/005-Data-dictionary.R"
cp "$AGENT_KIT/templates/Stata/003-Data-paths.do"      "Stata/$ANALYSIS/003-Data-paths.do"

# The paths file sits outside the project and is never overwritten. A new one
# has every line commented out, so the project renders before any data exists.
mkdir -p "$DATA_PATHS_DIR"
if [[ -e "$PATHS_FILE" ]]; then
  PATHS_NOTE="Kept the existing data paths file: $PATHS_FILE"
else
  cat > "$PATHS_FILE" <<'PATHS'
# Data locations for this project on this machine. One KEY=path line each.
# Remove the # from each line and fill in the path. SHARE_DATA may stay empty.
# Agents never read this file. Keep it out of Dropbox and out of the project.
# SOURCE=
# DERIVED=
# WORK=
# SHARE_DATA=
# MPLUS=
PATHS
  PATHS_NOTE="Wrote a data paths file to fill in: $PATHS_FILE"
fi

# REPORTS/ gains a dated copy on every render. archive_reports.R moves the older
# copies of each report into REPORTS/Archive/ and keeps the newest. Run it with
# Rscript on any platform; its README explains how it groups the files.
cp "$AGENT_KIT/templates/REPORTS/archive_reports.R"        "REPORTS/archive_reports.R"
cp "$AGENT_KIT/templates/REPORTS/archive_reports_README.md" "REPORTS/archive_reports_README.md"

echo "Created $PROJECT_DIR"
echo "Copied AGENTS.md, .github/copilot-instructions.md, CLAUDE.md, README.md,"
echo "RULES_AND_LOGS/R_Rules.md, RULES_AND_LOGS/Mplus_Rules.md,"
echo "the slide and manuscript templates and R starters into R/$ANALYSIS/,"
echo "including 002-Word-safe-docx.R, which the manuscript driver sources,"
echo "the data helpers 003-Data-paths.R, 004-Save-result.R, and"
echo "005-Data-dictionary.R, and Stata/$ANALYSIS/003-Data-paths.do,"
echo "REPORTS/archive_reports.R and its README, which move older report copies"
echo "into REPORTS/Archive/ (run: Rscript REPORTS/archive_reports.R),"
echo "and reference doc(s):"
if [[ ${#LINKED_REFS[@]} -gt 0 ]]; then
  printf '  %s\n' "${LINKED_REFS[@]}"
else
  echo "  (none found)"
  echo ""
  echo "  No reference_*.docx in $AGENT_KIT/templates. DOCX renders need one."
  echo "  Create a pandoc reference doc, name it reference_<type>.docx, and"
  echo "  drop it there. The script globs and does not hardcode names."
fi
echo ""
echo "$PATHS_NOTE"
echo ""
echo "Next steps (project specific, by design):"
echo "  1. Rename R/$ANALYSIS to your analysis name, then set the 'analysis'"
echo "     line in each Driver.R and each Control.qmd to match."
echo "  2. Add further analyses as sibling folders under R/ (or Stata/)."
echo "     RENDER/ and REPORTS/ stay flat and are shared by all of them."
echo "  3. Fill in the data paths file above, list the participant ID"
echo "     variables in DATA_DICTIONARY/ID_VARIABLES.txt, and put data in the"
echo "     SOURCE location, never in the project."
echo "  4. Put references in REFERENCES/ and run pdf2llm on new PDFs."
echo "  5. Ask your agent to build bibliography.bib from REFERENCES/."
echo "  6. Read README.md, then start working."
echo ""

# Open in VS Code if the 'code' command is available; otherwise skip quietly.
if command -v code >/dev/null 2>&1; then
  echo "Opening in VS Code..."
  code "$PROJECT_DIR"
else
  echo "VS Code 'code' command not found on PATH; open the folder manually."
fi
