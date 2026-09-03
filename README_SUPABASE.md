# MediReserva + Supabase

Esta entrega agrega la capa de datos real para el flujo:

Inicio -> Reservar Cita -> Especialidad -> Médico -> Calendario -> Horario -> Confirmación -> Detalle

## 1. Base de datos

1. Abre el proyecto de Supabase.
2. Ve a **SQL Editor**.
3. Ejecuta `supabase/schema.sql`.
4. Comprueba que existan:
   - profiles
   - specialties
   - doctors
   - doctor_availability
   - appointments
   - notifications

El script activa RLS y crea las políticas básicas para que cada paciente solo pueda
leer/modificar sus propios datos.

## 2. Dart

Copia estos archivos dentro de tu proyecto:

- `lib/models/medireserva_models.dart`
- `lib/services/medireserva_service.dart`

La aplicación ya debe tener `supabase_flutter` porque el login existente usa
`Supabase.instance.client`.

## 3. Siguiente integración

Las pantallas actuales de la maqueta todavía muestran datos de demostración.
La integración final debe hacer que:

- Especialidades consulte `getSpecialties()`.
- Médicos consulte `getDoctorsBySpecialty()`.
- Horarios consulte `getAvailableTimes()`.
- Confirmación llame `createAppointment()`.
- Mis Citas consulte `getMyAppointments()`.
- Perfil consulte/actualice `getMyProfile()` y `updateMyProfile()`.
- Notificaciones consulte `getNotifications()`.

## 4. Importante

No coloques la `service_role` key en Flutter. En la aplicación móvil usa la URL
del proyecto y la `anon/publishable` key, y deja las reglas de seguridad en RLS.

## 5. Reserva segura

La base incluye un índice único parcial para evitar dos reservas activas para
el mismo médico, fecha y hora. La aplicación debe capturar el error de conflicto
y mostrar al usuario que ese horario acaba de ser ocupado.
