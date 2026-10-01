import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../domain/entities/monthly_result.dart';
import '../../domain/entities/weekly_ranking_entry.dart';
import '../providers/ranking_provider.dart';
import '../widgets/ranking_card.dart';

/// Pantalla de ranking con 3 pestañas: Diario, Semanal, Mensual.
///
/// Incluye navegación de fechas con flechas ← → y botón "HOY" para
/// volver al presente.
class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedRankingPeriodProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ─── AppBar ───
              const _CustomAppBar(),

              // ─── Tabs ───
              _PeriodTabs(current: period),

              // ─── Navegador de fechas ───
              _DateNavigator(period: period),

              // ─── Contenido según pestaña ───
              Expanded(
                child: switch (period) {
                  RankingPeriod.daily => const _DailyView(),
                  RankingPeriod.weekly => const _WeeklyView(),
                  RankingPeriod.monthly => const _MonthlyView(),
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
//  APPBAR
// =============================================================================

class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar();

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
          const SizedBox(width: 8),
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.neonYellow,
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text(
            AppStrings.ranking,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  TABS DE PERÍODO
// =============================================================================

class _PeriodTabs extends ConsumerWidget {
  final RankingPeriod current;

  const _PeriodTabs({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tabs = [
      (period: RankingPeriod.daily, label: AppStrings.daily),
      (period: RankingPeriod.weekly, label: AppStrings.weekly),
      (period: RankingPeriod.monthly, label: AppStrings.monthly),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonCyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final selected = tab.period == current;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedRankingPeriodProvider.notifier).state =
                    tab.period;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [AppColors.neonCyan, AppColors.neonPurple],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
//  NAVEGADOR DE FECHAS
// =============================================================================

class _DateNavigator extends ConsumerWidget {
  final RankingPeriod period;

  const _DateNavigator({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final isToday = DateHelpers.isToday(date);

    // Etiqueta según período
    final label = switch (period) {
      RankingPeriod.daily => DateHelpers.formatFull(date),
      RankingPeriod.weekly => _weekLabel(date),
      RankingPeriod.monthly => _monthLabel(date),
    };

    void jump(int delta) {
      final next = period.jumpTo(date, delta);
      ref.read(selectedDateProvider.notifier).state = next;
    }

    void goToday() {
      ref.read(selectedDateProvider.notifier).state = DateTime.now();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Flecha izquierda
          _NavButton(icon: Icons.chevron_left_rounded, onTap: () => jump(-1)),

          // Etiqueta central (con botón HOY al lado)
          Expanded(
            child: GestureDetector(
              onTap: isToday ? null : goToday,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isToday
                              ? AppColors.neonYellow
                              : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neonYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.neonYellow.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'HOY',
                          style: TextStyle(
                            color: AppColors.neonYellow,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Flecha derecha
          _NavButton(icon: Icons.chevron_right_rounded, onTap: () => jump(1)),
        ],
      ),
    );
  }

  String _weekLabel(DateTime date) {
    final (from, to) = DateHelpers.weekRange(date);
    final fmt = DateFormat('d MMM', 'es');
    final weekNum = DateHelpers.isoWeekNumber(date);
    return 'Semana $weekNum · ${fmt.format(from)} — ${fmt.format(to)}';
  }

  String _monthLabel(DateTime date) {
    final fmt = DateFormat("MMMM 'de' yyyy", 'es');
    final label = fmt.format(date);
    return label[0].toUpperCase() + label.substring(1);
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Icon(icon, color: AppColors.neonCyan, size: 28),
        ),
      ),
    );
  }
}

// =============================================================================
//  VISTA DIARIA
// =============================================================================

class _DailyView extends ConsumerWidget {
  const _DailyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(dailyRankingProvider);

    return rankingAsync.when(
      data: (ranking) => _RankingList(
        entries: ranking.map((e) => RankingCard(entry: e)).toList(),
        emptyMessage: 'Sin estrellas este día',
        showEmpty: ranking.every((e) => e.stars == 0),
      ),
      loading: () => const _Loading(),
      error: (e, _) => _Error(message: e.toString()),
    );
  }
}

// =============================================================================
//  VISTA SEMANAL
// =============================================================================

class _WeeklyView extends ConsumerWidget {
  const _WeeklyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(weeklyRankingProvider);

    return rankingAsync.when(
      data: (ranking) => _RankingList(
        entries: ranking.map((e) => _WeeklyCard(entry: e)).toList(),
        emptyMessage: 'Sin estrellas esta semana',
        showEmpty: ranking.every((e) => e.weeklyStars == 0),
      ),
      loading: () => const _Loading(),
      error: (e, _) => _Error(message: e.toString()),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  final WeeklyRankingEntry entry;

  const _WeeklyCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final accent = switch (entry.position) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => AppColors.bronze,
      _ => AppColors.forIndex(entry.member.colorIndex),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.22),
              accent.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Medalla / posición
                if (entry.isPodium)
                  Text(
                    entry.medal ?? '',
                    style: const TextStyle(fontSize: 32, height: 1),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.2),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.position}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),

                // Nombre
                Expanded(
                  child: Text(
                    entry.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Total semanal
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.35),
                        accent.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: accent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.weeklyStars}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Barras por día
            _DayBars(dailyStars: entry.dailyStars, color: accent),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.1, end: 0);
  }
}

class _DayBars extends StatelessWidget {
  final List<int> dailyStars;
  final Color color;

  const _DayBars({required this.dailyStars, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxStars = dailyStars.isEmpty
        ? 0
        : dailyStars.reduce((a, b) => a > b ? a : b);

    return Row(
      children: List.generate(7, (i) {
        final stars = i < dailyStars.length ? dailyStars[i] : 0;
        final ratio = maxStars == 0 ? 0.0 : stars / maxStars;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                // Número arriba
                Text(
                  stars > 0 ? '$stars' : '',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                // Barra
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: ratio == 0 ? 2 : 6 + (14 * ratio),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [color, color.withValues(alpha: 0.5)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Etiqueta del día
                Text(
                  ['L', 'M', 'X', 'J', 'V', 'S', 'D'][i],
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
//  VISTA MENSUAL
// =============================================================================

class _MonthlyView extends ConsumerWidget {
  const _MonthlyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlyResultProvider);

    return monthlyAsync.when(
      data: (result) => _MonthlyContent(result: result),
      loading: () => const _Loading(),
      error: (e, _) => _Error(message: e.toString()),
    );
  }
}

class _MonthlyContent extends StatelessWidget {
  final MonthlyResult result;

  const _MonthlyContent({required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.hasData) {
      return const _Empty(message: 'Sin estrellas este mes');
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // ─── Banner del ganador ───
        if (result.winners.isNotEmpty) _WinnerBanner(result: result),

        const SizedBox(height: 16),

        // ─── Ranking del mes ───
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.leaderboard_rounded,
                color: AppColors.neonCyan,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Ranking del mes',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        ...result.ranking.asMap().entries.map((e) {
          return RankingCard(entry: e.value, animationIndex: e.key);
        }),

        const SizedBox(height: 24),

        // ─── Evolución semanal ───
        _WeeklyEvolution(result: result),
      ],
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  final MonthlyResult result;

  const _WinnerBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final top = result.topWinner!;
    final winner = top.member;
    final color = AppColors.forIndex(winner.colorIndex);
    final monthLabel = DateFormat("MMMM 'de' yyyy", 'es').format(result.month);
    final capitalized = monthLabel[0].toUpperCase() + monthLabel.substring(1);

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.neonYellow.withValues(alpha: 0.30),
                AppColors.neonPink.withValues(alpha: 0.20),
                AppColors.neonPurple.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.neonYellow.withValues(alpha: 0.8),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonYellow.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Título
              Text(
                result.hasTie
                    ? '🏆 EMPATE EN EL PRIMER LUGAR'
                    : '🏆 ${AppStrings.monthlyWinner}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                capitalized,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 18),

              // Corono + nombre
              if (!result.hasTie) ...[
                Text(
                      '👑',
                      style: TextStyle(
                        fontSize: 56,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: AppColors.neonYellow.withValues(alpha: 0.8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.15, 1.15),
                      duration: 1400.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(height: 12),
              ],

              // Nombres de ganadores
              ...result.winners.map((w) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.forIndex(w.member.colorIndex),
                              AppColors.forIndex(
                                w.member.colorIndex,
                              ).withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          w.member.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        w.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.neonYellow,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${w.stars}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Total del mes
              Text(
                'Total repartido: ${result.totalStars} ⭐',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}

class _WeeklyEvolution extends StatelessWidget {
  final MonthlyResult result;

  const _WeeklyEvolution({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.weeklyEvolution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: AppColors.neonPurple,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Evolución semanal',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...result.ranking.map((entry) {
            final starsPerWeek =
                result.weeklyEvolution[entry.memberId] ??
                List<int>.filled(result.weeksInMonth, 0);
            final color = AppColors.forIndex(entry.member.colorIndex);
            final maxWeek = starsPerWeek.isEmpty
                ? 0
                : starsPerWeek.reduce((a, b) => a > b ? a : b);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.member.initials[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.stars} ⭐',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(result.weeksInMonth, (i) {
                      final count = i < starsPerWeek.length
                          ? starsPerWeek[i]
                          : 0;
                      final ratio = maxWeek == 0 ? 0.0 : count / maxWeek;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              Text(
                                count > 0 ? '$count' : '',
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  height: ratio == 0 ? 2 : 4 + (10 * ratio),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'S',
                                style: TextStyle(
                                  color: AppColors.textDisabled,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
//  HELPERS DE VISTA
// =============================================================================

class _RankingList extends StatelessWidget {
  final List<Widget> entries;
  final String emptyMessage;
  final bool showEmpty;

  const _RankingList({
    required this.entries,
    required this.emptyMessage,
    required this.showEmpty,
  });

  @override
  Widget build(BuildContext context) {
    if (showEmpty) {
      return _Empty(message: emptyMessage);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: entries.asMap().entries.map((e) {
        final child = e.value;
        if (child is RankingCard) {
          return RankingCard(
            entry: child.entry,
            onTap: child.onTap,
            highlighted: child.highlighted,
            animationIndex: e.key,
          );
        }
        return child;
      }).toList(),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.neonYellow),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;

  const _Error({required this.message});

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
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              AppStrings.errorGeneric,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;

  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(),
      ),
    );
  }
}
