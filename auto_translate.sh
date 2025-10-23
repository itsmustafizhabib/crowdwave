#!/bin/bash

# Auto-translate all JSON files using Google Cloud Translate API
# This script will translate en.json to all other languages

echo "🚀 Starting Auto-Translation Process..."
echo "======================================"
echo ""

# Check if gcloud is available
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI not found. Please install Google Cloud SDK."
    exit 1
fi

# Enable Translate API (if not already enabled)
echo "📋 Enabling Google Translate API..."
gcloud services enable translate.googleapis.com 2>/dev/null || true
echo "✅ API enabled"
echo ""

# Check which runtime to use
if command -v python3 &> /dev/null; then
    echo "🐍 Using Python for translation..."
    echo ""
    
    # Install required package if needed
    pip3 install --quiet --upgrade google-cloud-translate 2>/dev/null || true
    
    # Run Python script
    python3 translate_json.py
    
elif command -v node &> /dev/null; then
    echo "📦 Using Node.js for translation..."
    echo ""
    
    # Install required package if needed
    if [ ! -d "node_modules/@google-cloud/translate" ]; then
        echo "Installing @google-cloud/translate..."
        npm install @google-cloud/translate --quiet
    fi
    
    # Run Node.js script
    node translate_json.js
    
else
    echo "❌ Error: Neither Python 3 nor Node.js found."
    echo "Please install one of them to run the translation script."
    exit 1
fi

echo ""
echo "✨ Translation complete! Your app is now multilingual! ✨"
