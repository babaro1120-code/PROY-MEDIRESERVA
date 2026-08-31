import 'package:flutter/foundation.dart';

import '../models/context_snapshot.dart';
import '../models/weather_snapshot.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

enum ContextStatus { idle, loadingLocation, loadingApi, ready, error }

enum LastAction { none, tarijaApi, gpsApi, controlledError, offline }

class ContextController extends ChangeNotifier {
  ContextController({
    required this.locationService,
    required this.weatherService,
  });

  final LocationService locationService;
  final WeatherService weatherService;

  ContextStatus _status = ContextStatus.idle;
  LastAction _lastAction = LastAction.none;
  ContextSnapshot? _snapshot;
  String? _errorMessage;

  ContextStatus get status => _status;
  ContextSnapshot? get snapshot => _snapshot;
  String? get errorMessage => _errorMessage;

  bool get busy =>
      _status == ContextStatus.loadingLocation ||
      _status == ContextStatus.loadingApi;

  String get statusText {
    switch (_status) {
      case ContextStatus.idle:
        return 'Listo';
      case ContextStatus.loadingLocation:
        return 'Obteniendo ubicacion...';
      case ContextStatus.loadingApi:
        return 'Consultando API REST...';
      case ContextStatus.ready:
        return 'Contexto listo';
      case ContextStatus.error:
        return 'Ocurrio un problema';
    }
  }

  Future<void> useTarijaApi() async {
    _lastAction = LastAction.tarijaApi;
    await _loadWeatherFor(
      latitude: -21.5355,
      longitude: -64.7296,
      source: 'Tarija fija + API real',
    );
  }

  Future<void> useGpsAndApi() async {
    _lastAction = LastAction.gpsApi;
    _setLoading(ContextStatus.loadingLocation);

    try {
      final position = await locationService.getCurrentPosition();
      await _loadWeatherFor(
        latitude: position.latitude,
        longitude: position.longitude,
        source: 'GPS real + API real',
      );
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> simulateControlledError() async {
    _lastAction = LastAction.controlledError;
    _setLoading(ContextStatus.loadingApi);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _snapshot = null;
    _errorMessage = 'Error controlado de aula: practica ERROR + REINTENTO.';
    _status = ContextStatus.error;
    notifyListeners();
  }

  void useOfflineRescue() {
    _lastAction = LastAction.offline;
    _snapshot = ContextSnapshot(
      latitude: -21.5355,
      longitude: -64.7296,
      weather: const WeatherSnapshot(
        temperatureC: 22,
        weatherCode: 1,
        summary: 'Dato de rescate - no viene de Internet',
      ),
      source: 'RESCATE OFFLINE',
      capturedAt: DateTime.now(),
    );
    _errorMessage = null;
    _status = ContextStatus.ready;
    notifyListeners();
  }

  Future<void> retry() async {
    if (_lastAction == LastAction.gpsApi) {
      await useGpsAndApi();
      return;
    }

    if (_lastAction == LastAction.offline) {
      useOfflineRescue();
      return;
    }

    await useTarijaApi();
  }

  Future<void> _loadWeatherFor({
    required double latitude,
    required double longitude,
    required String source,
  }) async {
    _setLoading(ContextStatus.loadingApi);

    try {
      final weather = await weatherService.fetchCurrent(
        latitude: latitude,
        longitude: longitude,
      );

      _snapshot = ContextSnapshot(
        latitude: latitude,
        longitude: longitude,
        weather: weather,
        source: source,
        capturedAt: DateTime.now(),
      );
      _errorMessage = null;
      _status = ContextStatus.ready;
      notifyListeners();
    } catch (error) {
      _setError(error);
    }
  }

  void _setLoading(ContextStatus newStatus) {
    _status = newStatus;
    _snapshot = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(Object error) {
    _snapshot = null;
    _errorMessage = error.toString().replaceFirst('Exception: ', '');
    _status = ContextStatus.error;
    notifyListeners();
  }
}
