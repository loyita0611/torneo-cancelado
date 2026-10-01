import 'package:flutter/material.dart';

/// Paleta de colores central de la app.
/// Estilo: neón colorido sobre fondo oscuro con gradiente.
class AppColors {
  AppColors._();

  // ---------- FONDOS ----------
  static const Color backgroundDark = Color(0xFF0F0E17);
  static const Color backgroundMid = Color(0xFF1A1A2E);
  static const Color backgroundBlue = Color(0xFF16213E);
  static const Color surface = Color(0xFF1F1F38);

  /// Gradiente principal del fondo de la app.
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
  );

  // ---------- NEÓN ----------
  static const Color neonPink = Color(0xFFFF2E63);
  static const Color neonYellow = Color(0xFFFFD93D);
  static const Color neonCyan = Color(0xFF08D9D6);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonOrange = Color(0xFFFF7B00);

  // ---------- TEXTO ----------
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8D1);
  static const Color textDisabled = Color(0xFF6C6C8A);

  // ---------- SEMÁNTICOS ----------
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);

  // ---------- PODIO ----------
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  /// Colores rotativos para cada integrante.
  static const List<Color> memberColors = [
    neonPink,
    neonYellow,
    neonCyan,
    neonPurple,
    neonGreen,
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFFB388FF),
    Color(0xFF00E5FF),
  ];

  /// Devuelve un color estable a partir de un índice.
  static Color forIndex(int index) =>
      memberColors[index.abs() % memberColors.length];

  /// Gradiente de la estrella animada.
  static const LinearGradient starGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonYellow, neonOrange],
  );

  /// Gradiente del botón/podio del ganador.
  static const LinearGradient winnerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonYellow, neonPink, neonPurple],
  );
}
