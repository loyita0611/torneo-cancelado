import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/member_with_stars.dart';
import '../../domain/usecases/add_member.dart';
import 'dependencies_provider.dart';

// =============================================================================
//  LISTA DE INTEGRANTES CON TOTAL DE ESTRELLAS
// =============================================================================

/// Expone la lista de integrantes **con su total histórico de estrellas**.
///
/// Se usa en la `HomePage` para pintar la lista principal.
///
/// **Refresco:** después de agregar/eliminar un integrante o agregar una
/// estrella, hay que llamar a:
/// ```dart
/// ref.invalidate(membersWithStarsProvider);
/// ```
/// y Riverpod vuelve a ejecutar el use case automáticamente.
final membersWithStarsProvider = FutureProvider<List<MemberWithStars>>((
  ref,
) async {
  final useCase = ref.watch(getMembersProvider);
  final result = await useCase.call();

  // Either → FutureProvider
  // Si es Left, lanzamos una excepción para que la UI la muestre con .when().
  return result.fold(
    (failure) => throw Exception(failure.message),
    (list) => list,
  );
});

// =============================================================================
//  ESTADO DE OPERACIONES (agregar / eliminar)
// =============================================================================

/// Estado de una operación asíncrona en la UI.
///
/// Nos permite saber si hay algo en curso, si hubo error, o si terminó bien.
enum MemberActionStatus { idle, loading, success, error }

class MemberActionState {
  final MemberActionStatus status;
  final String? errorMessage;

  const MemberActionState({
    this.status = MemberActionStatus.idle,
    this.errorMessage,
  });

  bool get isLoading => status == MemberActionStatus.loading;
  bool get isError => status == MemberActionStatus.error;
  bool get isSuccess => status == MemberActionStatus.success;

  MemberActionState copyWith({
    MemberActionStatus? status,
    String? errorMessage,
  }) {
    return MemberActionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Controller encargado de **agregar y eliminar integrantes**.
///
/// Cuando la operación termina con éxito:
/// - Invalida [membersWithStarsProvider] para que se refresque la lista.
/// - Devuelve el control a la UI (que mostrará un SnackBar o cerrará el diálogo).
class MemberActionController extends StateNotifier<MemberActionState> {
  final Ref _ref;

  MemberActionController(this._ref) : super(const MemberActionState());

  /// Agrega un integrante. Devuelve `true` si todo salió bien.
  Future<bool> addMember({
    required String name,
    required int colorIndex,
  }) async {
    state = state.copyWith(status: MemberActionStatus.loading);

    final useCase = _ref.read(addMemberProvider);
    final result = await useCase.call(
      AddMemberParams(name: name, colorIndex: colorIndex),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: MemberActionStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (member) {
        state = state.copyWith(status: MemberActionStatus.success);
        // Refrescar lista
        _ref.invalidate(membersWithStarsProvider);
        return true;
      },
    );
  }

  /// Elimina un integrante por su ID.
  Future<bool> deleteMember(String id) async {
    state = state.copyWith(status: MemberActionStatus.loading);

    try {
      final repository = _ref.read(tournamentRepositoryProvider);
      await repository.deleteMember(id);

      state = state.copyWith(status: MemberActionStatus.success);
      _ref.invalidate(membersWithStarsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: MemberActionStatus.error,
        errorMessage: 'No se pudo eliminar: $e',
      );
      return false;
    }
  }

  /// Reinicia el estado (por ejemplo, al cerrar el diálogo).
  void reset() {
    state = const MemberActionState();
  }
}

/// Provider del [MemberActionController].
final memberActionControllerProvider =
    StateNotifierProvider<MemberActionController, MemberActionState>((ref) {
      return MemberActionController(ref);
    });

// =============================================================================
//  ESTADO DEL DIÁLOGO "AGREGAR INTEGRANTE"
// =============================================================================

/// Controla si el diálogo "Agregar Integrante" está abierto.
/// Simple StateProvider<boolean>.
final showAddMemberDialogProvider = StateProvider<bool>((ref) => false);
