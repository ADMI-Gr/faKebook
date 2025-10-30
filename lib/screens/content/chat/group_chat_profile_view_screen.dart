import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/chat_providers.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import '../image_viewer_screen.dart';
import 'create_group_screen.dart';
import 'chat_detail_screen.dart';
import 'package:fakebook/widgets/group_avatar_actions.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/widgets/actions_group_chat_profile.dart';
import 'select_group_members_screen.dart';

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
    required this.conversationId,
  });

  final String conversationId;

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

    // Obtener datos dinámicamente
    final participantsAsync = ref.watch(participantsProvider(conversationId));

    return participantsAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Perfil del grupo',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Perfil del grupo',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: Center(child: Text('Error: $error')),
      ),
      data: (participants) {
        // Obtener información de la conversación
        return FutureBuilder(
          future: _loadGroupData(ref, me, participants),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                backgroundColor: const Color(0xFFF6F7FB),
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    'Perfil del grupo',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                  centerTitle: true,
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!;
            final title = data['title'] as String;
            final avatarUrl = data['avatarUrl'] as String;
            final description = data['description'] as String;
            final members = data['members'] as List<GroupMember>;
            final isCurrentUserAdmin = data['isCurrentUserAdmin'] as bool;

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
                title: const Text(
                  'Perfil del grupo',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    tooltip: 'Más opciones',
                    onPressed: () => _showActionMenu(
                      context,
                      ref,
                      title,
                      description,
                      avatarUrl,
                      isCurrentUserAdmin,
                    ),
                  ),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(0.5),
                  child: Divider(
                      height: 0.5, thickness: 0.5, color: Colors.black12),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                                builder: (_) =>
                                    ImageViewerScreen(imageUrl: avatarUrl),
                              ),
                            );
                          },
                          onLongPress: () async {
                            if (avatarUrl.isEmpty) return;
                            await showGroupAvatarActions(
                              context: context,
                              title: title,
                              avatarUrl: avatarUrl,
                              isCurrentUserAdmin: isCurrentUserAdmin,
                            );
                          },
                          child: CircleAvatar(
                            radius: 80,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            backgroundColor: avatarUrl.isEmpty
                                ? _colorFromInitial(title)
                                : null,
                            child: avatarUrl.isEmpty
                                ? Text(
                                    title.isNotEmpty
                                        ? title[0].toUpperCase()
                                        : '?',
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
                      const Divider(
                          height: 24, thickness: 0.5, color: Colors.black12),
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
                          description.isNotEmpty
                              ? description
                              : 'Sin descripción',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              color: Colors.black87, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Miembros',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (isCurrentUserAdmin)
                            TextButton.icon(
                              onPressed: () => _navigateToAddMembers(
                                context,
                                ref,
                                members,
                              ),
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('Agregar'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1976D2),
                              ),
                            ),
                        ],
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
                          separatorBuilder: (_, __) =>
                              const Divider(height: 0, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final m = members[index];
                            return InkWell(
                              onTap: () => _handleMemberTap(context, ref, m),
                              onLongPress: () => _showMemberActions(
                                  context, ref, m, isCurrentUserAdmin),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundImage: m.avatarUrl.isNotEmpty
                                          ? NetworkImage(m.avatarUrl)
                                          : null,
                                      backgroundColor: m.avatarUrl.isEmpty
                                          ? _colorFromInitial(m.name)
                                          : null,
                                      child: m.avatarUrl.isEmpty
                                          ? Text(
                                              m.name.isNotEmpty
                                                  ? m.name[0].toUpperCase()
                                                  : '?',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  m.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                              if (m.isAdmin)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFE8F5E9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFFB2DFDB)),
                                                  ),
                                                  child: const Text(
                                                    'Administrador',
                                                    style: TextStyle(
                                                      color: Color(0xFF00796B),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                            style: const TextStyle(
                                                color: Colors.black45,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: Colors.black26),
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
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadGroupData(
    WidgetRef ref,
    dynamic me,
    List<dynamic> participants,
  ) async {
    // Obtener conversación para metadata
    String title = 'Grupo';
    String avatarUrl = '';
    String description = '';
    List<String> adminIds = [];

    if (me != null) {
      final conversations =
          await ref.read(userConversationsProvider(me.id).future);
      final convo = conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => conversations.first,
      );
      final md = convo.metadata;

      if (md['title'] != null) title = md['title'].toString();
      if (md['avatarUrl'] != null) avatarUrl = md['avatarUrl'].toString();
      if (md['description'] != null) description = md['description'].toString();

      final rawAdmins = md['admins'];
      if (rawAdmins is List) {
        adminIds = rawAdmins.map((e) => e.toString()).toList();
      }
    }

    // Construir lista de miembros
    final List<GroupMember> members = [];
    for (final p in participants) {
      final prof = await ProfileRepository().getProfile(p.profileId);
      final name = prof?.displayName ?? prof?.username ?? 'Usuario';
      final avatar = prof?.avatarUrl ?? '';
      final isAdmin = adminIds.contains(p.profileId);

      members.add(GroupMember(
        profileId: p.profileId,
        name: name,
        avatarUrl: avatar,
        isAdmin: isAdmin,
      ));
    }

    // Determinar si el usuario actual es admin
    bool isCurrentUserAdmin = false;
    if (me != null) {
      isCurrentUserAdmin = adminIds.contains(me.id);
    }

    return {
      'title': title,
      'avatarUrl': avatarUrl,
      'description': description,
      'members': members,
      'isCurrentUserAdmin': isCurrentUserAdmin,
    };
  }

  void _navigateToAddMembers(
    BuildContext context,
    WidgetRef ref,
    List<GroupMember> currentMembers,
  ) {
    final currentMemberIds = currentMembers.map((m) => m.profileId).toSet();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectGroupMembersScreen(
          isAddingToGroup: true,
          conversationId: conversationId,
          excludeUserIds: currentMemberIds,
        ),
      ),
    );
  }

  void _handleMemberTap(
      BuildContext context, WidgetRef ref, GroupMember m) async {
    try {
      final me = ref.read(userProvider);
      if (me != null && m.profileId == me.id) return;

      String? existingConvoId;
      if (me != null) {
        final convos = await ref.read(userConversationsProvider(me.id).future);
        final privates = convos.where((c) => c.kind == 'private').toList();
        for (final c in privates) {
          final parts = await ref.read(participantsProvider(c.id).future);
          final ids = parts.map((e) => e.profileId).toSet();
          if (ids.length == 2 &&
              ids.contains(me.id) &&
              ids.contains(m.profileId)) {
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
  }

  void _showMemberActions(
    BuildContext context,
    WidgetRef ref,
    GroupMember m,
    bool isCurrentUserAdmin,
  ) async {
    final me = ref.read(userProvider);
    if (me != null && m.profileId == me.id) return;

    bool isBlocked = false;
    try {
      isBlocked = await ref.read(isUserBlockedProvider(m.profileId).future);
    } catch (_) {}

    if (!context.mounted) return;
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
        isMemberAdmin: m.isAdmin,
        isBlocked: isBlocked,
        onSendMessage: () => _handleMemberTap(context, ref, m),
        onPromote: () => _promoteToAdmin(context, ref, m),
        onDemote: () => _demoteFromAdmin(context, ref, m),
        onKick: () => _kickMember(context, ref, m),
      ),
    );
  }

  void _promoteToAdmin(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    final me = ref.read(userProvider);
    if (me == null) return;

    try {
      final isAdmin = await ref.read(
        isUserAdminProvider((
          conversationId: conversationId,
          profileId: me.id,
        )).future,
      );

      if (!isAdmin) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo los administradores pueden promover miembros'),
          ),
        );
        return;
      }

      ref.read(addAdminProvider.notifier).add(
            conversationId: conversationId,
            newAdminId: member.profileId,
            requesterId: me.id,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} ahora es administrador')),
      );
      await Future.delayed(const Duration(milliseconds: 300));

      // Invalidar para forzar recarga
      ref.invalidate(participantsProvider(conversationId));
      ref.invalidate(userConversationsProvider(me.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al promover: $e')),
      );
    }
  }

  void _demoteFromAdmin(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    final me = ref.read(userProvider);
    if (me == null) return;

    try {
      final isAdmin = await ref.read(
        isUserAdminProvider((
          conversationId: conversationId,
          profileId: me.id,
        )).future,
      );

      if (!isAdmin) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo los administradores pueden remover admins'),
          ),
        );
        return;
      }

      ref.read(removeAdminProvider.notifier).remove(
            conversationId: conversationId,
            adminIdToRemove: member.profileId,
            requesterId: me.id,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} ya no es administrador')),
      );
      await Future.delayed(const Duration(milliseconds: 300));

      // Invalidar para forzar recarga
      ref.invalidate(participantsProvider(conversationId));
      ref.invalidate(userConversationsProvider(me.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al despromover: $e')),
      );
    }
  }

  void _kickMember(BuildContext context, WidgetRef ref, GroupMember member) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Expulsar miembro'),
        content: Text('¿Seguro que quieres expulsar a ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dctx);
              await _performKick(context, ref, member);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Expulsar'),
          ),
        ],
      ),
    );
  }

  Future<void> _performKick(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    final me = ref.read(userProvider);
    if (me == null) return;

    try {
      final isAdmin = await ref.read(
        isUserAdminProvider((
          conversationId: conversationId,
          profileId: me.id,
        )).future,
      );

      if (!isAdmin) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo los administradores pueden expulsar miembros'),
          ),
        );
        return;
      }

      ref.read(leaveConversationProvider.notifier).leave(
            conversationId: conversationId,
            profileId: member.profileId,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} ha sido expulsado')),
      );
      await Future.delayed(const Duration(milliseconds: 300));

      // Invalidar para forzar recarga
      ref.invalidate(participantsProvider(conversationId));
      ref.invalidate(userConversationsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al expulsar: $e')),
      );
    }
  }

  void _showActionMenu(
    BuildContext context,
    WidgetRef ref,
    String title,
    String description,
    String avatarUrl,
    bool isCurrentUserAdmin,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => GroupActionsSheet(
        sheetContext: ctx,
        isCurrentUserAdmin: isCurrentUserAdmin,
        onEdit: () async {
          final result = await Navigator.push(
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

          // Si se editó exitosamente, forzar recarga
          if (result == true) {
            final me = ref.read(userProvider);
            if (me != null) {
              ref.invalidate(participantsProvider(conversationId));
              ref.invalidate(userConversationsProvider(me.id));
            }
          }
        },
        onLeave: () => _confirmLeave(context, ref),
        onArchive: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grupo archivado (demo)')),
          );
        },
        onDelete: () => _confirmDelete(context, ref),
      ),
    );
  }

  void _confirmLeave(BuildContext context, WidgetRef ref) {
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: const Text(
          '¿Seguro que quieres eliminar este grupo? Esta acción no se puede deshacer y eliminará todos los mensajes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dctx);
              await _performDelete(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(BuildContext context, WidgetRef ref) async {
    final me = ref.read(userProvider);
    if (me == null) return;

    try {
      // Mostrar indicador de carga
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Eliminar conversación
      ref.read(deleteConversationProvider.notifier).delete(
            conversationId: conversationId,
            profileId: me.id,
          );

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Cerrar todas las pantallas y volver a la lista de conversaciones
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga si hay error
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el grupo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
