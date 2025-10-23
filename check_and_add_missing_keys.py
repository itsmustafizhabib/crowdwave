#!/usr/bin/env python3
"""
Comprehensive script to:
1. Find all hardcoded strings in Dart files
2. Check which ones are missing from en.json
3. Add missing keys to en.json with proper structure
4. Verify the auto_replace script will work
"""

import json
import re
from pathlib import Path
from collections import defaultdict

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
    
    return flatten(data), data

def find_hardcoded_strings_in_file(file_path):
    """Find hardcoded strings in a single Dart file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    strings_found = []
    
    # More comprehensive patterns
    patterns = [
        # Text widget with string
        (r"Text\s*\(\s*'([A-Z][a-zA-Z\s,!?.]{2,})'\s*[,)]", 1),
        (r'Text\s*\(\s*"([A-Z][a-zA-Z\s,!?.]{2,})"\s*[,)]', 1),
        
        # Named parameters with strings
        (r"(hintText|labelText|title|subtitle|errorText|helperText|message|description|body|text|label|name|placeholder)\s*:\s*'([A-Z][a-zA-Z\s,!?.]{2,})'", 2),
        (r'(hintText|labelText|title|subtitle|errorText|helperText|message|description|body|text|label|name|placeholder)\s*:\s*"([A-Z][a-zA-Z\s,!?.]{2,})"', 2),
    ]
    
    for pattern, group_idx in patterns:
        matches = re.finditer(pattern, content)
        for match in matches:
            string_text = match.group(group_idx)
            
            # Skip if already has .tr()
            full_match = match.group(0)
            context_start = max(0, match.start() - 5)
            context_end = min(len(content), match.end() + 25)
            context = content[context_start:context_end]
            
            if '.tr()' in context:
                continue
            
            # Clean up the string
            string_text = string_text.strip()
            
            # Skip very short or likely false positives
            if len(string_text) < 3:
                continue
            
            strings_found.append({
                'text': string_text,
                'file': file_path,
                'line': content[:match.start()].count('\n') + 1
            })
    
    return strings_found

def suggest_translation_key(text, existing_keys):
    """Suggest a translation key based on the text."""
    # Convert to snake_case-like format
    key = text.lower()
    key = re.sub(r'[^a-z0-9\s]', '', key)  # Remove special chars
    key = re.sub(r'\s+', '_', key)  # Replace spaces with underscores
    key = key[:50]  # Limit length
    
    # Try to categorize based on common patterns
    if any(word in text.lower() for word in ['error', 'failed', 'invalid']):
        prefix = 'error_messages'
    elif any(word in text.lower() for word in ['success', 'complete', 'confirmed']):
        prefix = 'common'
    elif 'package' in text.lower():
        prefix = 'post_package'
    elif 'trip' in text.lower() or 'travel' in text.lower():
        prefix = 'travel'
    elif 'payment' in text.lower() or 'wallet' in text.lower():
        prefix = 'wallet'
    elif 'login' in text.lower() or 'sign' in text.lower() or 'password' in text.lower():
        prefix = 'auth'
    elif 'kyc' in text.lower() or 'verification' in text.lower():
        prefix = 'kyc'
    elif 'profile' in text.lower() or 'account' in text.lower():
        prefix = 'profile'
    elif 'notification' in text.lower():
        prefix = 'notifications'
    elif 'chat' in text.lower() or 'message' in text.lower():
        prefix = 'chat'
    elif 'review' in text.lower() or 'rating' in text.lower():
        prefix = 'reviews'
    elif 'track' in text.lower() or 'delivery' in text.lower():
        prefix = 'tracking'
    elif 'order' in text.lower() or 'booking' in text.lower():
        prefix = 'booking'
    else:
        prefix = 'common'
    
    # Make sure key is unique
    base_key = f'{prefix}.{key}'
    suggested_key = base_key
    counter = 1
    
    while suggested_key in existing_keys:
        suggested_key = f'{base_key}_{counter}'
        counter += 1
    
    return suggested_key

def main():
    print('🔍 Comprehensive Translation Key Check')
    print('=' * 80)
    
    # Load existing translation keys
    try:
        flat_keys, nested_data = load_translation_keys()
        print(f'✓ Loaded {len(flat_keys)} existing translation keys from en.json\n')
    except Exception as e:
        print(f'❌ Error loading translation keys: {e}')
        return
    
    # Find all hardcoded strings
    lib_dir = Path('lib')
    if not lib_dir.exists():
        print('❌ lib directory not found')
        return
    
    dart_files = [f for f in lib_dir.rglob('*.dart') 
                  if not (f.name.endswith('.g.dart') or f.name.endswith('.freezed.dart'))]
    
    print(f'📁 Scanning {len(dart_files)} Dart files...\n')
    
    all_hardcoded_strings = []
    
    for file_path in dart_files:
        try:
            strings = find_hardcoded_strings_in_file(file_path)
            all_hardcoded_strings.extend(strings)
        except Exception as e:
            print(f'  ⚠️  Error reading {file_path}: {e}')
    
    print(f'\n📊 Found {len(all_hardcoded_strings)} hardcoded strings total\n')
    
    # Check which strings are missing
    value_to_key = {v: k for k, v in flat_keys.items()}
    
    missing_strings = []
    existing_strings = []
    
    for string_info in all_hardcoded_strings:
        text = string_info['text']
        if text in value_to_key:
            existing_strings.append(string_info)
        else:
            missing_strings.append(string_info)
    
    print('=' * 80)
    print(f'✅ Strings with existing keys: {len(existing_strings)}')
    print(f'❌ Strings missing from en.json: {len(missing_strings)}')
    print('=' * 80)
    
    if missing_strings:
        print('\n📝 Missing Strings Details:\n')
        
        # Group by unique text
        unique_missing = {}
        for s in missing_strings:
            text = s['text']
            if text not in unique_missing:
                unique_missing[text] = []
            unique_missing[text].append(s)
        
        print(f'Unique missing strings: {len(unique_missing)}\n')
        
        # Show first 30 with suggested keys
        new_keys_to_add = {}
        
        for i, (text, occurrences) in enumerate(list(unique_missing.items())[:30], 1):
            suggested_key = suggest_translation_key(text, flat_keys)
            new_keys_to_add[suggested_key] = text
            
            print(f'{i}. "{text}"')
            print(f'   Suggested key: {suggested_key}')
            print(f'   Found in {len(occurrences)} file(s):')
            for occ in occurrences[:3]:
                rel_path = occ['file'].relative_to(lib_dir)
                print(f'     - {rel_path}:{occ["line"]}')
            if len(occurrences) > 3:
                print(f'     ... and {len(occurrences) - 3} more')
            print()
        
        if len(unique_missing) > 30:
            print(f'... and {len(unique_missing) - 30} more unique strings\n')
        
        # Ask if user wants to add missing keys
        print('=' * 80)
        print('💡 Suggestion: Add missing keys to en.json?')
        print('=' * 80)
        print(f'\nThis will add {len(new_keys_to_add)} new translation keys to en.json')
        print('The script will organize them into appropriate sections.')
        print('\nWould you like to proceed? (yes/no): ', end='')
        
        response = input().strip().lower()
        
        if response in ['yes', 'y']:
            # Add keys to nested_data
            for key, value in new_keys_to_add.items():
                parts = key.split('.')
                current = nested_data
                
                for part in parts[:-1]:
                    if part not in current:
                        current[part] = {}
                    current = current[part]
                
                current[parts[-1]] = value
            
            # Write back to file
            translation_file = Path('assets/translations/en.json')
            with open(translation_file, 'w', encoding='utf-8') as f:
                json.dump(nested_data, f, indent=2, ensure_ascii=False)
            
            print(f'\n✅ Added {len(new_keys_to_add)} new keys to en.json')
            print('✅ File updated successfully!')
        else:
            print('\n⏭️  Skipped adding new keys')
    else:
        print('\n🎉 Great! All hardcoded strings have corresponding keys in en.json')
        print('✅ The auto_replace script should work perfectly!\n')
    
    print('\n' + '=' * 80)
    print('📋 Summary:')
    print(f'   Total hardcoded strings: {len(all_hardcoded_strings)}')
    print(f'   Strings with keys: {len(existing_strings)}')
    print(f'   Missing keys: {len(missing_strings)}')
    print('=' * 80)
    
    if len(existing_strings) > 0:
        print('\n✅ Ready to run auto_replace_strings.py')
    else:
        print('\n⚠️  Add missing keys first, then run auto_replace_strings.py')

if __name__ == '__main__':
    main()
