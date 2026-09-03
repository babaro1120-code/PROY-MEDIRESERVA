import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';
import 'calendar_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key, required this.specialty});
  final Specialty specialty;
  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  late Future<List<Doctor>> _future;

  @override
  void initState() {
    super.initState();
    _future = MediReservaService(Supabase.instance.client).getDoctorsBySpecialty(widget.specialty.id);
  }

  @override
  Widget build(BuildContext context) {
    return MediReservaPage(
      title: 'Médicos disponibles',
      step: 'Paso 3 de 6',
      child: FutureBuilder<List<Doctor>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(strokeWidth: 2)));
          if (snapshot.hasError) return _error(snapshot.error.toString());
          final doctors = snapshot.data ?? const <Doctor>[];
          if (doctors.isEmpty) return _error('No hay médicos disponibles para esta especialidad.');
          return Column(children: [
            Text(widget.specialty.name, style: const TextStyle(color: kMediMuted, fontSize:13.6, fontWeight: FontWeight.w600)),
            const SizedBox(height:9.1),
            ...doctors.map(_doctorCard),
          ]);
        },
      ),
    );
  }

  Widget _doctorCard(Doctor doctor) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(specialty: widget.specialty, doctor: doctor))),
          child: Container(
            height: 53,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E6EE)), borderRadius: BorderRadius.circular(7)),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEAF2FF),
                backgroundImage: doctor.photoUrl == null ? null : NetworkImage(doctor.photoUrl!),
                child: doctor.photoUrl == null ? const Icon(Icons.person, color: kMediBlue, size:31) : null,
              ),
              const SizedBox(width:11.7),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doctor.name, style: const TextStyle(color: kMediText, fontSize:14.4, fontWeight: FontWeight.bold)),
                const SizedBox(height:3.9),
                Text(widget.specialty.name, style: const TextStyle(color: kMediMuted, fontSize:12)),
              ])),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('★ ${doctor.rating.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFFF5A000), fontSize:12, fontWeight: FontWeight.bold)),
                const SizedBox(height:3.9),
                Text('${doctor.experienceYears} años exp.', style: const TextStyle(color: kMediMuted, fontSize:11.2)),
              ]),
              const SizedBox(width:5.2),
              const Icon(Icons.chevron_right, size:23, color: kMediMuted),
            ]),
          ),
        ),
      );

  Widget _error(String message) => Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Icon(Icons.person_off_outlined, color: kMediMuted, size:40.5), const SizedBox(height:10.4), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kMediMuted, fontSize:12.8))]));
}
