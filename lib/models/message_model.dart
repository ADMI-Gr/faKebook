class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? body;
  final Map<String, dynamic> bodyJson;
  final DateTime? createdAt;
  final bool isDeleted;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.body,
    this.bodyJson = const {},
    this.createdAt,
    this.isDeleted = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      conversationId: map['conversation_id'],
      senderId: map['sender_id'],
      body: map['body'],
      bodyJson: map['body_json'] ?? {},
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body,
      'body_json': bodyJson,
      'created_at': createdAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
