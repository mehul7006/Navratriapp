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

:: Kill named windows
taskkill /FI "WindowTitle eq Navratri API Server" /T /F >nul 2>&1
taskkill /FI "WindowTitle eq Navratri nginx" /T /F >nul 2>&1
taskkill /FI "WindowTitle eq Navratri ngrok" /T /F >nul 2>&1

:: Kill all dart, nginx and ngrok processes
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM flutter.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul

:: Kill processes on all used ports
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :80 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :9001 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul

echo [OK] All previous servers stopped!
echo.

:: Wait for ports to be free
timeout /t 2 /nobreak >nul

echo ============================================
echo  [START] Starting fresh servers...
echo ============================================

echo [1/5] Starting API Server on port 8080...
cd /d "%PROJECT_DIR%\api_server"
start "Navratri API Server" cmd /k "cd /d "%PROJECT_DIR%\api_server" && "E:\flutter\bin\cache\dart-sdk\bin\dart.exe" run bin\main.dart 8080"
cd /d "%PROJECT_DIR%"

echo [2/5] Waiting 8s for API server to start...
timeout /t 8 /nobreak >nul

echo [3/5] Checking API server...
curl -s http://localhost:8080/api/announcements >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] API server is running!
) else (
    echo [WARNING] API server may not be ready yet. Check api_server.log
)

echo [4/5] Starting nginx on port 80...
cd /d "E:\nginx-1.28.3"
start "Navratri nginx" cmd /k "cd /d E:\nginx-1.28.3 && nginx.exe"
cd /d "%PROJECT_DIR%"
timeout /t 2 /nobreak >nul
echo [OK] nginx started!

echo [5/5] Starting ngrok tunnel on port 80...
start "Navratri ngrok" cmd /k "E:\ngrok.exe http 80"
timeout /t 5 /nobreak >nul

:: Get ngrok public URL
echo.
echo ============================================
echo.
for /f "tokens=*" %%u in ('curl -s http://127.0.0.1:4040/api/tunnels 2^>nul ^| findstr /C:"public_url"') do (
    for /f "tokens=2 delims=:" %%a in ("%%u") do (
        set "RAWURL=%%a"
    )
)
:: Clean up the URL (remove quotes and spaces)
set "PUBLIC_URL=%RAWURL: =%"
set "PUBLIC_URL=%PUBLIC_URL:"=%"
set "PUBLIC_URL=%PUBLIC_URL:,=%"

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
cd /d "E:\nginx-1.28.3"
nginx.exe -s stop >nul 2>nul
cd /d "%PROJECT_DIR%"
taskkill /FI "WindowTitle eq Navratri API Server" /T /F >nul 2>&1
taskkill /FI "WindowTitle eq Navratri nginx" /T /F >nul 2>&1
taskkill /FI "WindowTitle eq Navratri ngrok" /T /F >nul 2>&1
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :80 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>nul
echo  All servers stopped!
echo ============================================
