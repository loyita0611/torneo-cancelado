import '../../domain/entities/star_event.dart';

/// Modelo de datos para [StarEvent].
///
/// Serializa a/desde JSON y convierte a/desde la entidad de dominio.
class StarEventModel {
  final String id;
  final String memberId;
  final DateTime timestamp;
  final String? note;

  const StarEventModel({
    required this.id,
    required this.memberId,
    required this.timestamp,
    this.note,
  });

  factory StarEventModel.fromJson(Map<String, dynamic> json) {
    return StarEventModel(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
  };

  StarEvent toEntity() =>
      StarEvent(id: id, memberId: memberId, timestamp: timestamp, note: note);

  factory StarEventModel.fromEntity(StarEvent event) => StarEventModel(
    id: event.id,
    memberId: event.memberId,
    timestamp: event.timestamp,
    note: event.note,
  );
}
