# Monitoreo de la ruta de salud

El sistema desplegado se vigila con **monitoreo activo desde el propio
repositorio**, mediante GitHub Actions. No requiere ninguna cuenta externa, ni
servicio de pago, ni herramienta adicional: usa las funciones que GitHub ya
incluye para los repositorios públicos.

## 1. Qué se monitorea

Cada ejecución hace una petición `GET` a la ruta de salud pública y valida tres
condiciones:

| Comprobación | Valor esperado |
|---|---|
| Código HTTP | `200` |
| `estado` (servicio) | `ok` |
| `base_de_datos.estado` | `ok` |

La ruta consultada es <https://medireserva.vercel.app/api/v1/salud>. Como se
valida `base_de_datos.estado`, el monitoreo cubre también el enlace con Supabase:
si la base deja de responder, la ruta lo refleja y la ejecución falla.

## 2. Cada cuánto se ejecuta

- **Automáticamente cada 15 minutos**, con la expresión cron `*/15 * * * *`.
- **A mano**, cuando se quiera, desde *Actions → Salud → Run workflow*.

GitHub ejecuta el cron en **hora UTC** y puede demorar algunos minutos respecto
de la hora programada cuando la plataforma está cargada. Esa demora es normal y
no indica un problema del sistema.

## 3. Dónde se ve el historial

En la pestaña **Actions** del repositorio, workflow **«Salud»**:

<https://github.com/babaro1120-code/PROY-MEDIRESERVA/actions/workflows/salud.yml>

Cada ejecución deja un **resumen** en su propio panel con la fecha y la hora en
UTC, el código HTTP, el estado del servicio, el estado de la base de datos, la
latencia medida en milisegundos y el cuerpo completo de la respuesta. Lo mismo
queda en el registro de la consola.

## 4. Qué significa que falle

Si el código no es `200`, o si `estado` o `base_de_datos.estado` no son `ok`, el
**job termina en rojo** y queda registrado en el historial; además, el badge del
README cambia a rojo. El resumen de esa ejecución enumera los fallos detectados.

El badge del encabezado del README refleja el estado de la última ejecución:

```markdown
![Estado de la ruta de salud](https://github.com/babaro1120-code/PROY-MEDIRESERVA/actions/workflows/salud.yml/badge.svg)
```

## 5. Archivos y alcance

| Archivo | Función |
|---|---|
| `.github/workflows/salud.yml` | Define el disparador, la petición y la validación |
| `docs/MONITOREO.md` | Esta explicación |
| `README.md` | Muestra el badge y remite aquí |

El workflow no usa secretos ni credenciales, porque la ruta de salud es pública:
solo consulta y valida, nunca modifica datos del sistema. Está implementado con
el Node.js que ya trae la imagen del runner, de modo que no instala dependencias.

## 6. Limitación a tener en cuenta

GitHub **desactiva los workflows programados tras 60 días sin actividad en el
repositorio**. Si el badge deja de actualizarse y la pestaña *Actions* no muestra
ejecuciones nuevas, hay que volver a habilitar el workflow con el botón
*Enable workflow*; cualquier `push` a la rama principal también reinicia ese
contador de inactividad.
