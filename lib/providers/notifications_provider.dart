import 'dart:async';
import 'package:fakebook/providers/chat_providers.dart' as chat;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/profile_repository.dart';

// Provider para escuchar notificaciones en tiempo real
class RealtimeNotificationsNotifier
    extends StateNotifier<List<Map<String, dynamic>>> {
  RealtimeNotificationsNotifier(this.ref, this.userId) : super([]) {
    _initialize();
  }

  final Ref ref;
  final String userId;
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  void _initialize() async {
    // Configurar listener de tiempo real
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    print('🔔 Configurando listener de notificaciones para usuario: $userId');

    _channel = _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) async {
            print('🔔 Nueva notificación recibida: ${payload.newRecord}');
            final notification = payload.newRecord;

            // Agregar la notificación al estado
            state = [notification, ...state];

            // Mostrar notificación local
            await _showLocalNotification(notification);
          },
        )
        .subscribe((status, error) {
      print('🔔 Estado de suscripción: $status');
      if (error != null) {
        print('❌ Error en suscripción: $error');
      }
    });
  }

  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    try {
      final notificationService = ref.read(chat.notificationServiceProvider);
      final type = notification['type'] as String;
      final actorId = notification['actor_id'] as String?;
      final payload = notification['payload'] as Map<String, dynamic>?;

      if (actorId == null) return;

      // Obtener información del actor
      final actor = await ProfileRepository().getProfile(actorId);
      if (actor == null) return;

      final actorName = actor.displayName ?? actor.username;
      final actorUsername = actor.username;

      switch (type) {
        case 'new_post':
          final postId = payload?['post_id'] as String?;
          if (postId != null) {
            await notificationService.showNewPostNotification(
              postId: postId,
              authorName: actorName,
              authorUsername: actorUsername,
            );
          }
          break;

        case 'like_post':
          final postId = payload?['post_id'] as String?;
          if (postId != null) {
            await notificationService.showLikeNotification(
              postId: postId,
              likerName: actorName,
              likerUsername: actorUsername,
            );
          }
          break;

        case 'new_follower':
          await notificationService.showNewFollowerNotification(
            followerId: actorId,
            followerName: actorName,
            followerUsername: actorUsername,
          );
          break;

        case 'comment_post':
        case 'reply_comment':
          // Estos ya existen, puedes agregar notificaciones locales si deseas
          print('Notificación de comentario recibida');
          break;

        default:
          print('Tipo de notificación desconocido: $type');
      }
    } catch (e) {
      print('Error mostrando notificación local: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// Provider para acceder a las notificaciones en tiempo real
final realtimeNotificationsProvider = StateNotifierProvider.family.autoDispose<
    RealtimeNotificationsNotifier, List<Map<String, dynamic>>, String>(
  (ref, userId) {
    return RealtimeNotificationsNotifier(ref, userId);
  },
);
