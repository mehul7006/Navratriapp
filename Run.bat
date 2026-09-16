@echo off
title Navratri 2026 - Nishitpark
color 0A
cls

set "API_DIR=E:\Navratri App\navratri_app\api_server"
set "LOG_DIR=E:\Navratri App\navratri_app\logs"
set "FLUTTER_SDK=E:\flutter\bin\cache\dart-sdk\bin"
set "NGINX_DIR=E:\nginx-1.28.3"
set "PG_SERVICE=postgresql-x64-18"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

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
timeout /t 2 /nobreak >nul

echo.
echo  [1/4] Starting PostgreSQL Database...
sc query "%PG_SERVICE%" | findstr "RUNNING" >nul 2>nul
if %errorlevel% neq 0 (
    net start "%PG_SERVICE%" >nul 2>nul
    timeout /t 3 /nobreak >nul
)
"C:\Program Files\PostgreSQL\18\bin\pg_isready.exe" -h localhost -U postgres >nul 2>nul
if %errorlevel% equ 0 (
    echo         [OK] Database running!
) else (
    echo         [FAIL] Database not started. Run as Administrator.
    pause
    goto INPUT
)

echo  [2/4] Starting API Server (port 8080)...
start /b "" cmd /c "cd /d "%API_DIR%" && "%FLUTTER_SDK%\dart.exe" run bin\main.dart 8080 > "%LOG_DIR%\api.log" 2>&1"
echo         Waiting for API...
timeout /t 8 /nobreak >nul
curl -s http://localhost:8080/api/daily-info >nul 2>nul
if %errorlevel% equ 0 (
    echo         [OK] API + DB connected!
) else (
    echo         [WARN] API not ready - check logs
)

echo  [3/4] Starting nginx (port 80)...
start /b "" cmd /c "cd /d "%NGINX_DIR%" && nginx.exe > "%LOG_DIR%\nginx.log" 2>&1"
timeout /t 2 /nobreak >nul
echo         [OK] nginx started!

echo  [4/4] Starting ngrok tunnel...
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
echo     R  = Hot Restart  (restart API server only, keeps DB/nginx/ngrok)
echo     F  = Full Restart (stop everything and start fresh)
echo     H  = Hot Reload   (rebuild web + restart API)
echo     L  = Show API logs
echo     S  = Show status
echo     Q  = Quit (stop all)
echo.
echo ============================================
echo.

:INPUT
set /p "CHOICE=  > "

:: R = HOT RESTART (API server only)
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

:: F = FULL RESTART
if /I "%CHOICE%"=="F" goto START

:: H = HOT RELOAD (rebuild web + restart API)
if /I "%CHOICE%"=="H" (
    echo.
    echo  Rebuilding web and restarting API...
    taskkill /F /IM dart.exe >nul 2>nul
    echo  Building Flutter web...
    cmd /c "E:\flutter\bin\flutter.bat build web --release --no-tree-shake-icons --no-pub" > "%LOG_DIR%\web_build.log" 2>&1
    echo  Restarting nginx...
    taskkill /F /IM nginx.exe >nul 2>nul
    timeout /t 1 /nobreak >nul
    start /b "" cmd /c "cd /d "%NGINX_DIR%" && nginx.exe > "%LOG_DIR%\nginx.log" 2>&1"
    echo  Restarting API server...
    start /b "" cmd /c "cd /d "%API_DIR%" && "%FLUTTER_SDK%\dart.exe" run bin\main.dart 8080 > "%LOG_DIR%\api.log" 2>&1"
    timeout /t 6 /nobreak >nul
    curl -s http://localhost:8080/api/daily-info >nul 2>nul
    if %errorlevel% equ 0 (
        echo  [OK] Web rebuilt + API + DB reconnected!
    ) else (
        echo  [WARN] API not ready yet...
    )
    echo  TIP: Hard refresh browser (Ctrl+Shift+R) to clear cache.
    echo.
    goto INPUT
)

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

:: S = STATUS
if /I "%CHOICE%"=="S" (
    echo.
    echo  === STATUS ===
    sc query "%PG_SERVICE%" | findstr "RUNNING" >nul 2>nul && echo  [OK] PostgreSQL: RUNNING  || echo  [OFF] PostgreSQL: STOPPED
    tasklist /FI "IMAGENAME eq dart.exe" 2>nul | findstr dart >nul && echo  [OK] API Server: RUNNING  || echo  [OFF] API Server: STOPPED
    tasklist /FI "IMAGENAME eq nginx.exe" 2>nul | findstr nginx >nul && echo  [OK] nginx: RUNNING      || echo  [OFF] nginx: STOPPED
    tasklist /FI "IMAGENAME eq ngrok.exe" 2>nul | findstr ngrok >nul && echo  [OK] ngrok: RUNNING      || echo  [OFF] ngrok: STOPPED
    curl -s http://localhost:8080/api/daily-info >nul 2>nul && echo  [OK] API Health: OK       || echo  [OFF] API Health: FAIL
    echo.
    goto INPUT
)

:: Q = QUIT
if /I "%CHOICE%"=="Q" goto STOP

echo  Unknown command. Use R, F, H, L, S, or Q.
goto INPUT

:STOP
echo.
echo  Stopping all servers...
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM nginx.exe >nul 2>nul
taskkill /F /IM ngrok.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo  All servers stopped!
echo ============================================
timeout /t 2 /nobreak >nul
exit
