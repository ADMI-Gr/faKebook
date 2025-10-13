import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/social_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios Bloqueados', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: blockedUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No tienes a nadie bloqueado.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null
                      ? Text((user.displayName ?? user.username)[0].toUpperCase())
                      : null,
                ),
                title: Text(user.displayName ?? user.username),
                subtitle: Text('@${user.username}'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Desbloquear usuario'),
                            content: Text('¿Quieres desbloquear a @${user.username}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Desbloquear'),
                              ),
                            ],
                          ),
                        ) ??
                        false;

                    if (confirmed) {
                      await ref.read(unblockUserProvider(user.id).future);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Has desbloqueado a @${user.username}')),
                      );
                    }
                  },
                  child: const Text('Desbloquear'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}