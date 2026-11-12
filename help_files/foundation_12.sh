
#!/bin/bash

# Resolve avm_images root directory from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

BASE_URL="https://purge.jsdelivr.net/gh/mandloivishnu/avm_images@master/foundation"

FOLDERS=(
  "12/Maths/hi"
  "12/Physics/hi"
  "12/Chemistry/hi"
)

TOTAL=0
SUCCESS=0
FAILED=0

for folder in "${FOLDERS[@]}"; do

    echo ""
    echo "========================================"
    echo "Processing: $folder"
    echo "========================================"

    LOCAL_DIR="$PROJECT_ROOT/foundation/$folder"
    API_URL="$BASE_URL/$folder"

    if [[ ! -d "$LOCAL_DIR" ]]; then
        echo "Directory not found: $LOCAL_DIR"
        continue
    fi

    while IFS= read -r -d '' file; do

        filename=$(basename "$file")
        TOTAL=$((TOTAL + 1))

        echo "Purging: $filename"

        HTTP_CODE=$(curl -s -X GET "$API_URL/$filename" \
            -o /master/null \
            -w "%{http_code}")

        if [[ "$HTTP_CODE" == "200" ]]; then
            SUCCESS=$((SUCCESS + 1))
            echo "  → HTTP $HTTP_CODE SUCCESS"
        else
            FAILED=$((FAILED + 1))
            echo "  → HTTP $HTTP_CODE FAILED"
        fi

        sleep 0.5

    done < <(find "$LOCAL_DIR" -maxdepth 1 -type f -name "*.json" -print0)

done

echo ""
echo "========================================"
echo "PURGE SUMMARY"
echo "========================================"
echo "Total Files : $TOTAL"
echo "Successful  : $SUCCESS"
echo "Failed      : $FAILED"
echo "========================================"
