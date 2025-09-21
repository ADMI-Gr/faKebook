import 'package:fakebook/widgets/badge_tile.dart';
import 'package:fakebook/widgets/data_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import '../content/follow_screen.dart';
import '../content/blocked_users_screen.dart';
import '../content/user_list_screen.dart';

// ALMACENA los bytes de la img para DEMO, solo para visualizar
final tempAvatarProvider = StateProvider<Uint8List?>((ref) => null);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final tempBytes = ref.watch(tempAvatarProvider);
    final followersAsync = ref.watch(followersProvider);
    final followingAsync = ref.watch(followingProvider);

    if (user == null) {
      Future.microtask(() {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("@${user.username}"),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ira a la pantalla para acutalizar los datos
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Configuracion de perfil'),
                          onTap: () {
                            Navigator.pop(context);
                             Navigator.pushNamed(context, '/profile/edit');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.block),
                          title: const Text('Usuarios bloqueados'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
                          },
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.logout_sharp),
                          title: const Text(
                            'Cerrar sesión',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showLogoutDialog(context, ref);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final XFile? picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        // convierte el archivo seleccionado a bytes no se en q formato lo guardaran pero si es en bytes se enviaria asi
                        final bytes = await picked.readAsBytes();
                        // Aqui el path de la imagen seleccionada por si deciden usarlo con este
                        String urlImagen = picked.path;
                        ref.read(tempAvatarProvider.notifier).state = bytes;
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          //MUESTRA LA IMG TEMPORAL O LA FT DE PERFIL DEL USUARIO SI ES RECIBIDA DE user.avatarUrl
                          backgroundImage: tempBytes != null
                              ? MemoryImage(tempBytes) as ImageProvider<Object>
                              : (user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                      as ImageProvider<Object>
                                  : null),
                          backgroundColor: const Color(0xFF1976D2),
                          // Si no hay imagen (ni local demo, ni real) mostramos iniciales
                          child: (tempBytes == null && user.avatarUrl == null)
                              ? Text(
                                  user.displayName?.isNotEmpty == true
                                      ? user.displayName![0].toUpperCase()
                                      : user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1976D2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    user.displayName ?? user.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "@${user.username}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      user.bio!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn("Publicaciones", "0"),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => UserListScreen(
                              userId: user.id,
                              listType: UserListType.followers,
                              screenTitle: 'Seguidores',
                            ),
                          ));
                        },
                        child: _buildStatColumn(
                          "Seguidores",
                          followersAsync.when(
                            data: (list) => list.length.toString(),
                            loading: () => '...',
                            error: (e, s) => '-',
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const FollowScreen(),
                          ));
                        },
                        child: _buildStatColumn(
                          "Siguiendo",
                          followingAsync.when(
                            data: (list) => list.length.toString(),
                            loading: () => '...',
                            error: (e, s) => '-',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Datos del perfil de usuario, se muestran datos normales si no pertenece a ITCA
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 18, color: Colors.black87),
                            SizedBox(width: 8),
                            Text(
                              'Perfil de usuario',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        DataProfile(
                          title: 'Nombre',
                          subtitle: user.displayName ?? 'test',
                          icon: Icons.badge_outlined,
                        ),
                        DataProfile(
                          title: 'Correo electronico',
                          subtitle: user.email,
                          icon: Icons.alternate_email,
                        ),
                        ...(() {
                          final isItcaEmail = user.email.toLowerCase().endsWith('@itca.edu.sv');
                          if (!isItcaEmail) return <Widget>[];
                          final sede = user.metadata != null ? user.metadata!['sede'] : null;
                          final carrera = user.metadata != null ? user.metadata!['carrera'] : null;
                          final year = user.metadata != null ? user.metadata!['year'] : null;
                          return [
                            DataProfile(
                              title: 'Sede',
                              subtitle: sede?.toString() ?? 'No especificado',
                              icon: Icons.location_city_outlined,
                            ),
                            DataProfile(
                              title: 'Carrera',
                              subtitle: carrera?.toString() ?? 'No especificado',
                              icon: Icons.school_outlined,
                            ),
                            DataProfile(
                              title: 'Año',
                              subtitle: year?.toString() ?? 'No especificado',
                              icon: Icons.calendar_today_outlined,
                            ),
                          ];
                        }()),
                        DataProfile(
                          title: 'Biografia',
                          subtitle: (user.bio != null)
                              ? '${user.bio}'
                              : 'No hay biografia',
                          icon: Icons.grading_outlined,
                        ),

                        ...(() {
                          final isItcaEmail = user.email.toLowerCase().endsWith('@itca.edu.sv');
                          if (!isItcaEmail) return <Widget>[];
                          return [
                            const SizedBox(height: 8),
                            const Text(
                              'Insignias',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                // suponiendo q viene de metadata, en caso contrario se cambiara
                                // Ya que no se como se implementaran las insigneas solo se muestran parecidas al diseño de figma
                                BadgeTile(
                                    icon: Icons.diamond_outlined,
                                    active: user.metadata != null &&
                                        user.metadata!['mentor'] != null),
                                BadgeTile(
                                    icon: Icons.workspace_premium_outlined,
                                    active: user.metadata != null &&
                                        user.metadata!['mentor'] != null),
                                const BadgeTile(
                                    icon: Icons.diamond_outlined, active: true),
                                const BadgeTile(
                                    icon: Icons.diamond_outlined, active: true),
                                const BadgeTile(
                                    icon: Icons.workspace_premium_outlined,
                                    active: true),
                                BadgeTile(
                                    icon: Icons.diamond_outlined,
                                    active: user.metadata != null &&
                                        user.metadata!['mentor'] != null),
                              ],
                            ),
                          ];
                        }()),
                        
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 400,
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No hay publicaciones aún",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Cuando publiques algo, aparecerá aquí",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Fecha desconocida";
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  String _formatBirthDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Fecha no válida";
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cerrar sesión"),
          content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(logoutUserProvider.future);
                if (!context.mounted) return;

                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              child: const Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
