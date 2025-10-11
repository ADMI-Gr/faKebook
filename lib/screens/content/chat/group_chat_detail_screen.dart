import 'dart:io';
import 'package:fakebook/screens/content/chat/create_group_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/chat_providers.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:fakebook/utils/file_download_helper.dart';
import '../image_viewer_screen.dart';
import '../../../widgets/expandable_text.dart';
import 'group_chat_profile_view_screen.dart';
import 'package:fakebook/widgets/messageBubble_chat_group.dart' as mgb;

// Tipos locales para mensajes demo
enum _GDemoKind { image, file, text }

class _GDemoMessage {
  _GDemoMessage({
    required this.isMe,
    required this.kind,
    this.filePath,
    this.fileName,
    this.text,
    this.senderName,
    this.senderAvatarUrl,
    required this.time,
  });

  final bool isMe;
  final _GDemoKind kind;
  final String? filePath;
  final String? fileName;
  final String? text;
  final String? senderName;
  final String? senderAvatarUrl;
  final String time;
}

//=== PANTALLA DE CHAT DE GRUPO
class GroupChatDetailScreen extends ConsumerStatefulWidget {
  const GroupChatDetailScreen(
      {super.key,
      required this.conversationId,
      required this.title,
      required this.avatarUrl});
  final String conversationId;
  final String title;
  final String avatarUrl;

  @override
  ConsumerState<GroupChatDetailScreen> createState() =>
      _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends ConsumerState<GroupChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  // Mensajes locales de demo para mostrar envios simulados en chat de grupo
  final List<_GDemoMessage> _demoMessages = [];

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  void initState() {
    super.initState();
    if (_demoMessages.isEmpty) {
      final now = DateTime.now();
      _demoMessages.addAll([
        _GDemoMessage(
          isMe: false,
          kind: _GDemoKind.text,
          text: 'Hola este es un texto corto de prueba.',
          senderName: 'Carlos Perez',
          senderAvatarUrl: '',
          time: _formatTime(now.subtract(const Duration(minutes: 2))),
        ),
        _GDemoMessage(
          isMe: false,
          kind: _GDemoKind.text,
          text:
              'Este es un texto largo para verificar el ajuste de líneas y el ancho máximo de la burbuja. Queremos comprobar cómo se ve cuando el contenido ocupa varias líneas y mantiene el diseño consistente con el chat individual en diferentes tamaños de pantalla.',
          senderName: 'Ana Lopez',
          senderAvatarUrl: '',
          time: _formatTime(now.subtract(const Duration(minutes: 2))),
        ),
        _GDemoMessage(
          isMe: false,
          kind: _GDemoKind.file,
          fileName: 'Documento de ejemplo.pdf',
          filePath: '',
          senderName: 'Mario',
          senderAvatarUrl: '',
          time: _formatTime(now.subtract(const Duration(minutes: 1))),
        ),
        _GDemoMessage(
          isMe: false,
          kind: _GDemoKind.image,
          filePath:
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200',
          senderName: 'Lucía',
          senderAvatarUrl: '',
          time: _formatTime(now),
        ),
      ]);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.black87),
                title: const Text('Editar'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    String initialDescription = '';
                    String initialTitle = widget.title;
                    String initialAvatar = widget.avatarUrl;
                    final meLocal = ref.read(userProvider);
                    if (meLocal != null) {
                      final conversations = await ref
                          .read(userConversationsProvider(meLocal.id).future);
                      final convo = conversations.firstWhere(
                          (c) => c.id == widget.conversationId,
                          orElse: () => conversations.first);
                      final md = convo.metadata;
                      if (md['title'] != null)
                        initialTitle = md['title'].toString();
                      if (md['description'] != null)
                        initialDescription = md['description'].toString();
                      if (md['avatarUrl'] != null)
                        initialAvatar = md['avatarUrl'].toString();
                    }
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateGroupScreen(
                          memberIds: const [],
                          isEdit: true,
                          initialTitle: initialTitle,
                          initialDescription: initialDescription,
                          initialAvatarUrl: initialAvatar,
                          conversationId: widget.conversationId,
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo abrir edición: $e')),
                    );
                  }
                },
              ),
            if (isAdmin) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black87),
              title: const Text('Salir del grupo'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Salir del grupo'),
                    content:
                        const Text('¿Seguro que quieres salir de este grupo?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dctx),
                          child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Has salido del grupo (demo)')),
                          );
                        },
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.archive_outlined, color: Colors.black87),
              title: const Text('Archivar'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Grupo archivado (demo)')),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Eliminar grupo'),
                    content:
                        const Text('¿Seguro que quieres eliminar este grupo?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dctx),
                          child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Grupo eliminado (demo)')),
                          );
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
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
                    title: widget.title,
                    avatarUrl: widget.avatarUrl,
                    description: description,
                    members: members,
                    conversationId: widget.conversationId,
                    isCurrentUserAdmin: isCurrentUserAdmin,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => _showGroupActionMenu(context),
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
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final msgsAsync =
                      ref.watch(messagesProvider(widget.conversationId));
                  return msgsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                    data: (msgs) {
                      final List<Widget> children = [];

                      // Mensajes demo locales
                      for (final dm in _demoMessages) {
                        if (dm.kind == _GDemoKind.image) {
                          children.add(
                            const SizedBox(height: 6),
                          );
                          if (dm.isMe) {
                            children.add(
                              mgb.messageBubbleChatGroup(
                                isMe: true,
                                isImage: true,
                                time: dm.time,
                                child: (() {
                                  final src = dm.filePath ?? '';
                                  final bool isUrl =
                                      src.startsWith('http://') ||
                                          src.startsWith('https://');
                                  final Widget imageWidget = isUrl
                                      ? Image.network(src, fit: BoxFit.cover)
                                      : Image.file(File(src),
                                          fit: BoxFit.cover);
                                  void openViewer() {
                                    if (isUrl) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ImageViewerScreen(imageUrl: src),
                                        ),
                                      );
                                    }
                                  }

                                  return GestureDetector(
                                    onTap: openViewer,
                                    onLongPress: openViewer,
                                    child: imageWidget,
                                  );
                                })(),
                              ),
                            );
                          } else {
                            children.add(
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        (dm.senderAvatarUrl != null &&
                                                dm.senderAvatarUrl!.isNotEmpty)
                                            ? NetworkImage(dm.senderAvatarUrl!)
                                            : null,
                                    backgroundColor:
                                        (dm.senderAvatarUrl == null ||
                                                dm.senderAvatarUrl!.isEmpty)
                                            ? _colorFromInitial(
                                                dm.senderName ?? 'U')
                                            : null,
                                    child: (dm.senderAvatarUrl == null ||
                                            dm.senderAvatarUrl!.isEmpty)
                                        ? Text(
                                            (dm.senderName?.isNotEmpty == true
                                                ? dm.senderName![0]
                                                    .toUpperCase()
                                                : 'U'),
                                            style: const TextStyle(
                                                color: Colors.white))
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dm.senderName ?? 'Usuario',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        mgb.messageBubbleChatGroup(
                                          isMe: false,
                                          isImage: true,
                                          time: dm.time,
                                          child: (() {
                                            final src = dm.filePath ?? '';
                                            if (src.startsWith('http://') ||
                                                src.startsWith('https://')) {
                                              return Image.network(src,
                                                  fit: BoxFit.cover);
                                            }
                                            return Image.file(File(src),
                                                fit: BoxFit.cover);
                                          })(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        } else if (dm.kind == _GDemoKind.file) {
                          children.add(
                            const SizedBox(height: 6),
                          );
                          final fileRow = InkWell(
                            onTap: () async {
                              final src = dm.filePath;
                              if (src == null || src.isEmpty) return;
                              final suggested = dm.fileName ?? p.basename(src);
                              try {
                                await FileDownloadHelper.saveToDownloadsAndOpen(
                                  context,
                                  srcPath: src,
                                  fileName: suggested,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Error al guardar: $e')),
                                  );
                                }
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insert_drive_file,
                                    size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    dm.fileName ?? 'archivo',
                                    style:
                                        const TextStyle(color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.download_rounded,
                                    size: 18, color: Colors.black54),
                              ],
                            ),
                          );

                          if (dm.isMe) {
                            children.add(
                              mgb.messageBubbleChatGroup(
                                isMe: true,
                                isImage: false,
                                time: dm.time,
                                child: fileRow,
                              ),
                            );
                          } else {
                            children.add(
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        (dm.senderAvatarUrl != null &&
                                                dm.senderAvatarUrl!.isNotEmpty)
                                            ? NetworkImage(dm.senderAvatarUrl!)
                                            : null,
                                    backgroundColor:
                                        (dm.senderAvatarUrl == null ||
                                                dm.senderAvatarUrl!.isEmpty)
                                            ? _colorFromInitial(
                                                dm.senderName ?? 'U')
                                            : null,
                                    child: (dm.senderAvatarUrl == null ||
                                            dm.senderAvatarUrl!.isEmpty)
                                        ? Text(
                                            (dm.senderName?.isNotEmpty == true
                                                ? dm.senderName![0]
                                                    .toUpperCase()
                                                : 'U'),
                                            style: const TextStyle(
                                                color: Colors.white))
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dm.senderName ?? 'Usuario',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        mgb.messageBubbleChatGroup(
                                          isMe: false,
                                          isImage: false,
                                          time: dm.time,
                                          child: fileRow,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        } else if (dm.kind == _GDemoKind.text) {
                          children.add(
                            const SizedBox(height: 6),
                          );
                          if (dm.isMe) {
                            children.add(
                              mgb.messageBubbleChatGroup(
                                isMe: true,
                                isImage: false,
                                time: dm.time,
                                child: ExpandableText(
                                    text: dm.text ?? '', trimLength: 160),
                              ),
                            );
                          } else {
                            children.add(
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        (dm.senderAvatarUrl != null &&
                                                dm.senderAvatarUrl!.isNotEmpty)
                                            ? NetworkImage(dm.senderAvatarUrl!)
                                            : null,
                                    backgroundColor:
                                        (dm.senderAvatarUrl == null ||
                                                dm.senderAvatarUrl!.isEmpty)
                                            ? _colorFromInitial(
                                                dm.senderName ?? 'U')
                                            : null,
                                    child: (dm.senderAvatarUrl == null ||
                                            dm.senderAvatarUrl!.isEmpty)
                                        ? Text(
                                            (dm.senderName?.isNotEmpty == true
                                                ? dm.senderName![0]
                                                    .toUpperCase()
                                                : 'U'),
                                            style: const TextStyle(
                                                color: Colors.white))
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dm.senderName ?? 'Usuario',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        mgb.messageBubbleChatGroup(
                                          isMe: false,
                                          isImage: false,
                                          time: dm.time,
                                          child: ExpandableText(
                                              text: dm.text ?? '',
                                              trimLength: 160),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      }

                      if (msgs.isEmpty && children.isEmpty) {
                        return const Center(child: Text('Sin mensajes'));
                      }
                      for (final m in msgs) {
                        final isMeMsg = m.senderId == me?.id;
                        if (!isMeMsg) {
                          children.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
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
                                      final senderAvatar =
                                          snap.data?.avatarUrl ?? '';
                                      return CircleAvatar(
                                        radius: 16,
                                        backgroundImage: senderAvatar.isNotEmpty
                                            ? NetworkImage(senderAvatar)
                                            : null,
                                        child: senderAvatar.isEmpty
                                            ? Text(senderName[0].toUpperCase())
                                            : null,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: const Color(0xFFE6E8EE)),
                                          ),
                                          child: ExpandableText(
                                              text: m.body ?? '',
                                              trimLength: 160),
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
                          children.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
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
                                            color: Colors.black45,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      return ListView(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        children: children,
                      );
                    },
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
                  const SizedBox(width: 1),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.black87),
                    onPressed: () async {
                      // Demo seleccionar y previsualizar localmente
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
                            builder: (_) => Scaffold(
                              backgroundColor: Colors.transparent,
                              body: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(color: Colors.black),
                                  ),
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(_).maybePop(),
                                      child: Center(
                                        child: InteractiveViewer(
                                          minScale: 0.5,
                                          maxScale: 4,
                                          child: Image.file(File(pathStr)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SafeArea(
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white),
                                        onPressed: () => Navigator.of(_).pop(),
                                      ),
                                    ),
                                  ),
                                  SafeArea(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                            minimumSize:
                                                const Size(double.infinity, 48),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(_).pop(pathStr);
                                          },
                                          icon: const Icon(Icons.send),
                                          label: const Text('Enviar'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        if (!mounted) return;
                        if (result != null && result.isNotEmpty) {
                          // Insertaa mensaje demo de imagen para que se vea en el chat
                          setState(() {
                            _demoMessages.insert(
                              0,
                              _GDemoMessage(
                                isMe: true,
                                kind: _GDemoKind.image,
                                filePath: result,
                                time: _formatTime(DateTime.now()),
                              ),
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Imagen agregada al chat (demo) no se abre en el chat hasta q venga de firebase')),
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
                                            // mensaje demo de archivo para que se vea en el chat
                                            setState(() {
                                              _demoMessages.insert(
                                                0,
                                                _GDemoMessage(
                                                  isMe: true,
                                                  kind: _GDemoKind.file,
                                                  fileName: name,
                                                  filePath: pathStr,
                                                  time: _formatTime(
                                                      DateTime.now()),
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
                                          child: const Text('Cerrar'),
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
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: () {
                      final txt = _controller.text.trim();
                      if (txt.isEmpty) return;
                      // Meter el texto en el chat
                      setState(() {
                        _demoMessages.insert(
                          0,
                          _GDemoMessage(
                            isMe: true,
                            kind: _GDemoKind.text,
                            text: txt,
                            time: _formatTime(DateTime.now()),
                          ),
                        );
                      });
                      _controller.clear();
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
