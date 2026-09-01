import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class ExpenseDetailScreen extends StatelessWidget {
  // ===========================================================================
  // EXPENSE DATA
  // ===========================================================================

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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // =========================================================================
    // COLORS
    // =========================================================================

    final Color bg = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    final Color surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final Color surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final Color textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final Color textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final Color textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final Color border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Column(
          children: [
            // =================================================================
            // HEADER
            // =================================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _HeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    background: surface,
                    iconColor: textPrimary,
                    borderColor: border,
                    onTap: () => Navigator.pop(context),
                  ),

                  const SizedBox(width: 12),

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

                  _HeaderButton(
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

            // =================================================================
            // CONTENT
            // =================================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                child: Column(
                  children: [
                    // =========================================================
                    // EXPENSE SUMMARY
                    // =========================================================
                    _ExpenseSummaryCard(
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

                    // =========================================================
                    // TRANSACTION DETAILS
                    // =========================================================
                    _CardContainer(
                      surface: surface,
                      border: border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardTitle(
                            title: 'finance.expense.detail'.tr,
                            textPrimary: textPrimary,
                          ),

                          const SizedBox(height: 16),

                          _DetailItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'finance.expense.date'.tr,
                            value: date,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),

                          _DetailDivider(border: border),

                          _DetailItem(
                            icon: Icons.access_time_rounded,
                            label: 'Time',
                            value: time,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),

                          _DetailDivider(border: border),

                          _DetailItem(
                            icon: Icons.payments_outlined,
                            label: 'finance.expense.payment'.tr,
                            value: payment,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),

                          _DetailDivider(border: border),

                          _DetailItem(
                            icon: Icons.category_outlined,
                            label: 'finance.expense.category'.tr,
                            value: category,
                            surfaceSecondary: surfaceSecondary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),

                          // ===================================================
                          // NOTE
                          // ===================================================
                          if (note != null && note!.trim().isNotEmpty) ...[
                            _DetailDivider(border: border),

                            _NoteItem(
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

                    // =========================================================
                    // ACTIONS
                    // =========================================================
                    Row(
                      children: [
                        // EDIT
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Open edit expense screen
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

                    // =========================================================
                    // CLOSE
                    // =========================================================
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: textMuted,
                        ),
                        label: Text(
                          'finance.expense.close'.tr,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: surface,
                          foregroundColor: textPrimary,
                          side: BorderSide(color: border, width: 1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
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

  // ===========================================================================
  // MORE MENU
  // ===========================================================================

  void _showMoreMenu(BuildContext context) {
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
            // Handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 22),

            _BottomSheetItem(
              icon: Icons.edit_outlined,
              title: 'finance.expense.edit'.tr,
              color: textPrimary,
              onTap: () {
                Get.back();
              },
            ),

            const SizedBox(height: 8),

            _BottomSheetItem(
              icon: Icons.delete_outline_rounded,
              title: 'finance.expense.delete'.tr,
              color: const Color(0xFFB00020),
              onTap: () {
                Get.back();
                _showDeleteDialog(context);
              },
            ),

            const SizedBox(height: 8),

            _BottomSheetItem(
              icon: Icons.close_rounded,
              title: 'finance.expense.close'.tr,
              color: isDark ? const Color(0xFFB8C0CC) : const Color(0xFF5F6B7A),
              onTap: () {
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DELETE DIALOG
  // ===========================================================================

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
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
            ),
          ),

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

// =============================================================================
// EXPENSE SUMMARY CARD
// =============================================================================

class _ExpenseSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  final String title;
  final String subtitle;
  final String amount;

  final Color textPrimary;
  final Color textMuted;

  const _ExpenseSummaryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfacePrimary
            : AppColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorderSubtle
              : AppColors.lightBorderSubtle,
        ),
      ),
      child: Column(
        children: [
          // ================================================================
          // ICON
          // ================================================================
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(icon, color: iconColor, size: 29),
          ),

          const SizedBox(height: 15),

          // ================================================================
          // TITLE
          // ================================================================
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 6),

          // ================================================================
          // SUBTITLE
          // ================================================================
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // ================================================================
          // AMOUNT
          // ================================================================
          Text(
            amount,
            style: TextStyle(
              color: textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HEADER BUTTON
// =============================================================================

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ),
    );
  }
}

// =============================================================================
// CARD CONTAINER
// =============================================================================

class _CardContainer extends StatelessWidget {
  final Color surface;
  final Color border;
  final Widget child;

  const _CardContainer({
    required this.surface,
    required this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

// =============================================================================
// CARD TITLE
// =============================================================================

class _CardTitle extends StatelessWidget {
  final String title;
  final Color textPrimary;

  const _CardTitle({required this.title, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// =============================================================================
// DETAIL ITEM
// =============================================================================

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textMuted;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ICON
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: textMuted, size: 17),
        ),

        const SizedBox(width: 11),

        // LABEL
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // VALUE
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// NOTE ITEM
// =============================================================================

class _NoteItem extends StatelessWidget {
  final String note;

  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textMuted;

  const _NoteItem({
    required this.note,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.notes_outlined, color: textMuted, size: 17),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Note',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                note,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DETAIL DIVIDER
// =============================================================================

class _DetailDivider extends StatelessWidget {
  final Color border;

  const _DetailDivider({required this.border});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Divider(height: 1, thickness: 1, color: border),
    );
  }
}

// =============================================================================
// BOTTOM SHEET ITEM
// =============================================================================

class _BottomSheetItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),

            const SizedBox(width: 13),

            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
