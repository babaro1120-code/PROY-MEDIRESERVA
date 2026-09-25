# MEDIRESERVA

**Sistema web y móvil para la gestión de reservas de consultas médicas**

Proyecto final del Diplomado en Desarrollo Web y Aplicaciones Móviles · UAJMS 2026
Autor: Alvaro Vladimir Olivera Solano · Grupo 3

---

## 1. Descripción

MediReserva es una aplicación desarrollada en Flutter que permite a los pacientes
consultar la disponibilidad de profesionales de la salud, reservar un turno y
gestionar sus citas. El sistema se apoya en Supabase como plataforma de backend:
autenticación, base de datos PostgreSQL y autorización mediante políticas de
seguridad a nivel de fila (RLS).

Se ejecuta en Android y en navegador web desde un único código fuente.

## 2. Problema y objetivo

La reserva de consultas se realiza hoy por teléfono o de forma presencial, sin un
registro único que impida asignar el mismo horario a dos pacientes. MediReserva
centraliza la oferta de horarios y garantiza que un bloque solo pueda reservarse
una vez.

**Objetivo general:** desarrollar un sistema web y móvil que permita a los
pacientes reservar consultas médicas sobre la disponibilidad real de los
profesionales, evitando la doble asignación de un mismo horario.

## 3. Funcionalidades implementadas

- **Autenticación:** registro, inicio y cierre de sesión, recuperación de
  contraseña por correo y cambio de contraseña, con Supabase Auth.
- **Catálogo:** especialidades y profesionales, leídos desde la base de datos.
- **Flujo de reserva en seis pasos:** especialidad → profesional → fecha →
  horario → confirmación → comprobante con número de reserva.
- **Gestión de citas:** agenda propia del paciente, separada en próximas e
  históricas, y cancelación con liberación del bloque horario.
- **Perfil:** consulta y actualización de los datos personales.
- **Notificaciones:** avisos generados por el servidor al registrar, confirmar,
  atender o cancelar una reserva.
- **Estados de interfaz:** cada pantalla que consulta datos resuelve carga,
  vacío, error y datos, y muestra el mensaje de error de la API.
- **Roles:** paciente, profesional y administrador, con autorización aplicada en
  el servidor mediante RLS.

## 4. Tecnologías utilizadas

Versiones tomadas de `pubspec.lock`, del SDK instalado y del entorno de ejecución.

| Componente | Versión | Función en el sistema |
|---|---|---|
| Flutter | 3.44.8 | Framework multiplataforma (Android y web) |
| Dart | 3.12.2 | Lenguaje de programación |
| supabase_flutter | 2.17.2 | Cliente oficial de Supabase para Flutter |
| supabase (Dart) | 2.16.1 | Núcleo del cliente: Auth, Realtime, Storage |
| postgrest | 2.9.1 | Cliente de la API REST generada por PostgreSQL |
| gotrue | 2.27.2 | Cliente de autenticación (GoTrue) |
| shared_preferences | 2.5.5 | Persistencia local de la sesión |
| http | 1.6.0 | Cliente HTTP subyacente |
| app_links · url_launcher | 7.2.1 · 6.3.2 | Enlaces profundos y apertura de enlaces |
| Supabase (plataforma) | PostgreSQL gestionado | Base de datos, Auth, RLS y API REST |
| Vercel | — | Alojamiento del frontend web |
| Git | 2.40+ | Control de versiones |

> Las dependencias se declaran en `pubspec.yaml` y se fijan en `pubspec.lock`.
> Regla del aula: `flutter pub get` **sí**, `flutter pub upgrade` **no**.

## 5. Requisitos para ejecutar el proyecto

- Flutter SDK **>= 3.44.0** y Dart **>= 3.12.0**.
- Editor con extensión de Flutter (VS Code o Android Studio).
- Un proyecto de Supabase con el esquema aplicado (ver apartado 6).
- Archivo `config/local.json` con `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`.
- Para Android: un dispositivo o emulador. Para web: Chrome.

## 6. Instalación y ejecución

### 6.1 Base de datos

En **Supabase → SQL Editor**, ejecutar en este orden:

| Orden | Archivo | Contenido |
|---|---|---|
| 1 | `supabase/schema.sql` | Tablas, RLS, disparador de perfil y datos iniciales |
| 2 | `supabase/04_REPARAR_PERFILES.sql` | Reparación de perfiles faltantes (error 23503) |
| 3 | `supabase/05_ROLES_Y_RLS.sql` | Roles, funciones de autorización y políticas por rol |
| 4 | `supabase/06_NOTIFICACIONES.sql` | Notificaciones automáticas |
| 5 | `supabase/07_RESERVAS_RPC.sql` | CRUD de reservas y reserva atómica |
| 6 | `supabase/08_ELIMINAR_MODULO_DEMO.sql` | Elimina la tabla de demostración del aula |

Todos los scripts son idempotentes: pueden ejecutarse más de una vez sin
duplicar datos. Cada uno termina con consultas de verificación.

### 6.2 Configuración

```powershell
Copy-Item config/local.example.json config/local.json
# Editar config/local.json con la URL del proyecto y la clave publicable.
```

`config/local.json` está en `.gitignore`: nunca se versiona.

### 6.3 Ejecución

```powershell
flutter pub get
flutter run --dart-define-from-file=config/local.json
```

Para elegir el destino: `flutter run -d chrome` o `flutter run -d <id-dispositivo>`.

## 7. Estructura del proyecto

```
Proyecto MEDIRESERVA/
├── lib/
│   ├── main.dart                 # Punto de entrada y arranque de Supabase
│   ├── auth/auth_gate.dart       # Decide la pantalla según la sesión
│   ├── models/                   # Modelos de datos (especialidad, médico, reserva)
│   ├── screens/                  # Pantallas de la aplicación
│   ├── services/                 # auth_service y medireserva_service (acceso a datos)
│   └── widgets/                  # Componentes visuales reutilizables
├── supabase/                     # Scripts SQL del esquema y las migraciones
├── config/                       # local.example.json (plantilla) y local.json (ignorado)
├── web/                          # Plantilla de la compilación web
├── android/                      # Configuración nativa de Android
├── test/                         # Pruebas automatizadas
├── docs/                         # Documentación de apoyo
└── vercel.json                   # Configuración de despliegue web
```

## 8. Despliegue web

El frontend se publica como sitio estático. La compilación inyecta la
configuración de Supabase en el artefacto:

```powershell
flutter build web --release --dart-define-from-file=config/local.json
```

El resultado queda en `build/web` y se publica con:

```powershell
npx vercel deploy --prod
```

- **Dirección pública:** <https://medireserva.vercel.app>
- **Plataforma:** Vercel (sitio estático, `outputDirectory: build/web`)
- **Base de datos:** Supabase

> El despliegue se realiza desde el CLI sobre el artefacto ya compilado, porque el
> entorno de compilación de Vercel no incluye el SDK de Flutter.

> Tras publicar, la dirección debe registrarse en Supabase →
> **Authentication → URL Configuration** (Site URL y Redirect URLs) para que el
> inicio de sesión y la recuperación de contraseña funcionen en producción.

## 9. Generación del APK

```powershell
# Depuración
flutter build apk --debug

# Distribución
flutter build apk --release --dart-define-from-file=config/local.json
```

- Ruta: `build\app\outputs\flutter-apk\app-release.apk`
- Instalación: `flutter install`, o copiar el APK al dispositivo e instalarlo.

## 10. Seguridad

- **Autenticación:** Supabase Auth con JWT; las contraseñas las gestiona el
  servicio y nunca se almacenan en el cliente.
- **Autorización en el servidor:** políticas RLS por tabla y funciones
  `rol_actual()`, `es_administrador()` y `es_mi_agenda()`. Ocultar un control en
  la interfaz no se considera autorización.
- **El rol no se regala:** un disparador fuerza que toda cuenta creada por
  autorregistro nazca con el rol `paciente`. Solo un administrador puede cambiar
  un rol.
- **Menor privilegio:** en el cliente solo reside la clave publicable
  (`sb_publishable_...`). La clave `service_role` no se incluye en el código, ni
  en el APK, ni en la compilación web.
- **Baja lógica:** las cancelaciones se registran con estado `cancelled` en lugar
  de eliminar la fila, para conservar la trazabilidad.

## 11. Limitaciones conocidas

Las siguientes capacidades quedan **fuera del alcance** de esta entrega:

- **Pagos en línea:** requieren integración con una pasarela y obligaciones
  financieras ajenas al objetivo académico.
- **Telemedicina (videollamadas):** exige infraestructura de servidores en tiempo
  real.
- **Historia clínica electrónica:** sujeta a regulación específica sobre datos de
  salud.
- **Geolocalización de puntos de atención:** se evaluó y se retiró del alcance
  para concentrar el esfuerzo en el flujo de reserva.

Los datos de prueba son ficticios. No se utilizan nombres, teléfonos ni datos de
salud reales.

## 12. Pruebas

```powershell
flutter analyze
flutter test
```

| Nivel | Evidencia | Resultado |
|---|---|---|
| Análisis estático | `flutter analyze` | Sin observaciones |
| Modelos y contrato de la API | `test/medireserva_models_test.dart` | 11 de 11 |
| Interfaz | `test/widget_test.dart` | 1 de 1 |
| Base de datos y reglas de negocio | `docs/PRUEBAS_SQL.md` | 18 de 18 |

Las pruebas de la base de datos verifican, entre otras cosas, que el
autorregistro no pueda asignarse un rol privilegiado, que un segundo intento
sobre el mismo horario sea rechazado, que cancelar libere el bloque y permita
volver a reservarlo, y que las políticas RLS aíslen los datos entre pacientes.
Los resultados crudos de `analyze`, `test` y la compilación web están en
`docs/VERIFICACION_ANALYZE_TEST.txt`.

## 13. Autor

**Alvaro Vladimir Olivera Solano** · Grupo 3
Diplomado en Desarrollo Web y Aplicaciones Móviles · UAJMS 2026

- Repositorio: https://github.com/babaro1120-code/PROY-MEDIRESERVA
