import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Estás seguro que deseas cerrar sesión?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (confirmed == true) await Supabase.instance.client.auth.signOut();
}
