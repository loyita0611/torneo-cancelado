import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/member_with_stars.dart';
import '../repositories/tournament_repository.dart';

/// **Caso de uso**: obtener todos los integrantes junto con su total
/// histórico de estrellas.
///
/// Se usa en la pantalla principal para pintar la lista:
/// ```
/// Juan Pérez   | ⭐1 ⭐2 ⭐3
/// Ana López    | ⭐1 ⭐2
/// Carlos Ruiz  | (sin estrellas)
/// ```
///
/// Estrategia:
/// 1. Trae todos los integrantes (1 consulta).
/// 2. Trae todas las estrellas históricas (1 consulta).
/// 3. Cuenta estrellas por miembro en memoria (O(n)).
/// 4. Devuelve una lista de [MemberWithStars] ordenada alfabéticamente.
///
/// Devuelve:
/// - `Right(list)` con la lista (puede estar vacía).
/// - `Left(DatabaseFailure)` si algo falla.
class GetMembers extends NoParamsUseCase<List<MemberWithStars>> {
  final TournamentRepository repository;

  GetMembers(this.repository);

  @override
  Future<Either<Failure, List<MemberWithStars>>> call() async {
    try {
      // 1. Traer todos los integrantes
      final members = await repository.getMembers();

      // 2. Traer todas las estrellas (histórico completo)
      //    Usamos un rango muy amplio para cubrir todo.
      final allStars = await repository.getStarsInRange(
        DateTime(2000),
        DateTime(2100),
      );

      // 3. Contar estrellas por miembroId
      final countsByMember = <String, int>{};
      for (final star in allStars) {
        countsByMember[star.memberId] =
            (countsByMember[star.memberId] ?? 0) + 1;
      }

      // 4. Combinar en MemberWithStars
      final result =
          members
              .map(
                (m) => MemberWithStars(
                  member: m,
                  totalStars: countsByMember[m.id] ?? 0,
                ),
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure('No se pudieron cargar los integrantes: $e'));
    }
  }
}
