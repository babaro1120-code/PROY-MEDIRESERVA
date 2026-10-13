import 'package:flutter_test/flutter_test.dart';
import 'package:medireserva/services/medireserva_realtime.dart';
import 'package:medireserva/widgets/pestana_activa.dart';

/// Pruebas de la lógica pura del arreglo de actualización de citas.
///
/// No tocan la red ni Supabase: solo el agrupador de recargas y la decisión de
/// recargar al entrar a una pestaña.
void main() {
  group('AgrupadorDeCambios', () {
    test('ejecuta la recarga pedida cuando pasa la espera', () async {
      var recargas = 0;
      final agrupador =
          AgrupadorDeCambios(espera: const Duration(milliseconds: 10));
      addTearDown(agrupador.cancelar);

      agrupador.pedir(() => recargas++);
      expect(agrupador.pendiente, isTrue);
      expect(recargas, 0, reason: 'todavía no pasó la espera');

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(recargas, 1);
      expect(agrupador.pendiente, isFalse);
    });

    test('una ráfaga de cambios produce una sola recarga', () async {
      var recargas = 0;
      final agrupador =
          AgrupadorDeCambios(espera: const Duration(milliseconds: 40));
      addTearDown(agrupador.cancelar);

      for (var i = 0; i < 5; i++) {
        agrupador.pedir(() => recargas++);
      }

      await Future<void>.delayed(const Duration(milliseconds: 140));

      expect(recargas, 1);
    });

    test('si se piden dos acciones distintas, gana la última', () async {
      final ejecutadas = <String>[];
      final agrupador =
          AgrupadorDeCambios(espera: const Duration(milliseconds: 20));
      addTearDown(agrupador.cancelar);

      agrupador.pedir(() => ejecutadas.add('primera'));
      agrupador.pedir(() => ejecutadas.add('segunda'));

      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(ejecutadas, ['segunda']);
    });

    test('dos cambios separados producen dos recargas', () async {
      var recargas = 0;
      final agrupador =
          AgrupadorDeCambios(espera: const Duration(milliseconds: 10));
      addTearDown(agrupador.cancelar);

      agrupador.pedir(() => recargas++);
      await Future<void>.delayed(const Duration(milliseconds: 70));
      agrupador.pedir(() => recargas++);
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(recargas, 2);
    });

    test('cancelar descarta la recarga pedida', () async {
      var recargas = 0;
      final agrupador =
          AgrupadorDeCambios(espera: const Duration(milliseconds: 10));
      addTearDown(agrupador.cancelar);

      agrupador.pedir(() => recargas++);
      agrupador.cancelar();

      expect(agrupador.pendiente, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(recargas, 0);
    });
  });

  group('debeRecargarPorPestana', () {
    const aviso = PestanaSeleccionada(clave: 'agenda', tick: 3);

    test('sin aviso (pantalla fuera del armazón) no recarga', () {
      expect(
        debeRecargarPorPestana(
            aviso: null, clave: 'agenda', ultimoTick: 2),
        isFalse,
      );
    });

    test('en el primer registro no recarga: ya lo hizo initState', () {
      expect(
        debeRecargarPorPestana(
            aviso: aviso, clave: 'agenda', ultimoTick: null),
        isFalse,
      );
    });

    test('recarga cuando el aviso es de su pestaña y es nuevo', () {
      expect(
        debeRecargarPorPestana(
            aviso: aviso, clave: 'agenda', ultimoTick: 2),
        isTrue,
      );
    });

    test('no recarga si el aviso es de otra pestaña', () {
      expect(
        debeRecargarPorPestana(
            aviso: aviso, clave: 'citas', ultimoTick: 2),
        isFalse,
      );
    });

    test('no vuelve a recargar por el mismo aviso', () {
      expect(
        debeRecargarPorPestana(
            aviso: aviso, clave: 'agenda', ultimoTick: 3),
        isFalse,
      );
    });

    test('tocar la pestaña ya abierta recarga de nuevo', () {
      // El armazón publica un `tick` nuevo aunque la clave no cambie.
      const repetido = PestanaSeleccionada(clave: 'agenda', tick: 4);
      expect(
        debeRecargarPorPestana(
            aviso: repetido, clave: 'agenda', ultimoTick: 3),
        isTrue,
      );
    });
  });
}
