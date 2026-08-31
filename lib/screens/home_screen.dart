import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'specialties_screen.dart';

import '../config/app_config.dart';
import '../controllers/preferences_controller.dart';
import 'records_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $error'),
          ),
        );
      }
    }
  }

  // ============================================================
  // NAVEGACIÓN
  // ============================================================

  void _onNavigationItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ============================================================
  // ACCIONES DE LAS TARJETAS
  // ============================================================

  void _reservarCita() {
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (context) {
        return const SpecialtiesScreen();
      },
    ),
  );
}

  void _misCitas() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const RecordsScreen(),
      ),
    );
  }

  void _perfil() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _notificaciones() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Módulo de Notificaciones'),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final preferences = context.watch<PreferencesController>();

    final name = preferences.name.isEmpty
        ? 'Paciente'
        : preferences.name;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),

      // ========================================================
      // BARRA SUPERIOR
      // ========================================================

      appBar: AppBar(
        automaticallyImplyLeading: false,

        backgroundColor: const Color(0xFF075BD8),

        elevation: 0,

        toolbarHeight: 50,

        leading: IconButton(
  icon: const Icon(
    Icons.menu,
    color: Colors.white,
    size: 22,
  ),
  onPressed: () {
    // Acción temporal o menú personalizado
  },
),

        centerTitle: true,

        title: Text(
          '¡Hola, $name!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.white,
              size: 23,
            ),
            onPressed: _notificaciones,
          ),
        ],
      ),

      // ========================================================
      // CUERPO
      // ========================================================

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  14,
                  14,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ------------------------------------------------
                    // SALUDO
                    // ------------------------------------------------

                    const Text(
                      '¿Qué deseas hacer hoy?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF53627A),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ------------------------------------------------
                    // PRIMERA FILA
                    // ------------------------------------------------

                    Row(
                      children: [
                        Expanded(
                          child: _DashboardCard(
                            icon: Icons.calendar_month_outlined,
                            iconColor: const Color(0xFF075BD8),
                            backgroundColor:
                                const Color(0xFFF1F6FF),
                            title: 'Reservar Cita',
                            subtitle:
                                'Agenda una nueva\nconsulta médica',
                            onTap: _reservarCita,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _DashboardCard(
                            icon: Icons.calendar_today_outlined,
                            iconColor: const Color(0xFF159447),
                            backgroundColor:
                                const Color(0xFFF1F9F3),
                            title: 'Mis Citas',
                            subtitle:
                                'Consulta y gestiona\ntus citas',
                            onTap: _misCitas,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ------------------------------------------------
                    // SEGUNDA FILA
                    // ------------------------------------------------

                    Row(
                      children: [
                        Expanded(
                          child: _DashboardCard(
                            icon: Icons.person,
                            iconColor: const Color(0xFF075BD8),
                            backgroundColor:
                                const Color(0xFFF1F6FF),
                            title: 'Perfil',
                            subtitle:
                                'Ver y editar tu\ninformación',
                            onTap: _perfil,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _DashboardCard(
                            icon: Icons.notifications,
                            iconColor: const Color(0xFFFFA000),
                            backgroundColor:
                                const Color(0xFFFFF8E9),
                            title: 'Notificaciones',
                            subtitle:
                                'Avisos, recordatorios\ny comunicados',
                            onTap: _notificaciones,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ------------------------------------------------
                    // CERRAR SESIÓN
                    // ------------------------------------------------

                    _LogoutCard(
                      onTap: _signOut,
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ==========================================================
      // BARRA DE NAVEGACIÓN INFERIOR
      // ==========================================================

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,

          onTap: _onNavigationItemSelected,

          backgroundColor: Colors.white,

          elevation: 0,

          type: BottomNavigationBarType.fixed,

          selectedItemColor: const Color(0xFF075BD8),

          unselectedItemColor: const Color(0xFF6B778C),

          selectedFontSize: 9,

          unselectedFontSize: 9,

          iconSize: 19,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Citas',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notificaciones',
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// TARJETA DEL DASHBOARD
// ================================================================

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,

      child: Container(
        height: 72,

        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(9),

          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),

        child: Row(
          children: [
            // ------------------------------------------------------
            // ICONO
            // ------------------------------------------------------

            SizedBox(
              width: 35,
              child: Icon(
                icon,
                color: iconColor,
                size: 26,
              ),
            ),

            const SizedBox(width: 7),

            // ------------------------------------------------------
            // TEXTO
            // ------------------------------------------------------

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Color(0xFF15213D),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,

                    style: const TextStyle(
                      color: Color(0xFF4E5D73),
                      fontSize: 8,
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

// ================================================================
// TARJETA CERRAR SESIÓN
// ================================================================

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),

      onTap: onTap,

      child: Container(
        height: 58,

        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: const Color(0xFFFFF2F4),

          borderRadius: BorderRadius.circular(9),

          border: Border.all(
            color: const Color(0xFFFFE1E5),
          ),
        ),

        child: Row(
          children: [
            const Icon(
              Icons.power_settings_new,
              color: Color(0xFFFF1744),
              size: 25,
            ),

            const SizedBox(width: 12),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: const [
                Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Color(0xFF182238),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Salir de la aplicación',
                  style: TextStyle(
                    color: Color(0xFF657086),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}