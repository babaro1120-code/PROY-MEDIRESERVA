import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';
import 'admin_availability_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_home_screen.dart';
import 'admin_specialties_screen.dart';
import 'agenda_screen.dart';
import 'appointments_screen.dart';
import 'availability_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Ancho a partir del cual la navegación deja la barra inferior y pasa a la
/// barra lateral de escritorio.
const double kAnchoEscritorio = 900;

/// Ancho a partir del cual la barra lateral muestra también las etiquetas.
const double kAnchoRailExtendido = 1240;

/// Descripción de un módulo del menú de navegación.
class _Destino {
  const _Destino(this.clave, this.etiqueta, this.icono, this.iconoActivo);

  final String clave;
  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
}

/// Contenedor principal, sensible al rol y al ancho de la pantalla.
///
/// · Rol `paciente` y `profesional`: los módulos de siempre (inicio, agenda,
///   horarios, citas, perfil y avisos), sin cambios.
/// · Rol `administrador`: las secciones de gestión (panel de inicio,
///   especialidades, médicos, horarios y perfil). No ve "Citas" ni "Avisos"
///   porque su trabajo es mantener el catálogo y las agendas.
///
/// · Pantalla ancha (≥ [kAnchoEscritorio]): [NavigationRail] lateral, que a
///   partir de [kAnchoRailExtendido] se muestra extendida con las etiquetas.
/// · Pantalla angosta: la barra inferior de siempre, como en el móvil.
///
/// El rol lo resuelve el servidor; esta pantalla solo decide qué mostrar. Cada
/// sección conserva su propia pila de navegación ([Navigator]), así que el menú
/// sigue visible tanto al cambiar de módulo como al navegar dentro de uno.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  String _rol = 'paciente';
  final Map<String, GlobalKey<NavigatorState>> _claves = {};

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

  /// El rol define qué módulos se ofrecen. Ante cualquier error se conserva el
  /// rol de menor privilegio.
  Future<void> _cargarRol() async {
    try {
      final rol =
          await MediReservaService(Supabase.instance.client).getMyRole();
      if (mounted) setState(() => _rol = rol);
    } catch (_) {
      // Se mantiene 'paciente'.
    }
  }

  bool get _atiendeAgenda => _rol == 'profesional' || _rol == 'administrador';

  bool get _esAdministrador => _rol == 'administrador';

  List<_Destino> get _destinos {
    if (_esAdministrador) {
      return const [
        _Destino('inicio', 'Panel', Icons.dashboard_outlined, Icons.dashboard),
        _Destino(
          'especialidades',
          'Especialidades',
          Icons.medical_services_outlined,
          Icons.medical_services,
        ),
        _Destino('medicos', 'Médicos', Icons.groups_outlined, Icons.groups),
        _Destino('horarios', 'Horarios', Icons.schedule_outlined, Icons.schedule),
        _Destino('perfil', 'Perfil', Icons.person_outline, Icons.person),
      ];
    }

    return [
      const _Destino('inicio', 'Inicio', Icons.home_outlined, Icons.home),
      if (_atiendeAgenda)
        const _Destino(
            'agenda', 'Agenda', Icons.event_note_outlined, Icons.event_note),
      // RF-07: el profesional publica los bloques de atención de su agenda; el
      // paciente no administra ninguna.
      if (_atiendeAgenda)
        const _Destino('horarios', 'Horarios', Icons.schedule_outlined,
            Icons.schedule),
      const _Destino('citas', 'Citas', Icons.calendar_month_outlined,
          Icons.calendar_month),
      const _Destino('perfil', 'Perfil', Icons.person_outline, Icons.person),
      const _Destino('notificaciones', 'Avisos',
          Icons.notifications_none_outlined, Icons.notifications),
    ];
  }

  GlobalKey<NavigatorState> _claveDe(String clave) =>
      _claves.putIfAbsent(clave, () => GlobalKey<NavigatorState>());

  Widget _raizDe(String clave) => switch (clave) {
        'inicio' => _esAdministrador
            ? AdminHomeScreen(onSelectTab: _irA)
            : HomeScreen(onSelectTab: _irA, rol: _rol),
        'especialidades' => const AdminSpecialtiesScreen(),
        'medicos' => const AdminDoctorsScreen(),
        'agenda' => const AgendaScreen(showBack: false),
        // El administrador elige el médico; el profesional trabaja sobre el
        // suyo. Son pantallas distintas a propósito.
        'horarios' => _esAdministrador
            ? const AdminAvailabilityScreen()
            : const AvailabilityScreen(showBack: false),
        'citas' => const AppointmentsScreen(showBack: false),
        'perfil' => const ProfileScreen(showBack: false),
        'notificaciones' => const NotificationsScreen(showBack: false),
        _ => HomeScreen(onSelectTab: _irA, rol: _rol),
      };

  /// Navega por nombre de módulo, no por posición: el orden cambia según el rol.
  void _irA(String clave) {
    final destinos = _destinos;
    final destino = destinos.indexWhere((d) => d.clave == clave);
    if (destino >= 0) _seleccionar(destino);
  }

  void _seleccionar(int index) {
    final destinos = _destinos;
    if (index < 0 || index >= destinos.length) return;

    if (index == _index) {
      // Si ya estamos en la sección, volvemos a su raíz.
      _claveDe(destinos[index].clave)
          .currentState
          ?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final destinos = _destinos;
    final actual = _index.clamp(0, destinos.length - 1);

    // Cada sección conserva su propia pila de navegación.
    final pantallas = IndexedStack(
      index: actual,
      children: [
        for (final destino in destinos)
          Navigator(
            key: _claveDe(destino.clave),
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => _raizDe(destino.clave),
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kAnchoEscritorio) {
          return _conBarraLateral(
            destinos: destinos,
            actual: actual,
            extendida: constraints.maxWidth >= kAnchoRailExtendido,
            pantallas: pantallas,
          );
        }
        return _conBarraInferior(destinos: destinos, actual: actual, pantallas: pantallas);
      },
    );
  }

  /// Escritorio: barra lateral con las secciones y el contenido a la derecha.
  Widget _conBarraLateral({
    required List<_Destino> destinos,
    required int actual,
    required bool extendida,
    required Widget pantallas,
  }) {
    return Scaffold(
      backgroundColor: kMediBg,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: actual,
            onDestinationSelected: _seleccionar,
            extended: extendida,
            labelType: extendida ? null : NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFE7EFFC),
            selectedIconTheme: const IconThemeData(color: kMediBlue),
            unselectedIconTheme: const IconThemeData(color: Color(0xFF6B778C)),
            selectedLabelTextStyle: const TextStyle(
              color: kMediBlue,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Color(0xFF6B778C),
              fontSize: 12.5,
            ),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Icon(
                Icons.local_hospital_outlined,
                color: kMediBlue,
                size: 30,
              ),
            ),
            destinations: [
              for (final destino in destinos)
                NavigationRailDestination(
                  icon: Icon(destino.icono),
                  selectedIcon: Icon(destino.iconoActivo),
                  label: Text(destino.etiqueta),
                ),
            ],
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE0E6EE)),
          Expanded(child: pantallas),
        ],
      ),
    );
  }

  /// Móvil y tablet angosta: la barra inferior de siempre.
  Widget _conBarraInferior({
    required List<_Destino> destinos,
    required int actual,
    required Widget pantallas,
  }) {
    // Con cinco pestañas la etiqueta necesita menos cuerpo para no cortarse.
    final cuerpo = destinos.length >= 5 ? 10.4 : 14.4;

    return Scaffold(
      backgroundColor: kMediBg,
      body: pantallas,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: actual,
        onTap: _seleccionar,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: kMediBlue,
        unselectedItemColor: const Color(0xFF6B778C),
        selectedFontSize: cuerpo,
        unselectedFontSize: cuerpo,
        items: [
          for (final destino in destinos)
            BottomNavigationBarItem(
              icon: Icon(destino.icono),
              activeIcon: Icon(destino.iconoActivo),
              label: destino.etiqueta,
            ),
        ],
      ),
    );
  }
}
