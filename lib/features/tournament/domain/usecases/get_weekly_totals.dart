import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/date_helpers.dart';
import '../entities/member.dart';
import '../entities/star_event.dart';
import '../entities/weekly_ranking_entry.dart';
import '../repositories/tournament_repository.dart';

/// Parámetros que recibe [GetWeeklyTotals].
class GetWeeklyTotalsParams {
  /// Fecha de referencia. Si es `null`, se usa **hoy**.
  /// Se puede inyectar para ver "la semana pasada", "la semana del 15/09", etc.
  final DateTime? date;

  /// Si `true`, solo incluye integrantes con al menos 1 estrella esa semana.
  final bool onlyWithStars;

  const GetWeeklyTotalsParams({this.date, this.onlyWithStars = false});
}

/// **Caso de uso**: calcular el ranking **semanal** de estrellas,
/// incluyendo el detalle día por día.
///
/// Devuelve una lista de [WeeklyRankingEntry] ordenada de mayor a menor
/// total semanal. Cada entrada incluye:
/// - `weeklyStars`: total de la semana
/// - `dailyStars`: lista de 7 enteros (lun–dom) con el conteo de cada día
/// - `position` y `tiedWith`: para pintar el podio
///
/// Ejemplo de uso:
/// ```dart
/// final result = await getWeeklyTotals.call(
///   const GetWeeklyTotalsParams(),
/// );
/// result.fold(
///   (f) => print('Error: ${f.message}'),
///   (ranking) => ranking.forEach((e) {
///     print('${e.medal ?? e.position} ${e.name}: ${e.weeklyStars} '
///           '→ ${e.dailyStars}');
///   }),
/// );
/// ```
class GetWeeklyTotals
    extends UseCase<List<WeeklyRankingEntry>, GetWeeklyTotalsParams> {
  final TournamentRepository repository;

  GetWeeklyTotals(this.repository);

  @override
  Future<Either<Failure, List<WeeklyRankingEntry>>> call(
    GetWeeklyTotalsParams params,
  ) async {
    try {
      // 1. Determinar el rango de la semana (lunes a domingo)
      final reference = params.date ?? DateTime.now();
      final (from, to) = DateHelpers.weekRange(reference);

      // 2. Traer integrantes y estrellas de la semana en paralelo
      final results = await Future.wait([
        repository.getMembers(),
        repository.getStarsInRange(from, to),
      ]);
      final members = results[0] as List<Member>;
      final stars = results[1] as List<dynamic>;

      // 3. Lunes de la semana (referencia para calcular el índice de día)
      final monday = DateTime(from.year, from.month, from.day);

      // 4. Conteos por miembro: total y por día
      final weeklyTotals = <String, int>{};
      final dailyTotals = <String, List<int>>{};

      for (final raw in stars) {
        final star = raw as StarEvent;
        final id = star.memberId;

        // Total semanal
        weeklyTotals[id] = (weeklyTotals[id] ?? 0) + 1;

        // Índice de día: 0 = lunes, 6 = domingo
        final starDay = DateTime(
          star.timestamp.year,
          star.timestamp.month,
          star.timestamp.day,
        );
        final dayIndex = starDay.difference(monday).inDays.clamp(0, 6);

        // Inicializar el array si no existe
        dailyTotals.putIfAbsent(id, () => List<int>.filled(7, 0));
        dailyTotals[id]![dayIndex]++;
      }

      // 5. Construir entries (sin posición todavía)
      var entries = members.map((m) {
        return WeeklyRankingEntry(
          member: m,
          weeklyStars: weeklyTotals[m.id] ?? 0,
          dailyStars: dailyTotals[m.id] ?? List<int>.filled(7, 0),
          position: 0,
        );
      }).toList();

      // 6. Filtrar si se pidió "solo con estrellas"
      if (params.onlyWithStars) {
        entries = entries.where((e) => e.weeklyStars > 0).toList();
      }

      // 7. Ordenar: por total desc, luego por nombre asc
      entries.sort((a, b) {
        final byStars = b.weeklyStars.compareTo(a.weeklyStars);
        if (byStars != 0) return byStars;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      // 8. Asignar posiciones con empates
      final ranked = _assignPositions(entries);

      return Right(ranked);
    } catch (e) {
      return Left(
        DatabaseFailure('No se pudo calcular el ranking semanal: $e'),
      );
    }
  }

  /// Asigna posiciones teniendo en cuenta empates.
  /// [5, 3, 3, 1] → [1, 2, 2, 4]
  List<WeeklyRankingEntry> _assignPositions(List<WeeklyRankingEntry> sorted) {
    if (sorted.isEmpty) return sorted;

    final result = <WeeklyRankingEntry>[];
    var lastStars = -1;
    var currentPosition = 0;

    final positions = <int>[];
    final tiedCounts = <int, int>{};

    for (var i = 0; i < sorted.length; i++) {
      final stars = sorted[i].weeklyStars;
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
        sorted[i].copyWith(position: pos, tiedWith: tiedCounts[pos] ?? 1),
      );
    }

    return result;
  }
}
