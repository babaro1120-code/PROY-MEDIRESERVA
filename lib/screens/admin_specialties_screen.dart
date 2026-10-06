import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../services/medireserva_service.dart';
import '../utils/medireserva_iconos.dart';
import '../widgets/admin_ui.dart';
import '../widgets/medireserva_ui.dart';

/// Gestión de especialidades: ver, crear, editar y activar/desactivar.
///
/// Trabaja sobre la tabla `specialties` (`name`, `icon_name`, `active`). El
/// administrador ve también las desactivadas porque `specialties_admin_write`
/// es una política permisiva `for all`; el resto de los roles solo recibe las
/// activas. Quien autoriza de verdad es el servidor: si la cuenta no es
/// administradora, cada escritura falla con 42501 y se traduce con
/// [MediReservaService.mensajeDeError].
class AdminSpecialtiesScreen extends StatefulWidget {
  const AdminSpecialtiesScreen({super.key, this.showBack = false});

  final bool showBack;

  @override
  State<AdminSpecialtiesScreen> createState() => _AdminSpecialtiesScreenState();
}

class _AdminSpecialtiesScreenState extends State<AdminSpecialtiesScreen> {
  late Future<List<Specialty>> _future;
  bool _ocupado = false;

  MediReservaService get _servicio => MediReservaService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<Specialty>> _cargar() => _servicio.getAllSpecialties();

  void _refrescar() => setState(() => _future = _cargar());

  // ------------------------------------------------------------
  // Acciones
  // ------------------------------------------------------------

  Future<void> _crear() async {
    final datos = await showDialog<_DatosEspecialidad>(
      context: context,
      builder: (_) => const _DialogoEspecialidad(),
    );
    if (datos == null || !mounted) return;

    await _ejecutar(
      () async {
        await _servicio.createSpecialty(
          name: datos.nombre,
          iconName: datos.icono,
        );
        return 'Especialidad "${datos.nombre}" creada.';
      },
      mensajeDuplicado: 'Ya existe una especialidad con ese nombre.',
    );
  }

  Future<void> _editar(Specialty especialidad) async {
    final datos = await showDialog<_DatosEspecialidad>(
      context: context,
      builder: (_) => _DialogoEspecialidad(inicial: especialidad),
    );
    if (datos == null || !mounted) return;

    await _ejecutar(
      () async {
        await _servicio.updateSpecialty(
          id: especialidad.id,
          name: datos.nombre,
          iconName: datos.icono,
        );
        return 'Especialidad actualizada.';
      },
      mensajeDuplicado: 'Ya existe otra especialidad con ese nombre.',
    );
  }

  Future<void> _cambiarEstado(Specialty especialidad) async {
    final desactivar = especialidad.active;

    if (desactivar) {
      final confirmado = await confirmarAdmin(
        context,
        titulo: '¿Desactivar la especialidad?',
        mensaje: 'Dejará de ofrecerse en el catálogo de los pacientes. Las '
            'reservas ya hechas la conservan y podés reactivarla cuando '
            'quieras.',
        confirmar: 'Desactivar',
      );
      if (!confirmado || !mounted) return;
    }

    await _ejecutar(
      () async {
        await _servicio.setSpecialtyActive(
          id: especialidad.id,
          active: !especialidad.active,
        );
        return desactivar
            ? 'Especialidad desactivada.'
            : 'Especialidad reactivada.';
      },
    );
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

  // ------------------------------------------------------------
  // Interfaz
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Especialidades',
      subtitle: 'Catálogo de especialidades médicas del sistema',
      showBack: widget.showBack,
      acciones: [
        ElevatedButton.icon(
          onPressed: _ocupado ? null : _crear,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nueva especialidad'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kMediBlue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ],
      child: FutureBuilder<List<Specialty>>(
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

          final items = snapshot.data ?? const <Specialty>[];
          if (items.isEmpty) {
            return AdminAviso(
              icono: Icons.medical_services_outlined,
              mensaje: 'Todavía no hay especialidades cargadas.\n\n'
                  'Creá la primera con el botón "Nueva especialidad" para que '
                  'los pacientes puedan reservar turnos.',
              onReintentar: _refrescar,
              accion: ElevatedButton.icon(
                onPressed: _crear,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva especialidad'),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 760
                ? _tabla(items)
                : _tarjetas(items),
          );
        },
      ),
    );
  }

  Widget _tabla(List<Specialty> items) {
    return AdminTabla(
      columnas: const [
        AdminColumna('Especialidad', flex: 5),
        AdminColumna('Estado', ancho: 100),
        AdminColumna('Acciones', ancho: 240),
      ],
      filas: [
        for (final item in items)
          [
            Row(
              children: [
                Icon(iconoDeEspecialidad(item.iconName), color: kMediBlue, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: kMediText,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            AdminEstado.activo(item.active),
            _acciones(item),
          ],
      ],
    );
  }

  Widget _tarjetas(List<Specialty> items) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(iconoDeEspecialidad(item.iconName),
                          color: kMediBlue, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: kMediText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AdminEstado.activo(item.active),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _acciones(item),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _acciones(Specialty item) {
    // Wrap y no Row: si el ancho de la columna no alcanza, los botones bajan a
    // una segunda línea en lugar de desbordar.
    return Wrap(
      spacing: 2,
      children: [
        TextButton.icon(
          onPressed: _ocupado ? null : () => _editar(item),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Editar', style: TextStyle(fontSize: 12.5)),
        ),
        TextButton.icon(
          onPressed: _ocupado ? null : () => _cambiarEstado(item),
          icon: Icon(
            item.active ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
            size: 18,
          ),
          label: Text(
            item.active ? 'Desactivar' : 'Activar',
            style: TextStyle(
              fontSize: 12.5,
              color: item.active ? const Color(0xFFD32F2F) : kMediBlue,
            ),
          ),
        ),
      ],
    );
  }
}

/// Resultado del formulario de especialidad.
class _DatosEspecialidad {
  const _DatosEspecialidad({required this.nombre, this.icono});

  final String nombre;
  final String? icono;
}

/// Formulario de alta y edición de una especialidad.
class _DialogoEspecialidad extends StatefulWidget {
  const _DialogoEspecialidad({this.inicial});

  final Specialty? inicial;

  @override
  State<_DialogoEspecialidad> createState() => _DialogoEspecialidadState();
}

class _DialogoEspecialidadState extends State<_DialogoEspecialidad> {
  late final TextEditingController _nombre;

  /// Cadena vacía significa "sin icono": así el selector permite quitarlo.
  String _icono = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.inicial?.name ?? '');
    final guardado = widget.inicial?.iconName;
    // El selector solo admite valores de la lista: un icono desconocido
    // (guardado por otro medio) se muestra como "sin icono" en vez de romper.
    _icono = guardado != null && nombresDeIconos.contains(guardado)
        ? guardado
        : '';
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'El nombre de la especialidad es obligatorio.');
      return;
    }
    Navigator.pop(
      context,
      _DatosEspecialidad(
        nombre: nombre,
        icono: _icono.isEmpty ? null : _icono,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.inicial == null ? 'Nueva especialidad' : 'Editar especialidad',
      ),
      content: SizedBox(
        width: anchoDialogo(context, deseado: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminCampo(
                controlador: _nombre,
                etiqueta: 'Nombre',
                icono: Icons.medical_services_outlined,
                ayuda: 'Por ejemplo: Cardiología. No puede repetirse.',
              ),
              const Text(
                'Icono del catálogo',
                style: TextStyle(color: kMediMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    iconoDeEspecialidad(_icono.isEmpty ? null : _icono),
                    color: kMediBlue,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _icono,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text(
                            'Sin icono',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        for (final nombre in nombresDeIconos)
                          DropdownMenuItem<String>(
                            value: nombre,
                            child: Text(
                              etiquetaDeIcono(nombre),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                      onChanged: (valor) => setState(() => _icono = valor ?? ''),
                    ),
                  ),
                ],
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
}
