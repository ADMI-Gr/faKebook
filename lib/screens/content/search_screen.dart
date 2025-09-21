import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/widgets/follow_tile.dart';
import 'package:fakebook/providers/auth_provider.dart';

// Provider para mantener el texto de búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider que ejecuta la búsqueda de usuarios
final searchUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) {
    return [];
  }
  final socialRepository = ref.watch(socialRepositoryProvider);
  return await socialRepository.searchUsers(query);
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResult = ref.watch(searchUsersProvider);
    final currentUser = ref.watch(userProvider);
    // Observamos la lista de personas que el usuario actual sigue para saber el estado del botón
    final followingListAsync = ref.watch(followingProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar usuarios...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: searchResult.when(
        data: (users) {
          if (ref.watch(searchQueryProvider).trim().isEmpty) {
            return const Center(child: Text('Ingresa un término de búsqueda.'));
          }

          if (users.isEmpty) {
            return const Center(child: Text('No se encontraron usuarios.'));
          }

          return followingListAsync.when(
            data: (followingList) {
              final followingIds = followingList.map((e) => e.id).toSet();
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isCurrentUser = user.id == currentUser?.id;
                  final isFollowing = !isCurrentUser && followingIds.contains(user.id);
                  return FollowTile(
                    person: user,
                    isFollowing: isFollowing,
                    showActions: !isCurrentUser,
                    onToggleFollow: isCurrentUser ? null : () {
                      ref.read(toggleFollowProvider(user.id).future);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al buscar: $err')),
      ),
    );
  }
}