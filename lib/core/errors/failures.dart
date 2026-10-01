import 'package:equatable/equatable.dart';

/// Clase base para todos los errores de la app.
///
/// En Clean Architecture, los errores se representan como **valores**
/// (no excepciones) que viajan dentro de un `Either<Failure, T>`.
/// Esto obliga al llamador a manejar el caso de error explícitamente.
abstract class Failure extends Equatable {
  /// Mensaje legible para mostrar al usuario (o log).
  final String message;

  /// Código opcional para identificar el tipo de fallo.
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() =>
      'Failure($message${code != null ? ', code: $code' : ''})';
}

// ---------------------------------------------------------------------------
// FALLOS ESPECÍFICOS
// ---------------------------------------------------------------------------

/// Fallo al acceder a la base de datos local (Isar).
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// Fallo cuando una entidad no existe (ej. buscar un integrante por id).
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Fallo de validación (ej. nombre vacío, duplicado).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Fallo al reproducir un sonido.
class AudioFailure extends Failure {
  const AudioFailure(super.message, {super.code});
}

/// Fallo genérico no clasificado.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.code});
}
