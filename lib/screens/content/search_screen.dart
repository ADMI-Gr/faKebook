import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/widgets/follow_tile.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/widgets/custom_navbar.dart';
import 'package:fakebook/screens/content/dashboard.dart';
import 'package:fakebook/screens/auth/profile_screen.dart';
import 'package:fakebook/screens/content/chat/chat_screen.dart';

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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  int _selectedIndex = 1; // Búsqueda está en index 1

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        if (ModalRoute.of(context)?.settings.name != '/dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardPage(),
              settings: const RouteSettings(name: '/dashboard'),
            ),
          );
        }
        break;
      case 1: // Búsqueda (ya estamos aquí)
        break;
      case 3: // Chats
        if (ModalRoute.of(context)?.settings.name != '/chat') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ChatScreen(),
              settings: const RouteSettings(name: '/chat'),
            ),
          );
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
            _selectedIndex = 1;
          });
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResult = ref.watch(searchUsersProvider);
    final currentUser = ref.watch(userProvider);
    final followingListAsync = ref.watch(followingProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.search,
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Buscar usuarios...',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            fillColor: Colors.transparent,
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        // iconTheme: const IconThemeData(color: Colors.white),
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
                  final isFollowing =
                      !isCurrentUser && followingIds.contains(user.id);
                  return FollowTile(
                    person: user,
                    isFollowing: isFollowing,
                    showActions: !isCurrentUser,
                    onToggleFollow: isCurrentUser
                        ? null
                        : () {
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
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
