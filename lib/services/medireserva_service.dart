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

  /// Garantiza que exista la fila del perfil del usuario autenticado.
  ///
  /// `appointments.patient_id` referencia `public.profiles(id)`. Si el trigger
  /// `handle_new_user` no alcanzó a crear el perfil (cuentas registradas antes
  /// de ejecutar `supabase/schema.sql`), la reserva fallaría con el error 23503
  /// ("Key is not present in table profiles"). Este método autorrepara ese caso
  /// usando los datos del usuario de Auth.
  Future<void> ensureProfile() async {
    final id = _userId;

    final existing = await client
        .from('profiles')
        .select('id')
        .eq('id', id)
        .maybeSingle();

    if (existing != null) return;

    final user = client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final phone = (metadata['phone'] as String?)?.trim();
    final birthDate = (metadata['birth_date'] as String?)?.trim();

    await client.from('profiles').upsert({
      'id': id,
      'full_name': (metadata['full_name'] as String? ?? '').trim(),
      'email': user?.email ?? '',
      'phone': (phone == null || phone.isEmpty) ? null : phone,
      'birth_date': (birthDate == null || birthDate.isEmpty) ? null : birthDate,
    });
  }

  /// Rol del usuario autenticado: `paciente`, `profesional` o `administrador`.
  ///
  /// El rol no lo elige el usuario: lo asigna un administrador. Ante cualquier
  /// duda se devuelve `paciente`, que es el menor privilegio.
  Future<String> getMyRole() async {
    try {
      final row = await client
          .from('profiles')
          .select('role')
          .eq('id', _userId)
          .maybeSingle();
      final raw = (row?['role'] as String?)?.trim().toLowerCase();
      if (raw == 'profesional') return 'profesional';
      if (raw == 'administrador') return 'administrador';
      return 'paciente';
    } on PostgrestException {
      // La columna `role` todavía no existe (falta 05_ROLES_Y_RLS.sql).
      return 'paciente';
    }
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

    // Doble comprobación: además del bloque marcado como no disponible, se
    // descartan los horarios que ya tienen una reserva activa.
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

  /// Crea la reserva llamando a la función `reservar_cita` de PostgreSQL.
  ///
  /// La función hace en una sola transacción: valida el bloque, lo marca como
  /// ocupado y crea la cita, tomando `patient_id` de `auth.uid()`. Así dos
  /// intentos simultáneos sobre el mismo horario no pueden ganar los dos.
  ///
  /// Si la base todavía no tiene la función (falta ejecutar
  /// `supabase/07_RESERVAS_RPC.sql`), se recurre a la inserción directa para
  /// que la aplicación siga operativa: el índice único parcial del esquema
  /// sigue impidiendo la doble reserva.
  Future<Appointment> createAppointment({
    required String specialtyId,
    required String doctorId,
    required DateTime date,
    required String time,
  }) async {
    // Autorrepara el perfil: sin fila en `profiles` la FK fallaría con 23503.
    try {
      await ensureProfile();
    } on PostgrestException {
      // Se ignora a propósito; el error accionable lo reporta la reserva.
    }

    final params = {
      'p_doctor_id': doctorId,
      'p_specialty_id': specialtyId,
      'p_fecha': _dateOnly(date),
      'p_hora': time.length == 5 ? '$time:00' : time,
    };

    try {
      final response = await client.rpc('reservar_cita', params: params);

      if (response is Map) {
        return Appointment.fromMap(Map<String, dynamic>.from(response));
      }
    } on PostgrestException catch (error) {
      if (!_funcionRpcAusente(error)) rethrow;
      // Continúa con la inserción directa.
    }

    final response = await client
        .from('appointments')
        .insert({
          'patient_id': _userId,
          'specialty_id': specialtyId,
          'doctor_id': doctorId,
          'appointment_date': _dateOnly(date),
          'appointment_time': time.length == 5 ? '$time:00' : time,
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

  /// Da de baja la reserva (no se borra la fila: se conserva la trazabilidad).
  ///
  /// `cancelar_cita` además libera el bloque de disponibilidad para que otro
  /// paciente pueda reservarlo.
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await client.rpc('cancelar_cita', params: {'p_cita_id': appointmentId});
      return;
    } on PostgrestException catch (error) {
      if (!_funcionRpcAusente(error)) rethrow;
    }

    await client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', appointmentId)
        .eq('patient_id', _userId);
  }

  /// Editar el estado de una reserva: profesional asignado o administrador.
  Future<void> setAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    await client.rpc('cambiar_estado_reserva', params: {
      'p_cita_id': appointmentId,
      'p_estado': status,
    });
  }

  /// Reservas que puede ver el usuario autenticado según su rol.
  ///
  /// El acotamiento lo aplica el servidor mediante RLS: el paciente recibe las
  /// suyas, el profesional únicamente las de su agenda y el administrador,
  /// todas. Filtrar en el cliente no sería un mecanismo de autorización.
  Future<List<AgendaItem>> getAgenda() async {
    final rows = await client
        .from('appointments')
        .select(
          'id,reservation_number,appointment_date,appointment_time,status,'
          'specialties(name),doctors(name),profiles(full_name)',
        )
        .order('appointment_date', ascending: true)
        .order('appointment_time', ascending: true);

    return (rows as List)
        .map((row) => AgendaItem.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    await ensureProfile();

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
    await ensureProfile();

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

  /// Detecta si el error es "la función no existe todavía", para no confundirlo
  /// con un rechazo real de la reserva.
  bool _funcionRpcAusente(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST202' ||
        message.contains('could not find the function') ||
        message.contains('schema cache');
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
