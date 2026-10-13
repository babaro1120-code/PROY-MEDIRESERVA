import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tabla cuyas altas, cambios y bajas se vigilan en vivo.
const String kTablaDeCitas = 'appointments';

/// Espera entre el último aviso recibido y la recarga que provoca.
///
/// Una ráfaga de cambios (crear, confirmar y cancelar casi al mismo tiempo)
/// tiene que producir una sola recarga y no una por evento.
const Duration kEsperaEntreRecargas = Duration(milliseconds: 250);

/// Agrupa varios pedidos de recarga seguidos en uno solo.
///
/// Es lógica pura (solo depende de un `Timer`), así que se prueba sin red en
/// `test/medireserva_realtime_test.dart`.
class AgrupadorDeCambios {
  AgrupadorDeCambios({this.espera = kEsperaEntreRecargas});

  /// Tiempo que hay que esperar, desde el último pedido, antes de recargar.
  final Duration espera;

  Timer? _temporizador;
  void Function()? _accion;

  /// `true` mientras haya una recarga pedida y todavía no ejecutada.
  bool get pendiente => _temporizador != null;

  /// Pide ejecutar [accion] cuando pase [espera] sin pedidos nuevos.
  ///
  /// Si ya había un pedido sin ejecutar, se reemplaza: el último es el que vale,
  /// porque todos piden lo mismo (volver a leer los datos).
  void pedir(void Function() accion) {
    _accion = accion;
    _temporizador?.cancel();
    _temporizador = Timer(espera, _ejecutar);
  }

  void _ejecutar() {
    final accion = _accion;
    _temporizador = null;
    _accion = null;
    accion?.call();
  }

  /// Descarta la recarga pedida. Se usa al salir de la pantalla.
  void cancelar() {
    _temporizador?.cancel();
    _temporizador = null;
    _accion = null;
  }
}

/// Suscripción en vivo a los cambios de las citas (`public.appointments`).
///
/// La pantalla que la usa no parchea la lista a mano: cuando la base avisa que
/// algo cambió, [onCambio] vuelve a pedir los datos (ver [AgrupadorDeCambios]).
///
/// Está escrita para ser **defensiva**: si el *realtime* no está disponible —por
/// ejemplo, porque `appointments` no está en la publicación
/// `supabase_realtime` de PostgreSQL, porque la política RLS no deja ver las
/// filas o porque no hay conexión— no se propaga ninguna excepción ni se rompe
/// la vista. La pantalla queda igual que antes del arreglo y todavía tiene el
/// gesto de actualizar y la recarga al volver a la pestaña.
class EscuchaDeCitas {
  EscuchaDeCitas({
    required this.onCambio,
    this.tabla = kTablaDeCitas,
    SupabaseClient? client,
    Duration espera = kEsperaEntreRecargas,
  })  : _client = client,
        _agrupador = AgrupadorDeCambios(espera: espera);

  /// Se llama —ya agrupada— cada vez que la tabla vigilada cambia.
  final void Function() onCambio;

  /// Tabla vigilada, dentro del esquema `public`.
  final String tabla;

  final SupabaseClient? _client;
  final AgrupadorDeCambios _agrupador;

  /// El nombre del canal tiene que ser único: dos pantallas del mismo usuario
  /// pueden estar escuchando la misma tabla a la vez (por ejemplo, la agenda y
  /// las citas del profesional) y el servidor rechaza el topic repetido.
  static int _instancias = 0;

  RealtimeChannel? _canal;

  /// `true` mientras la suscripción esté viva.
  bool get escuchando => _canal != null;

  /// Se suscribe a `INSERT`, `UPDATE` y `DELETE` de [tabla]. Nunca lanza.
  void suscribir() {
    if (_canal != null) return;
    RealtimeChannel? canal;
    try {
      final cliente = _client ?? Supabase.instance.client;
      canal = cliente.channel('medireserva-$tabla-${_instancias++}');

      canal.onPostgresChanges(
        // `all` cubre INSERT, UPDATE y DELETE en una sola suscripción.
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: tabla,
        callback: (_) => _agrupador.pedir(onCambio),
      );

      _canal = canal;
      canal.subscribe(_alCambiarEstado);
    } catch (error) {
      // Sin realtime la pantalla sigue funcionando con los datos que ya cargó.
      _canal = null;
      _agrupador.cancelar();
      debugPrint('MediReserva · sin suscripción en vivo a $tabla: $error');
      // El canal pudo quedar anotado en el cliente aunque no se haya unido.
      final huerfano = canal;
      if (huerfano != null) unawaited(_soltar(huerfano));
    }
  }

  /// El servidor de *realtime* contesta de forma asíncrona: si rechaza el canal
  /// (tabla fuera de la publicación, sin permisos, sin conexión) se suelta el
  /// canal y la pantalla se queda con los refrescos manuales.
  void _alCambiarEstado(RealtimeSubscribeStatus estado, Object? error) {
    if (estado == RealtimeSubscribeStatus.subscribed) return;
    debugPrint(
      'MediReserva · realtime de $tabla no disponible ($estado): $error',
    );
    final canal = _canal;
    _canal = null;
    _agrupador.cancelar();
    if (canal != null) unawaited(_soltar(canal));
  }

  /// Cancela la suscripción. Se llama desde `dispose`, para no acumular canales.
  Future<void> cancelar() async {
    _agrupador.cancelar();
    final canal = _canal;
    _canal = null;
    if (canal != null) await _soltar(canal);
  }

  Future<void> _soltar(RealtimeChannel canal) async {
    try {
      await (_client ?? Supabase.instance.client).removeChannel(canal);
    } catch (error) {
      // `removeChannel` ya desuscribe; si igual falla se intenta una vez más y
      // se ignora: cerrar la pantalla nunca puede fallar.
      try {
        await canal.unsubscribe();
      } catch (otroError) {
        debugPrint('MediReserva · no se pudo cerrar el canal de $tabla: '
            '$otroError');
      }
    }
  }
}
