import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('La ubicacion del dispositivo esta desactivada.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw StateError('Permiso de ubicacion denegado.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Permiso de ubicacion denegado permanentemente. '
        'Habilitalo desde Ajustes.',
      );
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 15),
    );

    return Geolocator.getCurrentPosition(locationSettings: settings);
  }
}
