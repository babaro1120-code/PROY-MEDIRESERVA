import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../controllers/context_controller.dart';
import '../../models/context_snapshot.dart';
import '../../widgets/context_card.dart';
import '../../widgets/max_width_box.dart';
import '../record_form_screen.dart';

class ContextLabScreen extends StatelessWidget {
  const ContextLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ContextController>();
    final snapshot = controller.snapshot;

    return Scaffold(
      appBar: AppBar(title: const Text('Conexion con el mundo')),
      body: MaxWidthBox(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: <Widget>[
            Text(
              'ACCION -> ESPERA -> RESPUESTA -> UI',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Primero API con Tarija fija. Despues GPS. '
              'Asi separamos problemas y entendemos el flujo.',
            ),
            const SizedBox(height: 14),
            _buildStatus(controller),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: controller.busy ? null : controller.useTarijaApi,
              icon: const Icon(Icons.cloud_outlined),
              label: const Text('1. TARIJA FIJA + API REAL'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: controller.busy ? null : controller.useGpsAndApi,
              icon: const Icon(Icons.gps_fixed),
              label: const Text('2. GPS REAL + API'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.busy
                  ? null
                  : controller.simulateControlledError,
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('3. SIMULAR ERROR CONTROLADO'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: controller.busy ? null : controller.useOfflineRescue,
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('PLAN B OFFLINE'),
            ),
            if (snapshot != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (routeContext) {
                        return RecordFormScreen(initialContext: snapshot);
                      },
                    ),
                  );

                  if (changed == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Registro creado con contexto.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('CREAR REGISTRO CON ESTE CONTEXTO'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(ContextController controller) {
    if (controller.busy) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(controller.statusText)),
            ],
          ),
        ),
      );
    }

    if (controller.status == ContextStatus.error) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: <Widget>[
              const Icon(Icons.error_outline, size: 50),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage ?? 'Error desconocido',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: controller.retry,
                icon: const Icon(Icons.refresh),
                label: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = controller.snapshot;
    if (snapshot == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('LISTO: ejecuta primero Tarija fija + API real.'),
        ),
      );
    }

    return _ContextReady(snapshot: snapshot);
  }
}

class _ContextReady extends StatelessWidget {
  const _ContextReady({required this.snapshot});

  final ContextSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(snapshot.latitude, snapshot.longitude);

    return Column(
      children: <Widget>[
        ContextCard(snapshot: snapshot),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 260,
            child: FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 14.5),
              children: <Widget>[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'bo.edu.uajms.MEDIRESERVA',
                ),
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: point,
                      width: 56,
                      height: 56,
                      child: const Icon(
                        Icons.location_pin,
                        size: 52,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
