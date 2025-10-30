import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/widgets/badge_widget.dart';
import 'package:fakebook/providers/badge_provider.dart';
import 'package:fakebook/screens/content/other_user_profile_screen.dart';
import 'package:fakebook/screens/content/image_viewer_screen.dart';

// Widget para mostrar un distintivo (sede, carrera, año)
class DistinctiveWidget extends StatelessWidget {
  const DistinctiveWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.size = 18,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size * 0.6),
    );

    return Tooltip(
      message: label,
      child: tile,
    );
  }
}

// CLASE PARA EL ENCABEZADO DEL POST
class PostHeader extends ConsumerWidget {
  const PostHeader({
    super.key,
    required this.author,
    required this.onMoreTap,
    this.belowRight,
  });

  final UserModel author;
  final VoidCallback onMoreTap;
  final Widget? belowRight;

  // Función para obtener el ícono y color de sede
  Map<String, dynamic> _getSedeData(String? sede) {
    if (sede == null) return {};
    final sedeLower = sede.toLowerCase();
    const sedeColor = Color(0xFFcf9212);

    if (sedeLower.contains('santa tecla')) {
      return {'icon': Icons.business, 'color': sedeColor};
    }
    if (sedeLower.contains('san miguel')) {
      return {'icon': Icons.location_city, 'color': sedeColor};
    }
    if (sedeLower.contains('santa ana')) {
      return {'icon': Icons.account_balance, 'color': sedeColor};
    }
    return {'icon': Icons.location_city, 'color': sedeColor};
  }

  // Función para obtener el ícono y color de carrera
  Map<String, dynamic> _getCarreraData(String? carrera) {
    if (carrera == null) return {};
    final carreraLower = carrera.toLowerCase();

    if (carreraLower.contains('civil')) {
      return {'icon': Icons.construction, 'color': const Color(0xFF8B0000)};
    }
    if (carreraLower.contains('desarrollo') ||
        carreraLower.contains('software')) {
      return {'icon': Icons.code, 'color': const Color(0xFF2196F3)};
    }
    if (carreraLower.contains('eléctrica') ||
        carreraLower.contains('electrica')) {
      return {
        'icon': Icons.electrical_services,
        'color': const Color(0xFFFFC107)
      };
    }
    return {'icon': Icons.school, 'color': const Color(0xFF2196F3)};
  }

  // Función para obtener el color del año (de claro a oscuro)
  Color _getYearColor(String? year) {
    if (year == null || year.isEmpty) return const Color(0xFFcf9212);

    // Extraer el número del año
    final yearNumber = int.tryParse(year.split('°').first.trim()) ?? 1;

    // Escala de colores de claro a oscuro (#cf9212)
    // Base: #cf9212 (207, 146, 18)
    final baseR = 207;
    final baseG = 146;
    final baseB = 18;

    // Calcular el factor de oscurecimiento (1° = más claro, 5° = más oscuro)
    final factor = (yearNumber - 1) / 4; // 0.0 para 1°, 1.0 para 5°

    // Interpolar desde un color más claro hasta el color base
    final lightR = 255;
    final lightG = 220;
    final lightB = 150;

    final r = (lightR + (baseR - lightR) * factor).round().clamp(0, 255);
    final g = (lightG + (baseG - lightG) * factor).round().clamp(0, 255);
    final b = (lightB + (baseB - lightB) * factor).round().clamp(0, 255);

    return Color.fromRGBO(r, g, b, 1.0);
  }

  // Función para obtener los distintivos del usuario
  List<Widget> _buildDistinctives() {
    final metadata = author.metadata;
    if (metadata == null) return [];

    final distintivos = <Widget>[];

    // Sede
    final sede = metadata['sede'] as String?;
    if (sede != null && sede.isNotEmpty) {
      final sedeData = _getSedeData(sede);
      if (sedeData.isNotEmpty) {
        distintivos.add(
          DistinctiveWidget(
            icon: sedeData['icon'],
            label: sede,
            color: sedeData['color'],
          ),
        );
      }
    }

    // Carrera
    final carrera = metadata['carrera'] as String?;
    if (carrera != null && carrera.isNotEmpty) {
      final carreraData = _getCarreraData(carrera);
      if (carreraData.isNotEmpty) {
        distintivos.add(
          DistinctiveWidget(
            icon: carreraData['icon'],
            label: carrera,
            color: carreraData['color'],
          ),
        );
      }
    }

    // Año
    final year = metadata['year'] as String?;
    if (year != null && year.isNotEmpty) {
      // Extraer el número del año
      final yearNumber = year.split('°').first.trim();
      distintivos.add(
        DistinctiveWidget(
          icon: Icons.looks_one, // Se podría cambiar según el número
          label: year,
          color: _getYearColor(year),
        ),
      );
    }

    return distintivos;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener las insignias destacadas del autor del post
    final featuredBadgesAsync =
        ref.watch(userFeaturedBadgeModelsProvider(author.id));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                final url = author.avatarUrl;
                if (url != null && url.isNotEmpty) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => ImageViewerScreen(
                        imageUrl: url,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este usuario no tiene foto de perfil.'),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 20,
                backgroundImage:
                    (author.avatarUrl != null && author.avatarUrl!.isNotEmpty)
                        ? NetworkImage(author.avatarUrl!)
                        : null,
                backgroundColor:
                    (author.avatarUrl != null && author.avatarUrl!.isNotEmpty)
                        ? Colors.transparent
                        : Colors.grey[300],
                child: (author.avatarUrl == null || author.avatarUrl!.isEmpty)
                    ? Text(
                        author.displayName?.isNotEmpty == true
                            ? author.displayName![0].toUpperCase()
                            : author.username.isNotEmpty
                                ? author.username[0].toUpperCase()
                                : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // Insignias bajo la foto de perfil del usuario (dinámicas)
            featuredBadgesAsync.when(
              data: (badges) {
                if (badges.isEmpty) return const SizedBox.shrink();

                // Mostrar hasta 6 insignias en formato 2x3
                final displayBadges = badges.take(6).toList();

                return Column(
                  children: [
                    // Primera fila (2 insignias)
                    if (displayBadges.isNotEmpty)
                      Row(
                        children: [
                          if (displayBadges.length > 0)
                            BadgeWidget(
                              badge: displayBadges[0],
                              size: 24,
                              radius: 4,
                            ),
                          if (displayBadges.length > 1) ...[
                            const SizedBox(width: 4),
                            BadgeWidget(
                              badge: displayBadges[1],
                              size: 24,
                              radius: 4,
                            ),
                          ],
                        ],
                      ),
                    // Segunda fila (2 insignias)
                    if (displayBadges.length > 2) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          BadgeWidget(
                            badge: displayBadges[2],
                            size: 24,
                            radius: 4,
                          ),
                          if (displayBadges.length > 3) ...[
                            const SizedBox(width: 4),
                            BadgeWidget(
                              badge: displayBadges[3],
                              size: 24,
                              radius: 4,
                            ),
                          ],
                        ],
                      ),
                    ],
                    // Tercera fila (2 insignias)
                    if (displayBadges.length > 4) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          BadgeWidget(
                            badge: displayBadges[4],
                            size: 24,
                            radius: 4,
                          ),
                          if (displayBadges.length > 5) ...[
                            const SizedBox(width: 4),
                            BadgeWidget(
                              badge: displayBadges[5],
                              size: 24,
                              radius: 4,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                );
              },
              loading: () => const SizedBox(
                width: 24,
                height: 24,
                child: SizedBox.shrink(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Info derecha (nombre/usuario y boton de mas)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${author.displayName ?? author.username} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OtherUserProfileScreen(
                                      userId: author.id,
                                    ),
                                  ),
                                );
                              },
                          ),
                          // Distintivos entre el displayname y el username
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Builder(
                                builder: (context) {
                                  final distintivos = _buildDistinctives();
                                  if (distintivos.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: distintivos
                                        .asMap()
                                        .entries
                                        .map((entry) => Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (entry.key > 0)
                                                  const SizedBox(width: 5),
                                                entry.value,
                                              ],
                                            ))
                                        .toList(),
                                  );
                                },
                              ),
                            ),
                          ),
                          TextSpan(
                            text: '@${author.username}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OtherUserProfileScreen(
                                      userId: author.id,
                                    ),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onMoreTap,
                    borderRadius: BorderRadius.circular(20),
                    splashColor: Colors.grey.withOpacity(0.2),
                    child: const Icon(Icons.more_vert,
                        size: 20, color: Colors.grey),
                  ),
                ],
              ),
              if (belowRight != null) ...[
                const SizedBox(height: 4),
                belowRight!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
