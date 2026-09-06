@echo off
title Navratri 2026 - Initial Setup
color 0B
cls

echo ============================================
echo    NAVRATRI 2026 - FIRST TIME SETUP
echo ============================================
echo.
echo This script will set up everything you need.
echo.

:: Set working directory
cd /d "%~dp0"
set "PROJECT_DIR=%CD%\navratri_app"
set "FLUTTER_PATH=E:\flutter"

:: ============================================
:: STEP 1: CHECK GIT
:: ============================================
echo [Step 1/6] Checking Git...
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git not found!
    echo Please install Git from: https://git-scm.com/download/win
    pause
    exit /b 1
) else (
    echo [OK] Git is installed!
)

:: ============================================
:: STEP 2: CHECK FLUTTER AT E:\flutter
:: ============================================
echo.
echo [Step 2/6] Checking Flutter at %FLUTTER_PATH%...

:: Check if Flutter exists at E:\flutter
if exist "%FLUTTER_PATH%\bin\flutter.bat" (
    echo [OK] Flutter found at %FLUTTER_PATH%!
    set "PATH=%FLUTTER_PATH%\bin;%PATH%"
) else (
    echo [ERROR] Flutter not found at %FLUTTER_PATH%
    echo.
    echo Please ensure Flutter is installed at: %FLUTTER_PATH%
    echo Or update FLUTTER_PATH in this script.
    echo.
    echo Download Flutter from: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

:: ============================================
:: STEP 3: VERIFY FLUTTER COMMAND
:: ============================================
echo.
echo [Step 3/6] Verifying Flutter installation...
call flutter --version
if %errorlevel% neq 0 (
    echo [ERROR] Flutter command failed!
    echo Please reinstall Flutter at %FLUTTER_PATH%
    pause
    exit /b 1
)
echo [OK] Flutter is working!

:: ============================================
:: STEP 4: ENABLE WEB SUPPORT
:: ============================================
echo.
echo [Step 4/6] Enabling Flutter web...
call flutter config --enable-web
echo [OK] Web support enabled!

:: ============================================
:: STEP 5: GET DEPENDENCIES
:: ============================================
echo.
echo [Step 5/6] Installing dependencies...
cd /d "%PROJECT_DIR%"
call flutter pub get
if %errorlevel% neq 0 (
    echo [WARNING] pub get had issues, trying again...
    call flutter pub get
)
echo [OK] Dependencies installed!

:: ============================================
:: STEP 6: RUN DOCTOR
:: ============================================
echo.
echo [Step 6/6] Running Flutter Doctor...
echo.
call flutter doctor -v

echo.
echo ============================================
echo  SETUP COMPLETE!
echo ============================================
echo.
echo  Flutter Location: %FLUTTER_PATH%
echo  Project Location: %PROJECT_DIR%
echo.
echo  Next steps:
echo  1. Close this window
echo  2. Double-click "Run.bat" to start the app
echo  3. App will open at http://localhost:9001
echo.
echo ============================================
echo.
pause
