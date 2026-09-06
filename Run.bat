@echo off
title Navratri 2026 - Full Stack
color 0A
cls

echo ============================================
echo    NAVRATRI 2026 - NISHPARK SOCIETY APP
echo ============================================
echo.

set "PROJECT_DIR=%~dp0navratri_app"
set "FLUTTER_PATH=E:\flutter"
set "PATH=%FLUTTER_PATH%\bin;%PATH%"

echo ============================================
echo  [CLEANUP] Stopping all previous servers...
echo ============================================

:: Kill all dart and flutter processes
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM flutter.exe >nul 2>nul

:: Kill processes on all used ports
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8888 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8889 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :9001 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul

:: Kill named windows
taskkill /FI "WindowTitle eq Navratri API Server" /T /F >nul 2>&1
taskkill /FI "WindowTitle eq Navratri Flutter Web" /T /F >nul 2>&1

echo [OK] All previous servers stopped!
echo.

:: Wait for ports to be free
timeout /t 2 /nobreak >nul

echo ============================================
echo  [START] Starting fresh servers...
echo ============================================

echo [1/4] Starting API Server on port 8080...
cd /d "%PROJECT_DIR%\api_server"
start /B cmd /c "dart run bin\main.dart > "%~dp0api_server.log" 2>&1"
cd /d "%PROJECT_DIR%"

echo [2/4] Waiting 8s for API server to start...
timeout /t 8 /nobreak >nul

echo [3/4] Checking API server...
curl -s http://localhost:8080/api/announcements >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] API server is running!
) else (
    echo [WARNING] API server may not be ready yet. Check api_server.log
)

echo [4/4] Starting Flutter Web on port 9001...
echo.
echo ============================================
echo.
echo   API Server:  http://localhost:8080
echo   Flutter App: http://localhost:9001
echo.
echo   Press Ctrl+C to stop both servers.
echo.
echo ============================================
echo.

flutter run -d chrome --web-port=9001 --web-hostname=localhost

echo.
echo ============================================
echo  [STOP] Stopping servers...
echo ============================================
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM flutter.exe >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :9001 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
echo  All servers stopped!
echo ============================================
