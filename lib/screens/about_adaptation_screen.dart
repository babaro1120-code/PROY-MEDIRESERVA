import 'package:flutter/material.dart';

import '../widgets/max_width_box.dart';

class AboutAdaptationScreen extends StatelessWidget {
  const AboutAdaptationScreen({super.key});

  static const items = <String>[
    'Problema real que resuelve la app',
    'Entidad principal del dominio',
    'API externa con sentido',
    'Capacidad nativa con sentido',
    'Estado de carga, dato y error',
    'Datos que deben persistirse',
    'Evidencias para defensa',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptar a mi proyecto')),
      body: MaxWidthBox(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(items[index]),
            );
          },
        ),
      ),
    );
  }
}
