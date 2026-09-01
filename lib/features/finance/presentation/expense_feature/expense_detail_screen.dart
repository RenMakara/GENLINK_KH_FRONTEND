import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_detail_widget.dart';

class ExpenseDetailScreen extends StatelessWidget {
  // EXPENSE DATA
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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // COLORS
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
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  // BACK BUTTON
                  ExpenseHeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    background: surface,
                    iconColor: textPrimary,
                    borderColor: border,
                    onTap: () => Navigator.pop(context),
                  ),

                  const SizedBox(width: 12),

                  // TITLE
                  Expanded(
                    child: Text(
                      'finance.expense.details'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),

                  // MORE BUTTON
                  ExpenseHeaderButton(
                    icon: Icons.more_horiz_rounded,
                    background: surface,
                    iconColor: textMuted,
                    borderColor: border,
                    onTap: () {
                      _showMoreMenu(context);
                    },
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                child: Column(
                  children: [
                    // SUMMARY CARD
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

                    const SizedBox(height: 16),

                    // TRANSACTION DETAILS
                    ExpenseCardContainer(
                      surface: surface,
                      border: border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CARD TITLE
                          ExpenseCardTitle(
                            title: 'finance.expense.detail'.tr,
                            textPrimary: textPrimary,
                          ),

                          const SizedBox(height: 16),

                          // DATE
                          ExpenseDetailItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'finance.expense.date'.tr,
                            value: date,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),

                          ExpenseDetailDivider(border: border),

                          // TIME
                          ExpenseDetailItem(
                            icon: Icons.access_time_rounded,
                            label: 'finance.expense.time'.tr,
                            value: time,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),

                          ExpenseDetailDivider(border: border),

                          // PAYMENT
                          ExpenseDetailItem(
                            icon: Icons.payments_outlined,
                            label: 'finance.expense.payment'.tr,
                            value: payment,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),

                          ExpenseDetailDivider(border: border),

                          // CATEGORY
                          ExpenseDetailItem(
                            icon: Icons.category_outlined,
                            label: 'finance.expense.category'.tr,
                            value: category,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),

                          // NOTE
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

                    // EDIT + DELETE
                    Row(
                      children: [
                        // EDIT
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.back();
                              },
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 17,
                                color: textPrimary,
                              ),
                              label: Text(
                                'finance.expense.edit'.tr,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: surface,
                                side: BorderSide(color: border),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // DELETE
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showDeleteDialog(context);
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Color(0xFFB00020),
                              ),
                              label: Text(
                                'finance.expense.delete'.tr,
                                style: const TextStyle(
                                  color: Color(0xFFB00020),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: surface,
                                side: BorderSide(
                                  color: const Color(
                                    0xFFB00020,
                                  ).withValues(alpha: 0.25),
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // BEAUTIFUL CLOSE BUTTON
                    ExpenseCloseButton(
                      text: 'finance.expense.close'.tr,
                      background: surface,
                      border: border,
                      textColor: textPrimary,
                      onTap: () {
                        Navigator.pop(context);
                      },
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

  // MORE MENU
  void _showMoreMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HANDLE
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 22),

            // EDIT
            ExpenseSheetItem(
              icon: Icons.edit_outlined,
              title: 'finance.expense.edit'.tr,
              color: textPrimary,
              onTap: () {
                Get.back();
              },
            ),

            const SizedBox(height: 8),

            // DELETE
            ExpenseSheetItem(
              icon: Icons.delete_outline_rounded,
              title: 'finance.expense.delete'.tr,
              color: const Color(0xFFB00020),
              onTap: () {
                Get.back();

                _showDeleteDialog(context);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // DELETE DIALOG
  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    Get.dialog(
      AlertDialog(
        backgroundColor: surface,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),

        title: Text(
          'finance.expense.deleteConfirmTitle'.tr,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),

        content: Text(
          'finance.expense.deleteConfirmMessage'.tr,
          style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
        ),

        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

        actions: [
          // CANCEL
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
            ),
          ),

          // DELETE
          ElevatedButton(
            onPressed: () {
              Get.back();

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB00020),
              foregroundColor: Colors.white,
              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'finance.expense.delete'.tr,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
