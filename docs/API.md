# API de MediReserva

Inventario de la interfaz de programación de aplicaciones del sistema.
Complementa la Tabla 12 del documento (Diseño de la solución) y sirve como
Anexo F de documentación complementaria.

## 1. Arquitectura de la API

MediReserva se apoya en **Supabase como plataforma de backend** (patrón
*Backend como servicio*). No existe un servidor propio: **PostgREST genera la
API REST automáticamente a partir del esquema de PostgreSQL**, y Supabase Auth
expone los endpoints de autenticación.

Consecuencias de esta decisión:

- **Las rutas siguen la forma `/rest/v1/<tabla>`** y `/rest/v1/rpc/<funcion>`,
  no `/api/v1/<recurso>`.
- **La autorización no vive en el servidor de aplicaciones, sino en la base de
  datos**, mediante políticas de seguridad a nivel de fila (RLS). Ocultar un
  control en la interfaz no se considera un mecanismo de autorización.
- **La especificación OpenAPI de la raíz (`GET /rest/v1/`) exige una clave
  secreta**, por lo que no se expone públicamente: el contrato se documenta en
  este archivo y en la Tabla 12 del documento.

- **URL base:** `https://<proyecto>.supabase.co`. El identificador real del
  proyecto se resuelve desde `config/local.json`, que no se versiona.
- **Clave en el cliente:** únicamente la publicable (`sb_publishable_...`). La
  clave `service_role` nunca se incluye en la aplicación ni en el repositorio.

## 2. Autenticación

| Método | Ruta | Auth | Rol | Parámetros | Respuestas |
|---|---|---|---|---|---|
| POST | `/auth/v1/signup` | no | Pública | `email`, `password`, `data{full_name, phone, birth_date}` | 200 + token · 400 · 422 |
| POST | `/auth/v1/token?grant_type=password` | no | Pública | `email`, `password` | 200 + sesión · 400 · 401 |
| POST | `/auth/v1/logout` | sí | Autenticado | — | 204 · 401 |
| POST | `/auth/v1/recover` | no | Pública | `email` | 200 · 400 |
| PUT | `/auth/v1/user` | sí | Autenticado | `password` | 200 · 401 |

## 3. Datos

| Método | Ruta | Auth | Rol | Parámetros | Respuestas |
|---|---|---|---|---|---|
| GET | `/rest/v1/specialties` | sí | Paciente, Profesional, Administrador | `select`, `active=eq.true` | 200 + lista · 401 · 403 |
| GET | `/rest/v1/doctors` | sí | Paciente, Profesional, Administrador | `select`, `specialty_id=eq.`, `active=eq.true` | 200 + lista · 401 · 403 |
| GET | `/rest/v1/doctor_availability` | sí | Paciente | `doctor_id=eq.`, `available_date=eq.`, `is_available=eq.true` | 200 + lista · 401 · 403 · 404 |
| GET | `/rest/v1/appointments` | sí | Paciente (las propias), Profesional (su agenda), Administrador (todas) | `select`, `order`, `status=neq.cancelled` | 200 + lista · 401 · 403 |
| PATCH | `/rest/v1/appointments` | sí | Paciente (las propias), Profesional asignado, Administrador | `id=eq.`, `status` | 200 · 401 · 403 · 404 · 409 |
| GET | `/rest/v1/profiles` | sí | El propio usuario; el profesional respecto de sus pacientes | `id=eq.`, `select` | 200 · 401 · 403 |
| PATCH | `/rest/v1/profiles` | sí | El propio usuario | `id=eq.`, `full_name`, `phone`, `birth_date`, `address` | 200 · 401 · 403 |
| GET | `/rest/v1/notifications` | sí | El propio usuario | `order=created_at.desc` | 200 + lista · 401 |
| PATCH | `/rest/v1/notifications` | sí | El propio usuario | `id=eq.`, `is_read` | 200 · 401 |

## 4. Funciones (RPC)

Las operaciones con reglas de negocio se exponen como funciones de PostgreSQL,
de modo que **la validación y la escritura ocurren en una sola transacción en
el servidor**.

| Método | Ruta | Auth | Rol | Parámetros | Respuestas |
|---|---|---|---|---|---|
| POST | `/rest/v1/rpc/reservar_cita` | sí | Paciente | `p_doctor_id`, `p_specialty_id`, `p_fecha`, `p_hora` | 200 + reserva · 400 · 401 · 409 · 422 |
| POST | `/rest/v1/rpc/cancelar_cita` | sí | Paciente (dueño de la reserva), Administrador | `p_cita_id` | 200 · 401 · 403 · 404 · 409 |
| POST | `/rest/v1/rpc/cambiar_estado_reserva` | sí | Profesional asignado, Administrador | `p_cita_id`, `p_estado` | 200 · 401 · 403 · 404 · 422 |
| **GET** | **`/rest/v1/rpc/salud`** | **no** | **Pública** | **—** | **200 `{ "estado": "ok" }`** · 401 |

### Ruta de salud

```
GET https://<proyecto>.supabase.co/rest/v1/rpc/salud
Header: apikey: <clave publicable>
```

Respuesta esperada:

```json
{ "estado": "ok", "servicio": "MediReserva", "version": "1.0.0", "hora": "..." }
```

Verifica de una sola vez que la API está en línea y que la base de datos
responde. La función se declara `stable` porque es lo que habilita invocarla
por GET, y no expone ningún dato del sistema.

## 5. Familia de errores

Formato uniforme en toda la API:

```json
{ "error": { "codigo": "...", "mensaje": "...", "campos": { } } }
```

| Código | Significa | Ejemplo en MediReserva |
|---|---|---|
| 400 | La petición está mal formada o el tipo es incorrecto | `appointment_date` con formato inválido |
| 401 | No sé quién eres: sin token, vencido o inválido | Reservar sin sesión iniciada |
| 403 | Sé quién eres y no puedes | Un paciente intenta cambiar el estado de una reserva |
| 404 | No existe | Horario que no está en la oferta del profesional |
| 409 | Choca con el estado actual | Segundo intento sobre un horario ya reservado |
| 422 | Formato correcto, regla de negocio violada | El profesional no corresponde a la especialidad elegida |
| 500 | Falla nuestra; nunca con el detalle interno | — |

### Códigos de PostgreSQL que se traducen en la aplicación

| Código | Origen | Mensaje al usuario |
|---|---|---|
| `23503` | Clave foránea | Falta la fila del perfil; se ejecuta `04_REPARAR_PERFILES.sql` |
| `23505` | Índice único parcial | Ese horario acaba de ser reservado por otro paciente |
| `23514` | Violación de dominio | La consulta ya fue atendida y no se puede cancelar |
| `42501` | Permisos insuficientes | El rol no permite esa operación |
| `22007` | Fecha inválida | No se puede reservar en una fecha pasada |
| `22023` | Parámetro inválido | El profesional no corresponde a la especialidad |
| `P0002` | No encontrado | El horario no está en la oferta del profesional |
| `PGRST202` | Función ausente | Falta ejecutar `07_RESERVAS_RPC.sql` |

## 6. Convenciones

- Sustantivos en plural y en el idioma del esquema (`specialties`, `doctors`,
  `appointments`).
- Filtros y paginación por parámetros de consulta (`?select=`, `?order=`,
  `?limit=`).
- Fechas y horas en ISO 8601; en la base, `date` y `time` separados.
- El identificador del paciente **nunca viaja desde el cliente**: sale de
  `auth.uid()` en el servidor.
- Las bajas son lógicas (`status = 'cancelled'`), nunca `DELETE`, para
  conservar la trazabilidad.
