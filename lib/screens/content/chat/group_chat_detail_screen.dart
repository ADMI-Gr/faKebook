import 'package:fakebook/screens/content/chat/create_group_screen.dart';
import 'package:fakebook/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/chat_providers.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import '../../../widgets/expandable_text.dart';
import 'group_chat_profile_view_screen.dart';
import 'select_group_members_screen.dart';

//=== PANTALLA DE CHAT DE GRUPO
class GroupChatDetailScreen extends ConsumerStatefulWidget {
  const GroupChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.title,
    required this.avatarUrl,
  });

  final String conversationId;
  final String title;
  final String avatarUrl;

  @override
  ConsumerState<GroupChatDetailScreen> createState() =>
      _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends ConsumerState<GroupChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();

    // Cancelar notificación al abrir el chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().cancelNotification(widget.conversationId);

      // Marcar como leída en el provider global
      final currentUser = ref.read(userProvider);
      if (currentUser != null) {
        ref
            .read(realtimeConversationsProvider(currentUser.id).notifier)
            .markAsRead(widget.conversationId);
      }
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Auto scroll al final cuando llega un mensaje nuevo
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showGroupActionMenu(BuildContext context) async {
    bool isAdmin = false;
    try {
      final me = ref.read(userProvider);
      if (me != null) {
        // Revisa metadata['admins']
        final conversations =
            await ref.read(userConversationsProvider(me.id).future);
        final convo = conversations.firstWhere(
            (c) => c.id == widget.conversationId,
            orElse: () => conversations.first);
        final md = convo.metadata;
        final rawAdmins = md['admins'];
        if (rawAdmins is List &&
            rawAdmins.map((e) => e.toString()).contains(me.id)) {
          isAdmin = true;
        } else {
          // Revisa rol en participants
          final parts = await ref
              .read(participantsProvider(widget.conversationId).future);
          final mine = parts.firstWhere((p) => p.profileId == me.id,
              orElse: () => parts.first);
          final roleLower = mine.role?.toLowerCase();
          if (roleLower == 'admin' ||
              roleLower == 'administrator' ||
              roleLower == 'owner' ||
              roleLower == 'creator') {
            isAdmin = true;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
  }

  // Confirmar salir del grupo
  void _showLeaveGroupConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: const Text('¿Seguro que quieres salir de este grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dctx);
              await _leaveGroup();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  // Salir del grupo
  Future<void> _leaveGroup() async {
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    try {
      // Llamar al provider para salir del grupo
      ref.read(leaveConversationProvider.notifier).leave(
            conversationId: widget.conversationId,
            profileId: currentUser.id,
          );

      if (mounted) {
        // Refrescar la lista de conversaciones
        ref.invalidate(userConversationsProvider(currentUser.id));

        // Volver a la pantalla anterior
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has salido del grupo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al salir del grupo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Confirmar eliminar grupo
  void _showDeleteGroupConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Borrar Conversación'),
        content: const Text(
            '¿Seguro que quieres BORRAR la conversacion? Esta acción no se puede deshacer y eliminará todos los mensajes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dctx);
              _deleteGroup();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  // Eliminar grupo
  Future<void> _deleteGroup() async {
    print('Ingresando a deleteGroup');
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    try {
      print('Llamando a deleteConversationProvider');
      // Llamar al provider para eliminar el grupo
      ref.read(deleteConversationProvider.notifier).delete(
            conversationId: widget.conversationId,
            profileId: currentUser.id,
          );
      print('Después de llamar a deleteConversationProvider');
      if (mounted) {
        // Refrescar la lista de conversaciones
        ref.invalidate(userConversationsProvider(currentUser.id));

        // Volver a la pantalla anterior
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversación borrada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al borrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _colorFromInitial(String initial) {
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
    final key = (initial.isNotEmpty ? initial[0] : 'A').toUpperCase();
    return colors[key] ?? const Color(0xFF1976D2);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () async {
            try {
              final parts = await ref
                  .read(participantsProvider(widget.conversationId).future);
              final me = ref.read(userProvider);
              List<String> adminIds = const [];
              String description = '';
              if (me != null) {
                final conversations =
                    await ref.read(userConversationsProvider(me.id).future);
                final convo = conversations.firstWhere(
                    (c) => c.id == widget.conversationId,
                    orElse: () => conversations.first);
                final md = convo.metadata;
                final rawAdmins = md['admins'];
                if (rawAdmins is List) {
                  adminIds = rawAdmins.map((e) => e.toString()).toList();
                }
                if (md['description'] != null) {
                  description = md['description'].toString();
                }
              }
              final List<GroupMember> members = [];
              for (final p in parts) {
                final prof = await ProfileRepository().getProfile(p.profileId);
                final name = prof?.displayName ?? prof?.username ?? 'Usuario';
                final avatar = prof?.avatarUrl ?? '';
                final roleLower = p.role?.toLowerCase();
                final isAdmin = adminIds.contains(p.profileId) ||
                    roleLower == 'admin' ||
                    roleLower == 'administrator' ||
                    roleLower == 'owner' ||
                    roleLower == 'creator';
                members.add(GroupMember(
                    profileId: p.profileId,
                    name: name,
                    avatarUrl: avatar,
                    isAdmin: isAdmin));
              }
              bool isCurrentUserAdmin = false;
              if (me != null) {
                final mine = parts.where((p) => p.profileId == me.id).toList();
                final roleLower =
                    mine.isNotEmpty ? mine.first.role?.toLowerCase() : null;
                isCurrentUserAdmin = adminIds.contains(me.id) ||
                    roleLower == 'admin' ||
                    roleLower == 'administrator' ||
                    roleLower == 'owner' ||
                    roleLower == 'creator';
              }
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupChatProfileViewScreen(
                    conversationId: widget.conversationId, // Solo pasa el ID
                  ),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('No se pudo abrir el perfil del grupo: $e')),
              );
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.avatarUrl.isNotEmpty
                    ? NetworkImage(widget.avatarUrl)
                    : null,
                backgroundColor: widget.avatarUrl.isEmpty
                    ? _colorFromInitial(widget.title)
                    : null,
                child: widget.avatarUrl.isEmpty
                    ? Text(
                        widget.title.isNotEmpty
                            ? widget.title[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: Colors.black12),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  // ⭐ USAR REALTIME MESSAGES PROVIDER
                  final messages = ref
                      .watch(realtimeMessagesProvider(widget.conversationId));

                  // Auto-scroll cuando llegan mensajes nuevos
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  if (messages.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_outlined,
                                size: 64, color: Colors.black38),
                            SizedBox(height: 12),
                            Text(
                              'Inicia la conversación',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Sé el primero en enviar un mensaje al grupo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final List<Widget> children = [];

                  for (final m in messages) {
                    final isMeMsg = m.senderId == me?.id;

                    if (!isMeMsg) {
                      // Mensaje de otro usuario
                      children.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder(
                                future:
                                    ProfileRepository().getProfile(m.senderId),
                                builder: (context, snap) {
                                  final senderName = snap.data?.displayName ??
                                      snap.data?.username ??
                                      'Usuario';
                                  final senderAvatar =
                                      snap.data?.avatarUrl ?? '';
                                  return CircleAvatar(
                                    radius: 16,
                                    backgroundImage: senderAvatar.isNotEmpty
                                        ? NetworkImage(senderAvatar)
                                        : null,
                                    backgroundColor: senderAvatar.isEmpty
                                        ? _colorFromInitial(senderName)
                                        : null,
                                    child: senderAvatar.isEmpty
                                        ? Text(
                                            senderName[0].toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          )
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder(
                                      future: ProfileRepository()
                                          .getProfile(m.senderId),
                                      builder: (context, snap) {
                                        final senderName =
                                            snap.data?.displayName ??
                                                snap.data?.username ??
                                                'Usuario';
                                        return Text(
                                          senderName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFE6E8EE)),
                                      ),
                                      child: ExpandableText(
                                          text: m.body ?? '', trimLength: 160),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_formatTime(m.createdAt),
                                        style: const TextStyle(
                                            color: Colors.black45,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Mi mensaje
                      children.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD8FDD2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ExpandableText(
                                      text: m.body ?? '', trimLength: 160),
                                ),
                                const SizedBox(height: 4),
                                Text(_formatTime(m.createdAt),
                                    style: const TextStyle(
                                        color: Colors.black45, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  return ListView(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    children: children,
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6E8EE)),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Escribir mensaje',
                          hintStyle: TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: () async {
                      final txt = _controller.text.trim();
                      if (txt.isEmpty) return;
                      if (me == null) return;
                      if (_sending) return;

                      try {
                        _sending = true;

                        // Enviar mensaje
                        ref.read(sendMessageProvider.notifier).send(
                              conversationId: widget.conversationId,
                              senderId: me.id,
                              body: txt,
                            );

                        _controller.clear();

                        // NO es necesario invalidar porque el realtime provider
                        // actualizará automáticamente los mensajes

                        // Refrescar lista de conversaciones del usuario
                        ref.invalidate(userConversationsProvider(me.id));

                        // Auto-scroll después de enviar
                        _scrollToBottom();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al enviar: $e')),
                          );
                        }
                      } finally {
                        _sending = false;
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
