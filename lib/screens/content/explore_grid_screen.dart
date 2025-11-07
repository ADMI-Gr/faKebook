import 'package:fakebook/models/post_model.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/screens/auth/profile_screen.dart';
import 'package:fakebook/screens/content/other_user_profile_screen.dart';
import 'package:fakebook/screens/content/post_detail_screen.dart';
import 'package:fakebook/widgets/follow_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// Provider para filtrar solo los posts que tienen imagen
final explorePostsProvider =
    Provider<List<({PostModel post, UserModel author})>>((ref) {
  final allPostsAsync = ref.watch(allPostsProvider);
  return allPostsAsync.when(
    data: (posts) => posts
        .where((p) =>
            p.post.contentJson['image_url'] != null &&
            p.post.contentJson['image_url'].isNotEmpty)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// PANTALLA DE EXPLORAR CON GRID
class ExploreGridScreen extends ConsumerStatefulWidget {
  const ExploreGridScreen({super.key});

  @override
  ConsumerState<ExploreGridScreen> createState() => _ExploreGridScreenState();
}

class _ExploreGridScreenState extends ConsumerState<ExploreGridScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late TabController _tabController;

  double _dragStartX = 0;
  final double _dragThreshold = 100;
  final double _edgeWidth = 15;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Forzar rebuild cuando cambie la tab para actualizar el placeholder
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final user = ref.watch(userProvider);

    return GestureDetector(
      onHorizontalDragStart: (details) {
        final screenEdge = MediaQuery.of(context).size.width;
        // Solo iniciar el drag si estamos en los bordes
        if (details.localPosition.dx <= _edgeWidth || 
            details.localPosition.dx >= screenEdge - _edgeWidth) {
          _dragStartX = details.localPosition.dx;
        }
      },
      onHorizontalDragUpdate: (details) {
        if (_dragStartX > 0) {
          final deltaX = details.localPosition.dx - _dragStartX;
          if (deltaX.abs() > _dragThreshold) {
            if (deltaX > 0 && _tabController.index > 0) {
              _tabController.animateTo(_tabController.index - 1);
            } else if (deltaX < 0 && _tabController.index < 1) {
              _tabController.animateTo(_tabController.index + 1);
            }
            _dragStartX = 0;
          }
        }
      },
      onHorizontalDragEnd: (_) => _dragStartX = 0,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 74,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              const SizedBox(width: 12),
              const Text(
                'Explorar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const Spacer(),
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.displayName?.isNotEmpty == true
                                  ? user.displayName![0].toUpperCase()
                                  : user.username[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
            ],
          ),
        ),
        body: ref.watch(allPostsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (_) {
            final postsWithImages = ref.watch(explorePostsProvider);

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Search Box
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 10.0),
                    child: _buildSearchBox(context),
                  ),
                  
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Publicaciones'),
                      Tab(text: 'Usuarios'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                  
                  // Tab Bar View
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Posts Grid Tab
                        _query.isEmpty
                          ? (postsWithImages.isEmpty
                              ? _buildEmptyState(context)
                              : SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: StaggeredGrid.count(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 2,
                                      crossAxisSpacing: 2,
                                      children: _buildPattern(context, postsWithImages),
                                    ),
                                  ),
                                ))
                          : _buildPostsGrid(postsWithImages),
                        
                        // Users List Tab
                        _buildUsersList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostsGrid(List<({PostModel post, UserModel author})> allPosts) {
    final filteredPosts = _query.isEmpty
        ? allPosts
        : allPosts.where((p) {
            final searchLower = _query.toLowerCase();
            final hasMatchingText = p.post.content?.toLowerCase().contains(searchLower) ?? false;
            final hasMatchingAuthor = p.author.username.toLowerCase().contains(searchLower) ||
                (p.author.displayName?.toLowerCase().contains(searchLower) ?? false);
            return hasMatchingText || hasMatchingAuthor;
          }).toList();

    if (filteredPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _query.isEmpty
                  ? 'No hay publicaciones para mostrar'
                  : 'No se encontraron publicaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return StaggeredGrid.count(
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: _buildPattern(context, filteredPosts),
    );
  }

  Widget _buildUsersList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        // Prevenir el deslizamiento horizontal cuando se hace scroll vertical
        if (scrollInfo.metrics.axis == Axis.vertical) {
          _dragStartX = 0;
        }
        return false;
      },
      child: FutureBuilder<List<UserModel>>(
        future: ref.read(socialRepositoryProvider).searchUsers(_query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _query.isEmpty
                        ? 'Busca usuarios por nombre o @usuario'
                        : 'No se encontraron usuarios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }

          // Filtrar usuarios bloqueados
          final currentUser = ref.read(userProvider);
          if (currentUser == null) {
            return const Center(child: Text('No estás autenticado'));
          }

          return Consumer(
            builder: (context, ref, child) {
              final followingAsync = ref.watch(followingProvider);
              final blockedUsersAsync = ref.watch(blockedUsersProvider);

              return followingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (following) {
                  return blockedUsersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    data: (blockedUsers) {
                      final blockedIds = blockedUsers.map((u) => u.id).toSet();
                      final followingIds = following.map((u) => u.id).toSet();

                      // Filtrar usuarios bloqueados
                      final filteredUsers = users.where((u) => 
                        !blockedIds.contains(u.id) && 
                        u.id != currentUser.id
                      ).toList();

                      if (filteredUsers.isEmpty) {
                        return Center(
                          child: Text(
                            'No hay usuarios disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isFollowing = followingIds.contains(user.id);
                          return _buildUserTile(user, isFollowing: isFollowing);
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserTile(UserModel user, {required bool isFollowing}) {
    final currentUser = ref.read(userProvider);
    final isCurrentUser = currentUser?.id == user.id;

    return FollowTile(
      person: user,
      isFollowing: isFollowing,
      showActions: !isCurrentUser,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherUserProfileScreen(userId: user.id),
          ),
        );
      },
      onToggleFollow: isCurrentUser
          ? null
          : () {
              // Llamada al provider para togglear follow
              ref.read(toggleFollowProvider(user.id).future);
            },
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: _tabController.index == 0 
            ? 'Buscar publicaciones...'
            : 'Buscar usuarios...',
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _query = '';
                  });
                },
              )
            : null,
      ),
      onChanged: (value) {
        setState(() => _query = value.trim());
      },
    );
  }

  // CONSTRUCCION DEL PATRON DEL GRID
  List<Widget> _buildPattern(
      BuildContext context, List<({PostModel post, UserModel author})> posts) {
    List<Widget> tiles = [];

    for (int i = 0; i < posts.length; i += 5) {
      final remaining = posts.length - i;
      final int blockIndex = (i ~/ 5);

      if (remaining >= 5) {
        if (blockIndex % 2 == 0) {
          tiles.addAll([
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 2,
              child: _buildPostCard(context, posts[i]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, posts[i + 1]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, posts[i + 2]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, posts[i + 3]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, posts[i + 4]),
            ),
          ]);
        } else {
          tiles.addAll([
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, posts[i]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, posts[i + 1]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 2,
              child: _buildPostCard(context, posts[i + 2]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, posts[i + 3]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, posts[i + 4]),
            ),
          ]);
        }
      } else {
        // SI NO HAY 5 IMAGENES PARA EL GRID SE COLOCAN NORMALES
        for (int j = i; j < posts.length; j++) {
          tiles.add(
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, posts[j]),
            ),
          );
        }
      }
    }

    return tiles;
  }

  Widget _buildPostCard(
      BuildContext context, ({PostModel post, UserModel author}) postData) {
    return _ExplorePostTile(postData: postData);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded,
                size: 56, color: Colors.grey.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text(
              'Aun no hay publicaciones para mostrar',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Vuelve mas tarde para ver las publicaciones nuevas',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorePostTile extends ConsumerWidget {
  final ({PostModel post, UserModel author}) postData;

  const _ExplorePostTile({required this.postData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userReaction = ref.watch(userReactionProvider(
        (targetType: 'post', targetId: postData.post.id)));
    final bool isLiked = userReaction.value == 'like';

    void toggleLike() {
      ref.read(toggleReactionProvider(
        (
          targetType: 'post',
          targetId: postData.post.id,
          reactionType: 'like',
        ),
      ));
    }

    return GestureDetector(
      onTap: () {
        // Mostrar imagen en pantalla completa
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (BuildContext context, _, __) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Hero(
                        tag: 'explore-image-${postData.post.id}',
                        child: Image.network(
                          postData.post.contentJson['image_url'],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      onDoubleTap: toggleLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            postData.post.contentJson['image_url'],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: Icon(Icons.broken_image, color: Colors.grey[600])),
          ),
          // Icono de "Me gusta" (esquina superior derecha)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: toggleLike,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black.withOpacity(0.4),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          // Icono para ir a la publicación (esquina inferior derecha)
          Positioned(
            bottom: 6,
            right: 6,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    post: postData.post,
                    author: postData.author,
                    isMine: ref.read(userProvider)?.id == postData.author.id,
                  ),
                ));
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black.withOpacity(0.4),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
