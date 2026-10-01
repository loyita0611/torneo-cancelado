import '../../domain/entities/member.dart';
import '../../domain/entities/star_event.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_local_datasource.dart';
import '../models/member_model.dart';
import '../models/star_event_model.dart';

/// Implementación concreta de [TournamentRepository].
///
/// **Rol:** traduce entre el **mundo del dominio** (entidades puras) y el
/// **mundo de los datos** (modelos serializables), delegando todo el
/// trabajo de persistencia al [TournamentLocalDataSource].
///
/// Esta clase es la **única** que conoce ambos mundos. El dominio no
/// sabe que existe, y el datasource no sabe que existe tampoco.
class TournamentRepositoryImpl implements TournamentRepository {
  final TournamentLocalDataSource dataSource;

  TournamentRepositoryImpl(this.dataSource);

  // ---------------------------------------------------------------------------
  // INTEGRANTES
  // ---------------------------------------------------------------------------

  @override
  Future<List<Member>> getMembers() async {
    final models = await dataSource.getMembers();
    // Model → Entity
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Member?> getMemberById(String id) async {
    final model = await dataSource.getMemberById(id);
    // Model → Entity (o null)
    return model?.toEntity();
  }

  @override
  Future<Member> addMember(Member member) async {
    // Entity → Model
    final model = MemberModel.fromEntity(member);
    final saved = await dataSource.addMember(model);
    // Model → Entity
    return saved.toEntity();
  }

  @override
  Future<void> deleteMember(String id) async {
    await dataSource.deleteMember(id);
  }

  // ---------------------------------------------------------------------------
  // ESTRELLAS
  // ---------------------------------------------------------------------------

  @override
  Future<void> addStar(StarEvent event) async {
    // Entity → Model
    final model = StarEventModel.fromEntity(event);
    await dataSource.addStar(model);
  }

  @override
  Future<List<StarEvent>> getStarsByMember(String memberId) async {
    final models = await dataSource.getStarsByMember(memberId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<StarEvent>> getStarsInRange(DateTime from, DateTime to) async {
    final models = await dataSource.getStarsInRange(from, to);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<StarEvent>> getStarsForMemberInRange(
    String memberId,
    DateTime from,
    DateTime to,
  ) async {
    final models = await dataSource.getStarsForMemberInRange(
      memberId,
      from,
      to,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  // ---------------------------------------------------------------------------
  // OPERACIONES COMPUESTAS
  // ---------------------------------------------------------------------------

  @override
  Future<void> clearStarsForMember(String memberId) async {
    await dataSource.clearStarsForMember(memberId);
  }

  @override
  Future<void> clearAll() async {
    await dataSource.clearAll();
  }
}
