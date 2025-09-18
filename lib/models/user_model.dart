class UserModel {
  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final Map<String, dynamic>? metadata;
  final String? avatarUrl;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel(
    this.bio,
    this.metadata,
    this.updatedAt, {
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      map['bio'] as String?,
      map['metadata'] as Map<String, dynamic>?,
      DateTime.parse(map['updated_at']),
      id: map['id'] as String,
      email: map['email'] as String,
      username: map['username'] as String,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
