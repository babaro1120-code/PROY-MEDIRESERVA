# Supabase

Si ya hiciste la Sesion 1:
ejecuta `supabase/02_MIGRACION_SESION2_CONTEXTO.sql`.

Si partes de cero:
1. `01_SCHEMA_BASE_SESION1.sql`
2. `02_MIGRACION_SESION2_CONTEXTO.sql`
3. `03_VERIFICAR.sql`

Configura:
- Project URL
- Publishable Key

Si al reservar una cita aparece el error 23503
("Key is not present in table profiles"), ejecuta
`supabase/04_REPARAR_PERFILES.sql`: recrea el trigger de perfiles,
autorrepara el perfil del usuario y arregla las cuentas antiguas.

Nunca:
- service_role
- secret key
