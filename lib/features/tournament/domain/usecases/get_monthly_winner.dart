import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/date_helpers.dart';
import '../entities/member.dart';
import '../entities/monthly_result.dart';
import '../entities/ranking_entry.dart';
import '../entities/star_event.dart';
import '../repositories/tournament_repository.dart';

/// Parámetros que recibe [GetMonthlyWinner].
class GetMonthlyWinnerParams {
  /// Mes de referencia. Si es `null`, se usa **el mes actual**.
  final DateTime? date;

  const GetMonthlyWinnerParams({this.date});
}

/// **Caso de uso**: calcular el resultado completo del mes.
///
/// Devuelve un [MonthlyResult] con:
/// - El ranking mensual.
/// - El/los ganador(es) (con soporte para empates).
/// - La evolución semanal de cada integrante.
///
/// Devuelve:
/// - `Right(result)` con el resultado (aunque no haya datos).
/// - `Left(DatabaseFailure)` si algo falla.
class GetMonthlyWinner extends UseCase<MonthlyResult, GetMonthlyWinnerParams> {
  final TournamentRepository repository;

  GetMonthlyWinner(this.repository);

  @override
  Future<Either<Failure, MonthlyResult>> call(
    GetMonthlyWinnerParams params,
  ) async {
    try {
      // 1. Determinar el rango del mes
      final reference = params.date ?? DateTime.now();
      final (from, to) = DateHelpers.monthRange(reference);
      final monthStart = DateTime(reference.year, reference.month, 1);

      // 2. Traer integrantes y estrellas del mes en paralelo
      final results = await Future.wait([
        repository.getMembers(),
        repository.getStarsInRange(from, to),
      ]);
      final members = results[0] as List<Member>;
      final stars = results[1] as List<dynamic>;

      // 3. Contar estrellas por miembro (total del mes)
      final totalsByMember = <String, int>{};
      for (final raw in stars) {
        final star = raw as StarEvent;
        totalsByMember[star.memberId] =
            (totalsByMember[star.memberId] ?? 0) + 1;
      }

      // 4. Construir ranking (sin posición todavía)
      final entries = members
          .map(
            (m) => RankingEntry(
              member: m,
              stars: totalsByMember[m.id] ?? 0,
              position: 0,
            ),
          )
          .toList();

      // 5. Ordenar: por estrellas desc, luego por nombre asc
      entries.sort((a, b) {
        final byStars = b.stars.compareTo(a.stars);
        if (byStars != 0) return byStars;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      // 6. Asignar posiciones con empates
      final ranked = _assignPositions(entries);

      // 7. Identificar ganador(es) — todos los que tengan posición 1
      final winners = ranked
          .where((e) => e.position == 1 && e.stars > 0)
          .toList();
      final hasTie = winners.length > 1;

      // 8. Calcular semanas del mes y evolución semanal
      final weekNumbers = _isoWeeksInMonth(reference);
      final weeklyEvolution = _buildWeeklyEvolution(
        stars: stars.cast<StarEvent>(),
        weeks: weekNumbers,
        monthStart: monthStart,
      );

      // 9. Empaquetar el resultado
      final result = MonthlyResult(
        month: monthStart,
        ranking: ranked,
        winners: winners,
        hasTie: hasTie,
        weeksInMonth: weekNumbers.length,
        weeklyEvolution: weeklyEvolution,
      );

      return Right(result);
    } catch (e) {
      return Left(
        DatabaseFailure('No se pudo calcular el resultado mensual: $e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS PRIVADOS
  // ---------------------------------------------------------------------------

  /// Asigna posiciones teniendo en cuenta empates.
  /// [5, 3, 3, 1] → [1, 2, 2, 4]
  List<RankingEntry> _assignPositions(List<RankingEntry> sorted) {
    if (sorted.isEmpty) return sorted;

    final result = <RankingEntry>[];
    var lastStars = -1;
    var currentPosition = 0;

    final positions = <int>[];
    final tiedCounts = <int, int>{};

    for (var i = 0; i < sorted.length; i++) {
      final stars = sorted[i].stars;
      if (stars != lastStars) {
        currentPosition = i + 1;
        lastStars = stars;
      }
      positions.add(currentPosition);
      tiedCounts[currentPosition] = (tiedCounts[currentPosition] ?? 0) + 1;
    }

    for (var i = 0; i < sorted.length; i++) {
      final pos = positions[i];
      result.add(
        RankingEntry(
          member: sorted[i].member,
          stars: sorted[i].stars,
          position: pos,
          tiedWith: tiedCounts[pos] ?? 1,
        ),
      );
    }

    return result;
  }

  /// Devuelve los números de semana ISO (con duplicados eliminados) que
  /// tocan el mes de [reference], ordenados ascendentemente.
  ///
  /// Ej: octubre 2025 → [40, 41, 42, 43, 44]
  List<int> _isoWeeksInMonth(DateTime reference) {
    final lastDay = DateTime(reference.year, reference.month + 1, 0).day;
    final weeks = <int>{};

    for (var day = 1; day <= lastDay; day++) {
      final d = DateTime(reference.year, reference.month, day);
      weeks.add(DateHelpers.isoWeekNumber(d));
    }

    return weeks.toList()..sort();
  }

  /// Construye `{ memberId: [starsW1, starsW2, ...] }` para el mes dado.
  ///
  /// Cada lista tiene exactamente `weeks.length` posiciones.
  Map<String, List<int>> _buildWeeklyEvolution({
    required List<StarEvent> stars,
    required List<int> weeks,
    required DateTime monthStart,
  }) {
    final evolution = <String, List<int>>{};
    final weekIndex = <int, int>{
      for (var i = 0; i < weeks.length; i++) weeks[i]: i,
    };

    for (final star in stars) {
      // Ignorar estrellas fuera del mes (defensivo)
      if (star.timestamp.year != monthStart.year ||
          star.timestamp.month != monthStart.month) {
        continue;
      }

      final week = DateHelpers.isoWeekNumber(star.timestamp);
      final idx = weekIndex[week];
      if (idx == null) continue;

      evolution.putIfAbsent(
        star.memberId,
        () => List<int>.filled(weeks.length, 0),
      );
      evolution[star.memberId]![idx]++;
    }

    return evolution;
  }
}
