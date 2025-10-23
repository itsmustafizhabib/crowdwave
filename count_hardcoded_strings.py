#!/usr/bin/env python3
"""
Simple script to count hardcoded strings in Dart files.
Does NOT modify any files - just counts.
"""

import re
from pathlib import Path

def count_hardcoded_strings_in_file(file_path):
    """Count hardcoded strings in a single Dart file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Skip if already has .tr() calls (likely already translated)
    # But still count any remaining hardcoded strings
    
    # Pattern to find hardcoded strings (simple version)
    # Matches strings like 'Some Text', "Some Text" but excludes:
    # - Import statements
    # - Already translated strings with .tr()
    # - Single characters
    # - Numbers
    
    patterns = [
        # Text widget with string
        r"Text\s*\(\s*'([A-Z][a-zA-Z\s,!?.]{3,})'\s*[,)]",
        r'Text\s*\(\s*"([A-Z][a-zA-Z\s,!?.]{3,})"\s*[,)]',
        # Named parameters with strings
        r"(hintText|labelText|title|subtitle|errorText|helperText|message|description)\s*:\s*'([A-Z][a-zA-Z\s,!?.]{3,})'",
        r'(hintText|labelText|title|subtitle|errorText|helperText|message|description)\s*:\s*"([A-Z][a-zA-Z\s,!?.]{3,})"',
    ]
    
    strings_found = []
    for pattern in patterns:
        matches = re.finditer(pattern, content)
        for match in matches:
            # Get the actual string part
            if len(match.groups()) > 1:
                string_text = match.group(2)
            else:
                string_text = match.group(1)
            
            # Skip if already has .tr()
            full_match = match.group(0)
            if '.tr()' in content[match.start():match.end()+20]:
                continue
                
            strings_found.append(string_text)
    
    return strings_found

def main():
    print('🔍 Counting Hardcoded Strings')
    print('━' * 60)
    
    lib_dir = Path('lib')
    if not lib_dir.exists():
        print('❌ lib directory not found')
        return
    
    total_strings = 0
    files_with_strings = []
    
    dart_files = [f for f in lib_dir.rglob('*.dart') 
                  if not (f.name.endswith('.g.dart') or f.name.endswith('.freezed.dart'))]
    
    print(f'📁 Scanning {len(dart_files)} Dart files...\n')
    
    for file_path in dart_files:
        try:
            strings = count_hardcoded_strings_in_file(file_path)
            if strings:
                count = len(strings)
                total_strings += count
                files_with_strings.append((file_path, count, strings[:5]))  # Store first 5 examples
        except Exception as e:
            print(f'  ⚠️  Error reading {file_path}: {e}')
    
    print('━' * 60)
    print('📊 SUMMARY:')
    print(f'   Total hardcoded strings: {total_strings}')
    print(f'   Files with hardcoded strings: {len(files_with_strings)}')
    print('━' * 60)
    
    if files_with_strings:
        print('\n📝 Top 20 files by string count:')
        files_with_strings.sort(key=lambda x: x[1], reverse=True)
        for file_path, count, examples in files_with_strings[:20]:
            rel_path = file_path.relative_to(lib_dir)
            print(f'\n  📄 {rel_path} - {count} strings')
            if examples:
                print(f'     Examples: {examples[0][:50]}...')
    
    print('\n' + '━' * 60)

if __name__ == '__main__':
    main()
