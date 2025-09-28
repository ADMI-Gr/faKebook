import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/repositories/social_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/models/post_model.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import 'auth_provider.dart';

final socialRepositoryProvider = Provider((ref) => SocialRepository());

// Provider para obtener el perfil de un usuario específico por su ID
final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  return profileRepo.getProfile(userId);
});

// Provider para los seguidores de un usuario específico
final userFollowersProvider = FutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final socialRepository = ref.watch(socialRepositoryProvider);
  return socialRepository.getFollowers(userId);
});

// Provider para los seguidos de un usuario específico
final userFollowingProvider = FutureProvider.family<List<UserModel>, String>((ref, userId) async {
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
final toggleFollowProvider = FutureProvider.autoDispose.family<void, String>((ref, targetUserId) async {
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
    // Invalidamos los providers del usuario afectado para actualizar su contador de seguidores
    ref.invalidate(userFollowersProvider(targetUserId));
    // Invalidamos el provider de seguidos del usuario actual para vistas públicas
    ref.invalidate(userFollowingProvider(user.id));
});

// Provider para la acción de bloquear
final toggleBlockProvider = FutureProvider.autoDispose.family<void, String>((ref, targetUserId) async {
    final user = ref.watch(userProvider);
    if (user == null) throw Exception("Usuario no autenticado");
    final socialRepository = ref.watch(socialRepositoryProvider);

    await socialRepository.blockUser(user.id, targetUserId);
    // Al bloquear, también se deja de seguir
    ref.invalidate(followingProvider);
    ref.invalidate(followersProvider);
    ref.invalidate(userFollowersProvider(targetUserId));
    ref.invalidate(userFollowingProvider(user.id));

    ref.invalidate(blockedUsersProvider);
    // Invalidamos el estado de bloqueo para que la UI del perfil se actualice.
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
final unblockUserProvider = FutureProvider.autoDispose.family<void, String>((ref, targetUserId) async {
    final user = ref.watch(userProvider);
    if (user == null) throw Exception("Usuario no autenticado");
    final socialRepository = ref.watch(socialRepositoryProvider);

    await socialRepository.unblockUser(user.id, targetUserId);
    ref.invalidate(blockedUsersProvider);
    // Invalidamos el estado de bloqueo para que la UI del perfil se actualice.
    ref.invalidate(isUserBlockedProvider(targetUserId));
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

// Provider que combina las verificaciones de bloqueo para simplificar la UI
final combinedBlockCheckProvider = FutureProvider.family<({bool isBlockedByMe, bool amIBlocked}), String>((ref, userId) async {
  // Observamos los providers. Cuando uno se invalide, este se volverá a ejecutar.
  final isBlockedByMe = await ref.watch(isUserBlockedProvider(userId).future);
  final amIBlocked = await ref.watch(isCurrentUserBlockedByProvider(userId).future);
  
  return (
    isBlockedByMe: isBlockedByMe,
    amIBlocked: amIBlocked
  );
});

// Provider para obtener las publicaciones de un usuario específico
final userPostsProvider = FutureProvider.family<List<PostModel>, String>((ref, userId) async {
  final socialRepository = ref.watch(socialRepositoryProvider);
  final postsData = await socialRepository.getPostsForUser(userId);
  // Mapeamos los datos crudos a nuestro modelo Post
  return postsData.map((data) => PostModel.fromMap(data)).toList();
});

// Provider para obtener TODAS las publicaciones (para el dashboard) con sus autores
final allPostsProvider = FutureProvider<List<({PostModel post, UserModel author})>>((ref) async {
  final socialRepository = ref.watch(socialRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);

  //  Se podria implementar un método en SocialRepository para obtener un feed real (ej. posts de seguidos)
  // Por ahora, obtenemos todos los posts para la demostración.
  final response = await socialRepository.getAllPosts();
  final posts = response.map((data) => PostModel.fromMap(data)).toList();

  // Recopilar IDs de autores únicos
  final Set<String> authorIds = posts.map((p) => p.authorId).toSet();

  // Obtener perfiles de todos los autores
  final Map<String, UserModel> authors = {};
  for (final id in authorIds) {
    final author = await profileRepository.getProfile(id);
    if (author != null) {
      authors[id] = author;
    }
  }

  // Combinar posts con sus autores
  return posts.where((post) => authors.containsKey(post.authorId)).map((post) => (
    post: post,
    author: authors[post.authorId]!,
  )).toList();
});

// Provider para la acción de crear una publicación
final createPostProvider = FutureProvider.autoDispose.family<void, ({String content, XFile? imageFile})>((ref, postData) async {
  final user = ref.watch(userProvider);
  if (user == null) throw Exception("Usuario no autenticado para publicar.");

  final socialRepository = ref.watch(socialRepositoryProvider);
  String? imageUrl;

  // Si hay un archivo de imagen, usamos una URL de placeholder
  if (postData.imageFile != null) {
    imageUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/600';
  }

  await socialRepository.createPost(
    authorId: user.id,
    content: postData.content,
    imageUrl: imageUrl,
  );

  // ¡Paso clave! Invalidamos los providers que muestran listas de posts.
  // Esto les obliga a recargarse y mostrar la nueva publicación.
  ref.invalidate(userPostsProvider(user.id));
  ref.invalidate(allPostsProvider);
});

// Provider para la acción de actualizar una publicación
final updatePostProvider = FutureProvider.autoDispose.family<void, ({String postId, String content, XFile? imageFile})>((ref, postData) async {
  final user = ref.watch(userProvider);
  if (user == null) throw Exception("Usuario no autenticado para actualizar publicación.");

  final socialRepository = ref.watch(socialRepositoryProvider);
  String? imageUrl;

  // Si hay un archivo de imagen, usamos una URL de placeholder
  if (postData.imageFile != null) {
    imageUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/600';
  }

  await socialRepository.updatePost(
    postId: postData.postId,
    content: postData.content,
    imageUrl: imageUrl,
  );

  // Invalidamos los providers que muestran listas de posts.
  ref.invalidate(userPostsProvider(user.id));
  ref.invalidate(allPostsProvider);
});

// Provider para la acción de eliminar una publicación
final deletePostProvider = FutureProvider.autoDispose.family<void, String>((ref, postId) async {
  final user = ref.watch(userProvider);
  if (user == null) throw Exception("Usuario no autenticado para eliminar publicación.");

  final socialRepository = ref.watch(socialRepositoryProvider);
  await socialRepository.deletePost(postId);

  // Invalidamos los providers que muestran listas de posts.
  ref.invalidate(userPostsProvider(user.id));
  ref.invalidate(allPostsProvider);
});