import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/income_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_detail_widget.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

/// Detail view backed by the complete Income list payload.
class IncomeDetailScreen extends StatelessWidget {
  const IncomeDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.time,
    required this.source,
    this.description,
    this.currency,
    this.incomeId,
    this.onEdit,
    this.onDeleted,
  });

  factory IncomeDetailScreen.fromEntity(
    FinanceIncomeEntity income, {
    VoidCallback? onEdit,
    Future<bool> Function()? onDeleted,
  }) {
    final source = income.source;
    return IncomeDetailScreen(
      title: income.title,
      subtitle: [
        income.incomeDate,
        if (source?.trim().isNotEmpty == true) source!,
      ].join(' · '),
      amount: FinanceMoneyFormatter.signed(
        income.amount,
        income.currency,
        debit: false,
      ),
      date: income.incomeDate,
      time: _timeFromCreatedAt(income.createdAt),
      source: source ?? '—',
      description: income.description,
      currency: income.currency,
      incomeId: income.incomeId,
      onEdit: onEdit,
      onDeleted: onDeleted,
    );
  }

  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final String time;
  final String source;
  final String? description;
  final FinanceCurrency? currency;
  final String? incomeId;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onDeleted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final secondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final accent = AppColors.financeAccent;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  ExpenseHeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    background: surface,
                    iconColor: textPrimary,
                    borderColor: border,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'finance.income.details'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                child: Column(
                  children: [
                    ExpenseSummaryCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: accent,
                      iconBackground: accent.withValues(alpha: .12),
                      title: title,
                      subtitle: subtitle,
                      amount: amount,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    if (currency != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        currency!.apiValue,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ExpenseCardContainer(
                      surface: surface,
                      border: border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExpenseCardTitle(
                            title: 'finance.income.detail'.tr,
                            textPrimary: textPrimary,
                          ),
                          const SizedBox(height: 16),
                          ExpenseDetailItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'finance.income.date'.tr,
                            value: date,
                            surfaceSecondary: secondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          ExpenseDetailDivider(border: border),
                          ExpenseDetailItem(
                            icon: Icons.access_time_rounded,
                            label: 'finance.income.time'.tr,
                            value: time,
                            surfaceSecondary: secondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          ExpenseDetailDivider(border: border),
                          ExpenseDetailItem(
                            icon: Icons.label_outline_rounded,
                            label: 'finance.income.source'.tr,
                            value: source,
                            surfaceSecondary: secondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          if (description != null &&
                              description!.trim().isNotEmpty) ...[
                            ExpenseDetailDivider(border: border),
                            ExpenseNoteItem(
                              note: description!,
                              surfaceSecondary: secondary,
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit ?? () => Navigator.pop(context),
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: Text('finance.income.edit'.tr),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDeleted == null
                                ? null
                                : () => _showDeleteDialog(context),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text('finance.income.delete'.tr),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB00020),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ExpenseCloseButton(
                      text: 'finance.income.close'.tr,
                      background: surface,
                      border: border,
                      textColor: textPrimary,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('finance.income.deleteConfirmTitle'.tr),
        content: Text('finance.income.deleteConfirmMessage'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('finance.income.cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('finance.income.delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || onDeleted == null) return;
    final deleted = await onDeleted!();
    if (!context.mounted) return;
    if (deleted) {
      Navigator.pop(context, true);
    } else {
      final error = Get.isRegistered<IncomeController>()
          ? Get.find<IncomeController>().mutationErrorMessage.value
          : null;
      Get.snackbar(
        'finance.income.delete'.tr,
        error ?? 'common.error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

String _timeFromCreatedAt(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return value;
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${parsed.hour >= 12 ? 'PM' : 'AM'}';
}
