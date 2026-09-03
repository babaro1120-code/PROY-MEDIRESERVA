import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'widgets/medireserva_ui.dart';

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
