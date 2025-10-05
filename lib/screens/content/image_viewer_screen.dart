import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show
        kIsWeb,
        defaultTargetPlatform,
        TargetPlatform,
        consolidateHttpClientResponseBytes;
import 'dart:io' show File, HttpClient;

//====== PANTALLA PARA PREVISUALIZAR Y DESCARGAR IMAGENES ======
class ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;

  const ImageViewerScreen({super.key, required this.imageUrl, this.heroTag});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  double _dragDy = 0.0;
  double _bgOpacity = 1.0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDy += details.delta.dy;
      final t = (_dragDy.abs() / 300).clamp(0.0, 0.7);
      _bgOpacity = (1.0 - t).clamp(0.3, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final vy = details.primaryVelocity ?? 0.0;
    if (_dragDy.abs() > 120 || vy.abs() > 800) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _dragDy = 0.0;
      _bgOpacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(_bgOpacity)),
          ),
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              onLongPress: () {
                _showSaveSheet(context);
              },
              onTap: () => Navigator.of(context).maybePop(),
              child: Transform.translate(
                offset: Offset(0, _dragDy),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: widget.heroTag == null
                        ? _image()
                        : Hero(
                            tag: widget.heroTag!,
                            transitionOnUserGestures: true,
                            createRectTween: (begin, end) =>
                                RectTween(begin: begin, end: end),
                            flightShuttleBuilder: (context,
                                animation,
                                flightDirection,
                                fromHeroContext,
                                toHeroContext) {
                              return FadeTransition(
                                opacity: animation.drive(
                                    CurveTween(curve: Curves.easeOutCubic)),
                                child: toHeroContext.widget,
                              );
                            },
                            child: _image(),
                          ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _image() {
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(Colors.white70),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, color: Colors.white54, size: 64);
      },
    );
  }

  void _showSaveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Guardar imagen'),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Descargando imagen...')),
                  );
                  try {
                    if (kIsWeb) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Guardar imagen no está disponible en Web')),
                        );
                      }
                    } else if (defaultTargetPlatform ==
                            TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.iOS) {
                      final success = await GallerySaver.saveImage(
                          widget.imageUrl,
                          albumName: 'Fakebook');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(success == true
                                  ? 'Imagen guardada en la galería'
                                  : 'No se pudo guardar la imagen')),
                        );
                      }
                    } else {
                      // Desktop (Windows/macOS/Linux)
                      final uri = Uri.parse(widget.imageUrl);
                      String suggested = 'fakebook_image.jpg';
                      final lastSeg = uri.pathSegments.isNotEmpty
                          ? uri.pathSegments.last
                          : '';
                      if (lastSeg.isNotEmpty && lastSeg.contains('.')) {
                        suggested = lastSeg;
                      }
                      final location =
                          await getSaveLocation(suggestedName: suggested);
                      if (location == null) return;

                      final client = HttpClient();
                      final request = await client.getUrl(uri);
                      final response = await request.close();
                      if (response.statusCode == 200) {
                        final bytes =
                            await consolidateHttpClientResponseBytes(response);
                        final file = File(location.path);
                        await file.writeAsBytes(bytes);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Imagen guardada')),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Error al descargar: HTTP ${response.statusCode}')),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al guardar: $e')),
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
  }
}
