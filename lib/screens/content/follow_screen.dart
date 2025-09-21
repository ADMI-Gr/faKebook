import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/widgets/header_content.dart';
import 'package:fakebook/screens/auth/profile_screen.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import 'package:fakebook/widgets/follow_tile.dart';
import 'search_screen.dart';

class FollowScreen extends ConsumerWidget {
  const FollowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: const HeaderContent(
                  selectedTab: HeaderTab.siguiendo,
                ),
                maxHeight: 170,
                minHeight: 0,
              ),
            ),

            // personas para seguir/dejar de seguir
            Consumer(builder: (context, ref, _) {
              final followingAsync = ref.watch(followingProvider);
              return followingAsync.when(
                data: (people) {
                  if (people.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: Text(
                            'No sigues a nadie todavía.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final person = people[index];
                        return FollowTile(
                          person: person,
                          isFollowing: true, // Todos en esta lista son seguidos
                          onToggleFollow: () {
                            ref.read(toggleFollowProvider(person.id).future);
                          },
                        );
                      },
                      childCount: people.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ))),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $err')),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}