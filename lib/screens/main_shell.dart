import 'package:flutter/material.dart';

import 'appointments_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Contenedor principal con el menú inferior siempre visible.
///
/// Cada pestaña conserva su propia pila de navegación ([Navigator]), por lo
/// que el menú de abajo se mantiene tanto al cambiar de módulo (Inicio, Citas,
/// Perfil, Notificaciones) como al navegar dentro de cada módulo.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  void _selectTab(int index) {
    if (index == _index) {
      // Si ya estamos en la pestaña, regresamos a su raíz por si hay subpantallas.
      _navKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: IndexedStack(
        index: _index,
        children: [
          _buildTab(0, HomeScreen(onSelectTab: _selectTab)),
          _buildTab(1, const AppointmentsScreen(showBack: false)),
          _buildTab(2, const ProfileScreen(showBack: false)),
          _buildTab(3, const NotificationsScreen(showBack: false)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _selectTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: const Color(0xFF075BD8),
        unselectedItemColor: const Color(0xFF6B778C),
        selectedFontSize:14.4,
        unselectedFontSize:14.4,
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
    );
  }

  Widget _buildTab(int index, Widget root) {
    return Navigator(
      key: _navKeys[index],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(settings: settings, builder: (_) => root),
    );
  }
}
