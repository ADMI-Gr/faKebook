import 'package:flutter/material.dart';

// PANTALLA DE PREVIEW DE LA IMAGEN
class ExplorePostCard extends StatefulWidget {
  final String imageUrl;
  final int likeCount;
  final VoidCallback? onTap;

  const ExplorePostCard({
    super.key,
    required this.imageUrl,
    required this.likeCount,
    this.onTap,
  });

  @override
  State<ExplorePostCard> createState() => _ExplorePostCardState();
}

class _ExplorePostCardState extends State<ExplorePostCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: widget.imageUrl,
            child: Material(
              color: Colors.transparent,
              child: Ink.image(
                image: NetworkImage(widget.imageUrl),
                fit: BoxFit.cover,
                child: InkWell(onTap: widget.onTap),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black45,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _liked = !_liked),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(_liked),
                          size: 16,
                          color: _liked ? Colors.red : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.likeCount.toString(),
                        style: TextStyle(
                          color: _liked ? Colors.red : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
