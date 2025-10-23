# String Replacement Automation Scripts

Two automation scripts have been created to replace hardcoded English strings with `.tr()` calls for internationalization:

## 📜 Available Scripts

### 1. **Python Script** (Recommended - Easier to Run)
- **File**: `auto_replace_strings.py`
- **Requirements**: Python 3.6+
- **Advantages**: No compilation needed, runs immediately

### 2. **Dart Script** (Alternative)
- **File**: `auto_replace_strings.dart`
- **Requirements**: Dart SDK
- **Advantages**: Native Dart implementation

---

## 🚀 Quick Start

### Option A: Python Script (Recommended)

#### **1. Test Run (Dry Run - See What Will Change)**
```bash
python auto_replace_strings.py --dry-run
```

#### **2. Process Single File**
```bash
# Dry run on specific file
python auto_replace_strings.py --dry-run --file=lib/presentation/auth/login_view.dart

# Apply changes to specific file
python auto_replace_strings.py --file=lib/presentation/auth/login_view.dart
```

#### **3. Process All Files**
```bash
# Apply changes to all Dart files in lib/
python auto_replace_strings.py
```

---

### Option B: Dart Script

#### **1. Test Run (Dry Run)**
```bash
dart auto_replace_strings.dart --dry-run
```

#### **2. Process Single File**
```bash
dart auto_replace_strings.dart --dry-run --file=lib/presentation/auth/login_view.dart
dart auto_replace_strings.dart --file=lib/presentation/auth/login_view.dart
```

#### **3. Process All Files**
```bash
dart auto_replace_strings.dart
```

---

## 🔍 What The Scripts Do

### Automatic Replacements

The scripts automatically find and replace patterns like:

1. **Text Widgets**
   ```dart
   // Before
   Text('Login')
   
   // After
   Text('auth.login'.tr())
   ```

2. **TextField Properties**
   ```dart
   // Before
   hintText: 'Enter your email'
   
   // After
   hintText: 'auth.email_hint'.tr()
   ```

3. **AppBar Titles**
   ```dart
   // Before
   title: Text('My Wallet')
   
   // After
   title: Text('wallet.title'.tr())
   ```

### Automatic Import Management

The scripts also handle imports:

**If your file doesn't have GetX:**
```dart
import 'package:easy_localization/easy_localization.dart';
```

**If your file already uses GetX:**
```dart
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
```

---

## ⚠️ Important Notes

### Safety Features
- ✅ Only replaces strings that have matching keys in `assets/translations/en.json`
- ✅ Preserves code formatting and structure
- ✅ Skips generated files (`.g.dart`, `.freezed.dart`)
- ✅ No backups created (use Git to undo)

### Before Running
1. **Commit your current changes to Git** (important!)
   ```bash
   git add .
   git commit -m "Before string replacement automation"
   ```

2. **Make sure you have the translation keys in en.json**
   - All 200+ new keys have already been added
   - Located in: `assets/translations/en.json`

### After Running
1. **Review the changes**
   ```bash
   git diff
   ```

2. **If something looks wrong, undo everything**
   ```bash
   git checkout .
   ```

3. **Test your app**
   ```bash
   flutter run
   ```

---

## 📊 Expected Results

Based on the scan, the scripts should:
- Process ~50 files
- Make ~400 string replacements
- Add necessary imports to modified files

### Example Output
```
🚀 String Replacement Script
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mode: LIVE (will modify files)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Loaded 948 translation keys from en.json

📁 Files to process: 458

  ✓ lib/presentation/auth/login_view.dart: 12 replacements
  ✓ lib/presentation/wallet/wallet_view.dart: 8 replacements
  ✓ lib/presentation/tracking/tracking_view.dart: 15 replacements
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Summary:
   Files changed: 48
   Total replacements: 387

✅ Changes applied successfully!
   Use "git diff" to review changes
   Use "git checkout ." to undo if needed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🎯 Recommended Workflow

### Step 1: Start with Login Screen (Your Current File)
```bash
# Test on login_view.dart first
python auto_replace_strings.py --dry-run --file=lib/presentation/auth/login_view.dart

# If looks good, apply
python auto_replace_strings.py --file=lib/presentation/auth/login_view.dart

# Review changes
git diff lib/presentation/auth/login_view.dart

# Test the app
flutter run
```

### Step 2: Process High Priority Files
```bash
# Process wallet screens
python auto_replace_strings.py --file=lib/presentation/wallet/wallet_view.dart

# Process tracking screens  
python auto_replace_strings.py --file=lib/presentation/tracking/tracking_view.dart

# etc...
```

### Step 3: Process All Remaining Files
```bash
# Commit what you've done so far
git add .
git commit -m "Partial i18n conversion - tested files"

# Process everything
python auto_replace_strings.py

# Review
git diff

# Test thoroughly
flutter run
```

---

## 🐛 Troubleshooting

### Script Not Finding Files
Make sure you're running from the project root:
```bash
cd C:/Users/ghani/Desktop/Projects/Courier-CrowdWave/Flutterrr
python auto_replace_strings.py
```

### Translation Keys Not Found
The script only replaces strings that match values in `en.json`. If a string isn't replaced, it means:
1. The translation key doesn't exist in `en.json` (add it manually)
2. The string pattern doesn't match (may need manual replacement)

### Build Errors After Running
If you get compilation errors:
1. Check `git diff` to see what changed
2. Look for malformed replacements
3. Undo if needed: `git checkout .`
4. Report the issue and we'll fix the script

---

## 📝 Manual Replacements

Some strings may need manual replacement:
- Dynamic strings with interpolation
- Strings in comments
- Complex widget constructors
- Non-standard patterns

For these, use the patterns from `IMPLEMENTATION_SUMMARY.md`.

---

## ✅ Verification Checklist

After running the script:

- [ ] All modified files compile without errors
- [ ] App runs successfully
- [ ] UI displays translated text correctly
- [ ] No broken layouts or missing text
- [ ] Git diff shows expected changes only
- [ ] No accidental replacements in comments/code

---

## 🎉 Next Steps

After successful automation:

1. **Test the app thoroughly** - Check all screens that were modified
2. **Commit the changes** - `git commit -m "Automated i18n string replacements"`
3. **Translate to other languages** - Use your API to translate `en.json` to 29 European languages
4. **Update documentation** - Mark automation as complete in `IMPLEMENTATION_SUMMARY.md`

---

**Need Help?** 
- Check `IMPLEMENTATION_SUMMARY.md` for detailed implementation guide
- Review `TRANSLATION_KEYS_TO_ADD.md` for complete key mapping
- Use `git diff` to inspect changes before committing
