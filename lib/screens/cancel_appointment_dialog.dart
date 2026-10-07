import 'package:flutter/material.dart';

/// Pregunta antes de cancelar una cita.
///
/// Cancelar es destructivo: libera el bloque horario, otro paciente puede
/// tomarlo y no se puede deshacer. Por eso la pantalla que llama a este
/// diálogo solo debe continuar cuando el resultado es `true`; cerrarlo sin
/// elegir (tocando fuera o con el botón atrás del sistema) devuelve `false` y
/// la cita queda intacta.
///
/// [fecha], [hora] y [profesional] son los datos que la pantalla ya tiene a
/// mano para mostrarle al usuario qué cita está por cancelar.
Future<bool> showCancelAppointmentDialog(
  BuildContext context, {
  required String fecha,
  required String hora,
  required String profesional,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Cancelar la cita?'),
      content: Text(
        'Cita del $fecha a las $hora con $profesional.\n\n'
        'Al cancelar se libera el bloque horario para que otro paciente pueda '
        'reservarlo. Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No, volver'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sí, cancelar'),
        ),
      ],
    ),
  );
  return confirmado == true;
}
