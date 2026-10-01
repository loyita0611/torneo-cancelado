import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:torneo_cancelado/features/tournament/presentation/widgets/add_star_note_dialog.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../domain/entities/star_event.dart';
import '../providers/member_provider.dart';
import '../providers/star_provider.dart';
import '../widgets/add_star_button.dart';
import '../widgets/animated_star_overlay.dart';

/// Pantalla de detalle de un integrante.
///
/// Muestra:
/// - Nombre y avatar grande.
/// - Contadores: hoy / semana / mes / total.
/// - Botón "+1 ESTRELLA" (grande, con sonido y vibración).
/// - Overlay animado al agregar.
/// - Historial de estrellas.
/// - Botón de eliminar integrante.
class MemberDetailPage extends ConsumerStatefulWidget {
  final String memberId;

  const MemberDetailPage({super.key, required this.memberId});

  @override
  ConsumerState<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends ConsumerState<MemberDetailPage> {
  /// Controla si la estrella animada está visible.
  bool _showStarOverlay = false;

  /// Key única para forzar recreación del overlay (reinicia animación).
  Key _overlayKey = UniqueKey();

  /// Color del integrante, para reutilizar en varios sitios.
  Color get _memberColor {
    final member = ref.read(memberByIdProvider(widget.memberId)).value;
    if (member == null) return AppColors.neonCyan;
    return AppColors.forIndex(member.colorIndex);
  }

  Future<void> _handleAddStar() async {
    // 1. Pedir la nota (o null si salta)
    final note = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddStarNoteDialog(color: _memberColor),
    );

    // Si el usuario cerró el diálogo con el botón atrás, note es null
    // y no agregamos nada. Pero como no podemos distinguir "cancelar"
    // de "saltar" con `String?`, usamos otro enfoque:
    // - null = saltar (agrega sin nota)
    // - 'texto' = agregar con nota
    // - (no devuelve nada si se cancela con atrás)
    //
    // Para simplificar: siempre agregamos, con nota o sin ella.

    if (!mounted) return;

    // 2. Mostrar overlay
    setState(() {
      _overlayKey = UniqueKey();
      _showStarOverlay = true;
    });

    // 3. Ejecutar la acción con la nota (puede ser null)
    final controller = ref.read(addStarControllerProvider.notifier);
    final ok = await controller.addStar(memberId: widget.memberId, note: note);

    if (!mounted) return;

    if (!ok) {
      setState(() => _showStarOverlay = false);
      final error = ref.read(addStarControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? AppStrings.errorGeneric),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final memberAsync = ref.read(memberByIdProvider(widget.memberId));
    final name = memberAsync.value?.name ?? 'este integrante';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F38),
        title: const Text(
          AppStrings.deleteMemberTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${AppStrings.deleteMemberBody}\n\n($name)',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              AppStrings.delete,
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final controller = ref.read(memberActionControllerProvider.notifier);
    final ok = await controller.deleteMember(widget.memberId);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      final error = ref.read(memberActionControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? AppStrings.errorGeneric),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(memberByIdProvider(widget.memberId));
    final totalsAsync = ref.watch(memberStarsTotalsProvider(widget.memberId));
    final historyAsync = ref.watch(memberHistoryProvider(widget.memberId));
    final addStarState = ref.watch(addStarControllerProvider);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    // Si el integrante no existe → mostrar mensaje
    final member = memberAsync.value;
    if (memberAsync.hasValue && member == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: const Center(
            child: Text(
              AppStrings.errorMemberNotFound,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ),
        ),
      );
    }

    final color = member != null
        ? AppColors.forIndex(member.colorIndex)
        : AppColors.neonCyan;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // ─── Contenido principal ───
              Column(
                children: [
                  // ─── AppBar personalizada ───
                  _CustomAppBar(color: color, onDelete: _confirmDelete),

                  Expanded(
                    child: member == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.neonYellow,
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // ─── Cabecera del integrante ───
                                _MemberHeader(
                                  name: member.name,
                                  initials: member.initials,
                                  color: color,
                                  isTablet: isTablet,
                                ),

                                const SizedBox(height: 20),

                                // ─── Contadores ───
                                totalsAsync.when(
                                  data: (totals) => _TotalsGrid(
                                    totals: totals,
                                    color: color,
                                    isTablet: isTablet,
                                  ),
                                  loading: () => const SizedBox(height: 120),
                                  error: (e, _) => Text(
                                    'Error: $e',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ─── Botón grande +1 ───
                                AddStarButton(
                                  color: color,
                                  isLoading: addStarState.isLoading,
                                  onPressed: _handleAddStar,
                                ),

                                const SizedBox(height: 32),

                                // ─── Historial ───
                                _HistorySection(
                                  historyAsync: historyAsync,
                                  color: color,
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                  ),
                ],
              ),

              // ─── Overlay de estrella animada ───
              if (_showStarOverlay)
                AnimatedStarOverlay(
                  key: _overlayKey,
                  color: color,
                  onComplete: () {
                    if (mounted) {
                      setState(() => _showStarOverlay = false);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  APPBAR PERSONALIZADA
// =============================================================================

class _CustomAppBar extends StatelessWidget {
  final Color color;
  final VoidCallback onDelete;

  const _CustomAppBar({required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 26,
            ),
            onPressed: onDelete,
            tooltip: 'Eliminar integrante',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  CABECERA DEL INTEGRANTE
// =============================================================================

class _MemberHeader extends StatelessWidget {
  final String name;
  final String initials;
  final Color color;
  final bool isTablet;

  const _MemberHeader({
    required this.name,
    required this.initials,
    required this.color,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = isTablet ? 100.0 : 84.0;

    return Column(
      children: [
        // Avatar grande
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: 24,
                spreadRadius: 3,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: avatarSize * 0.38,
              fontWeight: FontWeight.w900,
            ),
          ),
        ).animate().scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        ),

        const SizedBox(height: 14),

        // Nombre
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isTablet ? 32 : 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
      ],
    );
  }
}

// =============================================================================
//  GRID DE CONTADORES
// =============================================================================

class _TotalsGrid extends StatelessWidget {
  final MemberStarsTotals totals;
  final Color color;
  final bool isTablet;

  const _TotalsGrid({
    required this.totals,
    required this.color,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (label: AppStrings.today, value: totals.today, icon: Icons.today_rounded),
      (
        label: AppStrings.thisWeek,
        value: totals.week,
        icon: Icons.view_week_rounded,
      ),
      (
        label: AppStrings.thisMonth,
        value: totals.month,
        icon: Icons.calendar_month_rounded,
      ),
      (
        label: AppStrings.total,
        value: totals.total,
        icon: Icons.all_inclusive_rounded,
      ),
    ];

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _StatCard(
                  label: s.label,
                  value: s.value,
                  icon: s.icon,
                  color: color,
                  compact: !isTablet,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool compact;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 20 : 24),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: compact ? 22 : 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  SECCIÓN DE HISTORIAL
// =============================================================================

class _HistorySection extends StatelessWidget {
  final AsyncValue<List<StarEvent>> historyAsync;
  final Color color;

  const _HistorySection({required this.historyAsync, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Row(
          children: [
            Icon(Icons.history_rounded, color: color, size: 24),
            const SizedBox(width: 8),
            const Text(
              AppStrings.history,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Contenido
        historyAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    AppStrings.noHistory,
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            }

            // Historial limitado a 30 entradas más recientes
            final visible = events.take(30).toList();

            return Column(
              children: visible
                  .map((e) => _HistoryTile(event: e, color: color))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.neonYellow),
            ),
          ),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final StarEvent event;
  final Color color;

  const _HistoryTile({required this.event, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateHelpers.humanize(event.timestamp),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (event.note != null && event.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '"${event.note}"',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            DateHelpers.formatTime(event.timestamp),
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }
}
