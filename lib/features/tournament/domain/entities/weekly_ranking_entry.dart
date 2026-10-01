import 'package:equatable/equatable.dart';

import 'member.dart';

/// Ranking semanal de un integrante, con el detalle **día por día**.
///
/// Se usa para mostrar:
/// ```
/// 🥇 Juan  ⭐⭐⭐⭐⭐ (5)   Lun●●● Mar●● Mié● Jue— Vie— Sáb— Dom—
/// ```
///
/// [dailyStars] indexa 0 = lunes, 6 = domingo (ISO 8601).
class WeeklyRankingEntry extends Equatable {
  /// El integrante.
  final Member member;

  /// Total de estrellas en la semana.
  final int weeklyStars;

  /// Conteo de estrellas por día de la semana.
  /// Índice 0 = lunes, 6 = domingo.
  /// Longitud siempre 7.
  final List<int> dailyStars;

  /// Posición en el ranking (1-based).
  final int position;

  /// Cuántos integrantes comparten esta posición.
  final int tiedWith;

  const WeeklyRankingEntry({
    required this.member,
    required this.weeklyStars,
    required this.dailyStars,
    required this.position,
    this.tiedWith = 1,
  });

  /// Atajos
  String get memberId => member.id;
  String get name => member.name;

  /// ¿Está en el podio?
  bool get isPodium => position <= 3;

  /// ¿Es el primero?
  bool get isWinner => position == 1;

  /// ¿Empatado?
  bool get isTied => tiedWith > 1;

  /// Medalla si está en podio.
  String? get medal {
    return switch (position) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
  }

  /// Nombres cortos de los días (lun–dom).
  static const List<String> dayLabels = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  /// Máximo del conteo diario (útil para escalar el gráfico de barras).
  int get maxDailyStars =>
      dailyStars.isEmpty ? 0 : dailyStars.reduce((a, b) => a > b ? a : b);

  /// Crea una copia con campos modificados.
  WeeklyRankingEntry copyWith({
    Member? member,
    int? weeklyStars,
    List<int>? dailyStars,
    int? position,
    int? tiedWith,
  }) {
    return WeeklyRankingEntry(
      member: member ?? this.member,
      weeklyStars: weeklyStars ?? this.weeklyStars,
      dailyStars: dailyStars ?? this.dailyStars,
      position: position ?? this.position,
      tiedWith: tiedWith ?? this.tiedWith,
    );
  }

  @override
  List<Object?> get props => [
    member,
    weeklyStars,
    dailyStars,
    position,
    tiedWith,
  ];

  @override
  String toString() =>
      'WeeklyRankingEntry(#$position ${member.name}: $weeklyStars)';
}
