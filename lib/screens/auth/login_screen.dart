// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String? emailError;
  String? passwordError;

  @override
  void initState() {
    super.initState();
    emailCtrl.addListener(_validateEmail);
    passCtrl.addListener(_validatePassword);
  }

  void _validateEmail() {
    setState(() {
      String value = emailCtrl.text.trim();
      if (value.isEmpty) {
        emailError = 'Campo obligatorio';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
        emailError = 'Correo electrónico inválido';
      } else {
        emailError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      String value = passCtrl.text.trim();
      if (value.isEmpty) {
        passwordError = 'Campo obligatorio';
      } else if (value.length < 6) {
        passwordError = 'Mínimo 6 caracteres';
      } else {
        passwordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontSize: 26,
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailCtrl,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: emailError != null
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: emailError != null
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: emailError != null
                                      ? Colors.red
                                      : const Color(0xFF1976D2),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              errorText: null,
                            ),
                          ),
                          if (emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  emailError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passCtrl,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: passwordError != null
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: passwordError != null
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: passwordError != null
                                      ? Colors.red
                                      : const Color(0xFF1976D2),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              errorText: null,
                            ),
                            obscureText: true,
                          ),
                          if (passwordError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  passwordError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () async {
                                _validateEmail();
                                _validatePassword();

                                if (emailError != null ||
                                    passwordError != null) {
                                  return;
                                }

                                try {
                                  final result =
                                      await ref.read(loginUserProvider({
                                    "email": emailCtrl.text.trim(),
                                    "password": passCtrl.text.trim(),
                                  }).future);

                                  if (result != null) {
                                    ref.read(userProvider.notifier).state =
                                        result;

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              "Bienvenido ${result.username}!"),
                                        ),
                                      );

                                      Navigator.pushReplacementNamed(
                                          context, "/home");
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'Iniciar Sesión',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('¿No tienes cuenta?'),
                              TextButton(
                                onPressed: () {
                                  // Navegar a la pantalla de registro
                                  Navigator.pushNamed(context, '/register');
                                },
                                child: const Text(
                                  'Regístrate',
                                  style: TextStyle(color: Color(0xFF1976D2)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
