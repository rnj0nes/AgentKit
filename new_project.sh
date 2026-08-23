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
AGENT_KIT="$HOME/Library/CloudStorage/Dropbox/Work/_AgentKit"
# ------------------------------------------------------------

PROJECT_NAME="${1:?Usage: new_project.sh <ProjectName> [parent-dir]}"
PARENT_DIR="${2:-$PWD}"
PROJECT_DIR="$PARENT_DIR/$PROJECT_NAME"

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
for d in RENDER REPORTS EXCALIDRAW FIGURES REFERENCES RULES_AND_LOGS ADMIN MD R Stata TEMPLATES .github; do
  mkdir -p "$d"
done
mkdir -p REFERENCES/LLM_OUT R/RDATA R/MPLUS_OUTPUT Stata/DTA Stata/MPLUS_OUTPUT
touch EXCALIDRAW/figure-1.excalidraw.svg bibliography.bib

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
cp "$AGENT_KIT/AGENTS.md" "AGENTS.md"
cp "$AGENT_KIT/academic-writing-style.md" ".github/copilot-instructions.md"

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
cp "$AGENT_KIT/templates/copilot-instructions-proposals.md" \
   ".github/copilot-instructions-proposals.md"

# Drivers, control files, and the R starters go inside the analysis subfolder,
# not the project root.
cp "$AGENT_KIT/templates/slides_Control.qmd"           "R/$ANALYSIS/slides_Control.qmd"
cp "$AGENT_KIT/templates/slides_Driver.R"              "R/$ANALYSIS/slides_Driver.R"
cp "$AGENT_KIT/templates/manuscript_Control.qmd"       "R/$ANALYSIS/manuscript_Control.qmd"
cp "$AGENT_KIT/templates/manuscript_Driver.R"          "R/$ANALYSIS/manuscript_Driver.R"
cp "$AGENT_KIT/templates/R/000-Libraries.R"            "R/$ANALYSIS/000-Libraries.R"
cp "$AGENT_KIT/templates/R/001-Environment-settings.R" "R/$ANALYSIS/001-Environment-settings.R"

echo "Created $PROJECT_DIR"
echo "Copied AGENTS.md, .github/copilot-instructions.md, CLAUDE.md, README.md,"
echo "RULES_AND_LOGS/R_Rules.md, RULES_AND_LOGS/Mplus_Rules.md,"
echo "the slide and manuscript templates and R starters into R/$ANALYSIS/,"
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
echo "Next steps (project specific, by design):"
echo "  1. Rename R/$ANALYSIS to your analysis name, then set the 'analysis'"
echo "     line in each Driver.R and each Control.qmd to match."
echo "  2. Add further analyses as sibling folders under R/ (or Stata/)."
echo "     RENDER/ and REPORTS/ stay flat and are shared by all of them."
echo "  3. Put references in REFERENCES/ and run pdf2llm on new PDFs."
echo "  4. Ask your agent to build bibliography.bib from REFERENCES/."
echo "  5. Read README.md, then start working."
echo ""

# Open in VS Code if the 'code' command is available; otherwise skip quietly.
if command -v code >/dev/null 2>&1; then
  echo "Opening in VS Code..."
  code "$PROJECT_DIR"
else
  echo "VS Code 'code' command not found on PATH; open the folder manually."
fi
