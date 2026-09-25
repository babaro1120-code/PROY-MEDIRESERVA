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
        _error = _friendlyError(error);
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
          const SizedBox(height:7.8),
          const Text(
            'Revisa la información y confirma tu reserva.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMediMuted, fontSize:13.6),
          ),
          const SizedBox(height:13),
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
            const SizedBox(height:13),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize:14.4,
              ),
            ),
          ],
          const SizedBox(height:15.6),
          MediButton(
            label: _busy ? 'Guardando...' : 'Confirmar cita',
            onPressed: _busy ? null : _confirm,
          ),
          const SizedBox(height:7.8),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: kMediBlue, fontSize:13.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Traduce los errores de PostgREST a mensajes entendibles para el paciente.
  ///
  /// La función `reservar_cita` de PostgreSQL lanza mensajes ya redactados en
  /// español, así que para esos códigos se muestra su texto tal cual.
  String _friendlyError(Object error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23503':
          // Clave foránea: falta la fila del perfil del paciente.
          return 'Tu perfil todavía no existe en la base de datos '
              '(tabla "profiles"), por eso no se puede guardar la cita.\n\n'
              'Abre Supabase → SQL Editor, ejecuta el archivo '
              'supabase/04_REPARAR_PERFILES.sql y vuelve a intentar.';
        case '23505':
          // Índice único activo del horario, o reserva ya cancelada.
          return 'Ese horario acaba de ser reservado por otro paciente.\n'
              'Vuelve atrás y elige otro horario.';
        case '23514':
          // Violación de dominio: la cita ya fue atendida.
          return 'Esa consulta ya figura como atendida y no se puede cancelar.\n\n'
              'Si necesitas una nueva cita, reserva otro horario.';
        case '22007':
          // Fecha inválida: se intentó reservar en el pasado.
          return 'Esa fecha ya pasó y no se puede reservar.\n'
              'Vuelve atrás y elige un día de hoy en adelante.';
        case '22023':
          // Parámetros inválidos: el médico no corresponde a la especialidad.
          return 'El profesional elegido no corresponde a esa especialidad.\n'
              'Vuelve al inicio del flujo y repite la selección.';
        case 'P0002':
          // Horario inexistente en la oferta del profesional.
          return 'Ese horario ya no está en la oferta del profesional.\n'
              'Vuelve atrás y elige otro horario disponible.';
        case '42501':
          return 'La sesión no permite guardar la cita.\n\n'
              'Abre Supabase → SQL Editor, ejecuta supabase/schema.sql y '
              'supabase/04_REPARAR_PERFILES.sql (crean permisos y políticas '
              'de "profiles") y vuelve a intentar.';
        case 'PGRST202':
          // Falta ejecutar la migración de la función de reserva.
          return 'La base de datos todavía no tiene la función de reserva.\n\n'
              'Abre Supabase → SQL Editor, ejecuta '
              'supabase/07_RESERVAS_RPC.sql y vuelve a intentar.';
      }
      return error.message;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  String _month(int month) => const [
        'enero','febrero','marzo','abril','mayo','junio',
        'julio','agosto','septiembre','octubre','noviembre','diciembre'
      ][month - 1];

  String _weekday(int day) => const [
        'Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'
      ][day - 1];
}
