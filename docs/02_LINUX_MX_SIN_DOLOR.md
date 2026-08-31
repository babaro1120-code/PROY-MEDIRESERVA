# Linux / MX Linux

Preparar:
`chmod +x scripts/*.sh`
`./scripts/00_PREPARAR_LINUX.sh`

Ejecutar:
`./scripts/01_MENU_LINUX.sh`

Si aparece build.ninja still dirty:
`./scripts/98_REPARAR_NINJA_LINUX.sh`

Ese script no toca `lib/`.
Normaliza timestamps y limpia solo artefactos generados.
