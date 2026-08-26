@echo off
cd /d E:\Navratri App\navratri_app\api_server
start /min E:\flutter\bin\dart.bat run bin\main.dart
echo API server starting...
timeout /t 5 /nobreak >nul
echo Done.
