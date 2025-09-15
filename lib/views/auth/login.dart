import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/usuario_controller.dart';
import 'registro.dart';
import '../content/dashboard.dart';

class LoginPage extends StatefulWidget {
  final UsuarioController usuarioController;
  LoginPage({Key? key, required this.usuarioController}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usuarioCorreoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? usuarioCorreoError;
  String? passwordError;

  @override
  void initState() {
    super.initState();
    usuarioCorreoController.addListener(_validateUsuarioCorreo);
    passwordController.addListener(_validatePassword);
  }

  void _validateUsuarioCorreo() {
    setState(() {
      String value = usuarioCorreoController.text.trim();
      if (value.isEmpty) {
        usuarioCorreoError = 'Campo obligatorio';
      } else if (value.contains('@') &&
          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
        usuarioCorreoError = 'Correo electrónico inválido';
      } else {
        usuarioCorreoError = null;
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
                    'INICIAR SESION',
                    style: TextStyle(
                      fontSize: 26,
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: usuarioCorreoController,
                          decoration: InputDecoration(
                            labelText: 'Usuario o email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: usuarioCorreoError != null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: usuarioCorreoError != null
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: usuarioCorreoError != null
                                    ? Colors.red
                                    : Color(0xFF1976D2),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            errorText: null,
                          ),
                        ),
                        if (usuarioCorreoError != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4, left: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(usuarioCorreoError!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 13)),
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
                                    : Color(0xFF1976D2),
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
                              child: Text(passwordError!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 13)),
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
                              _validateUsuarioCorreo();
                              _validatePassword();

                              if (usuarioCorreoError != null ||
                                  passwordError != null) {
                                return;
                              }

                              final usuario =
                                  await widget.usuarioController.loginFlexible(
                                usuarioCorreoController.text.trim(),
                                passwordController.text.trim(),
                              );
                              if (usuario != null) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString('nombre', usuario.nombre);
                                await prefs.setString(
                                    'usuario', usuario.usuario);
                                await prefs.setString('correo', usuario.correo);
                                await prefs.setString(
                                    'password', usuario.password);
                                await prefs.setString(
                                    'fotoUrl', usuario.fotoUrl ?? '');
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) =>
                                        DashboardPage(usuario: usuario),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      return FadeTransition(
                                          opacity: animation, child: child);
                                    },
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Usuario/correo o contraseña incorrectos')),
                                );
                              }
                            },
                            child:
                                Text('Entrar', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('¿No tienes cuenta?'),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegistroPage(
                                        usuarioController:
                                            widget.usuarioController),
                                  ),
                                );
                              },
                              child: Text(
                                'Regístrate',
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
