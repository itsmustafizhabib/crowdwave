@echo off
REM Deploy Tracking Email Notification Function
REM This script deploys the new Firestore trigger for tracking status email notifications

echo ==================================================
echo 📧 Deploying Tracking Email Notification Function
echo ==================================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI not found. Please install it first:
    echo    npm install -g firebase-tools
    exit /b 1
)

echo ✅ Firebase CLI found
echo.

REM Login check
echo 🔐 Checking Firebase authentication...
call firebase login:list

echo.
echo 📦 Deploying Cloud Function...
echo.

REM Deploy the new tracking notification function
call firebase deploy --only functions:notifyTrackingStatusChange

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==================================================
    echo ✅ DEPLOYMENT SUCCESSFUL!
    echo ==================================================
    echo.
    echo 📧 Function deployed: notifyTrackingStatusChange
    echo.
    echo 🧪 Testing Instructions:
    echo 1. Update a tracking status in the app
    echo 2. Check sender's email inbox
    echo 3. Verify email received with status update
    echo.
    echo 📊 Monitor logs:
    echo    firebase functions:log --only notifyTrackingStatusChange
    echo.
    echo 🎉 Senders will now receive email notifications for all tracking updates!
    echo.
) else (
    echo.
    echo ==================================================
    echo ❌ DEPLOYMENT FAILED
    echo ==================================================
    echo.
    echo Please check the error messages above.
    echo Common issues:
    echo   - Not logged in: Run 'firebase login'
    echo   - Wrong project: Run 'firebase use project-id'
    echo   - SMTP not configured: Set smtp.user and smtp.password
    echo.
    exit /b 1
)

pause
