import 'package:flutter/material.dart';

//==== Helper para mostrar dialogo de eliminacion de chat ====
Future<void> showDeleteChatDialog(
  BuildContext context, {
  required String name,
  required VoidCallback onConfirm,
}) async {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar conversacion'),
      content: Text('¿Estas seguro de que quieres eliminar la conversacion con $name?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}
