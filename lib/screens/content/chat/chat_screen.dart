import 'package:fakebook/providers/chat_providers.dart';
import 'package:fakebook/screens/auth/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/widgets/custom_navbar.dart';
import 'package:fakebook/screens/content/dashboard.dart';
import 'package:fakebook/screens/auth/profile_screen.dart';
import 'package:fakebook/screens/content/search_screen.dart';
import 'contacts_screen.dart';
import 'chat_detail_screen.dart';
import 'select_group_members_screen.dart';
import 'group_chat_detail_screen.dart';
import 'chat_card.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import 'package:fakebook/models/conversation_model.dart';
import 'archived_chats_screen.dart';
import 'package:fakebook/widgets/new_chat_modal.dart';

//==== PANTALLA DE CHATS ====
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final Set<String> _readConversations = <String>{};
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        if (ModalRoute.of(context)?.settings.name != '/dashboard') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardPage(),
              settings: const RouteSettings(name: '/dashboard'),
            ),
          );
        }
        break;
      case 1:
        if (ModalRoute.of(context)?.settings.name != '/search') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SearchScreen(),
              settings: const RouteSettings(name: '/search'),
            ),
          );
        }
        break;
      case 3:
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        ).then((_) {
          if (!mounted) return;
          setState(() {
            _selectedIndex = 3;
          });
        });
        break;
    }
  }

  void _startPrivateChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactsScreen()),
    );
  }

  void _startGroupChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectGroupMembersScreen()),
    );
  }

  void _showNewChatModal() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return NewChatModal(
          onStartPrivate: _startPrivateChat,
          onStartGroup: _startGroupChat,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Escuchar cambios en tiempo real
    ref.watch(realtimeConversationsProvider(currentUser.id));
    ref.watch(realtimeParticipantsProvider(currentUser.id));
    final chatAsync = ref.watch(userConversationsProvider(currentUser.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Mensajes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            elevation: 10,
            color: Colors.white,
            shadowColor: Colors.black.withOpacity(0.15),
            surfaceTintColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 8),
            onSelected: (value) {
              switch (value) {
                case 1:
                  _showNewChatModal();
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ArchivedChatsScreen()),
                  );
                  break;
                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 18, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Nuevo chat'),
                  ],
                ),
              ),
              PopupMenuDivider(height: 4),
              PopupMenuItem<int>(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined,
                        size: 18, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Ajustes'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: Colors.black12,
          ),
        ),
      ),
      body: chatAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Cargando conversaciones...',
                  style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (conversations) => conversations.isNotEmpty
            ? FutureBuilder<List<MapEntry<ConversationModel, DateTime?>>>(
                future: Future.wait(conversations.map((c) async {
                  try {
                    // CAMBIO IMPORTANTE: Usar realtimeMessagesProvider en lugar de messagesProvider
                    final msgs = ref.read(realtimeMessagesProvider(c.id));
                    final dt =
                        msgs.isNotEmpty ? msgs.first.createdAt : c.createdAt;
                    return MapEntry(c, dt);
                  } catch (_) {
                    return MapEntry(c, c.createdAt);
                  }
                })).then((list) {
                  list.sort((a, b) {
                    final at =
                        a.value ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final bt =
                        b.value ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return bt.compareTo(at);
                  });
                  return list;
                }),
                builder: (context, snap) {
                  final sorted = snap.data ??
                      conversations
                          .map((c) => MapEntry(c, c.createdAt))
                          .toList();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final convo = sorted[index].key;
                      return Consumer(
                        builder: (context, ref, _) {
                          // CAMBIO IMPORTANTE: Usar realtimeMessagesProvider
                          final msgs =
                              ref.watch(realtimeMessagesProvider(convo.id));
                          final partsAsync =
                              ref.watch(participantsProvider(convo.id));

                          // Para grupos
                          if (convo.kind == 'group') {
                            final title =
                                (convo.metadata['title'] ?? 'Grupo').toString();
                            final avatarUrl =
                                (convo.metadata['avatarUrl'] ?? '').toString();
                            final last = msgs.isNotEmpty ? msgs.first : null;
                            String preview = last?.body ?? 'Sin mensajes';
                            final myId = ref.read(userProvider)?.id;

                            if (last != null && last.senderId == myId) {
                              preview = 'Tú: $preview';
                            }

                            int unread = 0;
                            for (final m in msgs) {
                              if (m.senderId != myId) {
                                unread++;
                              } else {
                                break;
                              }
                            }
                            if (_readConversations.contains(convo.id))
                              unread = 0;

                            final time = last?.createdAt != null
                                ? _formatTime(last!.createdAt!)
                                : '';

                            return ChatCard(
                              name: title,
                              message: preview,
                              time: time,
                              avatarUrl: avatarUrl,
                              unreadCount: unread,
                              isUnread: unread > 0,
                              isGroup: true,
                              conversationId: convo.id,
                              onArchive: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ArchivedChatsScreen()),
                                );
                              },
                              onTap: () {
                                setState(
                                    () => _readConversations.add(convo.id));
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GroupChatDetailScreen(
                                      conversationId: convo.id,
                                      title: title,
                                      avatarUrl: avatarUrl,
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          // Para chats privados
                          return partsAsync.when(
                            loading: () => ChatCard(
                              name: 'Chat',
                              message: 'Cargando...',
                              time: '',
                              avatarUrl: '',
                              conversationId: convo.id,
                              onTap: () {},
                            ),
                            error: (e, st) => ChatCard(
                              name: (convo.metadata['title'] ?? 'Chat')
                                  .toString(),
                              message: 'Error al cargar',
                              time: '',
                              avatarUrl: (convo.metadata['avatarUrl'] ?? '')
                                  .toString(),
                              conversationId: convo.id,
                              onTap: () {},
                            ),
                            data: (parts) {
                              final me = ref.read(userProvider);
                              final myId = me?.id;
                              final otherId = parts
                                  .firstWhere((p) => p.profileId != myId,
                                      orElse: () => parts.first)
                                  .profileId;

                              return FutureBuilder(
                                future: ProfileRepository().getProfile(otherId),
                                builder: (context, snap) {
                                  final displayName = snap.data?.displayName ??
                                      (convo.metadata['title'] ?? 'Chat')
                                          .toString();
                                  final avatarUrl = snap.data?.avatarUrl ??
                                      (convo.metadata['avatarUrl'] ?? '')
                                          .toString();

                                  final last =
                                      msgs.isNotEmpty ? msgs.first : null;
                                  String preview = last?.body ?? 'Sin mensajes';

                                  if (last != null && last.senderId == me?.id) {
                                    preview = 'Tú: $preview';
                                  }

                                  int unread = 0;
                                  for (final m in msgs) {
                                    if (m.senderId != myId) {
                                      unread++;
                                    } else {
                                      break;
                                    }
                                  }

                                  final time = last?.createdAt != null
                                      ? _formatTime(last!.createdAt!)
                                      : '';
                                  if (_readConversations.contains(convo.id))
                                    unread = 0;

                                  return ChatCard(
                                    name: displayName,
                                    message: preview,
                                    time: time,
                                    avatarUrl: avatarUrl,
                                    conversationId: convo.id,
                                    unreadCount: unread,
                                    isUnread: unread > 0,
                                    targetUserId: otherId,
                                    onArchive: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Chat archivado (demo)')),
                                      );
                                    },
                                    onTap: () {
                                      setState(() =>
                                          _readConversations.add(convo.id));
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatDetailScreen(
                                            name: displayName,
                                            avatarUrl: avatarUrl,
                                            initialConversationId: convo.id,
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
                      );
                    },
                  );
                },
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.black38),
                      const SizedBox(height: 12),
                      const Text(
                        'Aun no hay chats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Inicia una conversacion nueva con los amigos que sigues',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showNewChatModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Iniciar nuevo chat'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
