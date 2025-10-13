import 'package:flutter/material.dart';
import 'chat_card.dart';

//=== Pantalla de chats archivados
class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo data
    final demoConversations = [
      {
        'name': 'Proyecto Taller',
        'message': 'Quedamos en revisar el PR mañana',
        'time': '18:45',
        'avatarUrl': '',
        'isGroup': true,
        'unread': 0,
      },
      {
        'name': 'Maria Lopez',
        'message': '¿Llegaste bien?',
        'time': '16:02',
        'avatarUrl': '',
        'isGroup': false,
        'unread': 2,
      },
      {
        'name': 'Familia',
        'message': 'Foto: cena de hoy',
        'time': 'Ayer',
        'avatarUrl': '',
        'isGroup': true,
        'unread': 0,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Archivados', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: Colors.black12),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (demoConversations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_outlined, size: 64, color: Colors.black38),
                    SizedBox(height: 12),
                    Text('No tienes chats archivados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text('Manten presionado un chat y elige Archivar para verlo aqui.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: demoConversations.length,
            itemBuilder: (context, index) {
              final item = demoConversations[index];
              return ChatCard(
                name: item['name'] as String,
                message: item['message'] as String,
                time: item['time'] as String,
                avatarUrl: item['avatarUrl'] as String,
                unreadCount: item['unread'] as int,
                isUnread: (item['unread'] as int) > 0,
                isGroup: item['isGroup'] as bool,
                isArchived: true,
                onArchive: () {
                  //FUTURO METODO PARA DESARCHIVAR
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat desarchivado (demo)')),
                  );
                },
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
