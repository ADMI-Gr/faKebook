class ConversationParticipantModel {
  final String conversationId;
  final String profileId;
  final String? role;
  final DateTime? joinedAt;

  ConversationParticipantModel({
    required this.conversationId,
    required this.profileId,
    this.role,
    this.joinedAt,
  });

  factory ConversationParticipantModel.fromMap(Map<String, dynamic> map) {
    return ConversationParticipantModel(
      conversationId: map['conversation_id'],
      profileId: map['profile_id'],
      role: map['role'],
      joinedAt:
          map['joined_at'] != null ? DateTime.parse(map['joined_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversation_id': conversationId,
      'profile_id': profileId,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
    };
  }
}
