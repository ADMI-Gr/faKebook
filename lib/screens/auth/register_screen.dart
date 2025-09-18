// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  File? _imageFile;

  String? emailError;
  String? passwordError;
  String? userError;

  @override
  void initState() {
    super.initState();
    emailCtrl.addListener(_validateEmail);
    passCtrl.addListener(_validatePassword);
    userCtrl.addListener(_validateUser);
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

  void _validateUser() {
    setState(() {
      userError = userCtrl.text.trim().isEmpty ? 'Campo obligatorio' : null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
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
                    'CREAR CUENTA',
                    style: TextStyle(
                      fontSize: 26,
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 45,
                      child: _imageFile == null
                          ? const Icon(Icons.add_a_photo,
                              color: Colors.white70, size: 32)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: userCtrl,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: userError != null
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: userError != null
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: userError != null
                                      ? Colors.red
                                      : const Color(0xFF1976D2),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              errorText: null,
                            ),
                          ),
                          if (userError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(userError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13)),
                              ),
                            ),
                          const SizedBox(height: 16),
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
                                child: Text(emailError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13)),
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
                                child: Text(passwordError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13)),
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
                                _validateUser();

                                if (emailError != null ||
                                    passwordError != null ||
                                    userError != null) {
                                  return;
                                }

                                if (_formKey.currentState!.validate()) {
                                  try {
                                    final result =
                                        await ref.read(registerUserProvider({
                                      "email": emailCtrl.text,
                                      "password": passCtrl.text,
                                      "username": userCtrl.text,
                                    }).future);

                                    if (result != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("Registrado con éxito")),
                                      );
                                      await Future.delayed(
                                          const Duration(milliseconds: 300));

                                      // Navegar de vuelta o a otra pantalla
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Error al registrar usuario")),
                                    );
                                    print("Error al registrar usuario: $e");
                                    print(
                                        "Email: ${emailCtrl.text}, Username: ${userCtrl.text}");
                                  }
                                }
                              },
                              child: const Text('Registrarse',
                                  style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('¿Ya tienes cuenta?'),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Inicia sesión',
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

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    userCtrl.dispose();
    super.dispose();
  }
}
