import 'dart:async';
import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_payment_success.dart';

class PaymentProcessScreen extends StatefulWidget {
  final double amount;
  final String merchant;
  final FinanceCurrency currency;

  const PaymentProcessScreen({
    super.key,
    required this.amount,
    required this.merchant,
    required this.currency,
  });

  @override
  State<PaymentProcessScreen> createState() => _PaymentProcessScreenState();
}

class _PaymentProcessScreenState extends State<PaymentProcessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  Timer? _timer;

  bool _isProcessing = false;
  bool _isCompleted = false;

  double _dragPosition = 0;

  static const double _sliderHeight = 58;
  static const double _sliderPadding = 4;
  static const double _sliderButtonSize = 50;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // FORMAT AMOUNT
  // ============================================================

  String _formatAmount() {
    if (widget.currency == FinanceCurrency.usd) {
      return '\$${widget.amount.toStringAsFixed(2)}';
    }

    return '${widget.amount.toStringAsFixed(0)} ៛';
  }

  // ============================================================
  // SLIDER START
  // ============================================================

  void _onDragStart() {
    if (_isProcessing || _isCompleted) return;
  }

  // ============================================================
  // SLIDER UPDATE
  // ============================================================

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isProcessing || _isCompleted) return;

    setState(() {
      _dragPosition += details.delta.dx;

      _dragPosition = _dragPosition.clamp(0.0, maxDrag);
    });
  }

  // ============================================================
  // SLIDER END
  // ============================================================

  void _onDragEnd(double maxDrag) {
    if (_isProcessing || _isCompleted) return;

    final progress = maxDrag <= 0 ? 0 : _dragPosition / maxDrag;

    if (progress >= 0.80) {
      // Snap completely to the end.
      setState(() {
        _dragPosition = maxDrag;
      });

      _confirmPayment();
    } else {
      // Snap back to the beginning.
      setState(() {
        _dragPosition = 0;
      });
    }
  }

  // ============================================================
  // CONFIRM PAYMENT
  // ============================================================

  void _confirmPayment() {
    if (_isProcessing || _isCompleted) return;

    setState(() {
      _isProcessing = true;
      _dragPosition = 0;
    });

    _animationController.repeat();

    // ==========================================================
    // DEMO PAYMENT PROCESS
    //
    // Replace this timer with your real payment API call.
    // ==========================================================

    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      _animationController.stop();

      setState(() {
        _isProcessing = false;
        _isCompleted = true;
      });

      _openSuccessScreen();
    });
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _openSuccessScreen() {
    if (!mounted) return;

    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          amount: widget.amount,
          merchant: widget.merchant,
          currency: widget.currency,
        ),
      ),
    );
  }

  // ============================================================
  // CANCEL
  // ============================================================

  void _cancelPayment() {
    if (_isProcessing) return;

    _timer?.cancel();

    Navigator.pop(context);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),

          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              Row(
                children: [
                  IconButton(
                    onPressed: _isProcessing ? null : _cancelPayment,

                    icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                  ),

                  const SizedBox(width: 4),

                  Expanded(
                    child: Text(
                      'Confirm Payment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PAYMENT ICON
              // ==================================================
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),

                width: 88,
                height: 88,

                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),

                child: AnimatedBuilder(
                  animation: _animationController,

                  builder: (context, child) {
                    if (!_isProcessing) {
                      return child!;
                    }

                    return Transform.rotate(
                      angle: _animationController.value * 6.283185307,

                      child: child,
                    );
                  },

                  child: Icon(
                    _isProcessing
                        ? Icons.sync_rounded
                        : Icons.qr_code_2_rounded,

                    size: 42,
                    color: primary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TITLE
              // ==================================================
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),

                child: Text(
                  _isProcessing ? 'Processing Payment' : 'Confirm Your Payment',

                  key: ValueKey(_isProcessing),

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),

                child: Text(
                  _isProcessing
                      ? 'Please wait while we process your payment.'
                      : 'Review the payment details before confirming.',

                  key: ValueKey('description_$_isProcessing'),

                  textAlign: TextAlign.center,

                  style: TextStyle(color: textMuted, fontSize: 14, height: 1.5),
                ),
              ),

              const SizedBox(height: 26),

              // ==================================================
              // PAYMENT INFORMATION CARD
              // ==================================================
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: surface,

                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(color: border),
                ),

                child: Column(
                  children: [
                    // ==========================================
                    // MERCHANT
                    // ==========================================
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,

                          decoration: BoxDecoration(
                            color: surfaceSecondary,
                            borderRadius: BorderRadius.circular(13),
                          ),

                          child: Icon(
                            Icons.storefront_rounded,
                            color: textPrimary,
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                'Merchant',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                widget.merchant,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,

                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Divider(height: 1, color: border),

                    const SizedBox(height: 20),

                    // ==========================================
                    // AMOUNT
                    // ==========================================
                    Text(
                      'Amount',

                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),

                    const SizedBox(height: 6),

                    FittedBox(
                      fit: BoxFit.scaleDown,

                      child: Text(
                        _formatAmount(),

                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.currency.apiValue,

                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ==================================================
              // PROCESSING
              // ==================================================
              if (_isProcessing) ...[
                SizedBox(
                  width: 30,
                  height: 30,

                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: primary,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Please do not close the app',

                  textAlign: TextAlign.center,

                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ]
              // ==================================================
              // CONFIRM SLIDER
              // ==================================================
              else ...[
                Text(
                  'Slide to confirm payment',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // RESPONSIVE SLIDER
                // ==================================================
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    // Total width of the slider.
                    final sliderWidth = constraints.maxWidth;

                    // Actual draggable distance.
                    final maxDrag =
                        sliderWidth - (_sliderPadding * 2) - _sliderButtonSize;

                    return Container(
                      width: sliderWidth,
                      height: _sliderHeight,

                      padding: const EdgeInsets.all(_sliderPadding),

                      decoration: BoxDecoration(
                        color: surface,

                        borderRadius: BorderRadius.circular(32),

                        border: Border.all(color: border),
                      ),

                      child: Stack(
                        clipBehavior: Clip.hardEdge,

                        children: [
                          // ====================================
                          // BACKGROUND TEXT
                          // ====================================
                          Positioned.fill(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 60,
                                ),

                                child: FittedBox(
                                  fit: BoxFit.scaleDown,

                                  child: Text(
                                    'Slide to Pay',

                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ====================================
                          // DRAG BUTTON
                          // ====================================
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 180),

                            curve: Curves.easeOut,

                            left: _dragPosition,

                            top: 0,

                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,

                              onHorizontalDragStart: (_) {
                                _onDragStart();
                              },

                              onHorizontalDragUpdate: (details) {
                                _onDragUpdate(details, maxDrag);
                              },

                              onHorizontalDragEnd: (_) {
                                _onDragEnd(maxDrag);
                              },

                              child: Container(
                                width: _sliderButtonSize,
                                height: _sliderButtonSize,

                                decoration: BoxDecoration(
                                  color: primary,

                                  shape: BoxShape.circle,

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.14,
                                      ),

                                      blurRadius: 8,

                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),

                                child: Icon(
                                  Icons.arrow_forward_rounded,

                                  color: textInverse,

                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // ==================================================
                // CANCEL
                // ==================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: OutlinedButton(
                    onPressed: _cancelPayment,

                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,

                      side: BorderSide(color: border),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: const Text(
                      'Cancel',

                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
