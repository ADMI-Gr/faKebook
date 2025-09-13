import 'package:flutter/material.dart';
import '../../controllers/usuario_controller.dart';
import '../../models/usuario.dart';
import 'login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegistroPage extends StatefulWidget {
  final UsuarioController usuarioController;
  RegistroPage({Key? key, required this.usuarioController}) : super(key: key);

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController usuarioControllerTxt = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  File? _imageFile;

  String? nombreError;
  String? usuarioError;
  String? correoError;
  String? passwordError;

  @override
  void initState() {
    super.initState();
    nombreController.addListener(_validateNombre);
    usuarioControllerTxt.addListener(_validateUsuario);
    correoController.addListener(_validateCorreo);
    passwordController.addListener(_validatePassword);
  }

  void _validateNombre() {
    setState(() {
      nombreError = nombreController.text.trim().isEmpty ? 'Campo obligatorio' : null;
    });
  }

  void _validateUsuario() {
    setState(() {
      usuarioError = usuarioControllerTxt.text.trim().isEmpty ? 'Campo obligatorio' : null;
    });
  }

  void _validateCorreo() {
    setState(() {
      String value = correoController.text.trim();
      if (value.isEmpty) {
        correoError = 'Campo obligatorio';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
        correoError = 'Correo electrónico inválido';
      } else {
        correoError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      String value = passwordController.text.trim();
      if (value.isEmpty) {
        passwordError = 'Campo obligatorio';
      } else if (value.length < 6) {
        passwordError = 'Mínimo 6 caracteres';
      } else {
        passwordError = null;
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
      backgroundColor: Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 500),
              child: Column(
                children: [
                  SizedBox(height: 60),
                  Text(
                    'CREAR CUENTA',
                    style: TextStyle(
                      fontSize: 26,
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : AssetImage('assets/default_avatar.png') as ImageProvider,
                      child: _imageFile == null
                        ? Icon(Icons.add_a_photo, color: Colors.white70, size: 32)
                        : null,
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: nombreError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: nombreError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: nombreError != null ? Colors.red : Color(0xFF1976D2),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            errorText: null,
                          ),
                        ),
                        if (nombreError != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4, left: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(nombreError!, style: TextStyle(color: Colors.red, fontSize: 13)),
                            ),
                          ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: usuarioControllerTxt,
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: usuarioError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: usuarioError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: usuarioError != null ? Colors.red : Color(0xFF1976D2),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            errorText: null,
                          ),
                        ),
                        if (usuarioError != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4, left: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(usuarioError!, style: TextStyle(color: Colors.red, fontSize: 13)),
                            ),
                          ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: correoController,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: correoError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: correoError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: correoError != null ? Colors.red : Color(0xFF1976D2),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            errorText: null,
                          ),
                        ),
                        if (correoError != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4, left: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(correoError!, style: TextStyle(color: Colors.red, fontSize: 13)),
                            ),
                          ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: passwordError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: passwordError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: passwordError != null ? Colors.red : Color(0xFF1976D2),
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
                            padding: EdgeInsets.only(top: 4, left: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(passwordError!, style: TextStyle(color: Colors.red, fontSize: 13)),
                            ),
                          ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () async {
                              _validateNombre();
                              _validateUsuario();
                              _validateCorreo();
                              _validatePassword();

                              if (nombreError != null || usuarioError != null || correoError != null || passwordError != null) {
                                return;
                              }

                              final nuevoUsuario = Usuario(
                                nombre: nombreController.text.trim(),
                                usuario: usuarioControllerTxt.text.trim(),
                                correo: correoController.text.trim(),
                                password: passwordController.text.trim(),
                                fotoUrl: _imageFile?.path,
                              );
                              bool registrado = await widget.usuarioController.registrar(nuevoUsuario);
                              if (registrado) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Registrado con éxito')),
                                );
                                await Future.delayed(Duration(milliseconds: 300));
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => LoginPage(usuarioController: widget.usuarioController),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Correo o usuario ya registrado')),
                                );
                              }
                            },
                            child: Text('Registrarse', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('¿Ya tienes cuenta?'),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoginPage(usuarioController: widget.usuarioController),
                                  ),
                                );
                              },
                              child: Text(
                                'Inicia sesión',
                                style: TextStyle(color: Color(0xFF1976D2)),
                              ),
                            ),
                          ],
                        ),
                      ],
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
