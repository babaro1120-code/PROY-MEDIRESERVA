import 'package:flutter/material.dart';
import '../widgets/medireserva_ui.dart';
import 'specialties_screen.dart';

class ReservationStartScreen extends StatelessWidget {
  const ReservationStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediReservaPage(
      title: 'Reservar Cita',
      step: 'Paso 1 de 6',
      child: Column(
        children: [
          const StepDots(current: 1),
          const SizedBox(height:23.4),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: kMediBlue,
              size:74.2,
            ),
          ),
          const SizedBox(height:19.5),
          const Text(
            'Inicia tu reserva',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kMediText,
              fontSize:20.8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height:10.4),
          const Text(
            'Sigue los pasos para agendar tu\nconsulta médica de forma rápida\ny sencilla.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kMediMuted,
              fontSize:15.2,
              height: 1.55,
            ),
          ),
          const SizedBox(height:32.5),
          MediButton(
            label: 'Comenzar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpecialtiesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
