import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../usuarios/perfil.dart';

class DashboardPage extends StatelessWidget {
  final Usuario usuario;

  DashboardPage({Key? key, required this.usuario}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¡Bienvenido, ${usuario.nombre}!', style: TextStyle(fontSize: 24), textAlign: TextAlign.center,),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => PerfilPage(usuario: usuario),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
              child: Text('Ver Perfil'),
            ),
          ],
        ),
      ),
    );
  }
}
