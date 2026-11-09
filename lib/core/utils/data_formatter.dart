import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String format(
    DateTime date, {
    String pattern = 'dd/MM/yyyy - hh:mm a',
    String locale = 'ar',
  }) {
    return DateFormat(pattern, locale).format(date);
  }
}

class MoneyFormatter {
  MoneyFormatter._();

  static String format(
    double value, {
    String pattern = '#,##0.00',
    String locale = 'ar',
  }) {
    return NumberFormat(pattern, locale).format(value);
  }

  static String withCurrency(
    double value, {
    String pattern = '#,##0.00',
    String locale = 'ar',
    required String currencySymbol,
  }) {
    return '${format(value, pattern: pattern, locale: locale)} $currencySymbol';
  }
}
