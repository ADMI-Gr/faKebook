import 'package:flutter/material.dart';

// Banner que aparece cuando el otro usuario esta bloqueado en el chat
class BlockedBanner extends StatelessWidget {
  const BlockedBanner({super.key, required this.onUnblock});
  final Future<void> Function() onUnblock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Este usuario esta bloqueado. No podras interactuar con el hasta desbloquearlo.',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onUnblock,
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
  }
}
