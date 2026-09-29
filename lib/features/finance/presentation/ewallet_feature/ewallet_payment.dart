import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_money.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_payment_processing.dart';

class Payment extends StatefulWidget {
  final double? amount;
  final String? merchant;
  final FinanceCurrency currency;

  const Payment({
    super.key,
    this.amount,
    this.merchant,
    required this.currency,
  });

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  String _amountText = '0';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    if (widget.amount != null && widget.amount! > 0) {
      _amountText = _formatInitialAmount(widget.amount!);
    }
  }

  // ─────────────────────────────────────────────
  // AMOUNT
  // ─────────────────────────────────────────────

  String _formatInitialAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  FinanceMoney? _getAmount() {
    if (_amountText.isEmpty || _amountText == '.') {
      return null;
    }
    return FinanceMoney.tryParseInput(_amountText);
  }

  String _merchantName() {
    final merchant = widget.merchant?.trim();

    if (merchant == null || merchant.isEmpty) {
      return 'finance.ewallet.defaultMerchant'.tr;
    }

    return merchant;
  }

  String _displayAmount() {
    if (_amountText.isEmpty) {
      return '0';
    }

    return _amountText;
  }

  // ─────────────────────────────────────────────
  // KEYPAD
  // ─────────────────────────────────────────────

  void _onKeyPressed(String key) {
    if (_isProcessing) return;

    setState(() {
      // Backspace
      if (key == 'backspace') {
        if (_amountText.length > 1) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        } else {
          _amountText = '0';
        }

        return;
      }

      // Decimal
      if (key == '.') {
        if (_amountText.contains('.')) {
          return;
        }

        if (_amountText.isEmpty) {
          _amountText = '0.';
        } else {
          _amountText += '.';
        }

        return;
      }

      // Number
      if (RegExp(r'^[0-9]$').hasMatch(key)) {
        // Maximum 2 decimal places
        if (_amountText.contains('.')) {
          final decimalPart = _amountText.split('.').last;

          if (decimalPart.length >= 2) {
            return;
          }
        }

        if (_amountText == '0' && key == '0') return;
        final candidate = _amountText == '0' ? key : '$_amountText$key';
        // Enforce the backend's NUMERIC(19,2) limit without imposing a smaller
        // keypad-only amount cap.
        if (FinanceMoney.tryParseInput(candidate) == null) return;
        _amountText = candidate;
      }
    });
  }

  // ─────────────────────────────────────────────
  // PAYMENT
  // ─────────────────────────────────────────────

  void _confirmPayment() {
    if (_isProcessing) return;

    final exactAmount = _getAmount();
    if (exactAmount == null || exactAmount.sign <= 0) {
      _showMessage('finance.ewallet.invalidAmount'.tr, AppColors.danger);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentProcessingScreen(
          amount: double.parse(exactAmount.toDecimalString()),
          merchant: _merchantName(),
          currency: widget.currency,
        ),
      ),
    );
  }

  void _cancelPayment() {
    if (_isProcessing) return;

    Navigator.pop(context);
  }

  void _showMessage(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    // ─────────────────────────────────────────────
    // RESPONSIVE
    // ─────────────────────────────────────────────

    final size = MediaQuery.sizeOf(context);

    final width = size.width;
    final height = size.height;

    final isSmallPhone = width < 360;
    final isTablet = width >= 600;

    final isVeryShort = height < 680;
    final isShort = height < 760;

    final horizontalPadding = isSmallPhone
        ? 14.0
        : isTablet
        ? 28.0
        : 18.0;

    final contentMaxWidth = isTablet ? 620.0 : double.infinity;

    final topHeight = isVeryShort
        ? height * 0.39
        : isShort
        ? height * 0.40
        : height * 0.43;

    // ─────────────────────────────────────────────
    // SCAFFOLD
    // ─────────────────────────────────────────────

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // ───────────────────────────────
                  // TOP AREA
                  // ───────────────────────────────
                  SizedBox(
                    height: topHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          // ────────────────────────
                          // HEADER
                          // ────────────────────────
                          SizedBox(
                            height: isVeryShort ? 48 : 56,
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: _isProcessing ? null : _cancelPayment,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? 0.4
                                                : 0.07,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: textPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 13),

                                Expanded(
                                  child: Text(
                                    'finance.ewallet.confirmPayment'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ────────────────────────
                          // MERCHANT
                          // ────────────────────────
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Merchant icon
                                Container(
                                  width: isVeryShort ? 72 : 82,
                                  height: isVeryShort ? 72 : 82,
                                  decoration: BoxDecoration(
                                    color: surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.15 : 0.08,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: primary,
                                    size: isVeryShort ? 36 : 42,
                                  ),
                                ),

                                SizedBox(height: isVeryShort ? 8 : 12),

                                // Merchant name
                                Text(
                                  _merchantName(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: isSmallPhone ? 18 : 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'finance.ewallet.paymentToMerchant'.tr,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Currency badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: surfaceSecondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.currency.apiValue,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ───────────────────────────────
                  // BOTTOM PAYMENT PANEL
                  // ───────────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    top: topHeight - 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isVeryShort ? 16 : 22,
                          horizontalPadding,
                          isVeryShort ? 8 : 12,
                        ),
                        child: Column(
                          children: [
                            // ─────────────────────
                            // AMOUNT DISPLAY
                            // ─────────────────────
                            _buildAmountDisplay(
                              surfaceSecondary: surfaceSecondary,
                              border: primary,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isDark: isDark,
                              compact: isVeryShort,
                            ),

                            SizedBox(
                              height: isVeryShort
                                  ? 8
                                  : isShort
                                  ? 12
                                  : 18,
                            ),

                            // ─────────────────────
                            // KEYPAD
                            // ─────────────────────
                            Expanded(
                              child: _buildKeypad(
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                border: border,
                                primary: primary,
                                isDark: isDark,
                              ),
                            ),

                            SizedBox(
                              height: isVeryShort
                                  ? 8
                                  : isShort
                                  ? 10
                                  : 14,
                            ),

                            // ─────────────────────
                            // CONFIRM BUTTON
                            // ─────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: isVeryShort ? 48 : 54,
                              child: ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : _confirmPayment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: textInverse,
                                  disabledBackgroundColor: primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  disabledForegroundColor: textInverse
                                      .withValues(alpha: 0.7),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: _isProcessing
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: textInverse,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'finance.ewallet.confirmPayment'.tr,
                                            style: TextStyle(
                                              fontSize: isSmallPhone ? 14 : 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            SizedBox(height: isVeryShort ? 2 : 5),

                            // ─────────────────────
                            // CANCEL
                            // ─────────────────────
                            SizedBox(
                              height: 30,
                              child: TextButton(
                                onPressed: _isProcessing
                                    ? null
                                    : _cancelPayment,
                                style: TextButton.styleFrom(
                                  foregroundColor: textMuted,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'finance.ewallet.cancel'.tr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // AMOUNT DISPLAY
  // ─────────────────────────────────────────────

  Widget _buildAmountDisplay({
    required Color surfaceSecondary,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required bool compact,
  }) {
    final amountFontSize = compact ? 32.0 : 40.0;

    return Container(
      width: double.infinity,
      height: compact ? 58 : 68,
      decoration: BoxDecoration(
        color: surfaceSecondary.withValues(alpha: isDark ? 0.65 : 0.7),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: border, width: 1.3),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.currency == FinanceCurrency.usd)
                Text(
                  '\$',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: amountFontSize,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),

              Text(
                _displayAmount(),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1,
                ),
              ),

              if (widget.currency == FinanceCurrency.khr)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(
                    '៛',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: amountFontSize * 0.55,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // KEYPAD
  // ─────────────────────────────────────────────

  Widget _buildKeypad({
    required Color textPrimary,
    required Color textMuted,
    required Color border,
    required Color primary,
    required bool isDark,
  }) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'backspace'],
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int rowIndex = 0; rowIndex < keys.length; rowIndex++)
            Expanded(
              child: Row(
                children: [
                  for (
                    int columnIndex = 0;
                    columnIndex < keys[rowIndex].length;
                    columnIndex++
                  )
                    Expanded(
                      child: _buildKey(
                        key: keys[rowIndex][columnIndex],
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        border: border,
                        primary: primary,
                        isDark: isDark,
                        isLastRow: rowIndex == keys.length - 1,
                        isLastColumn: columnIndex == keys[rowIndex].length - 1,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // KEYPAD KEY
  // ─────────────────────────────────────────────

  Widget _buildKey({
    required String key,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
    required Color primary,
    required bool isDark,
    required bool isLastRow,
    required bool isLastColumn,
  }) {
    final isBackspace = key == 'backspace';
    final isDecimal = key == '.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing ? null : () => _onKeyPressed(key),
        splashColor: primary.withValues(alpha: 0.08),
        highlightColor: primary.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: isLastColumn
                  ? BorderSide.none
                  : BorderSide(
                      color: border.withValues(alpha: isDark ? 0.5 : 0.65),
                      width: 0.8,
                    ),
              bottom: isLastRow
                  ? BorderSide.none
                  : BorderSide(
                      color: border.withValues(alpha: isDark ? 0.5 : 0.65),
                      width: 0.8,
                    ),
            ),
          ),
          child: Center(
            child: isBackspace
                ? Icon(Icons.backspace_outlined, color: textPrimary, size: 23)
                : Text(
                    key,
                    style: TextStyle(
                      color: isDecimal ? primary : textPrimary,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
