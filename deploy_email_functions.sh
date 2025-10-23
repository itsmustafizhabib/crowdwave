#!/bin/bash

# Email Functions Deployment Script for CrowdWave
# This script deploys the custom email Cloud Functions

echo "🌊 CrowdWave Email Functions Deployment"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "functions/email_functions.js" ]; then
    echo "❌ Error: email_functions.js not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Navigate to functions directory
cd functions || exit 1

echo "📦 Step 1: Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed successfully"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found!"
    echo "Creating .env template..."
    cat > .env << 'EOF'
# Firebase Functions Environment Variables
STRIPE_SECRET_KEY=your_stripe_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# SMTP Email Configuration (Zoho)
SMTP_USER=nauman@crowdwave.eu
SMTP_PASSWORD=your_zoho_app_password_here
EOF
    echo "✅ Created .env template"
    echo "⚠️  Please edit functions/.env and add your Zoho App Password!"
    echo ""
    read -p "Press Enter after you've updated the .env file..."
fi

# Verify .env has password
if grep -q "your_zoho_app_password_here" .env; then
    echo "⚠️  Warning: .env still contains placeholder password!"
    echo "Please update SMTP_PASSWORD in functions/.env before deploying."
    echo ""
    read -p "Continue anyway? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
fi

echo "🚀 Step 2: Deploying email functions to Firebase..."
echo ""

# Go back to project root
cd ..

# Deploy only email-related functions
firebase deploy --only functions:sendEmailVerification,functions:sendPasswordResetEmail,functions:sendDeliveryUpdateEmail,functions:testEmailConfig

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Deployment failed!"
    echo "Common issues:"
    echo "  - Not logged in to Firebase (run: firebase login)"
    echo "  - Wrong project selected (run: firebase use [project-id])"
    echo "  - Node.js version mismatch (need Node 20)"
    exit 1
fi

echo ""
echo "✅ Email functions deployed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Configure DNS records (SPF, DKIM) - see EMAIL_SETUP_GUIDE.md"
echo "2. Test using the Email Test Screen in the app"
echo "3. Toggle 'Use Cloud Function' ON in test screen"
echo "4. Send test emails and verify they work"
echo ""
echo "📖 For detailed setup instructions, see EMAIL_SETUP_GUIDE.md"
echo ""
