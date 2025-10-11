import 'package:flutter/material.dart';

// Modal para crear nuevo chat privado o grupo
class NewChatModal extends StatelessWidget {
  const NewChatModal({
    super.key,
    required this.onStartPrivate,
    required this.onStartGroup,
  });

  final VoidCallback onStartPrivate;
  final VoidCallback onStartGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.chat_outlined),
          title: const Text('Chat privado'),
          subtitle: const Text('Inicia una conversación 1 a 1'),
          onTap: () {
            Navigator.pop(context);
            onStartPrivate();
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.group_outlined),
          title: const Text('Grupo'),
          subtitle: const Text('Crea un chat con varias personas'),
          onTap: () {
            Navigator.pop(context);
            onStartGroup();
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
