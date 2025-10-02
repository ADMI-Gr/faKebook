import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

class PostModelRepository {
  final SupabaseClient _client;

  PostModelRepository(this._client);

  /// Crear un nuevo postModel
  Future<PostModel?> createPostModel({
    required String authorId,
    String? content,
    Map<String, dynamic>? contentJson,
    String visibility = "public",
    String? language,
    String? replyTo,
  }) async {
    final response = await _client
        .from('postModels')
        .insert({
          'author_id': authorId,
          'content': content,
          'content_json': contentJson ?? {},
          'visibility': visibility,
          'language': language,
          'reply_to': replyTo,
        })
        .select()
        .single();

    return PostModel.fromMap(response);
  }

  /// Obtener postModels de un usuario (ordenados por fecha)
  Future<List<PostModel>> getPostModelsByUser(String userId) async {
    final response = await _client
        .from('postModels')
        .select()
        .eq('author_id', userId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    return (response as List).map((item) => PostModel.fromMap(item)).toList();
  }

  /// Obtener feed público (ejemplo simple)
  Future<List<PostModel>> getFeed() async {
    final response = await _client
        .from('postModels')
        .select()
        .eq('visibility', 'public')
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List).map((item) => PostModel.fromMap(item)).toList();
  }

  /// Actualizar postModel (solo si es del autor)
  Future<PostModel?> updatePostModel({
    required String postModelId,
    required String authorId,
    String? content,
    Map<String, dynamic>? contentJson,
    String? visibility,
    String? language,
    bool? isPinned,
  }) async {
    final response = await _client
        .from('postModels')
        .update({
          if (content != null) 'content': content,
          if (contentJson != null) 'content_json': contentJson,
          if (visibility != null) 'visibility': visibility,
          if (language != null) 'language': language,
          if (isPinned != null) 'is_pinned': isPinned,
        })
        .eq('id', postModelId)
        .eq('author_id', authorId) // seguridad básica
        .select()
        .single();

    return PostModel.fromMap(response);
  }

  /// Borrado
  Future<void> deletePostModel({
    required String postModelId,
    required String authorId,
  }) async {
    await _client
        .from('postModels')
        .update({
          'is_deleted': true,
        })
        .eq('id', postModelId)
        .eq('author_id', authorId);
  }

  /// Subir imagen (retorna URL pública)
  Future<String> uploadImage(File file, String filePath) async {
    try {
      // Subir el archivo al bucket 'posts' (o el nombre de tu bucket)
      final response = await _client.storage
          .from('posts') // Cambia 'posts' por el nombre de tu bucket
          .upload(filePath, file);

      // Obtener la URL pública del archivo subido
      final publicUrl = _client.storage.from('posts').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error en uploadImage: $e');
      throw Exception('No se pudo subir la imagen: $e');
    }
  }
}
