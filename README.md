#  MEDIRESERVA — (SISTEMA WEB Y MÓVIL PARA LA GESTIÓN DE RESERVAS DE CONSULTAS MÉDICAS)

## 1. Nombre y descripción del proyecto

MEDIRESERVA es una aplicación móvil moderna desarrollada en Flutter que facilita la gestión y reserva de citas médicas
de forma rápida, eficiente e intuitiva. Permite a los usuarios consultar la disponibilidad de profesionales de la salud, programar consultas y gestionar sus reservas en tiempo real.


## 2. 🎯 Problema u objetivo

El objetivo principal de MEDIRESERVA es optimizar el proceso de reserva de citas en centros médicos, reduciendo los tiempos de espera y eliminando
las barreras de atención presencial o telefónica. La aplicación busca centralizar la información médica de turnos para ofrecer una experiencia accesible, 
ágil y transparente tanto para pacientes como para el personal médico.


## 3.🚀 Funcionalidades implementadas


* **Autenticación e Identificación:** Registro e inicio de sesión de usuarios.
* **Catálogo de Especialidades y Médicos:** Búsqueda y filtrado de profesionales de la salud.
* **Gestión de Citas Médicas:** 
  * Selección de fechas y horarios disponibles.
  * Confirmación y reserva de turnos.
  * Historial de citas médicas (pasadas y pendientes).
  * Cancelación o reprogramación de citas.
* **Perfiles de Usuario:** Gestión de datos personales y preferencias de atención.
* **Integración Web / Dispositivos:** Soporte para ejecución multiplataforma (Android y Web).

## 4. 🛠️ Tecnologías utilizadas

* **Lenguaje de Programación:** [Dart](https://dart.dev/)
* **Framework Principal:** [Flutter](https://flutter.dev/) (v3.x)
* **Entorno de Ejecución / Soporte:** Android SDK, Chrome / Web Drivers
* **Gestión de Estado y Dependencias:** Paquetes Dart/Flutter estándar (`pubspec.yaml`)
* **Herramientas de Construcción:** Gradle (Android), Dart Tooling


**Versiones principales (`pubspec.yaml`):** `provider 6.1.5+1`, `shared_preferences 2.5.5`, `supabase_flutter 2.17.2`, `http 1.6.0`, `geolocator 14.0.3`, `flutter_map 8.3.2`, `latlong2 0.10.1`.

## 5. Requisitos para ejecutar el proyecto

- Flutter SDK **>= 3.35.0** y Dart **>= 3.9.0**.
- Editor (VS Code con extensión Flutter, o Android Studio).
- Un proyecto **Supabase** con las tablas y políticas aplicadas (SQL en `supabase/`).
- Archivo `config/local.json` con `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`.
- Dispositivo **Android** (o Chrome para probar).

> ⚠️ Regla de estabilidad del aula: `flutter pub get` **SÍ** — `flutter pub upgrade` **NO** (podría romper dependencias).

## 6. Instrucciones de instalación y ejecución

### Windows

1. Extrae el proyecto en una ruta corta, por ejemplo: `C:\flutter_aula\PROYECTO_FINAL_360_SESION2_FINAL`
2. Ejecuta `scripts\00_PREPARAR_WINDOWS.bat`
3. Luego `scripts\01_MENU_WINDOWS.bat`
4. Elige Android o Chrome.

> Windows Desktop **no** es requisito para esta clase.

### Linux (MX)

1. Extrae el proyecto dentro de tu HOME.
2. `chmod +x scripts/*.sh`
3. `./scripts/00_PREPARAR_LINUX.sh`
4. `./scripts/01_MENU_LINUX.sh`
5. Si aparece error de Ninja: `./scripts/98_REPARAR_NINJA_LINUX.sh`

### Configuración de Supabase (único modo)

Este proyecto usa **solo** la parte final (Supabase). No hay modo DEMO.

1. Ejecuta el SQL de `supabase/` en tu proyecto Supabase.
2. Crea `config/local.json` a partir de `config/local.example.json` (Project URL + Publishable Key).
3. Ejecuta la app:
   ```powershell
   flutter run --dart-define-from-file=config/local.json
   ```

> ⚠️ Nunca pongas `service_role` ni secret keys dentro de Flutter.

## 7. Estructura general del proyecto

```
Proyecto MEDIRESERVA/
├── android/              # Configuración y código nativo para Android
├── ios/                  # Configuración nativa para iOS
├── lib/                  # Código fuente principal de la aplicación (Dart)
│   ├── main.dart         # Punto de entrada de la aplicación
│   ├── models/           # Modelos de datos
│   ├── screens/          # Pantallas e interfaces de usuario
│   ├── services/         # Servicios de red, APIs e integración
│   └── widgets/          # Componentes visuales reutilizables
├── web/                  # Archivos para soporte y compilación Web
├── pubspec.yaml          # Configuración de dependencias y assets de Flutter
└── README.md             # Documentación principal del proyecto

## 8. Procedimiento para generar el APK

### APK de depuración (rápido para probar)

```powershell
flutter build apk --debug
```

- Ruta del APK: `build\app\outputs\flutter-apk\app-debug.apk`

### APK de lanzamiento (para distribución)

```powershell
flutter build apk --release --dart-define-from-file=config/local.json
```

- Ruta del APK: `build\app\outputs\flutter-apk\app-release.apk`

### Instalación en un teléfono

1. Conecta el celular por USB (con depuración USB activada).
2. Ejecuta `flutter install`, o copia el archivo `app-release.apk` al teléfono e instálalo manualmente.

> 📌 Se usa `--dart-define-from-file=config/local.json` para que el APK incluya la configuración de Supabase (URL + Publishable Key). No modifiques `config/local.json` (contiene claves del aula).

## 9. Versión entregada

- **Versión:** `1.0.0+1` (definida en `pubspec.yaml`).
- **Sesión / etapa:** Sesión 2 — Proyecto Final MEDIRESERVA.
- **Plataforma objetivo:** Android (y web para pruebas).

## 10. Limitaciones conocidas

Integración de Pagos: La pasarela de pago en línea se encuentra en modo de prueba / simulación.

Notificaciones Push: Requieren la configuración previa de credenciales de servicios externos (Firebase Cloud Messaging) en el servidor final.

Soporte Offline: Es necesaria una conexión activa a Internet para consultar la disponibilidad de citas en tiempo real.

✍️ Autor del Proyecto

## 11. Autor del proyecto

Desarrollador / ALVARO VLADIMIR OLIVERA SOLANO

Contacto / Repositorio: Proyecto MEDIRESERVA - GitHub
"""