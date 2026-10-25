import json
import os
import sys

# Get target directory from command-line argument, default to current directory '.'
base_dir = sys.argv[1] if len(sys.argv) > 1 else "."

if not os.path.exists(base_dir):
    print(f"Error: Directory '{base_dir}' does not exist.")
    sys.exit(1)


def find_match_columns(obj, filepath):
    """Recursively search for MATCH_COLUMN question_type in dicts or lists."""
    if isinstance(obj, dict):
        if obj.get("question_type") == "MATCH_COLUMN":
            print(f"\n--- Found in: {filepath} ---")
            print(json.dumps(obj, ensure_ascii=False, indent=2))
        for value in obj.values():
            find_match_columns(value, filepath)
    elif isinstance(obj, list):
        for item in obj:
            find_match_columns(item, filepath)


print(f"Searching for MATCH_COLUMN questions in: '{base_dir}'...")

# Walk through the specified directory
for root, _, files in os.walk(base_dir):
    for file in files:
        if file.endswith(".json"):
            filepath = os.path.join(root, file)
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    find_match_columns(data, filepath)
            except Exception as e:
                # Skip unreadable/corrupted JSON files silently or log error
                pass

