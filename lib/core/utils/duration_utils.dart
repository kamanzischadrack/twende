// lib/core/utils/duration_utils.dart
// Twende: Duration helpers for rental billing calculations.

class DurationUtils {
  DurationUtils._();

  /// Billable days (ceiling of hours/24, minimum 1).
  static int billableDays(DateTime from, DateTime to) {
    final hours = to.difference(from).inHours;
    if (hours <= 0) return 1;
    return ((hours + 23) ~/ 24);
  }

  /// Decompose a total days count into months/weeks/days.
  static ({int months, int weeks, int days}) decompose(
    int totalDays, {
    int monthDays = 30,
    int weekDays = 7,
  }) {
    final months = totalDays ~/ monthDays;
    final rem1 = totalDays % monthDays;
    final weeks = rem1 ~/ weekDays;
    final days = rem1 % weekDays;
    return (months: months, weeks: weeks, days: days);
  }

  /// Human-readable duration string.
  static String describe(Duration duration) {
    final d = duration.inDays;
    final h = duration.inHours % 24;
    if (d == 0) return '$h hour${h == 1 ? '' : 's'}';
    if (h == 0) return '$d day${d == 1 ? '' : 's'}';
    return '$d day${d == 1 ? '' : 's'} ${h}h';
  }

  /// Format date as 'dd MMM yyyy'.
  static String formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day.toString().padLeft(2,'0')} ${months[dt.month-1]} ${dt.year}';
  }

  /// Format date+time as 'dd MMM yyyy HH:mm'.
  static String formatDateTime(DateTime dt) =>
      '${formatDate(dt)} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}
