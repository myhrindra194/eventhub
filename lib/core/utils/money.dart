import 'package:intl/intl.dart';

/// Les montants sont des entiers dans l’unité mineure de la devise :
/// centimes pour l’EUR et l’USD, ariary entiers pour le MGA (pas de
/// décimales en pratique, et devise « zero-decimal » chez Stripe). Un seul
/// formateur, pour que l’app, l’export CSV et les Cloud Functions
/// (`formatMoney`) affichent la même chose.
abstract final class Money {
  static const currencies = ['EUR', 'USD', 'MGA'];

  /// Borne haute du prix d’un billet, en unités mineures (1 000 000,00 €).
  static const maxAmount = 100000000;

  static bool isZeroDecimal(String currency) => currency.toUpperCase() == 'MGA';

  static int decimals(String currency) => isZeroDecimal(currency) ? 0 : 2;

  static String symbol(String currency) => switch (currency.toUpperCase()) {
    'EUR' => '€',
    'USD' => r'$',
    'MGA' => 'Ar',
    final other => other,
  };

  /// `15,00 €`, `12,50 $`, `15 000 Ar` (groupement et virgule décimale à la
  /// française).
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

  /// Ce qu’un organisateur a saisi (« 12,5 », « 12.50 », « 15 000 ») en
  /// unités mineures ; `null` si ce n’est pas un montant positif ou nul.
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

  /// L’inverse de [parse], pour pré-remplir un champ de saisie.
  static String inputValue(int amount, String currency) =>
      isZeroDecimal(currency)
      ? '$amount'
      : (amount / 100).toStringAsFixed(2).replaceAll('.', ',');
}
