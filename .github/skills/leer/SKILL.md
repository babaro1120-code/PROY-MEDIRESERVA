---
name: leer
description: 'Ejecutar la app Flutter del proyecto con la config de Supabase
  (config/local.json). Usar para: correr la app, probar cambios, verificar la
  sesión de aula. Respeta la regla: flutter pub get SÍ, flutter pub upgrade NO.'
user-invocable: true
---

# Ejecutar la app (proyecto SIGVACH)

## Cuándo usar
- El usuario pide correr/ejecutar/probar la app
- Verificar que un cambio compila y abre en la pantalla esperada
- Preparar la app para probar Supabase (login + registros_demo)

## Reglas del aula (importantes)
1. `flutter pub get` → permitido.
2. `flutter pub upgrade` → PROHIBIDO (podría romper dependencias).
3. No tocar `config/local.json` (contiene URL/keys de Supabase).

## Procedimiento
1. Verificar que existe `config/local.json`.
2. Ejecutar la app en el dispositivo deseado:
   ```
   flutter run --dart-define-from-file=config/local.json
   ```
3. Confirmar que aparece la pantalla de login/registro.
4. Si hay error de compilación, revisar `lib/` y `pubspec.yaml` sin actualizar dependencias.
