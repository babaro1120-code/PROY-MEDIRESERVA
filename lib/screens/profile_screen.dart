import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/medireserva_service.dart';
import '../utils/medireserva_fechas.dart';
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
      birth.text = _fechaParaMostrar(p['birth_date']);
      address.text = p['address']?.toString() ?? '';
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Texto que se muestra en el campo de fecha: `DD/MM/AAAA` o vacío.
  ///
  /// La base devuelve `AAAA-MM-DD`. Una fecha ilegible (o ausente) no rompe la
  /// pantalla: el campo queda vacío y el usuario puede volver a elegirla.
  String _fechaParaMostrar(Object? valor) {
    final fecha = _leerFecha(valor?.toString());
    return fecha == null ? '' : fechaDiaMesAnio(fecha);
  }

  /// [DateTime] de un texto de fecha, o `null` si está vacío o no se entiende.
  DateTime? _leerFecha(String? texto) {
    try {
      return fechaDesdeTexto(texto);
    } on FormatException {
      return null;
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
                  child: Icon(Icons.person, color: kMediBlue, size:56.7)),
              const SizedBox(height:13),
              _field('Nombre completo', name, Icons.person_outline),
              _field('Correo electrónico', email, Icons.mail_outline,
                  enabled: false),
              _field('Teléfono', phone, Icons.phone_outlined),
              _campoFecha(),
              _field('Dirección', address, Icons.location_on_outlined),
              const SizedBox(height:6.5),
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
              style: const TextStyle(fontSize:14.4),
              decoration: _decoracion(label, icon)));

  /// Campo de fecha de nacimiento: solo lectura, con selector de calendario.
  ///
  /// La cruz del final lo deja vacío, porque la fecha es opcional.
  Widget _campoFecha() => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: TextField(
          controller: birth,
          readOnly: true,
          onTap: saving ? null : _elegirFecha,
          style: const TextStyle(fontSize: 14.4),
          decoration: _decoracion(
              'Fecha de nacimiento', Icons.calendar_today_outlined,
              hintText: 'DD/MM/AAAA',
              suffixIcon: birth.text.trim().isEmpty
                  ? const Icon(Icons.edit_calendar_outlined,
                      size: 18, color: kMediMuted)
                  : IconButton(
                      tooltip: 'Borrar la fecha',
                      icon:
                          const Icon(Icons.clear, size: 18, color: kMediMuted),
                      onPressed:
                          saving ? null : () => setState(() => birth.clear()),
                    ))));

  /// Abre el calendario para elegir la fecha de nacimiento (1900 hasta hoy).
  ///
  /// Los nombres de mes y de día del calendario los aporta
  /// `flutter_localizations` (español), configurado en `lib/main.dart`; acá solo
  /// se ajustan los textos propios de este campo.
  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: hoy,
      initialDate: _fechaInicial(hoy),
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      fieldLabelText: 'Fecha de nacimiento',
      errorFormatText: 'Escribe la fecha como DD/MM/AAAA.',
      errorInvalidText: 'Esa fecha no existe en el calendario.',
    );
    if (elegida == null || !mounted) return;
    setState(() => birth.text = fechaDiaMesAnio(elegida));
  }

  /// Fecha con la que abre el calendario: la que ya estaba o el 1/1/1990.
  DateTime _fechaInicial(DateTime hoy) {
    final guardada = _leerFecha(birth.text);
    final minimo = DateTime(1900);
    if (guardada != null &&
        !guardada.isBefore(minimo) &&
        !guardada.isAfter(hoy)) {
      return guardada;
    }
    return DateTime(1990);
  }

  InputDecoration _decoracion(String label, IconData icon,
          {String? hintText, Widget? suffixIcon}) =>
      InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12.8, color: kMediMuted),
          labelStyle: const TextStyle(fontSize:12.8, color: kMediMuted),
          prefixIcon: Icon(icon, size:20.2, color: kMediBlue),
          suffixIcon: suffixIcon,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: Color(0xFFE0E6EE))));

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'No se pudo guardar. ${MediReservaService.mensajeDeError(e)}')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
