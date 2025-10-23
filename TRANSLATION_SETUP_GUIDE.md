# 🌍 CrowdWave Translation Setup Guide

## Overview
This guide will help you translate the CrowdWave app to 30 European languages using Google Cloud Translation API.

## Languages Included
The script will create translations for:
- **Western Europe**: German, French, Spanish, Italian, Portuguese, Dutch
- **Central Europe**: Polish, Czech, Slovak, Hungarian
- **Southern Europe**: Romanian, Greek, Bulgarian, Croatian, Slovenian, Albanian, Serbian, Macedonian
- **Northern Europe**: Swedish, Danish, Finnish, Norwegian, Icelandic
- **Baltic States**: Estonian, Latvian, Lithuanian
- **Other**: Maltese, Irish, Welsh
- **Caucasus**: Georgian (ka)

Total: **30 languages**

## Prerequisites

### 1. Python Installation
- **Windows**: Download from https://www.python.org/ (Python 3.7+)
- **Mac/Linux**: Usually pre-installed, or use `brew install python3`

### 2. Google Cloud Setup

#### Step 1: Create/Access Google Cloud Project
1. Go to https://console.cloud.google.com
2. Create a new project or select existing one
3. Note your Project ID

#### Step 2: Enable Translation API
1. In Google Cloud Console, go to **APIs & Services** → **Library**
2. Search for "Cloud Translation API"
3. Click on "Cloud Translation API"
4. Click **Enable**

#### Step 3: Enable Billing
⚠️ **IMPORTANT**: Translation API requires billing to be enabled
1. Go to **Billing** in Google Cloud Console
2. Link a billing account to your project
3. Check pricing: https://cloud.google.com/translate/pricing
   - First 500,000 characters/month: **FREE**
   - After that: ~$20 per 1 million characters

**Estimated Cost for CrowdWave**:
- ~1,343 translation keys × 30 languages = ~40,000 translations
- Average 30 characters per string = ~1.2 million characters
- **Estimated cost**: $10-25 (may be free if under monthly limit)

#### Step 4: Create Service Account
1. Go to **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Name it: `crowdwave-translator`
4. Click **Create and Continue**
5. Grant role: **Cloud Translation API User**
6. Click **Continue** → **Done**

#### Step 5: Download Service Account Key
1. Find your service account in the list
2. Click on it
3. Go to **Keys** tab
4. Click **Add Key** → **Create new key**
5. Choose **JSON** format
6. Click **Create**
7. Save the downloaded JSON file

#### Step 6: Place the Key File
**Option 1** (Recommended):
- Rename the file to `service_account.json`
- Place it in: `assets/service_account.json`

**Option 2**:
- Place it anywhere on your computer
- Set environment variable:
  - **Windows**: `set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\key.json`
  - **Mac/Linux**: `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json`

### 3. Install Required Libraries

Open terminal/command prompt in project folder:

```bash
# Install Google Cloud Translate library
pip install google-cloud-translate

# Or if using pip3
pip3 install google-cloud-translate
```

## Running the Translation

### Windows
Double-click `run_translation.bat` or run in command prompt:
```cmd
run_translation.bat
```

### Mac/Linux
Run in terminal:
```bash
chmod +x run_translation.sh
./run_translation.sh
```

### Manual Python Execution
```bash
python translate_all_languages.py
```

## What Happens During Translation

1. **Verification**: Checks Python, dependencies, and credentials
2. **Loading**: Reads `assets/translations/en.json`
3. **Translation**: Translates to each of the 30 languages
4. **Saving**: Creates files like `de.json`, `fr.json`, etc.
5. **Summary**: Shows completion status

### Expected Output
```
🌍 CrowdWave Comprehensive Translation Tool
✅ Connected to Google Translate API
✅ Loaded 1,343 strings from en.json

[1/30] 🔄 Translating to German (de)...
  ✓ Translated 50 strings...
  ✓ Translated 100 strings...
✅ German complete!

[2/30] 🔄 Translating to French (fr)...
...

✅ Successfully translated: 30/30 languages
🎉 TRANSLATION PROCESS COMPLETE!
```

## Generated Files

After completion, you'll have:
```
assets/translations/
  ├── en.json  (original)
  ├── de.json  (German)
  ├── fr.json  (French)
  ├── es.json  (Spanish)
  ├── it.json  (Italian)
  ├── pt.json  (Portuguese)
  ├── nl.json  (Dutch)
  ├── pl.json  (Polish)
  ├── cs.json  (Czech)
  ├── sk.json  (Slovak)
  ├── hu.json  (Hungarian)
  ├── ro.json  (Romanian)
  ├── el.json  (Greek)
  ├── bg.json  (Bulgarian)
  ├── hr.json  (Croatian)
  ├── sl.json  (Slovenian)
  ├── sq.json  (Albanian)
  ├── sr.json  (Serbian)
  ├── mk.json  (Macedonian)
  ├── sv.json  (Swedish)
  ├── da.json  (Danish)
  ├── fi.json  (Finnish)
  ├── no.json  (Norwegian)
  ├── is.json  (Icelandic)
  ├── et.json  (Estonian)
  ├── lv.json  (Latvian)
  ├── lt.json  (Lithuanian)
  ├── mt.json  (Maltese)
  ├── ga.json  (Irish)
  ├── cy.json  (Welsh)
  └── ka.json  (Georgian)
```

## Troubleshooting

### Error: "google-cloud-translate not installed"
**Solution**: Install the library
```bash
pip install google-cloud-translate
```

### Error: "GOOGLE_APPLICATION_CREDENTIALS not set"
**Solution**: Place your service account key file:
- As `assets/service_account.json`, or
- Set the environment variable

### Error: "Translation API has not been used"
**Solution**: 
1. Go to Google Cloud Console
2. Enable "Cloud Translation API"
3. Wait 2-3 minutes for it to activate

### Error: "Permission denied" / "Unauthorized"
**Solution**:
1. Make sure your service account has "Cloud Translation API User" role
2. Re-download the service account key
3. Make sure billing is enabled

### Error: "Quota exceeded"
**Solution**:
1. Check your quotas in Google Cloud Console
2. Request quota increase if needed
3. Wait until the next billing cycle

## Verification After Translation

1. **Check Files**: Verify all 30 JSON files were created
2. **Check Content**: Open a few files to verify translations look correct
3. **Test in App**: 
   - Run the app
   - Change language in settings
   - Verify UI displays correctly

## Cost Monitoring

Monitor your usage:
1. Go to **Google Cloud Console**
2. Navigate to **Billing** → **Reports**
3. Filter by "Cloud Translation API"
4. Check current month's usage

## Next Steps

After successful translation:

1. **Review Translations**: Check a few key strings for accuracy
2. **Update supported_locales.dart**: Add any new language codes if needed
3. **Test the App**: Switch between languages and verify UI
4. **Commit to Git**: 
   ```bash
   git add assets/translations/*.json
   git commit -m "Add translations for 30 European languages"
   git push
   ```

## Important Notes

- ⚠️ **Never commit** `service_account.json` to Git (it's in .gitignore)
- 🔄 **Re-running**: You can re-run the script anytime to update translations
- 💰 **Cost**: Monitor Google Cloud billing to avoid surprises
- 🌍 **Quality**: Auto-translations may need manual review for context
- 📝 **Brand Terms**: "CrowdWave" and similar terms are preserved (not translated)

## Support

If you encounter issues:
1. Check this guide thoroughly
2. Verify Google Cloud setup
3. Check Google Cloud Console for API errors
4. Review the error messages from the script

## Security Reminder

🔒 **Keep your service account key secure!**
- Don't share it
- Don't commit it to Git
- Don't upload it to public repositories
- Revoke and recreate if compromised

---

**Ready to translate?** Run `run_translation.bat` (Windows) or `./run_translation.sh` (Mac/Linux)!
