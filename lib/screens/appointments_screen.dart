import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';
import 'reservation_start_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, this.showBack = true});
  final bool showBack;
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int tab = 0;
  late Future<List<Appointment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Appointment>> _load() =>
      MediReservaService(Supabase.instance.client).getMyAppointments();
  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return MediReservaPage(
        title: 'Mis Citas',
        step: '',
        showBack: widget.showBack,
        child: Column(children: [
          Row(children: [
            _tab('Próximas', 0),
            _tab('Historial', 1),
            _tab('Canceladas', 2)
          ]),
          const SizedBox(height:10.4),
          FutureBuilder<List<Appointment>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Padding(
                      padding: EdgeInsets.all(25),
                      child: CircularProgressIndicator(strokeWidth: 2));
                if (snapshot.hasError)
                  return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: kMediMuted, fontSize:12.8)));
                final now = DateTime.now();
                final all = snapshot.data ?? const <Appointment>[];
                final filtered = all.where((a) {
                  final cancelled = a.status == 'cancelled';
                  final past =
                      a.date.isBefore(DateTime(now.year, now.month, now.day));
                  if (tab == 2) return cancelled;
                  if (tab == 1) return !cancelled && past;
                  return !cancelled && !past;
                }).toList();
                return Column(children: [
                  if (filtered.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No hay citas en esta sección.',
                            style: TextStyle(color: kMediMuted, fontSize:12.8))),
                  ...filtered.map(_card),
                ]);
              }),
          const SizedBox(height:7.8),
          MediButton(
              label: 'Nueva reserva',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ReservationStartScreen()))),
        ]));
  }

  Widget _tab(String label, int index) => Expanded(
      child: GestureDetector(
          onTap: () => setState(() => tab = index),
          child: Container(
              padding: const EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: tab == index
                              ? kMediBlue
                              : const Color(0xFFE6EBF2),
                          width: tab == index ? 2 : 1))),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: tab == index ? kMediBlue : kMediText,
                      fontSize:12.8,
                      fontWeight: tab == index
                          ? FontWeight.bold
                          : FontWeight.normal)))));

  Widget _card(Appointment a) {
    final status = _status(a.status);
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E6EE)),
            borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFEAF2FF),
              child: Icon(Icons.person, color: kMediBlue, size:33.8)),
          const SizedBox(width:11.7),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_date(a.date),
                    style: const TextStyle(
                        color: kMediText,
                        fontSize:12.8,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height:2.6),
                Text(a.time.substring(0, 5),
                    style: const TextStyle(
                        color: kMediText,
                        fontSize:12.8,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height:5.2),
                Text(a.doctor,
                    style: const TextStyle(
                        color: kMediText,
                        fontSize:13.6,
                        fontWeight: FontWeight.w600)),
                Text(a.specialty,
                    style: const TextStyle(color: kMediMuted, fontSize:12))
              ])),
          Column(children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                    color: status.$2, borderRadius: BorderRadius.circular(5)),
                child: Text(status.$1,
                    style: TextStyle(
                        color: status.$3,
                        fontSize:11.2,
                        fontWeight: FontWeight.bold))),
            if (a.status == 'confirmed' || a.status == 'pending')
              TextButton(
                  onPressed: () => _cancel(a.id),
                  child: const Text('Cancelar',
                      style: TextStyle(fontSize:11.2, color: Colors.red)))
          ])
        ]));
  }

  Future<void> _cancel(String id) async {
    try {
      await MediReservaService(Supabase.instance.client).cancelAppointment(id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cita cancelada')));
        _refresh();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo cancelar: $e')));
    }
  }

  String _date(DateTime d) =>
      '${_weekday(d.weekday)}, ${d.day} de ${_month(d.month)} de ${d.year}';
  String _month(int m) => const [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre'
      ][m - 1];
  String _weekday(int d) => const [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo'
      ][d - 1];
  (String, Color, Color) _status(String s) => switch (s) {
        'confirmed' => (
            'Confirmada',
            const Color(0xFFDDF5E6),
            const Color(0xFF138A4A)
          ),
        'cancelled' => (
            'Cancelada',
            const Color(0xFFFFE8EA),
            const Color(0xFFD32F2F)
          ),
        _ => ('Pendiente', const Color(0xFFFFF0D9), const Color(0xFFB86A00))
      };
}
