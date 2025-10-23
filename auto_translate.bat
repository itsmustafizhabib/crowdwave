@echo off
REM Auto-translate all JSON files using Google Cloud Translate API

echo.
echo ============================================
echo   Auto-Translation Starting...
echo ============================================
echo.

REM Enable Translate API
echo Enabling Google Translate API...
gcloud services enable translate.googleapis.com 2>nul
echo API enabled
echo.

REM Check for Python
where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Using Python for translation...
    echo.
    pip install --quiet --upgrade google-cloud-translate 2>nul
    python translate_json.py
    goto :done
)

REM Check for Node.js
where node >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Using Node.js for translation...
    echo.
    if not exist "node_modules\@google-cloud\translate" (
        echo Installing dependencies...
        npm install @google-cloud/translate --quiet
    )
    node translate_json.js
    goto :done
)

echo Error: Neither Python nor Node.js found.
echo Please install one of them to run the translation script.
exit /b 1

:done
echo.
echo ============================================
echo   Translation Complete!
echo ============================================
echo.
pause
