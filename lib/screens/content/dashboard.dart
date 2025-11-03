import 'package:fakebook/screens/auth/profile_screen.dart';
import 'package:fakebook/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_navbar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import '../../widgets/header_content.dart';
import 'search_screen.dart';
import 'chat/chat_screen.dart';
import 'package:fakebook/screens/content/explore_grid_screen.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navegación basada en el índice
    switch (index) {
      case 0: // Home
        print('Navegando a DashboardPage');
        if (ModalRoute.of(context)?.settings.name != '/dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const DashboardPage(),
                settings: const RouteSettings(name: '/dashboard')),
          );
        }
        break;
      case 1: // Pusqueda
        if (ModalRoute.of(context)?.settings.name != '/explore') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ExploreGridScreen(),
                settings: const RouteSettings(name: '/explore')),
          ).then((_) {
            if (!mounted) return;
            setState(() {
              _selectedIndex = 0;
            });
          });
        }
        break;
      case 3: // Chats
        print('Navegando a ChatScreen');
        if (ModalRoute.of(context)?.settings.name != '/chat') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ChatScreen(),
                settings: const RouteSettings(name: '/chat')),
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
      // Aquí se agregan lo del navbar para otros tabs
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    final allPostsAsync = ref.watch(allPostsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          user?.email?.endsWith('@itca.edu.sv') == true
              ? 'ITCAbook'
              : 'faKebook',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Avatar pequeño en la barra superior
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ).then((_) {
                    if (!mounted) return;
                    setState(() {
                      _selectedIndex = 0;
                    });
                  });
                },
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
      body: RefreshIndicator(
        onRefresh: () async {
          // AQUI SE DEBERIA LLAMAR AL PROVIDER DE POSTS PARA QUE SE REFRESCEN LOS POSTS
          ref.invalidate(allPostsProvider);
        },
        child: allPostsAsync.when(
          loading: () => CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: false,
                floating: true,
                delegate: HeaderSliver(
                  maxHeight: 170,
                  minHeight: 0,
                  child: const HeaderContent(
                    selectedTab: HeaderTab.nuevo,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (err, stack) => CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: false,
                floating: true,
                delegate: HeaderSliver(
                  maxHeight: 170,
                  minHeight: 0,
                  child: const HeaderContent(
                    selectedTab: HeaderTab.nuevo,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child:
                      Center(child: Text("Error al cargar los posts: $err"))),
            ],
          ),
          data: (postsWithAuthors) {
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
                    maxHeight: 170,
                    minHeight: 0,
                    child: const HeaderContent(
                      selectedTab: HeaderTab.nuevo,
                    ),
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
