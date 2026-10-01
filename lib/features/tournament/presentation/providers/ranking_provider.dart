import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/monthly_result.dart';
import '../../domain/entities/ranking_entry.dart';
import '../../domain/entities/weekly_ranking_entry.dart';
import '../../domain/usecases/get_daily_totals.dart';
import '../../domain/usecases/get_monthly_winner.dart';
import '../../domain/usecases/get_weekly_totals.dart';
import 'dependencies_provider.dart';

// =============================================================================
//  PERÍODO ACTIVO
// =============================================================================

/// Períodos disponibles en la pantalla de ranking.
enum RankingPeriod { daily, weekly, monthly }

/// Pestaña actualmente seleccionada en el ranking.
/// Se puede cambiar desde la UI con:
/// ```dart
/// ref.read(selectedRankingPeriodProvider.notifier).state = RankingPeriod.weekly;
/// ```
final selectedRankingPeriodProvider = StateProvider<RankingPeriod>(
  (ref) => RankingPeriod.daily,
);

// =============================================================================
//  FECHA DE REFERENCIA
// =============================================================================
//
// La pantalla de ranking permite navegar hacia atrás/adelante:
// - "Ver el ranking de ayer"
// - "Ver la semana pasada"
// - "Ver el mes de septiembre"
//
// En vez de guardar un `DateTime` distinto por período, guardamos una
// única fecha de referencia y cada provider la usa según su granularidad.
// =============================================================================

/// Fecha de referencia para todos los rankings.
/// Al cambiarla, los `FutureProvider` que la observan se reconstruyen.
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// =============================================================================
//  RANKING DIARIO
// =============================================================================

/// Ranking del día seleccionado.
/// Ordenado de mayor a menor cantidad de estrellas.
final dailyRankingProvider = FutureProvider<List<RankingEntry>>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final useCase = ref.watch(getDailyTotalsProvider);

  final result = await useCase.call(GetDailyTotalsParams(date: date));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (ranking) => ranking,
  );
});

/// Ranking diario **solo con integrantes que tienen al menos 1 estrella**.
/// Útil para un widget compacto en la HomePage.
final dailyRankingOnlyWithStarsProvider = FutureProvider<List<RankingEntry>>((
  ref,
) async {
  final date = ref.watch(selectedDateProvider);
  final useCase = ref.watch(getDailyTotalsProvider);

  final result = await useCase.call(
    GetDailyTotalsParams(date: date, onlyWithStars: true),
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (ranking) => ranking,
  );
});

// =============================================================================
//  RANKING SEMANAL
// =============================================================================

/// Ranking de la semana que contiene a [selectedDateProvider],
/// con evolución día por día de cada integrante.
final weeklyRankingProvider = FutureProvider<List<WeeklyRankingEntry>>((
  ref,
) async {
  final date = ref.watch(selectedDateProvider);
  final useCase = ref.watch(getWeeklyTotalsProvider);

  final result = await useCase.call(GetWeeklyTotalsParams(date: date));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (ranking) => ranking,
  );
});

// =============================================================================
//  RANKING MENSUAL
// =============================================================================

/// Resultado completo del mes: ranking + ganador(es) + evolución semanal.
///
/// Devuelve un [MonthlyResult] que contiene todo lo necesario para
/// pintar la pantalla de cierre del mes:
/// - `ranking` → tabla de posiciones
/// - `winners` → podio (1 o varios si hay empate)
/// - `hasTie` → para mostrar "empate" en el banner
/// - `weeklyEvolution` → gráfico de barras semana a semana
final monthlyResultProvider = FutureProvider<MonthlyResult>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final useCase = ref.watch(getMonthlyWinnerProvider);

  final result = await useCase.call(GetMonthlyWinnerParams(date: date));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (monthly) => monthly,
  );
});

// =============================================================================
//  HELPERS DE NAVEGACIÓN
// =============================================================================
//
// Funciones de conveniencia para mover la fecha de referencia
// según el período activo (con flechas ← →).
// =============================================================================

/// Extensión con operaciones útiles sobre [RankingPeriod].
extension RankingPeriodX on RankingPeriod {
  /// Devuelve una nueva fecha desplazada ±1 unidad según el período.
  ///
  /// Ejemplos:
  /// - `daily.jumpTo(2025-10-01, +1)` → `2025-10-02`
  /// - `weekly.jumpTo(2025-10-01, -1)` → `2025-09-24` (7 días atrás)
  /// - `monthly.jumpTo(2025-10-15, +1)` → `2025-11-15`
  DateTime jumpTo(DateTime base, int delta) {
    switch (this) {
      case RankingPeriod.daily:
        return base.add(Duration(days: delta));
      case RankingPeriod.weekly:
        return base.add(Duration(days: 7 * delta));
      case RankingPeriod.monthly:
        // En mes, sumamos al mes en sí (no a los días), respetando
        // el día si existe; si no (ej. 31 de octubre → noviembre),
        // Dart normaliza al último día del mes destino.
        final targetMonth = base.month + delta;
        return DateTime(base.year, targetMonth, base.day);
    }
  }
}
