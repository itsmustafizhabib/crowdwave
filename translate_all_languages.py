#!/usr/bin/env python3
"""
Comprehensive Auto-Translation Script for CrowdWave
Translates en.json to 30 European languages using Google Cloud Translate API

Prerequisites:
1. Google Cloud account with Translation API enabled
2. Service account key JSON file (place in project root)
3. Set GOOGLE_APPLICATION_CREDENTIALS environment variable

Usage:
    python translate_all_languages.py

This will create 30 translation files in assets/translations/
"""

import json
import os
import sys
from pathlib import Path

try:
    from google.cloud import translate_v2 as translate
except ImportError:
    print("❌ Error: google-cloud-translate not installed")
    print("Install it with: pip install google-cloud-translate")
    sys.exit(1)

# All 30 European languages (including Georgian)
LANGUAGES = {
    # Western Europe
    'de': 'German',
    'fr': 'French',
    'es': 'Spanish',
    'it': 'Italian',
    'pt': 'Portuguese',
    'nl': 'Dutch',
    
    # Central Europe
    'pl': 'Polish',
    'cs': 'Czech',
    'sk': 'Slovak',
    'hu': 'Hungarian',
    
    # Southern Europe
    'ro': 'Romanian',
    'el': 'Greek',
    'bg': 'Bulgarian',
    'hr': 'Croatian',
    'sl': 'Slovenian',
    'sq': 'Albanian',
    'sr': 'Serbian',
    'mk': 'Macedonian',
    
    # Northern Europe
    'sv': 'Swedish',
    'da': 'Danish',
    'fi': 'Finnish',
    'no': 'Norwegian',
    'is': 'Icelandic',
    
    # Baltic States
    'et': 'Estonian',
    'lv': 'Latvian',
    'lt': 'Lithuanian',
    
    # Other European
    'mt': 'Maltese',
    'ga': 'Irish',
    'cy': 'Welsh',
    
    # Caucasus (Georgia is geographically in Europe/Asia border)
    'ka': 'Georgian'
}

# Special handling for app name and brand terms (don't translate)
PRESERVE_TERMS = [
    'CrowdWave',
    'CrowdWave.Fatal',
    'LoggingService',
]

def should_translate(text):
    """Check if text should be translated"""
    if not text or not text.strip():
        return False
    
    # Don't translate if it contains only special characters
    if all(c in '{}<>[](),:;!?.\'"@#$%^&*-_=+|\\/' for c in text.strip()):
        return False
    
    # Don't translate preserved terms
    for term in PRESERVE_TERMS:
        if term.lower() in text.lower():
            return False
    
    # Don't translate placeholders like {error}, {count}, etc.
    if text.startswith('{') and text.endswith('}'):
        return False
    
    return True

def translate_text(text, target_language, client):
    """Translate a single text string"""
    if not should_translate(text):
        return text
    
    try:
        result = client.translate(
            text,
            target_language=target_language,
            source_language='en'
        )
        
        translated = result['translatedText']
        
        # Restore preserved terms if they got translated
        for term in PRESERVE_TERMS:
            if term in text and term not in translated:
                translated = translated.replace(term.lower(), term)
        
        return translated
    except Exception as e:
        print(f"  ⚠️  Error translating '{text[:50]}...': {e}")
        return text

def translate_dict(data, target_language, client, path="", stats=None):
    """Recursively translate dictionary"""
    if stats is None:
        stats = {'translated': 0, 'skipped': 0}
    
    if isinstance(data, dict):
        result = {}
        for key, value in data.items():
            current_path = f"{path}.{key}" if path else key
            result[key] = translate_dict(value, target_language, client, current_path, stats)
        return result
    elif isinstance(data, str):
        if should_translate(data):
            translated = translate_text(data, target_language, client)
            if translated != data:
                stats['translated'] += 1
                # Show progress for every 50 translations
                if stats['translated'] % 50 == 0:
                    print(f"  ✓ Translated {stats['translated']} strings...")
            else:
                stats['skipped'] += 1
            return translated
        else:
            stats['skipped'] += 1
            return data
    else:
        return data

def load_english_translations():
    """Load the English translation file"""
    script_dir = Path(__file__).parent
    en_file = script_dir / 'assets' / 'translations' / 'en.json'
    
    if not en_file.exists():
        print(f"❌ Error: English translation file not found at {en_file}")
        sys.exit(1)
    
    with open(en_file, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_translation(data, lang_code):
    """Save translated data to file"""
    script_dir = Path(__file__).parent
    translations_dir = script_dir / 'assets' / 'translations'
    translations_dir.mkdir(parents=True, exist_ok=True)
    
    output_file = translations_dir / f'{lang_code}.json'
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    return output_file

def verify_credentials():
    """Verify Google Cloud credentials are set"""
    cred_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
    
    if not cred_path:
        print("❌ Error: GOOGLE_APPLICATION_CREDENTIALS environment variable not set")
        print("\nPlease set it to your service account key file:")
        print("  Windows: set GOOGLE_APPLICATION_CREDENTIALS=path\\to\\key.json")
        print("  Linux/Mac: export GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json")
        return False
    
    if not os.path.exists(cred_path):
        print(f"❌ Error: Credentials file not found at: {cred_path}")
        return False
    
    print(f"✅ Using credentials: {cred_path}")
    return True

def main():
    print("=" * 80)
    print("  🌍 CrowdWave Comprehensive Translation Tool")
    print("  30 European Languages + Georgian")
    print("=" * 80)
    print()
    
    # Verify credentials
    print("🔐 Verifying Google Cloud credentials...")
    if not verify_credentials():
        sys.exit(1)
    print()
    
    # Initialize client
    print("📡 Connecting to Google Translate API...")
    try:
        client = translate.Client()
        print("✅ Connected successfully!\n")
    except Exception as e:
        print(f"❌ Failed to connect: {e}")
        print("\nMake sure:")
        print("  1. Translation API is enabled in your Google Cloud project")
        print("  2. Service account has Translation API permissions")
        print("  3. Billing is enabled on your Google Cloud project")
        sys.exit(1)
    
    # Load English translations
    print("📖 Loading English translations...")
    en_data = load_english_translations()
    
    # Count total strings
    def count_strings(obj):
        if isinstance(obj, dict):
            return sum(count_strings(v) for v in obj.values())
        elif isinstance(obj, str):
            return 1
        return 0
    
    total_strings = count_strings(en_data)
    print(f"✅ Loaded {total_strings} strings from en.json\n")
    
    # Ask for confirmation
    print(f"⚠️  This will translate to {len(LANGUAGES)} languages")
    print(f"   Estimated API calls: {total_strings * len(LANGUAGES):,}")
    print("\nLanguages to be created:")
    for code, name in sorted(LANGUAGES.items()):
        print(f"  • {code}.json - {name}")
    
    response = input("\n❓ Continue with translation? (yes/no): ").strip().lower()
    if response not in ['yes', 'y']:
        print("❌ Translation cancelled")
        sys.exit(0)
    
    print("\n" + "=" * 80)
    print("🚀 Starting translation process...")
    print("=" * 80 + "\n")
    
    # Translate each language
    completed = []
    failed = []
    skipped = []
    
    for i, (lang_code, lang_name) in enumerate(LANGUAGES.items(), 1):
        print(f"\n[{i}/{len(LANGUAGES)}] 🔄 Translating to {lang_name} ({lang_code})...")
        print("-" * 80)
        
        # Check if file already exists
        script_dir = Path(__file__).parent
        output_file = script_dir / 'assets' / 'translations' / f'{lang_code}.json'
        if output_file.exists():
            response = input(f"  ⚠️  {lang_code}.json already exists. Overwrite? (yes/no): ").strip().lower()
            if response not in ['yes', 'y']:
                print(f"  ⏭️  Skipped {lang_name}")
                skipped.append(lang_name)
                continue
        
        try:
            stats = {'translated': 0, 'skipped': 0}
            translated_data = translate_dict(en_data, lang_code, client, stats=stats)
            
            # Save to file
            output_file = save_translation(translated_data, lang_code)
            
            print(f"\n✅ {lang_name} complete!")
            print(f"   Translated: {stats['translated']} strings")
            print(f"   Preserved: {stats['skipped']} strings")
            print(f"   Saved to: {output_file}")
            
            completed.append(lang_name)
            
        except Exception as e:
            print(f"\n❌ {lang_name} failed: {e}")
            failed.append(lang_name)
    
    # Final summary
    print("\n" + "=" * 80)
    print("📊 TRANSLATION SUMMARY")
    print("=" * 80)
    print(f"\n✅ Successfully translated: {len(completed)}/{len(LANGUAGES)} languages")
    if skipped:
        print(f"⏭️  Skipped (already exist): {len(skipped)} languages")
    
    if completed:
        print("\n✓ Completed languages:")
        for lang in completed:
            print(f"  • {lang}")
    
    if skipped:
        print("\n⏭️  Skipped languages:")
        for lang in skipped:
            print(f"  • {lang}")
    
    if failed:
        print(f"\n❌ Failed languages: {len(failed)}")
        for lang in failed:
            print(f"  • {lang}")
    
    print("\n" + "=" * 80)
    print("🎉 TRANSLATION PROCESS COMPLETE!")
    print("=" * 80)
    print(f"\n📁 Translation files location:")
    print(f"   assets/translations/")
    print(f"\n💡 Next steps:")
    print(f"   1. Review the generated translation files")
    print(f"   2. Update supported_locales.dart if needed")
    print(f"   3. Test the app with different languages")
    print(f"   4. Commit the translation files to your repository")
    print()

if __name__ == "__main__":
    main()
