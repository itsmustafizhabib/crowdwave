#!/usr/bin/env python3
"""
Fix const Text() with .tr() errors in Flutter files.
Removes 'const' keyword before Text() widgets that use .tr() method.
"""

import os
import re
from pathlib import Path

def fix_const_tr_in_file(file_path):
    """Fix const Text() with .tr() in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = 0
        
        # Pattern 1: const Text('key'.tr()) - with any whitespace/formatting
        # This pattern handles cases like:
        # - const Text('key'.tr())
        # - const Text('key'.tr(),
        # - const Text('key'.tr()'),
        pattern1 = re.compile(r'\bconst\s+Text\s*\(\s*[\'"]([^\'"]+)[\'"]\s*\.tr\(\)', re.MULTILINE)
        matches1 = list(pattern1.finditer(content))
        
        for match in reversed(matches1):  # Reverse to maintain positions
            # Replace 'const Text(' with just 'Text('
            old_text = match.group(0)
            new_text = old_text.replace('const ', '')
            
            start, end = match.span()
            content = content[:start] + new_text + content[end:]
            changes_made += 1
        
        # Pattern 2: Handle cases with line breaks
        # const Text('key'.tr(),
        #   style: ...
        # )
        pattern2 = re.compile(r'\bconst\s+Text\s*\(\s*[\'"]([^\'"]+)[\'"]\s*\.tr\(\)\s*,', re.MULTILINE | re.DOTALL)
        matches2 = list(pattern2.finditer(content))
        
        for match in reversed(matches2):
            old_text = match.group(0)
            new_text = old_text.replace('const ', '')
            
            start, end = match.span()
            content = content[:start] + new_text + content[end:]
            changes_made += 1
        
        # Pattern 3: const SnackBar/AlertDialog/etc. containing Text().tr()
        # Find const widgets that have .tr() anywhere in their content
        # This is a more comprehensive check
        pattern3 = re.compile(
            r'\bconst\s+(SnackBar|AlertDialog|SimpleDialog|Dialog|ListTile|Card|Container|Column|Row|Padding)\s*\([^)]*\.tr\(\)',
            re.MULTILINE | re.DOTALL
        )
        
        # For complex widgets, we need to find the matching parentheses
        # Simpler approach: look for const Widget( ... .tr() ... )
        lines = content.split('\n')
        for i, line in enumerate(lines):
            # Check if line has const Widget( and contains .tr() in next few lines
            if re.search(r'\bconst\s+(SnackBar|AlertDialog|SimpleDialog|Dialog)\s*\(', line):
                # Check next 20 lines for .tr()
                check_range = min(i + 20, len(lines))
                has_tr = any('.tr()' in lines[j] for j in range(i, check_range))
                if has_tr:
                    lines[i] = re.sub(r'\bconst\s+', '', lines[i])
                    changes_made += 1
        
        content = '\n'.join(lines)
        
        # Only write if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return changes_made
        
        return 0
        
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return 0

def find_dart_files(directory):
    """Find all .dart files in directory and subdirectories."""
    dart_files = []
    for root, dirs, files in os.walk(directory):
        # Skip build directories and hidden directories
        dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'build']
        
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    return dart_files

def main():
    """Main function to fix all Dart files."""
    # Get the Flutter project directory (parent of this script)
    script_dir = Path(__file__).parent
    lib_dir = script_dir / 'lib'
    
    if not lib_dir.exists():
        print(f"Error: 'lib' directory not found at {lib_dir}")
        return
    
    print(f"Searching for Dart files in: {lib_dir}")
    dart_files = find_dart_files(str(lib_dir))
    
    print(f"Found {len(dart_files)} Dart files")
    print("\nFixing const Text() with .tr() errors...\n")
    
    total_changes = 0
    files_modified = 0
    
    for file_path in dart_files:
        changes = fix_const_tr_in_file(file_path)
        if changes > 0:
            files_modified += 1
            total_changes += changes
            rel_path = os.path.relpath(file_path, script_dir)
            print(f"[OK] {rel_path}: {changes} fix(es)")
    
    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  Files modified: {files_modified}")
    print(f"  Total fixes: {total_changes}")
    print(f"{'='*60}")
    
    if files_modified > 0:
        print("\n[SUCCESS] All const Text().tr() errors have been fixed!")
        print("  The 'const' keyword has been removed from Text() widgets using .tr()")
    else:
        print("\n[OK] No const Text().tr() errors found!")

if __name__ == '__main__':
    main()
