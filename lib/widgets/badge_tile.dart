import 'package:flutter/material.dart';

class BadgeTile extends StatelessWidget {
  final IconData icon;
  final bool active;
  final double size; 
  final double radius; 
  final VoidCallback? onTap;
  final String? tooltip;
  final Gradient? backgroundGradient;

  const BadgeTile({
    super.key,
    required this.icon,
    this.active = false,
    this.size = 48,
    this.radius = 12,
    this.onTap,
    this.tooltip,
    this.backgroundGradient,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = active ? const Color(0xFF1976D2) : Colors.white;
    final Color fg = active ? Colors.white : Colors.black87;

    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundGradient == null ? bg : null,
        gradient: backgroundGradient,
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

    Widget tappable = tile;
    if (onTap != null) {
      tappable = InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: tile,
      );
    }

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: tappable);
    }
    return tappable;
  }
}