import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'controllers/preferences_controller.dart';
import 'screens/auth_gate.dart';
import 'screens/setup_required_screen.dart';

class ProyectoFinalApp extends StatelessWidget {
  const ProyectoFinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final preferences = context.watch<PreferencesController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Proyecto Final MEDIRESERVA',
      themeMode: preferences.themeMode,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: config.hasSupabaseConfig
          ? const AuthGate()
          : const SetupRequiredScreen(),
    );
  }
}
