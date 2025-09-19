// lib/screens/register_screen.dart
import 'package:fakebook/widgets/textField_register.dart';
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
  final displayNameCtrl = TextEditingController();
  // Controladores adicionales para correos @itca.edu.sv
  final sedeCtrl = TextEditingController();
  final carreraCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final List<String> _sedes = const [
    'ITCA FEPADE Santa Tecla',
    'ITCA FEPADE San Miguel',
    'ITCA FEPADE La Union',
    'ITCA FEPADE Santa Ana',
    'ITCA FEPADE Zacatecoluca',
  ];
  String? _selectedSede;
  File? _imageFile;

  String? emailError;
  String? passwordError;
  String? userError;
  String? displayNameError;
  String? sedeError;
  String? carreraError;
  String? yearError;
  String? bioError;

  bool get _isItcaEmail =>
      emailCtrl.text.trim().toLowerCase().endsWith('@itca.edu.sv');
  // Datos demo, falto decidir que datos se usarian aqui para el tema del año
  final List<String> _years = const [
    '1° Primero',
    '2° Segundo',
    'Graduado',
    'Otro'
  ];
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    emailCtrl.addListener(_validateEmail);
    passCtrl.addListener(_validatePassword);
    userCtrl.addListener(_validateUser);
    displayNameCtrl.addListener(_validateDisplayName);
    carreraCtrl.addListener(_validateItcaFields);
    yearCtrl.addListener(_validateItcaFields);
    bioCtrl.addListener(_validateBio);
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
      final value = userCtrl.text.trim();
      if (value.isEmpty) {
        userError = 'Campo obligatorio';
      } else if (value.length < 3) {
        userError = 'Mínimo 3 caracteres';
      } else {
        userError = null;
      }
    });
  }

  void _validateDisplayName() {
    setState(() {
      final value = displayNameCtrl.text.trim();
      if (value.isEmpty) {
        displayNameError = 'Campo obligatorio';
      } else if (value.length < 4) {
        displayNameError = 'Mínimo 4 caracteres';
      } else {
        displayNameError = null;
      }
    });
  }

  void _validateItcaFields() {
    if (!_isItcaEmail) {
      setState(() {
        sedeError = null;
        carreraError = null;
        yearError = null;
      });
      return;
    }
    setState(() {
      sedeError = (_selectedSede == null || _selectedSede!.trim().isEmpty)
          ? 'Selecciona una sede'
          : null;
      final carrera = carreraCtrl.text.trim();
      carreraError = carrera.isEmpty
          ? 'Campo obligatorio'
          : (carrera.length < 4 ? 'Mínimo 4 caracteres' : null);
      yearError = (_selectedYear == null || _selectedYear!.trim().isEmpty)
          ? 'Selecciona un año'
          : null;
    });
  }

  void _validateBio() {
    setState(() {
      final bio = bioCtrl.text.trim();
      if (bio.isEmpty) {
        bioError = 'Campo obligatorio';
      } else if (bio.length < 6) {
        bioError = 'Mínimo 6 caracteres';
      } else {
        bioError = null;
      }
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
                      backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? const Icon(
                              Icons.add_a_photo,
                              color: Colors.white70,
                              size: 32,
                            )
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
                          TextFieldRegister(
                            controller: displayNameCtrl,
                            labelText: 'Nombre',
                            errorText: displayNameError,
                          ),
                          if (displayNameError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  displayNameError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextFieldRegister(
                            controller: userCtrl,
                            labelText: 'Username',
                            errorText: userError,
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
                          TextFieldRegister(
                            controller: emailCtrl,
                            labelText: 'Email',
                            errorText: emailError,
                            keyboardType: TextInputType.emailAddress,
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
                          TextFieldRegister(
                            controller: passCtrl,
                            labelText: 'Contraseña',
                            errorText: passwordError,
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
                          // Campos adicionales para correos @itca.edu.sv
                          if (_isItcaEmail) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedSede,
                              items: _sedes
                                  .map((sede) => DropdownMenuItem<String>(
                                        value: sede,
                                        child: Text(sede),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSede = value;
                                });
                                _validateItcaFields();
                              },
                              decoration: InputDecoration(
                                labelText: 'Sede',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            if (sedeError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    sedeError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            TextFieldRegister(
                              controller: carreraCtrl,
                              labelText: 'Carrera',
                              errorText: carreraError,
                            ),
                            if (carreraError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    carreraError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedYear,
                              items: _years
                                  .map((y) => DropdownMenuItem<String>(
                                        value: y,
                                        child: Text(y),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedYear = value;
                                });
                                _validateItcaFields();
                              },
                              decoration: InputDecoration(
                                labelText: 'Año',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            if (yearError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    yearError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 12),
                          TextFieldRegister(
                            controller: bioCtrl,
                            labelText: 'Biografía',
                            errorText: bioError,
                            maxLines: 3,
                          ),
                          if (bioError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  bioError!,
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
                                _validateUser();
                                _validateDisplayName();
                                _validateBio();
                                if (_isItcaEmail) {
                                  _validateItcaFields();
                                }

                                if (emailError != null ||
                                    passwordError != null ||
                                    userError != null ||
                                    displayNameError != null ||
                                    bioError != null ||
                                    (_isItcaEmail &&
                                        (sedeError != null ||
                                            carreraError != null ||
                                            yearError != null))) {
                                  return;
                                }

                                if (_formKey.currentState!.validate()) {
                                  try {
                                    //// EN REGISTER PROVIDER FALTA EL CAMPO PARA MANDAR LA FOTO, CUANDO SE AGREGE SE MNADA POR AQUI ///
                                    /// Tambien el formato en que se guardara si sera en bits o Base64 o con el PATH o otro q desconozco
                                    final result =
                                        await ref.read(registerUserProvider({
                                      "email": emailCtrl.text,
                                      "password": passCtrl.text,
                                      "username": userCtrl.text,
                                      "displayName":
                                          displayNameCtrl.text.trim(),
                                    }).future);

                                    if (result != null) {
                                      // Si es correo de itca se actualiza el perfil con campos adicionales (los que faltan)
                                      // Se manda la demas info en metadata porque no se aun como se va a manejar, caso contrario se cambia posteriormente
                                      if (_isItcaEmail) {
                                        final sede =
                                            _selectedSede?.trim() ?? '';
                                        final carrera = carreraCtrl.text.trim();
                                        final year =
                                            _selectedYear?.trim() ?? '';
                                        final bio = bioCtrl.text.trim();
                                        final metadata = <String, dynamic>{};
                                        if (sede.isNotEmpty) {
                                          metadata['sede'] = sede;
                                        }
                                        if (carrera.isNotEmpty) {
                                          metadata['carrera'] = carrera;
                                        }
                                        if (year.isNotEmpty) {
                                          metadata['year'] = year;
                                        }

                                        await ref.read(updateProfileProvider({
                                          'displayName': null,
                                          'bio': bio.isNotEmpty ? bio : null,
                                          'avatarUrl': null,
                                          'metadata': metadata.isNotEmpty
                                              ? metadata
                                              : null,
                                        }).future);
                                      } else {
                                        final bio = bioCtrl.text.trim();
                                        if (bio.isNotEmpty) {
                                          await ref.read(updateProfileProvider({
                                            'displayName': null,
                                            'bio': bio,
                                            'avatarUrl': null,
                                            'metadata': null,
                                          }).future);
                                        }
                                      }
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("Registrado con éxito")),
                                      );
                                      await Future.delayed(
                                          const Duration(milliseconds: 300));

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
    sedeCtrl.dispose();
    carreraCtrl.dispose();
    yearCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }
}
