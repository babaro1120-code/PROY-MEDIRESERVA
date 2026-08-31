import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _registerMode = false;
  bool _busy = false;
  bool _obscurePassword = true;

  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN / REGISTRO
  // ============================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final service = AuthService(
        Supabase.instance.client,
      );

      if (_registerMode) {
        final result = await service.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          setState(() {
            _message = result;
          });
        }
      } else {
        await service.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = 'Ocurrió un error: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // RECUPERAR CONTRASEÑA
  // ============================================================

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message =
            'Ingresa tu correo electrónico para recuperar tu contraseña.';
      });
      return;
    }

    try {
      setState(() {
        _busy = true;
        _message = null;
      });

      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
      );

      if (mounted) {
        setState(() {
          _message =
              'Se ha enviado un enlace de recuperación a tu correo.';
        });
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = 'Error al recuperar la contraseña.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // CAMBIAR ENTRE LOGIN Y REGISTRO
  // ============================================================

  void _toggleRegisterMode() {
    setState(() {
      _registerMode = !_registerMode;
      _message = null;
    });
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),

      body: SafeArea(
        child: Stack(
          children: [
            // ----------------------------------------------------
            // DECORACIÓN INFERIOR
            // ----------------------------------------------------

            Positioned(
              left: -35,
              bottom: -45,
              child: _cloud(
                width: 130,
                height: 95,
              ),
            ),

            Positioned(
              right: -35,
              bottom: -45,
              child: _cloud(
                width: 130,
                height: 95,
              ),
            ),

            Positioned(
              left: 55,
              bottom: -60,
              child: _cloud(
                width: 100,
                height: 70,
              ),
            ),

            Positioned(
              right: 55,
              bottom: -60,
              child: _cloud(
                width: 100,
                height: 70,
              ),
            ),

            // ----------------------------------------------------
            // CONTENIDO PRINCIPAL
            // ----------------------------------------------------

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 360,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.10),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        32,
                        20,
                        32,
                        25,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [

                            // =================================================
                            // LOGO
                            // =================================================

                            Center(
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF075BD8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 38,
                                  weight: 800,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // =================================================
                            // NOMBRE DE LA APLICACIÓN
                            // =================================================

                            const Text(
                              'MEDIRESERVA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF122B6B),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),

                            const SizedBox(height: 2),

                            const Text(
                              'Sistema de Reservas de Consultas Médicas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF52617A),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 22),

                            // =================================================
                            // CORREO
                            // =================================================

                            const Text(
                              'Correo electrónico',
                              style: TextStyle(
                                color: Color(0xFF16264A),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 5),

                            TextFormField(
                              controller: _emailController,
                              keyboardType:
                                  TextInputType.emailAddress,
                              textInputAction:
                                  TextInputAction.next,

                              decoration: InputDecoration(
                                hintText: 'ejemplo@correo.com',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9AA6B8),
                                  fontSize: 10,
                                ),
                                filled: true,
                                fillColor: Colors.white,

                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),

                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9E1EC),
                                    width: 1,
                                  ),
                                ),

                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF075BD8),
                                    width: 1.2,
                                  ),
                                ),
                              ),

                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1B2A41),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Ingresa tu correo';
                                }

                                if (!value.contains('@')) {
                                  return 'Correo electrónico inválido';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            // =================================================
                            // CONTRASEÑA
                            // =================================================

                            const Text(
                              'Contraseña',
                              style: TextStyle(
                                color: Color(0xFF16264A),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 5),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction:
                                  TextInputAction.done,

                              decoration: InputDecoration(
                                hintText: '••••••••••',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF7D8797),
                                  fontSize: 11,
                                ),

                                filled: true,
                                fillColor: Colors.white,

                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),

                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                    size: 17,
                                    color:
                                        const Color(0xFF64748B),
                                  ),
                                ),

                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9E1EC),
                                    width: 1,
                                  ),
                                ),

                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF075BD8),
                                    width: 1.2,
                                  ),
                                ),
                              ),

                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1B2A41),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Ingresa tu contraseña';
                                }

                                if (value.length < 6) {
                                  return 'Mínimo 6 caracteres';
                                }

                                return null;
                              },

                              onFieldSubmitted: (_) {
                                if (!_busy) {
                                  _submit();
                                }
                              },
                            ),

                            // =================================================
                            // RECUPERAR CONTRASEÑA
                            // =================================================

                            if (!_registerMode) ...[
                              const SizedBox(height: 8),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy
                                      ? null
                                      : _forgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize
                                            .shrinkWrap,
                                  ),
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: Color(0xFF075BD8),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // =================================================
                            // MENSAJE DE ERROR / INFORMACIÓN
                            // =================================================

                            if (_message != null) ...[
                              const SizedBox(height: 8),

                              Container(
                                padding:
                                    const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F6FF),
                                  borderRadius:
                                      BorderRadius.circular(5),
                                ),
                                child: Text(
                                  _message!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF34527D),
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            // =================================================
                            // BOTÓN INICIAR SESIÓN
                            // =================================================

                            SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                onPressed:
                                    _busy ? null : _submit,

                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF075BD8),
                                  foregroundColor: Colors.white,

                                  elevation: 0,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(5),
                                  ),
                                ),

                                child: _busy
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _registerMode
                                            ? 'Crear cuenta'
                                            : 'Iniciar sesión',
                                        style:
                                            const TextStyle(
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 13),

                            // =================================================
                            // REGISTRO
                            // =================================================

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  _registerMode
                                      ? '¿Ya tienes una cuenta? '
                                      : '¿No tienes cuenta? ',
                                  style: const TextStyle(
                                    color: Color(0xFF52617A),
                                    fontSize: 9,
                                  ),
                                ),

                                GestureDetector(
                                  onTap: _busy
                                      ? null
                                      : _toggleRegisterMode,
                                  child: Text(
                                    _registerMode
                                        ? 'Inicia sesión'
                                        : 'Regístrate',
                                    style: const TextStyle(
                                      color: Color(0xFF075BD8),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NUBES DECORATIVAS
  // ============================================================

  Widget _cloud({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2EEFF),
        borderRadius: BorderRadius.circular(60),
      ),
    );
  }
}