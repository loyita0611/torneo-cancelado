import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';

/// Diálogo opcional que se muestra al agregar una estrella.
///
/// Permite escribir la frase por la cual se ganó la estrella.
/// Devuelve:
/// - `String?` con la nota si el usuario escribió algo y guardó.
/// - `null` si el usuario saltó o no escribió nada.
/// - `false` (bool false) si canceló con el botón atrás.
class AddStarNoteDialog extends ConsumerStatefulWidget {
  final Color color;

  const AddStarNoteDialog({super.key, required this.color});

  @override
  ConsumerState<AddStarNoteDialog> createState() => _AddStarNoteDialogState();
}

class _AddStarNoteDialogState extends ConsumerState<AddStarNoteDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    final note = _controller.text.trim();
    Navigator.of(context).pop(note.isEmpty ? null : note);
  }

  void _skip() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.vertical - 80;

    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: availableHeight > 180 ? availableHeight : 180,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F1F38), Color(0xFF16213E)],
              ),
              border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Título ───
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: color, size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '¡Estrella ganada!',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '¿Qué dijo para ganarse la estrella? (opcional)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── Input ───
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 100,
                    maxLines: 2,
                    minLines: 1,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ej: "literalmente", "o sea"...',
                      hintStyle: const TextStyle(color: AppColors.textDisabled),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.25),
                      counterStyle: const TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: color, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 6),

                  // ─── Botones ───
                  Row(
                    children: [
                      // Saltar
                      Flexible(
                        child: TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Saltar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Guardar
                      Flexible(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text(
                            'Guardar',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
