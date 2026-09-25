import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/medireserva_service.dart';
import 'agenda_screen.dart';
import 'appointments_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Descripción de un módulo del menú inferior.
class _Destino {
  const _Destino(this.clave, this.etiqueta, this.icono, this.iconoActivo);

  final String clave;
  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
}

/// Contenedor principal con el menú inferior siempre visible.
///
/// Los módulos dependen del rol: el paciente ve las cuatro secciones de
/// siempre y el profesional o el administrador suman "Agenda". El rol lo
/// resuelve el servidor; esta pantalla solo decide qué mostrar.
///
/// Cada pestaña conserva su propia pila de navegación ([Navigator]), por lo que
/// el menú inferior se mantiene tanto al cambiar de módulo como al navegar
/// dentro de cada uno.
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

  List<_Destino> get _destinos => [
        const _Destino('inicio', 'Inicio', Icons.home_outlined, Icons.home),
        if (_atiendeAgenda)
          const _Destino(
              'agenda', 'Agenda', Icons.event_note_outlined, Icons.event_note),
        const _Destino('citas', 'Citas', Icons.calendar_month_outlined,
            Icons.calendar_month),
        const _Destino(
            'perfil', 'Perfil', Icons.person_outline, Icons.person),
        const _Destino('notificaciones', 'Avisos',
            Icons.notifications_none_outlined, Icons.notifications),
      ];

  GlobalKey<NavigatorState> _claveDe(String clave) =>
      _claves.putIfAbsent(clave, () => GlobalKey<NavigatorState>());

  Widget _raizDe(String clave) => switch (clave) {
        'agenda' => const AgendaScreen(showBack: false),
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
      // Si ya estamos en la pestaña, volvemos a su raíz.
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
    // Con cinco pestañas la etiqueta necesita menos cuerpo para no cortarse.
    final cuerpo = destinos.length >= 5 ? 10.4 : 14.4;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: IndexedStack(
        index: actual,
        children: [
          for (final d in destinos)
            Navigator(
              key: _claveDe(d.clave),
              onGenerateRoute: (settings) => MaterialPageRoute(
                settings: settings,
                builder: (_) => _raizDe(d.clave),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: actual,
        onTap: _seleccionar,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: const Color(0xFF075BD8),
        unselectedItemColor: const Color(0xFF6B778C),
        selectedFontSize: cuerpo,
        unselectedFontSize: cuerpo,
        items: [
          for (final d in destinos)
            BottomNavigationBarItem(
              icon: Icon(d.icono),
              activeIcon: Icon(d.iconoActivo),
              label: d.etiqueta,
            ),
        ],
      ),
    );
  }
}
