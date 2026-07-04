import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats the given amount as Indian Rupee (₹).
  static String format(num amount, {int? decimalDigits}) {
    return NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: decimalDigits,
    ).format(amount);
  }
}
