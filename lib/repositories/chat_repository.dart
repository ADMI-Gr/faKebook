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

  // === Eliminar (ocultar) un mensaje ===
  Future<void> deleteMessage(String messageId) async {
    await supabase
        .from('messages')
        .update({'is_deleted': true}).eq('id', messageId);
  }

  // === Abandonar o eliminar conversación (solo para el usuario actual) ===
  Future<void> leaveConversation({
    required String conversationId,
    required String profileId,
  }) async {
    // Verificar el tipo de conversación
    final convoResponse = await supabase
        .from('conversations')
        .select('kind, metadata')
        .eq('id', conversationId)
        .single();

    final kind = convoResponse['kind'] as String;

    // Si es un grupo, verificar si es admin
    if (kind == 'group') {
      final metadata = convoResponse['metadata'] as Map<String, dynamic>?;
      final admins = List<String>.from(metadata?['admins'] ?? []);

      // Si es admin y es el único admin, debe asignar el rol antes de salir
      if (admins.contains(profileId) && admins.length == 1) {
        throw Exception(
            'Eres el único administrador. Debes asignar el rol de administrador a otro participante antes de salir del grupo.');
      }

      // Si es admin pero no el único, removerlo de la lista de admins
      if (admins.contains(profileId)) {
        admins.remove(profileId);
        final updatedMetadata = Map<String, dynamic>.from(metadata ?? {});
        updatedMetadata['admins'] = admins;

        await supabase
            .from('conversations')
            .update({'metadata': updatedMetadata}).eq('id', conversationId);
      }
    }

    // Remover al participante de la conversación
    await supabase.from('conversation_participants').delete().match({
      'conversation_id': conversationId,
      'profile_id': profileId,
    });
  }

  // === Verificar si un usuario es admin de una conversación ===
  // ✅ CORREGIDO: Ahora busca en metadata.admins en lugar de un campo 'role'
  Future<bool> isUserAdmin({
    required String conversationId,
    required String profileId,
  }) async {
    final response = await supabase
        .from('conversations')
        .select('metadata')
        .eq('id', conversationId)
        .maybeSingle();

    if (response == null) return false;

    final metadata = response['metadata'] as Map<String, dynamic>?;
    if (metadata == null) return false;

    final admins = metadata['admins'] as List<dynamic>?;
    if (admins == null) return false;

    return admins.contains(profileId);
  }

  // === Eliminar conversación completa ===
  Future<void> deleteConversation({
    required String conversationId,
    required String profileId,
  }) async {
    print(
        'Ingresando a deleteConversation con conversationId: $conversationId y profileId: $profileId');

    // Obtener información de la conversación
    final convoResponse = await supabase
        .from('conversations')
        .select('kind, metadata')
        .eq('id', conversationId)
        .single();

    print('Información de la conversación: $convoResponse');
    final kind = convoResponse['kind'] as String;

    // Si es un chat grupal, verificar que sea admin
    if (kind == 'group') {
      print('Es un chat grupal, verificando si el usuario es admin...');
      final isAdmin = await isUserAdmin(
        conversationId: conversationId,
        profileId: profileId,
      );
      print('¿El usuario es admin? $isAdmin');

      if (!isAdmin) {
        print('El usuario no es admin, lanzando excepción...');
        throw Exception(
            'Solo los administradores pueden eliminar chats grupales');
      }
    }

    // Si es chat 1 a 1 o el usuario es admin, eliminar la conversación
    // Los mensajes y participantes se eliminan automáticamente por CASCADE
    await supabase.from('conversations').delete().eq('id', conversationId);
  }

  // === MÉTODO ADICIONAL: Agregar admin a un grupo ===
  Future<void> addAdminToGroup({
    required String conversationId,
    required String newAdminId,
    required String requesterId,
  }) async {
    // Verificar que el solicitante sea admin
    final isAdmin = await isUserAdmin(
      conversationId: conversationId,
      profileId: requesterId,
    );

    if (!isAdmin) {
      throw Exception('Solo los administradores pueden agregar nuevos admins');
    }

    // Obtener metadata actual
    final response = await supabase
        .from('conversations')
        .select('metadata')
        .eq('id', conversationId)
        .single();

    final metadata = Map<String, dynamic>.from(response['metadata'] ?? {});
    final admins = List<String>.from(metadata['admins'] ?? []);

    // Agregar nuevo admin si no existe
    if (!admins.contains(newAdminId)) {
      admins.add(newAdminId);
      metadata['admins'] = admins;

      await supabase
          .from('conversations')
          .update({'metadata': metadata}).eq('id', conversationId);
    }
  }

  // === MÉTODO ADICIONAL: Remover admin de un grupo ===
  Future<void> removeAdminFromGroup({
    required String conversationId,
    required String adminIdToRemove,
    required String requesterId,
  }) async {
    // Verificar que el solicitante sea admin
    final isAdmin = await isUserAdmin(
      conversationId: conversationId,
      profileId: requesterId,
    );

    if (!isAdmin) {
      throw Exception('Solo los administradores pueden remover admins');
    }

    // Obtener metadata actual
    final response = await supabase
        .from('conversations')
        .select('metadata')
        .eq('id', conversationId)
        .single();

    final metadata = Map<String, dynamic>.from(response['metadata'] ?? {});
    final admins = List<String>.from(metadata['admins'] ?? []);

    // Verificar que no sea el último admin
    if (admins.length <= 1) {
      throw Exception('No se puede eliminar al último administrador del grupo');
    }

    // Remover admin
    admins.remove(adminIdToRemove);
    metadata['admins'] = admins;

    await supabase
        .from('conversations')
        .update({'metadata': metadata}).eq('id', conversationId);
  }

  // === Editar información del grupo (solo admins) ===
  Future<void> updateGroupInfo({
    required String conversationId,
    required String requesterId,
    String? title,
    String? description,
    String? avatarUrl,
  }) async {
    // Verificar que el usuario sea admin
    final isAdmin = await isUserAdmin(
      conversationId: conversationId,
      profileId: requesterId,
    );

    if (!isAdmin) {
      throw Exception(
          'Solo los administradores pueden editar la información del grupo');
    }

    // Obtener metadata actual
    final response = await supabase
        .from('conversations')
        .select('metadata')
        .eq('id', conversationId)
        .single();

    final metadata = Map<String, dynamic>.from(response['metadata'] ?? {});

    // Actualizar solo los campos proporcionados
    if (title != null) metadata['title'] = title;
    if (description != null) metadata['description'] = description;
    if (avatarUrl != null) metadata['avatarUrl'] = avatarUrl;

    // Guardar cambios
    await supabase
        .from('conversations')
        .update({'metadata': metadata}).eq('id', conversationId);
  }

  // === Transferir propiedad del grupo (admin a otro participante) ===
  Future<void> transferGroupOwnership({
    required String conversationId,
    required String currentAdminId,
    required String newAdminId,
  }) async {
    // Verificar que el solicitante sea admin
    final isAdmin = await isUserAdmin(
      conversationId: conversationId,
      profileId: currentAdminId,
    );

    if (!isAdmin) {
      throw Exception(
          'Solo los administradores pueden transferir la propiedad');
    }

    // Verificar que el nuevo admin sea participante del grupo
    final participantResponse = await supabase
        .from('conversation_participants')
        .select()
        .eq('conversation_id', conversationId)
        .eq('profile_id', newAdminId)
        .maybeSingle();

    if (participantResponse == null) {
      throw Exception('El usuario debe ser participante del grupo');
    }

    // Obtener metadata actual
    final response = await supabase
        .from('conversations')
        .select('metadata')
        .eq('id', conversationId)
        .single();

    final metadata = Map<String, dynamic>.from(response['metadata'] ?? {});
    final admins = List<String>.from(metadata['admins'] ?? []);

    // Agregar nuevo admin si no existe
    if (!admins.contains(newAdminId)) {
      admins.add(newAdminId);
      metadata['admins'] = admins;

      await supabase
          .from('conversations')
          .update({'metadata': metadata}).eq('id', conversationId);
    }
  }

  // === MÉTODO: Marcar conversación como leída para un participante ===
  Future<void> markConversationAsRead({
    required String conversationId,
    required String profileId,
  }) async {
    // Guardar timestamp UTC como ISO string (esto no funciona porque se tiene que hacer algo en supabase)
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await supabase
        .from('conversation_participants')
        .update({'last_read': nowIso})
        .match({
      'conversation_id': conversationId,
      'profile_id': profileId,
    });
  }
}
