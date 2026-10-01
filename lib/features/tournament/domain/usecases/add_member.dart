import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/member.dart';
import '../repositories/tournament_repository.dart';

/// Parámetros que recibe [AddMember].
class AddMemberParams {
  final String name;
  final int colorIndex;

  const AddMemberParams({required this.name, required this.colorIndex});
}

/// **Caso de uso**: agregar un nuevo integrante al torneo.
///
/// Validaciones que aplica:
/// 1. El nombre no puede estar vacío.
/// 2. El nombre no puede estar duplicado (case-insensitive).
///
/// Devuelve:
/// - `Right(member)` con el integrante creado si todo sale bien.
/// - `Left(ValidationFailure)` si falla alguna validación.
/// - `Left(DatabaseFailure)` si falla la base de datos.
class AddMember extends UseCase<Member, AddMemberParams> {
  final TournamentRepository repository;
  final Uuid _uuid;

  AddMember(this.repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, Member>> call(AddMemberParams params) async {
    // 1. Validar: nombre no vacío
    final cleanName = params.name.trim();
    if (cleanName.isEmpty) {
      return const Left(ValidationFailure('El nombre no puede estar vacío'));
    }

    try {
      // 2. Validar: nombre no duplicado (case-insensitive)
      final existing = await repository.getMembers();
      final isDuplicate = existing.any(
        (m) => m.name.toLowerCase() == cleanName.toLowerCase(),
      );
      if (isDuplicate) {
        return Left(
          ValidationFailure('Ya existe un integrante llamado "$cleanName"'),
        );
      }

      // 3. Crear la entidad Member
      final member = Member(
        id: _uuid.v4(),
        name: cleanName,
        colorIndex: params.colorIndex,
        createdAt: DateTime.now(),
      );

      // 4. Persistir en el repositorio
      final saved = await repository.addMember(member);

      // 5. Devolver éxito
      return Right(saved);
    } catch (e) {
      // 6. Cualquier error inesperado → Failure
      return Left(DatabaseFailure('No se pudo guardar el integrante: $e'));
    }
  }
}
