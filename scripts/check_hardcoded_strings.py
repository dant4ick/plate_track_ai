import os
import re

PROJECT_ROOT = '../lib'  # путь к директории с dart-кодом

STRING_LITERAL_REGEX = re.compile(r'''(?<![a-zA-Z0-9_])(['"])(?:(?=(\\?))\2.)*?\1''')
IGNORE_PATTERNS = [
    re.compile(r'\.tr\b'),
    re.compile(r'\btr\s*\('),
    re.compile(r'\b(Text|print|debugPrint|Logger|Exception|assert)\s*\('),
    re.compile(r'^\s*//'),  # однострочные комментарии
    re.compile(r'^\s*\*'),  # внутри многострочных
    re.compile(r'^\s*/\*'), # начало многострочных
    re.compile(r'.*\*/'),   # конец многострочных
    re.compile(r'import\s+'),
    re.compile(r'\b(Route|PageRoute|MaterialPageRoute)\b'),
    re.compile(r'\b(test|group|expect)\b'),  # исключаем тесты
]

def find_dart_files(root_dir):
    dart_files = []
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('.dart'):
                dart_files.append(os.path.join(dirpath, filename))
    return dart_files

def is_ignored(line):
    return any(p.search(line) for p in IGNORE_PATTERNS)

def extract_hardcoded_strings(file_path):
    results = []
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        for i, line in enumerate(lines):
            if is_ignored(line):
                continue
            literals = STRING_LITERAL_REGEX.findall(line)
            for match in literals:
                full_string = match[0]  # кавычка
                string_text = re.search(r'''(['"])(.*?)\1''', line)
                if string_text:
                    value = string_text.group(2)
                    if value.strip() and not is_localization_usage(line, value):
                        results.append((file_path, i + 1, value.strip()))
    return results

def is_localization_usage(line, string_value):
    # Проверяем, используется ли строка как локализация
    if '.tr' in line or 'tr(' in line:
        return True
    return False

def main():
    dart_files = find_dart_files(PROJECT_ROOT)
    hardcoded_strings = []

    for file in dart_files:
        hardcoded_strings.extend(extract_hardcoded_strings(file))

    print(f"Найдено {len(hardcoded_strings)} возможных хардкод-строк:\n")
    for file, line_number, string in hardcoded_strings:
        print(f"{file}:{line_number} → \"{string}\"")

if __name__ == '__main__':
    main()
