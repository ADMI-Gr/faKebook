import 'package:flutter/material.dart';
import 'package:fakebook/models/post_model.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/screens/content/post_detail_screen.dart';

// Acciones del post: Me gusta, Comentar, Compartir
class PostActions extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              Icons.thumb_up_outlined,
              'Me gusta',
              () {},
            ),
          ),
          Expanded(
            child: _buildActionButton(
              Icons.chat_bubble_outline,
              'Comentar',
              () {
                //SOLO REDIRIGE A LA PANTALLA DE COMPLETA DEL POST
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
          Expanded(
            child: _buildActionButton(
              Icons.share_outlined,
              'Compartir',
              () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
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
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
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
}
