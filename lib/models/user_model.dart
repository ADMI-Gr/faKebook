class UserModel {
  final String id; // UUID
  final String username; // Nombre de usuario único, sin espacios ni caracteres especiales, es el que se ve con @ en el perfil
  final String? displayName; // Nombre para mostrar, este es el que se ve en grande en el perfil, puede ser nulo
  final String? bio; // Biografía del usuario, puede ser nula
  final Map<String, dynamic>? metadata; // Metadatos adicionales, puede ser nulo
  final String? avatarUrl; // URL del avatar del usuario, puede ser nulo
  final String email; // Email del usuario, único
  final DateTime createdAt; // Fecha de creación del perfil
  final DateTime updatedAt; // Fecha de última actualización del perfil, se actualiza cada vez que se cambia algo en el perfil

  // Constructor
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
  
  // Desde un mapa (por ejemplo, desde la base de datos)
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

  // A un mapa (por ejemplo, para guardar en la base de datos)
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
