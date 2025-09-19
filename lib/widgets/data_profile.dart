import 'package:flutter/material.dart';

class DataProfile extends StatelessWidget {
  const DataProfile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: highlight ? Colors.amber[700] : null),
      title: Text(
        title,
        style: TextStyle(
          color: highlight ? Colors.amber[800] : null,
          fontWeight: highlight ? FontWeight.w600 : null,
        ),
      ),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
      trailing: highlight
          ? const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 18,
            )
          : null,
    );
  }
}