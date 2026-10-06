import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';
import 'logout_dialog.dart';

/// Panel de inicio del administrador.
///
/// Reemplaza al inicio del paciente y del profesional: sus tarjetas llevan a
/// las secciones de gestión (especialidades, médicos y horarios) en lugar de a
/// la reserva de citas. Igual que [HomeScreen], identifica las secciones por
/// nombre y no por posición, porque el orden del menú cambia según el rol.
///
/// Esta pantalla no autoriza nada: si una cuenta sin rol de administrador
/// llegara acá, el servidor rechazaría cada escritura con 42501.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, this.onSelectTab});

  final ValueChanged<String>? onSelectTab;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _nombre = 'Administrador';

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    final user = Supabase.instance.client.auth.currentUser;
    final alterno = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (alterno != null && alterno.isNotEmpty && mounted) {
      setState(() => _nombre = alterno.split(' ').first);
    }

    try {
      final perfil =
          await MediReservaService(Supabase.instance.client).getMyProfile();
      final completo = (perfil['full_name'] as String? ?? '').trim();
      if (mounted && completo.isNotEmpty) {
        setState(() => _nombre = completo.split(' ').first);
      }
    } catch (_) {
      // Si el perfil no se puede leer, queda el nombre del registro.
    }
  }

  /// Icono, color, fondo, título, subtítulo y sección de cada tarjeta.
  List<(IconData, Color, Color, String, String, String)> get _tarjetas => [
        (
          Icons.medical_services_outlined,
          Color(0xFF075BD8),
          Color(0xFFF1F6FF),
          'Especialidades',
          'Crear, editar y activar\nlas especialidades',
          'especialidades',
        ),
        (
          Icons.groups_outlined,
          Color(0xFF159447),
          Color(0xFFF1F9F3),
          'Médicos',
          'Alta, edición y\nasignación de especialidad',
          'medicos',
        ),
        (
          Icons.schedule_outlined,
          Color(0xFF6A3FD1),
          Color(0xFFF4F1FE),
          'Horarios',
          'Publicar y cerrar bloques\nde cualquier médico',
          'horarios',
        ),
        (
          Icons.person_outline,
          Color(0xFF075BD8),
          Color(0xFFF1F6FF),
          'Perfil',
          'Ver y editar tus\ndatos de cuenta',
          'perfil',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMediBg,
      appBar: AppBar(
        backgroundColor: kMediBlue,
        elevation: 0,
        toolbarHeight: 52,
        automaticallyImplyLeading: false,
        title: Text(
          '¡Hola, $_nombre!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;
            final columnas = ancho >= 1020 ? 3 : (ancho >= 660 ? 2 : 1);
            const separacion = 14.0;
            final anchoTarjeta =
                (ancho - 28 - separacion * (columnas - 1)) / columnas;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0DA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 16,
                          color: Color(0xFF8A4B00),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Administrador',
                          style: TextStyle(
                            color: Color(0xFF8A4B00),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gestión del sistema',
                    style: TextStyle(
                      color: Color(0xFF53627A),
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: separacion,
                    runSpacing: separacion,
                    children: [
                      for (final tarjeta in _tarjetas)
                        SizedBox(
                          width: anchoTarjeta < 220 ? 220 : anchoTarjeta,
                          child: _TarjetaPanel(
                            icono: tarjeta.$1,
                            color: tarjeta.$2,
                            fondo: tarjeta.$3,
                            titulo: tarjeta.$4,
                            subtitulo: tarjeta.$5,
                            onTap: () => widget.onSelectTab?.call(tarjeta.$6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Como administrador podés crear y desactivar especialidades y '
                    'médicos, y publicar los bloques de atención de cualquier '
                    'profesional. El servidor valida cada cambio según tu rol.',
                    style: TextStyle(color: kMediMuted, fontSize: 12.5, height: 1.45),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Tarjeta de acceso a una sección del panel.
class _TarjetaPanel extends StatelessWidget {
  const _TarjetaPanel({
    required this.icono,
    required this.color,
    required this.fondo,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icono;
  final Color color;
  final Color fondo;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Color(0xFF15213D),
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: Color(0xFF4E5D73),
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
