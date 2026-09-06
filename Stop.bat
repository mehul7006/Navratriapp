@echo off
title Stop Navratri 2026 Server
color 0C
cls

echo ============================================
echo  Stopping Navratri 2026 Servers...
echo ============================================
echo.

echo Stopping Flutter processes...
taskkill /F /IM dart.exe >nul 2>nul
taskkill /F /IM flutter.exe >nul 2>nul

echo Stopping API Server...
taskkill /FI "WindowTitle eq Navratri API Server" /T /F >nul 2>&1
taskkill /FI "WindowTitle eq Navratri Flutter Web" /T /F >nul 2>&1

echo Killing processes on ports 8080, 8888, 8889, 9001...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING') do (
    echo Killing PID %%a on port 8080...
    taskkill /F /PID %%a >nul 2>nul
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8888 ^| findstr LISTENING') do (
    echo Killing PID %%a on port 8888...
    taskkill /F /PID %%a >nul 2>nul
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8889 ^| findstr LISTENING') do (
    echo Killing PID %%a on port 8889...
    taskkill /F /PID %%a >nul 2>nul
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :9001 ^| findstr LISTENING') do (
    echo Killing PID %%a on port 9001...
    taskkill /F /PID %%a >nul 2>nul
)

echo.
echo ============================================
echo  All servers stopped!
echo ============================================
echo.
pause
