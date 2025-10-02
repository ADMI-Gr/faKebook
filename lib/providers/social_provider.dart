import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/repositories/social_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/models/post_model.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'auth_provider.dart';

final socialRepositoryProvider = Provider((ref) => SocialRepository());

// Provider para obtener el perfil de un usuario específico por su ID
final userProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  return profileRepo.getProfile(userId);
});

// Provider para los seguidores de un usuario específico
final userFollowersProvider =
    FutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final socialRepository = ref.watch(socialRepositoryProvider);
  return socialRepository.getFollowers(userId);
});

// Provider para los seguidos de un usuario específico
final userFollowingProvider =
    FutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final socialRepository = ref.watch(socialRepositoryProvider);
  return socialRepository.getFollowing(userId);
});

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
final toggleFollowProvider =
    FutureProvider.autoDispose.family<void, String>((ref, targetUserId) async {
  final user = ref.watch(userProvider);
  if (user == null) throw Exception("Usuario no autenticado");
  final socialRepository = ref.watch(socialRepositoryProvider);

  final followingList = await ref.read(followingProvider.future);
  final isFollowing = followingList.any((u) => u.id == targetUserId);

  if (isFollowing) {
    await socialRepository.unfollowUser(user.id, targetUserId);
  } else {
    await socialRepository.followUser(user.id, targetUserId);
  }
  ref.invalidate(followingProvider);
  ref.invalidate(followersProvider);
  ref.invalidate(userFollowersProvider(targetUserId));
  ref.invalidate(userFollowingProvider(user.id));
});

// Provider para la acción de bloquear
final toggleBlockProvider =
    FutureProvider.autoDispose.family<void, String>((ref, targetUserId) async {
  final user = ref.watch(userProvider);
  if (user == null) throw Exception("Usuario no autenticado");
  final socialRepository = ref.watch(socialRepositoryProvider);

  await socialRepository.blockUser(user.id, targetUserId);
  ref.invalidate(followingProvider);
  ref.invalidate(followersProvider);
  ref.invalidate(userFollowersProvider(targetUserId));
  ref.invalidate(userFollowingProvider(user.id));
  ref.invalidate(blockedUsersProvider);
  ref.invalidate(isUserBlockedProvider(targetUserId));
});

// Provider para obtener la lista de usuarios bloqueados
final blockedUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) throw Exception("Usuario no autenticado");
  final socialRepository = ref.watch(socialRepositoryProvider);
  return socialRepository.getBlockedUsers(user.id);
});

// Provider para la acción de desbloquear
final unblockUserProvider =
    FutureProvider.autoDispose.family<void, String>((ref, targetUserId) async {
  final user = ref.watch(userProvider);
  if (user == null) throw Exception("Usuario no autenticado");
  final socialRepository = ref.watch(socialRepositoryProvider);

  await socialRepository.unblockUser(user.id, targetUserId);
  ref.invalidate(blockedUsersProvider);
  ref.invalidate(isUserBlockedProvider(targetUserId));
});

// Provider para verificar si un usuario específico está bloqueado por el usuario actual
final isUserBlockedProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  final user = ref.watch(userProvider);
  if (user == null) return false;
  final socialRepository = ref.watch(socialRepositoryProvider);
  return socialRepository.isUserBlocked(user.id, targetUserId);
});

// Provider para verificar si el usuario actual ha sido bloqueado por el usuario del perfil que se está visitando
final isCurrentUserBlockedByProvider =
    FutureProvider.family<bool, String>((ref, profileUserId) async {
  final currentUser = ref.watch(userProvider);
  if (currentUser == null) return false;
  final socialRepository = ref.watch(socialRepositoryProvider);
  return socialRepository.isUserBlocked(profileUserId, currentUser.id);
});

// Provider que combina las verificaciones de bloqueo para simplificar la UI
final combinedBlockCheckProvider =
    FutureProvider.family<({bool isBlockedByMe, bool amIBlocked}), String>(
        (ref, userId) async {
  final isBlockedByMe = await ref.watch(isUserBlockedProvider(userId).future);
  final amIBlocked =
      await ref.watch(isCurrentUserBlockedByProvider(userId).future);

  return (isBlockedByMe: isBlockedByMe, amIBlocked: amIBlocked);
});

// Provider para obtener las publicaciones de un usuario específico
final userPostsProvider =
    FutureProvider.family<List<PostModel>, String>((ref, userId) async {
  final socialRepository = ref.watch(socialRepositoryProvider);
  final postsData = await socialRepository.getPostsForUser(userId);
  return postsData.map((data) => PostModel.fromMap(data)).toList();
});

// Provider para obtener TODAS las publicaciones (para el dashboard) con sus autores
final allPostsProvider =
    FutureProvider<List<({PostModel post, UserModel author})>>((ref) async {
  final socialRepository = ref.watch(socialRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);

  final response = await socialRepository.getAllPosts();
  final posts = response.map((data) => PostModel.fromMap(data)).toList();

  final Set<String> authorIds = posts.map((p) => p.authorId).toSet();

  final Map<String, UserModel> authors = {};
  for (final id in authorIds) {
    final author = await profileRepository.getProfile(id);
    if (author != null) {
      authors[id] = author;
    }
  }

  return posts
      .where((post) => authors.containsKey(post.authorId))
      .map((post) => (
            post: post,
            author: authors[post.authorId]!,
          ))
      .toList();
});

// Provider para la acción de crear una publicación
final createPostProvider = FutureProvider.autoDispose
    .family<void, ({String content, XFile? imageFile})>((ref, postData) async {
  final user = ref.watch(userProvider);
  if (user == null) throw Exception("Usuario no autenticado para publicar.");

  final socialRepository = ref.watch(socialRepositoryProvider);
  String? imageUrl;

  // CORREGIDO: Subir imagen real a Supabase Storage
  if (postData.imageFile != null) {
    try {
      final file = File(postData.imageFile!.path);
      final fileExt = path.extension(postData.imageFile!.path);
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'posts/$fileName';

      // Subir a Supabase Storage
      imageUrl = await socialRepository.uploadImage(file, filePath);
    } catch (e) {
      print('Error al subir imagen: $e');
      // Si falla la subida, continuamos sin imagen
      imageUrl = null;
    }
  }

  await socialRepository.createPost(
    authorId: user.id,
    content: postData.content,
    imageUrl: imageUrl,
  );

  ref.invalidate(userPostsProvider(user.id));
  ref.invalidate(allPostsProvider);
});

// Provider para la acción de actualizar una publicación
final updatePostProvider = FutureProvider.autoDispose.family<
    void,
    ({
      String postId,
      String content,
      XFile? imageFile,
      bool shouldDeleteExistingImage,
      String? existingImageUrl,
    })>((ref, postData) async {
  final user = ref.watch(userProvider);
  if (user == null)
    throw Exception("Usuario no autenticado para actualizar publicación.");

  final socialRepository = ref.watch(socialRepositoryProvider);
  String? imageUrl;

  // Si se debe eliminar la imagen existente
  if (postData.shouldDeleteExistingImage && postData.existingImageUrl != null) {
    try {
      await socialRepository.deleteImage(postData.existingImageUrl!);
    } catch (e) {
      print('Error al eliminar imagen existente: $e');
    }
  }

  // Si hay una nueva imagen para subir
  if (postData.imageFile != null) {
    try {
      final file = File(postData.imageFile!.path);
      final fileExt = path.extension(postData.imageFile!.path);
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'posts/$fileName';

      // Subir a Supabase Storage
      imageUrl = await socialRepository.uploadImage(file, filePath);
    } catch (e) {
      print('Error al subir imagen: $e');
      imageUrl = null;
    }
  } else if (!postData.shouldDeleteExistingImage) {
    // Si no hay nueva imagen y no se eliminó la existente, mantener la URL actual
    imageUrl = postData.existingImageUrl;
  }

  await socialRepository.updatePost(
    postId: postData.postId,
    content: postData.content,
    imageUrl: imageUrl,
  );

  ref.invalidate(userPostsProvider(user.id));
  ref.invalidate(allPostsProvider);
});

// Provider para la acción de eliminar una publicación
final deletePostProvider =
    FutureProvider.autoDispose.family<void, String>((ref, postId) async {
  final user = ref.watch(userProvider);
  if (user == null)
    throw Exception("Usuario no autenticado para eliminar publicación.");

  final socialRepository = ref.watch(socialRepositoryProvider);
  await socialRepository.deletePost(postId);

  ref.invalidate(userPostsProvider(user.id));
  ref.invalidate(allPostsProvider);
});
