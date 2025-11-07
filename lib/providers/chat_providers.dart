import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/conversation_participant_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/profile_repository.dart';
import '../services/notification_service.dart';

// Repositorio base
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// Provider para obtener todas las conversaciones de un usuario
final userConversationsProvider =
    FutureProvider.family<List<ConversationModel>, String>(
        (ref, profileId) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return await chatRepo.getUserConversations(profileId);
});

// Provider para obtener los mensajes de una conversación
final messagesProvider = FutureProvider.family<List<MessageModel>, String>(
    (ref, conversationId) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return await chatRepo.getMessages(conversationId);
});

// Provider para obtener los participantes de una conversación
final participantsProvider =
    FutureProvider.family<List<ConversationParticipantModel>, String>(
        (ref, conversationId) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return await chatRepo.getParticipants(conversationId);
});

// ====== NUEVO: Provider para verificar si un usuario es admin ======
final isUserAdminProvider =
    FutureProvider.family<bool, ({String conversationId, String profileId})>(
        (ref, params) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return await chatRepo.isUserAdmin(
    conversationId: params.conversationId,
    profileId: params.profileId,
  );
});

// Provider tipo `Notifier` para enviar mensajes
class SendMessageNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> send({
    required String conversationId,
    required String senderId,
    required String body,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);

    try {
      state = const AsyncLoading();
      await chatRepo.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        body: body,
      );

      // Forzar recarga inmediata de mensajes en tiempo real para esta conversación
      // (evita que la UI espere a cerrar/abrir)
      ref.invalidate(realtimeMessagesProvider(conversationId));
      // Refrescar lista de conversaciones del usuario que envía
      ref.invalidate(userConversationsProvider(senderId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final sendMessageProvider =
    AutoDisposeAsyncNotifierProvider<SendMessageNotifier, void>(
        SendMessageNotifier.new);

// Provider tipo `Notifier` para crear una nueva conversación
class CreateConversationNotifier
    extends AutoDisposeAsyncNotifier<ConversationModel?> {
  @override
  FutureOr<ConversationModel?> build() => null;

  Future<ConversationModel?> create({
    String kind = 'private',
    Map<String, dynamic>? metadata,
    required List<String> participantIds,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);

    try {
      state = const AsyncLoading();
      final conversation = await chatRepo.createConversation(
        kind: kind,
        metadata: metadata,
        participantIds: participantIds,
      );

      state = AsyncData(conversation);
      return conversation;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createConversationProvider = AutoDisposeAsyncNotifierProvider<
    CreateConversationNotifier,
    ConversationModel?>(CreateConversationNotifier.new);

// Eliminar mensaje
class DeleteMessageNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> delete(String messageId) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await chatRepo.deleteMessage(messageId);
    });
  }
}

final deleteMessageProvider =
    AutoDisposeAsyncNotifierProvider<DeleteMessageNotifier, void>(
        DeleteMessageNotifier.new);

// Salir o eliminar conversación
class LeaveConversationNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> leave({
    required String conversationId,
    required String profileId,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await chatRepo.leaveConversation(
        conversationId: conversationId,
        profileId: profileId,
      );
    });

    // Invalidar la lista de conversaciones después de salir
    if (state.hasValue) {
      ref.invalidate(userConversationsProvider);
    }
  }
}

final leaveConversationProvider =
    AutoDisposeAsyncNotifierProvider<LeaveConversationNotifier, void>(
        LeaveConversationNotifier.new);

// Provider para eliminar conversación completa
class DeleteConversationNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> delete({
    required String conversationId,
    required String profileId,
  }) async {
    print('Ingresando a DeleteConversationNotifier.delete');
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();
    print('Antes de llamar a chatRepo.deleteConversation');
    try {
      print(
          'Llamando a chatRepo.deleteConversation con conversationId: $conversationId y profileId: $profileId');
      await chatRepo.deleteConversation(
        conversationId: conversationId,
        profileId: profileId,
      );
      print('Después de llamar a chatRepo.deleteConversation');
      await Future.microtask(() {
        ref.invalidate(userConversationsProvider);
      });
      print('Después de invalidar userConversationsProvider');

      state = const AsyncData(null);
      print('Conversación eliminada exitosamente');
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final deleteConversationProvider =
    AutoDisposeAsyncNotifierProvider<DeleteConversationNotifier, void>(
        DeleteConversationNotifier.new);

// ====== NUEVO: Añadir participante ======
class AddParticipantNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> add({
    required String conversationId,
    required String profileId,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await chatRepo.addParticipant(conversationId, profileId);
    });

    // Invalidar participantes después de agregar
    if (state.hasValue) {
      ref.invalidate(participantsProvider(conversationId));
    }
  }
}

final addParticipantProvider =
    AutoDisposeAsyncNotifierProvider<AddParticipantNotifier, void>(
        AddParticipantNotifier.new);

// ====== NUEVO: Agregar admin al grupo ======
class AddAdminNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> add({
    required String conversationId,
    required String newAdminId,
    required String requesterId,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      chatRepo.addAdminToGroup(
        conversationId: conversationId,
        newAdminId: newAdminId,
        requesterId: requesterId,
      );
    });

    // Invalidar provider de admin después de agregar
    if (state.hasValue) {
      ref.invalidate(isUserAdminProvider);
    }
  }
}

final addAdminProvider =
    AutoDisposeAsyncNotifierProvider<AddAdminNotifier, void>(
        AddAdminNotifier.new);

// ====== NUEVO: Remover admin del grupo ======
class RemoveAdminNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> remove({
    required String conversationId,
    required String adminIdToRemove,
    required String requesterId,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await chatRepo.removeAdminFromGroup(
        conversationId: conversationId,
        adminIdToRemove: adminIdToRemove,
        requesterId: requesterId,
      );
    });

    // Invalidar provider de admin después de remover
    if (state.hasValue) {
      ref.invalidate(isUserAdminProvider);
    }
  }
}

final removeAdminProvider =
    AutoDisposeAsyncNotifierProvider<RemoveAdminNotifier, void>(
        RemoveAdminNotifier.new);

// ====== NUEVO: Editar información del grupo ======
class UpdateGroupInfoNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateInfo({
    required String conversationId,
    required String requesterId,
    String? title,
    String? description,
    String? avatarUrl,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await chatRepo.updateGroupInfo(
        conversationId: conversationId,
        requesterId: requesterId,
        title: title,
        description: description,
        avatarUrl: avatarUrl,
      );
    });

    // Invalidar conversaciones después de actualizar
    if (state.hasValue) {
      ref.invalidate(userConversationsProvider);
    }
  }
}

final updateGroupInfoProvider =
    AutoDisposeAsyncNotifierProvider<UpdateGroupInfoNotifier, void>(
        UpdateGroupInfoNotifier.new);

// ====== NUEVO: Transferir propiedad del grupo ======
class TransferOwnershipNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> transfer({
    required String conversationId,
    required String currentAdminId,
    required String newAdminId,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await chatRepo.transferGroupOwnership(
        conversationId: conversationId,
        currentAdminId: currentAdminId,
        newAdminId: newAdminId,
      );
    });

    // Invalidar provider de admin después de transferir
    if (state.hasValue) {
      ref.invalidate(isUserAdminProvider);
    }
  }
}

final transferOwnershipProvider =
    AutoDisposeAsyncNotifierProvider<TransferOwnershipNotifier, void>(
        TransferOwnershipNotifier.new);

// Provider para el servicio de notificaciones
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider que escucha mensajes en tiempo real
class RealtimeMessagesNotifier extends StateNotifier<List<MessageModel>> {
  RealtimeMessagesNotifier(this.ref, this.conversationId) : super([]) {
    _initialize();
  }

  final Ref ref;
  final String conversationId;
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  String? _currentUserId;

  void _initialize() async {
    // Obtener mensajes iniciales
    await _loadMessages();

    // Configurar listener de tiempo real
    _setupRealtimeListener();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false);

      state = (response as List).map((e) => MessageModel.fromMap(e)).toList();
    } catch (e) {
      print('Error cargando mensajes: $e');
    }
  }

  void _setupRealtimeListener() {
    _currentUserId = _supabase.auth.currentUser?.id;

    _channel = _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) async {
            final newMessage = MessageModel.fromMap(payload.newRecord);

            // Agregar el mensaje al inicio de la lista
            state = [newMessage, ...state];

            // Mostrar notificación solo si el mensaje NO es del usuario actual
            if (newMessage.senderId != _currentUserId) {
              await _showNotification(newMessage);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final updatedMessage = MessageModel.fromMap(payload.newRecord);

            // Actualizar el mensaje en la lista
            state = state.map((m) {
              return m.id == updatedMessage.id ? updatedMessage : m;
            }).toList();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final deletedId = payload.oldRecord['id'] as String;

            // Remover el mensaje de la lista
            state = state.where((m) => m.id != deletedId).toList();
          },
        )
        .subscribe();
  }

  Future<void> _showNotification(MessageModel message) async {
    try {
      // Obtener información del remitente
      final profile = await ProfileRepository().getProfile(message.senderId);
      final senderName = profile?.displayName ?? 'Usuario';
      final avatarUrl = profile?.avatarUrl;

      // Mostrar notificación
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.showMessageNotification(
        conversationId: conversationId,
        senderName: senderName,
        messageBody: message.body ?? 'Mensaje nuevo',
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      print('Error mostrando notificación: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// Provider para acceder a los mensajes en tiempo real
final realtimeMessagesProvider = StateNotifierProvider.family
    .autoDispose<RealtimeMessagesNotifier, List<MessageModel>, String>(
  (ref, conversationId) {
    return RealtimeMessagesNotifier(ref, conversationId);
  },
);

// ====== NUEVO: Provider para escuchar cambios en conversation_participants ======
class RealtimeConversationParticipantsNotifier extends StateNotifier<int> {
  RealtimeConversationParticipantsNotifier(this.ref, this.userId) : super(0) {
    _setupListener();
  }

  final Ref ref;
  final String userId;
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  void _setupListener() {
    _channel = _supabase
        .channel('conversation_participants:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversation_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: userId,
          ),
          callback: (payload) {
            print('Nueva conversación detectada para el usuario $userId');
            // Invalidar el provider de conversaciones para recargar la lista
            ref.invalidate(userConversationsProvider(userId));
            state = state + 1; // Incrementar para forzar rebuild
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'conversation_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: userId,
          ),
          callback: (payload) {
            print('Conversación eliminada para el usuario $userId');
            // Invalidar el provider de conversaciones para recargar la lista
            ref.invalidate(userConversationsProvider(userId));
            state = state + 1; // Incrementar para forzar rebuild
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final realtimeConversationParticipantsProvider = StateNotifierProvider.family
    .autoDispose<RealtimeConversationParticipantsNotifier, int, String>(
  (ref, userId) {
    return RealtimeConversationParticipantsNotifier(ref, userId);
  },
);

// Provider para escuchar TODAS las conversaciones del usuario (mensajes nuevos)
class RealtimeConversationsNotifier extends StateNotifier<Set<String>> {
  RealtimeConversationsNotifier(this.ref, this.userId) : super({}) {
    _setupListener();
  }

  final Ref ref;
  final String userId;
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  void _setupListener() {
    // Escuchar mensajes nuevos en TODAS las conversaciones del usuario
    _channel = _supabase
        .channel('user_messages:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            final newMessage = MessageModel.fromMap(payload.newRecord);

            // Verificar si el mensaje es para una conversación del usuario
            final isInConversation = await _checkUserInConversation(
              newMessage.conversationId,
            );

            // Si el usuario está en la conversación y NO es el remitente
            if (isInConversation && newMessage.senderId != userId) {
              // Agregar a la lista de conversaciones con mensajes nuevos
              state = {...state, newMessage.conversationId};

              // Mostrar notificación
              await _showNotification(newMessage);
            }
          },
        )
        .subscribe();
  }

  Future<bool> _checkUserInConversation(String conversationId) async {
    try {
      final response = await _supabase
          .from('conversation_participants')
          .select('profile_id')
          .eq('conversation_id', conversationId)
          .eq('profile_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showNotification(MessageModel message) async {
    try {
      // Obtener información del remitente
      final profile = await ProfileRepository().getProfile(message.senderId);
      final senderName = profile?.displayName ?? 'Usuario';
      final avatarUrl = profile?.avatarUrl;

      // Obtener información de la conversación
      final convoResponse = await _supabase
          .from('conversations')
          .select('kind, metadata')
          .eq('id', message.conversationId)
          .single();

      String chatName = senderName;
      if (convoResponse['kind'] == 'group') {
        chatName = convoResponse['metadata']?['title'] ?? 'Grupo';
      }

      // Mostrar notificación
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.showMessageNotification(
        conversationId: message.conversationId,
        senderName: chatName,
        messageBody: message.body ?? 'Mensaje nuevo',
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      print('Error mostrando notificación: $e');
    }
  }

  void markAsRead(String conversationId) {
    state = {...state}..remove(conversationId);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final realtimeConversationsProvider = StateNotifierProvider.family
    .autoDispose<RealtimeConversationsNotifier, Set<String>, String>(
  (ref, userId) {
    return RealtimeConversationsNotifier(ref, userId);
  },
);

// Provider para escuchar cambios en conversation_participants en tiempo real
// Detecta cuando el usuario es agregado o removido de conversaciones
class RealtimeParticipantsNotifier extends StateNotifier<int> {
  RealtimeParticipantsNotifier(this.ref, this.userId) : super(0) {
    _setupListener();
  }

  final Ref ref;
  final String userId;
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  void _setupListener() {
    _channel = _supabase
        .channel('conversation_participants:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversation_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: userId,
          ),
          callback: (payload) {
            print('✅ Usuario $userId agregado a una conversación');
            // Cuando me agregan a una conversación, recargar mis conversaciones
            ref.invalidate(userConversationsProvider(userId));
            state++;
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'conversation_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: userId,
          ),
          callback: (payload) {
            print('❌ Usuario $userId removido de una conversación');
            // Cuando me eliminan de una conversación, recargar mis conversaciones
            ref.invalidate(userConversationsProvider(userId));
            state++;
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final realtimeParticipantsProvider = StateNotifierProvider.family
    .autoDispose<RealtimeParticipantsNotifier, int, String>(
  (ref, userId) {
    return RealtimeParticipantsNotifier(ref, userId);
  },
);

// Provider que devuelve una función para marcar una conversación como leída
final markConversationReadProvider =
    Provider<Future<void> Function(String conversationId, String profileId)>(
        (ref) {
  return (String conversationId, String profileId) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    await chatRepo.markConversationAsRead(
      conversationId: conversationId,
      profileId: profileId,
    );

    // Invalidar providers relevantes para refrescar estado en UI
    ref.invalidate(realtimeMessagesProvider(conversationId));
    ref.invalidate(userConversationsProvider(profileId));
    ref.invalidate(realtimeConversationsProvider(profileId));
  };
});
