import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/usuario.dart';
import 'login.dart';
import '../../controllers/usuario_controller.dart';
import 'package:image_picker/image_picker.dart';
import '../content/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/custom_navbar.dart';

class PerfilPage extends StatefulWidget {
  final Usuario usuario;

  PerfilPage({Key? key, required this.usuario}) : super(key: key);

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late Usuario usuario;
  File? _imageFile;
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
    if (usuario.fotoUrl != null &&
        usuario.fotoUrl!.isNotEmpty &&
        !usuario.fotoUrl!.startsWith('http')) {
      _imageFile = File(usuario.fotoUrl!);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        usuario.fotoUrl = pickedFile.path;
      });
      // Actualiza la foto en la base de datos
      await UsuarioController()
          .actualizarFoto(usuario.usuario, pickedFile.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto de perfil actualizada')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => DashboardPage(usuario: widget.usuario)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mi Perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => LoginPage(
                                  usuarioController: UsuarioController()),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (usuario.fotoUrl != null &&
                                usuario.fotoUrl!.isNotEmpty
                            ? (usuario.fotoUrl!.startsWith('http')
                                    ? NetworkImage(usuario.fotoUrl!)
                                    : FileImage(File(usuario.fotoUrl!)))
                                as ImageProvider
                            : AssetImage('assets/default_avatar.png')),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                usuario.nombre,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                '@${usuario.usuario}',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 8),
              Text(
                usuario.correo,
                style: TextStyle(fontSize: 14, color: Colors.black45),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          DashboardPage(usuario: usuario),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
                child: Text('Volver al Dashboard'),
              ),
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Publicaciones',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Ejemplo de publicaciones (puedes reemplazar por tu lógica real)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: List.generate(
                      2,
                      (index) => Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage: usuario.fotoUrl != null
                                        ? NetworkImage(usuario.fotoUrl!)
                                        : AssetImage(
                                                'assets/default_avatar.png')
                                            as ImageProvider,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          usuario.nombre,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('Great shot! I love it'),
                                        SizedBox(height: 4),
                                        Text('2 mins ago',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black38)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
