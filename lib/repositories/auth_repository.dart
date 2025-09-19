// lib/repositories/auth_repository.dart
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  //INsTANCIA DE SUPABASE
  final SupabaseClient _supabase = Supabase.instance.client;

  // REGISTRO DE USUARIO
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .insert({
          'id': user.id,
          'username': username,
          'display_name': displayName,
          'bio': null,
          'metadata': {},
          'avatar_url': null,
          'email': email,
        })
        .select()
        .single();

    return UserModel.fromMap(response);
  }

  // INICIO DE SESIÓN
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final authResponse = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) return null;

    final response =
        await _supabase.from('profiles').select().eq('id', user.id).single();

    return UserModel.fromMap(response);
  }

  // CIERRE DE SESIÓN
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // OBTENER USUARIO POR EMAIL
  Future<UserModel?> getUserByUsername(String email) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromMap(response);
  }


  // Método adicional para verificar si un username está disponible
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _supabase
        .from('profiles')
        .select('username')
        .eq('username', username)
        .maybeSingle();

    return response == null;
  }

  // Método para obtener el usuario actual desde auth
  User? get currentAuthUser => _supabase.auth.currentUser;

  // Stream para escuchar cambios en la autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;


}
