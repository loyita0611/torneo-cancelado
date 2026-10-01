import 'package:equatable/equatable.dart';

class StarEvent extends Equatable {
  /// Identificador único del evento (UUID v4).
  final String id;

  /// ID del [Member] al que pertenece esta estrella.
  final String memberId;

  /// Momento exacto en que se otorgó la estrella.
  /// Aquí se guarda tanto el día como la hora.
  final DateTime timestamp;

  /// Nota opcional: qué dijo el integrante para ganarse la estrella.
  /// Ej: "dijo 'literalmente'", "dijo 'o sea'", etc.
  final String? note;

  const StarEvent({
    required this.id,
    required this.memberId,
    required this.timestamp,
    this.note,
  });

  /// Crea una copia con campos modificados.
  StarEvent copyWith({
    String? id,
    String? memberId,
    DateTime? timestamp,
    String? note,
  }) {
    return StarEvent(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  /// ¿Esta estrella fue otorgada hoy?
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  /// ¿Esta estrella fue otorgada esta semana (lunes a domingo)?
  bool get isThisWeek {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = DateTime(
      sunday.year,
      sunday.month,
      sunday.day,
      23,
      59,
      59,
      999,
    );

    return !timestamp.isBefore(startOfWeek) && !timestamp.isAfter(endOfWeek);
  }

  /// ¿Esta estrella fue otorgada este mes?
  bool get isThisMonth {
    final now = DateTime.now();
    return timestamp.year == now.year && timestamp.month == now.month;
  }

  /// Fecha formateada para mostrar en el historial.
  /// Ej: "01/10 14:35".
  String get formattedTimestamp {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(timestamp.day)}/${two(timestamp.month)} '
        '${two(timestamp.hour)}:${two(timestamp.minute)}';
  }

  @override
  List<Object?> get props => [id, memberId, timestamp, note];

  @override
  String toString() =>
      'StarEvent(id: $id, memberId: $memberId, at: $timestamp)';
}
