#!/usr/bin/env python3
"""
Fix malformed .tr() calls with extra quotes.
Fixes patterns like .tr()') and .tr()' to just .tr()
"""

import os
import re
from pathlib import Path

def fix_malformed_tr_in_file(file_path):
    """Fix malformed .tr() calls in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = 0
        
        # Pattern 1: .tr()') - extra closing quote and paren
        pattern1 = re.compile(r"\.tr\(\)'\)", re.MULTILINE)
        matches1 = pattern1.findall(content)
        if matches1:
            content = pattern1.sub(".tr()", content)
            changes_made += len(matches1)
        
        # Pattern 2: .tr()' - extra closing quote
        pattern2 = re.compile(r"\.tr\(\)'(?![,)])", re.MULTILINE)
        matches2 = pattern2.findall(content)
        if matches2:
            content = pattern2.sub(".tr()", content)
            changes_made += len(matches2)
        
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
    print("\nFixing malformed .tr() calls...\n")
    
    total_changes = 0
    files_modified = 0
    
    for file_path in dart_files:
        changes = fix_malformed_tr_in_file(file_path)
        if changes > 0:
            files_modified += 1
            total_changes += changes
            rel_path = os.path.relpath(file_path, script_dir)
            print(f"✓ {rel_path}: {changes} fix(es)")
    
    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  Files modified: {files_modified}")
    print(f"  Total fixes: {total_changes}")
    print(f"{'='*60}")
    
    if files_modified > 0:
        print("\n✓ All malformed .tr() calls have been fixed!")
    else:
        print("\n✓ No malformed .tr() calls found!")

if __name__ == '__main__':
    main()
