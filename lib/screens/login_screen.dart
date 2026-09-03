import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/medireserva_ui.dart';
import 'register_screen.dart';
import 'recovery_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _message;
  bool _error = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
    });
    try {
      await AuthService(Supabase.instance.client).signIn(
        email: _email.text,
        password: _password.text,
      );
    } on AuthException catch (e) {
      if (mounted)
        setState(() {
          _message = _friendly(e.message);
          _error = true;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _message = 'No fue posible iniciar sesión.';
          _error = true;
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials'))
      return 'Correo o contraseña incorrectos.';
    if (m.contains('email not confirmed'))
      return 'Confirma tu correo electrónico antes de iniciar sesión.';
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMediBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: .06),
                        blurRadius: 16)
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const _Logo(),
                      const SizedBox(height: 9.1),
                      const Text('MEDIRESERVA',
                          style: TextStyle(
                              color: kMediDark,
                              fontSize: 27.2,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3.9),
                      const Text('Sistema de Reservas de Consultas Médicas',
                          style: TextStyle(color: kMediMuted, fontSize: 12.8)),
                      const SizedBox(height: 23.4),
                      _field('Correo electrónico', _email, Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                        if (v == null || !v.contains('@'))
                          return 'Ingresa un correo válido';
                        return null;
                      }),
                      const SizedBox(height: 13),
                      _field('Contraseña', _password, Icons.lock_outline,
                          obscure: _obscure,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 23,
                                color: kMediMuted),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Mínimo 6 caracteres'
                              : null),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RecoveryScreen())),
                          child: const Text('¿Olvidaste tu contraseña?',
                              style:
                                  TextStyle(color: kMediBlue, fontSize: 12.8)),
                        ),
                      ),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Text(_message!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: _error
                                      ? Colors.red
                                      : const Color(0xFF138A4A),
                                  fontSize: 12.8)),
                        ),
                      MediButton(
                          label:
                              _busy ? 'Iniciando sesión...' : 'Iniciar sesión',
                          onPressed: _busy ? null : _login),
                      const SizedBox(height: 6.5),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('¿No tienes cuenta? ',
                                style: TextStyle(
                                    color: kMediMuted, fontSize: 12.8)),
                            TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen())),
                                child: const Text('Regístrate',
                                    style: TextStyle(
                                        color: kMediBlue,
                                        fontSize: 12.8,
                                        fontWeight: FontWeight.bold))),
                          ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon,
      {bool obscure = false,
      Widget? suffix,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: kMediText, fontSize: 12.8, fontWeight: FontWeight.w600)),
      const SizedBox(height: 5.2),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 14.4),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 21.6, color: kMediMuted),
          suffixIcon: suffix,
          hintText: label == 'Correo electrónico'
              ? 'ejemplo@correo.com'
              : '••••••••••',
          hintStyle: const TextStyle(fontSize: 12.8, color: Color(0xFF9AA6B7)),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDDE3EC))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDDE3EC))),
        ),
      ),
    ]);
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Container(
        width: 86,
        height: 86,
        decoration:
            const BoxDecoration(shape: BoxShape.circle, color: kMediBlue),
        child:
            const Center(child: Icon(Icons.add, color: Colors.white, size: 52)),
      );
}
