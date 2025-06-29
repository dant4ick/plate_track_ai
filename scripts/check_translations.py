import os
import re
import json

PROJECT_ROOT = '../lib'  # директория с .dart файлами
LOCALE_FILE = '../assets/translations/ru.json'  # путь к ru.json

TR_REGEXES = [
    re.compile(r"['\"]([^'\"]+)['\"]\.tr\b"),              # "key".tr
    re.compile(r"\btr\s*\(\s*['\"]([^'\"]+)['\"]\s*\)"),    # tr("key")
]

def find_dart_files(root_dir):
    dart_files = []
    for dirpath, _, filenames in os.walk(root_dir):
        for f in filenames:
            if f.endswith('.dart'):
                dart_files.append(os.path.join(dirpath, f))
    return dart_files

def extract_keys_from_dart(file_path):
    keys = set()
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        for regex in TR_REGEXES:
            matches = regex.findall(content)
            keys.update(matches)
    return keys

def collect_all_keys():
    all_keys = set()
    dart_files = find_dart_files(PROJECT_ROOT)
    for file_path in dart_files:
        keys = extract_keys_from_dart(file_path)
        all_keys.update(keys)
    return all_keys

def load_translations(locale_path):
    with open(locale_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def flatten_json(d, parent_key='', sep='.'):
    """Преобразует вложенный JSON в плоский"""
    items = {}
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.update(flatten_json(v, new_key, sep=sep))
        else:
            items[new_key] = v
    return items

def main():
    used_keys = collect_all_keys()
    translation_data = load_translations(LOCALE_FILE)
    flat_translations = flatten_json(translation_data)

    translation_keys = set(flat_translations.keys())

    missing_keys = sorted(used_keys - translation_keys)
    unused_keys = sorted(translation_keys - used_keys)

    print(f"\n=== Не переведённые ключи (используются в коде, но отсутствуют в ru.json) ===\n")
    for key in missing_keys:
        print(key)

    print(f"\n=== Лишние переводы (присутствуют в ru.json, но не используются в коде) ===\n")
    for key in unused_keys:
        print(key)

if __name__ == '__main__':
    main()
