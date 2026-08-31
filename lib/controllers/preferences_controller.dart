import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

class PreferencesController extends ChangeNotifier {
  PreferencesController(this.service) {
    _darkMode = service.getDarkMode();
    _name = service.getName();
  }

  final PreferencesService service;

  bool _darkMode = false;
  String _name = '';

  bool get darkMode => _darkMode;
  String get name => _name;

  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    await service.setDarkMode(value);
  }

  Future<void> setName(String value) async {
    _name = value.trim();
    notifyListeners();
    await service.setName(_name);
  }
}
