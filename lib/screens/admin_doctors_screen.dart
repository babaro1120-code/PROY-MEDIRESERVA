import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../services/medireserva_service.dart';
import '../widgets/admin_ui.dart';
import '../widgets/medireserva_ui.dart';

/// Gestión de médicos: ver, crear, editar, activar/desactivar y asignar su
/// especialidad y su cuenta de usuario.
///
/// Trabaja sobre la tabla `doctors` (`name`, `specialty_id`, `photo_url`,
/// `experience_years`, `rating`, `active`, `profile_id`). La columna
/// `profile_id` es la que usa la política `availability_profesional_o_admin_write`
/// mediante `es_mi_agenda()`: hasta que un médico no está vinculado a su cuenta,
/// ese profesional no puede administrar su propia agenda.
class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key, this.showBack = false});

  final bool showBack;

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

/// Todo lo que la pantalla necesita, en una sola carga concurrente.
class _PanelMedicos {
  const _PanelMedicos({
    required this.medicos,
    required this.especialidades,
    required this.perfiles,
  });

  final List<Doctor> medicos;
  final List<Specialty> especialidades;
  final List<Map<String, dynamic>> perfiles;
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  late Future<_PanelMedicos> _future;
  bool _ocupado = false;

  MediReservaService get _servicio => MediReservaService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<_PanelMedicos> _cargar() async {
    final servicio = _servicio;
    // Las tres consultas salen a la vez: la lista, las especialidades para el
    // selector y los perfiles que se pueden vincular. Se esperan todas aunque
    // una falle, así no queda ningún error sin recoger.
    final resultados = await Future.wait<Object>([
      servicio.getAllDoctors(),
      servicio.getAllSpecialties(),
      servicio.getProfilesForLinking(),
    ]);

    return _PanelMedicos(
      medicos: resultados[0] as List<Doctor>,
      especialidades: resultados[1] as List<Specialty>,
      perfiles: resultados[2] as List<Map<String, dynamic>>,
    );
  }

  void _refrescar() => setState(() => _future = _cargar());

  // ------------------------------------------------------------
  // Acciones
  // ------------------------------------------------------------

  Future<void> _crear(_PanelMedicos panel) async {
    if (panel.especialidades.isEmpty) {
      _avisar('Primero creá al menos una especialidad en la sección '
          '"Especialidades".');
      return;
    }

    final datos = await showDialog<_DatosMedico>(
      context: context,
      builder: (_) => _DialogoMedico(
        especialidades: panel.especialidades,
        perfiles: panel.perfiles,
      ),
    );
    if (datos == null || !mounted) return;

    await _ejecutar(() async {
      await _servicio.createDoctor(
        name: datos.nombre,
        specialtyId: datos.especialidadId,
        photoUrl: datos.fotoUrl,
        experienceYears: datos.experiencia,
        rating: datos.valoracion,
        profileId: datos.cuentaId,
      );
      return 'Médico "${datos.nombre}" creado.';
    });
  }

  Future<void> _editar(_PanelMedicos panel, Doctor medico) async {
    if (panel.especialidades.isEmpty) {
      _avisar('No hay especialidades cargadas: creá una antes de editar '
          'médicos.');
      return;
    }

    final datos = await showDialog<_DatosMedico>(
      context: context,
      builder: (_) => _DialogoMedico(
        especialidades: panel.especialidades,
        perfiles: panel.perfiles,
        inicial: medico,
      ),
    );
    if (datos == null || !mounted) return;

    await _ejecutar(() async {
      await _servicio.updateDoctor(
        id: medico.id,
        name: datos.nombre,
        specialtyId: datos.especialidadId,
        photoUrl: datos.fotoUrl,
        experienceYears: datos.experiencia,
        rating: datos.valoracion,
        profileId: datos.cuentaId,
      );
      return 'Datos de "${datos.nombre}" actualizados.';
    }, mensajeDuplicado: 'Esa cuenta ya está vinculada a otro médico.');
  }

  Future<void> _cambiarEstado(Doctor medico) async {
    final desactivar = medico.active;

    if (desactivar) {
      final confirmado = await confirmarAdmin(
        context,
        titulo: '¿Desactivar al médico?',
        mensaje: '${medico.name} dejará de aparecer en el catálogo y no podrá '
            'recibir reservas nuevas. Sus citas ya agendadas se conservan y '
            'podés reactivarlo cuando quieras.',
        confirmar: 'Desactivar',
      );
      if (!confirmado || !mounted) return;
    }

    await _ejecutar(() async {
      await _servicio.setDoctorActive(id: medico.id, active: !medico.active);
      return desactivar ? 'Médico desactivado.' : 'Médico reactivado.';
    });
  }

  /// Ejecuta una operación, informa el resultado y recarga la lista.
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

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ------------------------------------------------------------
  // Interfaz
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Médicos',
      subtitle: 'Profesionales, su especialidad y su cuenta de usuario',
      showBack: widget.showBack,
      child: FutureBuilder<_PanelMedicos>(
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
          if (panel == null) {
            return AdminAviso(
              icono: Icons.groups_outlined,
              mensaje: 'No se pudo cargar la lista de médicos.',
              onReintentar: _refrescar,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _ocupado ? null : () => _crear(panel),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo médico'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMediBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (panel.medicos.isEmpty)
                AdminAviso(
                  icono: Icons.groups_outlined,
                  mensaje: 'Todavía no hay médicos registrados.\n\n'
                      'Creá el primero con el botón "Nuevo médico" y asignale '
                      'su especialidad. Después podrás publicar sus horarios en '
                      'la sección "Horarios".',
                  onReintentar: _refrescar,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) =>
                      constraints.maxWidth >= 860
                          ? _tabla(panel)
                          : _tarjetas(panel),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _tabla(_PanelMedicos panel) {
    return AdminTabla(
      columnas: const [
        AdminColumna('Médico', flex: 4),
        AdminColumna('Especialidad', flex: 3),
        AdminColumna('Cuenta vinculada', flex: 3),
        AdminColumna('Estado', ancho: 95),
        AdminColumna('Acciones', ancho: 220),
      ],
      filas: [
        for (final medico in panel.medicos)
          [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFEAF2FF),
                  backgroundImage: (medico.photoUrl ?? '').isEmpty
                      ? null
                      : NetworkImage(medico.photoUrl!),
                  child: (medico.photoUrl ?? '').isEmpty
                      ? const Icon(Icons.person, color: kMediBlue, size: 18)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medico.name,
                        style: const TextStyle(
                          color: kMediText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _detalle(medico),
                        style: const TextStyle(color: kMediMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              medico.specialtyName ?? 'Sin especialidad',
              style: const TextStyle(color: kMediText, fontSize: 13.5),
            ),
            Text(
              _etiquetaCuenta(panel, medico.profileId),
              style: TextStyle(
                color: medico.profileId == null ? kMediMuted : kMediText,
                fontSize: 13,
              ),
            ),
            AdminEstado.activo(medico.active),
            _acciones(panel, medico),
          ],
      ],
    );
  }

  Widget _tarjetas(_PanelMedicos panel) {
    return Column(
      children: [
        for (final medico in panel.medicos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFEAF2FF),
                        backgroundImage: (medico.photoUrl ?? '').isEmpty
                            ? null
                            : NetworkImage(medico.photoUrl!),
                        child: (medico.photoUrl ?? '').isEmpty
                            ? const Icon(Icons.person, color: kMediBlue, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medico.name,
                              style: const TextStyle(
                                color: kMediText,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${medico.specialtyName ?? 'Sin especialidad'} · ${_detalle(medico)}',
                              style: const TextStyle(
                                color: kMediMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AdminEstado.activo(medico.active),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuenta: ${_etiquetaCuenta(panel, medico.profileId)}',
                    style: const TextStyle(color: kMediMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  _acciones(panel, medico),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _acciones(_PanelMedicos panel, Doctor medico) {
    // Wrap y no Row: si el ancho de la columna no alcanza, los botones bajan a
    // una segunda línea en lugar de desbordar.
    return Wrap(
      spacing: 2,
      children: [
        TextButton.icon(
          onPressed: _ocupado ? null : () => _editar(panel, medico),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Editar', style: TextStyle(fontSize: 12.5)),
        ),
        TextButton.icon(
          onPressed: _ocupado ? null : () => _cambiarEstado(medico),
          icon: Icon(
            medico.active ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
            size: 18,
          ),
          label: Text(
            medico.active ? 'Desactivar' : 'Activar',
            style: TextStyle(
              fontSize: 12.5,
              color: medico.active ? const Color(0xFFD32F2F) : kMediBlue,
            ),
          ),
        ),
      ],
    );
  }

  String _detalle(Doctor medico) {
    final experiencia = '${medico.experienceYears} año(s) de experiencia';
    final valoracion = '★ ${medico.rating.toStringAsFixed(1)}';
    return '$experiencia · $valoracion';
  }

  String _etiquetaCuenta(_PanelMedicos panel, String? profileId) {
    if (profileId == null) return 'Sin vincular';
    for (final perfil in panel.perfiles) {
      if (perfil['id'].toString() == profileId) return _etiquetaPerfil(perfil);
    }
    return 'Cuenta no visible';
  }
}

/// Resumen legible de un perfil para los selectores del panel.
String _etiquetaPerfil(Map<String, dynamic> perfil) {
  final nombre = (perfil['full_name'] as String? ?? '').trim();
  final correo = (perfil['email'] as String? ?? '').trim();
  final rol = (perfil['role'] as String? ?? '').trim();

  final String base;
  if (nombre.isEmpty && correo.isEmpty) {
    base = 'Perfil sin datos';
  } else if (nombre.isEmpty) {
    base = correo;
  } else if (correo.isEmpty) {
    base = nombre;
  } else {
    base = '$nombre — $correo';
  }

  return rol.isEmpty ? base : '$base ($rol)';
}

/// Resultado del formulario de médico.
class _DatosMedico {
  const _DatosMedico({
    required this.nombre,
    required this.especialidadId,
    required this.experiencia,
    required this.valoracion,
    this.fotoUrl,
    this.cuentaId,
  });

  final String nombre;
  final String especialidadId;
  final int experiencia;
  final double valoracion;
  final String? fotoUrl;
  final String? cuentaId;
}

/// Formulario de alta y edición de un médico.
class _DialogoMedico extends StatefulWidget {
  const _DialogoMedico({
    required this.especialidades,
    required this.perfiles,
    this.inicial,
  });

  final List<Specialty> especialidades;
  final List<Map<String, dynamic>> perfiles;
  final Doctor? inicial;

  @override
  State<_DialogoMedico> createState() => _DialogoMedicoState();
}

class _DialogoMedicoState extends State<_DialogoMedico> {
  late final TextEditingController _nombre;
  late final TextEditingController _experiencia;
  late final TextEditingController _valoracion;
  late final TextEditingController _foto;
  String _especialidadId = '';

  /// Cadena vacía significa "sin vincular".
  String _cuentaId = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final inicial = widget.inicial;

    _nombre = TextEditingController(text: inicial?.name ?? '');
    _experiencia = TextEditingController(
      text: inicial == null ? '0' : '${inicial.experienceYears}',
    );
    _valoracion = TextEditingController(
      text: inicial == null ? '0' : inicial.rating.toStringAsFixed(1),
    );
    _foto = TextEditingController(text: inicial?.photoUrl ?? '');
    _cuentaId = inicial?.profileId ?? '';

    final especialidad = inicial?.specialtyId ?? '';
    final existe = widget.especialidades.any((e) => e.id == especialidad);
    _especialidadId =
        existe ? especialidad : (widget.especialidades.first.id);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _experiencia.dispose();
    _valoracion.dispose();
    _foto.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'El nombre del médico es obligatorio.');
      return;
    }

    if (_especialidadId.isEmpty) {
      setState(() => _error = 'Elegí la especialidad del médico.');
      return;
    }

    final experienciaTexto = _experiencia.text.trim();
    final experiencia = int.tryParse(experienciaTexto.isEmpty ? '0' : experienciaTexto);
    if (experiencia == null) {
      setState(() => _error = 'Los años de experiencia deben ser un número entero.');
      return;
    }
    if (experiencia < 0 || experiencia > 70) {
      setState(() => _error = 'Los años de experiencia deben estar entre 0 y 70.');
      return;
    }

    final valoracionTexto = _valoracion.text.trim();
    final valoracion = double.tryParse(valoracionTexto.isEmpty ? '0' : valoracionTexto);
    if (valoracion == null) {
      setState(() => _error = 'La valoración debe ser un número, por ejemplo 4.5.');
      return;
    }
    if (valoracion < 0 || valoracion > 5) {
      setState(() => _error = 'La valoración debe estar entre 0 y 5.');
      return;
    }

    Navigator.pop(
      context,
      _DatosMedico(
        nombre: nombre,
        especialidadId: _especialidadId,
        experiencia: experiencia,
        valoracion: valoracion,
        fotoUrl: _foto.text.trim(),
        cuentaId: _cuentaId.isEmpty ? null : _cuentaId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.inicial == null ? 'Nuevo médico' : 'Editar médico'),
      content: SizedBox(
        width: anchoDialogo(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminCampo(
                controlador: _nombre,
                etiqueta: 'Nombre completo',
                icono: Icons.person_outline,
                ayuda: 'Como debe verlo el paciente: Dra. Ana López.',
              ),
              const Text(
                'Especialidad',
                style: TextStyle(color: kMediMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              InputDecorator(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE0E6EE)),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _especialidadId,
                  isExpanded: true,
                  items: [
                    for (final especialidad in widget.especialidades)
                      DropdownMenuItem<String>(
                        value: especialidad.id,
                        child: Text(
                          especialidad.active
                              ? especialidad.name
                              : '${especialidad.name} (inactiva)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                  onChanged: (valor) =>
                      setState(() => _especialidadId = valor ?? ''),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AdminCampo(
                      controlador: _experiencia,
                      etiqueta: 'Años de experiencia',
                      icono: Icons.timeline_outlined,
                      tipo: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminCampo(
                      controlador: _valoracion,
                      etiqueta: 'Valoración (0 a 5)',
                      icono: Icons.star_outline,
                      tipo: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              AdminCampo(
                controlador: _foto,
                etiqueta: 'URL de la foto (opcional)',
                icono: Icons.image_outlined,
                ayuda: 'Si se deja vacío, el catálogo muestra un icono genérico.',
              ),
              const Text(
                'Cuenta de usuario vinculada',
                style: TextStyle(color: kMediMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              InputDecorator(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE0E6EE)),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _valorCuenta(widget.perfiles),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text(
                        'Sin vincular',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    for (final perfil in widget.perfiles)
                      DropdownMenuItem<String>(
                        value: perfil['id'].toString(),
                        child: Text(
                          _etiquetaPerfil(perfil),
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (valor) => setState(() => _cuentaId = valor ?? ''),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Al vincular una cuenta, ese profesional podrá administrar su '
                'propia agenda en la aplicación.',
                style: TextStyle(color: kMediMuted, fontSize: 11.5),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12.5),
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
          onPressed: _guardar,
          child: Text(widget.inicial == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }

  /// La cuenta elegida tiene que existir en la lista, si no el selector rompe.
  String _valorCuenta(List<Map<String, dynamic>> perfiles) {
    if (_cuentaId.isEmpty) return '';
    final existe = perfiles.any((p) => p['id'].toString() == _cuentaId);
    return existe ? _cuentaId : '';
  }
}
