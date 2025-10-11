import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:android_intent_plus/android_intent.dart';

// Helper para descargar archivos y abrirlos
class FileDownloadHelper {
  static Future<void> saveToDownloadsAndOpen(BuildContext context, {required String srcPath, required String fileName}) async {
    if (srcPath.isEmpty) return;
    try {
      if (kIsWeb) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guardar archivo no está disponible en Web (demo)')),
          );
        }
        return;
      } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        String downloadsBase;
        if (defaultTargetPlatform == TargetPlatform.android) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permiso de almacenamiento denegado')),
              );
            }
            return;
          }
          final downloadsDir = await DownloadsPathProvider.downloadsDirectory;
          downloadsBase = downloadsDir?.path ?? (await getApplicationDocumentsDirectory()).path;
        } else {
          final docs = await getApplicationDocumentsDirectory();
          downloadsBase = p.join(docs.path, 'Downloads');
        }
        final targetDir = Directory(p.join(downloadsBase, 'Fakebook'));
        if (!(await targetDir.exists())) {
          await targetDir.create(recursive: true);
        }
        final destPath = p.join(targetDir.path, fileName);
        try {
          if (srcPath.startsWith('http://') || srcPath.startsWith('https://')) {
            await Dio().download(srcPath, destPath);
          } else {
            await File(srcPath).copy(destPath);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al guardar: $e')),
            );
          }
          return;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Guardado en: $destPath')),
          );
        }
        try {
          if (defaultTargetPlatform == TargetPlatform.android) {
            const downloadsContentUri = 'content://com.android.externalstorage.documents/document/primary%3ADownload';
            final intent = const AndroidIntent(
              action: 'android.intent.action.VIEW',
              data: downloadsContentUri,
              type: 'vnd.android.document/directory',
            );
            await intent.launch();
          } else {
            final result = await OpenFilex.open(destPath);
            if (result.type != ResultType.done) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Archivo guardado, pero no se pudo abrir')),
                );
              }
            }
          }
        } catch (_) {
          try {
            await OpenFilex.open(destPath);
          } catch (_) {}
        }
        return;
      } else {
        final location = await getSaveLocation(suggestedName: fileName);
        if (location == null) return;
        await File(srcPath).copy(location.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo guardado')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }
}
