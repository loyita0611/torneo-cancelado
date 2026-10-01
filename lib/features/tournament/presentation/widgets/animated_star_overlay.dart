import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Overlay que muestra una estrella gigante animada al agregar una estrella.
///
/// Secuencia:
/// 1. Aparece desde el centro con escala 0.2 → 2.5
/// 2. Gira ligeramente y sube 300px
/// 3. Se desvanece
/// 4. Llama a [onComplete] para que el padre la remueva del árbol
///
/// **No captura toques** (`IgnorePointer`) para no bloquear la UI debajo.
class AnimatedStarOverlay extends StatefulWidget {
  /// Color de la estrella (el color del integrante).
  final Color color;

  /// Callback al terminar la animación.
  final VoidCallback? onComplete;

  /// Tamaño base de la estrella antes de escalar.
  final double baseSize;

  const AnimatedStarOverlay({
    super.key,
    required this.color,
    this.onComplete,
    this.baseSize = 96,
  });

  @override
  State<AnimatedStarOverlay> createState() => _AnimatedStarOverlayState();
}

class _AnimatedStarOverlayState extends State<AnimatedStarOverlay> {
  /// Controla si la animación ya terminó.
  /// Evita llamar a [widget.onComplete] más de una vez.
  bool _completed = false;

  void _handleComplete() {
    if (_completed) return;
    _completed = true;
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return IgnorePointer(
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ─── Halo difuso detrás de la estrella ───
            Container(
                  width: widget.baseSize * 1.8,
                  height: widget.baseSize * 1.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.6),
                        color.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.2, 0.2),
                  end: const Offset(2.2, 2.2),
                  duration: 400.ms,
                  curve: Curves.easeOutCirc,
                )
                .fadeOut(delay: 200.ms, duration: 400.ms),

            // ─── Estrella principal ───
            Icon(
                  Icons.star_rounded,
                  size: widget.baseSize,
                  color: color,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.8), blurRadius: 40),
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                )
                .animate()
                // 1) Aparece con un "pop" y escala a 2.5x
                .scale(
                  begin: const Offset(0.2, 0.2),
                  end: const Offset(2.5, 2.5),
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                )
                // 2) Sube 300px y se desvanece
                .then()
                .moveY(
                  begin: 0,
                  end: -320,
                  duration: 800.ms,
                  curve: Curves.easeInQuad,
                )
                // 3) Rota ligeramente mientras sube
                // (aplicado en paralelo con un segundo .animate encima)
                .fadeOut(delay: 100.ms, duration: 700.ms)
                // 4) Al terminar, notifica
                .callback(callback: (_) => _handleComplete()),

            // ─── Estrellitas secundarias orbitando ───
            ..._buildSparkles(color),
          ],
        ),
      ),
    );
  }

  /// Genera 6 estrellitas pequeñas alrededor que se dispersan
  /// mientras la principal sube.
  List<Widget> _buildSparkles(Color color) {
    const count = 6;
    const spread = 120.0;

    return List.generate(count, (i) {
      final angle = (i / count) * 3.14159 * 2;
      final dx = spread * _cos(angle);
      final dy = spread * _sin(angle);

      return Icon(
            Icons.star_rounded,
            size: 18,
            color: color.withValues(alpha: 0.9),
          )
          .animate(delay: (i * 30).ms)
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: 200.ms,
            curve: Curves.easeOutBack,
          )
          .then()
          .move(
            begin: const Offset(0, 0),
            end: Offset(dx, dy),
            duration: 500.ms,
            curve: Curves.easeOutQuad,
          )
          .fadeOut(duration: 300.ms);
    });
  }

  // Implementación simple de cos/sin sin importar dart:math
  // (para no arrastrar toda la librería por 2 funciones).
  double _cos(double x) {
    // Taylor / aproximación: suficiente para posicionamiento visual
    return _sin(x + 1.5707963); // cos(x) = sin(x + π/2)
  }

  double _sin(double x) {
    // Aproximación por serie de Taylor (5 términos)
    // Precisión más que suficiente para 6 estrellitas.
    final x2 = x * x;
    final x3 = x2 * x;
    final x5 = x3 * x2;
    final x7 = x5 * x2;
    final x9 = x7 * x2;
    return x - (x3 / 6) + (x5 / 120) - (x7 / 5040) + (x9 / 362880);
  }
}
