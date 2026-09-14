import 'package:intl/intl.dart';

/// Amounts are integers in the currency's minor unit: cents for EUR and USD,
/// whole ariary for MGA (no decimals in practice, and zero-decimal for
/// Stripe). One formatter, so the app, the CSV export and the Cloud
/// Functions (`formatMoney`) print the same thing.
abstract final class Money {
  static const currencies = ['EUR', 'USD', 'MGA'];

  /// Upper bound of a ticket price, in minor units (1 000 000,00 €).
  static const maxAmount = 100000000;

  static bool isZeroDecimal(String currency) => currency.toUpperCase() == 'MGA';

  static int decimals(String currency) => isZeroDecimal(currency) ? 0 : 2;

  static String symbol(String currency) => switch (currency.toUpperCase()) {
    'EUR' => '€',
    'USD' => r'$',
    'MGA' => 'Ar',
    final other => other,
  };

  /// `15,00 €`, `12,50 $`, `15 000 Ar` (French grouping and decimal comma).
  static String format(int amount, String currency) {
    final code = currency.toUpperCase();
    final digits = decimals(code);
    return NumberFormat.currency(
      locale: 'fr_FR',
      name: code,
      symbol: symbol(code),
      decimalDigits: digits,
    ).format(digits == 0 ? amount : amount / 100);
  }

  /// What an organizer typed ("12,5", "12.50", "15 000") in minor units;
  /// `null` when it is not a non-negative amount.
  static int? parse(String input, String currency) {
    final cleaned = input
        .replaceAll(RegExp('[\\s  ]'), '')
        .replaceAll(',', '.');
    if (cleaned.isEmpty) return 0;
    final value = double.tryParse(cleaned);
    if (value == null || value < 0 || value.isNaN || value.isInfinite) {
      return null;
    }
    return isZeroDecimal(currency) ? value.round() : (value * 100).round();
  }

  /// The inverse of [parse], for pre-filling a text field.
  static String inputValue(int amount, String currency) =>
      isZeroDecimal(currency)
      ? '$amount'
      : (amount / 100).toStringAsFixed(2).replaceAll('.', ',');
}
