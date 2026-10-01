import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/member_model.dart';
import '../models/star_event_model.dart';

/// Fuente de datos local basada en un archivo JSON en el directorio
/// de documentos de la app.
///
/// **Estrategia de caché:**
/// - Al inicializar, carga todo el JSON en memoria.
/// - Todas las lecturas van contra la memoria (rápidas).
/// - Cada escritura actualiza memoria **y** persiste el archivo.
///
/// Para esta app (decenas/cientos de eventos) es más que suficiente.
class TournamentLocalDataSource {
  static const String _fileName = 'torneo_cancelado_data.json';

  final List<MemberModel> _members = [];
  final List<StarEventModel> _stars = [];
  File? _file;
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // INICIALIZACIÓN
  // ---------------------------------------------------------------------------

  /// Carga el archivo JSON en memoria (una sola vez).
  /// Si no existe, arranca vacío.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/$_fileName');

    if (await _file!.exists()) {
      final raw = await _file!.readAsString();
      if (raw.trim().isNotEmpty) {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;

        final membersJson = (json['members'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final starsJson = (json['stars'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        _members
          ..clear()
          ..addAll(membersJson.map(MemberModel.fromJson));

        _stars
          ..clear()
          ..addAll(starsJson.map(StarEventModel.fromJson));
      }
    }

    _initialized = true;
  }

  /// Escribe el estado actual a disco.
  Future<void> _persist() async {
    if (_file == null) return;
    final data = {
      'members': _members.map((m) => m.toJson()).toList(),
      'stars': _stars.map((s) => s.toJson()).toList(),
    };
    final encoded = jsonEncode(data);
    await _file!.writeAsString(encoded, flush: true);
  }

  // ---------------------------------------------------------------------------
  // MIEMBROS
  // ---------------------------------------------------------------------------

  Future<List<MemberModel>> getMembers() async {
    await _ensureInitialized();
    return List.unmodifiable(_members);
  }

  Future<MemberModel?> getMemberById(String id) async {
    await _ensureInitialized();
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<MemberModel> addMember(MemberModel member) async {
    await _ensureInitialized();
    _members.add(member);
    await _persist();
    return member;
  }

  Future<void> deleteMember(String id) async {
    await _ensureInitialized();
    _members.removeWhere((m) => m.id == id);
    // Cascada: borra también sus estrellas
    _stars.removeWhere((s) => s.memberId == id);
    await _persist();
  }

  // ---------------------------------------------------------------------------
  // ESTRELLAS
  // ---------------------------------------------------------------------------

  Future<void> addStar(StarEventModel event) async {
    await _ensureInitialized();
    _stars.add(event);
    await _persist();
  }

  Future<List<StarEventModel>> getStarsByMember(String memberId) async {
    await _ensureInitialized();
    final result = _stars.where((s) => s.memberId == memberId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  Future<List<StarEventModel>> getStarsInRange(
    DateTime from,
    DateTime to,
  ) async {
    await _ensureInitialized();
    return _stars
        .where((s) => !s.timestamp.isBefore(from) && !s.timestamp.isAfter(to))
        .toList();
  }

  Future<List<StarEventModel>> getStarsForMemberInRange(
    String memberId,
    DateTime from,
    DateTime to,
  ) async {
    await _ensureInitialized();
    return _stars
        .where(
          (s) =>
              s.memberId == memberId &&
              !s.timestamp.isBefore(from) &&
              !s.timestamp.isAfter(to),
        )
        .toList();
  }

  Future<void> clearStarsForMember(String memberId) async {
    await _ensureInitialized();
    _stars.removeWhere((s) => s.memberId == memberId);
    await _persist();
  }

  Future<void> clearAll() async {
    await _ensureInitialized();
    _members.clear();
    _stars.clear();
    await _persist();
  }
}
