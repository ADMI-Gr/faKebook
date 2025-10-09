class ConversationModel {
  final String id;
  final String kind;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  ConversationModel({
    required this.id,
    required this.kind,
    required this.metadata,
    this.createdAt,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'],
      kind: map['kind'] ?? 'private',
      metadata: map['metadata'] ?? {},
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kind': kind,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
