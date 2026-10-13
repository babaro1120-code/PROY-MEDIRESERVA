import 'package:flutter/widgets.dart';

/// Aviso de "esta pestaña acaba de activarse".
///
/// [tick] crece con cada aviso, así que dos avisos seguidos de la misma pestaña
/// no son iguales: volver a tocar la pestaña que ya está abierta también sirve
/// para volver a pedir los datos.
@immutable
class PestanaSeleccionada {
  const PestanaSeleccionada({required this.clave, required this.tick});

  /// Clave del módulo, la misma que usa el menú del armazón (`inicio`, `agenda`,
  /// `citas`, `notificaciones`, ...).
  final String clave;

  /// Número de aviso, para distinguir un aviso del anterior.
  final int tick;
}

/// Publica la pestaña activa del armazón hacia las pantallas.
///
/// El armazón navega con un `IndexedStack`, así que las pantallas quedan
/// montadas y volver a una pestaña no las reconstruye: sin este aviso seguirían
/// mostrando los datos de la primera carga. Cada pantalla se registra leyendo
/// [de] desde `didChangeDependencies` y recarga cuando el aviso es suyo.
class PestanaActiva extends InheritedNotifier<ValueNotifier<PestanaSeleccionada>> {
  const PestanaActiva({
    super.key,
    required ValueNotifier<PestanaSeleccionada> super.notifier,
    required super.child,
  });

  /// Último aviso publicado, o `null` si la pantalla no está dentro del armazón.
  static PestanaSeleccionada? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PestanaActiva>()?.notifier?.value;
}

/// Decide si la pantalla de [clave] tiene que volver a pedir sus datos.
///
/// Es una función pura: se prueba sin red y sin interfaz en
/// `test/pestana_activa_test.dart`.
bool debeRecargarPorPestana({
  required PestanaSeleccionada? aviso,
  required String clave,
  required int? ultimoTick,
}) {
  // Fuera del armazón (por ejemplo, una pantalla empujada aparte) no hay aviso.
  if (aviso == null) return false;
  // Primera llamada: solo se deja constancia del aviso actual. Los datos ya los
  // pidió `initState`, así que recargar acá sería una consulta de más.
  if (ultimoTick == null) return false;
  return aviso.clave == clave && aviso.tick != ultimoTick;
}
