#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Reparando solo artefactos de build. No se toca lib/."

find . -type f \
  -not -path './.git/*' \
  -not -path './.dart_tool/*' \
  -exec touch {} +

flutter clean || true
rm -rf build .dart_tool
rm -rf linux/flutter/ephemeral 2>/dev/null || true

flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings

echo "Listo. Vuelve a ejecutar desde el menu."
