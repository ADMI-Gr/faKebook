class BadgeModel {
  final String id; // UUID
  final String name; // Nombre de la insignia
  final String description; // Descripción de la insignia
  final BadgeMetadata? metadata; // Metadatos estéticos
  final DateTime createdAt; // Fecha de creación
  final DateTime updatedAt; // Fecha de última actualización

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // Desde un mapa (desde la base de datos)
  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      metadata: map['metadata'] != null
          ? BadgeMetadata.fromMap(map['metadata'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // A un mapa (para guardar en la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'metadata': metadata?.toMap(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // CopyWith para crear copias con modificaciones
  BadgeModel copyWith({
    String? id,
    String? name,
    String? description,
    BadgeMetadata? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Clase para los metadatos estéticos de la insignia
class BadgeMetadata {
  final String? borderColor; // Color del borde en formato hex
  final String? backgroundColor; // Color de fondo en formato hex
  final String? fontType; // Tipo de letra (bold, normal, italic, etc.)
  final String? iconName; // Nombre del ícono de Material Icons
  final List<String>? gradientColors; // Colores para gradiente [color1, color2]

  BadgeMetadata({
    this.borderColor,
    this.backgroundColor,
    this.fontType,
    this.iconName,
    this.gradientColors,
  });

  factory BadgeMetadata.fromMap(Map<String, dynamic> map) {
    return BadgeMetadata(
      borderColor: map['borderColor'] as String?,
      backgroundColor: map['backgroundColor'] as String?,
      fontType: map['fontType'] as String?,
      iconName: map['iconName'] as String?,
      gradientColors: map['gradientColors'] != null
          ? (map['gradientColors'] as List).cast<String>()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'borderColor': borderColor,
      'backgroundColor': backgroundColor,
      'fontType': fontType,
      'iconName': iconName,
      'gradientColors': gradientColors,
    };
  }

  BadgeMetadata copyWith({
    String? borderColor,
    String? backgroundColor,
    String? fontType,
    String? iconName,
    List<String>? gradientColors,
  }) {
    return BadgeMetadata(
      borderColor: borderColor ?? this.borderColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontType: fontType ?? this.fontType,
      iconName: iconName ?? this.iconName,
      gradientColors: gradientColors ?? this.gradientColors,
    );
  }
}
