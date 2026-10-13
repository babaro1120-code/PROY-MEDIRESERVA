import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/medireserva_realtime.dart';
import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';
import '../widgets/pestana_activa.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int filter = 0;
  late Future<List<Map<String, dynamic>>> future;

  /// Clave de la pestaña del armazón a la que pertenece esta pantalla.
  static const _claveDePestana = 'notificaciones';

  /// Escucha en vivo las altas, los cambios y las bajas de `appointments`:
  /// es el momento en el que el servidor crea los avisos de la reserva.
  late final EscuchaDeCitas _escucha;

  /// Último aviso de pestaña atendido (`null` hasta el primer registro).
  int? _ultimoAviso;

  @override
  void initState() {
    super.initState();
    future = _cargar();
    // Defensivo: si el *realtime* no está disponible, la pantalla sigue igual y
    // quedan el gesto de actualizar y la recarga al volver a la pestaña.
    _escucha = EscuchaDeCitas(onCambio: _recargarPorCambio);
    _escucha.suscribir();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recargarAlEntrarALaPestana();
  }

  @override
  void dispose() {
    // Sin esto, cada visita a los avisos dejaría un canal abierto.
    unawaited(_escucha.cancelar());
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _cargar() async =>
      MediReservaService(Supabase.instance.client).getNotifications();

  /// Recarga pedida por la suscripción en vivo.
  void _recargarPorCambio() {
    if (!mounted) return;
    setState(() => future = _cargar());
  }

  /// Deslizar hacia abajo para actualizar (funciona con la lista vacía).
  Future<void> _refrescarConGesto() async {
    final nueva = _cargar();
    if (!mounted) return;
    setState(() => future = nueva);
    try {
      await nueva;
    } catch (_) {
      // El error ya lo muestra el `FutureBuilder`.
    }
  }

  /// Recarga al entrar a la pestaña: el `IndexedStack` del armazón mantiene esta
  /// pantalla montada y no la vuelve a construir.
  void _recargarAlEntrarALaPestana() {
    final aviso = PestanaActiva.de(context);
    if (debeRecargarPorPestana(
      aviso: aviso,
      clave: _claveDePestana,
      ultimoTick: _ultimoAviso,
    )) {
      future = _cargar();
    }
    _ultimoAviso = aviso?.tick ?? _ultimoAviso;
  }

  @override
  Widget build(BuildContext context) {
    return MediReservaPage(
      title: 'Notificaciones',
      step: '',
      showBack: widget.showBack,
      onRefresh: _refrescarConGesto,
      child: Column(
        children: [
          Row(
            children: [
              _filter('Todas', 0),
              _filter('Recordatorios', 1),
              _filter('Avisos', 2),
            ],
          ),
          const SizedBox(height:10.4),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(25),
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize:12.8, color: kMediMuted),
                  ),
                );
              }
              final items = (snapshot.data ?? const <Map<String, dynamic>>[])
                  .where((n) =>
                      filter == 0 ||
                      (filter == 1 && n['type'] == 'reminder') ||
                      (filter == 2 && n['type'] != 'reminder'))
                  .toList();
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No tienes notificaciones.',
                    style: TextStyle(fontSize:12.8, color: kMediMuted),
                  ),
                );
              }
              return Column(children: items.map(_item).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _filter(String text, int i) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => filter = i),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: filter == i ? kMediBlue : const Color(0xFFF3F5F8),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: filter == i ? Colors.white : kMediText,
              fontSize:12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(Map<String, dynamic> n) {
    final read = n['is_read'] == true;
    return InkWell(
      onTap: () => !read ? _read(n['id'].toString()) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE9EDF3))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: read ? const Color(0xFFF3F5F8) : const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: read ? kMediMuted : kMediBlue,
                size:21.6,
              ),
            ),
            const SizedBox(width:10.4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['title']?.toString() ?? '',
                    style: const TextStyle(
                      color: kMediText,
                      fontSize:12.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height:3.9),
                  Text(
                    n['body']?.toString() ?? '',
                    style: const TextStyle(
                      color: kMediMuted,
                      fontSize:12,
                      height: 1.3,
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

  Future<void> _read(String id) async {
    await MediReservaService(Supabase.instance.client)
        .markNotificationAsRead(id);
    if (mounted) {
      setState(() {
        future =
            MediReservaService(Supabase.instance.client).getNotifications();
      });
    }
  }
}
