import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../models/conversation_participant_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final supabase = Supabase.instance.client;

  // === Conversaciones del usuario ===
  Future<List<ConversationModel>> getUserConversations(String profileId) async {
    final response = await supabase
        .from('conversation_participants')
        .select('conversations(*)')
        .eq('profile_id', profileId);

    return (response as List)
        .map((e) => ConversationModel.fromMap(e['conversations']))
        .toList();
  }

  // === Crear nueva conversación ===
  Future<ConversationModel> createConversation({
    String kind = 'private',
    Map<String, dynamic>? metadata,
    required List<String> participantIds,
  }) async {
    final convo = await supabase
        .from('conversations')
        .insert({
          'kind': kind,
          'metadata': metadata ?? {},
        })
        .select()
        .single();

    final conversationId = convo['id'];

    for (final id in participantIds) {
      await supabase.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'profile_id': id,
      });
    }

    return ConversationModel.fromMap(convo);
  }

  // === Obtener mensajes de una conversación ===
  Future<List<MessageModel>> getMessages(String conversationId) async {
    final response = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => MessageModel.fromMap(e)).toList();
  }

  // === Enviar mensaje ===
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  }) async {
    final response = await supabase
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'body': body,
        })
        .select()
        .single();

    return MessageModel.fromMap(response);
  }

  // === Obtener participantes ===
  Future<List<ConversationParticipantModel>> getParticipants(
      String conversationId) async {
    final response = await supabase
        .from('conversation_participants')
        .select()
        .eq('conversation_id', conversationId);

    return (response as List)
        .map((e) => ConversationParticipantModel.fromMap(e))
        .toList();
  }

  // === Añadir participante ===
  Future<void> addParticipant(String conversationId, String profileId) async {
    await supabase.from('conversation_participants').insert({
      'conversation_id': conversationId,
      'profile_id': profileId,
    });
  }
}
