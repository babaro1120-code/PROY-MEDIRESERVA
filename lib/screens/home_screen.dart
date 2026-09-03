import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/medireserva_service.dart';
import 'logout_dialog.dart';
import 'reservation_start_screen.dart';

/// Sección "Inicio" del menú principal.
///
/// Ya no incluye un menú inferior propio: ese lo aporta [MainShell] de forma
/// fija. Las tarjetas que abren otros módulos usan [onSelectTab] para cambiar
/// de pestaña sin perder la barra inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = 'Paciente';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final user = Supabase.instance.client.auth.currentUser;
    final fallback = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      setState(() => _name = fallback.split(' ').first);
    }
    try {
      final p =
          await MediReservaService(Supabase.instance.client).getMyProfile();
      final full = (p['full_name'] as String? ?? '').trim();
      if (mounted && full.isNotEmpty)
        setState(() => _name = full.split(' ').first);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075BD8),
        elevation: 0,
        toolbarHeight: 50,
        leading: const IconButton(
          onPressed: null,
          icon: Icon(Icons.menu, color: Colors.white, size: 29.7),
        ),
        centerTitle: true,
        title: Text(
          '¡Hola, $_name!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => widget.onSelectTab?.call(3),
            icon: const Icon(Icons.notifications_none_outlined,
                color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            children: [
              const Text(
                '¿Qué deseas hacer hoy?',
                style: TextStyle(
                  color: Color(0xFF53627A),
                  fontSize: 17.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 18.2),
              Row(
                children: [
                  Expanded(
                    child: _card(
                      Icons.calendar_month_outlined,
                      const Color(0xFF075BD8),
                      const Color(0xFFF1F6FF),
                      'Reservar Cita',
                      'Agenda una nueva\nconsulta médica',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReservationStartScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: _card(
                      Icons.calendar_today_outlined,
                      const Color(0xFF159447),
                      const Color(0xFFF1F9F3),
                      'Mis Citas',
                      'Consulta y gestiona\ntus citas',
                      () => widget.onSelectTab?.call(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _card(
                      Icons.person,
                      const Color(0xFF075BD8),
                      const Color(0xFFF1F6FF),
                      'Perfil',
                      'Ver y editar tu\ninformación',
                      () => widget.onSelectTab?.call(2),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: _card(
                      Icons.notifications,
                      const Color(0xFFFFA000),
                      const Color(0xFFFFF8E9),
                      'Notificaciones',
                      'Avisos, recordatorios\ny comunicados',
                      () => widget.onSelectTab?.call(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => showLogoutDialog(context),
                child: Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F4),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFFFE1E5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.power_settings_new,
                          color: Color(0xFFFF1744), size: 33.8),
                      SizedBox(width: 15.6),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              color: Color(0xFF182238),
                              fontSize: 15.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3.9),
                          Text(
                            'Salir de la aplicación',
                            style: TextStyle(
                                color: Color(0xFF657086), fontSize: 12.8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(
    IconData icon,
    Color color,
    Color bg,
    String title,
    String subtitle,
    VoidCallback tap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: tap,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Icon(icon, color: color, size: 35.1),
            ),
            const SizedBox(width: 9.1),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF15213D),
                      fontSize: 15.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5.2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF4E5D73),
                      fontSize: 12.8,
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
