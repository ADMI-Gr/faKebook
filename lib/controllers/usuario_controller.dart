import '../models/usuario.dart';
import '../services/db_service.dart';

class UsuarioController {
  final DBService _db = DBService();

  Future<bool> registrar(Usuario usuario) async {
    if (await _db.correoExiste(usuario.correo) || await _db.usuarioExiste(usuario.usuario)) {
      return false; // correo o usuario duplicado
    }
    await _db.insertUsuario(usuario);
    return true;
  }

  Future<Usuario?> login(String correo, String password) async {
    return await _db.getUsuario(correo, password);
  }

  Future<Usuario?> loginFlexible(String usuarioOCorreo, String password) async {
    Usuario? usuario = await _db.getUsuario(usuarioOCorreo, password);
    if (usuario != null) return usuario;
    usuario = await _db.getUsuarioPorUsuario(usuarioOCorreo, password);
    return usuario;
  }

  Future<void> actualizarFoto(String usuario, String fotoUrl) async {
    await _db.actualizarFoto(usuario, fotoUrl);
  }
}
