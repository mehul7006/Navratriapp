@echo off
title Navratri 2026 - Nishitpark
color 0A
cls

set "API_DIR=E:\Navratri App\navratri_app\api_server"
set "LOG_DIR=E:\Navratri App\navratri_app\logs"
set "FLUTTER_SDK=E:\flutter\bin\cache\dart-sdk\bin"
set "NGINX_DIR=E:\nginx-1.28.3"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: ====== FULL START ======
:START
cls
echo ============================================
echo    NAVRATRI 2026 - NISHPARK SOCIETY APP
echo ============================================
echo.

echo  Stopping old servers...
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
taskkill /F /IM flutter.exe >nul 2>nul
timeout /t 2 /nobreak >nul

echo.
echo  [1/3] Starting API Server (port 8080)...
start /b "" cmd /c "cd /d "%API_DIR%" && "%FLUTTER_SDK%\dart.exe" run bin\main.dart 8080 > "%LOG_DIR%\api.log" 2>&1"
echo         Waiting for DB...
timeout /t 8 /nobreak >nul
curl -s http://localhost:8080/api/daily-info >nul 2>nul
if %errorlevel% equ 0 (
    echo         [OK] API + DB connected!
) else (
    echo         [WARN] API not ready - check logs
)

echo  [2/3] Starting nginx (port 80)...
start /b "" cmd /c "cd /d "%NGINX_DIR%" && nginx.exe > "%LOG_DIR%\nginx.log" 2>&1"
timeout /t 2 /nobreak >nul
echo         [OK] nginx started!

echo  [3/3] Starting ngrok tunnel...
start /b "" cmd /c "E:\ngrok.exe http 80 > "%LOG_DIR%\ngrok.log" 2>&1"
timeout /t 5 /nobreak >nul
echo         [OK] ngrok started!

echo.
echo ============================================
echo.
echo   Local:   http://localhost
echo   API:     http://localhost:8080
echo   Public:  https://consuming-upriver-struck.ngrok-free.dev
echo.
echo ============================================
echo.
echo   COMMANDS:
echo     R  = Hot Restart  (restart API server only, keeps ngrok/nginx)
echo     S  = Full Restart (stop everything and start fresh)
echo     L  = Show API logs
echo     V  = Show status
echo     Q  = Quit (stop all)
echo.
echo ============================================
echo.

:INPUT
set /p "CHOICE=  > "

:: R = HOT RESTART (only API server)
if /I "%CHOICE%"=="R" (
    echo.
    echo  Hot restarting API server...
    taskkill /F /IM dart.exe >nul 2>nul
    timeout /t 1 /nobreak >nul
    start /b "" cmd /c "cd /d "%API_DIR%" && "%FLUTTER_SDK%\dart.exe" run bin\main.dart 8080 > "%LOG_DIR%\api.log" 2>&1"
    timeout /t 6 /nobreak >nul
    curl -s http://localhost:8080/api/daily-info >nul 2>nul
    if %errorlevel% equ 0 (
        echo  [OK] API + DB reconnected!
    ) else (
        echo  [WARN] API not ready yet...
    )
    echo.
    goto INPUT
)

:: S = FULL RESTART
if /I "%CHOICE%"=="S" goto START

:: L = SHOW LOGS
if /I "%CHOICE%"=="L" (
    echo.
    echo  === API LOGS (last 20 lines) ===
    if exist "%LOG_DIR%\api.log" (
        powershell -Command "Get-Content '%LOG_DIR%\api.log' -Tail 20"
    ) else (
        echo  No logs yet.
    )
    echo.
    goto INPUT
)

:: V = STATUS
if /I "%CHOICE%"=="V" (
    echo.
    echo  === STATUS ===
    tasklist /FI "IMAGENAME eq dart.exe" 2>nul | findstr dart >nul && echo  [OK] API Server: RUNNING  || echo  [OFF] API Server: STOPPED
    tasklist /FI "IMAGENAME eq nginx.exe" 2>nul | findstr nginx >nul && echo  [OK] nginx: RUNNING      || echo  [OFF] nginx: STOPPED
    tasklist /FI "IMAGENAME eq ngrok.exe" 2>nul | findstr ngrok >nul && echo  [OK] ngrok: RUNNING      || echo  [OFF] ngrok: STOPPED
    curl -s http://localhost:8080/api/daily-info >nul 2>nul && echo  [OK] DB: CONNECTED       || echo  [OFF] DB: NOT CONNECTED
    echo.
    goto INPUT
)

:: Q = QUIT
if /I "%CHOICE%"=="Q" goto STOP

echo  Unknown command. Use R, S, L, V, or Q.
goto INPUT

:STOP
echo.
echo  Stopping all servers...
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
taskkill /F /IM flutter.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo  All servers stopped!
echo ============================================
timeout /t 2 /nobreak >nul
exit
