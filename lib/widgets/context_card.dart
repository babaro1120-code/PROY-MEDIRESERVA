import 'package:flutter/material.dart';

import '../models/context_snapshot.dart';

class ContextCard extends StatelessWidget {
  const ContextCard({super.key, required this.snapshot});

  final ContextSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.my_location),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snapshot.source,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lat ${snapshot.latitude.toStringAsFixed(5)} - '
              'Lon ${snapshot.longitude.toStringAsFixed(5)}',
            ),
            const SizedBox(height: 4),
            Text(
              '${snapshot.weather.temperatureC.toStringAsFixed(1)} C - '
              '${snapshot.weather.summary}',
            ),
          ],
        ),
      ),
    );
  }
}
