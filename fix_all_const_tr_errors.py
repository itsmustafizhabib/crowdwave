#!/usr/bin/env python3
"""
Comprehensive fix for const widgets with .tr() errors in Flutter code.
Removes 'const' keyword from ANY widget that contains .tr() since .tr() is not a compile-time constant.
"""

import os
import re
from pathlib import Path

def has_tr_in_scope(content, start_pos, end_pos):
    """Check if .tr() exists within a specific scope"""
    scope = content[start_pos:end_pos]
    return '.tr()' in scope

def find_matching_paren(content, start_pos):
    """Find the matching closing parenthesis for an opening parenthesis"""
    count = 1
    pos = start_pos + 1
    while pos < len(content) and count > 0:
        if content[pos] == '(':
            count += 1
        elif content[pos] == ')':
            count -= 1
        pos += 1
    return pos if count == 0 else -1

def fix_const_widgets_with_tr(file_path):
    """Remove const from any widget that contains .tr() in its scope"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = 0
        
        # Pattern to find const Widget(
        pattern = re.compile(r'\bconst\s+(\w+)\s*\(')
        
        # Find all const widgets
        matches = list(pattern.finditer(content))
        
        # Process from end to start to maintain positions
        for match in reversed(matches):
            widget_name = match.group(1)
            const_start = match.start()
            paren_start = match.end() - 1
            
            # Find matching closing parenthesis
            paren_end = find_matching_paren(content, paren_start)
            
            if paren_end == -1:
                continue
            
            # Check if this widget scope contains .tr()
            if has_tr_in_scope(content, paren_start, paren_end):
                # Remove the 'const ' keyword
                const_keyword_match = re.match(r'(\s*)const\s+', content[const_start:match.end()])
                if const_keyword_match:
                    # Replace 'const ' with nothing, keeping the whitespace
                    whitespace = const_keyword_match.group(1)
                    new_text = whitespace + widget_name + ' ('
                    content = content[:const_start] + new_text + content[match.end():]
                    changes_made += 1
        
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
    script_dir = Path(__file__).parent
    lib_dir = script_dir / 'lib'
    
    if not lib_dir.exists():
        print(f"Error: 'lib' directory not found at {lib_dir}")
        return
    
    print(f"Searching for Dart files in: {lib_dir}")
    dart_files = find_dart_files(str(lib_dir))
    
    print(f"Found {len(dart_files)} Dart files")
    print("\nFixing const widgets with .tr() errors...\n")
    
    total_changes = 0
    files_modified = 0
    
    for file_path in dart_files:
        changes = fix_const_widgets_with_tr(file_path)
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
        print("\n[SUCCESS] All const widget .tr() errors have been fixed!")
        print("  The 'const' keyword has been removed from widgets containing .tr()")
    else:
        print("\n[OK] No const widget .tr() errors found!")

if __name__ == '__main__':
    main()
