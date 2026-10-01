import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../providers/dependencies_provider.dart';

/// Botón grande "+1 ESTRELLA" con:
/// - Gradiente y glow del color del integrante.
/// - Animación de escala al presionar.
/// - Vibración háptica.
/// - Sonido (delegado a [SoundService]).
/// - Estado de carga (deshabilitado mientras procesa).
class AddStarButton extends ConsumerStatefulWidget {
  final VoidCallback onPressed;
  final Color color;
  final bool isLoading;
  final bool enabled;

  const AddStarButton({
    super.key,
    required this.onPressed,
    required this.color,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  ConsumerState<AddStarButton> createState() => _AddStarButtonState();
}

class _AddStarButtonState extends ConsumerState<AddStarButton> {
  bool _pressed = false;

  bool get _isDisabled => !widget.enabled || widget.isLoading;

  Future<void> _handleTap() async {
    if (_isDisabled) return;

    // 1. Feedback táctil
    HapticFeedback.mediumImpact();

    // 2. Sonido
    await ref.read(soundServiceProvider).playStar();

    // 3. Acción
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final disabled = _isDisabled;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled ? null : _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: disabled
                  ? [Colors.grey.shade700, Colors.grey.shade800]
                  : [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: disabled ? 0.1 : 0.3),
              width: 2,
            ),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.star_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Text(
                AppStrings.addStar,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
