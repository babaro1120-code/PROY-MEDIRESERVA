MEDIRESERVA - CONTINUACION DE PANTALLAS

Incluye:
1. reservation_start_screen.dart  -> Paso 1 de 6
2. specialties_screen.dart       -> Paso 2 de 6
3. doctors_screen.dart            -> Paso 3 de 6
4. calendar_screen.dart           -> Paso 4 de 6
5. schedule_screen.dart           -> Paso 5 de 6
6. confirmation_screen.dart       -> Paso 6 de 6
7. reservation_detail_screen.dart -> Detalle de reserva
8. appointments_screen.dart       -> Mis Citas
9. profile_screen.dart            -> Mi Perfil
10. notifications_screen.dart    -> Notificaciones
11. logout_dialog.dart            -> Confirmación de cierre de sesión
12. home_screen.dart              -> Dashboard conectado a las pantallas

INSTALACION:
- Copia el contenido de screens/ dentro de lib/screens/
- Copia widgets/medireserva_ui.dart dentro de lib/widgets/
- Reemplaza tu home_screen.dart por el incluido.
- Se mantienen las dependencias que ya utilizas: provider y supabase_flutter.

NOTA:
Las listas de médicos, horarios, citas y notificaciones son datos de demostración.
El flujo de navegación ya funciona. El siguiente paso es conectar estos datos a tus tablas reales de Supabase.
