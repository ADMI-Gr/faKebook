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

    // CAMBIO IMPORTANTE: Permitir establecer avatarUrl como null explícitamente
    // Si avatarUrl está presente en los parámetros (incluso si es null), actualízalo
    if (avatarUrl != null) {
      updateData['avatar_url'] = avatarUrl;
    } else {
      // Si quieres borrar el avatar, pasa null explícitamente
      // Esto permite distinguir entre "no cambiar" y "establecer como null"
      updateData['avatar_url'] = null;
    }

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

  // ACTUALIZAR INSIGNIAS DESTACADAS DEL USUARIO
  Future<void> updateFeaturedBadges(
      String userId, List<String> featuredBadgeIds) async {
    // Validar que no sean más de 6 insignias
    if (featuredBadgeIds.length > 6) {
      throw Exception('No se pueden destacar más de 6 insignias');
    }

    // Obtener el perfil actual para preservar otras propiedades de metadata
    final currentProfile = await getProfile(userId);
    if (currentProfile == null) {
      throw Exception('Usuario no encontrado');
    }

    // Crear nuevo metadata preservando lo existente
    final newMetadata =
        Map<String, dynamic>.from(currentProfile.metadata ?? {});

    // Asegurarnos de que existe la estructura de badges
    if (newMetadata['badges'] == null) {
      newMetadata['badges'] = {};
    }

    final badges = Map<String, dynamic>.from(newMetadata['badges']);

    // Preservar la lista 'all' si existe, solo actualizar 'featured'
    badges['featured'] = featuredBadgeIds;
    newMetadata['badges'] = badges;

    // Actualizar en la base de datos
    await _supabase.from('profiles').update({
      'metadata': newMetadata,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // OBTENER INSIGNIAS DESTACADAS DEL USUARIO
  Future<List<String>> getFeaturedBadges(String userId) async {
    final profile = await getProfile(userId);
    if (profile == null) return [];
    return profile.featuredBadges;
  }

  // OBTENER TODAS LAS INSIGNIAS DEL USUARIO (solo lectura)
  Future<List<String>> getAllUserBadges(String userId) async {
    final profile = await getProfile(userId);
    if (profile == null) return [];
    return profile.allBadges;
  }
}
