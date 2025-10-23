#!/bin/bash
# Deploy ALL Firebase Functions to ensure both confirmPayment and stripeWebhook are updated

echo "🚀 Deploying ALL Firebase Functions..."
echo ""

cd "$(dirname "$0")"

# Check if firebase is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed!"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Deploy all functions
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All Firebase Functions deployed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Hot restart your Flutter app (press 'R' in terminal)"
    echo "2. Create a NEW order (old orders have broken data)"
    echo "3. Check the console output for debug logs"
    echo "4. Check Orders → Pending tab"
else
    echo ""
    echo "❌ Deployment failed!"
    echo "Check the error messages above"
    exit 1
fi
