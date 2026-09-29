import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_money.dart';

void main() {
  group('FinanceMoney', () {
    test('parses the NUMERIC(19,2) boundaries without rounding', () {
      for (final value in [
        '0.00',
        '0.01',
        '1.00',
        '1.99',
        '10.50',
        '999.99',
        '99999999999999999.99',
      ]) {
        expect(FinanceMoney.tryParseInput(value)?.toDecimalString(), value);
      }
      expect(FinanceMoney.tryParseInput('10.001'), isNull);
      expect(FinanceMoney.tryParseInput('10.123'), isNull);
      expect(FinanceMoney.tryParseInput('100000000000000000.00'), isNull);
    });

    test('adds decimal amounts in minor units', () {
      final total = FinanceMoney.sum([0.10, 0.20]);
      expect(total.toDecimalString(), '0.30');
      expect(
        FinanceMoney.sum([1.99, 10.50, 999.99]).toDecimalString(),
        '1012.48',
      );
      expect(FinanceMoney.tryFromNumber(0.1 + 0.2), isNull);
    });

    test(
      'calculates rounded percentage changes and rejects a zero baseline',
      () {
        final hundred = FinanceMoney.tryParseInput('100.00')!;
        final oneHundredTwenty = FinanceMoney.tryParseInput('120.00')!;
        final result = FinanceMoney.percentChange(oneHundredTwenty, hundred);
        expect(result, BigInt.from(20));
        expect(
          FinanceMoney.percentChange(FinanceMoney.zero, FinanceMoney.zero),
          isNull,
        );
        expect(FinanceMoney.percentChange(hundred, FinanceMoney.zero), isNull);
      },
    );
  });
}
