#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."

flutter --version
flutter doctor -v
flutter devices
flutter pub deps
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
