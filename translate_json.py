#!/usr/bin/env python3
"""
Auto-translate JSON translation files using Google Cloud Translate API
Usage: python translate_json.py
"""

import json
import os
from google.cloud import translate_v2 as translate

# Language mappings
LANGUAGES = {
    'de': 'German',
    'fr': 'French',
    'es': 'Spanish',
    'lt': 'Lithuanian',
    'el': 'Greek'
}

def translate_text(text, target_language, translate_client):
    """Translate text to target language"""
    if not text or text.strip() == "":
        return text
    
    try:
        result = translate_client.translate(
            text,
            target_language=target_language,
            source_language='en'
        )
        return result['translatedText']
    except Exception as e:
        print(f"Error translating '{text}' to {target_language}: {e}")
        return text

def translate_dict(data, target_language, translate_client, path=""):
    """Recursively translate all string values in a dictionary"""
    if isinstance(data, dict):
        result = {}
        for key, value in data.items():
            current_path = f"{path}.{key}" if path else key
            print(f"Translating: {current_path}")
            result[key] = translate_dict(value, target_language, translate_client, current_path)
        return result
    elif isinstance(data, str):
        # Skip if string contains only special characters or is a placeholder
        if data.strip() and not data.startswith('{') and not data.endswith('}'):
            translated = translate_text(data, target_language, translate_client)
            print(f"  '{data}' -> '{translated}'")
            return translated
        return data
    else:
        return data

def main():
    # Initialize Translate client
    print("Initializing Google Cloud Translate API...")
    translate_client = translate.Client()
    
    # Get the assets/translations directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    translations_dir = os.path.join(script_dir, 'assets', 'translations')
    
    # Read English JSON
    en_file = os.path.join(translations_dir, 'en.json')
    print(f"\nReading English translations from: {en_file}")
    
    with open(en_file, 'r', encoding='utf-8') as f:
        en_data = json.load(f)
    
    print(f"Found {len(en_data)} top-level keys to translate\n")
    
    # Translate to each language
    for lang_code, lang_name in LANGUAGES.items():
        print(f"\n{'='*60}")
        print(f"Translating to {lang_name} ({lang_code})...")
        print(f"{'='*60}\n")
        
        # Translate the entire structure
        translated_data = translate_dict(en_data, lang_code, translate_client)
        
        # Save to file
        output_file = os.path.join(translations_dir, f'{lang_code}.json')
        print(f"\nSaving to: {output_file}")
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(translated_data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ {lang_name} translation complete!")
    
    print(f"\n{'='*60}")
    print("🎉 ALL TRANSLATIONS COMPLETE!")
    print(f"{'='*60}")
    print("\nTranslated files:")
    for lang_code, lang_name in LANGUAGES.items():
        print(f"  ✅ {lang_name}: assets/translations/{lang_code}.json")

if __name__ == "__main__":
    main()
