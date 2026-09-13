#!/bin/bash
#
# foundation_refresh.sh
#
# Recursively purges the jsDelivr CDN cache for EVERY .json file found
# under a given BASE folder (e.g. the whole "foundation" tree).
#
# IMPORTANT: run with `bash foundation_refresh.sh`, not `sh foundation_refresh.sh`.
# This script uses bash-only features (arrays, process substitution).
#
# USAGE:
#   bash foundation_refresh.sh <base_folder> [github_user/repo] [branch]
#
# EXAMPLES:
#   bash foundation_refresh.sh /d/Papers/LatestPapers/avm_images/foundation
#   bash foundation_refresh.sh /d/Papers/LatestPapers/avm_images/foundation/10/Science

# NOTE: deliberately NOT using "set -e" here. With set -e, a single
# transient curl failure (timeout, DNS blip, TLS reset) on ANY one file
# would silently kill the whole script mid-run — which is exactly what
# happened last time (it stopped after file #1 with no error shown).
# Instead we check curl's result per-file and just log + continue.

# ---- CONFIG: edit this to your usual base folder, then run with no args ----
DEFAULT_BASE_DIR="/d/Papers/LatestPapers/avm_images/foundation"
# -----------------------------------------------------------------------------

BASE_DIR="${1:-$DEFAULT_BASE_DIR}"
REPO="${2:-mandloivishnu/avm_images}"
BRANCH="${3:-master}"

if [ ! -d "$BASE_DIR" ]; then
  echo "ERROR: Base folder does not exist: $BASE_DIR"
  exit 1
fi

BASE_DIR="$(cd "$BASE_DIR" && pwd)"

echo "Base dir:    $BASE_DIR"
echo "Repo:        $REPO"
echo "Branch:      $BRANCH"
echo "----------------------------------------"

files=()
while IFS= read -r -d '' file; do
  files+=("$file")
done < <(find "$BASE_DIR" -type f -name "*.json" -print0)

total="${#files[@]}"

if [ "$total" -eq 0 ]; then
  echo "No .json files found under: $BASE_DIR"
  exit 0
fi

echo "Found $total JSON file(s) under $BASE_DIR."
[Oecho "----------------------------------------"

n=0
ok=0
skipped=0
failed=0
failed_files=()

for f in "${files[@]}"; do
  n=$((n + 1))

  SUBPATH="${f#*avm_images}"
  SUBPATH="${SUBPATH#/}"

  if [ -z "$SUBPATH" ] || [ "$SUBPATH" = "$f" ]; then
    echo "[$n/$total] SKIP (not under avm_images): $f"
    skipped=$((skipped + 1))
    continue
  fi

  url="https://purge.jsdelivr.net/gh/${REPO}@${BRANCH}/${SUBPATH}"
  echo "[$n/$total] Purging: $SUBPATH"

  # --retry 2: retry twice on transient network errors
  # --max-time 15: give up on a single request after 15s instead of hanging
  # We capture the http code; if curl itself fails to connect at all,
  # http_code will be empty/000 and we log it but DO NOT exit the script.
  http_code=$(curl -s --retry 2 --max-time 15 -o /master/null -w "%{http_code}" "$url" || echo "000")

  if [ "$http_code" = "200" ]; then
    echo "  -> HTTP $http_code"
    ok=$((ok + 1))
  else
    echo "  -> HTTP $http_code (FAILED)"
    failed=$((failed + 1))
    failed_files+=("$SUBPATH (HTTP $http_code)")
  fi

  sleep 0.3
done

echo "----------------------------------------"
echo "Done. Total: $total | Success: $ok | Skipped: $skipped | Failed: $failed"

if [ "$failed" -gt 0 ]; then
  echo "----------------------------------------"
  echo "Failed files:"
  for ff in "${failed_files[@]}"; do
    echo "  - $ff"
  done
  echo ""
  echo "You can re-run this same script — it's safe to repeat, jsDelivr purge is idempotent."
fi
