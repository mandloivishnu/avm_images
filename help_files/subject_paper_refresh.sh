#!/bin/bash
#
# purge_jsdelivr.sh
#
# Recursively purges the jsDelivr CDN cache for EVERY .json file found
# under a given BASE folder — no matter how many year/class/language
# subfolders exist beneath it.
#
# Example structure this handles automatically:
#   avm_images/question_data/mpbse/2026/10/en/*.json
#   avm_images/question_data/mpbse/2026/10/hi/*.json
#   avm_images/question_data/mpbse/2025/10/en/*.json
#   avm_images/question_data/mpbse/2025/12/en/*.json
#   ...and any new year/class/language folders added later, with no
#   script changes needed.
#
# USAGE:
#   bash purge_jsdelivr.sh <base_folder> [github_user/repo] [branch]
#
#   <base_folder>        Path to the folder to scan recursively for
#                         .json files (e.g. .../avm_images/question_data/mpbse).
#                         If omitted, uses DEFAULT_BASE_DIR below.
#
#   [github_user/repo]   Optional. Defaults to mandloivishnu/avm_images
#   [branch]              Optional. Defaults to master
#
# EXAMPLES:
#   bash purge_jsdelivr.sh /d/Papers/LatestPapers/avm_images/question_data/mpbse
#   bash purge_jsdelivr.sh /d/Papers/LatestPapers/avm_images/foundation
#   bash purge_jsdelivr.sh   # uses DEFAULT_BASE_DIR below

set -e

# ---- CONFIG: edit this to your usual base folder, then run with no args ----
DEFAULT_BASE_DIR="/d/Papers/LatestPapers/avm_images/question_data/mpbse"
# -----------------------------------------------------------------------------

BASE_DIR="${1:-$DEFAULT_BASE_DIR}"
REPO="${2:-mandloivishnu/avm_images}"
BRANCH="${3:-master}"

if [ ! -d "$BASE_DIR" ]; then
  echo "ERROR: Base folder does not exist: $BASE_DIR"
  exit 1
fi

# Resolve to an absolute path
BASE_DIR="$(cd "$BASE_DIR" && pwd)"

echo "Base dir:    $BASE_DIR"
echo "Repo:        $REPO"
echo "Branch:      $BRANCH"
echo "----------------------------------------"

# Recursively find every .json file under BASE_DIR
files=()
while IFS= read -r -d '' file; do
  files+=("$file")
done < <(find "$BASE_DIR" -type f -name "*.json" -print0)

total="${#files[@]}"

if [ "$total" -eq 0 ]; then
  echo "No .json files found under: $BASE_DIR"
  exit 0
fi

echo "Found $total JSON file(s) under $BASE_DIR:"
for f in "${files[@]}"; do
  echo "  - $f"
done
echo "----------------------------------------"

n=0
fail=0
for f in "${files[@]}"; do
  n=$((n + 1))

  # Derive each file's own subpath relative to "avm_images", so files
  # in different year/class/language folders all resolve correctly.
  SUBPATH="${f#*avm_images}"
  SUBPATH="${SUBPATH#/}"

  if [ -z "$SUBPATH" ] || [ "$SUBPATH" = "$f" ]; then
    echo "[$n/$total] SKIP (not under avm_images): $f"
    fail=$((fail + 1))
    continue
  fi

  url="https://purge.jsdelivr.net/gh/${REPO}@${BRANCH}/${SUBPATH}"
  echo "[$n/$total] Purging: $SUBPATH"
  curl -s -X GET "$url" -o /master/null -w "  -> HTTP %{http_code}\n"
  sleep 0.5
done

echo "----------------------------------------"
echo "Done. Purged $((n - fail)) of $total file(s). Skipped: $fail"
