import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/screens/content/post_detail_screen.dart';
import 'package:fakebook/screens/content/chat/chat_detail_screen.dart';
import 'package:fakebook/screens/content/chat/group_chat_detail_screen.dart';
import 'package:fakebook/repositories/social_repository.dart';
import 'package:fakebook/repositories/profile_repository.dart';
import 'package:fakebook/models/post_model.dart';
import 'package:fakebook/models/user_model.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/chat_providers.dart';

class NotificationNavigationHelper {
  /// Navega a un post específico
  static Future<void> navigateToPost(
    BuildContext context,
    ProviderContainer container,
    String postId,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Cargar el post
      final socialRepository = SocialRepository();
      final profileRepository = ProfileRepository();

      final posts = await socialRepository.getAllPosts();
      final postData = posts.firstWhere(
        (p) => p['id'] == postId,
        orElse: () => throw Exception('Post no encontrado'),
      );

      final post = PostModel.fromMap(postData);
      final author = await profileRepository.getProfile(post.authorId);

      if (author == null) {
        throw Exception('Autor no encontrado');
      }

      // Verificar si el post es del usuario actual
      final currentUser = container.read(userProvider);
      final isMine = currentUser?.id == post.authorId;

      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navegar al post
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              post: post,
              author: author,
              isMine: isMine,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error al navegar al post: $e');

      // Cerrar el diálogo de carga si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir la publicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navega a un perfil de usuario
  static Future<void> navigateToProfile(
    BuildContext context,
    ProviderContainer container,
    String profileId,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Cargar el perfil
      final profileRepository = ProfileRepository();
      final profile = await profileRepository.getProfile(profileId);

      if (profile == null) {
        throw Exception('Perfil no encontrado');
      }

      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navegar al perfil del usuario
      // Por ahora mostramos la información del perfil
      // Si tienes una pantalla de perfil específica, descomenta y ajusta el código abajo
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(profile.displayName ?? profile.username),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.avatarUrl != null)
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(profile.avatarUrl!),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Usuario: @${profile.username}'),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Bio: ${profile.bio}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );

        // TODO: Si tienes una pantalla de perfil, descomenta esto:
        // import 'package:fakebook/screens/content/profile_screen.dart';
        //
        // await Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => ProfileScreen(userId: profileId),
        //   ),
        // );
      }
    } catch (e) {
      print('❌ Error al navegar al perfil: $e');

      // Cerrar el diálogo de carga si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navega a un chat (privado o grupal)
  static Future<void> navigateToChat(
    BuildContext context,
    ProviderContainer container,
    String conversationId,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final currentUser = container.read(userProvider);
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener la conversación
      final conversations = await container
          .read(userConversationsProvider(currentUser.id).future);
      final conversation = conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => throw Exception('Conversación no encontrada'),
      );

      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navegar según el tipo de conversación
      if (context.mounted) {
        if (conversation.kind == 'private') {
          // Chat privado
          final participants =
              await container.read(participantsProvider(conversationId).future);
          final otherParticipant = participants.firstWhere(
            (p) => p.profileId != currentUser.id,
            orElse: () => participants.first,
          );

          final profileRepository = ProfileRepository();
          final profile =
              await profileRepository.getProfile(otherParticipant.profileId);

          final name = profile?.displayName ?? profile?.username ?? 'Usuario';
          final avatarUrl = profile?.avatarUrl ?? '';

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                name: name,
                avatarUrl: avatarUrl,
                recipientId: otherParticipant.profileId,
                userName: profile?.username,
                initialConversationId: conversationId,
              ),
            ),
          );
        } else {
          // Chat grupal
          final metadata = conversation.metadata;
          final title = metadata['name']?.toString() ?? 'Grupo sin nombre';
          final avatarUrl = metadata['avatar_url']?.toString() ?? '';

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupChatDetailScreen(
                conversationId: conversationId,
                title: title,
                avatarUrl: avatarUrl,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error al navegar al chat: $e');

      // Cerrar el diálogo de carga si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
