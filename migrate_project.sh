#!/usr/bin/env zsh
#
# migrate_project.sh
#
# Bring a project created before the August 2026 restructure onto the current
# layout, without ever renaming or replacing the project folder itself. The
# folder keeps its identity, which matters when it is shared through Dropbox:
# renaming a shared folder breaks the share for everyone it is shared with.
#
#   1. Copy the project to a sibling backup.
#   2. Verify the backup by file count and byte total. Refuse to go on if it
#      does not match, which is what catches Dropbox online-only placeholders.
#   3. Ask before the one irreversible step.
#   4. Erase the contents of the original folder, keeping the folder.
#   5. Build the current structure inside it.
#   6. Copy content back from the backup into its new places.
#   7. Anything unrecognized returns to the project root at its old relative
#      path, so nothing is silently dropped.
#   8. Name the backup <Project>_premigration once all of that succeeds.
#
# If any step after the erase fails, the original contents are restored from
# the backup and the script exits non-zero.
#
# The script moves files and never edits their contents. The analysis variable,
# the ../../ YAML paths, and the {{< include >}} paths all still need changing,
# and the closing message lists them.
#
# Before running: make the project available offline in Dropbox, and pick a
# time when nobody else is working in it. Every file will be deleted and
# recreated at a new path, which collaborators will see sync through.
#
# Written in the portable subset so it behaves the same under zsh and bash.
#
# Usage:
#   migrate_project.sh <ProjectName> [parent-dir]

set -eu

AGENT_KIT="$HOME/Library/CloudStorage/Dropbox/Work/_AgentKit"

if [ $# -lt 1 ]; then
  echo "Usage: migrate_project.sh <ProjectName> [parent-dir]" >&2
  exit 2
fi
PROJECT_NAME="$1"
PARENT_DIR="${2:-$PWD}"
PROJECT_DIR="$PARENT_DIR/$PROJECT_NAME"
BACKUP_FINAL="$PARENT_DIR/${PROJECT_NAME}_premigration"
BACKUP_WIP="$PARENT_DIR/${PROJECT_NAME}_premigration_INCOMPLETE"
SCAFFOLD_TMP="$PARENT_DIR/.${PROJECT_NAME}_scaffold_tmp"
# Declared here so the failure trap can clean them up even if it fires before
# the steps that populate them.
HANDLED="$PARENT_DIR/.${PROJECT_NAME}_handled"
STRAY_LIST="$PARENT_DIR/.${PROJECT_NAME}_strays"

# Files the current masters replace. Dropped rather than carried back.
is_superseded () {
  case "$1" in
    AGENTS.md|CLAUDE.md|README.md) return 0 ;;
    .github/copilot-instructions.md|.github/copilot-instructions-proposals.md) return 0 ;;
    REFERENCES/R_Rules.md|REFERENCES/Mplus_Rules.md) return 0 ;;
    RULES_AND_LOGS/R_Rules.md|RULES_AND_LOGS/Mplus_Rules.md) return 0 ;;
    *) return 1 ;;
  esac
}

# --- safety checks -----------------------------------------------------------

[ -d "$AGENT_KIT" ]                || { echo "Error: _AgentKit not found at $AGENT_KIT" >&2; exit 1; }
[ -f "$AGENT_KIT/new_project.sh" ] || { echo "Error: $AGENT_KIT/new_project.sh missing" >&2; exit 1; }
[ -d "$PROJECT_DIR" ]              || { echo "Error: $PROJECT_DIR does not exist" >&2; exit 1; }
[ ! -e "$BACKUP_FINAL" ]           || { echo "Error: $BACKUP_FINAL exists. Migration may have run before." >&2; exit 1; }
[ ! -e "$BACKUP_WIP" ]             || { echo "Error: $BACKUP_WIP exists from an interrupted run. Inspect it before retrying." >&2; exit 1; }
[ ! -e "$SCAFFOLD_TMP" ]           || { echo "Error: $SCAFFOLD_TMP exists from an interrupted run." >&2; exit 1; }

if [ ! -f "$PROJECT_DIR/AGENTS.md" ]; then
  echo "Error: $PROJECT_DIR has no AGENTS.md, so it does not look like an" >&2
  echo "AgentKit project. Refusing to touch it." >&2
  exit 1
fi

if [ -d "$PROJECT_DIR/RULES_AND_LOGS" ] && [ -d "$PROJECT_DIR/TEMPLATES" ]; then
  echo "Error: $PROJECT_DIR already has RULES_AND_LOGS/ and TEMPLATES/, so it" >&2
  echo "is already on the current layout. Nothing to migrate." >&2
  exit 1
fi

# --- choose the analysis name ------------------------------------------------

echo "Control files at the root of $PROJECT_NAME:"
SUGGEST=""
for f in "$PROJECT_DIR"/*_Control.qmd "$PROJECT_DIR"/*_Control.domd; do
  [ -e "$f" ] || continue
  echo "  $(basename "$f")"
  if [ -z "$SUGGEST" ]; then
    SUGGEST="$(basename "$f")"; SUGGEST="${SUGGEST%_Control.qmd}"; SUGGEST="${SUGGEST%_Control.domd}"
  fi
done
[ -n "$SUGGEST" ] || { echo "  (none)"; SUGGEST="Analysis1"; }

echo ""
echo "Name the analysis subfolder. Sources for one analysis move into R/<name>/,"
echo "and Stata sources into Stata/<name>/."
printf "Analysis name [%s]: " "$SUGGEST"
read ANALYSIS || ANALYSIS=""
[ -n "$ANALYSIS" ] || ANALYSIS="$SUGGEST"
echo ""

# --- 1. copy to a backup -----------------------------------------------------

echo "Copying $PROJECT_NAME to a backup..."
cp -R "$PROJECT_DIR" "$BACKUP_WIP"

# --- 2. verify the backup ----------------------------------------------------

count_files () { find "$1" -type f 2>/dev/null | wc -l | tr -d ' '; }
total_bytes () { find "$1" -type f -exec wc -c {} + 2>/dev/null | tail -1 | awk '{print $1}'; }

SRC_N="$(count_files "$PROJECT_DIR")";  BAK_N="$(count_files "$BACKUP_WIP")"
SRC_B="$(total_bytes "$PROJECT_DIR")";  BAK_B="$(total_bytes "$BACKUP_WIP")"

echo "  original: $SRC_N files, $SRC_B bytes"
echo "  backup:   $BAK_N files, $BAK_B bytes"

if [ "$SRC_N" != "$BAK_N" ] || [ "$SRC_B" != "$BAK_B" ]; then
  rm -rf "$BACKUP_WIP"
  echo "" >&2
  echo "Error: the backup does not match the original. Nothing was changed and" >&2
  echo "the partial backup was removed." >&2
  echo "" >&2
  echo "The usual cause is Dropbox online-only files, which copy as placeholders." >&2
  echo "Right-click the project in Finder, choose Make Available Offline, wait" >&2
  echo "for it to finish, then run this again." >&2
  exit 1
fi
echo "  backup verified"
echo ""

# --- 3. confirm --------------------------------------------------------------

echo "Next step empties $PROJECT_DIR and rebuilds it. The folder itself stays,"
echo "so any Dropbox share on it survives. The backup above holds everything."
printf "Proceed? [y/N]: "
read REPLY || REPLY=""
case "$REPLY" in
  y|Y|yes|YES) ;;
  *) rm -rf "$BACKUP_WIP"; echo "Cancelled. Nothing was changed."; exit 0 ;;
esac
echo ""

# From here on, a failure restores the original from the backup.
restore () {
  echo "" >&2
  echo "Migration failed. Restoring $PROJECT_NAME from the backup..." >&2
  rm -rf "$SCAFFOLD_TMP"
  # Empty the folder and refill it, rather than removing and recreating it.
  # Removing the folder would break any Dropbox share on it, which is the one
  # thing this whole design exists to protect.
  find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
  for _r in "$BACKUP_WIP"/* "$BACKUP_WIP"/.[!.]*; do
    [ -e "$_r" ] || continue
    cp -R "$_r" "$PROJECT_DIR/"
  done
  rm -rf "$BACKUP_WIP"
  rm -f "$HANDLED" "$STRAY_LIST"
  echo "Restored in place. The folder was never removed and nothing was lost." >&2
  exit 1
}
trap restore EXIT INT TERM

# --- 4. empty the original, keeping the folder -------------------------------

find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
echo "Emptied $PROJECT_NAME, folder kept in place"

# --- 5. build the current structure inside it --------------------------------

mkdir -p "$SCAFFOLD_TMP"
"$AGENT_KIT/new_project.sh" "$PROJECT_NAME" "$SCAFFOLD_TMP" >/dev/null 2>&1 || true
[ -d "$SCAFFOLD_TMP/$PROJECT_NAME" ] || { echo "Error: new_project.sh produced nothing" >&2; false; }

for f in "$SCAFFOLD_TMP/$PROJECT_NAME"/* "$SCAFFOLD_TMP/$PROJECT_NAME"/.[!.]*; do
  [ -e "$f" ] || continue
  mv "$f" "$PROJECT_DIR/"
done
rm -rf "$SCAFFOLD_TMP"
echo "Built the current structure in place"

mkdir -p "$PROJECT_DIR/R/$ANALYSIS" "$PROJECT_DIR/Stata/$ANALYSIS"

# Keep the two R starters for this analysis; drop the template drivers so there
# is no question which driver is yours once your own lands here.
SEED="$PROJECT_DIR/R/Analysis1"
if [ -d "$SEED" ] && [ "$ANALYSIS" != "Analysis1" ]; then
  for f in "$SEED"/000-Libraries.R "$SEED"/001-Environment-settings.R; do
    [ -e "$f" ] && mv "$f" "$PROJECT_DIR/R/$ANALYSIS/"
  done
  rm -rf "$SEED"
  rmdir "$PROJECT_DIR/Stata/Analysis1" 2>/dev/null || true
fi
rm -f "$PROJECT_DIR/R/$ANALYSIS"/manuscript_Driver.R \
      "$PROJECT_DIR/R/$ANALYSIS"/manuscript_Control.qmd \
      "$PROJECT_DIR/R/$ANALYSIS"/slides_Driver.R \
      "$PROJECT_DIR/R/$ANALYSIS"/slides_Control.qmd

# --- 6. copy content back into its new places --------------------------------

: > "$HANDLED"
mark () { echo "$1" >> "$HANDLED"; }

place () {   # place <relpath> <destination dir>
  _rel="$1"; _dest="$2"
  [ -e "$BACKUP_WIP/$_rel" ] || return 0
  mkdir -p "$_dest"
  cp -R "$BACKUP_WIP/$_rel" "$_dest/"
  mark "$_rel"
}

# Placement globs match one level only. Anything deeper under R/ or Stata/ is
# left for the stray pass, which returns it to its old path and lists it.
cd "$BACKUP_WIP"
for rel in *_Control.qmd *_Driver.R; do
  [ -e "$rel" ] && place "$rel" "$PROJECT_DIR/R/$ANALYSIS"
done
for rel in R/*.R R/*.qmd; do
  [ -e "$rel" ] && place "$rel" "$PROJECT_DIR/R/$ANALYSIS"
done
for rel in *_Control.domd *_Driver.do Stata/*.do Stata/*.domd; do
  [ -e "$rel" ] && place "$rel" "$PROJECT_DIR/Stata/$ANALYSIS"
done
for rel in REFERENCES/SESSION_LOGS.md REFERENCES/DECISIONS.md \
           RULES_AND_LOGS/SESSION_LOGS.md RULES_AND_LOGS/DECISIONS.md; do
  [ -e "$rel" ] && place "$rel" "$PROJECT_DIR/RULES_AND_LOGS"
done
for rel in reference_*.docx TEMPLATES/reference_*.docx; do
  [ -e "$rel" ] && place "$rel" "$PROJECT_DIR/TEMPLATES"
done
for rel in *.bib *.rproj *.Rproj; do
  [ -e "$rel" ] && place "$rel" "$PROJECT_DIR"
done
cd - >/dev/null

# Whole folders that keep their names and contents.
for d in REFERENCES FIGURES MD EXCALIDRAW REPORTS ADMIN RENDER \
         R/RDATA R/MPLUS_OUTPUT Stata/DTA Stata/MPLUS_OUTPUT; do
  [ -d "$BACKUP_WIP/$d" ] || continue
  mkdir -p "$PROJECT_DIR/$d"
  for f in "$BACKUP_WIP/$d"/* "$BACKUP_WIP/$d"/.[!.]*; do
    [ -e "$f" ] || continue
    rel="$d/$(basename "$f")"
    is_superseded "$rel" && { mark "$rel"; continue; }
    grep -qxF "$rel" "$HANDLED" 2>/dev/null && continue
    cp -R "$f" "$PROJECT_DIR/$d/"
    if [ -d "$f" ]; then
      # Mark every file inside, or the stray pass reports them as unsorted.
      ( cd "$BACKUP_WIP" && find "$rel" -type f ) >> "$HANDLED"
    else
      mark "$rel"
    fi
  done
done

# --- 7. anything unrecognized goes back to its old relative path -------------

STRAYS=0
: > "$STRAY_LIST"
cd "$BACKUP_WIP"
find . -type f | sed 's|^\./||' | while read -r rel; do
  grep -qxF "$rel" "$HANDLED" 2>/dev/null && continue
  is_superseded "$rel" && continue
  case "$rel" in
    R/*/*) ;;                             # nested under R/: never placed, so report it
    R/[0-9]*|R/*.R|R/*.qmd) continue ;;   # already placed in the analysis folder
  esac
  echo "$rel" >> "$STRAY_LIST"
done
cd - >/dev/null

if [ -s "$STRAY_LIST" ]; then
  while read -r rel; do
    mkdir -p "$PROJECT_DIR/$(dirname "$rel")"
    [ -e "$PROJECT_DIR/$rel" ] || cp "$BACKUP_WIP/$rel" "$PROJECT_DIR/$rel"
  done < "$STRAY_LIST"
  STRAYS="$(wc -l < "$STRAY_LIST" | tr -d ' ')"
fi

# --- 8. name the backup ------------------------------------------------------

trap - EXIT INT TERM
mv "$BACKUP_WIP" "$BACKUP_FINAL"
rm -f "$HANDLED"

NEW_N="$(count_files "$PROJECT_DIR")"

cat <<EOF

Migrated $PROJECT_NAME in place. The folder was never renamed, so any Dropbox
share on it is intact.

  backup:          ${PROJECT_NAME}_premigration ($SRC_N files)
  rebuilt project: $NEW_N files
  analysis folder: R/$ANALYSIS
  unsorted files returned to their old paths: $STRAYS
EOF

if [ "$STRAYS" -gt 0 ]; then
  echo ""
  echo "  Unsorted, listed so you can file them:"
  sed 's/^/    /' "$STRAY_LIST"
fi
rm -f "$STRAY_LIST"

cat <<EOF

AGENTS.md, .github/copilot-instructions.md, CLAUDE.md, and README.md are the
current masters. Your old copies are in the backup, not in the project.

The current driver pattern to copy from:
  $AGENT_KIT/templates/manuscript_Driver.R
  $AGENT_KIT/templates/slides_Driver.R

STILL TO DO BY HAND. The script moved files and changed no file contents.

1. In R/$ANALYSIS/*_Driver.R, set:
     analysis <- "$ANALYSIS"
     stem     <- "<control file stem, without _Control>"
   and replace the driver body with the pattern above.

2. In R/$ANALYSIS/*_Control.qmd, add to the setup chunk:
     analysis <- "$ANALYSIS"
   and source the starters through here::here("R", analysis, ...).

3. In that control file's YAML, prefix root-level paths with ../../ :
     reference-doc: "../../TEMPLATES/reference_<type>.docx"
     bibliography: ../../bibliography.bib

4. Fix {{< include >}} paths. Child .qmd files are siblings now.

5. Any driver still passing --output-dir will empty that directory on its next
   run. Check with:
     grep -l -- '--output-dir' R/$ANALYSIS/*_Driver.R

6. Render once, confirm output in RENDER/ and a dated copy in REPORTS/, then
   delete ${PROJECT_NAME}_premigration.
EOF
