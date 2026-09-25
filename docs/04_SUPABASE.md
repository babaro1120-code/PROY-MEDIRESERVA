# Supabase

Único modo de funcionamiento del proyecto: no existe modo DEMO.

## Orden de ejecución de los scripts

En **Supabase → SQL Editor**, uno por uno:

1. `schema.sql` — tablas, RLS, disparador de perfil y datos iniciales.
2. `04_REPARAR_PERFILES.sql` — repara las cuentas sin fila en `profiles`
   (es la causa del error 23503 al reservar).
3. `05_ROLES_Y_RLS.sql` — columna `role`, funciones de autorización y políticas
   por rol. Incluye el bloqueo que impide que el autorregistro se asigne un rol
   privilegiado.
4. `06_NOTIFICACIONES.sql` — disparadores que generan las notificaciones.
5. `07_RESERVAS_RPC.sql` — función `reservar_cita` (reserva atómica),
   `cancelar_cita` y `cambiar_estado_reserva`.
6. `08_ELIMINAR_MODULO_DEMO.sql` — elimina la tabla `registros_demo` del aula.

Todos son idempotentes y terminan con consultas de verificación.

## Nombrar al primer administrador

El autorregistro siempre crea la cuenta con rol `paciente`. Para habilitar un
administrador, regístralo desde la app y después ejecuta en el SQL Editor:

```sql
update public.profiles
   set role = 'administrador'
 where email = 'el-correo-del-admin@dominio.test';
```

Para vincular un profesional con su cuenta, de modo que vea su propia agenda:

```sql
update public.doctors d
   set profile_id = p.id
  from public.profiles p
 where p.email = 'el-correo-del-profesional@dominio.test'
   and d.name = 'Dra. Ana López';
```

## Configuración del cliente

Crea `config/local.json` a partir de `config/local.example.json` con la URL del
proyecto y la clave publicable. Ese archivo está en `.gitignore`.

```powershell
flutter run --dart-define-from-file=config/local.json
```

## Producción

Después de publicar el frontend, agrega su dirección en
**Authentication → URL Configuration** (Site URL y Redirect URLs). Sin ese paso,
el inicio de sesión y la recuperación de contraseña no funcionan en el dominio
público.

## Nunca

- `service_role` ni secret keys dentro de la aplicación o del APK.
- Credenciales en el repositorio o en su historial.
- Datos personales reales en capturas o pruebas: solo datos ficticios.
