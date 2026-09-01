import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/ewallet_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_payment_success.dart';

class PayWithKHQRScreen extends StatefulWidget {
  const PayWithKHQRScreen({super.key});

  @override
  State<PayWithKHQRScreen> createState() => _PayWithKHQRScreenState();
}

class _PayWithKHQRScreenState extends State<PayWithKHQRScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late final EWalletController _walletController;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _walletController = Get.find<EWalletController>();
    _walletController.clearOperationError();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || !amount.isFinite || amount <= 0) {
      setState(() => _validationError = 'finance.validation.invalidAmount'.tr);
      return;
    }
    setState(() => _validationError = null);
    final note = _noteController.text.trim();
    final success = await _walletController.makePayment(
      amount: amount,
      merchant: 'ShopABC · KHQR',
      note: note.isEmpty ? null : note,
    );
    if (!mounted || !success) return;
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          amount: amount,
          merchant: 'ShopABC · KHQR',
          currency: _walletController.selectedCurrency.value,
        ),
      ),
    );
  }

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
    final currency = _walletController.selectedCurrency.value;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'finance.ewallet.paymentTitle'.tr,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 28,
                  color: textPrimary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ShopABC · KHQR',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'finance.ewallet.scanToPay'.trParams({
                  'currency': currency.apiValue,
                }),
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 128,
                        color: textPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        prefixText: currency == FinanceCurrency.usd
                            ? r'$'
                            : '៛',
                        prefixStyle: TextStyle(
                          color: textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                        hintText: '0',
                        hintStyle: TextStyle(color: textMuted),
                        errorText: _validationError,
                        border: InputBorder.none,
                      ),
                    ),
                    Text(
                      'finance.ewallet.amountIn'.trParams({
                        'currency': currency.apiValue,
                      }),
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                maxLines: 1,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'finance.ewallet.noteOptional'.tr,
                  hintStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: border),
                  ),
                ),
              ),
              Obx(() {
                final error = _walletController.operationErrorMessage.value;
                if (error == null) return const SizedBox(height: 0);
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _walletController.isOperationLoading.value
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: textInverse,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _walletController.isOperationLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: textInverse,
                            ),
                          )
                        : Text(
                            'finance.ewallet.confirmPayment'.tr,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'common.cancel'.tr,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
