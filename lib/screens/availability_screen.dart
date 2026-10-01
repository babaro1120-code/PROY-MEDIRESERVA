import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';

/// RF-07 · El profesional administra su propia disponibilidad.
///
/// Publica los bloques de atención que ofrecerá, los cierra cuando no puede
/// atender y los elimina si se equivocó. La pantalla no decide sobre qué
/// bloques puede escribir: eso lo impone la política RLS
/// `availability_profesional_o_admin_write`, que solo alcanza los bloques cuyo
/// `doctor_id` pertenece al profesional autenticado.
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

/// Todo lo que la pantalla necesita, resuelto en una sola carga.
class _Panel {
  const _Panel({
    required this.doctor,
    required this.slots,
    required this.reservados,
  });

  final Doctor? doctor;
  final List<AvailabilitySlot> slots;

  /// Claves `fecha|hora` de los bloques que ya tomó un paciente.
  final Set<String> reservados;
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late Future<_Panel> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<_Panel> _cargar() async {
    final service = MediReservaService(Supabase.instance.client);

    final doctor = await service.getMyDoctorRow();
    if (doctor == null) {
      return const _Panel(
        doctor: null,
        slots: <AvailabilitySlot>[],
        reservados: <String>{},
      );
    }

    // Las dos consultas salen a la vez: la disponibilidad y la agenda, para
    // poder marcar qué bloque ya está tomado por un paciente.
    final slotsFuture = service.getMyAvailability();
    final agendaFuture = service.getAgenda();
    final slots = await slotsFuture;
    final agenda = await agendaFuture;

    return _Panel(
      doctor: doctor,
      slots: slots,
      reservados: {
        for (final a in agenda)
          if (a.status != 'cancelled') _clave(a.date, a.time),
      },
    );
  }

  void _refrescar() => setState(() => _future = _cargar());

  // ------------------------------------------------------------
  // Acciones
  // ------------------------------------------------------------

  Future<void> _agregarBloque(Doctor doctor) async {
    final hoy = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 90)),
      helpText: 'Fecha del bloque',
    );
    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Hora de atención',
    );
    if (hora == null || !mounted) return;

    final texto =
        '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}';

    await _ejecutar(
      () => MediReservaService(Supabase.instance.client).createAvailabilitySlot(
        doctorId: doctor.id,
        date: fecha,
        time: texto,
      ),
      exito: 'Bloque publicado para el ${_fechaCorta(fecha)} a las $texto.',
    );
  }

  Future<void> _cambiarBloque(AvailabilitySlot slot) async {
    await _ejecutar(
      () => MediReservaService(Supabase.instance.client)
          .setAvailabilitySlotAvailable(
        slotId: slot.id,
        available: !slot.isAvailable,
      ),
      exito: slot.isAvailable
          ? 'Bloque cerrado. No se ofrecerá a los pacientes.'
          : 'Bloque reabierto.',
    );
  }

  Future<void> _eliminarBloque(AvailabilitySlot slot) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar el bloque?'),
        content: Text(
          'Se quitará ${_fechaCorta(slot.date)} a las ${_hhmm(slot.time)} de tu '
          'agenda. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    await _ejecutar(
      () => MediReservaService(Supabase.instance.client)
          .deleteAvailabilitySlot(slot.id),
      exito: 'Bloque eliminado.',
    );
  }

  /// Ejecuta una operación y deja la lista actualizada, informando el resultado.
  Future<void> _ejecutar(
    Future<void> Function() accion, {
    required String exito,
  }) async {
    try {
      await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(exito)));
      _refrescar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorLegible(error))),
      );
    }
  }

  /// Traduce el rechazo del servidor a un mensaje entendible.
  String _errorLegible(Object error) {
    if (error is PostgrestException) {
      if (error.code == '42501') {
        return 'Tu cuenta no puede modificar esta agenda.';
      }
      if (error.code == '23505') {
        return 'Ya existe un bloque para esa fecha y hora.';
      }
      if (error.code == '23503') {
        return 'Tu cuenta no está vinculada a una agenda médica.';
      }
      if (error.code == 'PGRST202' ||
          error.message.toLowerCase().contains('schema cache')) {
        return 'Falta ejecutar supabase/05_ROLES_Y_RLS.sql en Supabase.';
      }
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  // ------------------------------------------------------------
  // Interfaz
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MediReservaPage(
      title: 'Mi Disponibilidad',
      step: '',
      showBack: widget.showBack,
      child: FutureBuilder<_Panel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(25),
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (snapshot.hasError) {
            return _aviso(_errorLegible(snapshot.error as Object));
          }

          final panel = snapshot.data;
          if (panel == null || panel.doctor == null) {
            return _aviso(
              'Tu cuenta todavía no está vinculada a una agenda médica.\n\n'
              'Un administrador debe asociarla con la fila del profesional en '
              'la tabla doctors (columna profile_id).',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _encabezado(panel.doctor!),
              const SizedBox(height: 10.4),
              MediButton(
                label: 'Publicar bloque de atención',
                icon: Icons.add,
                onPressed: () => _agregarBloque(panel.doctor!),
              ),
              const SizedBox(height: 12),
              if (panel.slots.isEmpty)
                _aviso(
                  'Todavía no publicaste bloques de atención.\n\n'
                  'Publicá los horarios en los que podés atender y aparecerán '
                  'disponibles para los pacientes.',
                )
              else ...[
                _contador(panel),
                const SizedBox(height: 8),
                ..._porFecha(panel),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _encabezado(Doctor doctor) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doctor.name,
              style: const TextStyle(
                color: kMediText,
                fontSize: 13.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((doctor.specialtyName ?? '').isNotEmpty) ...[
              const SizedBox(height: 2.6),
              Text(
                doctor.specialtyName!,
                style: const TextStyle(color: kMediMuted, fontSize: 12),
              ),
            ],
          ],
        ),
      );

  Widget _contador(_Panel panel) {
    final abiertos = panel.slots.where((s) => s.isAvailable).length;
    final tomados = panel.slots.where((s) => _estaTomado(panel, s)).length;

    return Text(
      '$abiertos bloque(s) disponible(s) · $tomados ya reservado(s)',
      style: const TextStyle(color: kMediMuted, fontSize: 12),
    );
  }

  /// Agrupa los bloques por día, conservando el orden que devolvió el servidor.
  List<Widget> _porFecha(_Panel panel) {
    final grupos = <String, List<AvailabilitySlot>>{};
    for (final slot in panel.slots) {
      grupos.putIfAbsent(_claveDia(slot.date), () => []).add(slot);
    }

    final widgets = <Widget>[];
    for (final entrada in grupos.entries) {
      final primero = entrada.value.first;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            _fecha(primero.date),
            style: const TextStyle(
              color: kMediDark,
              fontSize: 12.8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      for (final slot in entrada.value) {
        widgets.add(_bloque(panel, slot));
      }
    }
    return widgets;
  }

  Widget _bloque(_Panel panel, AvailabilitySlot slot) {
    final tomado = _estaTomado(panel, slot);
    final (etiqueta, fondo, texto) = tomado
        ? ('Reservado', const Color(0xFFE8F0FE), const Color(0xFF1A56C4))
        : slot.isAvailable
            ? ('Disponible', const Color(0xFFDDF5E6), const Color(0xFF138A4A))
            : ('Cerrado', const Color(0xFFFFE8EA), const Color(0xFFD32F2F));

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E6EE)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 18, color: kMediMuted),
          const SizedBox(width: 7),
          Text(
            _hhmm(slot.time),
            style: const TextStyle(
              color: kMediText,
              fontSize: 13.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              etiqueta,
              style: TextStyle(
                color: texto,
                fontSize: 11.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Un bloque ya reservado no se cierra ni se borra: primero hay que
          // cancelar la cita, para no dejar al paciente sin su horario.
          if (!tomado) ...[
            TextButton(
              onPressed: () => _cambiarBloque(slot),
              child: Text(
                slot.isAvailable ? 'Cerrar' : 'Reabrir',
                style: const TextStyle(fontSize: 11.2, color: kMediBlue),
              ),
            ),
            TextButton(
              onPressed: () => _eliminarBloque(slot),
              child: const Text(
                'Eliminar',
                style: TextStyle(fontSize: 11.2, color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aviso(String texto) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: kMediMuted, fontSize: 12.8),
        ),
      );

  // ------------------------------------------------------------
  // Fechas
  // ------------------------------------------------------------

  bool _estaTomado(_Panel panel, AvailabilitySlot slot) =>
      panel.reservados.contains(_clave(slot.date, slot.time));

  String _clave(DateTime date, String time) =>
      '${_claveDia(date)}|${_hhmm(time)}';

  String _claveDia(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  String _fechaCorta(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _fecha(DateTime d) =>
      '${_semana(d.weekday)}, ${d.day} de ${_mes(d.month)}';

  String _mes(int m) => const [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre'
      ][m - 1];

  String _semana(int d) => const [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo'
      ][d - 1];
}
