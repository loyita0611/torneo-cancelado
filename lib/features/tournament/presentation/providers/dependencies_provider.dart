import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torneo_cancelado/core/services/sound_service.dart';

import '../../data/datasources/tournament_local_datasource.dart';
import '../../data/repositories/tournament_repository_impl.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../../domain/usecases/add_member.dart';
import '../../domain/usecases/add_star.dart';
import '../../domain/usecases/get_daily_totals.dart';
import '../../domain/usecases/get_members.dart';
import '../../domain/usecases/get_monthly_winner.dart';
import '../../domain/usecases/get_weekly_totals.dart';

// =============================================================================
//  DATASOURCE
// =============================================================================

/// Fuente de datos local (archivo JSON).
/// Es un singleton durante toda la vida de la app.
final dataSourceProvider = Provider<TournamentLocalDataSource>((ref) {
  return TournamentLocalDataSource();
});

// =============================================================================
//  REPOSITORY
// =============================================================================

/// Implementación del contrato [TournamentRepository].
/// Se construye inyectando el datasource de arriba.
final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  final dataSource = ref.watch(dataSourceProvider);
  return TournamentRepositoryImpl(dataSource);
});

// =============================================================================
//  USE CASES
// =============================================================================
//
// Cada use case es un `Provider<T>` que recibe el repositorio por constructor.
// Cuando alguien hace `ref.watch(addMemberProvider)`, Riverpod construye
// (y cachea) el use case una sola vez.
//
// Si el repositorio cambia (por ejemplo en tests), todos los use cases
// que dependen de él se reconstruyen automáticamente.
// =============================================================================

/// **AddMember**: agrega un integrante nuevo.
final addMemberProvider = Provider<AddMember>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return AddMember(repository);
});

/// **AddStar**: otorga una estrella a un integrante.
final addStarProvider = Provider<AddStar>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return AddStar(repository);
});

/// **GetMembers**: lista de integrantes con su total de estrellas.
final getMembersProvider = Provider<GetMembers>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return GetMembers(repository);
});

/// **GetDailyTotals**: ranking del día.
final getDailyTotalsProvider = Provider<GetDailyTotals>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return GetDailyTotals(repository);
});

/// **GetWeeklyTotals**: ranking de la semana con evolución diaria.
final getWeeklyTotalsProvider = Provider<GetWeeklyTotals>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return GetWeeklyTotals(repository);
});

/// **GetMonthlyWinner**: resultado completo del mes.
final getMonthlyWinnerProvider = Provider<GetMonthlyWinner>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return GetMonthlyWinner(repository);
});

// =============================================================================
//  SERVICIOS
// =============================================================================

/// Servicio de audio. Singleton durante toda la vida de la app.
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(() => service.dispose());
  return service;
});
