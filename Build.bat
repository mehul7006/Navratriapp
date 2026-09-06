@echo off
title Navratri 2026 - Build for Production
color 0E
cls

echo ============================================
echo    NAVRATRI 2026 - BUILD FOR PRODUCTION
echo ============================================
echo.

cd /d "%~dp0\navratri_app"

echo Select build target:
echo.
echo [1] Web (HTML/JS/CSS) - Host on any server
echo [2] Android APK - Install on Android devices
echo [3] Both Web + Android
echo.
set /p choice="Enter choice (1-3): "

if "%choice%"=="1" goto :build_web
if "%choice%"=="2" goto :build_android
if "%choice%"=="3" goto :build_both
goto :invalid

:build_web
echo.
echo Building Flutter Web...
call E:\flutter\bin\flutter.bat build web --release
echo.
if %errorlevel% equ 0 (
    echo ============================================
    echo  BUILD SUCCESSFUL!
    echo ============================================
    echo  Output folder: build\web
    echo  Open index.html to run the app
    echo ============================================
) else (
    echo BUILD FAILED!
)
goto :end

:build_android
echo.
echo Building Android APK...
call E:\flutter\bin\flutter.bat build apk --release
echo.
if %errorlevel% equ 0 (
    echo ============================================
    echo  BUILD SUCCESSFUL!
    echo ============================================
    echo  APK location: build\app\outputs\flutter-apk\
    echo  Copy app-release.apk to your Android phone
    echo ============================================
) else (
    echo BUILD FAILED!
)
goto :end

:build_both
call :build_web
call :build_android
goto :end

:invalid
echo Invalid choice!
goto :end

:end
echo.
pause
