import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/chat_providers.dart';
import '../image_viewer_screen.dart';
import 'create_group_screen.dart';
import 'chat_detail_screen.dart';
import 'package:fakebook/widgets/group_avatar_actions.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/widgets/actions_group_chat_profile.dart';

// PANTALLA DE PERFIL DEL GRUPO
class GroupMember {
  GroupMember({
    required this.profileId,
    required this.name,
    required this.avatarUrl,
    this.isAdmin = false,
  });

  final String profileId;
  final String name;
  final String avatarUrl;
  final bool isAdmin;
}

class GroupChatProfileViewScreen extends ConsumerWidget {
  const GroupChatProfileViewScreen({
    super.key,
    required this.title,
    required this.avatarUrl,
    required this.description,
    required this.members,
    required this.conversationId,
    this.isCurrentUserAdmin = false,
  });

  final String title;
  final String avatarUrl;
  final String description;
  final List<GroupMember> members;
  final String conversationId;
  final bool isCurrentUserAdmin;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Perfil del grupo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            tooltip: 'Más opciones',
            onPressed: () => _showActionMenu(context),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: Colors.black12),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (avatarUrl.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewerScreen(imageUrl: avatarUrl),
                      ),
                    );
                  },
                  onLongPress: () async {
                    if (avatarUrl.isEmpty) return;
                    // Acciones de la foto del grupo
                    await showGroupAvatarActions(
                      context: context,
                      title: title,
                      avatarUrl: avatarUrl,
                      isCurrentUserAdmin: isCurrentUserAdmin,
                    );
                  },
                  // FOTO DEL GRUPO
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    backgroundColor: avatarUrl.isEmpty ? _colorFromInitial(title) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            title.isNotEmpty ? title[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 24, thickness: 0.5, color: Colors.black12),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Descripción',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6E8EE)),
                ),
                child: Text(
                  description.isNotEmpty ? description : 'Sin descripción',
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.black87, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Miembros',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6E8EE)),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 0, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    return InkWell(
                      onTap: () async {
                        try {
                          final me = ref.read(userProvider);
                          if (me != null && m.profileId == me.id) {
                            return;
                          }
                          String? existingConvoId;
                          if (me != null) {
                            final convos = await ref.read(userConversationsProvider(me.id).future);
                            final privates = convos.where((c) => c.kind == 'private').toList();
                            for (final c in privates) {
                              final parts = await ref.read(participantsProvider(c.id).future);
                              final ids = parts.map((e) => e.profileId).toSet();
                              if (ids.length == 2 && ids.contains(me.id) && ids.contains(m.profileId)) {
                                existingConvoId = c.id;
                                break;
                              }
                            }
                          }
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                name: m.name,
                                avatarUrl: m.avatarUrl,
                                recipientId: existingConvoId == null ? m.profileId : null,
                                userName: m.name,
                                initialConversationId: existingConvoId,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No se pudo abrir el chat: $e')),
                          );
                        }
                      },
                      onLongPress: () => _showMemberActions(context, ref, m),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: m.avatarUrl.isNotEmpty ? NetworkImage(m.avatarUrl) : null,
                              backgroundColor: m.avatarUrl.isEmpty ? _colorFromInitial(m.name) : null,
                              child: m.avatarUrl.isEmpty
                                  ? Text(
                                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          m.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (m.isAdmin)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFFB2DFDB)),
                                          ),
                                          child: const Text(
                                            'Administrador',
                                            style: TextStyle(
                                              color: Color(0xFF00796B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (me != null && m.profileId == me.id)
                                        ? 'Eres tú'
                                        : 'Tocar para chatear',
                                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.black26),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // METODO PARA MOSTRAR ACCIONES DE MIEMBRO
  void _showMemberActions(BuildContext context, WidgetRef ref, GroupMember m) async {
    final me = ref.read(userProvider);
    if (me != null && m.profileId == me.id) return; // no acciones sobre uno mismo

    // Estado de bloqueo (bloqueado por mi)
    bool isBlocked = false;
    try {
      isBlocked = await ref.read(isUserBlockedProvider(m.profileId).future);
    } catch (_) {}

    // Mostrar acciones
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => GroupMemberActionsSheet(
        parentContext: context,
        sheetContext: ctx,
        memberName: m.name,
        memberProfileId: m.profileId,
        memberAvatarUrl: m.avatarUrl,
        isCurrentUserAdmin: isCurrentUserAdmin,
        isBlocked: isBlocked,
        onSendMessage: () {
          () async {
            try {
              final me = ref.read(userProvider);
              String? existingConvoId;
              if (me != null) {
                final convos = await ref.read(userConversationsProvider(me.id).future);
                final privates = convos.where((c) => c.kind == 'private').toList();
                for (final c in privates) {
                  final parts = await ref.read(participantsProvider(c.id).future);
                  final ids = parts.map((e) => e.profileId).toSet();
                  if (ids.length == 2 && ids.contains(me.id) && ids.contains(m.profileId)) {
                    existingConvoId = c.id;
                    break;
                  }
                }
              }
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    name: m.name,
                    avatarUrl: m.avatarUrl,
                    recipientId: existingConvoId == null ? m.profileId : null,
                    userName: m.name,
                    initialConversationId: existingConvoId,
                  ),
                ),
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo abrir el chat: $e')),
                );
              }
            }
          }();
        },
        //METODO PARA PROMOVER UN MIEMBRO
        onPromote: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${m.name}" promovido (demo)')),
          );
        },
        //METODO PARA EXPULSAR UN MIEMBRO si es admin
        onKick: () {
          showDialog(
            context: context,
            builder: (dctx) => AlertDialog(
              title: const Text('Expulsar miembro'),
              content: Text('¿Seguro que quieres expulsar a ${m.name}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${m.name} expulsado (demo)')),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Expulsar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => GroupActionsSheet(
        sheetContext: ctx,
        isCurrentUserAdmin: isCurrentUserAdmin,
        //METODO PARA EDITAR UN GRUPO si es admin
        onEdit: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGroupScreen(
                memberIds: const [],
                isEdit: true,
                initialTitle: title,
                initialDescription: description,
                initialAvatarUrl: avatarUrl,
                conversationId: conversationId,
              ),
            ),
          );
        },
        //METODO PARA SALIR DEL GRUPO (MUESTRA UN MODAL PRIMERO)
        onLeave: () {
          _confirmLeave(context);
        },
        //METODO PARA ARCHIVAR UN GRUPO
        onArchive: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grupo archivado (demo)')),
          );
        },
        //METODO PARA ELIMINAR UN GRUPO
        onDelete: () {
          _confirmDelete(context);
        },
      ),
    );
  }

  //MODAL DE CONFIRMAR SALIR DEL GRUPO
  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: const Text('¿Seguro que quieres salir de este grupo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
          TextButton(
            //METODO PARA SALIR DEL GRUPO
            onPressed: () {
              Navigator.pop(dctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Has salido del grupo (demo)')),
              );
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  //MODAL DE CONFIRMAR ELIMINAR EL GRUPO
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: const Text('¿Seguro que quieres eliminar este grupo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
          TextButton(
            //METODO PARA ELIMINAR EL GRUPO
            onPressed: () {
              Navigator.pop(dctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Grupo eliminado (demo)')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
