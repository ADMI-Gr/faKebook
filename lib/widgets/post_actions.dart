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

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      double k = count / 1000.0;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    }
    double m = count / 1000000.0;
    return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}M';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener reacción del usuario actual
    final userReactionAsync = ref.watch(userReactionProvider((
      targetType: 'post',
      targetId: post.id,
    )));

    // Obtener contadores de reacciones y comentarios
    final reactionCountsAsync = ref.watch(reactionCountsProvider((
      targetType: 'post',
      targetId: post.id,
    )));
    final commentCountAsync = ref.watch(commentCountProvider(post.id));

    final likeCount = reactionCountsAsync.when(
        data: (counts) => counts['like'] ?? 0, loading: () => 0, error: (_, __) => 0);
    final commentCount = commentCountAsync.when(
        data: (count) => count, loading: () => 0, error: (_, __) => 0);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Botón Me gusta
          Expanded(
            child: userReactionAsync.when(
              data: (userReaction) {
                final hasLiked = userReaction == 'like';
                return _buildActionButton(
                  icon: hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  count: likeCount,
                  color: hasLiked ? const Color(0xFF6C63FF) : null,
                  onTap: () async {
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
                icon: Icons.thumb_up_outlined,
                count: likeCount,
                color: null,
                onTap: () {},
              ),
              error: (_, __) => _buildActionButton(
                icon: Icons.thumb_up_outlined,
                count: likeCount,
                color: null,
                onTap: () {},
              ),
            ),
          ),

          // Botón Comentar
          Expanded(
            child: _buildActionButton(
              icon: Icons.chat_bubble_outline,
              count: commentCount,
              color: null,
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
            ),
          ),

          // Botón Compartir
          Expanded(
            child: _buildActionButton(
              icon: Icons.share_outlined,
              count: null, // Compartir no tiene contador
              color: null,
              onTap: () => _handleShare(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    int? count,
    Color? color,
    required VoidCallback onTap,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.center, // Centrar el contenido
            children: [
              Icon(icon, size: 18, color: iconColor),
              if (count != null && count > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(_formatCount(count),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
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
