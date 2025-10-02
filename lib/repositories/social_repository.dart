import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SocialRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Método para seguir a otro usuario
  Future<void> followUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) {
      throw Exception("No puedes seguirte a ti mismo");
    }

    // Verificamos si ya existe la relación de seguimiento
    final exists = await _supabase
        .from('follows')
        .select()
        .eq('follower_id', currentUserId)
        .eq('followee_id', targetUserId);

    if ((exists as List).isNotEmpty) {
      // Ya se está siguiendo
      return;
    }

    // Verificamos bloqueos en cualquier dirección entre los dos usuarios
    final blocked = await _supabase.from('blocks').select().or(
          'and(blocker_id.eq.$currentUserId,blocked_id.eq.$targetUserId),and(blocker_id.eq.$targetUserId,blocked_id.eq.$currentUserId)',
        );

    if ((blocked as List).isNotEmpty) {
      throw Exception("No puedes seguir a este usuario debido a un bloqueo");
    }

    // Insertamos la relación de seguimiento
    await _supabase.from('follows').insert({
      'follower_id': currentUserId,
      'followee_id': targetUserId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  //Meotod para dejar de seguir a otro usuario
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', currentUserId)
        .eq('followee_id', targetUserId);
  }

  //Meotod para obtener la lista de usuarios que sigue el usuario actual
  Future<List<UserModel>> getFollowing(String userId) async {
    final response = await _supabase
        .from('follows')
        .select('followee_id')
        .eq('follower_id', userId);

    final followedIds =
        (response as List).map((e) => e['followee_id'] as String).toList();

    if (followedIds.isEmpty) return [];

    // Construir una query tipo OR
    final orQuery = followedIds.map((id) => 'id.eq.$id').join(',');

    final usersResponse = await _supabase.from('profiles').select().or(orQuery);

    return (usersResponse as List).map((e) => UserModel.fromMap(e)).toList();
  }

  //Meotod para obtener la lista de usuarios que siguen al usuario actual
  Future<List<UserModel>> getFollowers(String userId) async {
    final response = await _supabase
        .from('follows')
        .select('follower_id')
        .eq('followee_id', userId);

    final followerIds =
        (response as List).map((e) => e['follower_id'] as String).toList();

    if (followerIds.isEmpty) return [];

    // Construir una query tipo OR
    final orQuery = followerIds.map((id) => 'id.eq.$id').join(',');

    final usersResponse = await _supabase.from('profiles').select().or(orQuery);

    return (usersResponse as List).map((e) => UserModel.fromMap(e)).toList();
  }

  // Método para buscar usuarios por username o displayName
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%');

    return (response as List).map((e) => UserModel.fromMap(e)).toList();
  }

  //Bloquear usuario
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) {
      throw Exception("No puedes bloquearte a ti mismo");
    }

    final exists = await _supabase
        .from('blocks')
        .select()
        .eq('blocker_id', currentUserId)
        .eq('blocked_id', targetUserId);

    if ((exists as List).isEmpty) {
      await _supabase.from('blocks').insert({
        'blocker_id': currentUserId,
        'blocked_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });
      // Forzar que ambos dejen de seguirse mutuamente
      // El usuario actual deja de seguir al usuario bloqueado
      await unfollowUser(currentUserId, targetUserId);
      // El usuario bloqueado deja de seguir al usuario actual
      await unfollowUser(targetUserId, currentUserId);
    }
  }

  //Desbloquear usuario
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    await _supabase
        .from('blocks')
        .delete()
        .eq('blocker_id', currentUserId)
        .eq('blocked_id', targetUserId);
  }

  // Método para verificar si un usuario (blockerId) ha bloqueado a otro (blockedId)
  Future<bool> isUserBlocked(String blockerId, String blockedId) async {
    final response = await _supabase
        .from('blocks')
        .select('blocker_id')
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  //Metodo para obtener la lista de usuarios que ha bloqueado el usuario actual
  Future<List<UserModel>> getBlockedUsers(String userId) async {
    final response = await _supabase
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', userId);

    final blockedIds =
        (response as List).map((e) => e['blocked_id'] as String).toList();

    if (blockedIds.isEmpty) return [];

    // Construir una query tipo OR
    final orQuery = blockedIds.map((id) => 'id.eq.$id').join(',');

    final usersResponse = await _supabase.from('profiles').select().or(orQuery);

    return (usersResponse as List).map((e) => UserModel.fromMap(e)).toList();
  }

  // Método para obtener las publicaciones de un usuario específico
  Future<List<Map<String, dynamic>>> getPostsForUser(String userId) async {
    final response = await _supabase
        .from('posts')
        .select()
        .eq('author_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  // Método para crear una nueva publicación
  Future<void> createPost({
    required String authorId,
    required String content,
    String? imageUrl,
  }) async {
    await _supabase.from('posts').insert({
      'author_id': authorId,
      'content': content,
      'content_json': imageUrl != null ? {'image_url': imageUrl} : null,
    });
  }

  // Método para obtener todas las publicaciones (para el dashboard, por ejemplo)
  Future<List<Map<String, dynamic>>> getAllPosts() async {
    final response = await _supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  // Método para actualizar una publicación existente
  Future<void> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> updateData = {
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
      'content_json': imageUrl != null ? {'image_url': imageUrl} : {},
    };
    await _supabase.from('posts').update(updateData).eq('id', postId);
  }

  // Método para eliminar una publicación
  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  Future<String> uploadImage(File file, String filePath) async {
    try {
      // Subir el archivo al bucket 'posts' (o el nombre de tu bucket)
      final response = await _supabase.storage
          .from('posts') // Cambia 'posts' por el nombre de tu bucket
          .upload(filePath, file);

      // Obtener la URL pública del archivo subido
      final publicUrl = _supabase.storage.from('posts').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error en uploadImage: $e');
      throw Exception('No se pudo subir la imagen: $e');
    }
  }

  /// Eliminar imagen de Supabase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extraer el path del archivo desde la URL
      // Ejemplo de URL: https://xxx.supabase.co/storage/v1/object/public/posts/user123_1234567890.jpg
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Buscar el índice de 'posts' en los segmentos del path
      final bucketIndex = pathSegments.indexOf('posts');
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('No se pudo extraer el path del archivo de la URL');
      }

      // El path del archivo es todo lo que viene después del bucket
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Eliminar el archivo del storage
      await _supabase.storage.from('posts').remove([filePath]);

      print('Imagen eliminada correctamente: $filePath');
    } catch (e) {
      print('Error al eliminar imagen: $e');
      throw Exception('No se pudo eliminar la imagen: $e');
    }
  }
}
