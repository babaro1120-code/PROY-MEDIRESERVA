import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/update_password_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _subscription;
  bool _passwordRecovery = false;

  @override
  void initState() {
    super.initState();
    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _passwordRecovery = true);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_passwordRecovery) {
      return UpdatePasswordScreen(
        onFinished: () => setState(() => _passwordRecovery = false),
      );
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session == null) return const LoginScreen();
        return const MainShell();
      },
    );
  }
}
