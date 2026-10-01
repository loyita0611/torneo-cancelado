import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/star_event.dart';
import '../repositories/tournament_repository.dart';

/// Parámetros que recibe [AddStar].
class AddStarParams {
  /// ID del integrante que recibe la estrella.
  final String memberId;

  /// Nota opcional: qué dijo el integrante.
  /// Ej: "dijo 'literalmente'", "dijo 'o sea'".
  final String? note;

  /// Momento exacto en que se otorga la estrella.
  /// Si es `null`, se usa `DateTime.now()`.
  /// Se permite inyectar para tests determinísticos.
  final DateTime? timestamp;

  const AddStarParams({required this.memberId, this.note, this.timestamp});
}

/// **Caso de uso**: otorgar una estrella a un integrante.
///
/// Este es el caso de uso más frecuente del torneo: se ejecuta cada vez
/// que alguien dice algo "cancelable".
///
/// Validaciones que aplica:
/// 1. El integrante debe existir.
/// 2. El ID del integrante no puede estar vacío.
///
/// Devuelve:
/// - `Right(event)` con la estrella creada si todo sale bien.
/// - `Left(ValidationFailure)` si falla alguna validación.
/// - `Left(NotFoundFailure)` si el integrante no existe.
/// - `Left(DatabaseFailure)` si falla la base de datos.
class AddStar extends UseCase<StarEvent, AddStarParams> {
  final TournamentRepository repository;
  final Uuid _uuid;

  AddStar(this.repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, StarEvent>> call(AddStarParams params) async {
    // 1. Validar: memberId no vacío
    if (params.memberId.trim().isEmpty) {
      return const Left(
        ValidationFailure('El ID del integrante no puede estar vacío'),
      );
    }

    try {
      // 2. Validar: el integrante debe existir
      final member = await repository.getMemberById(params.memberId);
      if (member == null) {
        return Left(
          NotFoundFailure(
            'No existe un integrante con ID "${params.memberId}"',
          ),
        );
      }

      // 3. Normalizar la nota (trim, o null si queda vacía)
      final cleanNote = params.note?.trim();
      final note = (cleanNote == null || cleanNote.isEmpty) ? null : cleanNote;

      // 4. Crear el evento con timestamp
      final event = StarEvent(
        id: _uuid.v4(),
        memberId: params.memberId,
        timestamp: params.timestamp ?? DateTime.now(),
        note: note,
      );

      // 5. Persistir en el repositorio
      await repository.addStar(event);

      // 6. Devolver éxito
      return Right(event);
    } catch (e) {
      return Left(DatabaseFailure('No se pudo registrar la estrella: $e'));
    }
  }
}
