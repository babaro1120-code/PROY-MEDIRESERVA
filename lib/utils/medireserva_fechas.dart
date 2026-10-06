/// Utilidades de fecha y hora compartidas por las pantallas y el servicio.
///
/// A propósito no se agrega `intl`: el proyecto no necesita traducciones ni
/// zonas horarias, y así no se toca el archivo de dependencias. Todo lo de este
/// archivo son funciones puras, por lo que se prueban sin red en
/// `test/medireserva_fechas_test.dart`.
library;

/// `YYYY-MM-DD`, el formato que espera una columna `date` de PostgreSQL.
String fechaIso(DateTime fecha) {
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}

/// `HH:MM` a partir de un valor que puede venir como `HH:MM` o `HH:MM:SS`.
///
/// La base devuelve las columnas `time` como `HH:MM:SS`, mientras que las
/// pantallas y los selectores de hora trabajan con `HH:MM`.
String horaCorta(String hora) {
  final limpio = hora.trim();
  return limpio.length >= 5 ? limpio.substring(0, 5) : limpio;
}

/// `HH:MM:SS`, el formato que espera una columna `time` de PostgreSQL.
String horaCompleta(String hora) {
  final partes = hora.trim().split(':');
  if (partes.length >= 3) return hora.trim();
  final hh = partes.isNotEmpty ? partes[0].padLeft(2, '0') : '00';
  final mm = partes.length > 1 ? partes[1].padLeft(2, '0') : '00';
  return '$hh:$mm:00';
}

/// Clave estable `fecha|hora` para cruzar bloques de disponibilidad con las
/// reservas que ya los ocuparon.
String claveBloque(DateTime fecha, String hora) =>
    '${fechaIso(fecha)}|${horaCorta(hora)}';

/// Fecha corta para mensajes de confirmación: `5/10/2026`.
String fechaCorta(DateTime fecha) => '${fecha.day}/${fecha.month}/${fecha.year}';

/// Fecha de formulario con día y mes de dos dígitos: `15/03/1990`.
///
/// Es el formato que se muestra en el campo de fecha de nacimiento y el que
/// vuelve a leer [fechaDesdeTexto].
String fechaDiaMesAnio(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/'
    '${fecha.year.toString().padLeft(4, '0')}';

/// Convierte a [DateTime] el texto de una fecha: `AAAA-MM-DD` (lo que devuelve
/// la columna `date`) o `DD/MM/AAAA` (lo que se escribe en el formulario).
///
/// Devuelve `null` cuando el texto está vacío: así es como se representa "sin
/// fecha" en un campo opcional. Si el texto no vacío no es una fecha real
/// lanza [FormatException] con el motivo en español, en lugar de dejar pasar
/// un valor que PostgreSQL rechazaría con `22007`/`22008` y que haría fallar
/// toda la sentencia.
DateTime? fechaDesdeTexto(String? texto) {
  final valor = (texto ?? '').trim();
  if (valor.isEmpty) return null;

  // Se admite la hora al final porque una columna `timestamp` (o un valor
  // copiado de otra pantalla) llega como `AAAA-MM-DDTHH:MM:SS`.
  final iso =
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T ].*)?$').firstMatch(valor);
  if (iso != null) {
    return _fechaReal(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
      valor,
    );
  }

  final local = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(valor);
  if (local != null) {
    return _fechaReal(
      int.parse(local.group(3)!),
      int.parse(local.group(2)!),
      int.parse(local.group(1)!),
      valor,
    );
  }

  throw FormatException(
    'La fecha "$valor" no es válida. Usá el formato DD/MM/AAAA.',
  );
}

/// `AAAA-MM-DD` a partir del texto de un formulario, o `null` si está vacío.
///
/// Es el único formato de fecha que se envía a la columna `date` de
/// PostgreSQL. Lanza [FormatException] si el texto no es una fecha real.
String? fechaIsoOpcional(String? texto) {
  final fecha = fechaDesdeTexto(texto);
  return fecha == null ? null : fechaIso(fecha);
}

/// Comprueba que el día exista en ese mes antes de aceptarlo.
///
/// [DateTime] normaliza los desbordes (el 31 de febrero se convierte en el 3 de
/// marzo), así que una fecha que vuelve distinta es una fecha inexistente.
DateTime _fechaReal(int anio, int mes, int dia, String original) {
  final fecha = DateTime(anio, mes, dia);
  if (fecha.year != anio || fecha.month != mes || fecha.day != dia) {
    throw FormatException('La fecha "$original" no existe en el calendario.');
  }
  return fecha;
}

/// Fecha legible para encabezados: `lunes 5 de octubre de 2026`.
String fechaLarga(DateTime fecha) =>
    '${diaSemana(fecha.weekday)} ${fecha.day} de ${mes(fecha.month)} de '
    '${fecha.year}';

/// Nombre del día de la semana a partir de [DateTime.weekday] (1 = lunes).
String diaSemana(int weekday) => const [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ][weekday - 1];

/// Nombre del mes a partir del número de mes (1 = enero).
String mes(int month) => const [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ][month - 1];

/// Convierte `HH:MM` (o `HH:MM:SS`) a minutos transcurridos desde la medianoche.
///
/// Devuelve `null` cuando el texto no es una hora válida del día.
int? minutosDelDia(String hora) {
  final partes = hora.trim().split(':');
  if (partes.length < 2) return null;
  final hh = int.tryParse(partes[0]);
  final mm = int.tryParse(partes[1]);
  if (hh == null || mm == null) return null;
  if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
  return hh * 60 + mm;
}

/// `HH:MM` a partir de minutos transcurridos desde la medianoche.
String horaDeMinutos(int minutos) {
  final hh = (minutos ~/ 60).toString().padLeft(2, '0');
  final mm = (minutos % 60).toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Bloques de [pasoMinutos] entre [desde] y [hasta], sin incluir [hasta].
///
/// Es lo que usa el administrador para publicar una jornada completa de un
/// médico de una sola vez. Valida el rango: si las horas no son válidas o el
/// final no es posterior al inicio, lanza [ArgumentError] con el motivo en
/// español, en lugar de publicar bloques silenciosamente incorrectos.
List<String> rangoDeHoras({
  required String desde,
  required String hasta,
  int pasoMinutos = 30,
}) {
  if (pasoMinutos <= 0) {
    throw ArgumentError('El intervalo debe ser de al menos un minuto.');
  }

  final inicio = minutosDelDia(desde);
  if (inicio == null) {
    throw ArgumentError('La hora de inicio "$desde" no es válida.');
  }

  final fin = minutosDelDia(hasta);
  if (fin == null) {
    throw ArgumentError('La hora de fin "$hasta" no es válida.');
  }

  if (fin <= inicio) {
    throw ArgumentError(
      'La hora de fin ($hasta) debe ser posterior a la de inicio ($desde).',
    );
  }

  final horas = <String>[];
  for (var minuto = inicio; minuto < fin; minuto += pasoMinutos) {
    horas.add(horaDeMinutos(minuto));
    // Tope de seguridad: una jornada razonable nunca pasa de 96 bloques.
    if (horas.length >= 96) break;
  }
  return horas;
}
