import 'package:flutter/material.dart';

// Pantalla de previsualización de imagen DE LA PANTALLA DE GRID
class ImagePreviewScreen extends StatefulWidget {
  final String imageUrl;
  final int likeCount;

  const ImagePreviewScreen({
    super.key,
    required this.imageUrl,
    required this.likeCount,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _drag = 0;
  final TransformationController _transformController =
      TransformationController();
  double _scale = 1.0;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _transformController.addListener(() {
      final m = _transformController.value;
      final s = m.getMaxScaleOnAxis();
      if (s != _scale) {
        setState(() {
          _scale = s;
          if (_scale > 1.01) {
            _drag = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dy = details.primaryDelta ?? 0;
    setState(() {
      _drag = (_drag + dy).clamp(-200.0, 500.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final vy = details.primaryVelocity ?? 0;

    if (_drag > 120 || vy > 700) {
      Navigator.of(context).maybePop();
      return;
    }

    if (_drag < -120 || vy < -700) {
      Navigator.of(context).maybePop();
      return;
    }

    _controller.forward(from: 0).whenComplete(() {
      setState(() {
        _drag = 0;
      });
      _controller.reset();
    });
  }

  double get _progress {
    final p = (_drag.abs() / 280).clamp(0.0, 1.0);
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 - (_progress * 0.15);
    final opacity = 1.0 - (_progress * 0.7);
    final bool isZoomed = _scale > 1.01;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(opacity),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: isZoomed ? null : _handleDragUpdate,
        onVerticalDragEnd: isZoomed ? null : _handleDragEnd,
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, _drag),
                child: Transform.scale(
                  scale: scale,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.8,
                    maxScale: 4.0,
                    panEnabled: isZoomed,
                    child: Hero(
                      tag: widget.imageUrl,
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 24,
              child: Opacity(
                opacity: (1.0 - _progress).clamp(0.0, 1.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // FUTURO METODO PARA DAR LIKE
                    onTap: () => setState(() => _liked = !_liked),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24),
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
                              color: _liked ? Colors.red : Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.likeCount.toString(),
                            style: TextStyle(
                              color: _liked ? Colors.red : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
