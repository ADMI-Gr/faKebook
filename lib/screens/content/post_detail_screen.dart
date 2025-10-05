import 'package:flutter/material.dart';
import 'package:fakebook/widgets/post_card.dart';
import 'package:fakebook/models/post_model.dart';
import 'package:fakebook/models/user_model.dart';

//====== PANTALLA PARA VER UNA PUBLICACION EN PANTALLA COMPLETA ======
class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  final UserModel author;
  final bool isMine;

  const PostDetailScreen(
      {super.key,
      required this.post,
      required this.author,
      this.isMine = false});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: Text(
                'Comentarios',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverToBoxAdapter(
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
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: Padding(
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
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: boxShadow,
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un comentario...',
                            hintStyle: TextStyle(color: Colors.black38),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            prefixIcon: Icon(Icons.mode_comment_outlined,
                                size: 20, color: Colors.black45),
                          ),
                          minLines: 1,
                          maxLines: 4,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (_controller.text.trim().isEmpty) return;
                            final text = _controller.text.trim();
                            //AQUI IRIA LA LOGICA PARA PUBLICAR EL COMENTARIO
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Demo: publicar comentario "$text"')),
                            );
                            _controller.clear();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: _controller.text.trim().isEmpty ? 0.9 : 1.0,
                      curve: Curves.easeOut,
                      child: ElevatedButton(
                        onPressed: _controller.text.trim().isEmpty
                            ? null
                            : () {
                                final text = _controller.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Escribe algo antes de publicar')),
                                  );
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Demo: publicar comentario "$text"')),
                                );
                                _controller.clear();
                                setState(() {});
                              },
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
                        child: const Text('Publicar'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
