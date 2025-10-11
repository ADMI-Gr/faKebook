import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/widgets/block_unblock_tile.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fakebook/widgets/delete_chat_dialog.dart';
import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import '../image_viewer_screen.dart';

//PANTALLA DE PERFIL DE CHAT DE UN SUARIO
class UserChatProfileViewScreen extends StatelessWidget {
  const UserChatProfileViewScreen({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    this.targetUserId,
  });

  final String name;
  final String avatarUrl;
  final String bio;
  final String? targetUserId;

  Color _colorFromInitial(String initial) {
    final colors = {
      'A': const Color(0xFFE91E63),
      'B': const Color(0xFF9C27B0),
      'C': const Color(0xFF673AB7),
      'D': const Color(0xFF3F51B5),
      'E': const Color(0xFF2196F3),
      'F': const Color(0xFF03A9F4),
      'G': const Color(0xFF00BCD4),
      'H': const Color(0xFF009688),
      'I': const Color(0xFF4CAF50),
      'J': const Color(0xFF8BC34A),
      'K': const Color(0xFFCDDC39),
      'L': const Color(0xFFFFEB3B),
      'M': const Color(0xFFFFC107),
      'N': const Color(0xFFFF9800),
      'O': const Color(0xFFFF5722),
      'P': const Color(0xFFF44336),
      'Q': const Color(0xFFE91E63),
      'R': const Color(0xFF9C27B0),
      'S': const Color(0xFF673AB7),
      'T': const Color(0xFF3F51B5),
      'U': const Color(0xFF2196F3),
      'V': const Color(0xFF00BCD4),
      'W': const Color(0xFF009688),
      'X': const Color(0xFF4CAF50),
      'Y': const Color(0xFFFF9800),
      'Z': const Color(0xFFFF5722),
    };
    final key = (initial.isNotEmpty ? initial[0] : 'A').toUpperCase();
    return colors[key] ?? const Color(0xFF1976D2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            tooltip: 'Más opciones',
            onPressed: () => _showActionMenu(context),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: Colors.black12),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto de perfil
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (avatarUrl.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewerScreen(imageUrl: avatarUrl),
                      ),
                    );
                  },
                  onLongPress: () async {
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image, size: 28, color: Colors.black54),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        try {
                                          final uri = Uri.parse(avatarUrl);
                                          final httpClient = HttpClient();
                                          final request = await httpClient.getUrl(uri);
                                          final response = await request.close();
                                          if (response.statusCode == 200) {
                                            final bytes = await consolidateHttpClientResponseBytes(response);
                                            final location = await getSaveLocation(suggestedName: 'avatar_${name.replaceAll(' ', '_')}.jpg');
                                            if (location == null) return;
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
                                                SnackBar(content: Text('Error al descargar: ${response.statusCode}')),
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
                                      },
                                      child: const Text('Descargar'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancelar'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    backgroundColor: avatarUrl.isEmpty ? _colorFromInitial(name) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Nombre
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 24, thickness: 0.5, color: Colors.black12),
              const SizedBox(height: 8),

              // Descripcion / Biografia
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Biografia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6E8EE)),
                ),
                child: Text(
                  bio.isNotEmpty ? bio : 'Sin biografia',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showActionMenu(BuildContext context) async {
    bool currentBlocked = false;
    if (targetUserId != null && targetUserId!.isNotEmpty) {
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        currentBlocked = await container.read(isUserBlockedProvider(targetUserId!).future);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.black87),
              title: const Text('Archivar'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat archivado (demo)')),
                );
              },
            ),
            const Divider(height: 1),
            if (targetUserId != null && targetUserId!.isNotEmpty)
              BlockUnblockTile(
                profileId: targetUserId!,
                name: name,
                isBlocked: currentBlocked,
                parentContext: context,
                sheetContext: ctx,
              )
            else
              ListTile(
                leading: Icon(
                  currentBlocked ? Icons.lock_open : Icons.block,
                  color: currentBlocked ? Colors.green : Colors.red,
                ),
                title: Text(currentBlocked ? 'Desbloquear' : 'Bloquear'),
                onTap: () async {
                  Navigator.pop(ctx);
                  // Fallback demo
                  if (currentBlocked) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usuario desbloqueado (demo)')),
                      );
                    }
                  } else {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('Bloquear usuario'),
                        content: Text('¿Estas seguro de que quieres bloquear a $name?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () => Navigator.pop(dctx, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Bloquear'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usuario bloqueado (demo)')),
                      );
                    }
                  }
                },
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar chat'),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(context);
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDeleteChatDialog(
      context,
      name: name,
      onConfirm: () {
        Navigator.pop(context); // Cerrar la pantalla de perfil (simula chat eliminado)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversacion eliminada (demo)')),
        );
      },
    );
  }
}
