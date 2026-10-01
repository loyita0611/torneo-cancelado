import 'package:equatable/equatable.dart';

import 'ranking_entry.dart';

/// Resultado completo del **cierre de mes** del torneo.
///
/// Contiene:
/// - El mes representado.
/// - El ranking completo de ese mes.
/// - El/los ganador(es) (puede haber empate).
/// - La evolución semanal de cada integrante.
class MonthlyResult extends Equatable {
  /// Primer día del mes representado (ej. 2025-10-01).
  final DateTime month;

  /// Ranking completo del mes, ordenado de mayor a menor.
  final List<RankingEntry> ranking;

  /// Entradas empatadas en el primer lugar.
  /// Si no hay empate, contiene exactamente una.
  /// Si el mes no tiene estrellas, está vacía.
  final List<RankingEntry> winners;

  /// ¿Hubo empate en el primer lugar?
  final bool hasTie;

  /// Cantidad de semanas (ISO) que tocan este mes.
  /// Normalmente 4, 5 o 6.
  final int weeksInMonth;

  /// Estrellas por semana de cada integrante.
  /// `Map<memberId, List<int>>` donde la lista tiene `weeksInMonth` entradas.
  /// Índice 0 = primera semana del mes, índice n-1 = última.
  final Map<String, List<int>> weeklyEvolution;

  const MonthlyResult({
    required this.month,
    required this.ranking,
    required this.winners,
    required this.hasTie,
    required this.weeksInMonth,
    required this.weeklyEvolution,
  });

  /// ¿El mes tiene algún dato?
  bool get hasData => ranking.any((e) => e.stars > 0);

  /// Total de estrellas repartidas en el mes.
  int get totalStars => ranking.fold(0, (sum, entry) => sum + entry.stars);

  /// Primer lugar (o `null` si nadie tiene estrellas).
  RankingEntry? get topWinner => winners.isEmpty ? null : winners.first;

  /// Años + mes formateado, ej. "2025-10".
  String get monthKey =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
    month,
    ranking,
    winners,
    hasTie,
    weeksInMonth,
    weeklyEvolution,
  ];

  @override
  String toString() =>
      'MonthlyResult($monthKey: ${winners.length} ganador(es), '
      '${ranking.length} integrantes)';
}
