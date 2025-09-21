import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/widgets/follow_tile.dart';
import 'package:fakebook/screens/content/other_user_profile_screen.dart';

enum UserListType { followers, following }

// Provider para obtener la lista de usuarios (seguidores o seguidos)
final userListProvider = FutureProvider.family<List<UserModel>, ({String userId, UserListType type})>((ref, params) {
  if (params.type == UserListType.followers) {
    // Reutilizamos el provider que ya obtiene los seguidores de un usuario específico
    return ref.watch(userFollowersProvider(params.userId).future);
  } else {
    // Reutilizamos el provider que ya obtiene los seguidos de un usuario específico
    return ref.watch(userFollowingProvider(params.userId).future);
  }
});

class UserListScreen extends ConsumerWidget {
  final String userId;
  final UserListType listType;
  final String screenTitle;

  const UserListScreen({
    super.key,
    required this.userId,
    required this.listType,
    required this.screenTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userListAsync = ref.watch(userListProvider((userId: userId, type: listType)));
    final currentUser = ref.watch(userProvider);
    // Necesitamos la lista de a quién sigue el usuario actual para saber el estado del botón
    final currentUserFollowingAsync = ref.watch(followingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: userListAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                listType == UserListType.followers
                    ? 'No hay seguidores para mostrar.'
                    : 'No sigue a nadie.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return currentUserFollowingAsync.when(
            data: (currentUserFollowing) {
              final currentUserFollowingIds = currentUserFollowing.map((e) => e.id).toSet();
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isCurrentUser = user.id == currentUser?.id;
                  final isFollowing = !isCurrentUser && currentUserFollowingIds.contains(user.id);

                  return FollowTile(
                    person: user,
                    isFollowing: isFollowing,
                    showActions: !isCurrentUser,
                    onToggleFollow: isCurrentUser ? null : () => ref.read(toggleFollowProvider(user.id).future),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar la lista: $err')),
      ),
    );
  }
}