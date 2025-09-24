@echo off
echo Deploying Firestore configuration...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Firebase CLI is not installed. Please install it first:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

REM Login to Firebase (if not already logged in)
echo Checking Firebase authentication...
firebase login --no-localhost

REM Deploy Firestore indexes
echo Deploying Firestore indexes...
firebase deploy --only firestore:indexes

REM Deploy Firestore security rules  
echo Deploying Firestore security rules...
firebase deploy --only firestore:rules

echo ✅ Firestore configuration deployed successfully!
echo 🔍 Indexes may take a few minutes to build. Check the Firebase Console for progress.
pause
