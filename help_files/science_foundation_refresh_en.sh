#!/bin/bash
#
# purge_jsdelivr.sh
#
# Purges the jsDelivr CDN cache for every .json file found in a configured
# SOURCE folder (not necessarily your current directory).
#
# USAGE:
#   bash purge_jsdelivr.sh <source_folder> [github_user/repo] [branch]
#
#   <source_folder>   Path to the folder containing your .json files.
#                      Can be relative or absolute. Must live somewhere
#                      under a folder named "avm_images" so the script
#                      can derive the correct repo subpath.
#
#   [github_user/repo] Optional. Defaults to mandloivishnu/avm_images
#   [branch]            Optional. Defaults to dev
#
# EXAMPLES:
#   bash purge_jsdelivr.sh /d/Papers/LatestPapers/avm_images/foundation/10/Maths/en
#   bash purge_jsdelivr.sh /d/Papers/LatestPapers/avm_images/foundation/10/Science/en mandloivishnu/avm_images main
#
#   You can also just edit DEFAULT_SOURCE_DIR below and run the script
#   with no arguments at all:
#   bash purge_jsdelivr.sh

set -e

# ---- CONFIG: edit this if you want a fixed default source folder ----
DEFAULT_SOURCE_DIR="../foundation/10/Science/en"
# -----------------------------------------------------------------------

SOURCE_DIR="${1:-$DEFAULT_SOURCE_DIR}"
REPO="${2:-mandloivishnu/avm_images}"
BRANCH="${3:-master}"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "ERROR: Source folder does not exist: $SOURCE_DIR"
  exit 1
fi

# Resolve to an absolute path so subpath extraction is reliable
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"

# Extract everything after "avm_images" in the source path
SUBPATH="${SOURCE_DIR#*avm_images}"
SUBPATH="${SUBPATH#/}"

if [ -z "$SUBPATH" ] || [ "$SUBPATH" = "$SOURCE_DIR" ]; then
  echo "ERROR: Could not detect subpath. Make sure the source folder is"
  echo "somewhere under a folder named 'avm_images'."
  echo "Source folder given: $SOURCE_DIR"
  exit 1
fi

BASE_URL="https://purge.jsdelivr.net/gh/${REPO}@${BRANCH}/${SUBPATH}"

echo "Source dir:  $SOURCE_DIR"
echo "Repo:        $REPO"
echo "Branch:      $BRANCH"
echo "Subpath:     $SUBPATH"
echo "Purge base:  $BASE_URL"
echo "----------------------------------------"

# Collect files into an array first, so we can list them and get an accurate count
files=()
while IFS= read -r -d '' file; do
  files+=("$file")
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -name "*.json" -print0)

total="${#files[@]}"

if [ "$total" -eq 0 ]; then
  echo "No .json files found in: $SOURCE_DIR"
  exit 0
fi

echo "Found $total JSON file(s):"
for f in "${files[@]}"; do
  echo "  - $(basename "$f")"
done
echo "----------------------------------------"

n=0
for f in "${files[@]}"; do
  n=$((n + 1))
  filename=$(basename "$f")
  echo "[$n/$total] Purging: $filename"
  echo "$BASE_URL/$filename"
  curl -s -X GET "$BASE_URL/$filename" -o /dev/null -w "  -> HTTP %{http_code}\n"
  sleep 0.5
done

echo "----------------------------------------"
echo "Done. Purged $n file(s)."
