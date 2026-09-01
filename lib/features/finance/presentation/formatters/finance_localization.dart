import 'package:get/get.dart';

/// Resolves a Finance UI key while retaining a useful English fallback for
/// controller tests or hosts that have not installed the app translation
/// table yet. GetX returns the key itself when no translation is registered.
String financeText(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}

/// Maps backend transaction types to localized labels. Unknown future values
/// use a generic localized label instead of crashing or being misclassified.
String financeTransactionTypeText(String rawType) {
  final type = rawType.trim().toUpperCase();
  final key = switch (type) {
    'KHQR_PAYMENT' => 'finance.transactionType.khqrPayment',
    'EVENT_PAYMENT' => 'finance.transactionType.eventPayment',
    'DEPOSIT' => 'finance.transactionType.deposit',
    'REWARD' => 'finance.transactionType.reward',
    'EXPENSE' => 'finance.transactionType.expense',
    'INCOME' => 'finance.transactionType.income',
    'SAVING' => 'finance.transactionType.saving',
    _ => null,
  };
  if (key == null) {
    return financeText('finance.transactionType.unknown', 'Wallet Transaction');
  }
  return financeText(key, type);
}
