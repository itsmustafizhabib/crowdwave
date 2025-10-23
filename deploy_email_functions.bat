@echo off
REM Email Functions Deployment Script for CrowdWave (Windows)
REM This script deploys the custom email Cloud Functions

echo.
echo 🌊 CrowdWave Email Functions Deployment
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "functions\email_functions.js" (
    echo ❌ Error: email_functions.js not found!
    echo Please run this script from the project root directory.
    exit /b 1
)

REM Navigate to functions directory
cd functions

echo 📦 Step 1: Installing dependencies...
call npm install

if errorlevel 1 (
    echo ❌ Failed to install dependencies
    exit /b 1
)

echo ✅ Dependencies installed successfully
echo.

REM Check if .env file exists
if not exist ".env" (
    echo ⚠️  Warning: .env file not found!
    echo Creating .env template...
    (
        echo # Firebase Functions Environment Variables
        echo STRIPE_SECRET_KEY=your_stripe_key_here
        echo STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
        echo.
        echo # SMTP Email Configuration ^(Zoho^)
        echo SMTP_USER=nauman@crowdwave.eu
        echo SMTP_PASSWORD=your_zoho_app_password_here
    ) > .env
    echo ✅ Created .env template
    echo ⚠️  Please edit functions\.env and add your Zoho App Password!
    echo.
    pause
)

REM Verify .env has password
findstr /C:"your_zoho_app_password_here" .env >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Warning: .env still contains placeholder password!
    echo Please update SMTP_PASSWORD in functions\.env before deploying.
    echo.
    set /p confirm="Continue anyway? (y/N): "
    if /i not "%confirm%"=="y" (
        echo Deployment cancelled.
        exit /b 1
    )
)

echo 🚀 Step 2: Deploying email functions to Firebase...
echo.

REM Go back to project root
cd ..

REM Deploy only email-related functions
call firebase deploy --only functions:sendEmailVerification,functions:sendPasswordResetEmail,functions:sendDeliveryUpdateEmail,functions:testEmailConfig

if errorlevel 1 (
    echo.
    echo ❌ Deployment failed!
    echo Common issues:
    echo   - Not logged in to Firebase (run: firebase login^)
    echo   - Wrong project selected (run: firebase use [project-id]^)
    echo   - Node.js version mismatch (need Node 20^)
    exit /b 1
)

echo.
echo ✅ Email functions deployed successfully!
echo.
echo 📋 Next Steps:
echo 1. Configure DNS records (SPF, DKIM^) - see EMAIL_SETUP_GUIDE.md
echo 2. Test using the Email Test Screen in the app
echo 3. Toggle 'Use Cloud Function' ON in test screen
echo 4. Send test emails and verify they work
echo.
echo 📖 For detailed setup instructions, see EMAIL_SETUP_GUIDE.md
echo.
pause
