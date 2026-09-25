# Pruebas del servidor — MediReserva

Casos de prueba ejecutados sobre el esquema y las funciones de PostgreSQL.
Formato: identificador, escenario, resultado esperado, resultado obtenido y estado
(Lineamientos técnicos, apartado 3.2.8).

## Entorno de ejecución

| Elemento | Valor |
|---|---|
| Motor | PostgreSQL 14.5 (binario local de Laragon) |
| Simulación de Supabase | Esquema `auth` y `auth.uid()`, roles `anon`, `authenticated` y `service_role`, y privilegios por defecto equivalentes |
| Scripts aplicados | `schema.sql`, `04_REPARAR_PERFILES.sql`, `05_ROLES_Y_RLS.sql`, `06_NOTIFICACIONES.sql`, `07_RESERVAS_RPC.sql`, `08_ELIMINAR_MODULO_DEMO.sql` |
| Sesión simulada | `set role authenticated` + `set_config('request.jwt.claim.sub', <uuid>)`, igual que el reclamo del JWT de Supabase |

Los rechazos esperados (403, doble reserva) se ejecutan con `ON_ERROR_STOP`
desactivado a propósito: son el resultado que se quiere observar.

## Casos de prueba

| ID | Escenario evaluado | Resultado esperado | Resultado obtenido | Estado |
|---|---|---|---|---|
| P-01 | Alta de un usuario en `auth.users` | El disparador `handle_new_user` crea la fila en `profiles` con rol `paciente` | 3 perfiles creados, los 3 con rol `paciente` | Aprobado |
| P-02 | Un paciente intenta asignarse el rol `administrador` | Rechazo (42501) | `ERROR: Solo un administrador puede cambiar el rol de un usuario.` El rol permaneció en `paciente` | Aprobado |
| P-03 | Un paciente edita su propio nombre (control positivo) | Permitido | `UPDATE 1`; el nombre quedó actualizado | Aprobado |
| P-04 | Reserva sobre un bloque libre | Cita creada y número de reserva devuelto | `MR-20260925-9251B9DF`, estado `confirmed` | Aprobado |
| P-05 | Estado del bloque tras reservar | `is_available = false` | `f` | Aprobado |
| P-06 | Un segundo paciente intenta el mismo bloque | Rechazo (23505) | `ERROR: Ese horario acaba de ser reservado por otro paciente.` | Aprobado |
| P-07 | Reservas activas sobre ese bloque | Exactamente 1 | 1 | Aprobado |
| P-08 | Notificaciones al registrar una reserva | Aviso al paciente y al profesional | `Reserva registrada` y `Nueva reserva en tu agenda` | Aprobado |
| P-09 | Aislamiento RLS entre pacientes | El paciente 2 no ve la reserva del paciente 1 | 0 filas visibles | Aprobado |
| P-10 | Un paciente cancela una reserva ajena | Rechazo (42501) | `ERROR: No puedes cancelar una reserva que no es tuya.` | Aprobado |
| P-11 | El dueño cancela su propia reserva | Estado `cancelled` | `{"id": "...", "status": "cancelled"}` | Aprobado |
| P-12 | Cancelar libera el bloque horario | `is_available = true` | `t` | Aprobado |
| P-13 | Reservar de nuevo el bloque liberado | Permitido (índice único parcial) | `MR-20260925-16202B7F`, estado `confirmed` | Aprobado |
| P-14 | Un paciente cambia el estado de una reserva | Rechazo (42501) | `ERROR: Solo el profesional asignado o un administrador pueden cambiar el estado.` | Aprobado |
| P-15 | Estado fuera del dominio cerrado | Rechazo (22023) | `ERROR: Estado invalido: inventado. Use pending, confirmed, cancelled o completed.` | Aprobado |
| P-16 | El profesional asignado marca la consulta como atendida | Estado `completed` | `{"id": "...", "status": "completed"}` | Aprobado |
| P-17 | Notificación al cambiar el estado | Aviso al paciente y al profesional | `Consulta atendida` para ambos | Aprobado |
| P-18 | Idempotencia: re-ejecutar los 6 scripts | Sin errores ni datos duplicados | Los 6 con `exit=0`; conteos sin variación (7 especialidades, 3 profesionales, 2 reservas, 11 notificaciones, 3 perfiles) | Aprobado |

**Resultado:** 18 de 18 casos aprobados.

## Casos automatizados en Dart

Ejecutados con `flutter test` (ver `docs/VERIFICACION_ANALYZE_TEST.txt`):

| ID | Escenario | Estado |
|---|---|---|
| T-01 a T-06 | Conversión de los modelos `Specialty`, `Doctor` y `Appointment`, incluidos los valores por defecto | Aprobado |
| T-07 | `AgendaItem.fromMap` lee el nombre del paciente de la relación anidada | Aprobado |
| T-08 | `AgendaItem.fromMap` tolera que el paciente no llegue en la respuesta | Aprobado |
| T-09 | La forma `jsonb` que devuelve `reservar_cita` se mapea con `Appointment` sin adaptaciones | Aprobado |
| T-10 | El modelo no depende de `patient_id`: ese dato sale de `auth.uid()` | Aprobado |
| T-11 | La aplicación avisa cuando falta la configuración de Supabase | Aprobado |

**Resultado:** 11 de 11 casos aprobados.

## Cómo reproducir las pruebas del servidor

1. `initdb` sobre un directorio temporal y arrancar `postgres` en un puerto libre.
2. Aplicar el guion de simulación de Supabase (esquema `auth`, roles y privilegios).
3. Ejecutar los 6 scripts del proyecto en orden, con `ON_ERROR_STOP=1`.
4. Ejecutar los guiones de prueba funcional y comparar con la tabla anterior.

> El guion de simulación no forma parte del proyecto: existe únicamente para poder
> probar los scripts reales sin depender de una cuenta de Supabase.
