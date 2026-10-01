import 'package:equatable/equatable.dart';

/// Representa a un **integrante del torneo**.
///
/// Esta es una **entidad de dominio**: Dart puro, sin dependencias de
/// Flutter, Isar, ni APIs. Es el corazón del negocio.
class Member extends Equatable {
  /// Identificador único (UUID v4).
  final String id;

  /// Nombre visible del concursante.
  final String name;

  /// Índice en la paleta de colores [AppColors.memberColors].
  /// Se guarda como `int` para no depender de Flutter en el dominio.
  final int colorIndex;

  /// Momento en que se agregó al torneo.
  final DateTime createdAt;

  const Member({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.createdAt,
  });

  /// Crea una copia con campos modificados.
  /// Útil para actualizaciones sin mutar la entidad original (inmutabilidad).
  Member copyWith({
    String? id,
    String? name,
    int? colorIndex,
    DateTime? createdAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Devuelve las iniciales del nombre (máx. 2 caracteres) para el avatar.
  /// Ej: "Juan Pérez" → "JP", "Ana" → "A".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// `equatable` compara por estos campos.
  /// Dos instancias con los mismos valores son consideradas iguales.
  @override
  List<Object?> get props => [id, name, colorIndex, createdAt];

  @override
  String toString() => 'Member(id: $id, name: $name, colorIndex: $colorIndex)';
}