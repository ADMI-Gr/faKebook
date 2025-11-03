import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/chat_providers.dart';
import 'package:fakebook/screens/content/chat/chat_detail_screen.dart';

//==== PANTALLA DE LOS USUARIOS QUE SE SIGUEN E INICIAR UNA CONVERSACION ====
class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

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
    return colors[(initial.isNotEmpty ? initial[0] : 'A').toUpperCase()] ??
        const Color(0xFF1976D2);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingProvider);
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siguiendo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: Colors.black12),
        ),
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: blockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar bloqueados: $e')),
        data: (blockedList) {
          final blockedIds = blockedList.map((u) => u.id).toSet();
          return followingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                Center(child: Text('Error al cargar contactos: $e')),
            data: (users) {
              if (users.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.black38),
                        SizedBox(height: 12),
                        Text(
                          'Aún no sigues a nadie',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Sigue a personas para iniciar conversaciones rápidas desde aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 0, indent: 76),
                itemBuilder: (context, index) {
                  final u = users[index];
                  final isBlocked = blockedIds.contains(u.id);
                  final displayName = (u.displayName?.isNotEmpty == true)
                      ? u.displayName!
                      : u.username;
                  final avatarUrl = u.avatarUrl ?? '';

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          backgroundColor: avatarUrl.isEmpty
                              ? _getColorFromInitial(displayName)
                              : null,
                          child: avatarUrl.isEmpty
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        if (isBlocked)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.block,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isBlocked ? Colors.black45 : Colors.black,
                      ),
                    ),
                    subtitle: isBlocked
                        ? const Text(
                            'Usuario bloqueado',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500),
                          )
                        : Text('@${u.username}',
                            style: const TextStyle(color: Colors.black54)),
                    trailing: isBlocked
                        ? const Icon(Icons.lock_outline,
                            color: Colors.redAccent)
                        : const Icon(Icons.send, color: Colors.black26),
                    enabled: !isBlocked,
                    onTap: isBlocked
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'No puedes chatear con un usuario bloqueado')),
                            );
                          }
                        : () async {
                            final user = ref.read(userProvider);
                            if (user == null) return;
                            final convos = await ref.read(userConversationsProvider(user.id).future);
                            String? existingId;
                            for (final c in convos) {
                              if (c.kind != 'private') continue;
                              final parts = await ref.read(participantsProvider(c.id).future);
                              final ids = parts.map((p) => p.profileId).toSet();
                              if (ids.contains(u.id) && ids.contains(user.id)) {
                                existingId = c.id;
                                break;
                              }
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  name: displayName,
                                  userName: u.username,
                                  avatarUrl: avatarUrl,
                                  initialConversationId: existingId,
                                  recipientId: existingId == null ? u.id : null,
                                ),
                              ),
                            );
                          },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
