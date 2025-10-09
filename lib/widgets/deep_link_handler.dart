import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/screens/content/post_detail_screen.dart';

class DeepLinkHandler {
  StreamSubscription? _sub;

  void init(BuildContext context, WidgetRef ref) {
    // Manejar el link inicial (cuando la app se abre desde un link)
    _handleInitialLink(context, ref);

    // Manejar links mientras la app está abierta
    _handleIncomingLinks(context, ref);
  }

  Future<void> _handleInitialLink(BuildContext context, WidgetRef ref) async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _processLink(initialLink, context, ref);
      }
    } catch (e) {
      print('Error manejando link inicial: $e');
    }
  }

  void _handleIncomingLinks(BuildContext context, WidgetRef ref) {
    _sub = linkStream.listen((String? link) {
      if (link != null) {
        _processLink(link, context, ref);
      }
    }, onError: (err) {
      print('Error en stream de links: $err');
    });
  }

  void _processLink(String link, BuildContext context, WidgetRef ref) {
    final uri = Uri.parse(link);

    // Formato 1: fakebook://post/{postId}
    // Formato 2: https://fakebook.app/post/{postId}

    String? postId;

    if (uri.scheme == 'fakebook' && uri.host == 'post') {
      postId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    } else if (uri.scheme == 'https' && uri.host == 'fakebook.app') {
      // Extraer postId de /post/{postId}
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'post') {
        postId = uri.pathSegments[1];
      }
    }

    if (postId != null) {
      _openPost(postId, context, ref);
    }
  }

  Future<void> _openPost(
      String postId, BuildContext context, WidgetRef ref) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener todas las publicaciones y buscar la específica
      final allPosts = await ref.read(allPostsProvider.future);
      final postData = allPosts.firstWhere(
        (p) => p.post.id == postId,
        orElse: () => throw Exception('Post no encontrado'),
      );

      // Cerrar loading
      if (context.mounted) {
        Navigator.pop(context);

        // Navegar al post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              post: postData.post,
              author: postData.author,
              isMine: false, // Podrías verificar si es del usuario actual
            ),
          ),
        );
      }
    } catch (e) {
      // Cerrar loading
      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir la publicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
