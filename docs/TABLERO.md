# Tablero de tareas MediReserva --- GitHub Projects (Kanban)

**Proyecto:** MediReserva\
**Tipo:** Aplicación web y móvil para reservas médicas\
**Metodología:** Kanban\
**Límite de trabajo en curso (WIP):** 2 tareas

------------------------------------------------------------------------

## 📋 BACKLOG --- 8 tareas

  -----------------------------------------------------------------------
  ID                      Tarea                   Descripción
  ----------------------- ----------------------- -----------------------
  T-14                    Consulta y filtrado de  Permitir al paciente
                          citas                   consultar y filtrar sus
                                                  citas por fecha, médico
                                                  y estado.

  T-17                    Gestión de usuarios y   Administrar pacientes,
                          roles                   recepcionistas, médicos
                                                  y administradores según
                                                  sus permisos.

  T-20                    Publicación de reglas   Definir y mostrar
                          de reserva              reglas para reservar,
                                                  cancelar y reprogramar
                                                  citas.

  T-15                    Historial y estado de   Mostrar el historial de
                          reservas                citas y estados como
                                                  pendiente, confirmada,
                                                  atendida o cancelada.

  T-16                    Comprobante de reserva  Generar y visualizar un
                                                  comprobante con los
                                                  datos de la cita
                                                  médica.

  T-18                    Disponibilidad por      Mostrar los horarios
                          médico                  disponibles de cada
                                                  profesional médico.

  T-19                    Persistencia local /    Permitir conservar
                          Offline                 información básica de
                                                  la aplicación cuando no
                                                  exista conexión.

  T-21                    Geolocalización GPS     Incorporar ubicación
                                                  para facilitar la
                                                  localización del centro
                                                  médico.
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 🔄 EN CURSO --- Límite: 2

  -----------------------------------------------------------------------
  ID                      Tarea                   Estado
  ----------------------- ----------------------- -----------------------
  T-12                    UI Flutter con Supabase En desarrollo ---
                                                  integración de las
                                                  pantallas principales
                                                  con Supabase.

  T-11                    Capítulo I: Perfil del  En desarrollo ---
                          proyecto, metodología y documentación académica
                          requisitos              del proyecto
                                                  MediReserva.
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## ✅ HECHO --- 11 tareas

  -----------------------------------------------------------------------
  ID                      Tarea                   Resultado
  ----------------------- ----------------------- -----------------------
  T-03                    Supabase Auth y roles   Autenticación y gestión
                                                  inicial de roles
                                                  implementadas.

  T-04                    Endpoints API           Endpoints principales
                          PostgreSQL              de la API configurados.

  T-05                    Modelo en PostgreSQL    Modelo inicial de datos
                                                  para usuarios, médicos,
                                                  especialidades y citas.

  T-08                    Supabase SDK en Flutter SDK integrado en la
                                                  aplicación Flutter.

  T-09                    Pruebas de integración  Pruebas iniciales de
                                                  comunicación entre
                                                  aplicación, API y base
                                                  de datos.

  T-10                    Índices en PostgreSQL   Índices creados para
                                                  mejorar consultas
                                                  frecuentes.

  T-13                    Perfil de usuario en    Endpoint para consultar
                          API                     y administrar el perfil
                                                  del usuario.

  T-01                    Repositorio y README    Repositorio inicial y
                                                  documentación README
                                                  creados.

  T-02                    Credenciales de entorno Variables de entorno y
                                                  configuración inicial
                                                  establecidas.

  T-06                    Control anti-doble      Validación para evitar
                          reserva                 que un horario sea
                                                  reservado
                                                  simultáneamente.

  T-07                    UI Catálogo de          Pantalla para
                          especialidades          visualizar y
                                                  seleccionar
                                                  especialidades médicas.
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 📊 Resumen del tablero

  Estado          Cantidad        WIP
  ------------- ---------- ----------
  📋 Backlog             8        ---
  🔄 En curso            2   Máximo 2
  ✅ Hecho              11        ---
  **Total**         **21** 

------------------------------------------------------------------------

## 🎯 Flujo de trabajo

``` text
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│     BACKLOG      │ ───► │     EN CURSO     │ ───► │      HECHO       │
│                  │      │                  │      │                  │
│      8 tareas    │      │  Máximo 2 tareas │      │    11 tareas     │
└──────────────────┘      └──────────────────┘      └──────────────────┘
```

### Reglas del tablero

1.  Las tareas nuevas ingresan inicialmente al **Backlog**.
2.  Solo pueden existir **2 tareas simultáneamente en En Curso**.
3.  Una tarea pasa a **Hecho** cuando cumple sus criterios de aceptación
    y ha sido verificada.
4.  Cuando una tarea pasa a **Hecho**, se puede mover una nueva tarea
    del Backlog a **En Curso**.
5.  Las tareas deben mantenerse vinculadas a los módulos funcionales o
    documentación correspondiente de MediReserva.

------------------------------------------------------------------------

## 🏥 Módulos relacionados

-   Autenticación y usuarios.
-   Gestión de roles: paciente, administrador, recepcionista y
    profesional médico.
-   Especialidades médicas.
-   Gestión de médicos.
-   Disponibilidad y horarios.
-   Reservas de citas.
-   Cancelación y reprogramación.
-   Historial de citas.
-   Notificaciones y confirmaciones.
-   Perfil de usuario.
-   Base de datos PostgreSQL/Supabase.
-   Aplicación móvil Flutter.
-   API y servicios backend.
-   Documentación del proyecto.

------------------------------------------------------------------------

## 📝 Criterios generales para cerrar una tarea

Una tarea podrá pasar a **Hecho** cuando:

-   [ ] La funcionalidad esté implementada.
-   [ ] La información se almacene o consulte correctamente.
-   [ ] Se hayan realizado las pruebas correspondientes.
-   [ ] No existan errores críticos relacionados con la tarea.
-   [ ] La documentación necesaria esté actualizada.
-   [ ] El cambio esté registrado en el repositorio Git.

------------------------------------------------------------------------

**Proyecto:** MediReserva\
**Tablero:** Kanban\
**Última actualización:** 24/09/2026
