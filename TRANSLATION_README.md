# 🌍 Auto-Translation Setup for CrowdWave

This directory contains scripts to automatically translate your app using Google Cloud Translate API.

## 🚀 Quick Start (2 minutes)

### Option 1: Google Cloud Shell (RECOMMENDED - You're already here!)

```bash
# 1. Enable the API (run once)
gcloud services enable translate.googleapis.com

# 2. Make script executable
chmod +x auto_translate.sh

# 3. Run the translation
./auto_translate.sh
```

That's it! All your translations will be generated automatically.

---

### Option 2: Local Machine with Python

```bash
# 1. Install Google Cloud SDK if not already installed
# Visit: https://cloud.google.com/sdk/docs/install

# 2. Authenticate
gcloud auth application-default login

# 3. Install Python package
pip install google-cloud-translate

# 4. Run translation
python translate_json.py
```

---

### Option 3: Local Machine with Node.js

```bash
# 1. Install Google Cloud SDK if not already installed
# Visit: https://cloud.google.com/sdk/docs/install

# 2. Authenticate
gcloud auth application-default login

# 3. Install Node package
npm install @google-cloud/translate

# 4. Run translation
node translate_json.js
```

---

### Option 4: Windows (Double-click method)

1. Open Google Cloud Shell or install gcloud CLI
2. Run: `gcloud auth application-default login`
3. Double-click `auto_translate.bat`
4. Done!

---

## 📁 What Gets Translated

The script will:
- Read `assets/translations/en.json` (your source file)
- Auto-generate translations for:
  - 🇩🇪 German (`de.json`)
  - 🇫🇷 French (`fr.json`)
  - 🇪🇸 Spanish (`es.json`)
  - 🇱🇹 Lithuanian (`lt.json`)
  - 🇬🇷 Greek (`el.json`)

---

## 💰 Cost

- **Free Tier:** 500,000 characters/month
- **Your app:** ~20,000 characters = **FREE** ✅
- Even if you go over: ~$0.50 total

---

## ⚠️ Important Notes

1. **Preserve en.json structure:** The script maintains your JSON structure
2. **Translation keys unchanged:** Only values are translated
3. **Smart skipping:** Placeholders like `{value}` are preserved
4. **Review recommended:** Auto-translations are ~95% accurate

---

## 🔧 Troubleshooting

### "API not enabled"
```bash
gcloud services enable translate.googleapis.com
```

### "Permission denied"
```bash
gcloud auth application-default login
```

### "Module not found"
```bash
# Python
pip install google-cloud-translate

# Node.js
npm install @google-cloud/translate
```

---

## 📝 Manual Review (Optional)

After auto-translation, you might want to review:
- App name (keep as "CrowdWave")
- Brand-specific terms
- Technical terms
- Button labels for natural flow

But honestly, Google Translate is excellent for app UI text!

---

## 🎯 Next Steps After Translation

1. ✅ Translations are generated
2. Test app in different languages
3. Make minor adjustments if needed (optional)
4. Deploy! 🚀

---

## 📞 Need Help?

If you encounter issues:
1. Check gcloud is installed: `gcloud --version`
2. Check authentication: `gcloud auth list`
3. Check API is enabled: `gcloud services list --enabled | grep translate`

---

**Happy Translating! 🌍✨**
