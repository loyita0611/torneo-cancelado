import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Interfaz base para **casos de uso sin parámetros**.
///
/// Devuelve `Either<Failure, T>`:
/// - `Left(Failure)` si algo falla
/// - `Right(T)` con el resultado si todo va bien
abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

/// Clase base para casos de uso que **no requieren parámetros**.
///
/// Uso: `class GetMembers extends NoParamsUseCase<List<Member>> { ... }`
abstract class NoParamsUseCase<Result> {
  Future<Either<Failure, Result>> call();
}

/// Clase vacía que se pasa como parámetro cuando no hay parámetros.
/// Evita tener que crear una clase distinta por cada use case sin args.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
