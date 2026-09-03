import 'package:flutter/material.dart';

import '../models/medireserva_models.dart';
import '../widgets/medireserva_ui.dart';
import 'schedule_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.specialty, required this.doctor});
  final Specialty specialty;
  final Doctor doctor;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = (first.weekday - 1) % 7;
    const names = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return MediReservaPage(title: 'Selecciona una fecha', step: 'Paso 4 de 6', child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left, size:27), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        Text('${names[_month.month - 1]} ${_month.year}', style: const TextStyle(color: kMediText, fontSize:16.8, fontWeight: FontWeight.bold)),
        IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right, size:27), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('L'), Text('M'), Text('M'), Text('J'), Text('V'), Text('S'), Text('D')]),
      const SizedBox(height:7.8),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: leading + days,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 31),
        itemBuilder: (_, index) {
          if (index < leading) return const SizedBox.shrink();
          final date = DateTime(_month.year, _month.month, index - leading + 1);
          final past = date.isBefore(todayOnly);
          final selected = _same(date, _selected);
          return GestureDetector(
            onTap: past ? null : () => setState(() => _selected = date),
            child: Center(child: Container(width: 23, height: 23, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? kMediBlue : Colors.transparent, shape: BoxShape.circle), child: Text('${date.day}', style: TextStyle(fontSize:12.8, color: selected ? Colors.white : past ? const Color(0xFFB8C0CC) : kMediText, fontWeight: selected ? FontWeight.bold : FontWeight.normal)))),
          );
        },
      ),
      const SizedBox(height:15.6),
      MediButton(label: 'Continuar', onPressed: _selected == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleScreen(specialty: widget.specialty, doctor: widget.doctor, date: _selected!)))),
    ]));
  }

  bool _same(DateTime a, DateTime? b) => b != null && a.year == b.year && a.month == b.month && a.day == b.day;
}
