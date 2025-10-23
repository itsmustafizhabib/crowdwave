# 🚀 Quick Translation Reference

## ✅ System Status
- **Translation keys**: 1,343 strings in `en.json`
- **Code coverage**: 1,068 `.tr()` calls - all verified ✅
- **Languages ready**: 30 European languages + Georgian
- **Scripts ready**: ✅ All automation scripts created

## 📝 Quick Commands

### Windows
```cmd
# Run translation (automatic setup)
run_translation.bat

# Or manually
set GOOGLE_APPLICATION_CREDENTIALS=assets\service_account.json
python translate_all_languages.py
```

### Mac/Linux
```bash
# Run translation (automatic setup)
./run_translation.sh

# Or manually
export GOOGLE_APPLICATION_CREDENTIALS=assets/service_account.json
python translate_all_languages.py
```

## 📦 Required Files

```
project_root/
├── assets/
│   ├── service_account.json       ← YOUR GOOGLE CLOUD KEY (required)
│   └── translations/
│       └── en.json                 ← Source file (exists ✅)
├── translate_all_languages.py      ← Main script (created ✅)
├── run_translation.bat             ← Windows launcher (created ✅)
├── run_translation.sh              ← Mac/Linux launcher (created ✅)
├── TRANSLATION_SETUP_GUIDE.md      ← Full guide (created ✅)
└── TRANSLATION_READY.md            ← Quick start (created ✅)
```

## 🔑 Google Cloud Setup Checklist

- [ ] Create Google Cloud project
- [ ] Enable "Cloud Translation API"
- [ ] Enable billing (first 500K chars free/month)
- [ ] Create service account with "Cloud Translation API User" role
- [ ] Download JSON key
- [ ] Save as `assets/service_account.json`
- [ ] Install library: `pip install google-cloud-translate`
- [ ] Run script: `run_translation.bat` or `./run_translation.sh`

## 🌍 Output Files (30 Languages)

After running, these files will be created in `assets/translations/`:

```
de.json  (German)       fr.json  (French)        es.json  (Spanish)
it.json  (Italian)      pt.json  (Portuguese)    nl.json  (Dutch)
pl.json  (Polish)       cs.json  (Czech)         sk.json  (Slovak)
hu.json  (Hungarian)    ro.json  (Romanian)      el.json  (Greek)
bg.json  (Bulgarian)    hr.json  (Croatian)      sl.json  (Slovenian)
sq.json  (Albanian)     sr.json  (Serbian)       mk.json  (Macedonian)
sv.json  (Swedish)      da.json  (Danish)        fi.json  (Finnish)
no.json  (Norwegian)    is.json  (Icelandic)     et.json  (Estonian)
lv.json  (Latvian)      lt.json  (Lithuanian)    mt.json  (Maltese)
ga.json  (Irish)        cy.json  (Welsh)         ka.json  (Georgian)
```

## 💡 Tips

1. **Cost**: First 500K characters/month are free - CrowdWave likely qualifies
2. **Time**: Expect 5-15 minutes for all 30 languages
3. **Existing files**: Script will ask before overwriting
4. **Brand names**: "CrowdWave" won't be translated (preserved)
5. **Test**: Change language in app settings after translation

## 🆘 Common Issues

| Problem | Solution |
|---------|----------|
| "Module not found: google.cloud" | `pip install google-cloud-translate` |
| "Credentials not found" | Place key as `assets/service_account.json` |
| "API not enabled" | Enable Translation API in Google Cloud Console |
| "Permission denied" | Service account needs "Cloud Translation API User" role |
| "Billing not enabled" | Enable billing in Google Cloud (required for API) |

## 📊 Verification

After translation, verify:
```bash
# Count generated files (should be 31 total: en.json + 30 translations)
ls assets/translations/*.json | wc -l

# Check file sizes (should all be similar)
ls -lh assets/translations/*.json

# Test a translation (check German file exists and has content)
cat assets/translations/de.json | head -20
```

## 🎯 Next Steps After Translation

1. **Git commit**:
   ```bash
   git add assets/translations/*.json
   git commit -m "Add 30 European language translations"
   ```

2. **Test in app**:
   - Run Flutter app
   - Go to Settings → Language
   - Try different languages
   - Verify UI displays correctly

3. **Optional**: Review key translations manually for accuracy

## 🔒 Security

**NEVER commit these to Git:**
- ❌ `service_account.json`
- ❌ `assets/service_account.json`
- ❌ Any `*key*.json` files

These are already in `.gitignore` ✅

## 📧 Support

Questions? Check:
1. `TRANSLATION_SETUP_GUIDE.md` - Complete guide
2. `TRANSLATION_READY.md` - Quick start
3. Google Cloud Console - API status
4. Script output - Error messages

---

**Ready?** Place your `service_account.json` and run `run_translation.bat`! 🚀
