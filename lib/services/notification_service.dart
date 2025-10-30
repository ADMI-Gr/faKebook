import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_navigation_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // GlobalKey para acceder al Navigator desde cualquier lugar
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ProviderContainer para acceder a los providers desde el callback
  static ProviderContainer? providerContainer;

  Future<void> initialize() async {
    if (_initialized) return;

    // Solicitar permisos
    await _requestPermissions();

    // Configuración de Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    // Solicitar permisos en Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 ===== NOTIFICACIÓN TOCADA =====');
    print('🔔 Response: $response');
    print('🔔 Payload: ${response.payload}');

    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      print('❌ Payload es null o vacío');
      return;
    }

    print('🔔 Notificación tocada con payload: $payload');

    // Obtener el contexto de navegación
    final context = navigatorKey.currentContext;
    print('🔧 Context disponible: ${context != null}');
    if (context == null) {
      print('❌ No hay contexto de navegación disponible');
      print('❌ NavigatorKey: $navigatorKey');
      print('❌ CurrentState: ${navigatorKey.currentState}');
      return;
    }

    // Obtener el ProviderContainer
    print('🔧 ProviderContainer disponible: ${providerContainer != null}');
    if (providerContainer == null) {
      print('❌ ProviderContainer no está disponible');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo abrir la notificación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navegar según el tipo de payload usando el ProviderContainer directamente
    try {
      if (payload.startsWith('post:')) {
        // Navegar a un post
        final postId = payload.substring(5); // Remover "post:"
        print('📱 Navegando a post: $postId');
        NotificationNavigationHelper.navigateToPost(
            context, providerContainer!, postId);
      } else if (payload.startsWith('profile:')) {
        // Navegar a un perfil
        final profileId = payload.substring(8); // Remover "profile:"
        print('📱 Navegando a perfil: $profileId');
        NotificationNavigationHelper.navigateToProfile(
            context, providerContainer!, profileId);
      } else {
        // Es un conversationId de chat
        print('📱 Navegando a chat: $payload');
        NotificationNavigationHelper.navigateToChat(
            context, providerContainer!, payload);
      }
    } catch (e, stackTrace) {
      print('❌ Error al procesar notificación: $e');
      print('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> showMessageNotification({
    required String conversationId,
    required String senderName,
    required String messageBody,
    String? avatarUrl,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Mensajes de Chat',
      channelDescription: 'Notificaciones de mensajes nuevos',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      conversationId.hashCode,
      senderName,
      messageBody,
      details,
      payload: conversationId, // Payload es el conversationId
    );
  }

  Future<void> showNewPostNotification({
    required String postId,
    required String authorName,
    String? authorUsername,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'new_posts',
      'Nuevas Publicaciones',
      channelDescription:
          'Notificaciones de publicaciones de usuarios que sigues',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final username = authorUsername != null ? '@$authorUsername' : authorName;

    await _notifications.show(
      postId.hashCode,
      'Nueva publicación',
      '$username ha subido una publicación',
      details,
      payload: 'post:$postId', // Payload con prefijo "post:"
    );
  }

  Future<void> showLikeNotification({
    required String postId,
    required String likerName,
    String? likerUsername,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'post_likes',
      'Me gusta en publicaciones',
      channelDescription:
          'Notificaciones cuando alguien le da like a tus publicaciones',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final username = likerUsername != null ? '@$likerUsername' : likerName;

    await _notifications.show(
      'like_$postId'.hashCode,
      'Le gustó tu publicación',
      'A $username le gustó tu publicación',
      details,
      payload: 'post:$postId', // Payload con prefijo "post:"
    );
  }

  Future<void> showNewFollowerNotification({
    required String followerId,
    required String followerName,
    String? followerUsername,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'new_followers',
      'Nuevos Seguidores',
      channelDescription: 'Notificaciones cuando alguien te empieza a seguir',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final username =
        followerUsername != null ? '@$followerUsername' : followerName;

    await _notifications.show(
      followerId.hashCode,
      'Nuevo seguidor',
      '$username comenzó a seguirte',
      details,
      payload: 'profile:$followerId', // Payload con prefijo "profile:"
    );
  }

  Future<void> cancelNotification(String conversationId) async {
    await _notifications.cancel(conversationId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

// Provider para acceder al NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
