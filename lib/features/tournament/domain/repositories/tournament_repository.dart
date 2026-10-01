import '../../domain/entities/member.dart';
import '../../domain/entities/star_event.dart';

abstract class TournamentRepository {
  // -------------------------------------------------------------------------
  // INTEGRANTES
  // -------------------------------------------------------------------------

  /// Devuelve todos los integrantes del torneo.
  /// Ordenados por fecha de creación (los más antiguos primero).
  Future<List<Member>> getMembers();

  /// Devuelve un integrante por su ID, o `null` si no existe.
  Future<Member?> getMemberById(String id);

  /// Guarda un nuevo integrante.
  /// Devuelve el integrante guardado (con el ID que le asignó la BD, si aplica).
  Future<Member> addMember(Member member);

  /// Elimina un integrante y **todas sus estrellas** asociadas.
  Future<void> deleteMember(String id);

  // -------------------------------------------------------------------------
  // ESTRELLAS
  // -------------------------------------------------------------------------

  /// Guarda una nueva estrella.
  Future<void> addStar(StarEvent event);

  /// Devuelve todas las estrellas de un integrante.
  /// Ordenadas de la más reciente a la más antigua.
  Future<List<StarEvent>> getStarsByMember(String memberId);

  /// Devuelve **todas** las estrellas dentro de un rango de fechas.
  /// Útil para calcular rankings diarios/semanales/mensuales.
  Future<List<StarEvent>> getStarsInRange(DateTime from, DateTime to);

  /// Devuelve las estrellas de **un integrante** dentro de un rango de fechas.
  /// Más eficiente que filtrar en memoria cuando hay muchos eventos.
  Future<List<StarEvent>> getStarsForMemberInRange(
    String memberId,
    DateTime from,
    DateTime to,
  );

  // -------------------------------------------------------------------------
  // OPERACIONES COMPUESTAS
  // -------------------------------------------------------------------------

  /// Elimina **todas** las estrellas de un integrante (sin borrar al integrante).
  /// Útil para "resetear" a alguien sin sacarlo del torneo.
  Future<void> clearStarsForMember(String memberId);

  /// Elimina **todos** los datos (integrantes + estrellas).
  /// Útil para "reiniciar el torneo" desde ajustes.
  Future<void> clearAll();
}
