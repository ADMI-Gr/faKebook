import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, consolidateHttpClientResponseBytes;

//==== Acciones de la foto del grupo ====
Future<void> showGroupAvatarActions({
  required BuildContext context,
  required String title,
  required String avatarUrl,
  bool isCurrentUserAdmin = false,
}) async {
  if (avatarUrl.isEmpty) return;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUserAdmin)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Cambiar imagen del grupo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final typeGroup = const XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp']);
                    final file = await openFile(acceptedTypeGroups: [typeGroup]);
                    if (file == null) return;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Imagen del grupo actualizada (demo)')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo cambiar la imagen: $e')),
                      );
                    }
                  }
                },
              ),
            if (isCurrentUserAdmin) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Descargar imagen del grupo'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  if (kIsWeb) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Guardar imagen no está disponible en Web')),
                      );
                    }
                  } else if (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS) {
                    final success = await GallerySaver.saveImage(avatarUrl, albumName: 'Fakebook');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success == true
                              ? 'Imagen guardada en la galería'
                              : 'No se pudo guardar la imagen'),
                        ),
                      );
                    }
                  } else {
                    final uri = Uri.parse(avatarUrl);
                    String suggested = 'grupo_${title.replaceAll(' ', '_')}.jpg';
                    final lastSeg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
                    if (lastSeg.isNotEmpty && lastSeg.contains('.')) {
                      suggested = lastSeg;
                    }
                    final location = await getSaveLocation(suggestedName: suggested);
                    if (location == null) return;

                    final httpClient = HttpClient();
                    final request = await httpClient.getUrl(uri);
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
                          SnackBar(content: Text('Error al descargar: HTTP ${response.statusCode}')),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    ),
  );
}
