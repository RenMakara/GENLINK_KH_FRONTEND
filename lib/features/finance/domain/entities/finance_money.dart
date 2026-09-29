/// Exact two-decimal money arithmetic used where Finance combines amounts.
///
/// The API stores `NUMERIC(19,2)`. The Flutter API models remain numeric for
/// compatibility with existing screens, but sums and comparisons should move
/// through this minor-unit representation rather than adding binary doubles.
class FinanceMoney implements Comparable<FinanceMoney> {
  const FinanceMoney._(this.minorUnits);

  static final zero = FinanceMoney._(BigInt.zero);
  static final BigInt _numeric19Limit = BigInt.parse('10000000000000000000');
  static final RegExp _inputPattern = RegExp(r'^([+-]?)(\d+)(?:\.(\d{0,2}))?$');
  static final RegExp _numberPattern = RegExp(
    r'^([+-]?)(\d+)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$',
  );

  /// Cents (or the smallest hundredth unit in the selected currency).
  final BigInt minorUnits;

  static FinanceMoney? tryParseInput(String value) {
    final match = _inputPattern.firstMatch(value.trim());
    if (match == null) return null;
    return _fromParts(match[1] == '-', match[2]!, match[3] ?? '');
  }

  /// Converts an API/model number only when its decimal value fits the stored
  /// two-place, 19-digit contract. Calculations never round silently.
  static FinanceMoney? tryFromNumber(num value) {
    if (!value.isFinite) return null;
    final match = _numberPattern.firstMatch(value.toString());
    if (match == null) return null;

    final negative = match[1] == '-';
    final integer = match[2]!;
    final fraction = match[3] ?? '';
    final exponent = int.tryParse(match[4] ?? '0');
    if (exponent == null) return null;

    final digits = BigInt.tryParse('$integer$fraction');
    if (digits == null) return null;
    final scaleShift = exponent - fraction.length + 2;
    final cents = scaleShift >= 0
        ? digits * BigInt.from(10).pow(scaleShift)
        : _divideExact(digits, BigInt.from(10).pow(-scaleShift));
    if (cents == null) return null;
    return _fromCents(negative ? -cents : cents);
  }

  static FinanceMoney? _fromParts(
    bool negative,
    String integer,
    String fraction,
  ) {
    final whole = BigInt.tryParse(integer);
    if (whole == null) return null;
    final cents =
        whole * BigInt.from(100) + BigInt.parse(fraction.padRight(2, '0'));
    return _fromCents(negative ? -cents : cents);
  }

  static FinanceMoney? _fromCents(BigInt cents) {
    if (cents.abs() >= _numeric19Limit) return null;
    return FinanceMoney._(cents);
  }

  static BigInt? _divideExact(BigInt value, BigInt divisor) {
    final remainder = value.remainder(divisor);
    if (remainder != BigInt.zero) return null;
    return value ~/ divisor;
  }

  static FinanceMoney sum(Iterable<num> amounts) {
    var total = BigInt.zero;
    for (final amount in amounts) {
      final parsed = tryFromNumber(amount);
      if (parsed == null) {
        throw FormatException(
          'Finance amount is outside the NUMERIC(19,2) contract: $amount',
        );
      }
      total += parsed.minorUnits;
    }
    final result = _fromCents(total);
    if (result == null) {
      throw const FormatException(
        'Finance sum is outside the NUMERIC(19,2) contract',
      );
    }
    return result;
  }

  FinanceMoney operator +(FinanceMoney other) =>
      FinanceMoney._(minorUnits + other.minorUnits);

  FinanceMoney operator -(FinanceMoney other) =>
      FinanceMoney._(minorUnits - other.minorUnits);

  FinanceMoney abs() => FinanceMoney._(minorUnits.abs());

  int get sign => minorUnits.sign;

  String toDecimalString() {
    final negative = minorUnits.isNegative;
    final absolute = minorUnits.abs();
    final whole = absolute ~/ BigInt.from(100);
    final fraction = (absolute % BigInt.from(100)).toString().padLeft(2, '0');
    return '${negative ? '-' : ''}$whole.$fraction';
  }

  /// Rounded half away from zero. A zero prior period has no percentage
  /// baseline and therefore returns null instead of inventing a trend.
  static BigInt? percentChange(FinanceMoney current, FinanceMoney previous) {
    final baseline = previous.minorUnits.abs();
    if (baseline == BigInt.zero) return null;
    final numerator =
        (current.minorUnits - previous.minorUnits) * BigInt.from(100);
    final magnitude = numerator.abs();
    var rounded = magnitude ~/ baseline;
    final remainder = magnitude % baseline;
    if (remainder * BigInt.from(2) >= baseline) rounded += BigInt.one;
    return numerator.isNegative ? -rounded : rounded;
  }

  @override
  int compareTo(FinanceMoney other) => minorUnits.compareTo(other.minorUnits);

  @override
  bool operator ==(Object other) =>
      other is FinanceMoney && other.minorUnits == minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;
}
