import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/widgets/post_card.dart';
import 'package:fakebook/models/post_model.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/providers/auth_provider.dart';

//====== PANTALLA PARA VER UNA PUBLICACION EN PANTALLA COMPLETA ======
class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;
  final UserModel author;
  final bool isMine;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.author,
    this.isMine = false,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  Future<void> _submitComment() async {
    if (_controller.text.trim().isEmpty || _isSubmitting) return;

    final text = _controller.text.trim();
    setState(() => _isSubmitting = true);

    try {
      await ref.read(createCommentProvider((
        postId: widget.post.id,
        content: text,
        parentComment: _replyingToCommentId,
      )).future);

      _controller.clear();
      _cancelReply();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_replyingToCommentId != null
                ? 'Respuesta publicada'
                : 'Comentario publicado'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al publicar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));
    final commentCountAsync = ref.watch(commentCountProvider(widget.post.id));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            tooltip: 'Volver',
          ),
        ),
        title: const Text(
          'Publicación',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          PostList(posts: [
            (
              post: widget.post,
              author: widget.author,
              isMine: widget.isMine,
            )
          ]),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Comentarios',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  commentCountAsync.when(
                    data: (count) => Text(
                      '($count)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'Aun no hay comentarios. ¡Animate y se el primero en comentar!',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final comment = comments[index];
                    return _CommentCard(
                      comment: comment,
                      postId: widget.post.id,
                      onReply: (commentId, authorName) {
                        setState(() {
                          _replyingToCommentId = commentId;
                          _replyingToAuthorName = authorName;
                        });
                      },
                    );
                  },
                  childCount: comments.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar comentarios: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Respondiendo a $_replyingToAuthorName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: _controller.text.trim().isEmpty ? 0 : 1,
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  final borderColor = Color.lerp(
                      Colors.grey[300]!, const Color(0xFF6C63FF), value)!;
                  final bgColor =
                      Color.lerp(Colors.grey[100]!, Colors.white, value)!;
                  final boxShadow = [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.25 * value),
                      blurRadius: 10 * value,
                      offset: Offset(0, 3 * value),
                    ),
                  ];
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, -3),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: borderColor, width: 1.5),
                              boxShadow: boxShadow,
                            ),
                            child: TextField(
                              controller: _controller,
                              enabled: !_isSubmitting,
                              decoration: InputDecoration(
                                hintText: _replyingToCommentId != null
                                    ? 'Escribe una respuesta...'
                                    : 'Escribe un comentario...',
                                hintStyle:
                                    const TextStyle(color: Colors.black38),
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                prefixIcon: Icon(
                                  _replyingToCommentId != null
                                      ? Icons.reply
                                      : Icons.mode_comment_outlined,
                                  size: 20,
                                  color: Colors.black45,
                                ),
                              ),
                              minLines: 1,
                              maxLines: 4,
                              onChanged: (_) => setState(() {}),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _submitComment(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: _controller.text.trim().isEmpty ? 0.9 : 1.0,
                          curve: Curves.easeOut,
                          child: ElevatedButton(
                            onPressed:
                                _controller.text.trim().isEmpty || _isSubmitting
                                    ? null
                                    : _submitComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Publicar'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> comment;
  final String postId;
  final Function(String commentId, String authorName)? onReply;
  final bool isReply;
  final int depth;

  const _CommentCard({
    required this.comment,
    required this.postId,
    this.onReply,
    this.isReply = false,
    this.depth = 0,
  });

  @override
  ConsumerState<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends ConsumerState<_CommentCard> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final authorId = widget.comment['author_id'] as String;
    final commentId = widget.comment['id'] as String;
    final authorAsync = ref.watch(userProfileProvider(authorId));
    final currentUser = ref.watch(userProvider);
    final isMine = currentUser?.id == authorId;

    // Obtener el parent_comment_id si existe
    final parentCommentId = widget.comment['parent_comment_id'] as String?;

    // Obtener reacciones del comentario
    final reactionCountsAsync = ref.watch(reactionCountsProvider((
      targetType: 'comment',
      targetId: commentId,
    )));

    final userReactionAsync = ref.watch(userReactionProvider((
      targetType: 'comment',
      targetId: commentId,
    )));

    // Obtener respuestas
    final repliesAsync = ref.watch(commentRepliesProvider(commentId));

    return authorAsync.when(
      data: (author) {
        if (author == null) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(
            left: widget.isReply ? 48.0 : 16.0,
            right: 16.0,
            top: 8,
            bottom: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: widget.isReply ? 16 : 20,
                    backgroundImage: author.avatarUrl != null
                        ? NetworkImage(author.avatarUrl!)
                        : null,
                    child: author.avatarUrl == null
                        ? Text(
                            author.displayName![0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: widget.isReply ? 12 : 14,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      author.displayName ?? "author.name error",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (isMine)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz,
                                          size: 18),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline,
                                                  size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Eliminar'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) async {
                                        if (value == 'delete') {
                                          try {
                                            await ref
                                                .read(deleteCommentProvider((
                                              commentId: commentId,
                                              postId: widget.postId,
                                            )).future);
                                            await Future.delayed(const Duration(
                                                milliseconds: 300));
                                            if (parentCommentId != null) {
                                              ref.invalidate(
                                                  commentRepliesProvider(
                                                      parentCommentId));
                                            }
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Comentario eliminado'),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.comment['content'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            children: [
                              Text(
                                _formatTime(widget.comment['created_at']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Botón Like
                              userReactionAsync.when(
                                data: (userReaction) {
                                  final hasLiked = userReaction == 'like';
                                  return reactionCountsAsync.when(
                                    data: (counts) {
                                      final likeCount = counts['like'] ?? 0;
                                      return InkWell(
                                        onTap: () async {
                                          try {
                                            await ref
                                                .read(toggleReactionProvider((
                                              targetType: 'comment',
                                              targetId: commentId,
                                              reactionType: 'like',
                                            )).future);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              hasLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              size: 14,
                                              color: hasLiked
                                                  ? Colors.red
                                                  : Colors.grey[600],
                                            ),
                                            if (likeCount > 0) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                likeCount.toString(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: hasLiked
                                                      ? Colors.red
                                                      : Colors.grey[600],
                                                  fontWeight: hasLiked
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                              const SizedBox(width: 16),
                              // Botón Responder
                              if (!widget.isReply && widget.depth < 2)
                                InkWell(
                                  onTap: () {
                                    widget.onReply?.call(
                                        commentId,
                                        author.displayName ??
                                            "author.displayname error");
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.reply,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Responder',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Mostrar respuestas
                        if (!widget.isReply)
                          repliesAsync.when(
                            data: (replies) {
                              if (replies.isEmpty)
                                return const SizedBox.shrink();

                              return Column(
                                children: [
                                  const SizedBox(height: 8),
                                  if (!_showReplies && replies.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: InkWell(
                                        onTap: () =>
                                            setState(() => _showReplies = true),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 1,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Ver ${replies.length} respuesta${replies.length > 1 ? 's' : ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (_showReplies)
                                    ...replies.map((reply) => _CommentCard(
                                          comment: reply,
                                          postId: widget.postId,
                                          isReply: true,
                                          depth: widget.depth + 1,
                                        )),
                                  if (_showReplies && replies.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 12, top: 4),
                                      child: InkWell(
                                        onTap: () => setState(
                                            () => _showReplies = false),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 1,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Ocultar respuestas',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatTime(dynamic timestamp) {
    try {
      DateTime date;

      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        // Convierte manualmente a UTC ignorando la zona horaria del sistema
        date = DateTime.parse(timestamp).toUtc().toLocal();
      } else {
        return '';
      }

      if (date.isUtc) {
        date = date.toLocal();
      }

      final now = DateTime.now();
      final diff = now.difference(date);
      print('Formateando tiempo, ahora: $now, fecha: $date, diff: $diff');
      if (diff.inSeconds < 60) {
        return 'ahora';
      } else if (diff.inMinutes < 60) {
        return 'hace ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        return 'hace ${diff.inHours} hora${diff.inHours > 1 ? 's' : ''}';
      } else if (diff.inDays < 7) {
        return 'hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      print('Error formateando tiempo: $e, timestamp: $timestamp');
      return '';
    }
  }
}
