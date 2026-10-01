import 'package:audioplayers/audioplayers.dart';

import '../constants/app_sounds.dart';

/// Servicio de audio centralizado.
///
/// - Reproduce sonidos cortos desde `assets/sounds/`.
/// - Silencia errores (ej. si el asset no existe aún).
/// - Permite activar/desactivar el sonido globalmente.
class SoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  SoundService() {
    // Configuración para sonidos cortos: baja latencia.
    _player.setPlayerMode(PlayerMode.lowLatency);
    _player.setReleaseMode(ReleaseMode.stop);
  }

  /// ¿Está habilitado el sonido?
  bool get isEnabled => _enabled;

  /// Activa/desactiva todos los sonidos.
  void setEnabled(bool value) => _enabled = value;

  /// Reproduce el sonido de estrella (⭐).
  Future<void> playStar() => _play(AppSounds.star);

  /// Reproduce la fanfarria del ganador mensual.
  Future<void> playWinner() => _play(AppSounds.winner);

  /// Sonido al agregar un integrante nuevo.
  Future<void> playMemberAdded() => _play(AppSounds.memberAdded);

  /// Sonido de error.
  Future<void> playError() => _play(AppSounds.error);

  /// Reproduce un sonido desde assets. Silencia cualquier error.
  Future<void> _play(String assetPath) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Silencioso: si el asset no existe o falla la reproducción,
      // no queremos crashear la app por un sonido.
    }
  }

  /// Libera recursos.
  Future<void> dispose() async {
    await _player.dispose();
  }
}
