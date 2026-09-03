import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';

class MediReservaService {
  MediReservaService(this.client);

  final SupabaseClient client;

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) {
      throw AuthException('Debes iniciar sesión para continuar.');
    }
    return id;
  }

  Future<List<Specialty>> getSpecialties() async {
    final rows = await client
        .from('specialties')
        .select('id,name,icon_name')
        .eq('active', true)
        .order('name');

    return (rows as List)
        .map((row) => Specialty.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<Doctor>> getDoctorsBySpecialty(String specialtyId) async {
    final rows = await client
        .from('doctors')
        .select(
          'id,name,specialty_id,photo_url,experience_years,rating,specialties(name)',
        )
        .eq('specialty_id', specialtyId)
        .eq('active', true)
        .order('name');

    return (rows as List)
        .map((row) => Doctor.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<String>> getAvailableTimes({
    required String doctorId,
    required DateTime date,
  }) async {
    final day = _dateOnly(date);

    final rows = await client
        .from('doctor_availability')
        .select('appointment_time')
        .eq('doctor_id', doctorId)
        .eq('available_date', day)
        .eq('is_available', true)
        .order('appointment_time');

    final booked = await client
        .from('appointments')
        .select('appointment_time')
        .eq('doctor_id', doctorId)
        .eq('appointment_date', day)
        .neq('status', 'cancelled');

    final bookedTimes = (booked as List)
        .map((e) => e['appointment_time'].toString())
        .toSet();

    return (rows as List)
        .map((e) => e['appointment_time'].toString().substring(0, 5))
        .where((time) => !bookedTimes.contains(time))
        .toList();
  }

  Future<Appointment> createAppointment({
    required String specialtyId,
    required String doctorId,
    required DateTime date,
    required String time,
  }) async {
    final response = await client
        .from('appointments')
        .insert({
          'patient_id': _userId,
          'specialty_id': specialtyId,
          'doctor_id': doctorId,
          'appointment_date': _dateOnly(date),
          'appointment_time': '$time:00',
          'status': 'confirmed',
        })
        .select(
          'id,reservation_number,appointment_date,appointment_time,status,'
          'specialties(name),doctors(name)',
        )
        .single();

    return Appointment.fromMap(Map<String, dynamic>.from(response));
  }

  Future<List<Appointment>> getMyAppointments() async {
    final rows = await client
        .from('appointments')
        .select(
          'id,reservation_number,appointment_date,appointment_time,status,'
          'specialties(name),doctors(name)',
        )
        .eq('patient_id', _userId)
        .order('appointment_date', ascending: true)
        .order('appointment_time', ascending: true);

    return (rows as List)
        .map((row) => Appointment.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', appointmentId)
        .eq('patient_id', _userId);
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    return await client
        .from('profiles')
        .select('full_name,email,phone,birth_date,address')
        .eq('id', _userId)
        .single();
  }

  Future<void> updateMyProfile({
    required String fullName,
    required String phone,
    required String birthDate,
    required String address,
  }) async {
    await client.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'birth_date': birthDate.trim().isEmpty ? null : birthDate.trim(),
      'address': address.trim(),
    }).eq('id', _userId);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final rows = await client
        .from('notifications')
        .select('id,title,body,type,is_read,created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> markNotificationAsRead(String id) async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
