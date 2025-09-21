import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/repositories/social_repository.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());
final socialRepositoryProvider = Provider((ref) => SocialRepository());

// Provider para obtener la lista de usuarios que el usuario actual sigue
final followingProvider = FutureProvider<List<UserModel>>((ref) async {
    final user = ref.watch(userProvider);
    if (user == null) throw Exception("Usuario no autenticado");
    final socialRepository = ref.watch(socialRepositoryProvider);
    return socialRepository.getFollowing(user.id);
});

// Provider para obtener la lista de usuarios que siguen al usuario actual
final followersProvider = FutureProvider<List<UserModel>>((ref) async {
    final user = ref.watch(userProvider);
    if (user == null) throw Exception("Usuario no autenticado");
    final socialRepository = ref.watch(socialRepositoryProvider);
    return socialRepository.getFollowers(user.id);
});

// Provider para la acción de seguir/dejar de seguir
final toggleFollowProvider = FutureProvider.family<void, String>((ref, targetUserId) async {
    final user = ref.watch(userProvider);
    if (user == null) throw Exception("Usuario no autenticado");
    final socialRepository = ref.watch(socialRepositoryProvider);
    
    // Verificamos si ya lo está siguiendo
    final followingList = await ref.read(followingProvider.future);
    final isFollowing = followingList.any((u) => u.id == targetUserId);

    if (isFollowing) {
        await socialRepository.unfollowUser(user.id, targetUserId);
    } else {
        await socialRepository.followUser(user.id, targetUserId);
    }
    // Invalidamos los providers para que se refresquen los datos
    ref.invalidate(followingProvider);
    ref.invalidate(followersProvider);
});

// Provider para la acción de bloquear
final toggleBlockProvider = FutureProvider.family<void, String>((ref, targetUserId) async {
    final user = ref.watch(userProvider);
    if (user == null) throw Exception("Usuario no autenticado");
    final socialRepository = ref.watch(socialRepositoryProvider);

    await socialRepository.blockUser(user.id, targetUserId);
    ref.invalidate(followingProvider);
    ref.invalidate(followersProvider);
    ref.invalidate(blockedUsersProvider);
});

// Provider para obtener la lista de usuarios bloqueados
final blockedUsersProvider = FutureProvider<List<UserModel>>((ref) async {
    final user = ref.watch(userProvider);
    if (user == null) throw Exception("Usuario no autenticado");
    final socialRepository = ref.watch(socialRepositoryProvider);
    return socialRepository.getBlockedUsers(user.id);
});

// Provider para la acción de desbloquear
final unblockUserProvider = FutureProvider.family<void, String>((ref, targetUserId) async {
    final user = ref.watch(userProvider);
    if (user == null) throw Exception("Usuario no autenticado");
    final socialRepository = ref.watch(socialRepositoryProvider);

    await socialRepository.unblockUser(user.id, targetUserId);
    ref.invalidate(blockedUsersProvider);
    // Invalidamos el provider de 'seguir' para este usuario específico,
    // para que un nuevo intento de seguir no use un estado de error en caché.
    ref.invalidate(toggleFollowProvider(targetUserId));
});

// Provider para verificar si un usuario específico está bloqueado por el usuario actual
final isUserBlockedProvider = FutureProvider.family<bool, String>((ref, targetUserId) async {
  final user = ref.watch(userProvider);
  if (user == null) return false;
  final socialRepository = ref.watch(socialRepositoryProvider);
  return socialRepository.isUserBlocked(user.id, targetUserId);
});

// Provider para verificar si el usuario actual ha sido bloqueado por el usuario del perfil que se está visitando
final isCurrentUserBlockedByProvider = FutureProvider.family<bool, String>((ref, profileUserId) async {
  final currentUser = ref.watch(userProvider);
  if (currentUser == null) return false;
  final socialRepository = ref.watch(socialRepositoryProvider);
  // Verifica si el dueño del perfil (profileUserId) ha bloqueado al usuario actual (currentUser.id)
  return socialRepository.isUserBlocked(profileUserId, currentUser.id);
});