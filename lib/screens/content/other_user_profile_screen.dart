import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/screens/auth/profile_screen.dart';
import 'package:fakebook/screens/content/user_list_screen.dart';

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

// Provider que combina las verificaciones de bloqueo para simplificar la UI
final combinedBlockCheckProvider = FutureProvider.family<({bool isBlockedByMe, bool amIBlocked}), String>((ref, userId) async {
  // Espera a que ambos providers de bloqueo se resuelvan en paralelo
  final results = await Future.wait([
    ref.watch(isUserBlockedProvider(userId).future),
    ref.watch(isCurrentUserBlockedByProvider(userId).future),
  ]);
  return (isBlockedByMe: results[0], amIBlocked: results[1]);
});

class OtherUserProfileScreen extends ConsumerWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider);
    final userProfileAsync = ref.watch(userProfileProvider(userId));

    // Si el usuario está viendo su propio perfil, lo redirigimos a su página de perfil principal.
    if (currentUser?.id == userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return userProfileAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Usuario no encontrado')),
          );
        }

        final blockStatusAsync = ref.watch(combinedBlockCheckProvider(userId));

        return blockStatusAsync.when(
          data: (blockStatus) {
            if (blockStatus.amIBlocked) {
              // Si el usuario actual está bloqueado por el perfil que visita,
              // se muestra como "no encontrado" por motivos de privacidad.
              return Scaffold(
                appBar: AppBar(),
                body: const Center(child: Text('Usuario no encontrado')),
              );
            }

            if (blockStatus.isBlockedByMe) {
              // Si el usuario actual bloqueó a este perfil, muestra la vista de perfil bloqueado.
              return _buildBlockedProfileView(context, ref, user);
            }

            // Si no hay bloqueos, se muestra el perfil normal.
            final followersAsync = ref.watch(userFollowersProvider(userId));
            final followingAsync = ref.watch(userFollowingProvider(userId));
            final currentUserFollowingAsync = ref.watch(followingProvider);

            return Scaffold(
              backgroundColor: Colors.grey[100],
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: Text("@${user.username}"),
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    pinned: true,
                    actions: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'block') {
                            final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Bloquear usuario'),
                                    content: Text('¿Quieres bloquear a @${user.username}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                        child: const Text('Bloquear'),
                                      ),
                                    ],
                                  ),
                                ) ?? false;

                            if (confirmed) {
                              await ref.read(toggleBlockProvider(user.id).future);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Has bloqueado a @${user.username}')),
                              );
                              if (context.mounted) Navigator.of(context).pop();
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(value: 'block', child: Text('Bloquear')),
                        ],
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                            backgroundColor: const Color(0xFF1976D2),
                            child: (user.avatarUrl == null)
                                ? Text(
                                    user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : user.username[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(user.displayName ?? user.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text("@${user.username}", style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(user.bio!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 20),
                          currentUserFollowingAsync.when(
                            data: (currentUserFollowingList) {
                              final isFollowing = currentUserFollowingList.any((u) => u.id == user.id);
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: ElevatedButton(
                                  onPressed: () => ref.read(toggleFollowProvider(user.id).future),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing ? Colors.grey.shade300 : const Color(0xFF1976D2),
                                    foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                                    minimumSize: const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: Text(isFollowing ? 'Dejar de seguir' : 'Seguir', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, s) => Text('Error: $e'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn("Publicaciones", "0"),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => UserListScreen(
                                      userId: userId,
                                      listType: UserListType.followers,
                                      screenTitle: 'Seguidores',
                                    ),
                                  ));
                                },
                                child: _buildStatColumn("Seguidores", followersAsync.when(data: (list) => list.length.toString(), loading: () => '...', error: (e, s) => '-')),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => UserListScreen(
                                      userId: userId,
                                      listType: UserListType.following,
                                      screenTitle: 'Siguiendo',
                                    ),
                                  ));
                                },
                                child: _buildStatColumn("Siguiendo", followingAsync.when(data: (list) => list.length.toString(), loading: () => '...', error: (e, s) => '-')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Container(
                      height: 400,
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_camera_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("No hay publicaciones aún", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error al comprobar el estado: $e'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error al cargar el perfil: $e'))),
    );
  }

  Widget _buildBlockedProfileView(BuildContext context, WidgetRef ref, UserModel user) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("@${user.username}"),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              )
            ]
          ),
          width: double.infinity,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_flipped, color: Colors.redAccent, size: 50),
              const SizedBox(height: 16),
              Text(
                'Has bloqueado a @${user.username}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'No puedes ver su perfil ni sus publicaciones hasta que lo desbloquees.',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(unblockUserProvider(user.id).future);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Has desbloqueado a @${user.username}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Desbloquear', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}