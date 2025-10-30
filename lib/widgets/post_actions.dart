import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/models/post_model.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/screens/content/post_detail_screen.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:share_plus/share_plus.dart';

// Acciones del post: Me gusta, Comentar, Compartir
class PostActions extends ConsumerWidget {
  const PostActions({
    super.key,
    required this.post,
    required this.author,
    required this.isMine,
  });

  final PostModel post;
  final UserModel author;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener conteo de reacciones
    final reactionCountsAsync = ref.watch(reactionCountsProvider((
      targetType: 'post',
      targetId: post.id,
    )));

    // Obtener reacción del usuario actual
    final userReactionAsync = ref.watch(userReactionProvider((
      targetType: 'post',
      targetId: post.id,
    )));

    // Obtener conteo de comentarios
    final commentCountAsync = ref.watch(commentCountProvider(post.id));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Botón Me gusta
          Expanded(
            child: userReactionAsync.when(
              data: (userReaction) {
                final hasLiked = userReaction == 'like';

                return reactionCountsAsync.when(
                  data: (counts) {
                    final likeCount = counts['like'] ?? 0;

                    return _buildActionButton(
                      hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      'Me gusta${likeCount > 0 ? ' ($likeCount)' : ''}',
                      hasLiked ? const Color(0xFF6C63FF) : null,
                      () async {
                        try {
                          await ref.read(toggleReactionProvider((
                            targetType: 'post',
                            targetId: post.id,
                            reactionType: 'like',
                          )).future);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                  loading: () => _buildActionButton(
                    hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    'Me gusta',
                    hasLiked ? const Color(0xFF6C63FF) : null,
                    () {},
                  ),
                  error: (_, __) => _buildActionButton(
                    hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    'Me gusta',
                    hasLiked ? const Color(0xFF6C63FF) : null,
                    () {},
                  ),
                );
              },
              loading: () => _buildActionButton(
                Icons.thumb_up_outlined,
                'Me gusta',
                null,
                () {},
              ),
              error: (_, __) => _buildActionButton(
                Icons.thumb_up_outlined,
                'Me gusta',
                null,
                () {},
              ),
            ),
          ),

          // Botón Comentar
          Expanded(
            child: commentCountAsync.when(
              data: (count) => _buildActionButton(
                Icons.chat_bubble_outline,
                'Comentar${count > 0 ? ' ($count)' : ''}',
                null,
                () {
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
              ),
              loading: () => _buildActionButton(
                Icons.chat_bubble_outline,
                'Comentar',
                null,
                () {},
              ),
              error: (_, __) => _buildActionButton(
                Icons.chat_bubble_outline,
                'Comentar',
                null,
                () {},
              ),
            ),
          ),

          // Botón Compartir
          Expanded(
            child: _buildActionButton(
              Icons.share_outlined,
              'Compartir',
              null,
              () => _handleShare(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color? color,
    VoidCallback onTap,
  ) {
    final iconColor = color ?? Colors.grey[600]!;
    final textColor = color ?? Colors.grey[600]!;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.grey.withOpacity(0.2),
        highlightColor: Colors.grey.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleShare(BuildContext context) {
    // Generar el deep link del post
    final postUrl = 'fakebook://post/${post.id}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.copy, color: Color(0xFF6C63FF)),
              title: const Text('Copiar enlace'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: postUrl));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enlace copiado al portapapeles'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF6C63FF)),
              title: const Text('Compartir enlace'),
              onTap: () {
                Navigator.pop(context);
                Share.share(
                  'Mira esta publicación de ${author.displayName} en Fakebook:\n$postUrl',
                  subject: 'Publicación de ${author.displayName}',
                );
              },
            ),
            if (post.content != null && post.content!.isNotEmpty)
              ListTile(
                leading:
                    const Icon(Icons.text_fields, color: Color(0xFF6C63FF)),
                title: const Text('Copiar texto'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    '${author.displayName}: ${post.content}',
                    subject: 'Publicación de ${author.displayName}',
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
