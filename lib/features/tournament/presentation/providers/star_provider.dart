import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torneo_cancelado/features/tournament/presentation/providers/ranking_provider.dart';

import '../../domain/entities/member.dart';
import '../../domain/entities/star_event.dart';
import '../../domain/usecases/add_star.dart';
import 'dependencies_provider.dart';
import 'member_provider.dart';

// =============================================================================
//  INTEGRANTE ESPECÍFICO
// =============================================================================

/// Obtiene un integrante por su ID.
/// Devuelve `null` si no existe.
final memberByIdProvider = FutureProvider.family<Member?, String>((
  ref,
  memberId,
) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getMemberById(memberId);
});

// =============================================================================
//  HISTORIAL DE ESTRELLAS
// =============================================================================

/// Historial completo de estrellas de un integrante,
/// ordenado de la más reciente a la más antigua.
final memberHistoryProvider = FutureProvider.family<List<StarEvent>, String>((
  ref,
  memberId,
) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getStarsByMember(memberId);
});

// =============================================================================
//  TOTALES POR PERÍODO
// =============================================================================

/// Contenedor de los 4 totales que muestra el detalle del integrante.
class MemberStarsTotals {
  final int today;
  final int week;
  final int month;
  final int total;

  const MemberStarsTotals({
    required this.today,
    required this.week,
    required this.month,
    required this.total,
  });

  static const empty = MemberStarsTotals(today: 0, week: 0, month: 0, total: 0);
}

/// Totales de un integrante: hoy, semana, mes y total.
///
/// Usa un solo llamado al repositorio (todo el histórico) y calcula
/// los 4 totales en memoria. Mucho más eficiente que 4 consultas.
final memberStarsTotalsProvider =
    FutureProvider.family<MemberStarsTotals, String>((ref, memberId) async {
      final repository = ref.watch(tournamentRepositoryProvider);

      // Traemos todo el histórico del miembro (1 sola consulta)
      final events = await repository.getStarsByMember(memberId);

      // Calculamos cada total usando los getters de la entidad StarEvent.
      final today = events.where((e) => e.isToday).length;
      final week = events.where((e) => e.isThisWeek).length;
      final month = events.where((e) => e.isThisMonth).length;
      final total = events.length;

      return MemberStarsTotals(
        today: today,
        week: week,
        month: month,
        total: total,
      );
    });

// =============================================================================
//  CONTROLLER PARA AGREGAR ESTRELLA
// =============================================================================

/// Estado de la acción "agregar estrella".
enum AddStarStatus { idle, loading, success, error }

class AddStarState {
  final AddStarStatus status;

  /// Última estrella registrada (útil para mostrar el timestamp exacto).
  final StarEvent? lastEvent;

  final String? errorMessage;

  const AddStarState({
    this.status = AddStarStatus.idle,
    this.lastEvent,
    this.errorMessage,
  });

  bool get isLoading => status == AddStarStatus.loading;
  bool get isError => status == AddStarStatus.error;
  bool get isSuccess => status == AddStarStatus.success;

  AddStarState copyWith({
    AddStarStatus? status,
    StarEvent? lastEvent,
    String? errorMessage,
  }) {
    return AddStarState(
      status: status ?? this.status,
      lastEvent: lastEvent ?? this.lastEvent,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Controller encargado de **agregar una estrella** a un integrante.
///
/// Después de agregar con éxito:
/// - Invalida el historial y los totales del miembro.
/// - Invalida la lista global (para que el contador de la HomePage
///   se actualice).
/// - Invalida rankings (para que si el usuario navega al ranking,
///   vea datos frescos).
class AddStarController extends StateNotifier<AddStarState> {
  final Ref _ref;

  AddStarController(this._ref) : super(const AddStarState());

  /// Agrega una estrella al miembro [memberId].
  /// Devuelve `true` si todo salió bien.
  ///
  /// [note] es opcional: qué dijo el integrante.
  Future<bool> addStar({required String memberId, String? note}) async {
    state = state.copyWith(status: AddStarStatus.loading);

    final useCase = _ref.read(addStarProvider);
    final result = await useCase.call(
      AddStarParams(memberId: memberId, note: note),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: AddStarStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (event) {
        state = AddStarState(status: AddStarStatus.success, lastEvent: event);
        _invalidateCaches(memberId);
        return true;
      },
    );
  }

  /// Reinicia el estado para el próximo tap.
  void reset() {
    state = const AddStarState();
  }

  /// Invalida todos los providers que dependen de las estrellas.
  void _invalidateCaches(String memberId) {
    // Específicos del integrante
    _ref.invalidate(memberHistoryProvider(memberId));
    _ref.invalidate(memberStarsTotalsProvider(memberId));

    // Lista global
    _ref.invalidate(membersWithStarsProvider);

    // Rankings (diario, semanal, mensual)
    _ref.invalidate(dailyRankingProvider);
    _ref.invalidate(dailyRankingOnlyWithStarsProvider);
    _ref.invalidate(weeklyRankingProvider);
    _ref.invalidate(monthlyResultProvider);
  }
}

/// Provider del [AddStarController].
final addStarControllerProvider =
    StateNotifierProvider<AddStarController, AddStarState>((ref) {
      return AddStarController(ref);
    });
