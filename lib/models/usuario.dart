class Usuario {
  String nombre;
  String usuario;
  String correo;
  String password;
  String? fotoUrl;

  Usuario({
    required this.nombre,
    required this.usuario,
    required this.correo,
    required this.password,
    this.fotoUrl,
  });
}
