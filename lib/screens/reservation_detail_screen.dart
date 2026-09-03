import 'package:flutter/material.dart';
import '../widgets/medireserva_ui.dart';
import 'appointments_screen.dart';

class ReservationDetailScreen extends StatelessWidget {
  const ReservationDetailScreen({super.key, required this.specialty, required this.doctor, required this.date, required this.time, this.reservationNumber});
  final String specialty;
  final String doctor;
  final DateTime date;
  final String time;
  final String? reservationNumber;

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${_weekday(date.weekday)}, ${date.day} de ${_month(date.month)} de ${date.year}';
    return MediReservaPage(title: 'Detalle de la Reserva', step: '', child: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: const Color(0xFFE0F6E9), borderRadius: BorderRadius.circular(7)), child: const Text('✓  ¡Cita reservada con éxito!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF138A4A), fontSize:14.4, fontWeight: FontWeight.bold))),
      const SizedBox(height:13),
      Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E6EE)), borderRadius: BorderRadius.circular(7)), child: Column(children: [
        _line('Nº de Reserva', reservationNumber == null ? 'Generada' : '#$reservationNumber'),
        _line('Especialidad', specialty), _line('Médico', doctor), _line('Fecha', dateLabel), _line('Hora', time), _line('Estado', 'Confirmada', success: true),
      ])),
      const SizedBox(height:15.6),
      Row(children: [Expanded(child: MediButton(label: 'Ver mis citas', outlined: true, onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen())))), const SizedBox(width:13), Expanded(child: MediButton(label: 'Ir al inicio', outlined: true, onPressed: () => Navigator.popUntil(context, (route) => route.isFirst)))])
    ]));
  }
  String _month(int m) => const ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'][m-1];
  String _weekday(int d) => const ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'][d-1];
}

class _line extends StatelessWidget {
  const _line(this.label, this.value, {this.success = false});
  final String label, value; final bool success;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE9EDF3))),), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: kMediMuted, fontSize:12))), if (success) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFDDF5E6), borderRadius: BorderRadius.circular(5)), child: Text(value, style: const TextStyle(color: Color(0xFF138A4A), fontSize:12, fontWeight: FontWeight.bold))) else Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: kMediText, fontSize:12.8, fontWeight: FontWeight.w600))) ]));
}
