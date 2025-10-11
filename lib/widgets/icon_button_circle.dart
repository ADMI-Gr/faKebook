import 'package:flutter/material.dart';

class IconButtonCircle extends StatelessWidget {
  const IconButtonCircle({
    super.key,
    required this.icon,
    this.color,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final Color? color;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Colors.white;
    final ic = iconColor ?? Colors.black87;
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, size: 20, color: ic),
        ),
      ),
    );
  }
}
