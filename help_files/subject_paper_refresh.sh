#!/bin/bash
#
# purge_jsdelivr.sh
#
# Recursively purges jsDelivr cache for EVERY .json file
# under the given BASE folder.
#
# USAGE:
#   bash purge_jsdelivr.sh <base_folder> [github_user/repo] [branch]
#
# Example:
#   bash purge_jsdelivr.sh /d/Papers/LatestPapers/avm_images/question_data/mpbse
#
# Defaults:
#   BASE_DIR = ../question_data/mpbse
#   REPO     = mandloivishnu/avm_images
#   BRANCH   = master

set +e

# --------------------------------------------------
# CONFIG
# --------------------------------------------------

DEFAULT_BASE_DIR="../question_data/mpbse"

BASE_DIR="${1:-$DEFAULT_BASE_DIR}"
REPO="${2:-mandloivishnu/avm_images}"
BRANCH="${3:-master}"

# --------------------------------------------------
# VALIDATE BASE DIRECTORY
# --------------------------------------------------

if [ ! -d "$BASE_DIR" ]; then
    echo "ERROR: Base folder does not exist:"
    echo "$BASE_DIR"
    exit 1
fi

# Convert to absolute path
BASE_DIR="$(cd "$BASE_DIR" && pwd)"

echo
echo "=============================================="
echo " jsDelivr JSON Cache Purge"
echo "=============================================="
echo "Base dir : $BASE_DIR"
echo "Repo     : $REPO"
echo "Branch   : $BRANCH"
echo "=============================================="
echo

# --------------------------------------------------
# FIND AVM_IMAGES ROOT
# --------------------------------------------------

if [[ "$BASE_DIR" != *"/avm_images"* ]]; then
    echo "ERROR: Base directory must be inside 'avm_images'."
    echo
    echo "Example:"
    echo "/d/Papers/LatestPapers/avm_images/question_data/mpbse"
    exit 1
fi

# Extract path before /avm_images
AVM_ROOT="${BASE_DIR%%/avm_images*}/avm_images"

echo "Repository root:"
echo "$AVM_ROOT"
echo

# --------------------------------------------------
# FIND ALL JSON FILES
# --------------------------------------------------

echo "Scanning for JSON files..."
echo

mapfile -d '' files < <(
    find "$BASE_DIR" -type f -iname "*.json" -print0
)

TOTAL=${#files[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "No JSON files found."
    exit 0
fi

echo "Found $TOTAL JSON file(s)"
echo "----------------------------------------------"

# --------------------------------------------------
# DISPLAY FILES
# --------------------------------------------------

COUNT=0

for file in "${files[@]}"; do
    COUNT=$((COUNT + 1))

    RELATIVE_PATH="${file#"$AVM_ROOT"/}"

    echo "$COUNT. $RELATIVE_PATH"
done

echo "----------------------------------------------"
echo

# --------------------------------------------------
# PURGE EACH FILE
# --------------------------------------------------

SUCCESS=0
FAILED=0
COUNT=0

for file in "${files[@]}"; do

    COUNT=$((COUNT + 1))

    # Remove avm_images root from path
    SUBPATH="${file#"$AVM_ROOT"/}"

    URL="https://purge.jsdelivr.net/gh/${REPO}@${BRANCH}/${SUBPATH}"

    echo
    echo "[$COUNT/$TOTAL]"
    echo "File : $SUBPATH"
    echo "URL  : $URL"

    # Call jsDelivr purge API
    HTTP_CODE=$(curl \
        -s \
        -o /master/null \
        -w "%{http_code}" \
        -X GET \
        "$URL"
    )

    if [ "$HTTP_CODE" = "200" ]; then

        echo "Status: SUCCESS (HTTP $HTTP_CODE)"
        SUCCESS=$((SUCCESS + 1))

    else

        echo "Status: FAILED (HTTP $HTTP_CODE)"
        FAILED=$((FAILED + 1))

    fi

    # Small delay to avoid hitting API too aggressively
    sleep 0.5

done

# --------------------------------------------------
# SUMMARY
# --------------------------------------------------

echo
echo
echo "=============================================="
echo " PURGE COMPLETED"
echo "=============================================="
echo "Total files : $TOTAL"
echo "Successful  : $SUCCESS"
echo "Failed      : $FAILED"
echo "=============================================="
