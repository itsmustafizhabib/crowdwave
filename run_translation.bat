@echo off
REM Translation Setup and Execution Script for CrowdWave (Windows)
REM Translates en.json to 30 European languages

echo ==================================
echo 🌍 CrowdWave Translation Setup
echo ==================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed
    echo Please install Python 3.7 or higher from https://www.python.org/
    pause
    exit /b 1
)

echo ✅ Python is installed
echo.

REM Check if Google Cloud Translate library is installed
echo 📦 Checking dependencies...
python -c "import google.cloud.translate_v2" >nul 2>&1

if errorlevel 1 (
    echo ⚠️  google-cloud-translate not installed
    echo Installing...
    python -m pip install google-cloud-translate
    
    if errorlevel 1 (
        echo ❌ Failed to install google-cloud-translate
        echo Please install manually: pip install google-cloud-translate
        pause
        exit /b 1
    )
)

echo ✅ Dependencies OK
echo.

REM Check for service account key
echo 🔐 Checking Google Cloud credentials...

if "%GOOGLE_APPLICATION_CREDENTIALS%"=="" (
    REM Try to find service account key in common locations
    if exist "assets\service_account.json" (
        set GOOGLE_APPLICATION_CREDENTIALS=%CD%\assets\service_account.json
        echo ✅ Found: assets\service_account.json
    ) else if exist "service_account.json" (
        set GOOGLE_APPLICATION_CREDENTIALS=%CD%\service_account.json
        echo ✅ Found: service_account.json
    ) else (
        echo ❌ No Google Cloud service account key found!
        echo.
        echo Please do ONE of the following:
        echo.
        echo Option 1: Place your service account key file:
        echo   → As: assets\service_account.json
        echo   → Or: service_account.json (project root^)
        echo.
        echo Option 2: Set environment variable:
        echo   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\key.json
        echo.
        echo 📖 To get a service account key:
        echo   1. Go to: https://console.cloud.google.com
        echo   2. Select your project
        echo   3. Go to: IAM ^& Admin → Service Accounts
        echo   4. Create or select a service account
        echo   5. Click 'Keys' → 'Add Key' → 'Create new key' → JSON
        echo   6. Save the downloaded JSON file as service_account.json
        echo.
        pause
        exit /b 1
    )
) else (
    echo ✅ Using: %GOOGLE_APPLICATION_CREDENTIALS%
)

REM Check if en.json exists
if not exist "assets\translations\en.json" (
    echo ❌ English translation file not found: assets\translations\en.json
    pause
    exit /b 1
)

echo ✅ Found: assets\translations\en.json
echo.

REM Show info
echo 📊 Will translate to 30 European languages
echo.

REM Warning about API costs
echo ⚠️  IMPORTANT: Google Cloud Translation API costs money!
echo    Check pricing: https://cloud.google.com/translate/pricing
echo.

REM Ask for confirmation
set /p CONFIRM="❓ Continue with translation? (yes/no): "

if /i not "%CONFIRM%"=="yes" (
    if /i not "%CONFIRM%"=="y" (
        echo ❌ Translation cancelled
        pause
        exit /b 0
    )
)

REM Run the translation script
echo.
echo ==================================
echo 🚀 Starting Translation...
echo ==================================
echo.

python translate_all_languages.py

if errorlevel 1 (
    echo.
    echo ❌ Translation failed. Check the errors above.
    pause
    exit /b 1
)

echo.
echo ==================================
echo ✅ Translation Complete!
echo ==================================
echo.
echo 📁 Check: assets\translations\
echo.
echo Next steps:
echo   1. Review the generated translation files
echo   2. Test the app with different languages
echo   3. Commit the files to your repository
echo.
pause
