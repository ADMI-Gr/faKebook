import 'package:fakebook/screens/auth/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_navbar.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/header_content.dart';
import 'search_screen.dart';

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
        if (ModalRoute.of(context)?.settings.name != '/dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage(), settings: const RouteSettings(name: '/dashboard')),
          );
        }
        break;
      case 1: // Pusqueda
        if (ModalRoute.of(context)?.settings.name != '/search') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen(), settings: const RouteSettings(name: '/search')),
          );
        }
        break;
      case 2: // Notificaciones
        // Aquí agregar la navegación a la pantalla de notificaciones cuando esté implementada
        break;
      case 4: // Perfil
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        );
        break;
      // Aquí se agregan lo del navbar para otros tabs
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'faKebook',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
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
                  );
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
          // Aquí puedes implementar refresh del feed
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: false,
              floating: true,
              delegate: HeaderSliver(
                child: const HeaderContent(
                  selectedTab: HeaderTab.popular,
                ),
                maxHeight: 170,
                minHeight: 0,
              ),
            ),
            // Feed de publicaciones (placeholder)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header del post
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.primaries[
                                      index % Colors.primaries.length],
                                  child: Text(
                                    'U${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Usuario ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'hace ${index + 1}h',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.more_vert),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Contenido del post
                            Text(
                              'Esta es una publicación de ejemplo #${index + 1}. '
                              'En el futuro aquí aparecerán las publicaciones reales de los usuarios.',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),

                            // Placeholder para imagen
                            if (index % 3 == 0)
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Acciones (like, comment, share)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                      Icons.thumb_up_outlined, 'Me gusta', () {})),
                                Expanded(
                                  child: _buildActionButton(Icons.chat_bubble_outline,
                                      'Comentar', () {})),
                                Expanded(
                                  child: _buildActionButton(
                                      Icons.share_outlined, 'Compartir', () {})),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: 10, // Número de posts de ejemplo
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
