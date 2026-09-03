import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/medireserva_service.dart';
import '../widgets/medireserva_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBack = true});
  final bool showBack;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      birth = TextEditingController(),
      address = TextEditingController();
  bool loading = true, saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p =
          await MediReservaService(Supabase.instance.client).getMyProfile();
      name.text = p['full_name']?.toString() ?? '';
      email.text = p['email']?.toString() ??
          Supabase.instance.client.auth.currentUser?.email ??
          '';
      phone.text = p['phone']?.toString() ?? '';
      birth.text = p['birth_date']?.toString() ?? '';
      address.text = p['address']?.toString() ?? '';
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    birth.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediReservaPage(
      title: 'Mi Perfil',
      step: '',
      showBack: widget.showBack,
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(strokeWidth: 2))
          : Column(children: [
              const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(Icons.person, color: kMediBlue, size: 42)),
              const SizedBox(height: 10),
              _field('Nombre completo', name, Icons.person_outline),
              _field('Correo electrónico', email, Icons.mail_outline,
                  enabled: false),
              _field('Teléfono', phone, Icons.phone_outlined),
              _field(
                  'Fecha de nacimiento', birth, Icons.calendar_today_outlined),
              _field('Dirección', address, Icons.location_on_outlined),
              const SizedBox(height: 5),
              MediButton(
                  label: saving ? 'Guardando...' : 'Guardar cambios',
                  onPressed: saving ? null : _save),
            ]));

  Widget _field(String label, TextEditingController c, IconData icon,
          {bool enabled = true}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: TextField(
              controller: c,
              enabled: enabled,
              style: const TextStyle(fontSize: 9),
              decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(fontSize: 8, color: kMediMuted),
                  prefixIcon: Icon(icon, size: 15, color: kMediBlue),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          const BorderSide(color: Color(0xFFE0E6EE))))));
  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await MediReservaService(Supabase.instance.client).updateMyProfile(
          fullName: name.text,
          phone: phone.text,
          birthDate: birth.text,
          address: address.text);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cambios guardados')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
