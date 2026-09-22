import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_detail_widget.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.time,
    required this.category,
    required this.payment,
    this.note,
    this.currency,
    this.expenseId,
    this.onEdit,
    this.onDeleted,
  });

  factory ExpenseDetailScreen.fromEntity(
    FinanceExpenseEntity expense, {
    VoidCallback? onEdit,
    Future<bool> Function()? onDeleted,
  }) {
    final accent = _categoryColor(expense.category);
    return ExpenseDetailScreen(
      icon: _categoryIcon(expense.category),
      iconColor: accent,
      iconBackground: accent.withValues(alpha: .12),
      title: expense.title,
      subtitle: [
        expense.expenseDate,
        if (expense.category?.trim().isNotEmpty == true) expense.category!,
      ].join(' · '),
      amount: FinanceMoneyFormatter.signed(
        expense.amount,
        expense.currency,
        debit: true,
      ),
      date: expense.expenseDate,
      time: _timeFromCreatedAt(expense.createdAt),
      category: expense.category ?? '—',
      payment: expense.paymentMethod ?? '—',
      note: expense.description,
      currency: expense.currency,
      expenseId: expense.expenseId,
      onEdit: onEdit,
      onDeleted: onDeleted,
    );
  }

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final String time;
  final String category;
  final String payment;
  final String? note;
  final FinanceCurrency? currency;
  final String? expenseId;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onDeleted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'finance.expense.details'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  ExpenseHeaderButton(
                    icon: Icons.more_horiz_rounded,
                    background: surface,
                    iconColor: textMuted,
                    borderColor: border,
                    onTap: () => _showMoreMenu(context),
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
                      icon: icon,
                      iconColor: iconColor,
                      iconBackground: iconBackground,
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
                            title: 'finance.expense.detail'.tr,
                            textPrimary: textPrimary,
                          ),
                          const SizedBox(height: 16),
                          ExpenseDetailItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'finance.expense.date'.tr,
                            value: date,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          ExpenseDetailDivider(border: border),
                          ExpenseDetailItem(
                            icon: Icons.access_time_rounded,
                            label: 'finance.expense.time'.tr,
                            value: time,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          ExpenseDetailDivider(border: border),
                          ExpenseDetailItem(
                            icon: Icons.payments_outlined,
                            label: 'finance.expense.payment'.tr,
                            value: payment,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          ExpenseDetailDivider(border: border),
                          ExpenseDetailItem(
                            icon: Icons.category_outlined,
                            label: 'finance.expense.category'.tr,
                            value: category,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          if (note != null && note!.trim().isNotEmpty) ...[
                            ExpenseDetailDivider(border: border),
                            ExpenseNoteItem(
                              note: note!,
                              surfaceSecondary: surfaceSecondary,
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
                            label: Text('finance.expense.edit'.tr),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              backgroundColor: surface,
                              side: BorderSide(color: border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(44),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDeleted == null
                                ? null
                                : () => _showDeleteDialog(context),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text('finance.expense.delete'.tr),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB00020),
                              backgroundColor: surface,
                              side: BorderSide(color: border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(44),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ExpenseCloseButton(
                      text: 'finance.expense.close'.tr,
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

  void _showMoreMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExpenseSheetItem(
              icon: Icons.edit_outlined,
              title: 'finance.expense.edit'.tr,
              color: textPrimary,
              onTap: () {
                Get.back();
                onEdit?.call();
              },
            ),
            ExpenseSheetItem(
              icon: Icons.delete_outline_rounded,
              title: 'finance.expense.delete'.tr,
              color: const Color(0xFFB00020),
              onTap: () {
                Get.back();
                _showDeleteDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: 'finance.expense.deleteConfirmTitle'.tr,
      message: 'finance.expense.deleteConfirmMessage'.tr,
      confirmLabel: 'finance.expense.delete'.tr,
      cancelLabel: 'finance.expense.cancel'.tr,
    );
    if (!confirmed || onDeleted == null) return;
    final deleted = await onDeleted!();
    if (!context.mounted) return;
    if (deleted) {
      Navigator.pop(context, true);
    } else {
      Get.snackbar(
        'finance.expense.delete'.tr,
        _deleteErrorMessage(),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  String _deleteErrorMessage() {
    if (Get.isRegistered<ExpenseController>()) {
      return Get.find<ExpenseController>().mutationErrorMessage.value ??
          'common.error'.tr;
    }
    return 'common.error'.tr;
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

IconData _categoryIcon(String? category) {
  switch (category?.toUpperCase()) {
    case 'FOOD':
      return Icons.restaurant_outlined;
    case 'TRANSPORT':
      return Icons.directions_car_outlined;
    case 'STUDY':
      return Icons.menu_book_outlined;
    case 'BILLS':
    case 'UTILITIES':
      return Icons.bolt_outlined;
    case 'HEALTH':
      return Icons.favorite_border_rounded;
    case 'SHOPPING':
      return Icons.shopping_bag_outlined;
    case 'ENTERTAINMENT':
      return Icons.play_circle_outline_rounded;
    default:
      return Icons.receipt_long_outlined;
  }
}

Color _categoryColor(String? category) {
  switch (category?.toUpperCase()) {
    case 'FOOD':
      return AppColors.growthAccent;
    case 'TRANSPORT':
      return AppColors.brandPrimary;
    case 'STUDY':
      return AppColors.productivityAccent;
    case 'BILLS':
    case 'UTILITIES':
      return AppColors.financeAccent;
    default:
      return AppColors.financeAccent;
  }
}
