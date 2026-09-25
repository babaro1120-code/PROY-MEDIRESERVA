import 'package:flutter_test/flutter_test.dart';
// Se importa con prefijo porque este archivo tambien declara `main()`:
// sin el prefijo, la funcion local eclipsaria la de la aplicacion.
import 'package:medireserva/main.dart' as app;

void main() {
  testWidgets(
    'muestra el aviso de configuración cuando faltan SUPABASE_URL y la clave',
    (tester) async {
      // Sin --dart-define-from-file=config/local.json las variables de entorno
      // llegan vacías, por lo que la app debe mostrar la pantalla de aviso.
      await app.main();
      await tester.pumpAndSettle();

      expect(find.text('MediReserva necesita configuración'), findsOneWidget);
      expect(
        find.textContaining('SUPABASE_URL'),
        findsOneWidget,
      );
    },
  );
}
