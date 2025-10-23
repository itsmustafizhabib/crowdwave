#!/usr/bin/env python3
"""
Add ALL missing translation keys to en.json in one go
"""

import json
import re
from pathlib import Path

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
    
    return flatten(data), data

def find_hardcoded_strings_in_file(file_path):
    """Find hardcoded strings in a single Dart file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    strings_found = []
    
    patterns = [
        (r"Text\s*\(\s*'([A-Z][a-zA-Z\s,!?.]{2,})'\s*[,)]", 1),
        (r'Text\s*\(\s*"([A-Z][a-zA-Z\s,!?.]{2,})"\s*[,)]', 1),
        (r"(hintText|labelText|title|subtitle|errorText|helperText|message|description|body|text|label|name|placeholder)\s*:\s*'([A-Z][a-zA-Z\s,!?.]{2,})'", 2),
        (r'(hintText|labelText|title|subtitle|errorText|helperText|message|description|body|text|label|name|placeholder)\s*:\s*"([A-Z][a-zA-Z\s,!?.]{2,})"', 2),
    ]
    
    for pattern, group_idx in patterns:
        matches = re.finditer(pattern, content)
        for match in matches:
            string_text = match.group(group_idx).strip()
            
            # Skip if already has .tr()
            context_start = max(0, match.start() - 5)
            context_end = min(len(content), match.end() + 25)
            context = content[context_start:context_end]
            
            if '.tr()' in context or len(string_text) < 3:
                continue
            
            strings_found.append(string_text)
    
    return strings_found

def suggest_translation_key(text, existing_keys):
    """Suggest a translation key based on the text."""
    key = text.lower()
    key = re.sub(r'[^a-z0-9\s]', '', key)
    key = re.sub(r'\s+', '_', key)
    key = key[:50]
    
    # Categorize
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
    
    base_key = f'{prefix}.{key}'
    suggested_key = base_key
    counter = 1
    
    while suggested_key in existing_keys:
        suggested_key = f'{base_key}_{counter}'
        counter += 1
    
    return suggested_key

def main():
    print('🚀 Adding ALL Missing Translation Keys')
    print('=' * 80)
    
    flat_keys, nested_data = load_translation_keys()
    print(f'✓ Loaded {len(flat_keys)} existing keys\n')
    
    lib_dir = Path('lib')
    dart_files = [f for f in lib_dir.rglob('*.dart') 
                  if not (f.name.endswith('.g.dart') or f.name.endswith('.freezed.dart'))]
    
    print(f'📁 Scanning {len(dart_files)} files...\n')
    
    all_strings = []
    for file_path in dart_files:
        try:
            strings = find_hardcoded_strings_in_file(file_path)
            all_strings.extend(strings)
        except:
            pass
    
    # Find unique missing strings
    value_to_key = {v: k for k, v in flat_keys.items()}
    unique_missing = set()
    
    for text in all_strings:
        if text not in value_to_key:
            unique_missing.add(text)
    
    print(f'📊 Total hardcoded strings: {len(all_strings)}')
    print(f'📊 Unique missing strings: {len(unique_missing)}')
    print()
    
    if not unique_missing:
        print('🎉 No missing keys! All strings are covered.')
        return
    
    # Add ALL missing keys
    new_keys_to_add = {}
    for text in unique_missing:
        suggested_key = suggest_translation_key(text, {**flat_keys, **new_keys_to_add})
        new_keys_to_add[suggested_key] = text
    
    print(f'➕ Adding {len(new_keys_to_add)} new keys to en.json...\n')
    
    # Add to nested structure
    for key, value in new_keys_to_add.items():
        parts = key.split('.')
        current = nested_data
        
        for part in parts[:-1]:
            if part not in current:
                current[part] = {}
            current = current[part]
        
        current[parts[-1]] = value
    
    # Write back
    translation_file = Path('assets/translations/en.json')
    with open(translation_file, 'w', encoding='utf-8') as f:
        json.dump(nested_data, f, indent=2, ensure_ascii=False)
    
    print(f'✅ Successfully added {len(new_keys_to_add)} keys!')
    print(f'✅ Total keys now: {len(flat_keys) + len(new_keys_to_add)}')
    print()
    print('=' * 80)
    print('🎯 Next Step: Run auto_replace_strings.py to apply replacements')
    print('=' * 80)

if __name__ == '__main__':
    main()
