import 'package:flutter_test/flutter_test.dart';
import 'package:medireserva/utils/medireserva_fechas.dart';

/// Pruebas de las utilidades de fecha y hora que usan el servicio y el panel.
///
/// Son funciones puras: no tocan la red ni Supabase.
void main() {
  group('fechaIso', () {
    test('rellena mes y día con dos dígitos', () {
      expect(fechaIso(DateTime(2026, 1, 5)), '2026-01-05');
      expect(fechaIso(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('ignora la hora del día', () {
      expect(fechaIso(DateTime(2026, 10, 5, 23, 59)), '2026-10-05');
    });
  });

  group('horaCorta y horaCompleta', () {
    test('horaCorta recorta los segundos que devuelve PostgreSQL', () {
      expect(horaCorta('09:30:00'), '09:30');
    });

    test('horaCorta deja intacto un valor que ya viene en HH:MM', () {
      expect(horaCorta('09:30'), '09:30');
    });

    test('horaCompleta agrega los segundos que espera la columna time', () {
      expect(horaCompleta('09:30'), '09:30:00');
    });

    test('horaCompleta respeta un valor que ya trae los segundos', () {
      expect(horaCompleta('09:30:15'), '09:30:15');
    });

    test('horaCompleta completa las partes que faltan', () {
      expect(horaCompleta('9'), '09:00:00');
    });
  });

  group('claveBloque', () {
    test('combina la fecha y la hora en una clave estable', () {
      expect(claveBloque(DateTime(2026, 10, 5), '09:30:00'), '2026-10-05|09:30');
    });

    test('la misma fecha y hora producen siempre la misma clave', () {
      expect(
        claveBloque(DateTime(2026, 10, 5, 8), '09:30:00'),
        claveBloque(DateTime(2026, 10, 5, 17), '09:30:00'),
      );
    });
  });

  group('textos de fecha', () {
    test('fechaCorta usa el formato día/mes/año', () {
      expect(fechaCorta(DateTime(2026, 10, 5)), '5/10/2026');
    });

    test('fechaLarga escribe el día de la semana y el mes en español', () {
      // El 1 de enero de 2026 cae jueves.
      expect(fechaLarga(DateTime(2026, 1, 1)), 'jueves 1 de enero de 2026');
      // El 5 de octubre de 2026 cae lunes.
      expect(fechaLarga(DateTime(2026, 10, 5)), 'lunes 5 de octubre de 2026');
    });
  });

  group('fechaDiaMesAnio', () {
    test('escribe el día y el mes con dos dígitos', () {
      expect(fechaDiaMesAnio(DateTime(1990, 3, 15)), '15/03/1990');
      expect(fechaDiaMesAnio(DateTime(2026, 10, 5)), '05/10/2026');
    });

    test('completa el año con cuatro dígitos', () {
      expect(fechaDiaMesAnio(DateTime(945, 1, 2)), '02/01/0945');
    });
  });

  group('fechaDesdeTexto', () {
    test('lee el formato ISO que devuelve la columna date', () {
      expect(fechaDesdeTexto('1990-03-15'), DateTime(1990, 3, 15));
    });

    test('lee el formato del formulario DD/MM/AAAA', () {
      expect(fechaDesdeTexto('15/03/1990'), DateTime(1990, 3, 15));
      // Sin ceros: el 5 de marzo, no el 15.
      expect(fechaDesdeTexto('5/3/1990'), DateTime(1990, 3, 5));
    });

    test('acepta un valor ISO con hora', () {
      expect(
        fechaDesdeTexto('1990-03-15T00:00:00.000Z'),
        DateTime(1990, 3, 15),
      );
    });

    test('ignora los espacios de alrededor', () {
      expect(fechaDesdeTexto('  1990-03-15 '), DateTime(1990, 3, 15));
    });

    test('devuelve null cuando el campo está vacío', () {
      expect(fechaDesdeTexto(''), isNull);
      expect(fechaDesdeTexto('   '), isNull);
      expect(fechaDesdeTexto(null), isNull);
    });

    test('rechaza un texto que no es una fecha', () {
      expect(() => fechaDesdeTexto('ayer'), throwsFormatException);
      expect(() => fechaDesdeTexto('15-03-1990'), throwsFormatException);
      expect(() => fechaDesdeTexto('1990'), throwsFormatException);
      expect(() => fechaDesdeTexto('15/03/90'), throwsFormatException);
    });

    test('rechaza una fecha que no existe en el calendario', () {
      expect(() => fechaDesdeTexto('31/02/1990'), throwsFormatException);
      expect(() => fechaDesdeTexto('1990-02-31'), throwsFormatException);
      expect(() => fechaDesdeTexto('15/13/1990'), throwsFormatException);
      expect(() => fechaDesdeTexto('1990-00-10'), throwsFormatException);
    });

    test('el error explica el problema en español', () {
      expect(
        () => fechaDesdeTexto('ayer'),
        throwsA(isA<FormatException>().having((e) => e.message, 'mensaje',
            contains('no es válida'))),
      );
      expect(
        () => fechaDesdeTexto('31/02/1990'),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'mensaje', contains('no existe'))),
      );
    });
  });

  group('fechaIsoOpcional', () {
    test('normaliza el formato del formulario a ISO', () {
      expect(fechaIsoOpcional('15/03/1990'), '1990-03-15');
      expect(fechaIsoOpcional('5/3/1990'), '1990-03-05');
    });

    test('deja pasar un valor que ya está en ISO', () {
      expect(fechaIsoOpcional('1990-03-15'), '1990-03-15');
      expect(fechaIsoOpcional('1990-3-5'), '1990-03-05');
    });

    test('devuelve null cuando no hay fecha', () {
      expect(fechaIsoOpcional(''), isNull);
      expect(fechaIsoOpcional('   '), isNull);
      expect(fechaIsoOpcional(null), isNull);
    });

    test('no deja pasar una fecha inexistente hacia la base', () {
      expect(() => fechaIsoOpcional('31/02/1990'), throwsFormatException);
      expect(() => fechaIsoOpcional('1990-02-31'), throwsFormatException);
    });
  });

  group('minutosDelDia', () {
    test('convierte HH:MM a minutos desde la medianoche', () {
      expect(minutosDelDia('00:00'), 0);
      expect(minutosDelDia('09:30'), 570);
      expect(minutosDelDia('23:59'), 1439);
    });

    test('acepta también el formato con segundos', () {
      expect(minutosDelDia('09:30:00'), 570);
    });

    test('devuelve null cuando la hora no es válida', () {
      expect(minutosDelDia('24:00'), isNull);
      expect(minutosDelDia('09:70'), isNull);
      expect(minutosDelDia('abc'), isNull);
      expect(minutosDelDia('09'), isNull);
    });
  });

  group('horaDeMinutos', () {
    test('vuelve de minutos a HH:MM con dos dígitos', () {
      expect(horaDeMinutos(0), '00:00');
      expect(horaDeMinutos(570), '09:30');
      expect(horaDeMinutos(1439), '23:59');
    });
  });

  group('rangoDeHoras', () {
    test('genera los bloques cada 30 minutos, sin incluir el final', () {
      expect(
        rangoDeHoras(desde: '08:00', hasta: '10:00', pasoMinutos: 30),
        ['08:00', '08:30', '09:00', '09:30'],
      );
    });

    test('genera los bloques cada 60 minutos', () {
      expect(
        rangoDeHoras(desde: '08:00', hasta: '12:00', pasoMinutos: 60),
        ['08:00', '09:00', '10:00', '11:00'],
      );
    });

    test('un rango de una sola hora produce un único bloque', () {
      expect(
        rangoDeHoras(desde: '15:00', hasta: '15:30'),
        ['15:00'],
      );
    });

    test('rechaza un rango invertido', () {
      expect(
        () => rangoDeHoras(desde: '10:00', hasta: '08:00'),
        throwsArgumentError,
      );
    });

    test('rechaza el rango en el que el fin es igual al inicio', () {
      expect(
        () => rangoDeHoras(desde: '08:00', hasta: '08:00'),
        throwsArgumentError,
      );
    });

    test('rechaza horas que no existen en el día', () {
      expect(
        () => rangoDeHoras(desde: '25:00', hasta: '26:00'),
        throwsArgumentError,
      );
      expect(
        () => rangoDeHoras(desde: '08:00', hasta: 'ocho'),
        throwsArgumentError,
      );
    });

    test('rechaza un intervalo inválido', () {
      expect(
        () => rangoDeHoras(desde: '08:00', hasta: '12:00', pasoMinutos: 0),
        throwsArgumentError,
      );
    });
  });
}
