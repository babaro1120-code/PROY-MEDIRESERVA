import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medireserva/screens/cancel_appointment_dialog.dart';

/// Arma el mismo flujo que usan `appointments_screen` y `agenda_screen`:
/// preguntar y solo cancelar si el diálogo devuelve `true`.
Future<void> _montarPantallaDePrueba(
  WidgetTester tester,
  void Function() alCancelar,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final confirmado = await showCancelAppointmentDialog(
                  context,
                  fecha: 'Lunes, 24 de marzo de 2025',
                  hora: '09:30',
                  profesional: 'Dra. Ana Pérez',
                );
                if (!confirmado) return;
                alCancelar();
              },
              child: const Text('Cancelar'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Cancelar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el diálogo muestra la fecha, la hora y el profesional',
      (tester) async {
    await _montarPantallaDePrueba(tester, () {});

    expect(find.text('¿Cancelar la cita?'), findsOneWidget);
    expect(
      find.textContaining('Lunes, 24 de marzo de 2025 a las 09:30 con '
          'Dra. Ana Pérez'),
      findsOneWidget,
    );
    expect(find.textContaining('se libera el bloque horario'), findsOneWidget);
    expect(find.text('No, volver'), findsOneWidget);
    expect(find.text('Sí, cancelar'), findsOneWidget);
  });

  testWidgets('al elegir volver atrás no se cancela la cita', (tester) async {
    var cancelaciones = 0;
    await _montarPantallaDePrueba(tester, () => cancelaciones++);

    await tester.tap(find.text('No, volver'));
    await tester.pumpAndSettle();

    expect(cancelaciones, 0);
    expect(find.text('¿Cancelar la cita?'), findsNothing);
  });

  testWidgets('al cerrar el diálogo sin elegir no se cancela la cita',
      (tester) async {
    var cancelaciones = 0;
    await _montarPantallaDePrueba(tester, () => cancelaciones++);

    // Tocar fuera del diálogo lo cierra sin devolver `true`.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(cancelaciones, 0);
  });

  testWidgets('solo al confirmar se cancela la cita', (tester) async {
    var cancelaciones = 0;
    await _montarPantallaDePrueba(tester, () => cancelaciones++);

    await tester.tap(find.text('Sí, cancelar'));
    await tester.pumpAndSettle();

    expect(cancelaciones, 1);
  });
}
