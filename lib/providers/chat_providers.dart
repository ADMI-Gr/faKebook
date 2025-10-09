import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/conversation_participant_model.dart';

// Repositorio base
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

/// 🗨️ Provider para obtener todas las conversaciones de un usuario
final userConversationsProvider =
    FutureProvider.family<List<ConversationModel>, String>(
        (ref, profileId) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return await chatRepo.getUserConversations(profileId);
});

/// 💬 Provider para obtener los mensajes de una conversación
final messagesProvider = FutureProvider.family<List<MessageModel>, String>(
    (ref, conversationId) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return await chatRepo.getMessages(conversationId);
});

/// 👥 Provider para obtener los participantes de una conversación
final participantsProvider =
    FutureProvider.family<List<ConversationParticipantModel>, String>(
        (ref, conversationId) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return await chatRepo.getParticipants(conversationId);
});

/// ✉️ Provider tipo `Notifier` para enviar mensajes
class SendMessageNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> send({
    required String conversationId,
    required String senderId,
    required String body,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await chatRepo.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        body: body,
      );
    });
  }
}

final sendMessageProvider =
    AutoDisposeAsyncNotifierProvider<SendMessageNotifier, void>(
        SendMessageNotifier.new);

/// ➕ Provider tipo `Notifier` para crear una nueva conversación
class CreateConversationNotifier
    extends AutoDisposeAsyncNotifier<ConversationModel?> {
  @override
  FutureOr<ConversationModel?> build() => null;

  Future<void> create({
    String kind = 'private',
    Map<String, dynamic>? metadata,
    required List<String> participantIds,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      return await chatRepo.createConversation(
        kind: kind,
        metadata: metadata,
        participantIds: participantIds,
      );
    });

    state = result;
  }
}

final createConversationProvider = AutoDisposeAsyncNotifierProvider<
    CreateConversationNotifier,
    ConversationModel?>(CreateConversationNotifier.new);
