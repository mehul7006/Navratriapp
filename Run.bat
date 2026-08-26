@echo off
title Navratri App - Full Stack
echo ============================================
echo   Navratri 2026 - Starting Full Stack
echo ============================================
echo.

echo [1/2] Starting API Server on port 8080...
start "Navratri API Server" cmd /c "cd /d E:\Navratri App\navratri_app\api_server && E:\flutter\bin\dart.bat run bin\main.dart"

echo [2/2] Waiting 3s for API server...
timeout /t 3 /nobreak >nul

echo [3/3] Building Flutter Web (release mode)...
echo        First run: ~60s build, then instant on refresh
echo        Subsequent runs: ~3-5s startup
echo.
start "Navratri Flutter Web" cmd /c "cd /d E:\Navratri App\navratri_app && E:\flutter\bin\flutter.bat run -d chrome --web-port=9001 --web-hostname=localhost --release"

echo.
echo ============================================
echo   API Server:  http://localhost:8080
echo   Flutter App: http://localhost:9001
echo ============================================
echo.
echo Press any key to stop both servers...
pause >nul
taskkill /FI "WindowTitle eq Navratri API Server" /T /F >nul 2>&1
taskkill /FI "WindowTitle eq Navratri Flutter Web" /T /F >nul 2>&1
echo Servers stopped.
