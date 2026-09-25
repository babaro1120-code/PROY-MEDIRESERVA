# MediReserva — autenticación y navegación de extremo a extremo

Esta entrega adapta el proyecto para que el arranque sea:

**Supabase → AuthGate → Login → Registro/Recuperación → Home → Reserva**.

## 1. Configurar Supabase

En Supabase ejecuta primero:

`supabase/schema.sql`

Ese script crea `profiles`, `specialties`, `doctors`, `doctor_availability`, `appointments` y `notifications`, además de RLS y el trigger para crear el perfil al registrarse.

## 2. Ejecutar Flutter

No pongas claves directamente en el código. Usa variables de compilación:

```bash
flutter pub get
flutter run \\
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \\
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_O_PUBLISHABLE_KEY \\
  --dart-define=SUPABASE_REDIRECT_URL=io.medireserva://login-callback/
```

Para producción usa el mecanismo seguro de configuración de tu plataforma/CI y nunca la `service_role` key en la aplicación.

## 3. Registro

`RegisterScreen` llama a `supabase.auth.signUp()` con:

- correo
- contraseña
- `full_name` en metadata

El trigger `handle_new_user()` crea automáticamente la fila correspondiente en `profiles`.

Si Supabase tiene activada la confirmación de correo, el usuario debe confirmar el email antes de entrar.

## 4. Inicio de sesión

`LoginScreen` llama a `signInWithPassword()`. `AuthGate` escucha `onAuthStateChange` y muestra automáticamente:

- `LoginScreen` sin sesión
- `HomeScreen` con sesión
- `UpdatePasswordScreen` durante `passwordRecovery`

Por tanto, no es necesario navegar manualmente al Home después del login.

## 5. Recuperar contraseña

`RecoveryScreen` usa `resetPasswordForEmail()`.

El enlace del correo debe devolver a la aplicación con el deep link configurado en `SUPABASE_REDIRECT_URL` y permitido en Supabase.

### Android

Registra el esquema `io.medireserva` en `android/app/src/main/AndroidManifest.xml` mediante un `intent-filter` para `VIEW`, `DEFAULT` y `BROWSABLE`, con `scheme=io.medireserva` y `host=login-callback`.

### iOS

Registra el URL Scheme `io.medireserva` en la configuración de la aplicación (URL Types).

En Supabase agrega la misma URL a **Authentication → URL Configuration → Redirect URLs**.

## 6. Navegación

El Home ya queda conectado a:

- Reservar Cita → `ReservationStartScreen`
- Mis Citas → `AppointmentsScreen`
- Perfil → `ProfileScreen`
- Notificaciones → `NotificationsScreen`
- Cerrar sesión → Supabase Auth

El flujo de reserva conserva los IDs reales de especialidad y médico y termina en `createAppointment()`.

## 7. Punto de prueba

Después de ejecutar el SQL y arrancar la app:

1. Registra un usuario.
2. Confirma el correo si Supabase lo solicita.
3. Inicia sesión.
4. Comprueba que aparece el nombre del perfil.
5. Pulsa **Reservar Cita**.
6. Selecciona especialidad.
7. Selecciona médico.
8. Selecciona fecha.
9. Selecciona horario.
10. Confirma.
11. Comprueba la cita en **Mis Citas**.
12. Cierra sesión y confirma que vuelve a Login.

## 8. Nota sobre recuperación

Para probar recuperación desde un teléfono/emulador real, el deep link debe estar registrado en Android/iOS. En web puede usarse una URL HTTPS de la aplicación en lugar del esquema móvil.

## 9. Solución de problemas

### Error 23503 al confirmar una cita

```
PostgrestException(message: insert or update on table "appointments" violates
foreign key constraint "appointments_patient_id_fkey", code: 23503,
details: Key is not present in table "profiles".)
```

Ocurre cuando la cuenta existe en `auth.users` pero **no tiene fila en `public.profiles`**
(pasa con cuentas registradas antes de ejecutar `supabase/schema.sql`, o si el trigger
`on_auth_user_created` no estaba creado). Como `appointments.patient_id` es clave foránea a
`profiles(id)`, el insert se rechaza.

Solución:

1. Ejecuta `supabase/04_REPARAR_PERFILES.sql` en el SQL Editor de Supabase.
   Recrea el trigger, habilita la autorreparación desde la app y rellena los perfiles
   faltantes. La última consulta del script debe devolver **0 filas**.
2. Reintenta la reserva. La app además llama a `MediReservaService.ensureProfile()` antes
   de crear la cita, por lo que el perfil se crea solo si faltara (requiere la política
   `profiles_insert_own` incluida en `schema.sql` y en el script de reparación).
