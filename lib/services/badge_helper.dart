import 'package:flutter/material.dart';

/// Helper class para convertir y parsear datos de insignias
class BadgeHelpers {
  /// Convierte un color hex string a Color
  static Color parseColor(String? colorHex,
      {Color defaultColor = Colors.grey}) {
    if (colorHex == null || colorHex.isEmpty) return defaultColor;

    try {
      final hexColor = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return defaultColor;
    }
  }

  /// Convierte un fontType string a FontWeight
  static FontWeight parseFontWeight(String? fontType) {
    switch (fontType?.toLowerCase()) {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
        return FontWeight.normal;
      case 'light':
        return FontWeight.w300;
      case 'medium':
        return FontWeight.w500;
      case 'semibold':
        return FontWeight.w600;
      default:
        return FontWeight.normal;
    }
  }

  /// Convierte una lista de colores hex a Gradient
  static Gradient? parseGradient(List<String>? gradientColors) {
    if (gradientColors == null || gradientColors.length < 2) return null;

    try {
      final colors = gradientColors.map((hex) => parseColor(hex)).toList();
      return LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } catch (e) {
      return null;
    }
  }

  /// Convierte un string de nombre de ícono a IconData
  /// Soporta los íconos más comunes de Material Icons
  static IconData parseIcon(String? iconName,
      {IconData defaultIcon = Icons.star}) {
    if (iconName == null || iconName.isEmpty) return defaultIcon;

    // Mapa de nombres de íconos comunes a IconData
    final iconMap = <String, IconData>{
      // Verificación y estado
      'verified': Icons.verified,
      'check_circle': Icons.check_circle,
      'shield': Icons.shield,

      // Estrellas y premios
      'star': Icons.star,
      'star_outline': Icons.star_outline,
      'stars': Icons.stars,
      'emoji_events': Icons.emoji_events,
      'workspace_premium': Icons.workspace_premium,
      'military_tech': Icons.military_tech,

      // Velocidad y actividad
      'flash_on': Icons.flash_on,
      'bolt': Icons.bolt,
      'speed': Icons.speed,
      'rocket_launch': Icons.rocket_launch,

      // Corazón y favoritos
      'favorite': Icons.favorite,
      'favorite_outline': Icons.favorite_outline,
      'volunteer_activism': Icons.volunteer_activism,

      // Seguridad
      'lock': Icons.lock,
      'security': Icons.security,
      'verified_user': Icons.verified_user,

      // Tiempo
      'timelapse': Icons.timelapse,
      'schedule': Icons.schedule,
      'access_time': Icons.access_time,
      'history': Icons.history,

      // Fuego y energía
      'local_fire_department': Icons.local_fire_department,
      'whatshot': Icons.whatshot,

      // Corona y realeza
      'auto_awesome': Icons.auto_awesome,
      'diamond': Icons.diamond,

      // Social
      'people': Icons.people,
      'group': Icons.group,
      'forum': Icons.forum,
      'chat': Icons.chat,

      // Educación
      'school': Icons.school,
      'menu_book': Icons.menu_book,
      'library_books': Icons.library_books,

      // Creatividad
      'palette': Icons.palette,
      'brush': Icons.brush,
      'color_lens': Icons.color_lens,

      // Tecnología
      'computer': Icons.computer,
      'code': Icons.code,
      'developer_mode': Icons.developer_mode,

      // Emergencia (del ejemplo)
      'emergency': Icons.emergency,

      // Deportes
      'sports_esports': Icons.sports_esports,
      'sports_soccer': Icons.sports_soccer,

      // Música
      'music_note': Icons.music_note,
      'audiotrack': Icons.audiotrack,

      // Otros comunes
      'build': Icons.build,
      'lightbulb': Icons.lightbulb,
      'thumb_up': Icons.thumb_up,
      'celebration': Icons.celebration,
      'cake': Icons.cake,
      'card_giftcard': Icons.card_giftcard,
    };

    // Buscar el ícono en el mapa (case insensitive)
    final icon = iconMap[iconName.toLowerCase()];
    return icon ?? defaultIcon;
  }
}
