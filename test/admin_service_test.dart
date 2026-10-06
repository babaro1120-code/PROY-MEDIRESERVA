import 'package:flutter_test/flutter_test.dart';
import 'package:medireserva/services/medireserva_service.dart';
// `PostgrestException` viene reexportada por supabase_flutter, así que no hace
// falta agregar `postgrest` como dependencia directa del proyecto.
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pruebas sin red de la capa de servicio del panel de administración.
///
/// Se prueban las dos piezas puras del servicio:
///  · los mapas de datos que se envían a PostgreSQL (nombres de columna reales
///    de `specialties`, `doctors` y `doctor_availability`), y
///  · la traducción de los errores del servidor, incluido el 403 por rol.
void main() {
  group('especialidades · mapas para la tabla specialties', () {
    test('especialidadNueva arma name, icon_name y active', () {
      final fila = MediReservaService.especialidadNueva(
        name: '  Cardiología ',
        iconName: 'favorite',
      );

      expect(fila['name'], 'Cardiología');
      expect(fila['icon_name'], 'favorite');
      expect(fila['active'], isTrue);
    });

    test('especialidadNueva deja icon_name en null si no se eligió icono', () {
      final fila = MediReservaService.especialidadNueva(
        name: 'Oftalmología',
        iconName: '   ',
      );

      expect(fila['icon_name'], isNull);
      expect(fila.containsKey('icon_name'), isTrue);
    });

    test('cambiosDeEspecialidad no toca la columna active', () {
      final fila = MediReservaService.cambiosDeEspecialidad(
        name: 'Pediatría',
        iconName: 'child_care',
      );

      expect(fila['name'], 'Pediatría');
      expect(fila['icon_name'], 'child_care');
      expect(fila.containsKey('active'), isFalse);
    });

    test('cambioDeEstado solo envía la columna active', () {
      expect(MediReservaService.cambioDeEstado(false), {'active': false});
      expect(MediReservaService.cambioDeEstado(true), {'active': true});
    });
  });

  group('médicos · mapas para la tabla doctors', () {
    test('nuevoDoctor arma las columnas del esquema', () {
      final fila = MediReservaService.nuevoDoctor(
        name: ' Dra. Ana López ',
        specialtyId: 'esp-1',
        photoUrl: 'https://ejemplo.test/ana.png',
        experienceYears: 7,
        rating: 4.9,
        profileId: 'perfil-1',
      );

      expect(fila['name'], 'Dra. Ana López');
      expect(fila['specialty_id'], 'esp-1');
      expect(fila['photo_url'], 'https://ejemplo.test/ana.png');
      expect(fila['experience_years'], 7);
      expect(fila['rating'], 4.9);
      expect(fila['active'], isTrue);
      expect(fila['profile_id'], 'perfil-1');
    });

    test('nuevoDoctor deja la cuenta y la foto vacías en null', () {
      final fila = MediReservaService.nuevoDoctor(
        name: 'Dr. Juan Pérez',
        specialtyId: 'esp-1',
      );

      expect(fila['photo_url'], isNull);
      expect(fila['profile_id'], isNull);
      expect(fila['experience_years'], 0);
      expect(fila['rating'], 0);
    });

    test('cambiosDeDoctor envía profile_id null para desvincular la cuenta', () {
      final fila = MediReservaService.cambiosDeDoctor(
        name: 'Dr. Juan Pérez',
        specialtyId: 'esp-2',
        profileId: null,
      );

      expect(fila['specialty_id'], 'esp-2');
      expect(fila.containsKey('profile_id'), isTrue);
      expect(fila['profile_id'], isNull);
      // El estado se cambia por separado, con setDoctorActive.
      expect(fila.containsKey('active'), isFalse);
    });
  });

  group('disponibilidad · mapas para doctor_availability', () {
    test('bloqueDeDisponibilidad convierte fecha y hora al formato de la base', () {
      final fila = MediReservaService.bloqueDeDisponibilidad(
        doctorId: 'doc-1',
        date: DateTime(2026, 10, 5, 17, 30),
        time: '09:30',
      );

      expect(fila['doctor_id'], 'doc-1');
      expect(fila['available_date'], '2026-10-05');
      expect(fila['appointment_time'], '09:30:00');
      expect(fila['is_available'], isTrue);
    });
  });

  group('mensajeDeError · traducción de los errores del servidor', () {
    test('el rechazo por rol (42501) explica que falta el rol de administrador', () {
      final mensaje = MediReservaService.mensajeDeError(
        const PostgrestException(
          message:
              'new row violates row-level security policy for table "specialties"',
          code: '42501',
        ),
      );

      expect(mensaje, contains('administrador'));
    });

    test('una violación de RLS sin código también se reconoce', () {
      final mensaje = MediReservaService.mensajeDeError(
        const PostgrestException(
          message: 'new row violates row-level security policy',
        ),
      );

      expect(mensaje, contains('permisos'));
    });

    test('el duplicado usa el mensaje a medida cuando se indica', () {
      final mensaje = MediReservaService.mensajeDeError(
        const PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        ),
        mensajeDuplicado: 'Ya existe un bloque para esa fecha y hora.',
      );

      expect(mensaje, 'Ya existe un bloque para esa fecha y hora.');
    });

    test('el duplicado usa el mensaje genérico si no se indica ninguno', () {
      final mensaje = MediReservaService.mensajeDeError(
        const PostgrestException(message: 'duplicate key', code: '23505'),
      );

      expect(mensaje, contains('Ya existe'));
    });

    test('la función que todavía no existe avisa que falta el SQL de roles', () {
      final mensaje = MediReservaService.mensajeDeError(
        const PostgrestException(
          message: 'Could not find the function public.reservar_cita',
          code: 'PGRST202',
        ),
      );

      expect(mensaje, contains('05_ROLES_Y_RLS.sql'));
    });

    test('un error desconocido conserva el mensaje del servidor', () {
      final mensaje = MediReservaService.mensajeDeError(
        const PostgrestException(message: 'algo salió mal', code: '99999'),
      );

      expect(mensaje, 'algo salió mal');
    });

    test('un error común pierde el prefijo "Exception:"', () {
      expect(
        MediReservaService.mensajeDeError(Exception('sin conexión')),
        'sin conexión',
      );
    });
  });
}
