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
}
