import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this.client);

  final SupabaseClient client;

  Future<void> signIn({required String email, required String password}) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String fullName,
    String phone = '',
    String birthDate = '',
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'birth_date': birthDate.trim().isEmpty ? null : birthDate.trim(),
      },
    );

    if (response.session != null) {
      return 'Cuenta creada correctamente.';
    }

    return 'Cuenta creada. Revisa tu correo para confirmar la cuenta antes de iniciar sesión.';
  }

  Future<void> sendPasswordReset(String email) async {
    final redirectUrl = const String.fromEnvironment(
      'SUPABASE_REDIRECT_URL',
      defaultValue: '',
    );

    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl.isEmpty ? null : redirectUrl,
    );
  }

  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => client.auth.signOut();
}
