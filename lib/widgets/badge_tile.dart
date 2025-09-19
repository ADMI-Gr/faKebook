import 'package:flutter/material.dart';

class BadgeTile extends StatelessWidget {
  final IconData icon;
  final bool active;
  final double size; 
  final double radius; 

  const BadgeTile({
    super.key,
    required this.icon,
    this.active = false,
    this.size = 48,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = active ? const Color(0xFF1976D2) : Colors.white;
    final Color fg = active ? Colors.white : Colors.black87;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: size * 0.54),
    );
  }
}