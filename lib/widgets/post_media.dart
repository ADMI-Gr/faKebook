import 'dart:io' show File, HttpClient;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, consolidateHttpClientResponseBytes, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:fakebook/screens/content/image_viewer_screen.dart';

// CLASE PARA LA IMAGEN DEL POST
class PostMedia extends StatelessWidget {
  const PostMedia({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: StatefulBuilder(
        builder: (context, setLocalState) {
          bool heroEnabled = false;
          return GestureDetector(
            onTap: () {
              setLocalState(() => heroEnabled = true);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewerScreen(
                    imageUrl: imageUrl,
                    heroTag: (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
                        ? null
                        : heroTag,
                  ),
                ),
              ).then((_) {
                if (context.mounted) {
                  setLocalState(() => heroEnabled = false);
                }
              });
            },
            onLongPress: () async {
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
                                    const SnackBar(content: Text('Guardar imagen no esta disponible en Web')),
                                  );
                                }
                              } else if (defaultTargetPlatform == TargetPlatform.android ||
                                  defaultTargetPlatform == TargetPlatform.iOS) {
                                final success = await GallerySaver.saveImage(imageUrl, albumName: 'Fakebook');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(success == true
                                            ? 'Imagen guardada en la galeria'
                                            : 'No se pudo guardar la imagen')),
                                  );
                                }
                              } else {
                                final location = await getSaveLocation(suggestedName: 'fakebook_image.jpg');
                                if (location == null) return;
                                final uri = Uri.parse(imageUrl);
                                final client = HttpClient();
                                final request = await client.getUrl(uri);
                                final response = await request.close();
                                if (response.statusCode == 200) {
                                  final bytes = await consolidateHttpClientResponseBytes(response);
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
                                          content: Text('Error al descargar: HTTP ${response.statusCode}')),
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
            },
            child: HeroMode(
              enabled: heroEnabled,
              child: Hero(
                tag: heroTag,
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: 180,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.grey[500]!),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
