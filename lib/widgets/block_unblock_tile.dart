import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/social_provider.dart';

//==== Tile para bloquear/desbloquear usuario ====s
class BlockUnblockTile extends ConsumerWidget {
  const BlockUnblockTile({
    super.key,
    required this.profileId,
    required this.name,
    required this.isBlocked,
    required this.parentContext,
    required this.sheetContext,
  });

  final String profileId;
  final String name;
  final bool isBlocked;
  final BuildContext parentContext;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        isBlocked ? Icons.lock_open : Icons.block,
        color: isBlocked ? Colors.green : Colors.red,
      ),
      title: Text(isBlocked ? 'Desbloquear' : 'Bloquear'),
      onTap: () async {
        final container = ProviderScope.containerOf(parentContext, listen: false);
        Navigator.pop(sheetContext);
        try {
          if (isBlocked) {
            await container.read(unblockUserProvider(profileId).future);
            if (parentContext.mounted) {
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(content: Text('Has desbloqueado a $name')),
              );
            }
          } else {
            final confirmed = await showDialog<bool>(
              context: parentContext,
              builder: (dctx) => AlertDialog(
                title: const Text('Bloquear usuario'),
                content: Text('¿Seguro que quieres bloquear a $name?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dctx, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Bloquear'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await container.read(toggleBlockProvider(profileId).future);
              if (parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('Has bloqueado a $name')),
                );
              }
            }
          }
        } catch (e) {
          if (parentContext.mounted) {
            print(e);
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      },
    );
  }
}
