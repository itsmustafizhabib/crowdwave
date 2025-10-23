# Translation Workflow: Cloud Shell → Local Flutter Project

## Overview
We'll use Google Cloud Shell to generate translations, then download them to your local Flutter project.

---

## Step 1: Upload en.json to Cloud Shell

In your Cloud Shell terminal, run:

```bash
# Create a working directory
mkdir -p ~/translation_work
cd ~/translation_work
```

Then click **Upload File** button in Cloud Shell (three dots menu → Upload) and upload:
- `C:\Users\ghani\Desktop\Projects\Courier-CrowdWave\Flutterrr\assets\translations\en.json`

---

## Step 2: Create the Translation Script

In Cloud Shell, create the script:

```bash
cat > translate_all.py << 'ENDSCRIPT'
import os
import json
from google.cloud import translate_v2 as translate

# Set credentials
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = os.path.expanduser('~/translate-key.json')

# Initialize client
client = translate.Client()

# Target languages
TARGET_LANGUAGES = {
    'de': 'German',
    'fr': 'French', 
    'es': 'Spanish',
    'lt': 'Lithuanian',
    'el': 'Greek'
}

def translate_dict(data, target_lang):
    """Recursively translate all string values in a dictionary"""
    if isinstance(data, dict):
        result = {}
        for key, value in data.items():
            result[key] = translate_dict(value, target_lang)
        return result
    elif isinstance(data, str):
        try:
            translation = client.translate(value, target_language=target_lang)
            return translation['translatedText']
        except Exception as e:
            print(f"Error translating '{value[:50]}...': {e}")
            return value
    else:
        return data

# Load English JSON
print("📖 Loading en.json...")
with open('en.json', 'r', encoding='utf-8') as f:
    english_data = json.load(f)

# Translate to each language
for lang_code, lang_name in TARGET_LANGUAGES.items():
    print(f"\n🌍 Translating to {lang_name} ({lang_code})...")
    translated_data = translate_dict(english_data, lang_code)
    
    output_file = f'{lang_code}.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(translated_data, f, ensure_ascii=False, indent=2)
    
    print(f"✅ Created {output_file}")

print("\n🎉 All translations complete!")
print("\n📦 Files created:")
for lang_code in TARGET_LANGUAGES.keys():
    print(f"   - {lang_code}.json")

print("\n📥 Next: Download these files to your local project!")
ENDSCRIPT
```

---

## Step 3: Run the Translation

```bash
python3 translate_all.py
```

This will create 5 files:
- `de.json` (German)
- `fr.json` (French)
- `es.json` (Spanish)
- `lt.json` (Lithuanian)
- `el.json` (Greek)

**Estimated time: 2-3 minutes**

---

## Step 4: Download Files to Local Project

In Cloud Shell, click the **three dots menu → Download** and download each file:
- `de.json`
- `fr.json`
- `es.json`
- `lt.json`
- `el.json`

Then move them to your local folder:
```
C:\Users\ghani\Desktop\Projects\Courier-CrowdWave\Flutterrr\assets\translations\
```

**Replace the existing files** (backup first if needed).

---

## Step 5: Test in Your Local Flutter App

```bash
cd C:\Users\ghani\Desktop\Projects\Courier-CrowdWave\Flutterrr
flutter run
```

Change language in the app and verify translations appear!

---

## Quick Test Before Full Translation

Test the API first with this one-liner in Cloud Shell:

```bash
python3 << 'ENDPYTHON'
import os
from google.cloud import translate_v2 as translate
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = os.path.expanduser('~/translate-key.json')
client = translate.Client()
result = client.translate('Hello World', target_language='de')
print(f"✅ API Works! English: 'Hello World' → German: '{result['translatedText']}'")
ENDPYTHON
```

If you see `✅ API Works! ... → German: 'Hallo Welt'` then proceed to full translation!

---

## Summary

| Where | What Happens |
|-------|--------------|
| **Cloud Shell** | Generate translations using Google Translate API |
| **Download** | Transfer JSON files from Cloud to your computer |
| **Local Project** | Copy JSON files to `assets/translations/` folder |
| **Flutter App** | Automatically reads the new translations |

**No code changes needed in your Flutter app** - just replace the JSON files! 🚀
