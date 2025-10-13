import 'package:fakebook/providers/profile_provider.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import 'package:fakebook/screens/content/post_publish_screen.dart';
import 'package:fakebook/widgets/badge_tile.dart';
import 'package:fakebook/widgets/badge_info_dialog.dart';
import 'package:fakebook/widgets/data_profile.dart';
import 'package:fakebook/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import '../content/follow_screen.dart';
import '../content/blocked_users_screen.dart';
import '../content/user_list_screen.dart';
import 'package:fakebook/screens/content/image_viewer_screen.dart';

final tempAvatarProvider = StateProvider<Uint8List?>((ref) => null);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Color _getColorFromInitial(String initial) {
    final colors = {
      'A': const Color(0xFFE91E63), // Rosa
      'B': const Color(0xFF9C27B0), // Púrpura
      'C': const Color(0xFF673AB7), // Púrpura oscuro
      'D': const Color(0xFF3F51B5), // Índigo
      'E': const Color(0xFF2196F3), // Azul
      'F': const Color(0xFF03A9F4), // Azul claro
      'G': const Color(0xFF00BCD4), // Cian
      'H': const Color(0xFF009688), // Verde azulado
      'I': const Color(0xFF4CAF50), // Verde
      'J': const Color(0xFF8BC34A), // Verde claro
      'K': const Color(0xFFCDDC39), // Lima
      'L': const Color(0xFFFFEB3B), // Amarillo
      'M': const Color(0xFFFFC107), // Ámbar
      'N': const Color(0xFFFF9800), // Naranja
      'O': const Color(0xFFFF5722), // Naranja oscuro
      'P': const Color(0xFFF44336), // Rojo
      'Q': const Color(0xFFE91E63), // Rosa
      'R': const Color(0xFF9C27B0), // Púrpura
      'S': const Color(0xFF673AB7), // Púrpura oscuro
      'T': const Color(0xFF3F51B5), // Índigo
      'U': const Color(0xFF2196F3), // Azul
      'V': const Color(0xFF00BCD4), // Cian
      'W': const Color(0xFF009688), // Verde azulado
      'X': const Color(0xFF4CAF50), // Verde
      'Y': const Color(0xFFFF9800), // Naranja
      'Z': const Color(0xFFFF5722), // Naranja oscuro
    };

    return colors[initial.toUpperCase()] ?? const Color(0xFF1976D2);
  }

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

    final myPostsAsync = ref.watch(userPostsProvider(user.id));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("@${user.username}"),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const BlockedUsersScreen()));
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
                      // Mostrar opciones: cambiar o eliminar
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 16),
                                const Text(
                                  'Foto de perfil',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListTile(
                                  leading: const Icon(Icons.remove_red_eye,
                                      color: Color(0xFF1976D2)),
                                  title: const Text('Ver foto'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    final url = user.avatarUrl;
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
                                          content: Text('Aún no tienes foto de perfil'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library,
                                      color: Color(0xFF1976D2)),
                                  title: const Text('Cambiar foto'),
                                  onTap: () async {
                                    Navigator.pop(context);

                                    final picker = ImagePicker();
                                    final XFile? picked =
                                        await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85,
                                    );

                                    if (picked != null) {
                                      // Mostrar preview inmediato
                                      final bytes = await picked.readAsBytes();
                                      ref
                                          .read(tempAvatarProvider.notifier)
                                          .state = bytes;

                                      // Mostrar loading
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Row(
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                ),
                                                SizedBox(width: 16),
                                                Text('Subiendo imagen...'),
                                              ],
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }

                                      // Subir a Supabase
                                      try {
                                        final profileRepo = ProfileRepository();
                                        await profileRepo.updateAvatar(
                                            user.id, picked.path);

                                        // Refrescar el usuario
                                        await ref.refresh(
                                            refreshCurrentUserProvider.future);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Foto de perfil actualizada'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }

                                        // Limpiar preview temporal
                                        ref
                                            .read(tempAvatarProvider.notifier)
                                            .state = null;
                                      } catch (e) {
                                        // Revertir preview en caso de error
                                        ref
                                            .read(tempAvatarProvider.notifier)
                                            .state = null;

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error al subir imagen: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                                if (user.avatarUrl != null)
                                  ListTile(
                                    leading: const Icon(Icons.delete,
                                        color: Colors.red),
                                    title: const Text('Eliminar foto'),
                                    onTap: () async {
                                      Navigator.pop(context);

                                      try {
                                        // Establecer avatar_url como null en la BD
                                        final profileRepo = ProfileRepository();
                                        await profileRepo.updateUserProfile(
                                          user.id,
                                          avatarUrl: null,
                                        );

                                        // Limpiar preview temporal
                                        ref
                                            .read(tempAvatarProvider.notifier)
                                            .state = null;

                                        // Refrescar usuario
                                        await ref.refresh(
                                            refreshCurrentUserProvider.future);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Foto de perfil eliminada'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error al eliminar foto: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: tempBytes != null
                              ? MemoryImage(tempBytes) as ImageProvider<Object>
                              : (user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null),
                          backgroundColor:
                              tempBytes == null && user.avatarUrl == null
                                  ? _getColorFromInitial(
                                      user.displayName?.isNotEmpty == true
                                          ? user.displayName![0]
                                          : user.username[0])
                                  : const Color(0xFF1976D2),
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
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
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
                  const SizedBox(height: 12),
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
                      _buildStatColumn(
                          "Publicaciones",
                          myPostsAsync.when(
                              data: (posts) => posts.length.toString(),
                              loading: () => '...',
                              error: (e, s) => '-')),
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
                          final isItcaEmail =
                              user.email.toLowerCase().endsWith('@itca.edu.sv');
                          if (!isItcaEmail) return <Widget>[];
                          final sede = user.metadata != null
                              ? user.metadata!['sede']
                              : null;
                          final carrera = user.metadata != null
                              ? user.metadata!['carrera']
                              : null;
                          final year = user.metadata != null
                              ? user.metadata!['year']
                              : null;
                          return [
                            DataProfile(
                              title: 'Sede',
                              subtitle: sede?.toString() ?? 'No especificado',
                              icon: Icons.location_city_outlined,
                            ),
                            DataProfile(
                              title: 'Carrera',
                              subtitle:
                                  carrera?.toString() ?? 'No especificado',
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
                          final isItcaEmail =
                              user.email.toLowerCase().endsWith('@itca.edu.sv');
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
                                //INSIGNIAS DEL PERFIL PROPIO
                                BadgeTile(
                                  icon: Icons.verified,
                                  active: true,
                                  tooltip: 'Verificado',
                                  onTap: () => showBadgeInfoDialog(
                                    context,
                                    title: 'Usuario verificado',
                                    description: 'Cuenta verificada.',
                                    backgroundColor: Colors.white,
                                    backgroundGradient: const LinearGradient(
                                      colors: [Color(0xFFEAF2FF), Color(0xFFF5FAFF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    icon: Icons.verified,

                                    //PARAMETROS ASIGNABLES DE ESTILO (los demas tambien lo tienen para asignar)
                                    borderColor: Colors.blueAccent,
                                    titleTextStyle: const TextStyle(
                                      color: Color.fromARGB(255, 27, 51, 76),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    descriptionTextStyle: const TextStyle(
                                      color: Color.fromARGB(255, 27, 51, 76),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                BadgeTile(
                                  icon: Icons.star,
                                  active: false,
                                  tooltip: 'Estrella',
                                  onTap: () => showBadgeInfoDialog(
                                    context,
                                    title: 'Usuario destacado',
                                    description: 'Reconocimiento por contribuciones.',
                                    borderColor: Color.fromARGB(255, 159, 159, 156),
                                    backgroundColor: Colors.white,
                                    backgroundGradient: const LinearGradient(
                                      colors: [Color.fromARGB(255, 201, 205, 207), Color.fromARGB(255, 241, 238, 235)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    icon: Icons.star,
                                  ),
                                ),
                                BadgeTile(
                                  icon: Icons.flash_on,
                                  active: true,
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
                                    icon: Icons.flash_on,
                                  ),
                                ),
                                BadgeTile(
                                  icon: Icons.favorite,
                                  active: false,
                                  tooltip: 'Apoyo',
                                  onTap: () => showBadgeInfoDialog(
                                    context,
                                    title: 'Apoyo a la comunidad',
                                    description: 'Valora y apoya el contenido de la comunidad.',
                                    borderColor: Colors.pinkAccent,
                                    backgroundColor: Colors.white,
                                    backgroundGradient: const LinearGradient(
                                      colors: [Color(0xFFFFE6EB), Color(0xFFFFF2F5)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    icon: Icons.favorite,
                                  ),
                                ),
                                BadgeTile(
                                  icon: Icons.lock,
                                  active: false,
                                  tooltip: 'Privacidad',
                                  onTap: () => showBadgeInfoDialog(
                                    context,
                                    title: 'Privacidad',
                                    description: 'Cuida la seguridad y privacidad de su cuenta.',
                                    borderColor: Colors.grey,
                                    backgroundColor: Colors.white,
                                    backgroundGradient: const LinearGradient(
                                      colors: [Color(0xFFF5F7FA), Color(0xFFE9EEF5)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    icon: Icons.lock,
                                  ),
                                ),
                                BadgeTile(
                                  icon: Icons.timelapse,
                                  active: false,
                                  tooltip: 'Veterano',
                                  onTap: () => showBadgeInfoDialog(
                                    context,
                                    title: 'Fiel usuario',
                                    description: 'Un usuario fiel que ha estado con Fakebook desde el inicio.',
                                    borderColor: Colors.blueGrey,
                                    backgroundColor: Colors.white,
                                    backgroundGradient: const LinearGradient(
                                      colors: [Color(0xFFEAF7FF), Color(0xFFF2FDFF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    icon: Icons.timelapse,
                                  ),
                                ),
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

          // Espaciado
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          myPostsAsync.when(
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(
                child: Center(child: Text('Error al cargar posts: $e'))),
            data: (posts) {
              if (posts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 48, horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.post_add_outlined,
                          size: 64,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aun no has publicado nada',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¡Comparte tu primer post y empieza a interactuar!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PostPublishScreen()));
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text("Crear mi primer post",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final postItems = posts
                  .map((post) => (
                        post: post,
                        author: user,
                        isMine: true,
                      ))
                  .toList();
              return PostList(posts: postItems);
            },
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
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text("Cerrar sesión"),
            ),
          ],
        );
      },
    );
  }
}
