import 'package:flutter_test/flutter_test.dart';
import 'package:medireserva/models/medireserva_models.dart';

void main() {
  group('Specialty.fromMap', () {
    test('convierte el id numérico y conserva el nombre', () {
      final specialty = Specialty.fromMap({
        'id': 3,
        'name': 'Cardiología',
        'icon_name': 'favorite',
      });

      expect(specialty.id, '3');
      expect(specialty.name, 'Cardiología');
      expect(specialty.iconName, 'favorite');
    });

    test('usa valores por defecto cuando faltan datos', () {
      final specialty = Specialty.fromMap({'id': 'abc'});

      expect(specialty.id, 'abc');
      expect(specialty.name, '');
      expect(specialty.iconName, isNull);
    });
  });

  group('Doctor.fromMap', () {
    test('lee el nombre de la especialidad anidada', () {
      final doctor = Doctor.fromMap({
        'id': 'd1',
        'name': 'Dr. Pérez',
        'specialty_id': 's1',
        'photo_url': null,
        'experience_years': 8,
        'rating': 4.5,
        'specialties': {'name': 'Cardiología'},
      });

      expect(doctor.id, 'd1');
      expect(doctor.name, 'Dr. Pérez');
      expect(doctor.specialtyId, 's1');
      expect(doctor.specialtyName, 'Cardiología');
      expect(doctor.photoUrl, isNull);
      expect(doctor.experienceYears, 8);
      expect(doctor.rating, 4.5);
    });

    test('tolera datos ausentes', () {
      final doctor = Doctor.fromMap({'id': 'd2', 'specialty_id': 's2'});

      expect(doctor.name, '');
      expect(doctor.specialtyName, isNull);
      expect(doctor.experienceYears, 0);
      expect(doctor.rating, 0);
    });
  });

  group('Appointment.fromMap', () {
    test('combina fecha, hora y relaciones', () {
      final appointment = Appointment.fromMap({
        'id': 7,
        'reservation_number': 'MR-0007',
        'appointment_date': '2026-09-24',
        'appointment_time': '08:30:00',
        'status': 'confirmed',
        'specialties': {'name': 'Cardiología'},
        'doctors': {'name': 'Dr. Pérez'},
      });

      expect(appointment.id, '7');
      expect(appointment.reservationNumber, 'MR-0007');
      expect(appointment.date, DateTime(2026, 9, 24));
      expect(appointment.time, '08:30:00');
      expect(appointment.status, 'confirmed');
      expect(appointment.specialty, 'Cardiología');
      expect(appointment.doctor, 'Dr. Pérez');
    });

    test('usa "pending" cuando no llega el estado', () {
      final appointment = Appointment.fromMap({
        'id': 'a1',
        'appointment_date': '2026-09-25',
        'appointment_time': '09:00:00',
      });

      expect(appointment.status, 'pending');
      expect(appointment.specialty, '');
      expect(appointment.doctor, '');
      expect(appointment.reservationNumber, isNull);
    });
  });

  group('AgendaItem.fromMap', () {
    test('lee el nombre del paciente desde la relación anidada', () {
      final item = AgendaItem.fromMap({
        'id': 'a1',
        'reservation_number': 'MR-20260926-ABCD1234',
        'appointment_date': '2026-09-26',
        'appointment_time': '10:30:00',
        'status': 'confirmed',
        'specialties': {'name': 'Pediatría'},
        'doctors': {'name': 'Dra. López'},
        'profiles': {'full_name': 'Ana Quispe'},
      });

      expect(item.id, 'a1');
      expect(item.patientName, 'Ana Quispe');
      expect(item.specialty, 'Pediatría');
      expect(item.doctor, 'Dra. López');
      expect(item.date, DateTime(2026, 9, 26));
      expect(item.time, '10:30:00');
      expect(item.status, 'confirmed');
      expect(item.reservationNumber, 'MR-20260926-ABCD1234');
    });

    test('tolera que el paciente no llegue en la respuesta', () {
      final item = AgendaItem.fromMap({
        'id': 'a2',
        'appointment_date': '2026-09-27',
        'appointment_time': '11:00:00',
      });

      expect(item.patientName, '');
      expect(item.specialty, '');
      expect(item.doctor, '');
      expect(item.status, 'pending');
      expect(item.reservationNumber, isNull);
    });
  });

  group('respuesta de la función reservar_cita', () {
    // Forma exacta que arma jsonb_build_object en supabase/07_RESERVAS_RPC.sql.
    final respuestaRpc = <String, dynamic>{
      'id': '11111111-2222-3333-4444-555555555555',
      'reservation_number': 'MR-20260926-DEADBEEF',
      'appointment_date': '2026-09-26',
      'appointment_time': '15:00:00',
      'status': 'confirmed',
      'specialties': {'name': 'Medicina General'},
      'doctors': {'name': 'Dra. Ana López'},
    };

    test('se mapea con Appointment sin adaptar nada', () {
      final appointment = Appointment.fromMap(respuestaRpc);

      expect(appointment.id, '11111111-2222-3333-4444-555555555555');
      expect(appointment.reservationNumber, 'MR-20260926-DEADBEEF');
      expect(appointment.specialty, 'Medicina General');
      expect(appointment.doctor, 'Dra. Ana López');
      expect(appointment.date, DateTime(2026, 9, 26));
      expect(appointment.time, '15:00:00');
      expect(appointment.status, 'confirmed');
    });

    test('no depende de patient_id: ese dato sale de auth.uid()', () {
      // El RPC no devuelve patient_id a propósito: el cliente nunca lo envía.
      expect(respuestaRpc.containsKey('patient_id'), isFalse);

      final appointment = Appointment.fromMap(respuestaRpc);
      expect(appointment.status, 'confirmed');
      expect(appointment.specialty, 'Medicina General');
    });
  });
}
