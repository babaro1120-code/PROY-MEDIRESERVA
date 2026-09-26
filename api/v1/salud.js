// ============================================================
// Ruta de salud publica de la API de MediReserva
// ------------------------------------------------------------
// Responde en   GET /api/v1/salud
//
// Que hace:
//   Reenvia la consulta a la funcion public.salud() de PostgreSQL, que
//   Supabase expone mediante PostgREST en /rest/v1/rpc/salud. Asi la ruta
//   sigue la convencion /api/v1/ del Modulo 4 sin depender de que el
//   cliente conozca las credenciales del proyecto.
//
// Credenciales:
//   Se leen de variables de entorno del proyecto en Vercel
//   (SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY). NO se guardan en el
//   repositorio: la clave de servicio (service_role) nunca se usa aqui.
//
// Despliegue:
//   Vercel detecta esta carpeta api/ y publica la funcion automaticamente
//   junto con el sitio estatico de build/web.
// ============================================================

module.exports = async (req, res) => {
  // Una ruta de salud solo se consulta con GET (o HEAD).
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.setHeader('Allow', 'GET, HEAD');
    return res.status(405).json({
      error: { codigo: 'METODO_NO_PERMITIDO', mensaje: 'Esta ruta solo admite GET.' },
    });
  }

  const url = process.env.SUPABASE_URL;
  const clave =
    process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_ANON_KEY;

  // Si faltan las variables de entorno, se informa con claridad en lugar de
  // fallar sin explicacion.
  if (!url || !clave) {
    return res.status(503).json({
      estado: 'error',
      servicio: 'MediReserva',
      error: {
        codigo: 'CONFIGURACION_AUSENTE',
        mensaje:
          'Faltan SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY en las variables de entorno del proyecto en Vercel.',
      },
    });
  }

  const base = url.replace(/\/+$/, '') + '/rest/v1/rpc/salud';

  try {
    const respuesta = await fetch(base, {
      headers: { apikey: clave, Authorization: 'Bearer ' + clave },
    });

    let datos = null;
    try {
      datos = await respuesta.json();
    } catch (_) {
      datos = null;
    }

    res.setHeader('Cache-Control', 'no-store');

    if (!respuesta.ok) {
      return res.status(503).json({
        estado: 'degradado',
        servicio: 'MediReserva',
        version: '1.0.0',
        ruta: '/api/v1/salud',
        error: {
          codigo: 'BASE_NO_RESPONDE',
          mensaje: 'El servicio de datos respondio con estado ' + respuesta.status + '.',
        },
      });
    }

    return res.status(200).json({
      estado: 'ok',
      servicio: 'MediReserva',
      version: '1.0.0',
      ruta: '/api/v1/salud',
      base_de_datos: datos,
    });
  } catch (error) {
    return res.status(503).json({
      estado: 'error',
      servicio: 'MediReserva',
      version: '1.0.0',
      ruta: '/api/v1/salud',
      error: {
        codigo: 'BASE_INALCANZABLE',
        mensaje: 'No se pudo contactar al servicio de datos.',
      },
    });
  }
};
