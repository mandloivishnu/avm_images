find . -type f -name "*.json" -print0 | while IFS= read -r -d '' file; do
    if jq -e '
        any(.questions[]?;
            .question_type == "DESCRIPTIVE"
        )
    ' "$file" > /dev/null 2>&1; then

        jq '
          (.questions[] 
           | select(.question_type == "DESCRIPTIVE")
           | (.parts[]?, .or_option.parts[]?)
          ) |= (
              if has("explanation") and has("correct_answer")
              then .correct_answer = .explanation
              else .
              end
          )
        ' "$file" > "${file}.tmp" && {
            cp "$file" "${file}.bak"
            mv "${file}.tmp" "$file"
            echo "Updated: $file"
        } || {
            rm -f "${file}.tmp"
            echo "Failed: $file"
        }
    fi
done

echo "All JSON files processed!"
