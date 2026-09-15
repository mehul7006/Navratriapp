@echo off
title Navratri 2026 - Nishitpark
color 0A
cls

echo ============================================
echo    NAVRATRI 2026 - NISHPARK SOCIETY APP
echo ============================================
echo.

set "API_DIR=E:\Navratri App\navratri_app\api_server"
set "WEB_DIR=E:\Navratri App\navratri_app\build\web"
set "FLUTTER_SDK=E:\flutter\bin\cache\dart-sdk\bin"
set "NGINX_DIR=E:\nginx-1.28.3"

:: ====== STOP EVERYTHING FIRST ======
echo [CLEANUP] Stopping previous servers...
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
taskkill /F /IM flutter.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo [OK] Clean!
echo.

:: ====== START API SERVER ======
echo ============================================
echo [1/4] Starting API Server on port 8080...
echo ============================================
cd /d "%API_DIR%"
start "Navratri API" /D "%API_DIR%" "%FLUTTER_SDK%\dart.exe" run bin\main.dart 8080

echo       Waiting 8s for DB connection...
timeout /t 8 /nobreak >nul

:: Check API
curl -s http://localhost:8080/api/daily-info >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] API Server + Database connected!
) else (
    echo [FAIL] API Server not responding. Check the API window for errors.
    echo.
    pause
    exit /b 1
)

:: ====== START NGINX ======
echo.
echo ============================================
echo [2/4] Starting nginx on port 80...
echo ============================================
taskkill /F /IM nginx.exe >nul 2>nul
timeout /t 1 /nobreak >nul
start "Navratri nginx" /D "%NGINX_DIR%" "%NGINX_DIR%\nginx.exe"
timeout /t 2 /nobreak >nul

curl -s http://localhost/ >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] nginx serving Flutter web!
) else (
    echo [FAIL] nginx not responding.
)

:: ====== START NGROK ======
echo.
echo ============================================
echo [3/4] Starting ngrok tunnel...
echo ============================================
taskkill /F /IM ngrok.exe >nul 2>nul
timeout /t 1 /nobreak >nul
start "Navratri ngrok" "E:\ngrok.exe" http 80
timeout /t 6 /nobreak >nul
echo [OK] ngrok tunnel active!

:: ====== SUMMARY ======
echo.
echo ============================================
echo.
echo   ALL SERVICES STARTED!
echo.
echo   ------------------------------------------------
echo   Local:      http://localhost
echo   API:        http://localhost:8080
echo   Public:     https://consuming-upriver-struck.ngrok-free.dev
echo   ------------------------------------------------
echo.
echo   Share the Public URL with anyone!
echo.
echo   TIPS:
echo     - To rebuild web: flutter build web --release
echo     - To rebuild APK: flutter build apk --release
echo     - To stop: press Enter below
echo.
echo ============================================
echo.

:: ====== WAIT FOR USER ======
pause

:: ====== STOP EVERYTHING ======
echo.
echo ============================================
echo [STOP] Stopping all servers...
echo ============================================
cd /d "%NGINX_DIR%"
"%NGINX_DIR%\nginx.exe" -s stop >nul 2>nul
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo  All servers stopped!
echo ============================================
