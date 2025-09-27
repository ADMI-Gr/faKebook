import 'dart:convert';

class PostModel {
  final String id;
  final String authorId;
  final String? content;
  final Map<String, dynamic> contentJson;
  final String visibility;
  final String? language;
  final String? replyTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isDeleted;

  PostModel({
    required this.id,
    required this.authorId,
    this.content,
    Map<String, dynamic>? contentJson,
    this.visibility = "public",
    this.language,
    this.replyTo,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isDeleted = false,
  }) : contentJson = contentJson ?? {};

  /// Convertir desde Supabase (map)
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      content: map['content'] as String?,
      contentJson: map['content_json'] != null
          ? Map<String, dynamic>.from(map['content_json'])
          : {},
      visibility: map['visibility'] ?? 'public',
      language: map['language'] as String?,
      replyTo: map['reply_to'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isPinned: map['is_pinned'] ?? false,
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  /// Convertir a Map (para enviar a Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author_id': authorId,
      'content': content,
      'content_json': contentJson,
      'visibility': visibility,
      'language': language,
      'reply_to': replyTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned,
      'is_deleted': isDeleted,
    };
  }

  /// Copiar con modificaciones
  PostModel copyWith({
    String? id,
    String? authorId,
    String? content,
    Map<String, dynamic>? contentJson,
    String? visibility,
    String? language,
    String? replyTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isDeleted,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      contentJson: contentJson ?? this.contentJson,
      visibility: visibility ?? this.visibility,
      language: language ?? this.language,
      replyTo: replyTo ?? this.replyTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() => jsonEncode(toMap());
}
