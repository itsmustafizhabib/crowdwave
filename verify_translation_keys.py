#!/usr/bin/env python3
"""
Verify that all .tr() calls in Dart files have corresponding keys in en.json
"""

import json
import re
from pathlib import Path
from collections import defaultdict

def load_translation_keys():
    """Load all translation keys from en.json."""
    translation_file = Path('assets/translations/en.json')
    if not translation_file.exists():
        raise FileNotFoundError(f'Translation file not found: {translation_file}')
    
    with open(translation_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
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

def find_tr_calls_in_file(file_path):
    """Find all .tr() calls in a Dart file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to match .tr() calls: 'key'.tr() or "key".tr()
    pattern = r"['\"]([a-z_][a-z0-9_]*(?:\.[a-z_][a-z0-9_]*)*)['\"]\.tr\(\)"
    
    matches = re.finditer(pattern, content, re.IGNORECASE)
    keys_found = []
    
    for match in matches:
        key = match.group(1)
        line_num = content[:match.start()].count('\n') + 1
        keys_found.append({'key': key, 'line': line_num})
    
    return keys_found

def main():
    print('🔍 Verifying Translation Keys')
    print('=' * 80)
    
    # Load en.json keys
    try:
        translation_keys = load_translation_keys()
        print(f'✓ Loaded {len(translation_keys)} keys from en.json\n')
    except Exception as e:
        print(f'❌ Error loading en.json: {e}')
        return
    
    # Find all Dart files
    lib_dir = Path('lib')
    if not lib_dir.exists():
        print('❌ lib directory not found')
        return
    
    dart_files = [f for f in lib_dir.rglob('*.dart') 
                  if not (f.name.endswith('.g.dart') or f.name.endswith('.freezed.dart'))]
    
    print(f'📁 Scanning {len(dart_files)} Dart files...\n')
    
    all_tr_calls = {}
    total_tr_calls = 0
    
    for file_path in dart_files:
        try:
            tr_calls = find_tr_calls_in_file(file_path)
            if tr_calls:
                all_tr_calls[file_path] = tr_calls
                total_tr_calls += len(tr_calls)
        except Exception as e:
            print(f'  ⚠️  Error reading {file_path}: {e}')
    
    print(f'📊 Found {total_tr_calls} .tr() calls in {len(all_tr_calls)} files\n')
    
    # Check which keys are missing
    missing_keys = defaultdict(list)
    existing_keys_count = 0
    
    for file_path, tr_calls in all_tr_calls.items():
        for call in tr_calls:
            key = call['key']
            if key in translation_keys:
                existing_keys_count += 1
            else:
                missing_keys[key].append({
                    'file': file_path,
                    'line': call['line']
                })
    
    print('=' * 80)
    print('📋 VERIFICATION RESULTS')
    print('=' * 80)
    print(f'✅ Keys found in en.json: {existing_keys_count}')
    print(f'❌ Keys missing from en.json: {len(missing_keys)}')
    print('=' * 80)
    
    if missing_keys:
        print('\n⚠️  MISSING KEYS DETAILS:\n')
        
        for i, (key, occurrences) in enumerate(sorted(missing_keys.items()), 1):
            print(f'{i}. Key: "{key}"')
            print(f'   Used in {len(occurrences)} location(s):')
            for occ in occurrences[:3]:
                rel_path = occ['file'].relative_to(lib_dir)
                print(f'     - {rel_path}:{occ["line"]}')
            if len(occurrences) > 3:
                print(f'     ... and {len(occurrences) - 3} more')
            print()
        
        print('=' * 80)
        print('⚠️  ACTION REQUIRED: Add missing keys to en.json')
        print('=' * 80)
    else:
        print('\n🎉 SUCCESS! All .tr() keys are present in en.json')
        print('✅ Your project is ready for translation to other languages!')
        print('\n📝 Next Steps:')
        print('   1. Use en.json as the base for translations')
        print('   2. Create translation files for other European languages')
        print('   3. Include Georgian (ka.json) - it\'s not in standard European languages')
        print('\n🌍 European Languages to Support:')
        european_langs = [
            'de (German)', 'fr (French)', 'es (Spanish)', 'it (Italian)',
            'pt (Portuguese)', 'nl (Dutch)', 'pl (Polish)', 'cs (Czech)',
            'ro (Romanian)', 'el (Greek)', 'sv (Swedish)', 'da (Danish)',
            'fi (Finnish)', 'no (Norwegian)', 'hu (Hungarian)', 'bg (Bulgarian)',
            'sk (Slovak)', 'hr (Croatian)', 'sl (Slovenian)', 'et (Estonian)',
            'lv (Latvian)', 'lt (Lithuanian)', 'mt (Maltese)', 'ga (Irish)',
            'cy (Welsh)', 'is (Icelandic)', 'sq (Albanian)', 'mk (Macedonian)',
            'sr (Serbian)', 'ka (Georgian)'
        ]
        print('   ' + ', '.join(european_langs))
    
    print('\n' + '=' * 80)
    print(f'📊 SUMMARY:')
    print(f'   Total .tr() calls: {total_tr_calls}')
    print(f'   Unique keys used: {existing_keys_count + len(missing_keys)}')
    print(f'   Keys in en.json: {len(translation_keys)}')
    print(f'   Missing keys: {len(missing_keys)}')
    print('=' * 80)

if __name__ == '__main__':
    main()
