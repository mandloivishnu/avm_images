import json
import os
import shutil

# Your exact folder path
ROOT_DIR = r"D:\Papers\ExamPapers\avm_images\foundation\12\Physics\hi"

updated_files = 0
updated_answers = 0
skipped_files = 0

for filename in os.listdir(ROOT_DIR):

    if not filename.endswith(".json"):
        continue

    file_path = os.path.join(ROOT_DIR, filename)

    # Skip backup files
    if filename.endswith(".bak.json"):
        continue

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # Support both JSON object and JSON array
        if isinstance(data, dict):
            questions = data.get("questions", [])
        elif isinstance(data, list):
            questions = data
        else:
            skipped_files += 1
            print(f"SKIPPED: {filename} (Invalid JSON structure)")
            continue

        if not isinstance(questions, list):
            skipped_files += 1
            print(f"SKIPPED: {filename} (Questions is not a list)")
            continue

        file_changes = 0

        for question in questions:

            if not isinstance(question, dict):
                continue

            # Process only DESCRIPTIVE questions
            if question.get("question_type") != "DESCRIPTIVE":
                continue

            # Normal parts and OR option parts
            parts_groups = [
                question.get("parts", []),
                question.get("or_option", {}).get("parts", [])
                if isinstance(question.get("or_option"), dict)
                else []
            ]

            for parts in parts_groups:

                if not isinstance(parts, list):
                    continue

                for part in parts:

                    if not isinstance(part, dict):
                        continue

                    if "correct_answer" not in part:
                        continue

                    if "explanation" not in part:
                        continue

                    new_answer = part["explanation"]

                    if part["correct_answer"] != new_answer:
                        part["correct_answer"] = new_answer
                        file_changes += 1

        if file_changes > 0:

            # Create backup before updating
            backup_path = file_path + ".bak"

            if not os.path.exists(backup_path):
                shutil.copy2(file_path, backup_path)

            temp_path = file_path + ".tmp"

            with open(temp_path, "w", encoding="utf-8") as f:
                json.dump(
                    data,
                    f,
                    ensure_ascii=False,
                    indent=2
                )
                f.write("\n")

            os.replace(temp_path, file_path)

            updated_files += 1
            updated_answers += file_changes

            print(f"UPDATED: {filename} | Answers: {file_changes}")

        else:
            print(f"NO CHANGE: {filename}")

    except Exception as e:
        print(f"ERROR: {filename} -> {e}")

print("\n===================================")
print(f"Files updated    : {updated_files}")
print(f"Answers replaced : {updated_answers}")
print(f"Files skipped    : {skipped_files}")
print("===================================")
