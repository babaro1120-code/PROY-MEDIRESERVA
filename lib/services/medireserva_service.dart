import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../utils/medireserva_fechas.dart';

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

  // ------------------------------------------------------------
  // RF-07 · El profesional administra su propia disponibilidad.
  //
  // Ninguno de estos métodos filtra por médico en el cliente: el
  // acotamiento lo impone la política RLS
  // `availability_profesional_o_admin_write`, que solo deja tocar los
  // bloques cuyo `doctor_id` pertenece al profesional autenticado.
  // ------------------------------------------------------------

  /// Fila de `doctors` del profesional autenticado.
  ///
  /// Se resuelve por `doctors.profile_id`, que vincula la cuenta de Auth con la
  /// agenda médica. Devuelve `null` si la cuenta todavía no está vinculada, que
  /// es lo que ocurre antes de ejecutar `05_ROLES_Y_RLS.sql` o cuando un
  /// administrador aún no asignó al profesional.
  Future<Doctor?> getMyDoctorRow() async {
    try {
      final row = await client
          .from('doctors')
          .select(
            'id,name,specialty_id,photo_url,experience_years,rating,'
            'specialties(name)',
          )
          .eq('profile_id', _userId)
          .maybeSingle();

      if (row == null) return null;
      return Doctor.fromMap(Map<String, dynamic>.from(row));
    } on PostgrestException {
      // Falta 05_ROLES_Y_RLS.sql: la columna doctors.profile_id no existe.
      return null;
    }
  }

  /// Bloques de atención del profesional, desde hoy y hasta [days] días después.
  Future<List<AvailabilitySlot>> getMyAvailability({int days = 30}) async {
    final hoy = DateTime.now();
    final desde = _dateOnly(DateTime(hoy.year, hoy.month, hoy.day));
    final hasta = _dateOnly(hoy.add(Duration(days: days)));

    final rows = await client
        .from('doctor_availability')
        .select('id,doctor_id,available_date,appointment_time,is_available')
        .gte('available_date', desde)
        .lte('available_date', hasta)
        .order('available_date', ascending: true)
        .order('appointment_time', ascending: true);

    return (rows as List)
        .map((row) => AvailabilitySlot.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Publica un bloque de atención nuevo.
  Future<void> createAvailabilitySlot({
    required String doctorId,
    required DateTime date,
    required String time,
  }) async {
    await client.from('doctor_availability').insert({
      'doctor_id': doctorId,
      'available_date': _dateOnly(date),
      'appointment_time': _horaCompleta(time),
      'is_available': true,
    });
  }

  /// Abre o cierra un bloque sin borrarlo, para conservar el historial.
  Future<void> setAvailabilitySlotAvailable({
    required String slotId,
    required bool available,
  }) async {
    await client
        .from('doctor_availability')
        .update({'is_available': available}).eq('id', slotId);
  }

  Future<void> deleteAvailabilitySlot(String slotId) async {
    await client.from('doctor_availability').delete().eq('id', slotId);
  }

  // ============================================================
  // PANEL DE ADMINISTRACIÓN (rol `administrador`)
  //
  // Ninguno de estos métodos autoriza nada: la interfaz solo oculta lo
  // que el rol no puede hacer y el servidor decide. Las tres políticas
  // que ya están aplicadas cubren todo el panel:
  //   · `specialties_admin_write`               -> specialties
  //   · `doctors_admin_write`                   -> doctors
  //   · `availability_profesional_o_admin_write`-> doctor_availability
  // Si la cuenta no es administradora, PostgreSQL responde 42501 y la
  // pantalla lo traduce con mensajeDeError().
  // ============================================================

  // ------------------------------------------------------------
  // Mapas de datos. Son funciones estáticas y puras: se prueban sin
  // red y garantizan que las columnas enviadas sean las del esquema.
  // ------------------------------------------------------------

  /// Especialidad nueva contra `specialties(name, icon_name, active)`.
  static Map<String, dynamic> especialidadNueva({
    required String name,
    String? iconName,
  }) {
    return {
      'name': name.trim(),
      'icon_name': _textoOpcional(iconName),
      'active': true,
    };
  }

  /// Datos editables de `specialties`; no toca `active`.
  static Map<String, dynamic> cambiosDeEspecialidad({
    required String name,
    String? iconName,
  }) {
    return {
      'name': name.trim(),
      'icon_name': _textoOpcional(iconName),
    };
  }

  /// Cambio de estado contra `specialties.active` o `doctors.active`.
  static Map<String, dynamic> cambioDeEstado(bool active) => {'active': active};

  /// Médico nuevo contra
  /// `doctors(name, specialty_id, photo_url, experience_years, rating, active, profile_id)`.
  ///
  /// `profile_id` es la cuenta de Auth del profesional; se envía aunque sea
  /// nula porque la columna admite `null` (médico sin cuenta vinculada).
  static Map<String, dynamic> nuevoDoctor({
    required String name,
    required String specialtyId,
    String? photoUrl,
    int experienceYears = 0,
    double rating = 0,
    String? profileId,
  }) {
    return {
      'name': name.trim(),
      'specialty_id': specialtyId,
      'photo_url': _textoOpcional(photoUrl),
      'experience_years': experienceYears,
      'rating': rating,
      'active': true,
      'profile_id': _textoOpcional(profileId),
    };
  }

  /// Datos editables de `doctors`, incluida la especialidad y la cuenta
  /// vinculada. Enviar `profile_id` nulo desvincula la cuenta.
  static Map<String, dynamic> cambiosDeDoctor({
    required String name,
    required String specialtyId,
    String? photoUrl,
    int experienceYears = 0,
    double rating = 0,
    String? profileId,
  }) {
    return {
      'name': name.trim(),
      'specialty_id': specialtyId,
      'photo_url': _textoOpcional(photoUrl),
      'experience_years': experienceYears,
      'rating': rating,
      'profile_id': _textoOpcional(profileId),
    };
  }

  /// Bloque nuevo contra
  /// `doctor_availability(doctor_id, available_date, appointment_time, is_available)`.
  static Map<String, dynamic> bloqueDeDisponibilidad({
    required String doctorId,
    required DateTime date,
    required String time,
  }) {
    return {
      'doctor_id': doctorId,
      'available_date': fechaIso(date),
      'appointment_time': horaCompleta(time),
      'is_available': true,
    };
  }

  /// Traduce el rechazo del servidor a un mensaje entendible para el usuario.
  ///
  /// Se centraliza acá para que todas las pantallas del panel informen igual.
  /// El 403 por rol llega como `42501` (violación de política RLS) y tiene que
  /// quedar claro que el problema es de permisos, no de datos.
  static String mensajeDeError(Object error, {String? mensajeDuplicado}) {
    if (error is PostgrestException) {
      final codigo = error.code;
      final texto = error.message.toLowerCase();

      if (codigo == '42501' || texto.contains('row-level security')) {
        return 'Tu cuenta no tiene permisos de administrador para esta acción.';
      }
      if (codigo == '23505') {
        return mensajeDuplicado ?? 'Ya existe un registro con esos mismos datos.';
      }
      if (codigo == '23503') {
        return 'El registro relacionado no existe: revisá la especialidad o la '
            'cuenta elegida.';
      }
      if (codigo == '23514' ||
          codigo == '22007' ||
          codigo == '22008' ||
          codigo == '22P02') {
        return 'Alguno de los valores enviados no es válido para el sistema.';
      }
      if (codigo == 'PGRST116') {
        return 'No se encontró el registro que se quería modificar.';
      }
      if (codigo == 'PGRST202' ||
          texto.contains('schema cache') ||
          texto.contains('could not find the function')) {
        return 'Falta ejecutar supabase/05_ROLES_Y_RLS.sql en Supabase.';
      }
      if (codigo == 'PGRST205' ||
          codigo == '42P01' ||
          texto.contains('does not exist')) {
        return 'La base de datos no tiene la tabla o la columna que esta '
            'pantalla necesita.';
      }
      return error.message;
    }
    if (error is AuthException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  static String? _textoOpcional(String? valor) {
    final limpio = (valor ?? '').trim();
    return limpio.isEmpty ? null : limpio;
  }

  // ------------------------------------------------------------
  // Especialidades · tabla `specialties`
  // ------------------------------------------------------------

  /// Todas las especialidades, incluidas las desactivadas.
  ///
  /// El administrador las ve todas porque `specialties_admin_write` es una
  /// política permisiva `for all`; para el resto de los roles el servidor
  /// devuelve solo las activas, así que esta pantalla es solo para el panel.
  Future<List<Specialty>> getAllSpecialties() async {
    final rows = await client
        .from('specialties')
        .select('id,name,icon_name,active')
        .order('name');

    return (rows as List)
        .map((row) => Specialty.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> createSpecialty({
    required String name,
    String? iconName,
  }) async {
    await client
        .from('specialties')
        .insert(especialidadNueva(name: name, iconName: iconName));
  }

  Future<void> updateSpecialty({
    required String id,
    required String name,
    String? iconName,
  }) async {
    await client
        .from('specialties')
        .update(cambiosDeEspecialidad(name: name, iconName: iconName))
        .eq('id', id);
  }

  /// Activa o desactiva sin borrar: las reservas conservan su especialidad.
  Future<void> setSpecialtyActive({
    required String id,
    required bool active,
  }) async {
    await client
        .from('specialties')
        .update(cambioDeEstado(active))
        .eq('id', id);
  }

  // ------------------------------------------------------------
  // Médicos · tabla `doctors`
  // ------------------------------------------------------------

  /// Todos los médicos, incluidos los desactivados, con su especialidad.
  Future<List<Doctor>> getAllDoctors() async {
    final rows = await client
        .from('doctors')
        .select(
          'id,name,specialty_id,photo_url,experience_years,rating,active,'
          'profile_id,specialties(name)',
        )
        .order('name');

    return (rows as List)
        .map((row) => Doctor.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> createDoctor({
    required String name,
    required String specialtyId,
    String? photoUrl,
    int experienceYears = 0,
    double rating = 0,
    String? profileId,
  }) async {
    await client.from('doctors').insert(
          nuevoDoctor(
            name: name,
            specialtyId: specialtyId,
            photoUrl: photoUrl,
            experienceYears: experienceYears,
            rating: rating,
            profileId: profileId,
          ),
        );
  }

  /// Actualiza los datos del médico, incluida su especialidad y su cuenta.
  Future<void> updateDoctor({
    required String id,
    required String name,
    required String specialtyId,
    String? photoUrl,
    int experienceYears = 0,
    double rating = 0,
    String? profileId,
  }) async {
    await client.from('doctors').update(
          cambiosDeDoctor(
            name: name,
            specialtyId: specialtyId,
            photoUrl: photoUrl,
            experienceYears: experienceYears,
            rating: rating,
            profileId: profileId,
          ),
        ).eq('id', id);
  }

  Future<void> setDoctorActive({
    required String id,
    required bool active,
  }) async {
    await client.from('doctors').update(cambioDeEstado(active)).eq('id', id);
  }

  /// Perfiles disponibles para vincular con `doctors.profile_id`.
  ///
  /// `profiles_select_por_rol` deja que el administrador lea todos los
  /// perfiles; el profesional solo se vería a sí mismo, por eso este método
  /// pertenece al panel.
  Future<List<Map<String, dynamic>>> getProfilesForLinking() async {
    final rows = await client
        .from('profiles')
        .select('id,full_name,email,role')
        .order('full_name');

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  // ------------------------------------------------------------
  // Disponibilidad de cualquier médico · tabla `doctor_availability`
  //
  // Variante de RF-07 para el administrador: el médico no sale de la
  // sesión sino del parámetro, porque `es_administrador()` lo habilita
  // sobre la agenda de cualquiera. Los métodos de escritura son los
  // mismos que usa el profesional (`createAvailabilitySlot`,
  // `setAvailabilitySlotAvailable`, `deleteAvailabilitySlot`): operan
  // por `doctor_id` o por `id` de bloque, sin depender de la sesión.
  // ------------------------------------------------------------

  /// Bloques de [doctorId] desde hoy y hasta [days] días después.
  Future<List<AvailabilitySlot>> getAvailabilityOfDoctor({
    required String doctorId,
    int days = 60,
  }) async {
    final hoy = DateTime.now();
    final desde = fechaIso(DateTime(hoy.year, hoy.month, hoy.day));
    final hasta = fechaIso(hoy.add(Duration(days: days)));

    final rows = await client
        .from('doctor_availability')
        .select('id,doctor_id,available_date,appointment_time,is_available')
        .eq('doctor_id', doctorId)
        .gte('available_date', desde)
        .lte('available_date', hasta)
        .order('available_date', ascending: true)
        .order('appointment_time', ascending: true);

    return (rows as List)
        .map((row) => AvailabilitySlot.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Publica varios bloques de [doctorId] de una sola vez (una jornada).
  ///
  /// Descarta las horas que ya existen para esa fecha: el índice único
  /// `doctor_availability_slot_unique` las rechazaría con 23505 y no tiene
  /// sentido que publicar una jornada falle porque una hora ya estaba
  /// publicada. Devuelve cuántas filas nuevas se insertaron.
  Future<int> createAvailabilitySlotsForDoctor({
    required String doctorId,
    required DateTime date,
    required List<String> times,
  }) async {
    final horas = times.map(horaCompleta).toSet().toList()..sort();
    if (horas.isEmpty) return 0;

    final existentes = await client
        .from('doctor_availability')
        .select('appointment_time')
        .eq('doctor_id', doctorId)
        .eq('available_date', fechaIso(date));

    final yaPublicadas = (existentes as List)
        .map((row) => horaCorta(row['appointment_time'].toString()))
        .toSet();

    final nuevas = horas
        .where((hora) => !yaPublicadas.contains(horaCorta(hora)))
        .toList();
    if (nuevas.isEmpty) return 0;

    await client.from('doctor_availability').insert([
      for (final hora in nuevas)
        bloqueDeDisponibilidad(doctorId: doctorId, date: date, time: hora),
    ]);

    return nuevas.length;
  }

  /// Claves `fecha|hora` de los bloques de [doctorId] que ya tomó un paciente.
  ///
  /// Sirve para que el administrador no cierre ni borre un bloque reservado:
  /// primero hay que cancelar la cita, igual que en la agenda del profesional.
  Future<Set<String>> getReservedSlotKeys({
    required String doctorId,
    int days = 60,
  }) async {
    final hoy = DateTime.now();
    final desde = fechaIso(DateTime(hoy.year, hoy.month, hoy.day));
    final hasta = fechaIso(hoy.add(Duration(days: days)));

    final rows = await client
        .from('appointments')
        .select('appointment_date,appointment_time')
        .eq('doctor_id', doctorId)
        .neq('status', 'cancelled')
        .gte('appointment_date', desde)
        .lte('appointment_date', hasta);

    return <String>{
      for (final row in (rows as List))
        claveBloque(
          DateTime.parse(row['appointment_date'].toString()),
          row['appointment_time'].toString(),
        ),
    };
  }

  /// PostgreSQL espera `HH:MM:SS` en una columna de tipo `time`.
  String _horaCompleta(String value) => horaCompleta(value);

  /// Detecta si el error es "la función no existe todavía", para no confundirlo
  /// con un rechazo real de la reserva.
  bool _funcionRpcAusente(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST202' ||
        message.contains('could not find the function') ||
        message.contains('schema cache');
  }

  /// `YYYY-MM-DD` que espera una columna `date` de PostgreSQL.
  String _dateOnly(DateTime value) => fechaIso(value);
}
