import 'package:get/get.dart';

String financeText(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}

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
