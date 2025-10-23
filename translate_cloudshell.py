#!/usr/bin/env python3
"""
Simple Cloud Shell Translation Script
Run this in Google Cloud Shell after creating the service account key
"""

import json
import os
from google.cloud import translate_v2 as translate

# Set the credentials
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = os.path.expanduser('~/translate-key.json')

# Language mappings
LANGUAGES = {
    'de': 'German',
    'fr': 'French',
    'es': 'Spanish',
    'lt': 'Lithuanian',
    'el': 'Greek'
}

# Your English translations (copy from en.json)
EN_TRANSLATIONS = """
{
  "app": {
    "name": "CrowdWave",
    "title": "CrowdWave - Delivery Marketplace"
  },
  "common": {
    "yes": "Yes",
    "no": "No",
    "cancel": "Cancel",
    "confirm": "Confirm",
    "ok": "OK",
    "save": "Save",
    "delete": "Delete",
    "edit": "Edit",
    "search": "Search",
    "filter": "Filter",
    "loading": "Loading...",
    "error": "Error",
    "retry": "Retry",
    "continue": "Continue",
    "back": "Back",
    "next": "Next",
    "done": "Done",
    "close": "Close",
    "view_details": "View Details",
    "select": "Select",
    "all": "All",
    "none": "None"
  }
}
"""

def translate_text(text, target_language, client):
    """Translate a single text string"""
    if not text or not text.strip():
        return text
    
    try:
        result = client.translate(text, target_language=target_language, source_language='en')
        return result['translatedText']
    except Exception as e:
        print(f"  ⚠️  Error translating: {e}")
        return text

def translate_dict(data, target_language, client, path=""):
    """Recursively translate dictionary"""
    if isinstance(data, dict):
        result = {}
        for key, value in data.items():
            current_path = f"{path}.{key}" if path else key
            result[key] = translate_dict(value, target_language, client, current_path)
        return result
    elif isinstance(data, str):
        if data.strip() and 'CrowdWave' not in data:  # Don't translate app name
            translated = translate_text(data, target_language, client)
            if translated != data:
                print(f"  ✓ {data[:50]}... -> {translated[:50]}...")
            return translated
        return data
    else:
        return data

def main():
    print("=" * 70)
    print("  🌍 CrowdWave Auto-Translation Tool")
    print("=" * 70)
    print()
    
    # Initialize client
    print("📡 Connecting to Google Translate API...")
    client = translate.Client()
    print("✅ Connected!\n")
    
    # Load English data
    print("📖 Loading English translations...")
    en_data = json.loads(EN_TRANSLATIONS)
    print(f"✅ Loaded {len(en_data)} sections\n")
    
    # Translate each language
    for lang_code, lang_name in LANGUAGES.items():
        print("=" * 70)
        print(f"🔄 Translating to {lang_name} ({lang_code})...")
        print("=" * 70)
        
        translated = translate_dict(en_data, lang_code, client)
        
        # Save to file
        output_file = f"{lang_code}_translations.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(translated, f, ensure_ascii=False, indent=2)
        
        print(f"\n✅ {lang_name} complete! Saved to: {output_file}\n")
    
    print("=" * 70)
    print("  🎉 ALL TRANSLATIONS COMPLETE!")
    print("=" * 70)
    print("\n📁 Generated files:")
    for lang_code, lang_name in LANGUAGES.items():
        print(f"  • {lang_code}_translations.json ({lang_name})")
    print("\n💡 Copy these files to your Flutter project:")
    print("   assets/translations/")

if __name__ == "__main__":
    main()
