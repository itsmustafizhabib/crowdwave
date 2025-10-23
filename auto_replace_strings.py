#!/usr/bin/env python3
"""
Automated script to replace hardcoded English strings with .tr() calls
for internationalization using easy_localization package.

Usage:
    python auto_replace_strings.py [--dry-run] [--file=path/to/file.dart]

Options:
    --dry-run    Show what would be changed without modifying files
    --file=PATH  Process only specific file instead of all files

Safety features:
- Only replaces strings that have matching keys in en.json
- Adds necessary imports automatically
- Preserves code formatting
- No backups (use Git to undo if needed)
"""

import json
import os
import re
import sys
from pathlib import Path

def load_translation_keys():
    """Load all translation keys from en.json as a flat dictionary."""
    translation_file = Path('assets/translations/en.json')
    if not translation_file.exists():
        raise FileNotFoundError(f'Translation file not found: {translation_file}')
    
    with open(translation_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Flatten nested JSON to dot notation
    def flatten(obj, prefix=''):
        items = {}
        for key, value in obj.items():
            new_key = f'{prefix}.{key}' if prefix else key
            if isinstance(value, dict):
                items.update(flatten(value, new_key))
            elif isinstance(value, str):
                items[new_key] = value
        return items
    
    return flatten(data)

def get_dart_files():
    """Get all Dart files in lib directory, excluding generated files."""
    lib_dir = Path('lib')
    if not lib_dir.exists():
        raise FileNotFoundError('lib directory not found')
    
    dart_files = []
    for dart_file in lib_dir.rglob('*.dart'):
        if not (dart_file.name.endswith('.g.dart') or 
                dart_file.name.endswith('.freezed.dart')):
            dart_files.append(dart_file)
    
    return dart_files

def process_file(file_path, translation_keys, dry_run=False):
    """Process a single Dart file and replace hardcoded strings."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    replacements = 0
    
    # Check if file needs imports
    needs_easy_localization = "import 'package:easy_localization/easy_localization.dart'" not in content
    has_getx = "import 'package:get/get.dart'" in content
    
    # Build reverse mapping: value -> key for faster lookup
    value_to_key = {v: k for k, v in translation_keys.items()}
    
    # Find and replace hardcoded strings
    replacement_map = {}
    
    for value, key in value_to_key.items():
        # Escape special regex characters
        escaped_value = re.escape(value)
        
        # Pattern 1: Text('string') or Text("string")
        pattern1 = re.compile(
            rf"Text\s*\(\s*['\"]({escaped_value})['\"](\s*,|\s*\))",
            re.IGNORECASE
        )
        for match in pattern1.finditer(new_content):
            original = match.group(0)
            # Get the closing part (comma or closing paren) - group 2 captures this
            closing = match.group(2)
            replacement = f"Text('{key}'.tr(){closing}"
            replacement_map[original] = replacement
        
        # Pattern 2: hintText: 'string', labelText: "string", etc.
        pattern2 = re.compile(
            rf"(hintText|labelText|title|subtitle|body|message|label|text|description|name|placeholder|errorText|helperText)\s*:\s*['\"]({escaped_value})['\"]",
            re.IGNORECASE
        )
        for match in pattern2.finditer(new_content):
            original = match.group(0)
            field_name = match.group(1)
            replacement = f"{field_name}: '{key}'.tr()"
            replacement_map[original] = replacement
        
        # Pattern 3: title: Text('string')
        pattern3 = re.compile(
            rf"title\s*:\s*Text\s*\(\s*['\"]({escaped_value})['\"](\s*,|\s*\))",
            re.IGNORECASE
        )
        for match in pattern3.finditer(new_content):
            original = match.group(0)
            closing = match.group(2)
            replacement = f"title: Text('{key}'.tr(){closing}"
            replacement_map[original] = replacement
    
    # Apply replacements (avoid replacing same text multiple times)
    for original, replacement in replacement_map.items():
        if original in new_content:
            new_content = new_content.replace(original, replacement, 1)
            replacements += 1
    
    # Add imports if needed
    if replacements > 0 and needs_easy_localization:
        if has_getx:
            # Modify GetX import and add easy_localization
            new_content = new_content.replace(
                "import 'package:get/get.dart';",
                "import 'package:get/get.dart' hide Trans;\nimport 'package:easy_localization/easy_localization.dart';"
            )
        else:
            # Find first import and add after it
            import_match = re.search(r"import '[^']+';", new_content)
            if import_match:
                insert_pos = import_match.end()
                new_content = (
                    new_content[:insert_pos] +
                    "\nimport 'package:easy_localization/easy_localization.dart';" +
                    new_content[insert_pos:]
                )
    
    # Write changes if not dry run
    if not dry_run and replacements > 0:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
    
    return {
        'changed': replacements > 0,
        'replacements': replacements
    }

def main():
    # Parse arguments
    dry_run = '--dry-run' in sys.argv
    file_arg = next((arg for arg in sys.argv if arg.startswith('--file=')), None)
    
    print('🚀 String Replacement Script')
    print('━' * 60)
    print(f'Mode: {"DRY RUN (preview only)" if dry_run else "LIVE (will modify files)"}')
    print('━' * 60)
    
    # Load translation keys
    try:
        translation_keys = load_translation_keys()
        print(f'✓ Loaded {len(translation_keys)} translation keys from en.json\n')
    except Exception as e:
        print(f'❌ Error loading translation keys: {e}')
        sys.exit(1)
    
    # Get files to process
    if file_arg:
        files_to_process = [Path(file_arg.split('=', 1)[1])]
    else:
        files_to_process = get_dart_files()
    
    print(f'📁 Files to process: {len(files_to_process)}\n')
    
    total_files_changed = 0
    total_replacements = 0
    
    for file_path in files_to_process:
        try:
            result = process_file(file_path, translation_keys, dry_run)
            if result['changed']:
                total_files_changed += 1
                total_replacements += result['replacements']
                print(f"  ✓ {file_path}: {result['replacements']} replacements")
        except Exception as e:
            print(f"  ❌ {file_path}: Error - {e}")
    
    print('\n' + '━' * 60)
    print('📊 Summary:')
    print(f'   Files changed: {total_files_changed}')
    print(f'   Total replacements: {total_replacements}')
    
    if dry_run:
        print('\n⚠️  DRY RUN - No files were modified')
        print('   Run without --dry-run to apply changes')
    else:
        print('\n✅ Changes applied successfully!')
        print('   Use "git diff" to review changes')
        print('   Use "git checkout ." to undo if needed')
    print('━' * 60)

if __name__ == '__main__':
    main()
