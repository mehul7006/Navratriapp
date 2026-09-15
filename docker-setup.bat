@echo off
echo ============================================
echo  Navratri 2026 - Docker Setup
echo ============================================
echo.

echo [1/2] Building Flutter web...
call flutter build web
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter web build failed!
    pause
    exit /b 1
)
echo Flutter web built successfully!
echo.

echo [2/2] Starting Docker containers...
docker-compose up -d --build
if %ERRORLEVEL% neq 0 (
    echo ERROR: Docker compose failed!
    pause
    exit /b 1
)

echo.
echo ============================================
echo  All services started!
echo  App:  http://localhost
echo  API:  http://localhost:8080
echo  pgAdmin: http://localhost:5050 (if enabled)
echo ============================================
echo.
echo To stop: docker-compose down
echo To reset DB: docker-compose down -v && docker-compose up -d --build
pause
