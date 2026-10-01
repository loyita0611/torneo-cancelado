import '../../domain/entities/member.dart';

/// Modelo de datos para [Member].
///
/// Sabe cómo serializarse a/desde JSON, y cómo convertirse a/desde la
/// entidad de dominio. **Solo la capa `data` conoce este modelo**.
class MemberModel {
  final String id;
  final String name;
  final int colorIndex;
  final DateTime createdAt;

  const MemberModel({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.createdAt,
  });

  /// Crea un modelo desde un mapa JSON.
  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorIndex: json['colorIndex'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convierte el modelo a un mapa JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorIndex': colorIndex,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Convierte a la entidad de dominio [Member].
  Member toEntity() =>
      Member(id: id, name: name, colorIndex: colorIndex, createdAt: createdAt);

  /// Construye un modelo desde la entidad de dominio.
  factory MemberModel.fromEntity(Member member) => MemberModel(
    id: member.id,
    name: member.name,
    colorIndex: member.colorIndex,
    createdAt: member.createdAt,
  );
}
