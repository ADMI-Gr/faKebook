import 'package:flutter/material.dart';

// MENSAJE DE CHAT DE GRUPO
Widget messageBubbleChatGroup({
  Key? key,
  required bool isMe,
  required bool isImage,
  required String time,
  required Widget child,
}) {
  return _GroupMessageBubble(
    key: key,
    isMe: isMe,
    isImage: isImage,
    time: time,
    child: child,
  );
}

class _GroupMessageBubble extends StatelessWidget {
  const _GroupMessageBubble({
    super.key,
    required this.isMe,
    required this.isImage,
    required this.time,
    required this.child,
  });

  final bool isMe;
  final bool isImage;
  final String time;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.78;
    final incomingColor = Colors.white;
    final outgoingColor = const Color(0xFFD8FDD2);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isMe ? 14 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 14),
    );

    final Widget contentCore = isImage
        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: child)
        : child;

    final Widget bubbleChild = isMe
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              contentCore,
            ],
          )
        : (isImage
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: const TextStyle(color: Colors.black45, fontSize: 11)),
                  const SizedBox(height: 4),
                  contentCore,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: contentCore),
                  const SizedBox(width: 8),
                  Text(time, style: const TextStyle(color: Colors.black45, fontSize: 11)),
                ],
              ));

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? outgoingColor : incomingColor,
        borderRadius: radius,
        border: isMe ? null : Border.all(color: const Color(0xFFE6E8EE)),
        boxShadow: [
          if (!isMe)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: bubbleChild,
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }
}
