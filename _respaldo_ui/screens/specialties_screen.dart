import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medireserva_models.dart';
import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';
import 'doctors_screen.dart';

class SpecialtiesScreen extends StatefulWidget {
  const SpecialtiesScreen({super.key});

  @override
  State<SpecialtiesScreen> createState() => _SpecialtiesScreenState();
}

class _SpecialtiesScreenState extends State<SpecialtiesScreen> {
  late Future<List<Specialty>> _future;

  @override
  void initState() {
    super.initState();
    _future = MediReservaService(Supabase.instance.client).getSpecialties();
  }

  void _reload() => setState(() {
        _future = MediReservaService(Supabase.instance.client).getSpecialties();
      });

  @override
  Widget build(BuildContext context) {
    return MediReservaPage(
      title: 'Especialidades',
      step: 'Paso 2 de 6',
      child: FutureBuilder<List<Specialty>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString(), onRetry: _reload);
          }
          final items = snapshot.data ?? const <Specialty>[];
          if (items.isEmpty) {
            return _ErrorState(message: 'No hay especialidades disponibles.', onRetry: _reload);
          }
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E6EE)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                final item = items[i];
                return Column(
                  children: [
                    SizedBox(
                      height: 33,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorsScreen(specialty: item),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          child: Row(
                            children: [
                              Icon(_icon(item.iconName), color: kMediBlue, size: 16),
                              const SizedBox(width: 9),
                              Expanded(child: Text(item.name, style: const TextStyle(color: kMediText, fontSize: 9.5, fontWeight: FontWeight.w600))),
                              const Icon(Icons.chevron_right, size: 17, color: kMediMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (i < items.length - 1)
                      const Divider(height: 1, indent: 8, endIndent: 8, color: Color(0xFFE9EDF3)),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  IconData _icon(String? name) => switch (name) {
        'child_care' => Icons.child_care_outlined,
        'favorite' => Icons.favorite,
        'face' => Icons.face_outlined,
        'pregnant_woman' => Icons.pregnant_woman_outlined,
        'dentistry' => Icons.health_and_safety_outlined,
        'visibility' => Icons.visibility_outlined,
        _ => Icons.medical_services_outlined,
      };
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(children: [
        const Icon(Icons.cloud_off_outlined, color: kMediMuted, size: 30),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: kMediMuted)),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Reintentar', style: TextStyle(fontSize: 8))),
      ]);
}
