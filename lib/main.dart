import 'package:flutter/material.dart';
import 'views/auth/login.dart';
import 'controllers/usuario_controller.dart';
import 'views/content/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/usuario.dart';

//ANGEL IMPORTS
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UsuarioController usuarioController = UsuarioController();
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre');
    final usuario = prefs.getString('usuario');
    final correo = prefs.getString('correo');
    final password = prefs.getString('password');
    final fotoUrl = prefs.getString('fotoUrl');
    if (correo != null &&
        password != null &&
        usuario != null &&
        nombre != null) {
      _home = DashboardPage(
        usuario: Usuario(
          nombre: nombre,
          usuario: usuario,
          correo: correo,
          password: password,
          fotoUrl: fotoUrl,
        ),
      );
    } else {
      _home = LoginPage(usuarioController: usuarioController);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fakebook',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: _home ?? Scaffold(body: Center(child: CircularProgressIndicator())),
      debugShowCheckedModeBanner: false,
    );
  }
}
