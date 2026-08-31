import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/preferences_controller.dart';
import '../widgets/max_width_box.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<PreferencesController>().name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();
    final config = context.watch<AppConfig>();

    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias')),
      body: MaxWidthBox(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                await preferences.setName(_nameController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nombre guardado localmente')),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
            const Divider(height: 32),
            SwitchListTile(
              value: preferences.darkMode,
              title: const Text('Tema oscuro'),
              subtitle: const Text('Persistencia local de Sesion 1'),
              onChanged: preferences.setDarkMode,
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.settings_input_component),
              title: Text('Modo: ${config.modeLabel}'),
            ),
          ],
        ),
      ),
    );
  }
}
