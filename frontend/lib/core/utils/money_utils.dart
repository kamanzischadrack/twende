// lib/core/utils/money_utils.dart
// Twende: Currency formatting — RWF (no decimals) + multi-currency.
import 'package:intl/intl.dart';

class MoneyUtils {
  MoneyUtils._();

  static String format(double amount, [String currency = 'RWF']) {
    if (currency == 'RWF') {
      return 'RWF ${NumberFormat('#,##0', 'en').format(amount.round())}';
    }
    return NumberFormat.currency(symbol: _symbol(currency), decimalDigits: 2)
        .format(amount);
  }

  static String rwf(double amount) => format(amount, 'RWF');
  static String formatRwf(num amount) => format(amount.toDouble(), 'RWF');
  static String usd(double amount) => format(amount, 'USD');

  /// Just the number, formatted with commas, no currency suffix.
  static String number(double amount, {int decimals = 0}) {
    final pattern = decimals > 0
        ? '#,##0.${'0' * decimals}'
        : '#,##0';
    return NumberFormat(pattern, 'en').format(amount);
  }

  static String _symbol(String currency) {
    switch (currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'RWF': return 'RWF ';
      default: return '$currency ';
    }
  }
}
