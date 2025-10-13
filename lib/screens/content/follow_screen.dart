import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/widgets/header_content.dart';
import 'package:fakebook/screens/auth/profile_screen.dart';
import 'package:fakebook/widgets/post_card.dart';
import 'package:fakebook/widgets/custom_navbar.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import 'search_screen.dart';
import 'chat/chat_screen.dart';

class FollowScreen extends ConsumerStatefulWidget {
  const FollowScreen({super.key});

  @override
  ConsumerState<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends ConsumerState<FollowScreen> {
  int _selectedIndex = 0; 

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navegación basada en el índice
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1: // Búsqueda
        if (ModalRoute.of(context)?.settings.name != '/search') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SearchScreen(),
              settings: const RouteSettings(name: '/search'),
            ),
          ).then((_) {
            if (!mounted) return;
            setState(() {
              _selectedIndex = 3;
            });
          });
        }
        break;
      case 2: // Notificaciones
        // Aquí agregar la navegación a la pantalla de notificaciones cuando esté implementada
        break;
      case 3: // Chats
        if (ModalRoute.of(context)?.settings.name != '/chat') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChatScreen(),
              settings: const RouteSettings(name: '/chat'),
            ),
          ).then((_) {
            if (!mounted) return;
            setState(() {
              _selectedIndex = 0;
            });
          });
        }
        break;
      case 4: // Perfil
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        ).then((_) {
          if (!mounted) return;
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final followingPostsAsync = ref.watch(followingPostsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
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
              'faKebook',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Input de busqueda entre el logo y el avatar
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          // FUTURO METODO PARA EL INPUT ¿?
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ).then((_) {
                    if (!mounted) return;
                    setState(() {
                      _selectedIndex = 3;
                    });
                  });
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  backgroundColor: Colors.white.withOpacity(0.3),
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
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(followingPostsProvider);
        },
        child: followingPostsAsync.when(
          loading: () => CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: false,
                floating: true,
                delegate: HeaderSliver(
                  child: const HeaderContent(
                    selectedTab: HeaderTab.siguiendo,
                  ),
                  maxHeight: 170,
                  minHeight: 0,
                ),
              ),
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          ),
          error: (err, stack) => CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: false,
                floating: true,
                delegate: HeaderSliver(
                  child: const HeaderContent(
                    selectedTab: HeaderTab.siguiendo,
                  ),
                  maxHeight: 170,
                  minHeight: 0,
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      'Error al cargar las publicaciones: $err',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          data: (postsWithAuthors) {
            if (postsWithAuthors.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: false,
                    floating: true,
                    delegate: HeaderSliver(
                      child: const HeaderContent(
                        selectedTab: HeaderTab.siguiendo,
                      ),
                      maxHeight: 170,
                      minHeight: 0,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay publicaciones',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Las personas que sigues aún no han publicado nada.\n¡Busca más personas para seguir!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final postItems = postsWithAuthors.map((data) {
              final post = data.post;
              final author = data.author;
              final isMine = user?.id == post.authorId;
              return (post: post, author: author, isMine: isMine);
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: false,
                  floating: true,
                  delegate: HeaderSliver(
                    child: const HeaderContent(
                      selectedTab: HeaderTab.siguiendo,
                    ),
                    maxHeight: 170,
                    minHeight: 0,
                  ),
                ),
                PostList(posts: postItems),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
