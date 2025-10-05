import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/screens/auth/profile_screen.dart';
import 'package:fakebook/screens/content/user_list_screen.dart';
import 'package:fakebook/screens/content/image_viewer_screen.dart';

import 'package:fakebook/widgets/post_card.dart';

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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error al cargar el Perfil: $e'))),
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
              // se muestra una vista que indica que el acceso está restringido.
              return _buildBeenBlockedView(context, user);
            }

            if (blockStatus.isBlockedByMe) {
              // Si el usuario actual bloqueó a este perfil, muestra la vista de perfil bloqueado.
              return _buildBlockedProfileView(context, ref, user);
            }

            // Si no hay bloqueos, se muestra el perfil normal.
            final followersAsync = ref.watch(userFollowersProvider(userId));
            final followingAsync = ref.watch(userFollowingProvider(userId));
            final currentUserFollowingAsync = ref.watch(followingProvider);
            final userPostsAsync = ref.watch(userPostsProvider(userId));

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
                                    content: Text(
                                        '¿Quieres bloquear a @${user.username}?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancelar')),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white),
                                        child: const Text('Bloquear'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;

                            if (confirmed) {
                              await ref
                                  .read(toggleBlockProvider(user.id).future);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Has bloqueado a @${user.username}')),
                              );
                              if (context.mounted) Navigator.of(context).pop();
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                              value: 'block', child: Text('Bloquear')),
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
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              final url = user.avatarUrl;
                              if (url != null && url.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder: (_, __, ___) => ImageViewerScreen(
                                      imageUrl: url,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Este usuario no tiene foto de perfil.'),
                                  ),
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              backgroundColor: const Color(0xFF1976D2),
                              child: (user.avatarUrl == null)
                                  ? Text(
                                      user.displayName?.isNotEmpty == true
                                          ? user.displayName![0].toUpperCase()
                                          : user.username[0].toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(user.displayName ?? user.username,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          Text("@${user.username}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500)),
                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(user.bio!,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 20),
                          currentUserFollowingAsync.when(
                            data: (currentUserFollowingList) {
                              final isFollowing = currentUserFollowingList
                                  .any((u) => u.id == user.id);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: ElevatedButton(
                                  onPressed: () => ref.read(
                                      toggleFollowProvider(user.id).future),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing
                                        ? Colors.grey.shade300
                                        : const Color(0xFF1976D2),
                                    foregroundColor: isFollowing
                                        ? Colors.black87
                                        : Colors.white,
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                      isFollowing
                                          ? 'Dejar de seguir'
                                          : 'Seguir',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, s) => Text('Error: $e'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(
                                  "Publicaciones",
                                  userPostsAsync.when(
                                      data: (posts) => posts.length.toString(),
                                      loading: () => '...',
                                      error: (e, s) => '-')),
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
                                child: _buildStatColumn(
                                    "Seguidores",
                                    followersAsync.when(
                                        data: (list) => list.length.toString(),
                                        loading: () => '...',
                                        error: (e, s) => '-')),
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
                                child: _buildStatColumn(
                                    "Siguiendo",
                                    followingAsync.when(
                                        data: (list) => list.length.toString(),
                                        loading: () => '...',
                                        error: (e, s) => '-')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  userPostsAsync.when(
                    loading: () => const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, s) => SliverToBoxAdapter(
                        child: Center(child: Text('Error al cargar posts: $e'))),
                    data: (posts) {
                      if (posts.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 48, horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_camera_outlined,
                                    size: 64, color: Colors.grey[500]),
                                const SizedBox(height: 16),
                                Text(
                                  'Este usuario aún no tiene publicaciones',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cuando publique algo, lo verás aquí.',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final postItems = posts.map((post) => (
                            post: post,
                            author: user,
                            isMine: currentUser?.id == post.authorId,
                          )).toList();
                      return PostList(
                        posts: postItems,
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => Scaffold(
              appBar: AppBar(),
              body: Center(child: Text('Error al cargar el Perfil: $e'))),
        );
      },
    );
  }

  Widget _buildBlockedProfileView(
      BuildContext context, WidgetRef ref, UserModel user) {
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
              ]),
          width: double.infinity,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_flipped,
                  color: Colors.redAccent, size: 50),
              const SizedBox(height: 16),
              Text(
                'Has bloqueado a @${user.username}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    SnackBar(
                        content: Text('Has desbloqueado a @${user.username}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Desbloquear',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeenBlockedView(BuildContext context, UserModel user) {
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
              ]),
          width: double.infinity,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: Colors.grey, size: 50),
              const SizedBox(height: 16),
              const Text(
                'No puedes ver este perfil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'El acceso a este perfil ha sido restringido.',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                textAlign: TextAlign.center,
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
        Text(count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
