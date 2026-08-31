import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'controllers/context_controller.dart';
import 'controllers/preferences_controller.dart';
import 'repositories/registro_repository.dart';
import 'repositories/supabase_registro_repository.dart';
import 'services/location_service.dart';
import 'services/preferences_service.dart';
import 'services/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final prefs = await SharedPreferences.getInstance();

  final preferencesController = PreferencesController(
    PreferencesService(prefs),
  );

  final providers = <SingleChildWidget>[
    Provider<AppConfig>.value(value: config),
    ChangeNotifierProvider<PreferencesController>.value(
      value: preferencesController,
    ),
  ];

  // Modo final: siempre Supabase cuando esta configurado.
  if (config.hasSupabaseConfig) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );

    providers.add(
      Provider<RegistroRepository>.value(
        value: SupabaseRegistroRepository(Supabase.instance.client),
      ),
    );
    providers.add(
      Provider<LocationService>(
        create: (providerContext) => const LocationService(),
      ),
    );
    providers.add(
      Provider<WeatherService>(
        create: (providerContext) => const WeatherService(),
      ),
    );
    providers.add(
      ChangeNotifierProvider<ContextController>(
        create: (providerContext) {
          return ContextController(
            locationService: providerContext.read<LocationService>(),
            weatherService: providerContext.read<WeatherService>(),
          );
        },
      ),
    );
  }

  runApp(MultiProvider(providers: providers, child: const ProyectoFinalApp()));
}
