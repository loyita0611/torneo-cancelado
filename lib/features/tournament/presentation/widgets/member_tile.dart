import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/member_with_stars.dart';

/// Fila de un integrante en la lista principal.
///
/// Estructura:
/// ```
/// (J)  Juan Pérez     │  ⭐1 ⭐2 ⭐3
/// ```
///
/// - Avatar circular con iniciales.
/// - Borde con el color del integrante.
/// - Strip animada de estrellas (efecto cascada).
class MemberTile extends StatelessWidget {
  /// Datos del integrante con su total de estrellas.
  final MemberWithStars item;

  /// Callback al tocar la fila.
  final VoidCallback? onTap;

  /// Callback al mantener presionada la fila (útil para eliminar).
  final VoidCallback? onLongPress;

  /// Color del integrante. Si no se pasa, se calcula desde `colorIndex`.
  final Color? colorOverride;

  const MemberTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.colorOverride,
  });

  Color get _color =>
      colorOverride ?? AppColors.forIndex(item.member.colorIndex);

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withValues(alpha: 0.15),
          highlightColor: color.withValues(alpha: 0.08),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // ─── Avatar ───
                _Avatar(initials: item.member.initials, color: color),
                const SizedBox(width: 14),

                // ─── Nombre ───
                Expanded(
                  flex: 3,
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // ─── Separador ───
                Container(
                  width: 2,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),

                // ─── Estrellas ───
                Expanded(
                  flex: 5,
                  child: _StarStrip(count: item.totalStars, color: color),
                ),
              ],
            ),
          ),
        ),
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

  const _Avatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
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
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// =============================================================================
//  STRIP DE ESTRELLAS
// =============================================================================

class _StarStrip extends StatelessWidget {
  final int count;
  final Color color;

  const _StarStrip({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    // Sin estrellas → mensaje
    if (count == 0) {
      return const Text(
        AppStrings.noStars,
        style: TextStyle(
          color: AppColors.textDisabled,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Limitar visualmente a 20 para no saturar la fila.
    // (Si tiene más, mostramos los primeros 20 + "+N más").
    const maxVisible = 20;
    final visible = count > maxVisible ? maxVisible : count;
    final hidden = count - visible;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        ...List.generate(
          visible,
          (i) => _StarBadge(
            number: i + 1,
            color: color,
            // Delay en cascada: cada estrella aparece 40ms después
            delayMs: i * 40,
          ),
        ),
        if (hidden > 0) _MoreBadge(count: hidden, color: color),
      ],
    );
  }
}

// =============================================================================
//  BADGE DE ESTRELLA INDIVIDUAL
// =============================================================================

class _StarBadge extends StatelessWidget {
  final int number;
  final Color color;
  final int delayMs;

  const _StarBadge({
    required this.number,
    required this.color,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.75)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        )
        .animate(delay: delayMs.ms)
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 250.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// =============================================================================
//  BADGE "+N MÁS"
// =============================================================================

class _MoreBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _MoreBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
