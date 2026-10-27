#!/usr/bin/env bash
#
# add_prime_directive.sh
#
# Puts the prime directive from PRIME_DIRECTIVE.md (kept beside this script)
# at the top of every agent instruction file under one or more folders. A file
# that already holds the block, between its PRIME-DIRECTIVE:BEGIN and
# PRIME-DIRECTIVE:END markers, has that block replaced with the current text,
# so running this again after a wording change updates every file in place and
# never adds a second copy.
#
# Usage:
#   add_prime_directive.sh [--apply] [folder ...]
#
# With no folder, it searches ~/Library/CloudStorage/Dropbox/Work. Without
# --apply it only lists what it would change. With --apply it backs up each
# file it changes to <name>.bak (or <name>.bak.<timestamp> if a .bak exists)
# and then writes the file in place.
#
# Files it looks for, by name, ignoring case:
#   AGENTS.md, CLAUDE.md, GEMINI.md, instructions.md, copilot-instructions.md,
#   copilot-instructions-proposals.md, *.instructions.md,
#   AgentKit_instructions.md, AgentKit_overview.md, SKILL.md
#
# Where the block goes:
#   - a file with the markers: the block between them is replaced
#   - a file starting with YAML frontmatter (a first line of ---): just after
#     the closing ---, because SKILL.md and *.instructions.md files must start
#     with their frontmatter
#   - any other file: the very top
#
# Folders it skips: .git, node_modules, *_premigration backups,
# _test_scaffold, .Trash, and .dropbox.cache. It also skips
# _AgentKit/templates/copilot-instructions-proposals.md, because
# new_project.sh adds the block to that file when it copies it.
#
# Changing an instruction file in a folder shared through Dropbox changes it
# for every collaborator who shares that folder.

set -euo pipefail

APPLY=0
ROOTS=()
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help) sed -n '2,38p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; exit 2 ;;
    *) ROOTS+=("$arg") ;;
  esac
done
if [[ ${#ROOTS[@]} -eq 0 ]]; then
  ROOTS=("$HOME/Library/CloudStorage/Dropbox/Work")
fi

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
DFILE="$KIT_DIR/PRIME_DIRECTIVE.md"
if [[ ! -f "$DFILE" ]]; then
  echo "Error: PRIME_DIRECTIVE.md not found beside this script, in $KIT_DIR" >&2
  exit 1
fi
if ! grep -q 'PRIME-DIRECTIVE:BEGIN' "$DFILE" || ! grep -q 'PRIME-DIRECTIVE:END' "$DFILE"; then
  echo "Error: $DFILE lacks its BEGIN and END marker lines." >&2
  exit 1
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Writes the new content of file $1 to $TMP.
render() {
  local f="$1"
  if grep -q '<!-- PRIME-DIRECTIVE:BEGIN' "$f"; then
    awk -v dfile="$DFILE" '
      /<!-- PRIME-DIRECTIVE:BEGIN/ { while ((getline l < dfile) > 0) print l; close(dfile); inb = 1; next }
      inb && /<!-- PRIME-DIRECTIVE:END/ { inb = 0; next }
      !inb { print }
    ' "$f" > "$TMP"
  elif [[ "$(head -n 1 "$f" | tr -d '\r')" == "---" ]]; then
    awk -v dfile="$DFILE" '
      NR == 1 { print; fm = 1; next }
      fm && /^---[[:space:]]*\r?$/ { print; print ""; while ((getline l < dfile) > 0) print l; close(dfile); print ""; fm = 0; next }
      { print }
    ' "$f" > "$TMP"
  else
    { cat "$DFILE"; echo; cat "$f"; } > "$TMP"
  fi
}

n_new=0; n_upd=0; n_same=0; n_skip=0

for root in "${ROOTS[@]}"; do
  if [[ ! -d "$root" ]]; then
    echo "Skipping $root: not a folder" >&2
    continue
  fi
  while IFS= read -r -d '' f; do
    case "$f" in
      */_AgentKit/templates/copilot-instructions-proposals.md) continue ;;
    esac

    has_begin=0; has_end=0
    grep -q '<!-- PRIME-DIRECTIVE:BEGIN' "$f" && has_begin=1
    grep -q '<!-- PRIME-DIRECTIVE:END' "$f" && has_end=1
    if [[ $has_begin -ne $has_end ]]; then
      echo "SKIP     $f  (has only one of the BEGIN and END markers; fix by hand)"
      n_skip=$((n_skip + 1)); continue
    fi

    render "$f"

    if [[ $has_begin -eq 0 ]] && ! grep -q 'PRIME-DIRECTIVE:BEGIN' "$TMP"; then
      echo "SKIP     $f  (frontmatter has no closing ---)"
      n_skip=$((n_skip + 1)); continue
    fi
    if cmp -s "$TMP" "$f"; then
      n_same=$((n_same + 1)); continue
    fi

    if [[ $has_begin -eq 1 ]]; then action="UPDATE"; n_upd=$((n_upd + 1))
    else action="INSERT"; n_new=$((n_new + 1)); fi

    if [[ $APPLY -eq 1 ]]; then
      bak="$f.bak"
      [[ -e "$bak" ]] && bak="$f.bak.$(date +%Y%m%d%H%M%S)"
      cp -p "$f" "$bak"
      cat "$TMP" > "$f"
      echo "$action   $f  (backup: $(basename "$bak"))"
    else
      echo "$action   $f"
    fi
  done < <(find "$root" \
      \( -name .git -o -name node_modules -o -name '*_premigration' \
         -o -name _test_scaffold -o -name .Trash -o -name .dropbox.cache \) -prune \
      -o -type f \( -iname AGENTS.md -o -iname CLAUDE.md -o -iname GEMINI.md \
         -o -iname instructions.md -o -iname copilot-instructions.md \
         -o -iname copilot-instructions-proposals.md -o -iname '*.instructions.md' \
         -o -iname AgentKit_instructions.md -o -iname AgentKit_overview.md \
         -o -name SKILL.md \) -print0)
done

echo ""
echo "Insert: $n_new. Update: $n_upd. Already current: $n_same. Skipped: $n_skip."
if [[ $APPLY -eq 0 && $((n_new + n_upd)) -gt 0 ]]; then
  echo "Nothing was changed. Run again with --apply to make these changes."
fi
