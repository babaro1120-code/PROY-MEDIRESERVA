import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'widgets/medireserva_ui.dart';

/// Idiomas que entiende la interfaz. El español va primero porque es el idioma
/// en el que se entrega la aplicación.
const List<Locale> kMediReservaLocales = <Locale>[Locale('es'), Locale('en')];

/// Delegados de localización que vienen con el SDK de Flutter (material,
/// widgets y Cupertino). Sin ellos el calendario de `showDatePicker`, los
/// tooltips y demás textos del sistema se muestran en inglés.
const List<LocalizationsDelegate<dynamic>> kMediReservaDelegados =
    <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  // Soporta el nombre nuevo (publishable) y el antiguo (anon) según la config.
  final key = publishableKey.isNotEmpty ? publishableKey : anonKey;

  if (url.isEmpty || key.isEmpty) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(url: url, publishableKey: key);
  runApp(const MediReservaApp());
}

class MediReservaApp extends StatelessWidget {
  const MediReservaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MediReserva',
        // Se fija el español para que el calendario y los textos del sistema no
        // dependan del idioma del navegador ni del teléfono.
        locale: const Locale('es'),
        supportedLocales: kMediReservaLocales,
        localizationsDelegates: kMediReservaDelegados,
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: kMediBlue),
            scaffoldBackgroundColor: kMediBg,
            fontFamily: 'Arial'),
        home: const AuthGate(),
      );
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: kMediReservaLocales,
      localizationsDelegates: kMediReservaDelegados,
      home: Scaffold(
        backgroundColor: kMediBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, color: kMediBlue, size:64.8),
                const SizedBox(height:18.2),
                const Text(
                  'MediReserva necesita configuración',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMediDark,
                    fontSize:28.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height:13),
                const Text(
                  'Ejecuta la aplicación proporcionando SUPABASE_URL y SUPABASE_ANON_KEY mediante --dart-define. Consulta README_INTEGRACION.md.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: kMediMuted, fontSize:19.2, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
