import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/widgets/badge_tile.dart';
import 'package:fakebook/widgets/badge_info_dialog.dart';
import 'package:fakebook/screens/content/other_user_profile_screen.dart';
import 'package:fakebook/screens/content/image_viewer_screen.dart';
import 'package:fakebook/providers/social_provider.dart';

// CLASE PARA EL ENCABEZADO DEL POST
class PostHeader extends StatelessWidget {
  const PostHeader({
    super.key,
    required this.author,
    required this.onMoreTap,
    this.belowRight,
  });

  final UserModel author;
  final VoidCallback onMoreTap;
  final Widget? belowRight;

  @override
  Widget build(BuildContext context) {
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
            // Insignias bajo la foto de perfil del usuario
            Column(
              children: [
                Row(
                  children: [
                    BadgeTile(
                      icon: Icons.verified,
                      active: true,
                      size: 24,
                      radius: 4,
                      tooltip: 'Verificado',
                      onTap: () => showBadgeInfoDialog(
                        context,
                        title: 'Usuario verificado',
                        description: 'Cuenta verificada.',
                        borderColor: Colors.blueAccent,
                        backgroundColor: Colors.white,
                        backgroundGradient: const LinearGradient(
                          colors: [Color(0xFFEAF2FF), Color(0xFFF5FAFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        titleTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        descriptionTextStyle: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                        icon: Icons.verified,
                      ),
                    ),
                    const SizedBox(width: 4),
                    BadgeTile(
                      icon: Icons.star,
                      active: false,
                      size: 24,
                      radius: 4,
                      tooltip: 'Estrella',
                      onTap: () => showBadgeInfoDialog(
                        context,
                        title: 'Usuario destacado',
                        description: 'Reconocimiento por contribuciones.',
                        borderColor: const Color.fromARGB(255, 159, 159, 156),
                        backgroundColor: Colors.white,
                        backgroundGradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 201, 205, 207),
                            Color.fromARGB(255, 241, 238, 235)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        titleTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        descriptionTextStyle: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                        icon: Icons.star,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    BadgeTile(
                      icon: Icons.flash_on,
                      active: true,
                      size: 24,
                      radius: 4,
                      tooltip: 'Rapido',
                      onTap: () => showBadgeInfoDialog(
                        context,
                        title: 'Respuesta rapida',
                        description: 'Responde con rapidez en la comunidad.',
                        borderColor: Colors.deepPurple,
                        backgroundColor: Colors.white,
                        backgroundGradient: const LinearGradient(
                          colors: [Color(0xFFF1E8FF), Color(0xFFFAEEFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        titleTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        descriptionTextStyle: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                        icon: Icons.flash_on,
                      ),
                    ),
                    const SizedBox(width: 4),
                    BadgeTile(
                      icon: Icons.favorite,
                      active: false,
                      size: 24,
                      radius: 4,
                      tooltip: 'Apoyo',
                      onTap: () => showBadgeInfoDialog(
                        context,
                        title: 'Apoyo a la comunidad',
                        description:
                            'Valora y apoya el contenido de la comunidad.',
                        borderColor: Colors.pinkAccent,
                        backgroundColor: Colors.white,
                        backgroundGradient: const LinearGradient(
                          colors: [Color(0xFFFFE6EB), Color(0xFFFFF2F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        titleTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        descriptionTextStyle: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                        icon: Icons.favorite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    BadgeTile(
                      icon: Icons.lock,
                      active: false,
                      size: 24,
                      radius: 4,
                      tooltip: 'Privacidad',
                      onTap: () => showBadgeInfoDialog(
                        context,
                        title: 'Privacidad',
                        description:
                            'Cuida la seguridad y privacidad de su cuenta.',
                        borderColor: Colors.grey,
                        backgroundColor: Colors.white,
                        backgroundGradient: const LinearGradient(
                          colors: [Color(0xFFF5F7FA), Color(0xFFE9EEF5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        titleTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        descriptionTextStyle: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                        icon: Icons.lock,
                      ),
                    ),
                    const SizedBox(width: 4),
                    BadgeTile(
                      icon: Icons.timelapse,
                      active: false,
                      size: 24,
                      radius: 4,
                      tooltip: 'Veterano',
                      onTap: () => showBadgeInfoDialog(
                        context,
                        title: 'Fiel usuario',
                        description:
                            'Un usuario fiel que ha estado con Fakebook desde el inicio.',
                        borderColor: Colors.blueGrey,
                        backgroundColor: Colors.white,
                        backgroundGradient: const LinearGradient(
                          colors: [Color(0xFFEAF7FF), Color(0xFFF2FDFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        titleTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        descriptionTextStyle: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                        icon: Icons.timelapse,
                      ),
                    ),
                  ],
                ),
              ],
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
                          // Insignias entre el displayname y el username
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  BadgeTile(
                                    icon: Icons.emergency,
                                    active: true,
                                    size: 18,
                                    radius: 3,
                                    tooltip: 'Distintivo 1',
                                    onTap: () => showBadgeInfoDialog(
                                      context,
                                      title: 'Distintivo 1',
                                      description:
                                          'Descripción del distintivo 1.',
                                      borderColor: const Color(0xFF1976D2),
                                      backgroundColor: Colors.white,
                                      backgroundGradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFEAF2FF),
                                          Color(0xFFF5FAFF)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      titleTextStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      descriptionTextStyle: const TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        color: Colors.black87,
                                      ),
                                      icon: Icons.emergency,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  BadgeTile(
                                    icon: Icons.emergency,
                                    active: true,
                                    size: 18,
                                    radius: 3,
                                    tooltip: 'Distintivo 2',
                                    onTap: () => showBadgeInfoDialog(
                                      context,
                                      title: 'Distintivo 2',
                                      description:
                                          'Descripción del distintivo 2.',
                                      borderColor: const Color(0xFF1976D2),
                                      backgroundColor: Colors.white,
                                      backgroundGradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFEAF2FF),
                                          Color(0xFFF5FAFF)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      titleTextStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      descriptionTextStyle: const TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        color: Colors.black87,
                                      ),
                                      icon: Icons.emergency,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  BadgeTile(
                                    icon: Icons.emergency,
                                    active: true,
                                    size: 18,
                                    radius: 3,
                                    tooltip: 'Distintivo 3',
                                    onTap: () => showBadgeInfoDialog(
                                      context,
                                      title: 'Distintivo 3',
                                      description:
                                          'Descripcion del distintivo 3.',
                                      borderColor: const Color(0xFF1976D2),
                                      backgroundColor: Colors.white,
                                      backgroundGradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFEAF2FF),
                                          Color(0xFFF5FAFF)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      icon: Icons.emergency,
                                    ),
                                  ),
                                ],
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
