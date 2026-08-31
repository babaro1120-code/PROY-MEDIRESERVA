#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo "PROYECTO FINAL 360 - PREPARAR LINUX / MX LINUX"
echo "============================================================"

command -v flutter >/dev/null 2>&1 || {
  echo "ERROR: flutter no esta en PATH."
  exit 1
}

flutter --version

rm -rf .platform_seed
flutter create .platform_seed \
  --project-name sigvach \
  --org bo.edu.uajms \
  --platforms=android,web,linux \
  --no-pub

rm -rf android web linux
cp -a .platform_seed/android .
cp -a .platform_seed/web .
cp -a .platform_seed/linux .
rm -rf .platform_seed

cp platform_templates/android/AndroidManifest.xml \
  android/app/src/main/AndroidManifest.xml

echo
echo "Normalizando timestamps..."
find . -type f \
  -not -path './.git/*' \
  -not -path './.dart_tool/*' \
  -exec touch {} +

echo
echo "flutter pub get"
flutter pub get

echo
echo "flutter analyze"
flutter analyze --no-fatal-infos --no-fatal-warnings

echo
echo "flutter test"
flutter test

echo
echo "flutter devices"
flutter devices

echo
echo "PREPARACION COMPLETA."
echo "Ruta recomendada: Android. Plan B: Chrome. Linux desktop: opcional."
