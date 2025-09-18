// lib/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('username', username)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromMap(response);
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromMap(response);
  }

  Future<void> updateUserProfile(
    String userId, {
    String? displayName,
    String? bio,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final updateData = <String, dynamic>{};

    if (displayName != null) updateData['display_name'] = displayName;
    if (bio != null) updateData['bio'] = bio;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    if (metadata != null) updateData['metadata'] = metadata;

    // Siempre actualizar updated_at
    updateData['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('profiles').update(updateData).eq('id', userId);
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
