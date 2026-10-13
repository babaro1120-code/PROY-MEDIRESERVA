import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medireserva/widgets/pestana_activa.dart';

/// Comprueba el mecanismo que usa el armazón para avisar a las pantallas que
/// una pestaña quedó visible. Es lo que permite recargar al cambiar de pestaña
/// aunque el contenido viva en un `IndexedStack`.
void main() {
  testWidgets('la pantalla recibe el aviso cuando cambia la pestaña',
      (tester) async {
    final notifier = ValueNotifier(
      const PestanaSeleccionada(clave: 'inicio', tick: 0),
    );
    addTearDown(notifier.dispose);

    await tester.pumpWidget(
      PestanaActiva(notifier: notifier, child: const _PantallaDePrueba()),
    );

    expect(find.text('inicio:0'), findsOneWidget);

    notifier.value = const PestanaSeleccionada(clave: 'agenda', tick: 1);
    await tester.pump();

    expect(find.text('agenda:1'), findsOneWidget);
  });

  testWidgets('fuera del armazón la pantalla no recibe ningún aviso',
      (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: _PantallaDePrueba(),
    ));

    expect(find.text('sin aviso'), findsOneWidget);
  });
}

/// Pantalla mínima: solo muestra el aviso de pestaña que recibe.
class _PantallaDePrueba extends StatelessWidget {
  const _PantallaDePrueba();

  @override
  Widget build(BuildContext context) {
    final aviso = PestanaActiva.de(context);
    return Text(
      aviso == null ? 'sin aviso' : '${aviso.clave}:${aviso.tick}',
      textDirection: TextDirection.ltr,
    );
  }
}
