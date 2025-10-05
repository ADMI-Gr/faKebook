import 'package:fakebook/screens/content/post_publish_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/social_provider.dart';
import 'package:fakebook/screens/content/post_detail_screen.dart';
import 'package:fakebook/widgets/post_actions.dart';
import 'package:fakebook/widgets/expandable_text.dart';
import 'package:fakebook/widgets/post_header.dart';
import 'package:fakebook/widgets/post_media.dart';

// AQUI SE RECIBE LA LISTA DE LOS POSTS DESDE EL DASHBOARD
class PostList extends StatelessWidget {
  final List<({PostModel post, UserModel author, bool isMine})> posts;

  const PostList({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Todavia no hay publicaciones!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Animate a ser el primero en publicar\n'
                    'o comienza a seguir a tus amigos para ver sus posts.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PostPublishScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                    label: const Text(
                      'Crear tu primera publicacion',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final p = posts[index];
          return _PostCard(
            post: p.post,
            author: p.author,
            isMine: p.isMine,
            key: ValueKey(p.post.id),
          );
        },
        childCount: posts.length,
      ),
    );
  }
}

// CLASE PARA EL POST Y SU DISEÑO
class _PostCard extends ConsumerWidget {
  final PostModel post;
  final UserModel author;
  final bool isMine;

  const _PostCard({
    super.key,
    required this.post,
    required this.author,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SE MOVIO AL ARCHIVO post_header.dart
                PostHeader(
                  author: author,
                  onMoreTap: () => _showPostOptions(context, ref),
                  belowRight: InkWell(
                    onTap: () {
                      Navigator.push( 
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            post: post,
                            author: author,
                            isMine: isMine,
                          ),
                        ),
                      );
                    },
                    child: ExpandableText(text: post.content ?? ''),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (post.contentJson['image_url'] != null &&
              post.contentJson['image_url'].isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              // SE MOVIO AL ARCHIVO post_media.dart
              child: PostMedia(
                imageUrl: post.contentJson['image_url'],
                heroTag: 'post-image-${post.id}',
              ),
            ),
          ],
          const SizedBox(height: 10),
          //SE MOVIO AL ARCHIVO post_actions.dart
          PostActions(post: post, author: author, isMine: isMine),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  //OPCIONES DEL POST BOTON DE LOS 3 PUNTITOS
  void _showPostOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Guardar publicacion'),
                onTap: () {
                  Navigator.pop(ctx);
                  // AQUI IRA LA LOGICA PARA GUARDAR LA PUBLICACION EN EL FUTURO
                },
              ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Editar publicación'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostPublishScreen(postToEdit: post),
                      ),
                    );
                  },
                ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text(
                    'Eliminar publicacion',
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await showDialog(
                      context: context,
                      builder: (dCtx) {
                        return AlertDialog(
                          title: const Text('Eliminar publicacion'),
                          content: const Text(
                              '¿Estos seguro que deseas eliminar esta publicacion? Esta acción no se puede deshacer.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.redAccent),
                              onPressed: () {
                                // Call the delete post provider
                                ref
                                    .read(deletePostProvider(post.id).future)
                                    .then((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Publicación eliminada')),
                                  );
                                }).catchError((e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Error al eliminar: $e')),
                                  );
                                });
                                Navigator.pop(dCtx);
                              },
                              child: const Text('Eliminar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}
