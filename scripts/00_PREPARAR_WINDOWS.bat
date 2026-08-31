@echo off
setlocal
cd /d "%~dp0\.."

echo ============================================================
echo PROYECTO FINAL 360 - PREPARAR WINDOWS
echo ============================================================

where flutter >nul 2>&1
if errorlevel 1 (
  echo ERROR: flutter no esta en PATH.
  pause
  exit /b 1
)

flutter --version

if exist .platform_seed rmdir /s /q .platform_seed

flutter create .platform_seed --project-name sigvach --org bo.edu.uajms --platforms=android,web --no-pub
if errorlevel 1 goto :error

if exist android rmdir /s /q android
if exist web rmdir /s /q web

xcopy /E /I /Y .platform_seed\android android >nul
xcopy /E /I /Y .platform_seed\web web >nul
rmdir /s /q .platform_seed

copy /Y platform_templates\android\AndroidManifest.xml android\app\src\main\AndroidManifest.xml >nul

echo.
echo flutter pub get
flutter pub get
if errorlevel 1 goto :error

echo.
echo flutter analyze --no-fatal-infos --no-fatal-warnings
flutter analyze --no-fatal-infos --no-fatal-warnings
if errorlevel 1 goto :error

echo.
echo flutter test
flutter test
if errorlevel 1 goto :error

echo.
echo flutter devices
flutter devices

echo.
echo PREPARACION COMPLETA.
echo Ruta recomendada: Android. Plan B: Chrome.
pause
exit /b 0

:error
echo.
echo PREPARACION DETENIDA. Copia el error completo al docente.
echo NO ejecutes flutter pub upgrade.
pause
exit /b 1
