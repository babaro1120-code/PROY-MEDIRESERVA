import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';
import 'reservation_detail_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({
    super.key,
    required this.specialty,
    required this.specialtyId,
    required this.doctor,
    required this.doctorId,
    required this.date,
    required this.time,
  });

  final String specialty;
  final String specialtyId;
  final String doctor;
  final String doctorId;
  final DateTime date;
  final String time;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final appointment = await MediReservaService(
        Supabase.instance.client,
      ).createAppointment(
        specialtyId: widget.specialtyId,
        doctorId: widget.doctorId,
        date: widget.date,
        time: widget.time,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReservationDetailScreen(
            specialty: widget.specialty,
            doctor: widget.doctor,
            date: widget.date,
            time: widget.time,
            reservationNumber: appointment.reservationNumber,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_weekday(widget.date.weekday)}, ${widget.date.day} de '
        '${_month(widget.date.month)} de ${widget.date.year}';

    return MediReservaPage(
      title: 'Confirma tu cita',
      step: 'Paso 6 de 6',
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Text(
            'Revisa la información y confirma tu reserva.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMediMuted, fontSize: 8.5),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E6EE)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Especialidad',
                  value: widget.specialty,
                ),
                InfoRow(
                  icon: Icons.person_outline,
                  label: 'Médico',
                  value: widget.doctor,
                ),
                InfoRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Fecha',
                  value: dateLabel,
                ),
                InfoRow(
                  icon: Icons.schedule_outlined,
                  label: 'Hora',
                  value: widget.time,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 9,
              ),
            ),
          ],
          const SizedBox(height: 12),
          MediButton(
            label: _busy ? 'Guardando...' : 'Confirmar cita',
            onPressed: _busy ? null : _confirm,
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: kMediBlue, fontSize: 8.5),
            ),
          ),
        ],
      ),
    );
  }

  String _month(int month) => const [
        'enero','febrero','marzo','abril','mayo','junio',
        'julio','agosto','septiembre','octubre','noviembre','diciembre'
      ][month - 1];

  String _weekday(int day) => const [
        'Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'
      ][day - 1];
}
