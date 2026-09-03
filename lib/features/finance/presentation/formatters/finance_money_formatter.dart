import '../../domain/entities/finance_entities.dart';

/// Formats Finance amounts without converting between currencies.
///
/// USD is rendered with two fractional digits. KHR is rendered as a whole
/// amount, which matches the dashboard's user-facing currency convention.
abstract final class FinanceMoneyFormatter {
  const FinanceMoneyFormatter._();

  static String format(double amount, FinanceCurrency currency) {
    final decimals = currency == FinanceCurrency.usd ? 2 : 0;
    final rounded = amount.abs().toStringAsFixed(decimals);
    final parts = rounded.split('.');
    final grouped = _groupThousands(parts.first);
    final number = decimals == 0 ? grouped : '$grouped.${parts[1]}';
    final symbol = currency == FinanceCurrency.usd ? r'$' : '៛';
    final sign = amount < 0 ? '-' : '';
    return '$sign$symbol$number';
  }

  static String signed(
    double amount,
    FinanceCurrency currency, {
    required bool debit,
  }) {
    final sign = debit ? '-' : '+';
    return '$sign${format(amount.abs(), currency)}';
  }

  static String _groupThousands(String value) {
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      if (index > 0 && (value.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(value[index]);
    }
    return buffer.toString();
  }
}
