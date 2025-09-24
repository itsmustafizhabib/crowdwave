@echo off

REM CrowdWave Backend Deployment Script for Windows
echo 🚀 Deploying CrowdWave Stripe Backend...

REM Check if we're in the right directory
if not exist "stripe_backend.js" (
    echo ❌ Error: Please run this script from the backend directory
    pause
    exit /b 1
)

REM Install dependencies
echo 📦 Installing dependencies...
npm install

REM Check if Vercel CLI is installed
vercel --version >nul 2>&1
if errorlevel 1 (
    echo 🔧 Installing Vercel CLI...
    npm install -g vercel
)

REM Deploy to Vercel
echo 🌐 Deploying to Vercel...
vercel --prod

echo ✅ Deployment complete!
echo.
echo 📋 Next steps:
echo 1. Copy the deployment URL from above
echo 2. Update api_constants.dart with your new backend URL
echo 3. Test payments in your Flutter app
echo.
echo 🎉 Your CrowdWave backend is now live!
pause
