@echo off
setlocal
cd /d "%~dp0\.."

flutter --version
flutter doctor -v
flutter devices
flutter pub deps
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
pause
