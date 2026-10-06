import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../services/medireserva_service.dart';
import '../utils/medireserva_fechas.dart';
import '../widgets/admin_ui.dart';
import '../widgets/medireserva_ui.dart';

/// Disponibilidad de cualquier médico, vista del administrador (RF-07).
///
/// Es la variante de "Mi Disponibilidad": en lugar de trabajar sobre el médico
/// de la sesión, el administrador elige el médico y gestiona sus bloques. La
/// política `availability_profesional_o_admin_write` lo habilita sobre la
/// agenda de cualquiera mediante `es_administrador()`, así que no hace falta
/// ninguna política nueva ni filtrar en el cliente.
class AdminAvailabilityScreen extends StatefulWidget {
  const AdminAvailabilityScreen({super.key, this.showBack = false});

  final bool showBack;

  @override
  State<AdminAvailabilityScreen> createState() =>
      _AdminAvailabilityScreenState();
}

/// Todo lo que la pantalla necesita para el médico elegido.
class _PanelAgenda {
  const _PanelAgenda({
    required this.medicos,
    required this.slots,
    required this.reservados,
    this.medico,
  });

  final List<Doctor> medicos;
  final Doctor? medico;
  final List<AvailabilitySlot> slots;

  /// Claves `fecha|hora` de los bloques que ya tomó un paciente.
  final Set<String> reservados;
}

class _AdminAvailabilityScreenState extends State<AdminAvailabilityScreen> {
  static const int _dias = 60;

  late Future<_PanelAgenda> _future;
  String? _medicoId;
  bool _ocupado = false;

  MediReservaService get _servicio => MediReservaService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<_PanelAgenda> _cargar() async {
    final servicio = _servicio;
    final medicos = await servicio.getAllDoctors();

    if (medicos.isEmpty) {
      return const _PanelAgenda(
        medicos: <Doctor>[],
        slots: <AvailabilitySlot>[],
        reservados: <String>{},
      );
    }

    final elegido = medicos.firstWhere(
      (medico) => medico.id == _medicoId,
      orElse: () => medicos.first,
    );
    _medicoId = elegido.id;

    // Las dos consultas salen a la vez: los bloques del médico y las reservas
    // que ya los ocuparon, para marcar los que no se pueden cerrar ni borrar.
    final resultados = await Future.wait<Object>([
      servicio.getAvailabilityOfDoctor(doctorId: elegido.id, days: _dias),
      servicio.getReservedSlotKeys(doctorId: elegido.id, days: _dias),
    ]);

    return _PanelAgenda(
      medicos: medicos,
      medico: elegido,
      slots: resultados[0] as List<AvailabilitySlot>,
      reservados: resultados[1] as Set<String>,
    );
  }

  void _elegirMedico(String id) {
    setState(() {
      _medicoId = id;
      _future = _cargar();
    });
  }

  void _refrescar() => setState(() => _future = _cargar());

  // ------------------------------------------------------------
  // Acciones
  // ------------------------------------------------------------

  /// Publica una jornada completa o varias horas sueltas de una sola vez.
  Future<void> _publicar(Doctor medico) async {
    final datos = await showDialog<_DatosBloques>(
      context: context,
      builder: (_) => const _DialogoBloques(),
    );
    if (datos == null || !mounted) return;

    await _ejecutar(() async {
      final creados = await _servicio.createAvailabilitySlotsForDoctor(
        doctorId: medico.id,
        date: datos.fecha,
        times: datos.horas,
      );
      if (creados == 0) {
        return 'Esos bloques ya estaban publicados el '
            '${fechaCorta(datos.fecha)}.';
      }
      return 'Se publicaron $creados bloque(s) el ${fechaCorta(datos.fecha)}.';
    }, mensajeDuplicado: 'Ya existe un bloque para esa fecha y hora.');
  }

  /// Publica un solo bloque en un día que ya tiene bloques.
  Future<void> _agregarHora(Doctor medico, DateTime dia) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Hora de atención',
    );
    if (hora == null || !mounted) return;

    final texto = horaDeMinutos(hora.hour * 60 + hora.minute);

    await _ejecutar(() async {
      await _servicio.createAvailabilitySlot(
        doctorId: medico.id,
        date: dia,
        time: texto,
      );
      return 'Bloque publicado: ${fechaCorta(dia)} a las $texto.';
    }, mensajeDuplicado: 'Ya existe un bloque para esa fecha y hora.');
  }

  Future<void> _cambiarBloque(AvailabilitySlot slot) async {
    final cerrar = slot.isAvailable;

    if (cerrar) {
      final confirmado = await confirmarAdmin(
        context,
        titulo: '¿Cerrar el bloque?',
        mensaje: 'El bloque del ${fechaLarga(slot.date)} a las '
            '${horaCorta(slot.time)} dejará de ofrecerse a los pacientes. '
            'Podés reabrirlo cuando quieras.',
        confirmar: 'Cerrar bloque',
      );
      if (!confirmado || !mounted) return;
    }

    await _ejecutar(() async {
      await _servicio.setAvailabilitySlotAvailable(
        slotId: slot.id,
        available: !cerrar,
      );
      return cerrar ? 'Bloque cerrado.' : 'Bloque reabierto.';
    });
  }

  Future<void> _eliminarBloque(AvailabilitySlot slot) async {
    final confirmado = await confirmarAdmin(
      context,
      titulo: '¿Eliminar el bloque?',
      mensaje: 'Se quitará ${fechaLarga(slot.date)} a las '
          '${horaCorta(slot.time)} de la agenda del médico. Esta acción no se '
          'puede deshacer.',
      confirmar: 'Eliminar',
    );
    if (!confirmado || !mounted) return;

    await _ejecutar(() async {
      await _servicio.deleteAvailabilitySlot(slot.id);
      return 'Bloque eliminado.';
    });
  }

  /// Ejecuta una operación, informa el resultado y recarga los bloques.
  Future<void> _ejecutar(
    Future<String> Function() accion, {
    String? mensajeDuplicado,
  }) async {
    setState(() => _ocupado = true);
    try {
      final exito = await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(exito)));
      _refrescar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MediReservaService.mensajeDeError(
              error,
              mensajeDuplicado: mensajeDuplicado,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // ------------------------------------------------------------
  // Interfaz
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Horarios de los médicos',
      subtitle: 'Publicá, cerrá y reabrí los bloques de atención de un médico',
      showBack: widget.showBack,
      child: FutureBuilder<_PanelAgenda>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (snapshot.hasError) {
            return AdminAviso(
              icono: Icons.cloud_off_outlined,
              mensaje: MediReservaService.mensajeDeError(snapshot.error!),
              onReintentar: _refrescar,
            );
          }

          final panel = snapshot.data;
          if (panel == null || panel.medicos.isEmpty) {
            return AdminAviso(
              icono: Icons.groups_outlined,
              mensaje: 'Todavía no hay médicos registrados.\n\n'
                  'Creá un médico en la sección "Médicos" para poder publicar '
                  'sus horarios.',
              onReintentar: _refrescar,
            );
          }

          final medico = panel.medico!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _selector(panel, medico),
              const SizedBox(height: 14),
              if (panel.slots.isEmpty)
                AdminAviso(
                  icono: Icons.schedule_outlined,
                  mensaje: '${medico.name} no tiene bloques publicados en los '
                      'próximos $_dias días.\n\n'
                      'Publicá una jornada completa o una hora suelta con el '
                      'botón "Publicar bloques".',
                  onReintentar: _refrescar,
                  accion: ElevatedButton.icon(
                    onPressed: _ocupado ? null : () => _publicar(medico),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Publicar bloques'),
                  ),
                )
              else
                _porDia(panel, medico),
            ],
          );
        },
      ),
    );
  }

  Widget _selector(_PanelAgenda panel, Doctor medico) {
    final abiertos = panel.slots.where((slot) => slot.isAvailable).length;
    final reservados = panel.slots
        .where((slot) =>
            panel.reservados.contains(claveBloque(slot.date, slot.time)))
        .length;
    final cerrados = panel.slots.length - abiertos;

    final selector = Row(
      children: [
        const Icon(Icons.medical_services_outlined, color: kMediBlue, size: 20),
        const SizedBox(width: 8),
        const Text(
          'Médico',
          style: TextStyle(color: kMediMuted, fontSize: 12.5),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: DropdownButton<String>(
            value: medico.id,
            isExpanded: true,
            items: [
              for (final item in panel.medicos)
                DropdownMenuItem<String>(
                  value: item.id,
                  child: Text(
                    _etiquetaMedico(item),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _ocupado
                ? null
                : (valor) {
                    if (valor != null) _elegirMedico(valor);
                  },
          ),
        ),
      ],
    );

    final resumen = Text(
      '${medico.specialtyName ?? 'Sin especialidad'} · Próximos $_dias días: '
      '$abiertos disponible(s), $cerrados cerrado(s), $reservados reservado(s)',
      style: const TextStyle(color: kMediMuted, fontSize: 12),
    );

    final publicar = ElevatedButton.icon(
      onPressed: _ocupado ? null : () => _publicar(medico),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Publicar bloques'),
      style: ElevatedButton.styleFrom(
        backgroundColor: kMediBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );

    return AdminCard(
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 720
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: selector),
                      const SizedBox(width: 14),
                      publicar,
                    ],
                  ),
                  const SizedBox(height: 8),
                  resumen,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  selector,
                  const SizedBox(height: 8),
                  resumen,
                  const SizedBox(height: 10),
                  publicar,
                ],
              ),
      ),
    );
  }

  /// Agrupa los bloques por día y los reparte en columnas según el ancho.
  Widget _porDia(_PanelAgenda panel, Doctor medico) {
    final grupos = <String, List<AvailabilitySlot>>{};
    for (final slot in panel.slots) {
      grupos
          .putIfAbsent(fechaIso(slot.date), () => <AvailabilitySlot>[])
          .add(slot);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho >= 1080 ? 3 : (ancho >= 700 ? 2 : 1);
        const separacion = 12.0;
        final anchoTarjeta =
            (ancho - separacion * (columnas - 1)) / columnas;

        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (final grupo in grupos.values)
              SizedBox(
                width: anchoTarjeta,
                child: _tarjetaDia(panel, medico, grupo),
              ),
          ],
        );
      },
    );
  }

  Widget _tarjetaDia(
    _PanelAgenda panel,
    Doctor medico,
    List<AvailabilitySlot> slots,
  ) {
    final dia = slots.first.date;
    final abiertos = slots.where((slot) => slot.isAvailable).length;

    return AdminCard(
      color: const Color(0xFFFDFEFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_outlined,
                  size: 18, color: kMediBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fechaLarga(dia),
                  style: const TextStyle(
                    color: kMediDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$abiertos disponible(s) de ${slots.length} bloque(s)',
            style: const TextStyle(color: kMediMuted, fontSize: 11.5),
          ),
          const Divider(height: 18, color: Color(0xFFE9EDF3)),
          for (final slot in slots) _bloque(panel, slot),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _ocupado ? null : () => _agregarHora(medico, dia),
              icon: const Icon(Icons.add_alarm_outlined, size: 16),
              label: const Text(
                'Agregar hora a este día',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloque(_PanelAgenda panel, AvailabilitySlot slot) {
    final tomado = panel.reservados.contains(claveBloque(slot.date, slot.time));

    final (etiqueta, texto, fondo) = tomado
        ? ('Reservado', const Color(0xFF1A56C4), const Color(0xFFE8F0FE))
        : slot.isAvailable
            ? ('Disponible', const Color(0xFF138A4A), const Color(0xFFDDF5E6))
            : ('Cerrado', const Color(0xFFD32F2F), const Color(0xFFFFE8EA));

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            horaCorta(slot.time),
            style: const TextStyle(
              color: kMediText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          AdminEstado(etiqueta: etiqueta, texto: texto, fondo: fondo),
          const Spacer(),
          // Un bloque ya reservado no se cierra ni se borra: primero hay que
          // cancelar la cita, para no dejar al paciente sin su horario.
          if (tomado)
            const Tooltip(
              message: 'Primero hay que cancelar la cita del paciente',
              child: Icon(Icons.lock_outline, size: 18, color: kMediMuted),
            )
          else ...[
            TextButton(
              onPressed: _ocupado ? null : () => _cambiarBloque(slot),
              child: Text(
                slot.isAvailable ? 'Cerrar' : 'Reabrir',
                style: const TextStyle(fontSize: 12, color: kMediBlue),
              ),
            ),
            TextButton(
              onPressed: _ocupado ? null : () => _eliminarBloque(slot),
              child: const Text(
                'Eliminar',
                style: TextStyle(fontSize: 12, color: Color(0xFFD32F2F)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _etiquetaMedico(Doctor medico) {
    final especialidad = medico.specialtyName ?? 'sin especialidad';
    final estado = medico.active ? '' : ' · inactivo';
    return '${medico.name} — $especialidad$estado';
  }
}

/// Resultado del formulario de publicación de bloques.
class _DatosBloques {
  const _DatosBloques({required this.fecha, required this.horas});

  final DateTime fecha;
  final List<String> horas;
}

/// Formulario para publicar una jornada completa o varias horas sueltas.
class _DialogoBloques extends StatefulWidget {
  const _DialogoBloques();

  @override
  State<_DialogoBloques> createState() => _DialogoBloquesState();
}

class _DialogoBloquesState extends State<_DialogoBloques> {
  static const List<int> _pasos = [30, 45, 60];

  DateTime _fecha = DateTime.now();
  bool _porRango = true;
  TimeOfDay _desde = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _hasta = const TimeOfDay(hour: 12, minute: 0);
  int _paso = 30;
  final List<String> _horas = <String>[];
  String? _error;

  /// Horas que se van a enviar, según el modo elegido.
  ///
  /// El rango se calcula con `rangoDeHoras`, que valida el orden de las horas y
  /// lanza [ArgumentError] si el rango es inválido: acá se traduce a una lista
  /// vacía, que deja el botón "Publicar" deshabilitado.
  List<String> get _calculadas {
    if (!_porRango) return List<String>.unmodifiable(_horas);

    try {
      return rangoDeHoras(
        desde: _hhmmDe(_desde),
        hasta: _hhmmDe(_hasta),
        pasoMinutos: _paso,
      );
    } on ArgumentError {
      return const <String>[];
    }
  }

  String _hhmmDe(TimeOfDay hora) => horaDeMinutos(hora.hour * 60 + hora.minute);

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Fecha de los bloques',
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _fecha = DateTime(elegida.year, elegida.month, elegida.day);
      _error = null;
    });
  }

  Future<void> _agregarHora() async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: _desde,
      helpText: 'Hora de atención',
    );
    if (elegida == null || !mounted) return;

    final texto = _hhmmDe(elegida);
    setState(() {
      if (!_horas.contains(texto)) _horas.add(texto);
      _horas.sort();
      _error = null;
    });
  }

  void _publicar() {
    final horas = _calculadas;
    if (horas.isEmpty) {
      setState(() => _error = 'No hay horas válidas para publicar.');
      return;
    }
    Navigator.pop(
      context,
      _DatosBloques(fecha: _fecha, horas: horas),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horas = _calculadas;

    return AlertDialog(
      title: const Text('Publicar bloques de atención'),
      content: SizedBox(
        width: anchoDialogo(context, deseado: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, color: kMediBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fecha: ${fechaLarga(_fecha)}',
                      style: const TextStyle(color: kMediText, fontSize: 14),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _elegirFecha,
                    child: const Text('Elegir fecha'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _botonModo('Por rango de horas', true),
                  const SizedBox(width: 8),
                  _botonModo('Horas sueltas', false),
                ],
              ),
              const SizedBox(height: 14),
              if (_porRango) ...[
                Row(
                  children: [
                    Expanded(child: _campoHora('Desde', _desde)),
                    const SizedBox(width: 12),
                    Expanded(child: _campoHora('Hasta', _hasta)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Intervalo entre bloques',
                      style: TextStyle(color: kMediMuted, fontSize: 12.5),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: _paso,
                      items: [
                        for (final paso in _pasos)
                          DropdownMenuItem<int>(
                            value: paso,
                            child: Text('$paso minutos',
                                style: const TextStyle(fontSize: 14)),
                          ),
                      ],
                      onChanged: (valor) =>
                          setState(() => _paso = valor ?? 30),
                    ),
                  ],
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _agregarHora,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar hora'),
                ),
                const SizedBox(height: 10),
                if (_horas.isEmpty)
                  const Text(
                    'Todavía no agregaste horas.',
                    style: TextStyle(color: kMediMuted, fontSize: 12.5),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final hora in _horas) _etiquetaHora(hora),
                    ],
                  ),
              ],
              const SizedBox(height: 14),
              Text(
                horas.isEmpty
                    ? (_porRango
                        ? 'Elegí un rango válido: la hora de fin tiene que ser '
                            'posterior a la de inicio.'
                        : 'Agregá al menos una hora para publicar.')
                    : 'Se publicarán ${horas.length} bloque(s): '
                        '${_vistaPrevia(horas)}',
                style: TextStyle(
                  color: horas.isEmpty ? const Color(0xFFD32F2F) : kMediMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: horas.isEmpty ? null : _publicar,
          child: const Text('Publicar'),
        ),
      ],
    );
  }

  Widget _botonModo(String texto, bool rango) {
    final seleccionado = _porRango == rango;
    final alTocar = () => setState(() {
          _porRango = rango;
          _error = null;
        });

    if (seleccionado) {
      return ElevatedButton(
        onPressed: alTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: kMediBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        child: Text(texto),
      );
    }
    return OutlinedButton(onPressed: alTocar, child: Text(texto));
  }

  Widget _campoHora(String etiqueta, TimeOfDay valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(color: kMediMuted, fontSize: 12.5)),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () async {
            final elegida = await showTimePicker(
              context: context,
              initialTime: valor,
              helpText: 'Hora de $etiqueta',
            );
            if (elegida == null || !mounted) return;
            setState(() {
              if (etiqueta == 'Desde') {
                _desde = elegida;
              } else {
                _hasta = elegida;
              }
              _error = null;
            });
          },
          icon: const Icon(Icons.schedule, size: 16),
          label: Text(_hhmmDe(valor)),
        ),
      ],
    );
  }

  Widget _etiquetaHora(String hora) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        border: Border.all(color: const Color(0xFFCFE0FA)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hora,
            style: const TextStyle(color: kMediText, fontSize: 12.5),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: () => setState(() => _horas.remove(hora)),
            child: const Icon(Icons.close, size: 15, color: kMediMuted),
          ),
        ],
      ),
    );
  }

  String _vistaPrevia(List<String> horas) {
    if (horas.length <= 8) return horas.join(', ');
    return '${horas.take(8).join(', ')} …';
  }
}
