#!/bin/bash

# CrowdWave Backend Deployment Script
echo "🚀 Deploying CrowdWave Stripe Backend..."

# Check if we're in the right directory
if [ ! -f "stripe_backend.js" ]; then
    echo "❌ Error: Please run this script from the backend directory"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "🔧 Installing Vercel CLI..."
    npm install -g vercel
fi

# Deploy to Vercel
echo "🌐 Deploying to Vercel..."
vercel --prod

echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Copy the deployment URL from above"
echo "2. Update api_constants.dart with your new backend URL"
echo "3. Test payments in your Flutter app"
echo ""
echo "🎉 Your CrowdWave backend is now live!"
