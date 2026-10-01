import 'package:equatable/equatable.dart';

import 'member.dart';

/// Representa a un integrante en una **clasificación** (ranking).
///
/// Se usa para mostrar listas ordenadas por período:
/// - Diario
/// - Semanal
/// - Mensual
///
/// [position] es 1-based: 1 = primero, 2 = segundo, ...
/// Cuando hay empate, varios pueden compartir la misma posición.
class RankingEntry extends Equatable {
  /// El integrante.
  final Member member;

  /// Cantidad de estrellas en el período consultado.
  final int stars;

  /// Posición en el ranking (1 = primero).
  final int position;

  /// ¿Cuántos integrantes comparten esta posición? (útil para empates)
  final int tiedWith;

  const RankingEntry({
    required this.member,
    required this.stars,
    required this.position,
    this.tiedWith = 1,
  });

  /// Atajos
  String get memberId => member.id;
  String get name => member.name;

  /// ¿Está en el podio (1º, 2º o 3º)?
  bool get isPodium => position <= 3;

  /// ¿Es el primer lugar?
  bool get isWinner => position == 1;

  /// ¿Hay empate en su posición?
  bool get isTied => tiedWith > 1;

  /// Medalla si está en podio, `null` si no.
  /// Nota: devuelve un emoji como String para no depender de Flutter.
  String? get medal {
    return switch (position) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
  }

  @override
  List<Object?> get props => [member, stars, position, tiedWith];

  @override
  String toString() => 'RankingEntry(#$position ${member.name}: $stars)';
}
