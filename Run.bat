@echo off
title Navratri 2026 - Nishitpark
color 0A
cls

set "API_DIR=E:\Navratri App\navratri_app\api_server"
set "FLUTTER_SDK=E:\flutter\bin\cache\dart-sdk\bin"
set "NGINX_DIR=E:\nginx-1.28.3"

:START
cls
echo ============================================
echo    NAVRATRI 2026 - NISHPARK SOCIETY APP
echo ============================================
echo.
echo  [STOPPING OLD SERVERS...]
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
timeout /t 2 /nobreak >nul

echo.
echo  [1/4] Starting API Server (port 8080)...
start "API" /D "%API_DIR%" "%FLUTTER_SDK%\dart.exe" run bin\main.dart 8080
echo         Waiting for DB connection...
timeout /t 8 /nobreak >nul

curl -s http://localhost:8080/api/daily-info >nul 2>nul
if %errorlevel% equ 0 (
    echo         [OK] API + DB connected!
) else (
    echo         [WARN] API not ready yet - check API window
)

echo  [2/4] Starting nginx (port 80)...
start "nginx" /D "%NGINX_DIR%" "%NGINX_DIR%\nginx.exe"
timeout /t 2 /nobreak >nul
echo         [OK] nginx started!

echo  [3/4] Starting ngrok tunnel...
start "ngrok" "E:\ngrok.exe" http 80
timeout /t 5 /nobreak >nul
echo         [OK] ngrok started!

echo  [4/4] All services running!
echo.
echo ============================================
echo.
echo   Local:   http://localhost
echo   API:     http://localhost:8080
echo   Public:  https://consuming-upriver-struck.ngrok-free.dev
echo.
echo ============================================
echo.
echo   CONTROLS:
echo     R  = Reload (restart all servers with latest build)
echo     S  = Show status
echo     Q  = Quit (stop all servers)
echo.
echo ============================================
echo.

:INPUT
set /p "CHOICE=  Enter command: "

if /I "%CHOICE%"=="R" (
    echo.
    echo  Reloading servers...
    goto START
)
if /I "%CHOICE%"=="S" (
    echo.
    echo  === STATUS ===
    echo.
    tasklist /FI "IMAGENAME eq dart.exe" 2>nul | findstr dart >nul && echo  [OK] API Server: RUNNING || echo  [OFF] API Server: STOPPED
    tasklist /FI "IMAGENAME eq nginx.exe" 2>nul | findstr nginx >nul && echo  [OK] nginx: RUNNING || echo  [OFF] nginx: STOPPED
    tasklist /FI "IMAGENAME eq ngrok.exe" 2>nul | findstr ngrok >nul && echo  [OK] ngrok: RUNNING || echo  [OFF] ngrok: STOPPED
    curl -s http://localhost:8080/api/daily-info >nul 2>nul && echo  [OK] DB: CONNECTED || echo  [OFF] DB: NOT CONNECTED
    echo.
    echo  Public: https://consuming-upriver-struck.ngrok-free.dev
    echo.
    goto INPUT
)
if /I "%CHOICE%"=="Q" goto STOP
goto INPUT

:STOP
echo.
echo ============================================
echo  Stopping all servers...
echo ============================================
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo  All servers stopped!
echo ============================================
timeout /t 2 /nobreak >nul
exit
