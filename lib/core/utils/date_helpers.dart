import 'package:intl/intl.dart';

/// Utilidades para trabajar con fechas del concurso.
///
/// Convención:
/// - **Semana empieza en lunes** (ISO 8601).
/// - Los rangos son inclusivos en ambos extremos.
class DateHelpers {
  DateHelpers._();

  // ---------- RANGOS ----------

  /// Devuelve `(inicio, fin)` del día de la fecha dada.
  /// Ej: si ref = 2025-10-01 15:30 → (2025-10-01 00:00:00, 2025-10-01 23:59:59.999)
  static (DateTime from, DateTime to) dayRange(DateTime ref) {
    final from = DateTime(ref.year, ref.month, ref.day);
    final to = DateTime(ref.year, ref.month, ref.day, 23, 59, 59, 999);
    return (from, to);
  }

  /// Devuelve `(inicio, fin)` de la semana ISO (lunes a domingo) de la fecha dada.
  static (DateTime from, DateTime to) weekRange(DateTime ref) {
    // DateTime.weekday: 1 = lunes, 7 = domingo
    final monday = ref.subtract(Duration(days: ref.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final from = DateTime(monday.year, monday.month, monday.day);
    final to = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
    return (from, to);
  }

  /// Devuelve `(inicio, fin)` del mes de la fecha dada.
  static (DateTime from, DateTime to) monthRange(DateTime ref) {
    final from = DateTime(ref.year, ref.month, 1);
    // Día 0 del siguiente mes = último día del mes actual.
    final lastDay = DateTime(ref.year, ref.month + 1, 0);
    final to = DateTime(
      lastDay.year,
      lastDay.month,
      lastDay.day,
      23,
      59,
      59,
      999,
    );
    return (from, to);
  }

  // ---------- ETIQUETAS ----------

  /// Número de semana ISO del año (1 a 53).
  static int isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1; // lunes = 0
    return ((dayOfYear + daysOffset - 1) / 7).ceil();
  }

  /// Etiqueta para una fecha: `"2025-10-01"`.
  static String toIsoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Etiqueta para mes: `"2025-10"`.
  static String toIsoMonth(DateTime d) => DateFormat('yyyy-MM').format(d);

  /// Etiqueta para semana: `"2025-W40"`.
  static String toIsoWeek(DateTime d) =>
      '${d.year}-W${isoWeekNumber(d).toString().padLeft(2, '0')}';

  // ---------- FORMATEO AMIGABLE ----------

  /// Ej: `"miércoles, 1 de octubre de 2025"`.
  static String formatFull(DateTime d) =>
      DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'es').format(d);

  /// Ej: `"01/10/2025"`.
  static String formatShort(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  /// Ej: `"14:35"`.
  static String formatTime(DateTime d) => DateFormat('HH:mm').format(d);

  /// Ej: `"01/10 14:35"`.
  static String formatDateTime(DateTime d) =>
      DateFormat('dd/MM HH:mm').format(d);

  /// Devuelve `"Hoy"`, `"Ayer"`, `"Hace N días"` o la fecha corta.
  static String humanize(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'Hoy';
    if (diffDays == 1) return 'Ayer';
    if (diffDays < 7) return 'Hace $diffDays días';
    return formatShort(d);
  }

  // ---------- HELPERS DE UI ----------

  /// ¿La fecha dada es hoy?
  static bool isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// ¿La fecha dada está en la semana actual?
  static bool isThisWeek(DateTime d) {
    final (from, to) = weekRange(DateTime.now());
    return d.isAfter(from.subtract(const Duration(milliseconds: 1))) &&
        d.isBefore(to.add(const Duration(milliseconds: 1)));
  }

  /// ¿La fecha dada está en el mes actual?
  static bool isThisMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }
}
