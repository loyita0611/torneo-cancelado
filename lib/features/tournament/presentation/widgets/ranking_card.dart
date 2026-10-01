import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/ranking_entry.dart';

/// Tarjeta de ranking para un integrante.
///
/// Se adapta visualmente según la posición:
/// - **1º** → dorado + glow fuerte + escala mayor
/// - **2º** → plateado
/// - **3º** → bronce
/// - **4º+** → color del integrante
///
/// Muestra medalla (🥇🥈🥉) si está en el podio, o el número de posición.
class RankingCard extends StatelessWidget {
  /// Entrada del ranking (contiene member, stars, position, etc.).
  final RankingEntry entry;

  /// Callback al tocar la tarjeta.
  final VoidCallback? onTap;

  /// Si es `true`, se muestra más grande y llamativa (útil para el 1º lugar).
  final bool highlighted;

  /// Índice para el delay de la animación en cascada.
  /// Se le suma `index * 60ms` al delay de entrada.
  final int animationIndex;

  const RankingCard({
    super.key,
    required this.entry,
    this.onTap,
    this.highlighted = false,
    this.animationIndex = 0,
  });

  // ---------------------------------------------------------------------------
  // HELPERS DE ESTILO
  // ---------------------------------------------------------------------------

  /// Color principal según la posición.
  Color get _accentColor {
    return switch (entry.position) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => AppColors.bronze,
      _ => AppColors.forIndex(entry.member.colorIndex),
    };
  }

  /// ¿Debe tratarse como "destacado"?
  bool get _isTop => highlighted || entry.isWinner;

  /// Padding según destacado o no.
  EdgeInsets get _padding => EdgeInsets.symmetric(
    horizontal: _isTop ? 20 : 16,
    vertical: _isTop ? 18 : 14,
  );

  /// Radio de esquinas.
  double get _radius => _isTop ? 24 : 18;

  /// Tamaño de la medalla según posición.
  double get _medalSize => _isTop ? 40 : 32;

  double get _avatarSize => _isTop ? 60 : 48;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_radius),
              splashColor: accent.withValues(alpha: 0.2),
              child: Container(
                padding: _padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: _isTop
                        // Podio: gradiente del color de la medalla
                        ? [
                            accent.withValues(alpha: 0.35),
                            accent.withValues(alpha: 0.10),
                          ]
                        // Resto: color del integrante
                        : [
                            accent.withValues(alpha: 0.18),
                            accent.withValues(alpha: 0.04),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(
                    color: accent.withValues(alpha: _isTop ? 0.85 : 0.45),
                    width: _isTop ? 2.5 : 1.5,
                  ),
                  boxShadow: _isTop
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.45),
                            blurRadius: 24,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // ─── Medalla o número ───
                    _PositionBadge(
                      entry: entry,
                      color: accent,
                      size: _medalSize,
                    ),
                    const SizedBox(width: 10),

                    _Avatar(
                      initials: entry.member.initials,
                      color: accent,
                      size: _avatarSize,
                    ),
                    const SizedBox(width: 12),

                    // ─── Nombre + subtítulo ───
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.name,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: _isTop ? 22 : 18,
                                    fontWeight: _isTop
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (entry.isTied)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _TieBadge(color: accent),
                                ),
                            ],
                          ),
                          if (_isTop) ...[
                            const SizedBox(height: 2),
                            Text(
                              entry.isWinner
                                  ? 'Líder del ranking'
                                  : 'En el podio',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ─── Contador de estrellas ───
                    _StarsCount(count: entry.stars, color: accent, big: _isTop),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: (animationIndex * 60).ms)
        .fadeIn(duration: 350.ms)
        .slideX(
          begin: -0.15,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// =============================================================================
//  BADGE DE POSICIÓN (medalla o número)
// =============================================================================

class _PositionBadge extends StatelessWidget {
  final RankingEntry entry;
  final Color color;
  final double size;

  const _PositionBadge({
    required this.entry,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Podio (1º, 2º, 3º) → emoji
    if (entry.isPodium) {
      return SizedBox(
        width: size + 8,
        height: size + 8,
        child: Center(
          child: Text(
            entry.medal ?? '',
            style: TextStyle(fontSize: size, height: 1),
          ),
        ),
      );
    }

    // Resto → número de posición
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '${entry.position}',
        style: TextStyle(
          color: color,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

// =============================================================================
//  BADGE DE EMPATE
// =============================================================================

class _TieBadge extends StatelessWidget {
  final Color color;

  const _TieBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: const Text(
        'empate',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// =============================================================================
//  CONTADOR DE ESTRELLAS
// =============================================================================

class _StarsCount extends StatelessWidget {
  final int count;
  final Color color;
  final bool big;

  const _StarsCount({
    required this.count,
    required this.color,
    required this.big,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: big ? 14 : 10,
        vertical: big ? 8 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(big ? 16 : 12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: big ? 26 : 20),
          SizedBox(width: big ? 6 : 4),
          Text(
            '$count',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: big ? 24 : 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  AVATAR
// =============================================================================

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;

  const _Avatar({
    required this.initials,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.65)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
