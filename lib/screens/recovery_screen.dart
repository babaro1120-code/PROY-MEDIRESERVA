import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../widgets/medireserva_ui.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override State<RecoveryScreen> createState() => _RecoveryScreenState();
}
class _RecoveryScreenState extends State<RecoveryScreen> {
  final _email = TextEditingController();
  final _key = GlobalKey<FormState>();
  bool _busy = false;
  String? _message;
  @override void dispose() { _email.dispose(); super.dispose(); }
  Future<void> _send() async {
    if (!_key.currentState!.validate()) return;
    setState(() { _busy = true; _message = null; });
    try {
      await AuthService(Supabase.instance.client).sendPasswordReset(_email.text);
      if (mounted) setState(() => _message = 'Te enviamos un enlace para recuperar tu contraseña. Revisa tu correo.');
    } on AuthException catch (e) { if (mounted) setState(() => _message = e.message); }
    catch (_) { if (mounted) setState(() => _message = 'No fue posible enviar el enlace.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override Widget build(BuildContext context) => MediReservaPage(title: 'Recuperar contraseña', step: '', child: Form(key: _key, child: Column(children: [
    const Icon(Icons.mark_email_unread_outlined, color: kMediBlue, size:74.2), const SizedBox(height:10.4),
    const Text('Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.', textAlign: TextAlign.center, style: TextStyle(color: kMediMuted, fontSize:13.6, height: 1.5)), const SizedBox(height:20.8),
    TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null, style: const TextStyle(fontSize:14.4), decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline, size:21.6), hintText: 'Correo electrónico', isDense: true, border: OutlineInputBorder())),
    if (_message != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF138A4A), fontSize:12.8))),
    const SizedBox(height:15.6), MediButton(label: _busy ? 'Enviando...' : 'Enviar enlace', onPressed: _busy ? null : _send),
    TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Volver al inicio de sesión', style: TextStyle(color: kMediBlue, fontSize:12.8))),
  ])));
}
