# PROYECTO FINAL 360 - SESION 2 FINAL

## Hilo conductor

Sesion 1:
pantallas + navegacion + preferencias + Auth + CRUD + Supabase.

Sesion 2:
Future + async/await + loading + API REST + JSON + modelo + error/reintento + GPS + mapa + contexto + persistencia.

NO es otro proyecto. Es el mismo sistema creciendo.

## Windows

1. Extrae en una ruta corta, por ejemplo:
   `C:\flutter_aula\PROYECTO_FINAL_360_SESION2_FINAL`
2. Ejecuta:
   `scripts\00_PREPARAR_WINDOWS.bat`
3. Luego:
   `scripts\01_MENU_WINDOWS.bat`
4. Empieza SUPABASE en Android o Chrome.

Windows Desktop NO es requisito para esta clase.

## MX Linux / Linux

1. Extrae dentro de tu HOME.
2. Ejecuta:
   `chmod +x scripts/*.sh`
3. Luego:
   `./scripts/00_PREPARAR_LINUX.sh`
4. Después:
   `./scripts/01_MENU_LINUX.sh`

Si aparece Ninja:
`./scripts/98_REPARAR_NINJA_LINUX.sh`

## SUPABASE (unico modo)

Este proyecto usa SOLO la parte final (Supabase). No hay modo DEMO.

1. Ejecutar SQL de `supabase/` en el proyecto Supabase.
2. Crear `config/local.json` con Project URL + Publishable Key.
3. Ejecutar el menu: `scripts\01_MENU_WINDOWS.bat` (o `.sh`).

Nunca poner service_role ni secret key dentro de Flutter.

## Regla de estabilidad

Durante la clase:
`flutter pub get` SI
`flutter pub upgrade` NO
