import 'package:flutter/material.dart';
import 'package:fakebook/models/badge_model.dart';
import 'package:fakebook/widgets/badge_tile.dart';
import 'package:fakebook/widgets/badge_info_dialog.dart';
import 'package:fakebook/services/badge_helper.dart';

/// Widget que renderiza una insignia desde un BadgeModel
class BadgeWidget extends StatelessWidget {
  final BadgeModel badge;
  final double size;
  final double radius;
  final bool showDialog;

  const BadgeWidget({
    super.key,
    required this.badge,
    this.size = 48,
    this.radius = 12,
    this.showDialog = true,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = badge.metadata;
    final icon = BadgeHelpers.parseIcon(
      metadata?.iconName,
      defaultIcon: Icons.star,
    );
    final borderColor = BadgeHelpers.parseColor(
      metadata?.borderColor,
      defaultColor: const Color(0xFF1976D2),
    );
    final backgroundColor = BadgeHelpers.parseColor(
      metadata?.backgroundColor,
      defaultColor: Colors.white,
    );
    final gradient = BadgeHelpers.parseGradient(metadata?.gradientColors);

    return BadgeTile(
      icon: icon,
      active: true,
      size: size,
      radius: radius,
      tooltip: badge.name,
      backgroundGradient: gradient,
      onTap: showDialog
          ? () => showBadgeInfoDialog(
                context,
                title: badge.name,
                description: badge.description,
                borderColor: borderColor,
                backgroundColor: backgroundColor,
                backgroundGradient: gradient,
                icon: icon,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: null,
                ),
                descriptionTextStyle: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: Colors.black87,
                ),
              )
          : null,
    );
  }
}

/// Widget para mostrar las insignias destacadas de un usuario
class UserFeaturedBadgesRow extends StatelessWidget {
  final List<BadgeModel> badges;
  final double badgeSize;
  final double spacing;
  final int maxBadges;

  const UserFeaturedBadgesRow({
    super.key,
    required this.badges,
    this.badgeSize = 24,
    this.spacing = 4,
    this.maxBadges = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    final displayBadges = badges.take(maxBadges).toList();

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: displayBadges
          .map((badge) => BadgeWidget(
                badge: badge,
                size: badgeSize,
                radius: 4,
              ))
          .toList(),
    );
  }
}

/// Widget para mostrar insignias en una grilla (para perfiles)
class BadgeGrid extends StatelessWidget {
  final List<BadgeModel> badges;
  final double badgeSize;
  final double spacing;
  final int crossAxisCount;

  const BadgeGrid({
    super.key,
    required this.badges,
    this.badgeSize = 48,
    this.spacing = 12,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No hay insignias para mostrar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: badges
          .map((badge) => BadgeWidget(
                badge: badge,
                size: badgeSize,
                radius: 12,
              ))
          .toList(),
    );
  }
}
