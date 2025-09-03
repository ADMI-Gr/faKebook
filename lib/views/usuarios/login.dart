import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/usuario_controller.dart';
import 'registro.dart';
import '../contenido/dashboard.dart';

class LoginPage extends StatelessWidget {
  final UsuarioController usuarioController;
  final TextEditingController usuarioCorreoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({Key? key, required this.usuarioController}) : super(key: key);

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
                        TextField(
                          controller: usuarioCorreoController,
                          decoration: InputDecoration(
                            labelText: 'Usuario o email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: true,
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
                              final usuario = await usuarioController.loginFlexible(
                                usuarioCorreoController.text,
                                passwordController.text,
                              );
                              if (usuario != null) {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('nombre', usuario.nombre);
                                await prefs.setString('usuario', usuario.usuario);
                                await prefs.setString('correo', usuario.correo);
                                await prefs.setString('password', usuario.password);
                                await prefs.setString('fotoUrl', usuario.fotoUrl ?? '');
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => DashboardPage(usuario: usuario),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Usuario/correo o contraseña incorrectos')),
                                );
                              }
                            },
                            child: Text('Entrar', style: TextStyle(fontSize: 18)),
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
                                    builder: (_) => RegistroPage(usuarioController: usuarioController),
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
