#!/bin/bash

BASE_URL="https://purge.jsdelivr.net/gh/mandloivishnu/avm_images@dev/foundation/12/Physics/hi"

FILES=(
  "electric_current.json"
  "magnetism_and_matter.json"
  "alternating_current.json"
  "electromagnetic_waves.json"
  "ray_optics.json"
  "wave_optics.json"
  "dual_nature_of_radiation.json"
  "atoms.json"
  "nuclei.json"
  "semiconductor_electronics.json"
)

for file in "${FILES[@]}"; do
    echo ""
    echo "========================================"
    echo "Purging: $file"
    echo "========================================"

    API_URL="${BASE_URL}/${file}"

    curl -sS "$API_URL"

    echo ""
    echo "Completed: $file"
done

echo ""
echo "========================================"
echo "All CDN purge requests completed!"
echo "========================================"
