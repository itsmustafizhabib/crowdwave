#!/bin/bash
# Translation Setup and Execution Script for CrowdWave
# Translates en.json to 30 European languages

echo "=================================="
echo "🌍 CrowdWave Translation Setup"
echo "=================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo "❌ Python is not installed"
    echo "Please install Python 3.7 or higher"
    exit 1
fi

# Determine Python command
if command -v python3 &> /dev/null; then
    PYTHON=python3
else
    PYTHON=python
fi

echo "✅ Using Python: $($PYTHON --version)"
echo ""

# Check if Google Cloud Translate library is installed
echo "📦 Checking dependencies..."
$PYTHON -c "import google.cloud.translate_v2" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "⚠️  google-cloud-translate not installed"
    echo "Installing..."
    $PYTHON -m pip install google-cloud-translate
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install google-cloud-translate"
        echo "Please install manually: pip install google-cloud-translate"
        exit 1
    fi
fi

echo "✅ Dependencies OK"
echo ""

# Check for service account key
echo "🔐 Checking Google Cloud credentials..."

if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    # Try to find service account key in common locations
    if [ -f "assets/service_account.json" ] && [ -s "assets/service_account.json" ]; then
        export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/assets/service_account.json"
        echo "✅ Found: assets/service_account.json"
    elif [ -f "service_account.json" ] && [ -s "service_account.json" ]; then
        export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/service_account.json"
        echo "✅ Found: service_account.json"
    else
        echo "❌ No Google Cloud service account key found!"
        echo ""
        echo "Please do ONE of the following:"
        echo ""
        echo "Option 1: Place your service account key file:"
        echo "  → As: assets/service_account.json"
        echo "  → Or: service_account.json (project root)"
        echo ""
        echo "Option 2: Set environment variable:"
        echo "  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json"
        echo ""
        echo "📖 To get a service account key:"
        echo "  1. Go to: https://console.cloud.google.com"
        echo "  2. Select your project"
        echo "  3. Go to: IAM & Admin → Service Accounts"
        echo "  4. Create or select a service account"
        echo "  5. Click 'Keys' → 'Add Key' → 'Create new key' → JSON"
        echo "  6. Save the downloaded JSON file as service_account.json"
        echo ""
        exit 1
    fi
else
    echo "✅ Using: $GOOGLE_APPLICATION_CREDENTIALS"
fi

# Check if en.json exists
if [ ! -f "assets/translations/en.json" ]; then
    echo "❌ English translation file not found: assets/translations/en.json"
    exit 1
fi

echo "✅ Found: assets/translations/en.json"
echo ""

# Count strings in en.json
STRING_COUNT=$($PYTHON -c "import json; data=json.load(open('assets/translations/en.json')); print(sum(1 for _ in str(data).split('\"') if _)//2)")
echo "📊 English file contains approximately $STRING_COUNT strings"
echo "📊 Will create 30 language files"
echo ""

# Warning about API costs
echo "⚠️  IMPORTANT: Google Cloud Translation API costs money!"
echo "   Estimated API calls: $(($STRING_COUNT * 30))"
echo "   Check pricing: https://cloud.google.com/translate/pricing"
echo ""

# Ask for confirmation
read -p "❓ Continue with translation? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy]([Ee][Ss])?$ ]]; then
    echo "❌ Translation cancelled"
    exit 0
fi

# Run the translation script
echo "=================================="
echo "🚀 Starting Translation..."
echo "=================================="
echo ""

$PYTHON translate_all_languages.py

if [ $? -eq 0 ]; then
    echo ""
    echo "=================================="
    echo "✅ Translation Complete!"
    echo "=================================="
    echo ""
    echo "📁 Check: assets/translations/"
    echo ""
    echo "Next steps:"
    echo "  1. Review the generated translation files"
    echo "  2. Test the app with different languages"
    echo "  3. Commit the files to your repository"
else
    echo ""
    echo "❌ Translation failed. Check the errors above."
    exit 1
fi
