import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/widgets/header_content.dart';
import 'package:fakebook/screens/auth/profile_screen.dart';
import '../../providers/auth_provider.dart';
import 'package:fakebook/widgets/follow_tile.dart';

class FollowScreen extends ConsumerStatefulWidget {
  const FollowScreen({super.key});

  @override
  ConsumerState<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends ConsumerState<FollowScreen> {
  // ejemplo de como deberia recibir los datos de la gente, ademas de mandar un identificador, aunque supongo se puede hacer con el @
  // Para abrir el perfil de la persona (supongo que la app traera eso ya q hay sistema de follow/unfollow) caso contrario se quita
  // aqui el puse follow/unfollow que se maneje con true o false
  final List<_Person> _people = [
    _Person(name: 'Lionel Messi', username: '@messi', avatarUrl: null, following: true),
    _Person(name: 'Cristiano Ronaldo', username: '@cr7', avatarUrl: null, following: true),
    _Person(name: 'Neymar Jr', username: '@neymar', avatarUrl: null, following: true),
    _Person(name: 'Kylian Mbappé', username: '@mbappe', avatarUrl: null, following: true),
    _Person(name: 'Kevin De Bruyne', username: '@kdb', avatarUrl: null, following: true),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: false,
              floating: true,
              delegate: HeaderSliver(
                child: const HeaderContent(selectedTab: HeaderTab.siguiendo),
                maxHeight: 150,
                minHeight: 0,
              ),
            ),

            // personas para seguir/dejar de seguir
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final person = _people[index];
                  return FollowTile(
                    name: person.name,
                    username: person.username,
                    avatarUrl: person.avatarUrl,
                    following: person.following,
                    // aqui deberia ir a la navegacion al perfil de la persona (supongo q se hara ya que hay sistema de follow/unfollow) caso contrario simplemente se deja el seguir/dejar sin ver el perfil de la persona
                    // usando por ejemplo el @ para hacer fetch de datos o como ustedes lo hagan para el perfil
                  //////////////// Navegacion pendiente //////////////////
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Abrir perfil de ${person.username} (pendiente aun :c)'),
                        ),
                      );
                    },
                    onToggleFollow: () {
                      setState(() {
                        person.following = !person.following;
                      });
                    },
                  );
                },
                childCount: _people.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Person {
  _Person({
    required this.name,
    required this.username,
    required this.avatarUrl,
    this.following = false,
  });

  final String name;
  final String username;
  final String? avatarUrl;
  bool following;
}