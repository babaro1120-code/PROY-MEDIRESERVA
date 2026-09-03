import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/medireserva_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _birth = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _accepted = true;
  bool _hide = true;
  String? _message;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _birth, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_key.currentState!.validate() || !_accepted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final msg = await AuthService(Supabase.instance.client).signUp(
        email: _email.text,
        password: _password.text,
        fullName: _name.text,
        phone: _phone.text,
        birthDate: _birth.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (Supabase.instance.client.auth.currentSession != null) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'No fue posible crear la cuenta.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediReservaPage(
      title: 'Crear cuenta',
      step: 'Completa tus datos para registrarte',
      child: Form(
        key: _key,
        child: Column(
          children: [
            _field(_name, 'Nombre completo', Icons.person_outline),
            _field(
              _email,
              'Correo electrónico',
              Icons.mail_outline,
              type: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Correo inválido' : null,
            ),
            _field(_phone, 'Teléfono', Icons.phone_outlined,
                type: TextInputType.phone),
            _field(
              _birth,
              'Fecha de nacimiento',
              Icons.calendar_month_outlined,
              readOnly: true,
              onTap: _pickBirth,
            ),
            _field(
              _password,
              'Contraseña',
              Icons.lock_outline,
              obscure: _hide,
              suffix: IconButton(
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(
                  _hide
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 16,
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
            ),
            _field(
              _confirm,
              'Confirmar contraseña',
              Icons.lock_outline,
              obscure: _hide,
              validator: (v) =>
                  v != _password.text ? 'Las contraseñas no coinciden' : null,
            ),
            Row(
              children: [
                Checkbox(
                  value: _accepted,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _accepted = v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                const Expanded(
                  child: Text(
                    'Acepto los términos y condiciones',
                    style: TextStyle(fontSize: 8),
                  ),
                ),
              ],
            ),
            if (_message != null)
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 8),
              ),
            const SizedBox(height: 7),
            MediButton(
              label: _busy ? 'Registrando...' : 'Registrarme',
              onPressed: _busy ? null : _register,
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text(
                '¿Ya tienes cuenta?  Inicia sesión',
                style: TextStyle(color: kMediBlue, fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType? type,
    bool obscure = false,
    Widget? suffix,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator ??
            (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
        style: const TextStyle(fontSize: 8.5),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 15),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 8),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFDDE3EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFDDE3EC)),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirth() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(1990, 1, 1),
    );
    if (d != null) {
      _birth.text =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }
}
