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
}
