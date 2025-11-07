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

    // Solo actualiza avatar_url si se proporciona explícitamente.
    // Para borrar, se debe pasar un `null` explícito.
    // Si no se pasa el parámetro, no se toca el campo.
    if (metadata != null) updateData['metadata'] = metadata;
    if (avatarUrl != null || (metadata == null && displayName == null && bio == null)) updateData['avatar_url'] = avatarUrl;


    // Siempre actualizar updated_at
    updateData['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('profiles').update(updateData).eq('id', userId);
  }

  //ACTUALIZAR FOTO DE PERFIL
  Future<void> updateAvatar(String userId, String pathLocalDeLaImagen) async {
    // 1. Obtener perfil actual para saber si hay una imagen anterior
    final currentUser = await getProfile(userId);
    final oldAvatarUrl = currentUser?.avatarUrl;

    // 2. Subir la nueva imagen
    final imageFile = File(pathLocalDeLaImagen);
    final fileName =
        "${userId}_avatar_${DateTime.now().millisecondsSinceEpoch}.png";
    await _supabase.storage.from('avatars').upload(fileName, imageFile,
        fileOptions: const FileOptions(upsert: true));

    // 3. Obtener la URL pública de la nueva imagen
    final avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

    // 4. Actualizar el perfil con la nueva URL
    await _supabase
        .from('profiles')
        .update({'avatar_url': avatarUrl}).eq('id', userId);

    // 5. Si había una imagen anterior, eliminarla del storage
    if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(oldAvatarUrl);
        // La ruta del archivo en el bucket es el último segmento de la URL
        final oldFileName = uri.pathSegments.last;
        if (oldFileName.isNotEmpty) {
          await _supabase.storage.from('avatars').remove([oldFileName]);
        }
      } catch (e) {
        // Si falla la eliminación, no es crítico. Lo registramos.
        print('Error al eliminar avatar anterior: $e');
      }
    }
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
