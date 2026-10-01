import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/date_helpers.dart';
import '../entities/member.dart';
import '../entities/ranking_entry.dart';
import '../repositories/tournament_repository.dart';

/// Parámetros que recibe [GetDailyTotals].
class GetDailyTotalsParams {
  /// Día de referencia. Si es `null`, se usa **hoy**.
  /// Se permite inyectar para tests o para ver "el ranking de ayer".
  final DateTime? date;

  /// Si `true`, solo incluye integrantes con al menos 1 estrella.
  /// Si `false` (default), incluye a todos con su conteo (aunque sea 0).
  final bool onlyWithStars;

  const GetDailyTotalsParams({this.date, this.onlyWithStars = false});
}

/// **Caso de uso**: calcular el ranking **diario** de estrellas.
///
/// Devuelve una lista de [RankingEntry] ordenada de mayor a menor cantidad
/// de estrellas del día indicado (o de hoy si no se especifica).
///
/// Ejemplo de uso:
/// ```dart
/// final result = await getDailyTotals.call(
///   const GetDailyTotalsParams(),
/// );
/// result.fold(
///   (f) => print('Error: ${f.message}'),
///   (ranking) => ranking.forEach((e) => print('${e.medal ?? e.position} ${e.name}: ${e.stars}')),
/// );
/// ```
class GetDailyTotals extends UseCase<List<RankingEntry>, GetDailyTotalsParams> {
  final TournamentRepository repository;

  GetDailyTotals(this.repository);

  @override
  Future<Either<Failure, List<RankingEntry>>> call(
    GetDailyTotalsParams params,
  ) async {
    try {
      // 1. Determinar el rango del día
      final reference = params.date ?? DateTime.now();
      final (from, to) = DateHelpers.dayRange(reference);

      // 2. Traer integrantes y estrellas en paralelo
      final results = await Future.wait([
        repository.getMembers(),
        repository.getStarsInRange(from, to),
      ]);
      final members = results[0] as List<Member>;
      final stars = results[1] as List<dynamic>;

      // 3. Contar estrellas por miembro
      final countsByMember = <String, int>{};
      for (final star in stars) {
        final id = star.memberId as String;
        countsByMember[id] = (countsByMember[id] ?? 0) + 1;
      }

      // 4. Construir las entradas (sin posición todavía)
      var entries = members
          .map(
            (m) => RankingEntry(
              member: m,
              stars: countsByMember[m.id] ?? 0,
              position: 0, // se asigna luego
            ),
          )
          .toList();

      // 5. Filtrar si se pidió "solo con estrellas"
      if (params.onlyWithStars) {
        entries = entries.where((e) => e.stars > 0).toList();
      }

      // 6. Ordenar: por estrellas desc, luego por nombre asc (desempate estable)
      entries.sort((a, b) {
        final byStars = b.stars.compareTo(a.stars);
        if (byStars != 0) return byStars;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      // 7. Asignar posiciones (con empates)
      final ranked = _assignPositions(entries);

      return Right(ranked);
    } catch (e) {
      return Left(DatabaseFailure('No se pudo calcular el ranking diario: $e'));
    }
  }

  /// Asigna posiciones teniendo en cuenta empates.
  ///
  /// Ejemplo:
  /// ```
  /// [5, 3, 3, 1] → [1, 2, 2, 4]
  /// ```
  /// Los que empatan comparten la misma posición y el siguiente salta.
  List<RankingEntry> _assignPositions(List<RankingEntry> sorted) {
    if (sorted.isEmpty) return sorted;

    final result = <RankingEntry>[];
    var lastStars = -1;
    var currentPosition = 0;

    // Primer paso: asignar posición y contar empates por grupo
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

    // Segundo paso: construir las entradas finales
    for (var i = 0; i < sorted.length; i++) {
      final pos = positions[i];
      result.add(
        sorted[i].copyWith(position: pos, tiedWith: tiedCounts[pos] ?? 1),
      );
    }

    return result;
  }
}

/// Extensión interna para copiar [RankingEntry] con posición.
extension _RankingEntryCopy on RankingEntry {
  RankingEntry copyWith({int? position, int? tiedWith}) {
    return RankingEntry(
      member: member,
      stars: stars,
      position: position ?? this.position,
      tiedWith: tiedWith ?? this.tiedWith,
    );
  }
}
