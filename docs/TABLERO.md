# Tablero de tareas MediReserva (Kanban)

**Proyecto:** MediReserva
**Tipo:** Aplicación web y móvil para reservas médicas
**Metodología:** Kanban
**Límite de trabajo en curso (WIP):** 2 tareas
**Última actualización:** 25/09/2026

---

## ✅ HECHO — 23 tareas

| ID | Tarea | Resultado |
|---|---|---|
| T-01 | Repositorio y README | Repositorio inicial y documentación README creados. |
| T-02 | Credenciales de entorno | Variables de entorno y configuración inicial establecidas. |
| T-03 | Supabase Auth y roles | Autenticación y gestión inicial de roles implementadas. |
| T-04 | Endpoints API PostgreSQL | Endpoints principales de la API configurados. |
| T-05 | Modelo en PostgreSQL | Modelo inicial de datos para usuarios, médicos, especialidades y citas. |
| T-06 | Control anti-doble reserva | Validación para evitar que un horario sea reservado simultáneamente. |
| T-07 | UI Catálogo de especialidades | Pantalla para visualizar y seleccionar especialidades médicas. |
| T-08 | Supabase SDK en Flutter | SDK integrado en la aplicación Flutter. |
| T-09 | Pruebas de integración | Pruebas iniciales de comunicación entre aplicación, API y base de datos. |
| T-10 | Índices en PostgreSQL | Índices creados para mejorar consultas frecuentes. |
| T-11 | Capítulo I: Perfil del proyecto | Perfil del proyecto, metodología y requisitos (entrega E1). |
| T-12 | UI Flutter con Supabase | Pantallas principales integradas con la base de datos real. |
| T-13 | Perfil de usuario en API | Endpoint para consultar y administrar el perfil del usuario. |
| T-14 | Consulta y filtrado de citas | El paciente consulta y filtra sus citas por fecha, médico y estado. |
| T-15 | Historial y estado de reservas | Historial de citas y estados: pendiente, confirmada, atendida y cancelada. |
| T-16 | Comprobante de reserva | Comprobante con los datos de la cita y el número de reserva. |
| T-18 | Disponibilidad por médico | Horarios disponibles de cada profesional médico. |
| T-22 | Roles y autorización con RLS | Tres roles (paciente, profesional y administrador), funciones `rol_actual()` y `es_administrador()`, y políticas de seguridad por rol. Un disparador impide que el autorregistro se asigne un rol privilegiado. |
| T-23 | Notificaciones automáticas | Disparadores que generan avisos al registrar, confirmar, atender o cancelar una reserva. |
| T-24 | Reserva atómica y CRUD de reservas | Función `reservar_cita` en una sola transacción (sin `patient_id` desde el cliente), `cancelar_cita` que libera el bloque y cambio de estado autorizado por rol. |
| T-25 | Despliegue público | Frontend web publicado y verificado: <https://medireserva.vercel.app> |
| T-26 | Pruebas automatizadas con evidencia | 11 pruebas en Dart, 18 casos funcionales sobre PostgreSQL y análisis estático sin observaciones. |
| T-27 | Documento del E2 | Apartados 2.4, 2.5 y 2.6 redactados y correcciones del E1 aplicadas en el mismo archivo. |

---

## 🔄 EN CURSO — Límite: 2

| ID | Tarea | Estado |
|---|---|---|
| T-17 | Gestión de usuarios y roles | En desarrollo: la interfaz de administración de usuarios y roles. |
| T-20 | Publicación de reglas de reserva | En desarrollo: reglas visibles para reservar, cancelar y reprogramar. |

---

## 📋 BACKLOG — 1 tarea

| ID | Tarea | Descripción |
|---|---|---|
| T-19 | Persistencia local / Offline | Conservar información básica cuando no haya conexión. Pendiente de decisión de alcance: el apartado 2.1 del documento lo declara y el sistema todavía no lo implementa. |

---

## 🚫 FUERA DE ALCANCE (Won't have) — 1 tarea

| ID | Tarea | Justificación de la exclusión |
|---|---|---|
| T-21 | Geolocalización GPS | Se retiró del alcance para concentrar el esfuerzo en el flujo de reserva y en la integridad de los datos. |

---

## 📊 Resumen del tablero

| Estado | Cantidad | WIP |
|---|---|---|
| ✅ Hecho | 23 | — |
| 🔄 En curso | 2 | Máximo 2 |
| 📋 Backlog | 1 | — |
| 🚫 Fuera de alcance | 1 | — |
| **Total** | **27** | |

---

## 🎯 Flujo de trabajo

```text
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│     BACKLOG      │ ───► │     EN CURSO     │ ───► │      HECHO       │
│                  │      │                  │      │                  │
│      1 tarea     │      │  Máximo 2 tareas │      │    23 tareas     │
└──────────────────┘      └──────────────────┘      └──────────────────┘
                                   │
                                   ▼
                        ┌──────────────────────┐
                        │  FUERA DE ALCANCE    │
                        │     1 tarea          │
                        └──────────────────────┘
```

### Reglas del tablero

1. Las tareas nuevas ingresan inicialmente al **Backlog**.
2. Solo pueden existir **2 tareas simultáneamente en En Curso**.
3. Una tarea pasa a **Hecho** cuando cumple sus criterios de aceptación y ha sido verificada.
4. Cuando una tarea pasa a **Hecho**, se puede mover una nueva tarea del Backlog a **En Curso**.
5. Las tareas deben mantenerse vinculadas a los módulos funcionales o a la documentación correspondiente de MediReserva.
6. Una tarea puede pasar a **Fuera de alcance** por decisión de alcance, y en ese caso se declara con su justificación.

---

## 🏥 Módulos relacionados

- Autenticación y usuarios.
- Gestión de roles: paciente, profesional y administrador. El perfil de recepción opera con el rol de administrador, por lo que no constituye un rol independiente.
- Especialidades médicas.
- Gestión de médicos.
- Disponibilidad y horarios.
- Reservas de citas.
- Cancelación y reprogramación.
- Historial de citas.
- Notificaciones y confirmaciones.
- Perfil de usuario.
- Base de datos PostgreSQL / Supabase.
- Aplicación móvil y web con Flutter.
- API y servicios backend.
- Documentación del proyecto.

---

## 📝 Criterios generales para cerrar una tarea

Una tarea podrá pasar a **Hecho** cuando:

- [ ] La funcionalidad esté implementada.
- [ ] La información se almacene o consulte correctamente.
- [ ] Se hayan realizado las pruebas correspondientes.
- [ ] No existan errores críticos relacionados con la tarea.
- [ ] La documentación necesaria esté actualizada.
- [ ] El cambio esté registrado en el repositorio Git.

---

**Proyecto:** MediReserva
**Tablero:** Kanban
**Última actualización:** 25/09/2026
