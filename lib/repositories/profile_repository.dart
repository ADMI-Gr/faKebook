import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel?> getProfile(String userId) async {
    final response =
        await _supabase.from('profiles').select().eq('id', userId).single();

    if (response == null) return null;

    return UserModel.fromMap(response);
  }

  // OBTENER USUARIO ACTUAL
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

  // ACTUALIZAR PERFIL DE USUARIO
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

  //ACTUALIZAR FOTO DE PERFIL
  Future<void> updateAvatar(String userId, String pathLocalDeLaImagen) async {
    //Obtenemos el archivo de la imagen en local
    final imageFile = File(pathLocalDeLaImagen);
    print("Ruta local de la imagen: $pathLocalDeLaImagen");
    //Subimos la imagen a Supabase Storage con el userId y un timestamp para que sea único
    final fileName =
        "${userId}_avatar_${DateTime.now().millisecondsSinceEpoch}.png";
    print("Nombre del archivo a subir: $fileName del usuario: $userId");
    await _supabase.storage.from('avatars').upload(fileName, imageFile,
        fileOptions: const FileOptions(upsert: true));

    // Obtenemos la URL pública de la imagen subida
    final avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

    await _supabase
        .from('profiles')
        .update({'avatar_url': avatarUrl}).eq('id', userId);
  }
}
