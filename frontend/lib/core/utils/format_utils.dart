// lib/core/utils/format_utils.dart
import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static String formatPrice(double price, {String currency = 'USD'}) {
    final formatter = NumberFormat.currency(
      symbol: _currencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(price);
  }

  static String _currencySymbol(String code) {
    const symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'AUD': 'A\$',
    };
    return symbols[code] ?? code;
  }

  static String formatDate(DateTime date, {String locale = 'en'}) {
    return DateFormat('dd MMM yyyy', locale).format(date);
  }

  static String formatDateTime(DateTime date, {String locale = 'en'}) {
    return DateFormat('dd MMM yyyy HH:mm', locale).format(date);
  }

  static int daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return t.difference(f).inDays;
  }

  static String formatMileage(double? mileage, {String locale = 'en'}) {
    if (mileage == null || mileage == -1) return 'Unlimited';
    return '${NumberFormat('#,###', locale).format(mileage)} km';
  }
}
