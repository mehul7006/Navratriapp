@echo off
title Navratri 2026 - Full Stack
color 0A
cls

echo ============================================
echo    NAVRATRI 2026 - NISHPARK SOCIETY APP
echo ============================================
echo.

set "API_DIR=E:\Navratri App\navratri_app\api_server"
set "FLUTTER_SDK=E:\flutter\bin\cache\dart-sdk\bin"

echo ============================================
echo  [CLEANUP] Stopping all previous servers...
echo ============================================

taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
taskkill /F /IM flutter.exe >nul 2>nul

echo [OK] All previous servers stopped!
echo.

:: Wait for ports to be free
timeout /t 2 /nobreak >nul

echo ============================================
echo  [START] Starting fresh servers...
echo ============================================

echo [1/5] Starting API Server on port 8080...
start "API Server" /D "%API_DIR%" "%FLUTTER_SDK%\dart.exe" run bin\main.dart 8080

echo [2/5] Waiting 8s for API server to start...
timeout /t 8 /nobreak >nul

echo [3/5] Checking API server...
curl -s http://localhost:8080/api/daily-info >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] API server is running!
) else (
    echo [WARNING] API server may not be ready yet.
)

echo [4/5] Starting nginx on port 80...
start "nginx" /D "E:\nginx-1.28.3" "E:\nginx-1.28.3\nginx.exe"
timeout /t 2 /nobreak >nul
echo [OK] nginx started!

echo [5/5] Starting ngrok tunnel on port 80...
start "ngrok" "E:\ngrok.exe" http 80
timeout /t 5 /nobreak >nul
echo [OK] ngrok started!

echo.
echo ============================================
echo.
echo   Local:   http://localhost
echo   API:     http://localhost:8080
echo   Public:  https://consuming-upriver-struck.ngrok-free.dev
echo.
echo   Share the Public URL with anyone!
echo.
echo   Press Enter to stop all servers.
echo.
echo ============================================
echo.

pause

echo.
echo ============================================
echo  [STOP] Stopping servers...
echo ============================================
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :80 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
echo  All servers stopped!
echo ============================================
