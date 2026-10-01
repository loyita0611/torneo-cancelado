import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:torneo_cancelado/features/tournament/presentation/pages/member_detail_page.dart';
import 'package:torneo_cancelado/features/tournament/presentation/pages/ranking_page.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/member_provider.dart';
import '../widgets/add_member_dialog.dart';
import '../widgets/member_tile.dart';

/// Pantalla principal del torneo.
///
/// Muestra:
/// - Título animado con la marca.
/// - Botones "Agregar Integrante" y "Ver Ranking".
/// - Lista de integrantes con sus estrellas (1 o 2 columnas según ancho).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersWithStarsProvider);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Encabezado ───
              const _Header(),

              // ─── Botones de acción ───
              const _ActionsBar(),

              // ─── Lista de integrantes ───
              Expanded(
                child: membersAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const _EmptyState();
                    }
                    return _MembersList(
                      items: items,
                      columns: isTablet ? 2 : 1,
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.neonYellow,
                    ),
                  ),
                  error: (e, _) => _ErrorState(message: e.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  ENCABEZADO
// =============================================================================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, isTablet ? 28 : 20, 24, 12),
      child: Column(
        children: [
          // Estrella animada arriba
          Icon(
                Icons.star_rounded,
                size: isTablet ? 72 : 56,
                color: AppColors.neonYellow,
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 1400.ms,
                curve: Curves.easeInOut,
              ),

          const SizedBox(height: 8),

          // Título con degradado
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                AppColors.neonPink,
                AppColors.neonYellow,
                AppColors.neonCyan,
              ],
            ).createShader(bounds),
            child: Text(
              AppStrings.homeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 32 : 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
                height: 1.1,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            AppStrings.appTagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTablet ? 14 : 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  BARRA DE ACCIONES
// =============================================================================

class _ActionsBar extends ConsumerWidget {
  const _ActionsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Si la pantalla es angosta (< 500px), apilamos los botones.
    final isNarrow = screenWidth < 500;

    final addButton = _ActionButton(
      icon: Icons.person_add_alt_1_rounded,
      label: AppStrings.addMember,
      color: AppColors.neonCyan,
      onPressed: () {
        showDialog(
          context: context,
          useSafeArea: true,
          builder: (_) => const AddMemberDialog(),
        );
      },
    );

    final rankingButton = _ActionButton(
      icon: Icons.emoji_events_rounded,
      label: AppStrings.ranking,
      color: AppColors.neonYellow,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RankingPage()),
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: isNarrow
          ? Column(
              children: [addButton, const SizedBox(height: 10), rankingButton],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: addButton),
                const SizedBox(width: 12),
                Flexible(child: rankingButton),
              ],
            ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withValues(alpha: 0.25),
                widget.color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 14,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  LISTA DE INTEGRANTES
// =============================================================================

class _MembersList extends StatelessWidget {
  final List items;
  final int columns;

  const _MembersList({required this.items, required this.columns});

  @override
  Widget build(BuildContext context) {
    // Móvil: 1 columna
    if (columns == 1) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return MemberTile(
            item: item,
            onTap: () => _goToDetail(context, item),
          ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.2, end: 0);
        },
      );
    }

    // Tablet: 2 columnas
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 3.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return MemberTile(
          item: item,
          onTap: () => _goToDetail(context, item),
        ).animate(delay: (i * 40).ms).fadeIn().scale();
      },
    );
  }

  void _goToDetail(BuildContext context, dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberDetailPage(memberId: item.memberId),
      ),
    );
  }
}

// =============================================================================
//  ESTADOS VACÍO / ERROR
// =============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 72,
              color: AppColors.textDisabled,
            ),
            SizedBox(height: 16),
            Text(
              AppStrings.noMembers,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).scale(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.errorGeneric,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
