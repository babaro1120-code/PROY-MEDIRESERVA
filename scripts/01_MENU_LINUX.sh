#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."

while true; do
  clear
  echo "============================================================"
  echo "PROYECTO FINAL 360 - SESION 2 - LINUX / MX"
  echo "============================================================"
  echo "1. SUPABASE - elegir dispositivo"
  echo "2. SUPABASE - Chrome"
  echo "3. SUPABASE - Linux desktop"
  echo "4. Ver dispositivos"
  echo "5. Reparar Ninja"
  echo "0. Salir"
  echo "============================================================"
  read -r -p "Opcion: " option

  case "$option" in
    1) flutter run --dart-define-from-file=config/local.json ;;
    2) flutter run -d chrome --dart-define-from-file=config/local.json ;;
    3) flutter run -d linux --dart-define-from-file=config/local.json ;;
    4) flutter devices ;;
    5) bash scripts/98_REPARAR_NINJA_LINUX.sh ;;
    0) exit 0 ;;
    *) echo "Opcion invalida" ;;
  esac

  echo
  read -r -p "ENTER para volver..."
done
