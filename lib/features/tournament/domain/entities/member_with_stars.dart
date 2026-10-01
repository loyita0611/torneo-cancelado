import 'package:equatable/equatable.dart';

import 'member.dart';

/// Combina un [Member] con su total de estrellas.
///
/// Es una **proyección de dominio**: no se persiste, se calcula al vuelo
/// cuando la UI necesita mostrar la lista con los totales.
class MemberWithStars extends Equatable {
  /// El integrante.
  final Member member;

  /// Total de estrellas acumuladas.
  final int totalStars;

  const MemberWithStars({required this.member, required this.totalStars});

  /// Atajo al ID del miembro (para keys en widgets, por ejemplo).
  String get memberId => member.id;

  /// Atajo al nombre (para ordenamientos y textos).
  String get name => member.name;

  /// ¿Tiene al menos una estrella?
  bool get hasStars => totalStars > 0;

  /// Crea una copia con el total modificado.
  MemberWithStars copyWith({Member? member, int? totalStars}) {
    return MemberWithStars(
      member: member ?? this.member,
      totalStars: totalStars ?? this.totalStars,
    );
  }

  @override
  List<Object?> get props => [member, totalStars];

  @override
  String toString() => 'MemberWithStars(${member.name}: $totalStars estrellas)';
}
