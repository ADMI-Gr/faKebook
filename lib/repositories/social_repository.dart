import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SocialRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  // ==================== MÉTODOS DE SEGUIMIENTO ====================
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

  // ==================== MÉTODOS DE BLOQUEO ====================
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

  // ==================== MÉTODOS DE POSTS ====================
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

  // ==================== MÉTODOS DE STORAGE ====================
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

  // ==================== MÉTODOS DE REACCIONES ====================

  /// Agregar o cambiar reacción
  /// Si el usuario ya tiene una reacción diferente, la reemplaza
  /// Si tiene la misma, no hace nada (usar toggleReaction para quitar)
  Future<void> addReaction({
    required String targetType,
    required String targetId,
    required String reactorId,
    required String reactionType,
  }) async {
    try {
      // Verificar si ya existe alguna reacción del usuario en este target
      final existingReaction = await _supabase
          .from('reactions')
          .select()
          .eq('target_type', targetType)
          .eq('target_id', targetId)
          .eq('reactor_id', reactorId)
          .maybeSingle();

      if (existingReaction != null) {
        // Si ya tiene la misma reacción, no hacer nada
        if (existingReaction['reaction_type'] == reactionType) {
          return;
        }
        // Si tiene una reacción diferente, actualizarla
        await _supabase
            .from('reactions')
            .update({
              'reaction_type': reactionType,
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('target_type', targetType)
            .eq('target_id', targetId)
            .eq('reactor_id', reactorId);
      } else {
        // Insertar nueva reacción
        await _supabase.from('reactions').insert({
          'target_type': targetType,
          'target_id': targetId,
          'reactor_id': reactorId,
          'reaction_type': reactionType,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error en addReaction: $e');
      throw Exception('No se pudo agregar la reacción: $e');
    }
  }

  /// Quitar reacción específica del usuario
  Future<void> removeReaction({
    required String targetType,
    required String targetId,
    required String reactorId,
  }) async {
    try {
      await _supabase
          .from('reactions')
          .delete()
          .eq('target_type', targetType)
          .eq('target_id', targetId)
          .eq('reactor_id', reactorId);
    } catch (e) {
      print('Error en removeReaction: $e');
      throw Exception('No se pudo quitar la reacción: $e');
    }
  }

  /// Alternar reacción (toggle): si existe la quita, si no existe la agrega
  Future<void> toggleReaction({
    required String targetType,
    required String targetId,
    required String reactorId,
    required String reactionType,
  }) async {
    try {
      final existingReaction = await _supabase
          .from('reactions')
          .select()
          .eq('target_type', targetType)
          .eq('target_id', targetId)
          .eq('reactor_id', reactorId)
          .maybeSingle();

      if (existingReaction != null) {
        // Si tiene la misma reacción, quitarla
        if (existingReaction['reaction_type'] == reactionType) {
          await removeReaction(
            targetType: targetType,
            targetId: targetId,
            reactorId: reactorId,
          );
        } else {
          // Si tiene otra reacción, cambiarla
          await addReaction(
            targetType: targetType,
            targetId: targetId,
            reactorId: reactorId,
            reactionType: reactionType,
          );
        }
      } else {
        // No tiene reacción, agregarla
        await addReaction(
          targetType: targetType,
          targetId: targetId,
          reactorId: reactorId,
          reactionType: reactionType,
        );
      }
    } catch (e) {
      print('Error en toggleReaction: $e');
      throw Exception('No se pudo alternar la reacción: $e');
    }
  }

  /// Obtener contadores de reacciones agrupados por tipo
  /// Retorna Map: {'like': 5, 'love': 3, 'laugh': 1}
  Future<Map<String, int>> getReactionCounts({
    required String targetType,
    required String targetId,
  }) async {
    try {
      final response = await _supabase
          .from('reactions')
          .select('reaction_type')
          .eq('target_type', targetType)
          .eq('target_id', targetId);

      final reactions = response as List;

      // Contar reacciones por tipo
      final Map<String, int> counts = {};
      for (final reaction in reactions) {
        final type = reaction['reaction_type'] as String;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error en getReactionCounts: $e');
      return {};
    }
  }

  /// Obtener la reacción del usuario actual (si existe)
  /// Retorna el tipo de reacción o null si no ha reaccionado
  Future<String?> getUserReaction({
    required String targetType,
    required String targetId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('reactions')
          .select('reaction_type')
          .eq('target_type', targetType)
          .eq('target_id', targetId)
          .eq('reactor_id', userId)
          .maybeSingle();

      return response?['reaction_type'] as String?;
    } catch (e) {
      print('Error en getUserReaction: $e');
      return null;
    }
  }

  /// Obtener lista de usuarios que reaccionaron
  /// Si reactionType es null, obtiene todos los que reaccionaron
  /// Si se especifica, solo obtiene los que pusieron esa reacción
  Future<List<({UserModel user, String reactionType})>> getReactors({
    required String targetType,
    required String targetId,
    String? reactionType,
  }) async {
    try {
      var query = _supabase
          .from('reactions')
          .select('reactor_id, reaction_type')
          .eq('target_type', targetType)
          .eq('target_id', targetId);

      if (reactionType != null) {
        query = query.eq('reaction_type', reactionType);
      }

      final reactions = await query;

      if ((reactions as List).isEmpty) return [];

      // Obtener IDs únicos de reactores
      final reactorIds =
          reactions.map((e) => e['reactor_id'] as String).toSet().toList();

      // Construir query para obtener perfiles
      final orQuery = reactorIds.map((id) => 'id.eq.$id').join(',');
      final usersResponse =
          await _supabase.from('profiles').select().or(orQuery);

      // Crear mapa de usuarios por ID
      final usersMap = <String, UserModel>{};
      for (final userData in usersResponse as List) {
        final user = UserModel.fromMap(userData);
        usersMap[user.id] = user;
      }

      // Combinar usuarios con sus reacciones
      return reactions
          .where((r) => usersMap.containsKey(r['reactor_id']))
          .map((r) => (
                user: usersMap[r['reactor_id']]!,
                reactionType: r['reaction_type'] as String,
              ))
          .toList();
    } catch (e) {
      print('Error en getReactors: $e');
      return [];
    }
  }

  // ==================== MÉTODOS DE COMENTARIOS ====================

  /// Crear un nuevo comentario
  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String authorId,
    required String content,
    String? parentComment,
  }) async {
    try {
      final response = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'author_id': authorId,
            'content': content,
            'parent_comment': parentComment,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error en createComment: $e');
      throw Exception('No se pudo crear el comentario: $e');
    }
  }

  /// Editar un comentario existente
  Future<void> updateComment({
    required String commentId,
    required String authorId,
    required String content,
  }) async {
    try {
      await _supabase
          .from('comments')
          .update({'content': content})
          .eq('id', commentId)
          .eq('author_id', authorId); // Seguridad: solo el autor puede editar
    } catch (e) {
      print('Error en updateComment: $e');
      throw Exception('No se pudo editar el comentario: $e');
    }
  }

  /// Eliminar un comentario (soft delete)
  Future<void> deleteComment({
    required String commentId,
    required String authorId,
  }) async {
    try {
      await _supabase
          .from('comments')
          .update({'is_deleted': true})
          .eq('id', commentId)
          .eq('author_id', authorId); // Seguridad: solo el autor puede eliminar
    } catch (e) {
      print('Error en deleteComment: $e');
      throw Exception('No se pudo eliminar el comentario: $e');
    }
  }

  /// Obtener comentarios de nivel superior de un post (sin respuestas)
  Future<List<Map<String, dynamic>>> getPostComments({
    required String postId,
  }) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .filter('parent_comment', 'is', null)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error en getPostComments: $e');
      return [];
    }
  }

  /// Obtener respuestas de un comentario específico
  Future<List<Map<String, dynamic>>> getCommentReplies({
    required String commentId,
  }) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('parent_comment', commentId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error en getCommentReplies: $e');
      return [];
    }
  }

  /// Obtener contador total de comentarios (incluyendo respuestas)
  Future<int> getCommentCount({
    required String postId,
  }) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('id')
          .eq('post_id', postId)
          .eq('is_deleted', false);

      return (response as List).length;
    } catch (e) {
      print('Error en getCommentCount: $e');
      return 0;
    }
  }

  // ==================== MÉTODOS DE NOTIFICACIONES ====================

  /// Crear una notificación
  Future<void> createNotification({
    required String recipientId,
    String? actorId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // No crear notificación si el actor es el mismo que el receptor
      if (actorId == recipientId) return;

      await _supabase.from('notifications').insert({
        'recipient_id': recipientId,
        'actor_id': actorId,
        'type': type,
        'payload': payload,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error en createNotification: $e');
      // No lanzar excepción para que no bloquee la operación principal
    }
  }
}
