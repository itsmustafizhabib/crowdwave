@echo off
REM Check Google Cloud Translation API Quota using gcloud CLI

echo 🔍 Checking Translation API Quota...
echo.

REM Get project ID
for /f "tokens=*" %%i in ('gcloud config get-value project 2^>nul') do set PROJECT_ID=%%i

if "%PROJECT_ID%"=="" (
    echo ❌ No project set. Run: gcloud config set project PROJECT_ID
    exit /b 1
)

echo 📊 Project: %PROJECT_ID%
echo.

REM Check if Translation API is enabled
echo Checking if Translation API is enabled...
gcloud services list --enabled --filter="name:translate.googleapis.com" --format="value(name)" > temp_api_check.txt 2>nul
set /p API_ENABLED=<temp_api_check.txt
del temp_api_check.txt

if "%API_ENABLED%"=="" (
    echo ❌ Translation API is NOT enabled
    echo.
    echo To enable it, run:
    echo   gcloud services enable translate.googleapis.com
    exit /b 1
) else (
    echo ✅ Translation API is enabled
)

echo.
echo ============================================================
echo 📈 Quota Information
echo ============================================================

REM Estimate translation requirements
if exist "assets\translations\en.json" (
    for %%A in (assets\translations\en.json) do set EN_SIZE=%%~zA
    set /a LANGUAGES=30
    set /a TOTAL_CHARS=!EN_SIZE! * !LANGUAGES!
    
    echo   English JSON size:       !EN_SIZE! characters
    echo   Target languages:        !LANGUAGES!
    echo   Total to translate:      !TOTAL_CHARS! characters
    echo.
    
    if !TOTAL_CHARS! LSS 500000 (
        set /a REMAINING=500000 - !TOTAL_CHARS!
        echo   ✅ Should fit in free tier (500K/month^)
        echo   Estimated remaining:     !REMAINING! characters
    ) else (
        set /a OVERAGE=!TOTAL_CHARS! - 500000
        echo   ⚠️  Will exceed free tier
        echo   Overage:                 !OVERAGE! characters
    )
) else (
    echo   ⚠️  en.json not found - cannot estimate
)

echo ============================================================
echo.
echo 🔗 View detailed quota in Cloud Console:
echo    https://console.cloud.google.com/apis/api/translate.googleapis.com/quotas?project=%PROJECT_ID%
echo.
echo 📊 View usage metrics:
echo    https://console.cloud.google.com/monitoring/metrics-explorer?project=%PROJECT_ID%
echo.
echo 💡 The free tier provides 500,000 characters per month
echo    After that, it's $20 per 1 million characters
echo.

pause
