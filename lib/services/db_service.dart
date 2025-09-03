import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/usuario.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'red_social.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            usuario TEXT NOT NULL,
            correo TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            fotoUrl TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertUsuario(Usuario usuario) async {
    final db = await database;
    return await db.insert('usuarios', {
      'nombre': usuario.nombre,
      'usuario': usuario.usuario,
      'correo': usuario.correo,
      'password': usuario.password,
      'fotoUrl': usuario.fotoUrl,
    });
  }

  Future<Usuario?> getUsuario(String correo, String password) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      where: 'correo = ? AND password = ?',
      whereArgs: [correo, password],
    );

    if (res.isNotEmpty) {
      final u = res.first;
      return Usuario(
        nombre: u['nombre'] as String,
        usuario: u['usuario'] as String,
        correo: u['correo'] as String,
        password: u['password'] as String,
        fotoUrl: u['fotoUrl'] as String?,
      );
    }
    return null;
  }

  Future<bool> correoExiste(String correo) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
    );
    return res.isNotEmpty;
  }

  Future<bool> usuarioExiste(String usuario) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
    return res.isNotEmpty;
  }

  Future<Usuario?> getUsuarioPorUsuario(String usuario, String password) async {
    final db = await database;
    final res = await db.query(
      'usuarios',
      where: 'usuario = ? AND password = ?',
      whereArgs: [usuario, password],
    );
    if (res.isNotEmpty) {
      final u = res.first;
      return Usuario(
        nombre: u['nombre'] as String,
        usuario: u['usuario'] as String,
        correo: u['correo'] as String,
        password: u['password'] as String,
        fotoUrl: u['fotoUrl'] as String?,
      );
    }
    return null;
  }

  Future<void> actualizarFoto(String usuario, String fotoUrl) async {
    final db = await database;
    await db.update(
      'usuarios',
      {'fotoUrl': fotoUrl},
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
  }
}
