import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';
import 'confirmation_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.specialty, required this.doctor, required this.date});
  final Specialty specialty;
  final Doctor doctor;
  final DateTime date;
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<String>> _future;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = MediReservaService(Supabase.instance.client).getAvailableTimes(doctorId: widget.doctor.id, date: widget.date);

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${_weekday(widget.date.weekday)}, ${widget.date.day} de ${_month(widget.date.month)} de ${widget.date.year}';
    return MediReservaPage(title: 'Selecciona un horario', step: 'Paso 5 de 6', child: FutureBuilder<List<String>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        if (snapshot.hasError) return _message('No se pudieron cargar los horarios.\n${snapshot.error}');
        final times = snapshot.data ?? const <String>[];
        if (times.isEmpty) return _message('No hay horarios disponibles para esta fecha.\nSelecciona otro día.');
        return Column(children: [
          Text(dateLabel, textAlign: TextAlign.center, style: const TextStyle(color: kMediText, fontSize:15.2, fontWeight: FontWeight.bold)),
          const SizedBox(height:15.6),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 9, mainAxisSpacing: 8, childAspectRatio: 3.7, children: times.map((time) {
            final active = _selected == time;
            return OutlinedButton(onPressed: () => setState(() => _selected = time), style: OutlinedButton.styleFrom(backgroundColor: active ? kMediBlue : Colors.white, foregroundColor: active ? Colors.white : kMediText, side: BorderSide(color: active ? kMediBlue : const Color(0xFFE0E6EE)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: Text(time, style: const TextStyle(fontSize:13.6)));
          }).toList()),
          const SizedBox(height:15.6),
          const Text('Los horarios mostrados están en tu hora local.', style: TextStyle(color: kMediMuted, fontSize:12)),
          const SizedBox(height:13),
          MediButton(label: 'Continuar', onPressed: _selected == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmationScreen(specialty: widget.specialty.name, specialtyId: widget.specialty.id, doctor: widget.doctor.name, doctorId: widget.doctor.id, date: widget.date, time: _selected!)))),
        ]);
      },
    ));
  }

  Widget _message(String text) => Padding(padding: const EdgeInsets.all(25), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: kMediMuted, fontSize:13.6, height: 1.4)));
  String _month(int month) => const ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'][month - 1];
  String _weekday(int day) => const ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'][day - 1];
}
