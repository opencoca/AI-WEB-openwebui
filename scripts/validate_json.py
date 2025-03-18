import json
from pathlib import Path

def load_json_without_comments(filepath):
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            # Remove lines that start with '//' (ignoring whitespace)
            lines = [line for line in f if not line.lstrip().startswith("//")]
        content = "".join(lines)
        json.loads(content)
        return None
    except Exception as e:
        return e

def main():
    # Adjust the base path as required; here we're scanning all JSON files in i18n locales.
    base_path = Path("../src/lib/i18n/locales")
    error_found = False

    for json_file in base_path.rglob("*.json"):
        error = load_json_without_comments(json_file)
        if error:
            print(f"Error in {json_file}: {error}")
            error_found = True
        else:
            #print(f"Valid: {json_file}")
            pass

    if error_found:
        print("One or more JSON errors were found.")
        exit(1)
    else:
        print("All JSON files are valid.")

if __name__ == "__main__":
    main()