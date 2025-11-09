import 'dart:io';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/chat_providers.dart';
import 'package:fakebook/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/utils/file_download_helper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import '../image_viewer_screen.dart';
import 'user_chat_profile_view_screen.dart';
import '../../../widgets/expandable_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/widgets/block_unblock_tile.dart';
import 'package:fakebook/widgets/delete_chat_dialog.dart';
import 'package:fakebook/widgets/icon_button_circle.dart';
import 'package:fakebook/widgets/messageBubble_chat_priv.dart' as mb;
import 'package:fakebook/widgets/blocked_banner.dart';

//==== PANTALLA DEL CHAT PRIVADO ====
enum MessageKind { text, image, file }

// Modelo de mensaje para demo
class Message {
  Message({
    required this.isMe,
    required this.kind,
    this.text,
    this.imageUrl,
    this.filePath,
    this.fileName,
    this.time = '10:00',
  });
  final bool isMe;
  final MessageKind kind;
  final String? text;
  final String? imageUrl;
  final String? filePath;
  final String? fileName;
  final String time;
}

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.recipientId,
    this.userName,
    this.initialConversationId,
  });

  final String name;
  final String avatarUrl;
  final String? recipientId;
  final String? userName;
  final String? initialConversationId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversationId;
  bool _creating = false;
  bool _sending = false;
  // Mensajes locales de demo (no persistentes)
  final List<Message> _demoMessages = [];

  @override
  void initState() {
    super.initState();
    _conversationId = widget.initialConversationId;

    // Cancelar notificación al abrir el chat
    if (_conversationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        NotificationService().cancelNotification(_conversationId!);

        // Marcar como leída localmente y en servidor
        final currentUser = ref.read(userProvider);
        if (currentUser != null) {
          // marcar en provider local
          ref
              .read(realtimeConversationsProvider(currentUser.id).notifier)
              .markAsRead(_conversationId!);

          // marcar persistente en servidor
          final markRead = ref.read(markConversationReadProvider);
          await markRead(_conversationId!, currentUser.id);
        }
      });
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

  Future<void> _showActionMenu(BuildContext context) async {
    String? targetUserId = widget.recipientId;
    final container = ProviderScope.containerOf(context, listen: false);
    if ((targetUserId == null || targetUserId.isEmpty) &&
        _conversationId != null) {
      try {
        final parts =
            await container.read(participantsProvider(_conversationId!).future);
        final me = ref.read(userProvider);
        final myId = me?.id;
        targetUserId = parts
            .firstWhere((p) => p.profileId != myId, orElse: () => parts.first)
            .profileId;
      } catch (_) {}
    }

    bool currentBlocked = false;
    if (targetUserId != null && targetUserId.isNotEmpty) {
      try {
        currentBlocked =
            await container.read(isUserBlockedProvider(targetUserId).future);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            if (targetUserId != null && targetUserId.isNotEmpty)
              BlockUnblockTile(
                profileId: targetUserId,
                name: widget.name,
                isBlocked: currentBlocked,
                parentContext: context,
                sheetContext: ctx,
              )
            else
              ListTile(
                leading: Icon(
                  currentBlocked ? Icons.lock_open : Icons.block,
                  color: currentBlocked ? Colors.green : Colors.red,
                ),
                title: Text(currentBlocked ? 'Desbloquear' : 'Bloquear'),
                onTap: () async {
                  Navigator.pop(ctx);
                  // Fallback demo sin target real
                  if (currentBlocked) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Usuario desbloqueado (demo)')),
                      );
                    }
                  } else {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('Bloquear usuario'),
                        content: Text(
                            '¿Estas seguro de que quieres bloquear a ${widget.name}?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(dctx, false),
                              child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () => Navigator.pop(dctx, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Bloquear'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Usuario bloqueado (demo)')),
                      );
                    }
                  }
                },
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar chat'),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(context);
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
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
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDeleteChatDialog(
      context,
      name: widget.name,
      onConfirm: () async {
        if (_conversationId != null && _conversationId!.isNotEmpty) {
          try {
            final currentUser = ref.read(userProvider);
            if (currentUser != null) {
              ref.read(deleteConversationProvider.notifier).delete(
                    conversationId: _conversationId!,
                    profileId: currentUser.id,
                  );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversación eliminada'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al eliminar: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Conversación eliminada (demo)'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 70, left: 10, right: 10),
              ),
            );
          }
        }
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

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
        title: (_conversationId == null)
            ? InkWell(
                onTap: () async {
                  // Si hay un recipientId, intentar cargar el perfil real antes de navegar.
                  if (widget.recipientId != null &&
                      widget.recipientId!.isNotEmpty) {
                    try {
                      final profile = await ProfileRepository()
                          .getProfile(widget.recipientId!);
                      final displayName = profile?.displayName ?? widget.name;
                      final avatar = profile?.avatarUrl ?? widget.avatarUrl;
                      final bio = profile?.bio ?? '';

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserChatProfileViewScreen(
                            name: displayName,
                            avatarUrl: avatar,
                            bio: bio,
                            targetUserId: widget.recipientId,
                          ),
                        ),
                      );
                      return;
                    } catch (e) {
                      // Fallthrough: si falla la carga, usar los datos provisionales
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('No se pudo cargar el perfil: $e')),
                        );
                      }
                    }
                  }

                  // Fallback si no hay recipientId o la carga falló
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserChatProfileViewScreen(
                        name: widget.name,
                        avatarUrl: widget.avatarUrl,
                        bio: '',
                        targetUserId: widget.recipientId,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.avatarUrl.isNotEmpty
                          ? NetworkImage(widget.avatarUrl)
                          : null,
                      backgroundColor: _colorFromInitial(widget.name),
                      child: widget.avatarUrl.isEmpty
                          ? Text(
                              widget.name.isNotEmpty
                                  ? widget.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Consumer(builder: (context, ref, _) {
                final me = ref.watch(userProvider);
                final partsAsync =
                    ref.watch(participantsProvider(_conversationId!));
                return partsAsync.when(
                  loading: () => InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserChatProfileViewScreen(
                              name: widget.name,
                              avatarUrl: widget.avatarUrl,
                              bio: '',
                              targetUserId: widget.recipientId,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _colorFromInitial(widget.name),
                            child: Text(
                              widget.name.isNotEmpty
                                  ? widget.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Cargando...',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      )),
                  error: (e, st) => Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          widget.name.isNotEmpty
                              ? widget.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  data: (parts) {
                    final myId = me?.id;
                    String? otherId = parts
                        .firstWhere((p) => p.profileId != myId,
                            orElse: () => parts.first)
                        .profileId;
                    return FutureBuilder(
                      future: ProfileRepository().getProfile(otherId),
                      builder: (context, snap) {
                        final displayName =
                            snap.data?.displayName ?? widget.name;
                        final avatarUrl =
                            snap.data?.avatarUrl ?? widget.avatarUrl;
                        return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserChatProfileViewScreen(
                                    name: displayName,
                                    avatarUrl: avatarUrl,
                                    bio: snap.data?.bio ?? '',
                                    targetUserId: otherId,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  backgroundColor:
                                      _colorFromInitial(displayName),
                                  child: avatarUrl.isEmpty
                                      ? Text(
                                          displayName.isNotEmpty
                                              ? displayName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ));
                      },
                    );
                  },
                );
              }),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => _showActionMenu(context),
            tooltip: 'Más opciones',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: Colors.black12),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner de bloqueo (si el otro usuario está bloqueado)
            if (_conversationId == null && widget.recipientId != null)
              Consumer(builder: (context, ref, _) {
                final blockedAsync =
                    ref.watch(isUserBlockedProvider(widget.recipientId!));
                return blockedAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (isBlocked) {
                    if (!isBlocked) return const SizedBox.shrink();
                    return BlockedBanner(
                      onUnblock: () async =>
                          _promptUnblock(widget.recipientId!),
                    );
                  },
                );
              })
            else if (_conversationId != null)
              Consumer(builder: (context, ref, _) {
                final partsAsync =
                    ref.watch(participantsProvider(_conversationId!));
                return partsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (parts) {
                    final myId = user?.id;
                    final otherId = parts
                        .firstWhere((p) => p.profileId != myId,
                            orElse: () => parts.first)
                        .profileId;
                    final blockedAsync =
                        ref.watch(isUserBlockedProvider(otherId));
                    return blockedAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                      data: (isBlocked) {
                        if (!isBlocked) return const SizedBox.shrink();
                        return BlockedBanner(
                            onUnblock: () async => _promptUnblock(otherId));
                      },
                    );
                  },
                );
              }),
            // MENSAJES DEL CHAT CON REALTIME
            Expanded(
              child: (_conversationId == null)
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.message_outlined,
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
                              'Envía el primer mensaje para crear la conversación.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Consumer(
                      builder: (context, ref, _) {
                        // USAR REALTIME MESSAGES PROVIDER
                        final messages = ref
                            .watch(realtimeMessagesProvider(_conversationId!));

                        // Auto-scroll cuando llegan mensajes nuevos
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });

                        final List<Widget> children = [];

                        // Mensajes locales de demo
                        for (final dm in _demoMessages) {
                          if (dm.kind == MessageKind.image) {
                            children.add(
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: mb.MessageBubbleChatPriv(
                                  isMe: true,
                                  isImage: true,
                                  time: dm.time,
                                  child: _ImageContent(filePath: dm.filePath),
                                ),
                              ),
                            );
                          } else if (dm.kind == MessageKind.file) {
                            children.add(
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: mb.MessageBubbleChatPriv(
                                  isMe: true,
                                  isImage: false,
                                  time: dm.time,
                                  child: _FileContent(
                                      fileName: dm.fileName ?? 'archivo',
                                      filePath: dm.filePath),
                                ),
                              ),
                            );
                          } else {
                            children.add(
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: mb.MessageBubbleChatPriv(
                                  isMe: true,
                                  isImage: false,
                                  time: dm.time,
                                  child: ExpandableText(
                                      text: dm.text ?? '', trimLength: 160),
                                ),
                              ),
                            );
                          }
                        }

                        // Mensajes en tiempo real
                        if (messages.isEmpty && children.isEmpty) {
                          return const Center(child: Text('Sin mensajes'));
                        }

                        for (final m in messages) {
                          final isMe = m.senderId == user?.id;
                          children.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: mb.MessageBubbleChatPriv(
                                isMe: isMe,
                                isImage: false,
                                time: _formatTime(m.createdAt),
                                child: ExpandableText(
                                    text: m.body ?? '', trimLength: 160),
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            // Invalidar el provider para recargar los mensajes
                            ref.invalidate(
                                realtimeMessagesProvider(_conversationId!));
                            // Pequeño delay para mostrar el indicador
                            await Future.delayed(
                                const Duration(milliseconds: 500));
                          },
                          // Color personalizado para el indicador
                          color: Colors.blueAccent,
                          backgroundColor: Colors.white,
                          child: ListView(
                            controller: _scrollController,
                            reverse: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            children: children,
                          ),
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
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6E8EE)),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Escribir mensaje',
                          hintStyle: TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  IconButtonCircle(
                    icon: Icons.attach_file,
                    onTap: () async {
                      // Demo permite seleccionar y previsualizar localmente sin subir
                      final XFile? picked = await openFile(
                        acceptedTypeGroups: const [
                          XTypeGroup(label: 'all', extensions: [
                            'jpg',
                            'jpeg',
                            'png',
                            'gif',
                            'webp',
                            'bmp',
                            'heic',
                            'heif',
                            'pdf',
                            'doc',
                            'docx',
                            'ppt',
                            'pptx',
                            'xls',
                            'xlsx',
                            'txt'
                          ])
                        ],
                      );
                      if (picked == null) return;
                      final pathStr = picked.path;
                      final ext = p.extension(pathStr).toLowerCase();
                      final isImage = [
                        '.jpg',
                        '.jpeg',
                        '.png',
                        '.gif',
                        '.webp',
                        '.bmp',
                        '.heic',
                        '.heif'
                      ].contains(ext);

                      if (!context.mounted) return;
                      if (isImage) {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                              builder: (_) =>
                                  _LocalImageViewer(filePath: pathStr)),
                        );
                        if (!mounted) return;
                        if (result != null && result.isNotEmpty) {
                          setState(() {
                            _demoMessages.insert(
                              0,
                              Message(
                                isMe: false,
                                kind: MessageKind.image,
                                filePath: result,
                                time: _nowTime(),
                              ),
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Imagen agregada al chat (demo)')),
                          );
                        }
                      } else {
                        final file = File(pathStr);
                        int size = 0;
                        try {
                          size = await file.length();
                        } catch (_) {}
                        final name = p.basename(pathStr);
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (ctx) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.insert_drive_file,
                                          size: 28, color: Colors.black54),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    size > 0
                                        ? 'Tamaño: ${size.toString()} bytes'
                                        : 'Tamaño desconocido',
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            setState(() {
                                              _demoMessages.insert(
                                                0,
                                                Message(
                                                  isMe: true,
                                                  kind: MessageKind.file,
                                                  fileName: name,
                                                  filePath: pathStr,
                                                  time: _nowTime(),
                                                ),
                                              );
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Archivo agregado al chat (demo)')),
                                            );
                                          },
                                          child: const Text('Enviar'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancelar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButtonCircle(
                    icon: Icons.send,
                    iconColor: Colors.black,
                    onTap: () async {
                      final txt = _controller.text.trim();
                      if (txt.isEmpty) return;
                      if (user == null) return;
                      if (_sending || _creating) return;

                      try {
                        // Determinar el ID del destinatario
                        String targetId;
                        if (widget.recipientId != null) {
                          targetId = widget.recipientId!;
                        } else if (_conversationId != null) {
                          final parts = await ref.read(
                              participantsProvider(_conversationId!).future);
                          final myId = user.id;
                          targetId = parts
                              .firstWhere((p) => p.profileId != myId,
                                  orElse: () => parts.first)
                              .profileId;
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Error: No hay destinatario')),
                            );
                          }
                          return;
                        }

                        // Verificar si está bloqueado
                        final isBlocked = await ref
                            .read(isUserBlockedProvider(targetId).future);
                        if (isBlocked) {
                          await _promptUnblock(targetId);
                          return;
                        }

                        // Crear conversación si no existe
                        if (_conversationId == null) {
                          if (widget.recipientId == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Falta recipientId para crear conversación')),
                              );
                            }
                            return;
                          }

                          setState(() => _creating = true);

                          try {
                            print('Buscando conversación existente...');
                            // Buscar una conversación existente entre ambos
                            final convos = await ref.read(
                                userConversationsProvider(user.id).future);
                            String? foundId;

                            print(
                                'Conversaciones encontradas: ${convos.length}');

                            for (final c in convos) {
                              print(
                                  'Revisando conversación: ${c.id}, tipo: ${c.kind}');
                              if (c.kind != 'private') continue;
                              final parts = await ref
                                  .read(participantsProvider(c.id).future);
                              final ids = parts.map((p) => p.profileId).toSet();
                              print('Participantes: $ids');
                              if (ids.contains(user.id) &&
                                  ids.contains(widget.recipientId!)) {
                                foundId = c.id;
                                print(
                                    '¡Conversación existente encontrada! ID: $foundId');
                                break;
                              }
                            }

                            // Si no existe, crear una nueva
                            if (foundId == null) {
                              print(
                                  'No se encontró conversación, creando nueva...');

                              // Llamar directamente al repositorio en lugar del notifier
                              final chatRepo = ref.read(chatRepositoryProvider);
                              final newConversation =
                                  await chatRepo.createConversation(
                                kind: 'private',
                                metadata: {},
                                participantIds: [user.id, widget.recipientId!],
                              );
                              foundId = newConversation.id;
                              print('Conversación creada con ID: $foundId');
                            }

                            if (foundId != null) {
                              setState(() => _conversationId = foundId);

                              // Cancelar notificación al crear la conversación
                              NotificationService().cancelNotification(foundId);

                              // Marcar como leída localmente y en servidor
                              try {
                                ref
                                    .read(realtimeConversationsProvider(user.id)
                                        .notifier)
                                    .markAsRead(foundId);
                                final markRead =
                                    ref.read(markConversationReadProvider);
                                await markRead(foundId, user.id);
                              } catch (e) {
                                // Ignorar error si la columna last_read no existe
                                print('No se pudo marcar como leída: $e');
                              }
                            } else {
                              throw Exception(
                                  'No se pudo obtener el ID de la conversación');
                            }
                          } finally {
                            setState(() => _creating = false);
                          }
                        }

                        // Verificar que tenemos un conversationId válido
                        if (_conversationId == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('No se pudo crear la conversación')),
                            );
                          }
                          return;
                        }

                        // Enviar mensaje
                        setState(() => _sending = true);

                        try {
                          print(
                              'Enviando mensaje a conversación: $_conversationId');

                          // Llamar directamente al repositorio
                          final chatRepo = ref.read(chatRepositoryProvider);
                          await chatRepo.sendMessage(
                            conversationId: _conversationId!,
                            senderId: user.id,
                            body: txt,
                          );

                          print('Mensaje enviado exitosamente');

                          // Limpiar el campo de texto
                          _controller.clear();

                          // Refrescar lista de conversaciones
                          ref.invalidate(userConversationsProvider(user.id));

                          // Auto-scroll después de enviar
                          _scrollToBottom();
                        } catch (sendError) {
                          print('Error al enviar mensaje: $sendError');
                          rethrow;
                        }
                      } catch (e) {
                        print('Error completo al enviar: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al enviar: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _sending = false);
                        }
                      }
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SOLO SIRVE PARA VER Y FORMATEAR LA HORA EN EL CHAT local
  String _nowTime() {
    final now = TimeOfDay.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _promptUnblock(String targetUserId) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuario bloqueado'),
        content: const Text(
            'Este usuario está bloqueado. ¿Deseas desbloquearlo para chatear?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Desbloquear')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(unblockUserProvider(targetUserId).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario desbloqueado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo desbloquear: $e')),
        );
      }
    }
  }
}

// Visor de imagen local
class _LocalImageViewer extends StatefulWidget {
  const _LocalImageViewer({required this.filePath});
  final String filePath;

  @override
  State<_LocalImageViewer> createState() => _LocalImageViewerState();
}

class _LocalImageViewerState extends State<_LocalImageViewer> {
  double _dragDy = 0.0;
  double _bgOpacity = 1.0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDy += details.delta.dy;
      final t = (_dragDy.abs() / 300).clamp(0.0, 0.7);
      _bgOpacity = (1.0 - t).clamp(0.3, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final vy = details.primaryVelocity ?? 0.0;
    if (_dragDy.abs() > 120 || vy.abs() > 800) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _dragDy = 0.0;
      _bgOpacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(_bgOpacity)),
          ),
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              onTap: () => Navigator.of(context).maybePop(),
              child: Transform.translate(
                offset: Offset(0, _dragDy),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child:
                        Image.file(File(widget.filePath), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              ignoring: false,
              child: SafeArea(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.basename(widget.filePath),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(widget.filePath);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CONTENIDO DE IMAGEN
class _ImageContent extends StatelessWidget {
  const _ImageContent({this.url, this.filePath});
  final String? url;
  final String? filePath;
  @override
  Widget build(BuildContext context) {
    final bool isLocal = (filePath != null && filePath!.isNotEmpty);
    final Widget imageWidget = isLocal
        ? Image.file(File(filePath!), fit: BoxFit.cover)
        : Image.network(url!, fit: BoxFit.cover);
    void openViewer() {
      if (!isLocal && url != null && url!.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(imageUrl: url!),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: openViewer,
      onLongPress: () {
        openViewer();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageWidget,
      ),
    );
  }
}

class _FileContent extends StatelessWidget {
  const _FileContent({required this.fileName, this.filePath});
  final String fileName;
  final String? filePath;

  @override
  Widget build(BuildContext context) {
    Future<void> _saveFile() async {
      if (filePath == null || filePath!.isEmpty) return;
      await FileDownloadHelper.saveToDownloadsAndOpen(
        context,
        srcPath: filePath!,
        fileName: fileName,
      );
    }

    return InkWell(
      onTap: _saveFile,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName,
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.download_rounded, size: 18, color: Colors.black54),
        ],
      ),
    );
  }
}
