import 'package:flutter/material.dart';
import 'package:fakebook/widgets/block_unblock_tile.dart';

class GroupMemberActionsSheet extends StatelessWidget {
  const GroupMemberActionsSheet({
    super.key,
    required this.parentContext,
    required this.sheetContext,
    required this.memberName,
    required this.memberProfileId,
    required this.memberAvatarUrl,
    required this.isCurrentUserAdmin,
    required this.isBlocked,
    required this.onSendMessage,
    required this.onPromote,
    required this.onKick,
  });

  final BuildContext parentContext;
  final BuildContext sheetContext;
  final String memberName;
  final String memberProfileId;
  final String? memberAvatarUrl;
  final bool isCurrentUserAdmin;
  final bool isBlocked;
  final VoidCallback onSendMessage;
  final VoidCallback onPromote;
  final VoidCallback onKick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.message_outlined, color: Colors.black87),
            title: const Text('Enviar mensaje'),
            onTap: () {
              Navigator.pop(sheetContext);
              onSendMessage();
            },
          ),
          const Divider(height: 1),
          if (isCurrentUserAdmin) ...[
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.black87),
              title: const Text('Promover a administrador'),
              onTap: () {
                Navigator.pop(sheetContext);
                onPromote();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
              title: const Text('Expulsar del grupo'),
              onTap: () {
                Navigator.pop(sheetContext);
                onKick();
              },
            ),
            const Divider(height: 1),
          ],
          BlockUnblockTile(
            profileId: memberProfileId,
            name: memberName,
            isBlocked: isBlocked,
            parentContext: parentContext,
            sheetContext: sheetContext,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GroupActionsSheet extends StatelessWidget {
  const GroupActionsSheet({
    super.key,
    required this.sheetContext,
    required this.isCurrentUserAdmin,
    required this.onEdit,
    required this.onLeave,
    required this.onArchive,
    required this.onDelete,
  });

  final BuildContext sheetContext;
  final bool isCurrentUserAdmin;
  final VoidCallback onEdit;
  final VoidCallback onLeave;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrentUserAdmin)
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.black87),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(sheetContext);
                onEdit();
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black87),
            title: const Text('Salir del grupo'),
            onTap: () {
              Navigator.pop(sheetContext);
              onLeave();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.archive_outlined, color: Colors.black87),
            title: const Text('Archivar'),
            onTap: () {
              Navigator.pop(sheetContext);
              onArchive();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Eliminar'),
            onTap: () {
              Navigator.pop(sheetContext);
              onDelete();
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
