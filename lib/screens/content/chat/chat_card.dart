import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/widgets/block_unblock_tile.dart';
import 'package:fakebook/widgets/delete_chat_dialog.dart';

//==== CARD DE CHAT ====
Color _getColorFromInitial(String initial) {
  final colors = {
    'A': const Color(0xFFE91E63),
    'B': const Color(0xFF9C27B0),
    'C': const Color(0xFF673AB7),
    'D': const Color(0xFF3F51B5),
    'E': const Color(0xFF2196F3),
    'F': const Color(0xFF03A9F4),
    'G': const Color(0xFF00BCD4),
    'H': const Color(0xFF009688),
    'I': const Color(0xFF4CAF50),
    'J': const Color(0xFF8BC34A),
    'K': const Color(0xFFCDDC39),
    'L': const Color(0xFFFFEB3B),
    'M': const Color(0xFFFFC107),
    'N': const Color(0xFFFF9800),
    'O': const Color(0xFFFF5722),
    'P': const Color(0xFFF44336),
    'Q': const Color(0xFFE91E63),
    'R': const Color(0xFF9C27B0),
    'S': const Color(0xFF673AB7),
    'T': const Color(0xFF3F51B5),
    'U': const Color(0xFF2196F3),
    'V': const Color(0xFF00BCD4),
    'W': const Color(0xFF009688),
    'X': const Color(0xFF4CAF50),
    'Y': const Color(0xFFFF9800),
    'Z': const Color(0xFFFF5722),
  };
  return colors[(initial.isNotEmpty ? initial[0] : 'A').toUpperCase()] ?? const Color(0xFF1976D2);
}

class ChatCard extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String avatarUrl;
  final int unreadCount;
  final bool isUnread;
  final bool isGroup;
  final VoidCallback? onTap;
  final String? conversationId;
  final bool isArchived;
  final bool isBlocked;
  final String? targetUserId;
  final Function()? onArchive;
  final Function()? onDelete;
  final Function()? onBlock;

  const ChatCard({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.avatarUrl,
    this.unreadCount = 0,
    this.isUnread = false,
    this.isGroup = false,
    this.conversationId,
    this.isArchived = false,
    this.isBlocked = false,
    this.targetUserId,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onBlock,
  });

  Future<void> _showActionMenu(BuildContext context) async {
    bool currentBlocked = isBlocked;
    if (!isGroup && targetUserId != null && targetUserId!.isNotEmpty) {
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        currentBlocked = await container.read(isUserBlockedProvider(targetUserId!).future);
      } catch (_) {
        currentBlocked = isBlocked;
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.black87),
              title: Text(isArchived ? 'Desarchivar' : 'Archivar'),
              onTap: () {
                // FUTURO METODO PARA ARCHIVAR
                Navigator.pop(sheetCtx);
                onArchive?.call();
              },
            ),
            const Divider(height: 1, thickness: 0.5),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                // FUTURO METODO PARA ELIMINAR
                Navigator.pop(sheetCtx);
                _showDeleteConfirmation(context);
              },
            ),
            const Divider(height: 1, thickness: 0.5),
            if (!isGroup)
              if (targetUserId != null && targetUserId!.isNotEmpty)
                BlockUnblockTile(
                  profileId: targetUserId!,
                  name: name,
                  isBlocked: currentBlocked,
                  parentContext: context,
                  sheetContext: sheetCtx,
                )
              else
                ListTile(
                  leading: Icon(
                    currentBlocked ? Icons.lock_open : Icons.block,
                    color: currentBlocked ? Colors.green : Colors.red,
                  ),
                  title: Text(currentBlocked ? 'Desbloquear' : 'Bloquear'),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    try {
                      // Fallback demo si no tenemos targetUserId
                      if (currentBlocked) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Conversación desbloqueada (demo)')),
                          );
                        }
                      } else {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Bloquear usuario'),
                            content: Text('¿Seguro que quieres bloquear a $name?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancelar')),
                              TextButton(
                                onPressed: () => Navigator.pop(dctx, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Bloquear'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Conversación bloqueada (demo)')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDeleteChatDialog(
      context,
      name: name,
      onConfirm: () {
        // FUTURO METODO PARA ELIMINAR
        onDelete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ConversaciOn eliminada (demo)')),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () => _showActionMenu(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E8EE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              backgroundColor: avatarUrl.isEmpty ? _getColorFromInitial(name) : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGroup) ...[
                        const Icon(Icons.group, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
