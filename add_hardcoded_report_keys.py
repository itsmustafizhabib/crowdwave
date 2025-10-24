#!/usr/bin/env python3
"""
Script to add translation keys from HARDCODED_STRINGS_REPORT.md to all language JSON files.
This script extracts all the recommended translation keys from the report and adds them to 
all translation files with proper structure.
"""

import json
import os
from pathlib import Path
from typing import Dict, Any

# Define the new translation keys to add based on the report
NEW_KEYS = {
    "error": {
        "title": "Error",
        "generic": "Error: {0}",
        "network": "Network error: {0}"
    },
    "moderation": {
        "report_failed": "Failed to report content: {0}",
        "review_status": "Review {0}",
        "update_status_failed": "Failed to update status: {0}"
    },
    "comments": {
        "add_failed": "Failed to add comment: {0}",
        "like_failed": "Failed to like comment: {0}",
        "unlike_failed": "Failed to unlike comment: {0}",
        "report_failed": "Failed to report comment: {0}"
    },
    "calls": {
        "voice_failed": "Voice call failed: {0}",
        "video_failed": "Video call failed: {0}",
        "accept_failed": "Failed to accept call: {0}"
    },
    "matching": {
        "request_sent": "Match request sent to {0}!",
        "no_package_selected": "No package selected for matching",
        "no_package_request": "No package request provided",
        "load_suggestions_failed": "Failed to load suggestions: {0}",
        "find_matches_failed": "Failed to find matches: {0}"
    },
    "chat": {
        "start_failed": "Failed to start chat: {0}"
    },
    "profile": {
        "photo_remove_failed": "Failed to remove photo: {0}"
    },
    "image": {
        "pick_failed": "Failed to pick image: {0}"
    },
    "location": {
        "get_current_failed": "Failed to get current location: {0}",
        "select_failed": "Error selecting location: {0}",
        "send_current": "Send Current Location",
        "send_current_description": "Share your current location once",
        "share_live": "Share Live Location",
        "share_live_description": "Share your location for 15 minutes"
    },
    "permissions": {
        "location_required": "Location Permission Required"
    },
    "auth": {
        "logout_failed": "Error logging out: {0}"
    },
    "payment": {
        "init_failed": "Failed to initialize payment service: {0}"
    },
    "offer": {
        "submitted": "Submitted"
    },
    "tracking": {
        "updated": "Updated"
    },
    "contact": {
        "title": "Contact",
        "opening_chat": "Opening chat with {0}"
    },
    "details": {
        "title": "Details",
        "viewing": "Viewing details for {0}"
    },
    "validation": {
        "invalid_price": "Please enter a valid price"
    }
}

def deep_merge(base: Dict[str, Any], updates: Dict[str, Any]) -> Dict[str, Any]:
    """
    Deep merge two dictionaries. Updates overwrites base where keys conflict.
    """
    result = base.copy()
    for key, value in updates.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result

def add_keys_to_json_file(file_path: Path, new_keys: Dict[str, Any]) -> bool:
    """
    Add new translation keys to a JSON file.
    Returns True if changes were made, False otherwise.
    """
    try:
        # Read existing data
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Store original for comparison
        original_data = json.dumps(data, sort_keys=True)
        
        # Merge new keys
        data = deep_merge(data, new_keys)
        
        # Check if anything changed
        new_data = json.dumps(data, sort_keys=True)
        if original_data == new_data:
            return False
        
        # Write back with proper formatting
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write('\n')  # Add trailing newline
        
        return True
    
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def get_translation_files() -> list:
    """
    Get all JSON translation files from assets/translations directory.
    """
    translations_dir = Path('assets/translations')
    if not translations_dir.exists():
        raise FileNotFoundError(f"Translations directory not found: {translations_dir}")
    
    json_files = list(translations_dir.glob('*.json'))
    if not json_files:
        raise FileNotFoundError(f"No JSON files found in {translations_dir}")
    
    return sorted(json_files)

def main():
    """
    Main function to add translation keys to all language files.
    """
    print("=" * 70)
    print("Adding Translation Keys from HARDCODED_STRINGS_REPORT.md")
    print("=" * 70)
    print()
    
    # Get all translation files
    try:
        translation_files = get_translation_files()
        print(f"Found {len(translation_files)} translation files:\n")
    except FileNotFoundError as e:
        print(f"Error: {e}")
        return 1
    
    # Process each file
    updated_files = []
    skipped_files = []
    
    for file_path in translation_files:
        lang_code = file_path.stem
        print(f"Processing {lang_code}.json...", end=" ")
        
        # For English, use the actual English strings
        keys_to_add = NEW_KEYS.copy()
        
        # For other languages, mark them as needing translation
        if lang_code != 'en':
            # We'll add the English keys but they'll need translation later
            # This is acceptable as it provides a fallback
            pass
        
        if add_keys_to_json_file(file_path, keys_to_add):
            updated_files.append(lang_code)
            print("✓ Updated")
        else:
            skipped_files.append(lang_code)
            print("⊘ Already exists")
    
    # Summary
    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Total files processed: {len(translation_files)}")
    print(f"Files updated: {len(updated_files)}")
    print(f"Files skipped (keys already exist): {len(skipped_files)}")
    print()
    
    if updated_files:
        print("✓ Updated files:")
        for lang in updated_files:
            print(f"  - {lang}.json")
        print()
    
    if skipped_files:
        print("⊘ Skipped files (keys already present):")
        for lang in skipped_files:
            print(f"  - {lang}.json")
        print()
    
    print("=" * 70)
    print("NEXT STEPS")
    print("=" * 70)
    print("1. Review the English (en.json) translations to ensure they're correct")
    print("2. Run your translation script to translate all new keys to other languages")
    print("3. Update the Dart files to use .tr() for all hardcoded strings")
    print("4. Test the application to ensure all translations work correctly")
    print()
    print("Translation keys added:")
    print("  - error.title, error.generic, error.network")
    print("  - moderation.* (3 keys)")
    print("  - comments.* (4 keys)")
    print("  - calls.* (3 keys)")
    print("  - matching.* (5 keys)")
    print("  - chat.start_failed")
    print("  - profile.photo_remove_failed")
    print("  - image.pick_failed")
    print("  - location.* (6 keys)")
    print("  - permissions.location_required")
    print("  - auth.logout_failed")
    print("  - payment.init_failed")
    print("  - offer.submitted")
    print("  - tracking.updated")
    print("  - contact.* (2 keys)")
    print("  - details.* (2 keys)")
    print("  - validation.invalid_price")
    print()
    print("Total new keys: 36 translation strings")
    print("=" * 70)
    
    return 0

if __name__ == '__main__':
    exit(main())
