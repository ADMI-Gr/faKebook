import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../screens/content/other_user_profile_screen.dart';
import '../providers/social_provider.dart';

////// TARJETA DE FOLLOW/UNFOLLOW
class FollowTile extends ConsumerWidget {
  const FollowTile({
    super.key,
    required this.person,
    this.isFollowing = false,
    this.onToggleFollow,
    this.onTap,
    this.showActions = true,
  });

  final UserModel person;
  final bool isFollowing;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFollow;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryBlue = Color(0xFF1976D2);

    final isBlockedAsync = ref.watch(isUserBlockedProvider(person.id));

    return InkWell(
      onTap: onTap ??
          () {
            // Navegar al perfil del usuario
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OtherUserProfileScreen(userId: person.id)),
            );
          },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryBlue,
              backgroundImage:
                  person.avatarUrl != null ? NetworkImage(person.avatarUrl!) : null,
              child: person.avatarUrl == null
                  ? Text(
                      (person.displayName ?? person.username).isNotEmpty
                          ? (person.displayName ?? person.username)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.displayName ?? person.username,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${person.username}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (showActions) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Theme.of(context).colorScheme.primary,
                  foregroundColor: isFollowing ? Colors.black : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onToggleFollow,
                child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
              ),
              const SizedBox(width: 8),

              // MENU PARA BLOQUEAR/DESBLOQUEAR AL USUARIO
              isBlockedAsync.when(
                data: (isBlocked) => PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'block') {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Bloquear usuario'),
                              content: Text('¿Quieres bloquear a @${person.username}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                  ),
                                  child: const Text('Bloquear'),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (confirmed) {
                        await ref.read(toggleBlockProvider(person.id).future);
                        ref.invalidate(isUserBlockedProvider(person.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Has bloqueado a @${person.username}')),
                        );
                      }
                    } else if (value == 'unblock') {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Desbloquear usuario'),
                              content: Text('¿Quieres desbloquear a @${person.username}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                  ),
                                  child: const Text('Desbloquear'),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (confirmed) {
                        await ref.read(unblockUserProvider(person.id).future);
                        ref.invalidate(isUserBlockedProvider(person.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Has desbloqueado a @${person.username}')),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isBlocked)
                      const PopupMenuItem<String>(
                        value: 'block',
                        child: Text('Bloquear'),
                      )
                    else
                      const PopupMenuItem<String>(
                        value: 'unblock',
                        child: Text('Desbloquear'),
                      ),
                  ],
                ),
                loading: () => const SizedBox(width: 32, height: 32),
                error: (err, stack) => const SizedBox(width: 32, height: 32),
              ),
            ]
          ],
        ),
      ),
    );
  }
}