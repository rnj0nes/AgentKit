#!/usr/bin/env zsh
#
# add_word_safe_docx.sh
#
# Adds the LibreOffice DOCX re-save to a project that already exists.
#
# Quarto writes DOCX files that Word reports as damaged whenever the document
# holds flextable tables. Word opens the recovered copy under the name
# "Document 1", so the original filename is lost. LibreOffice reads the same
# file without complaint. Re-encoding the file through LibreOffice's Word
# filter produces a DOCX that Word opens directly.
#
# The change has two parts. This script makes both:
#
#   1. Copy 002-Word-safe-docx.R into every analysis folder under R/.
#   2. In each DOCX driver, replace the plain copy into REPORTS/ with a call to
#      word_safe_docx(). RENDER/ keeps Quarto's own output and REPORTS/ gets
#      the version Word accepts.
#
# LibreOffice is optional for the project this runs on. A machine without it
# gets the plain dated copy plus a note about what installing LibreOffice would
# buy, so this script is safe to run whether or not LibreOffice is present.
#
# What it refuses to do. It patches a driver only when the statement being
# replaced occurs exactly once at the left margin. Other drivers are reported
# and left alone, with replacement text printed for you to place by hand.
# It backs up every driver it touches to <name>.bak first. It changes
# no rule files, no control files, and nothing under RENDER/ or REPORTS/.
#
# Running it twice is safe. A driver already on the current pattern is reported
# as up to date and skipped. A driver on the first version of the pattern, the
# one that stopped the render when LibreOffice was missing, is upgraded.
#
# This is a one-shot script for one change, not an update mechanism. Projects
# own frozen copies of the masters by design, and that stays true.
#
# Requires python3 for the driver patch, which macOS provides through the
# Command Line Tools.
#
# Usage:
#   add_word_safe_docx.sh [project-dir]
#
# The argument is a path, not a project name, and it defaults to the folder you
# are standing in. Note that this differs from migrate_project.sh, which takes a
# project name plus an optional parent directory.
#
# Examples:
#   add_word_safe_docx.sh                                  # from inside the project
#   add_word_safe_docx.sh MyProject                        # from the parent folder
#   add_word_safe_docx.sh ~/Library/CloudStorage/Dropbox/Work/MyProject

set -eu
setopt null_glob 2>/dev/null || true   # zsh; harmless no-op under bash

# --- edit this one line if you move or rename _AgentKit ---
AGENT_KIT="$HOME/Library/CloudStorage/Dropbox/Work/_AgentKit"
# ------------------------------------------------------------

HELPER="$AGENT_KIT/templates/R/002-Word-safe-docx.R"

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "No such folder: $PROJECT_DIR" >&2
  echo "Usage: add_word_safe_docx.sh [project-dir]   (defaults to .)" >&2
  exit 1
fi

# Report an absolute path, so a run with no argument still names the project it
# changed rather than printing a dot.
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [ ! -f "$HELPER" ]; then
  echo "Missing $HELPER" >&2
  echo "Point AGENT_KIT at your _AgentKit folder and try again." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found. The driver patch needs it." >&2
  exit 1
fi

# Confirm this is an AgentKit project rather than an arbitrary folder, so a
# mistyped path cannot scatter R files somewhere unrelated.
if [ ! -d "$PROJECT_DIR/R" ] || [ ! -f "$PROJECT_DIR/AGENTS.md" ]; then
  echo "$PROJECT_DIR does not look like an AgentKit project." >&2
  echo "Expected an R/ folder and an AGENTS.md at its root." >&2
  exit 1
fi

echo "Project: $PROJECT_DIR"
echo ""

analyses=0
patched=0
upgraded=0
skipped=0
drifted=0

for dir in "$PROJECT_DIR"/R/*/; do
  [ -d "$dir" ] || continue

  # RDATA/ and MPLUS_OUTPUT/ sit under R/ but hold output, not analyses.
  base="$(basename "$dir")"
  case "$base" in
    RDATA|MPLUS_OUTPUT) continue ;;
  esac

  # An analysis folder is one that holds a driver.
  has_driver=0
  for d in "$dir"*_Driver.R; do
    [ -f "$d" ] && has_driver=1
  done
  [ "$has_driver" -eq 1 ] || continue

  analyses=$((analyses + 1))
  cp "$HELPER" "$dir/002-Word-safe-docx.R"
  echo "R/$base/"
  echo "  copied 002-Word-safe-docx.R"

  for driver in "$dir"*_Driver.R; do
    [ -f "$driver" ] || continue
    name="$(basename "$driver")"

    patch_status="$(PATCH_TARGET="$driver" python3 - <<'PY'
import os
import re
import shutil

path = os.environ["PATCH_TARGET"]
src = open(path, encoding="utf-8").read()


def done(word):
    print(word)
    raise SystemExit


# Only DOCX drivers need this. A slides driver's closing statements read the
# same but produce HTML, which Word never opens.
if not re.search(r'^ext\s*<-\s*"docx"', src, re.M):
    done("not-docx")

# A driver already on the current pattern is left alone.
if "converted <- word_safe_docx(" in src:
    done("already")

# Match the statements being replaced, not the comments around them. Rich's
# real drivers carry their own headers and their own comments, so a whole-block
# match finds almost none of them. Each pattern is anchored to newlines, so it
# matches a whole statement at the left margin and not a fragment of a longer
# line.
CALL_OLD  = "\nfile.copy(flat, dated, overwrite = TRUE)\n"
CALL_PREV = "\nword_safe_docx(flat, dated, quiet = TRUE)\n"
CALL_NEW  = """
# LibreOffice is optional. Without it the file is copied unchanged and the
# helper prints a note about what installing LibreOffice would buy, so a render
# never fails on this account.
source(file.path(src_dir, "002-Word-safe-docx.R"))
converted <- word_safe_docx(flat, dated, quiet = TRUE)
"""

CAT_OLD = '''cat("Built", basename(flat), "in RENDER/, copied to REPORTS/ as",
    basename(dated), "\\n")'''
CAT_PREV = '''cat("Built", basename(flat), "in RENDER/, re-saved to REPORTS/ as",
    basename(dated), "\\n")'''
CAT_NEW = '''cat("Built", basename(flat), "in RENDER/,",
    if (converted) "re-saved to REPORTS/ as" else "copied unconverted to REPORTS/ as",
    basename(dated), "\\n")'''

COMMENT_PREV = '''# word_safe_docx() stops on any failure, so a DOCX in REPORTS/ has either been
# through LibreOffice or this driver has halted.
'''
COMMENT_NEW = '''# LibreOffice is optional. Without it the file is copied unchanged and the
# helper prints a note about what installing LibreOffice would buy, so a render
# never fails on this account.
'''

if src.count(CALL_PREV) == 1:
    out = src.replace(CALL_PREV, "\nconverted <- word_safe_docx(flat, dated, quiet = TRUE)\n")
    out = out.replace(COMMENT_PREV, COMMENT_NEW)
    verdict = "upgraded"
    cat_from = CAT_PREV
elif src.count(CALL_OLD) == 1:
    out = src.replace(CALL_OLD, CALL_NEW)
    verdict = "patched"
    cat_from = CAT_OLD
else:
    # Zero matches means the driver does not use the statement this change
    # replaces. More than one means the script cannot tell which to replace.
    done("drifted")

# The closing message is replaced only when it matches, because a driver whose
# message was rewritten still needs the call patched.
if cat_from in out:
    out = out.replace(cat_from, CAT_NEW)
else:
    verdict = verdict + "-nocat"

shutil.copy2(path, path + ".bak")
open(path, "w", encoding="utf-8").write(out)
done(verdict)
PY
)"

    case "$patch_status" in
      patched)
        patched=$((patched + 1))
        echo "  patched $name, backed up to $name.bak"
        ;;
      patched-nocat)
        patched=$((patched + 1))
        echo "  patched $name, backed up to $name.bak"
        echo "    its closing cat() message is your own, so check that it still"
        echo "    reads true; the file may now be copied rather than converted"
        ;;
      upgraded)
        upgraded=$((upgraded + 1))
        echo "  upgraded $name from the earlier pattern, backed up to $name.bak"
        ;;
      upgraded-nocat)
        upgraded=$((upgraded + 1))
        echo "  upgraded $name from the earlier pattern, backed up to $name.bak"
        echo "    its closing cat() message is your own, so check that it still"
        echo "    reads true; the file may now be copied rather than converted"
        ;;
      already)
        skipped=$((skipped + 1))
        echo "  $name already on the current pattern, left alone"
        ;;
      drifted)
        drifted=$((drifted + 1))
        echo "  $name has been edited, LEFT ALONE"
        ;;
      not-docx)
        : ;;
      *)
        echo "  could not read $name, left alone" >&2
        ;;
    esac
  done
  echo ""
done

if [ "$analyses" -eq 0 ]; then
  echo "Found no analysis folder under R/ holding a *_Driver.R." >&2
  exit 1
fi

echo "Analyses: $analyses. Drivers patched: $patched, upgraded: $upgraded,"
echo "already current: $skipped, edited and left alone: $drifted."
echo ""

if [ "$drifted" -gt 0 ]; then
  cat <<'EOM'
A driver was left alone because it does not hold exactly one statement reading

    file.copy(flat, dated, overwrite = TRUE)

at the left margin. Either it writes REPORTS/ some other way, or it does so in
more than one place and the script cannot tell which to change. Open it and
replace that copy with these two lines:

    source(file.path(src_dir, "002-Word-safe-docx.R"))
    converted <- word_safe_docx(flat, dated, quiet = TRUE)

The source() line needs src_dir, which every current driver already defines.
word_safe_docx() returns TRUE when it converted the file and FALSE when it
copied it unchanged, so the driver's closing message can say which happened.

EOM
fi

# Report on LibreOffice without making it a requirement.
SOFFICE_FOUND=""
for cand in "${SOFFICE:-}" \
            "/Applications/LibreOffice.app/Contents/MacOS/soffice" \
            "$HOME/Applications/LibreOffice.app/Contents/MacOS/soffice"; do
  if [ -n "$cand" ] && [ -x "$cand" ]; then SOFFICE_FOUND="$cand"; break; fi
done
if [ -z "$SOFFICE_FOUND" ]; then
  SOFFICE_FOUND="$(command -v soffice 2>/dev/null || command -v libreoffice 2>/dev/null || true)"
fi

if [ -n "$SOFFICE_FOUND" ]; then
  echo "LibreOffice found at $SOFFICE_FOUND, so renders will convert."
  echo ""
  cat <<'EOM'
Next:

  1. Render one DOCX and confirm the file in REPORTS/ opens in Word without
     the recovery prompt, and that its tables still look right.
  2. Delete the .bak files once that render succeeds.
  3. This project's RULES_AND_LOGS/R_Rules.md is now behind the master, which
     documents the re-save. Copy it in by hand if you want it current.
EOM
else
  cat <<'EOM'
LibreOffice was not found on this machine. That is fine: renders still write a
dated DOCX to REPORTS/, and the driver prints a note explaining what the
conversion would have fixed. Installing it later needs no further change here.

  https://www.libreoffice.org/download/

Next:

  1. Render one DOCX and confirm a dated file appears in REPORTS/. Word will
     still report a document with tables as damaged until LibreOffice is
     installed, which is what the driver's note is telling you.
  2. Delete the .bak files once that render succeeds.
  3. This project's RULES_AND_LOGS/R_Rules.md is now behind the master, which
     documents the re-save. Copy it in by hand if you want it current.
EOM
fi
