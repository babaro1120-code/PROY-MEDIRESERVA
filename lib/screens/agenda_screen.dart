import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';

/// Agenda de reservas para el profesional y el administrador.
///
/// La lista que llega desde el servidor ya viene acotada por las políticas de
/// seguridad a nivel de fila: el profesional recibe solo las reservas de su
/// propia agenda y el administrador, todas. La pantalla no filtra por rol: se
/// limita a mostrar lo que el servidor autorizó.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  int _filtro = 0;
  late Future<List<AgendaItem>> _future;

  static const _filtros = ['Todas', 'Pendientes', 'Confirmadas', 'Atendidas'];

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<AgendaItem>> _cargar() =>
      MediReservaService(Supabase.instance.client).getAgenda();

  void _refrescar() => setState(() => _future = _cargar());

  List<AgendaItem> _aplicarFiltro(List<AgendaItem> items) => switch (_filtro) {
        1 => items.where((a) => a.status == 'pending').toList(),
        2 => items.where((a) => a.status == 'confirmed').toList(),
        3 => items.where((a) => a.status == 'completed').toList(),
        _ => items,
      };

  Future<void> _cambiarEstado(AgendaItem item, String estado) async {
    try {
      await MediReservaService(Supabase.instance.client).setAppointmentStatus(
        appointmentId: item.id,
        status: estado,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reserva marcada como ${_etiqueta(estado)}.')),
      );
      _refrescar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorLegible(error))),
      );
    }
  }

  /// Traduce el rechazo del servidor a un mensaje entendible.
  String _errorLegible(Object error) {
    if (error is PostgrestException) {
      if (error.code == '42501') {
        return 'Tu rol no permite cambiar el estado de esta reserva.';
      }
      if (error.code == 'PGRST202') {
        return 'Falta ejecutar supabase/07_RESERVAS_RPC.sql en Supabase.';
      }
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return MediReservaPage(
      title: 'Mi Agenda',
      step: '',
      showBack: widget.showBack,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _filtros.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _chip(_filtros[i], i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10.4),
          FutureBuilder<List<AgendaItem>>(
            future: _future,
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
                    _errorLegible(snapshot.error as Object),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kMediMuted, fontSize: 12.8),
                  ),
                );
              }

              final items = _aplicarFiltro(snapshot.data ?? const <AgendaItem>[]);
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay reservas en esta sección.',
                    style: TextStyle(color: kMediMuted, fontSize: 12.8),
                  ),
                );
              }

              return Column(children: items.map(_card).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int index) => GestureDetector(
        onTap: () => setState(() => _filtro = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: _filtro == index ? kMediBlue : const Color(0xFFF1F5FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: _filtro == index ? Colors.white : kMediText,
              fontSize: 12,
              fontWeight: _filtro == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

  Widget _card(AgendaItem a) {
    final status = _estado(a.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E6EE)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFEAF2FF),
                child: Icon(Icons.person, color: kMediBlue, size: 33.8),
              ),
              const SizedBox(width: 11.7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.patientName.trim().isEmpty
                          ? 'Paciente sin nombre'
                          : a.patientName,
                      style: const TextStyle(
                        color: kMediText,
                        fontSize: 13.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2.6),
                    Text(
                      '${_fecha(a.date)} · ${a.time.substring(0, 5)}',
                      style: const TextStyle(
                        color: kMediText,
                        fontSize: 12.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2.6),
                    Text(
                      '${a.specialty} · ${a.doctor}',
                      style: const TextStyle(color: kMediMuted, fontSize: 12),
                    ),
                    if (a.reservationNumber != null) ...[
                      const SizedBox(height: 2.6),
                      Text(
                        a.reservationNumber!,
                        style: const TextStyle(
                          color: kMediMuted,
                          fontSize: 11.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: status.$2,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status.$1,
                  style: TextStyle(
                    color: status.$3,
                    fontSize: 11.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (a.status == 'pending' || a.status == 'confirmed') ...[
            const SizedBox(height: 5.2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (a.status == 'pending')
                  TextButton(
                    onPressed: () => _cambiarEstado(a, 'confirmed'),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(fontSize: 11.2, color: kMediBlue),
                    ),
                  ),
                TextButton(
                  onPressed: () => _cambiarEstado(a, 'completed'),
                  child: const Text(
                    'Atender',
                    style: TextStyle(fontSize: 11.2, color: Color(0xFF138A4A)),
                  ),
                ),
                TextButton(
                  onPressed: () => _cambiarEstado(a, 'cancelled'),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 11.2, color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _etiqueta(String s) => switch (s) {
        'confirmed' => 'confirmada',
        'completed' => 'atendida',
        'cancelled' => 'cancelada',
        _ => 'pendiente',
      };

  (String, Color, Color) _estado(String s) => switch (s) {
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
        'completed' => (
            'Atendida',
            const Color(0xFFE8F0FE),
            const Color(0xFF1A56C4)
          ),
        _ => ('Pendiente', const Color(0xFFFFF0D9), const Color(0xFFB86A00))
      };

  String _fecha(DateTime d) =>
      '${_semana(d.weekday)}, ${d.day} de ${_mes(d.month)} de ${d.year}';

  String _mes(int m) => const [
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

  String _semana(int d) => const [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo'
      ][d - 1];
}
