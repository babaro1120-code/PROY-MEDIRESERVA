@echo off
setlocal
cd /d "%~dp0\.."

:menu
cls
echo ============================================================
echo PROYECTO FINAL MEDIRESERVA - WINDOWS
echo ============================================================
echo 1. SUPABASE - elegir dispositivo
echo 2. SUPABASE - Chrome
echo 3. Ver dispositivos
echo 0. Salir
echo ============================================================
set /p option=Opcion: 

if "%option%"=="1" flutter run --dart-define-from-file=config/local.json
if "%option%"=="2" flutter run -d chrome --dart-define-from-file=config/local.json
if "%option%"=="3" flutter devices
if "%option%"=="0" exit /b 0

echo.
pause
goto menu
