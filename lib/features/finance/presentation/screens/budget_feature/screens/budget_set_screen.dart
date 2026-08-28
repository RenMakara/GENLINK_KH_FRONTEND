import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({super.key});

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  final _totalController = TextEditingController(text: '900');
  final _foodController = TextEditingController(text: '300');
  final _transportController = TextEditingController(text: '150');
  final _studyController = TextEditingController(text: '150');
  final _billsController = TextEditingController(text: '300');

  @override
  void dispose() {
    _totalController.dispose();
    _foodController.dispose();
    _transportController.dispose();
    _studyController.dispose();
    _billsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final secondarySurface = isDark
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
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textPrimary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Set Budget',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 30),
                child: Column(
                  children: [
                    // ── Month ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'June 2026',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: textMuted,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Total Amount ──
                    Text(
                      '\$',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Text(
                      'Monthly total budget',
                      style: TextStyle(color: textMuted, fontSize: 13),
                    ),

                    const SizedBox(height: 28),

                    // ── Category Allocation ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Category Allocation',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          _AllocRow(
                            icon: Icons.restaurant_outlined,
                            title: 'Food & Drink',
                            controller: _foodController,
                            color: AppColors.growthAccent,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            secondarySurface: secondarySurface,
                            border: border,
                          ),
                          Divider(height: 1, color: border),
                          _AllocRow(
                            icon: Icons.directions_bus_outlined,
                            title: 'Transport',
                            controller: _transportController,
                            color: AppColors.brandPrimary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            secondarySurface: secondarySurface,
                            border: border,
                          ),
                          Divider(height: 1, color: border),
                          _AllocRow(
                            icon: Icons.menu_book_outlined,
                            title: 'Study',
                            controller: _studyController,
                            color: AppColors.productivityAccent,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            secondarySurface: secondarySurface,
                            border: border,
                          ),
                          Divider(height: 1, color: border),
                          _AllocRow(
                            icon: Icons.bolt_outlined,
                            title: 'Bills',
                            controller: _billsController,
                            color: AppColors.financeAccent,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            secondarySurface: secondarySurface,
                            border: border,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: inverseText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save Budget',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final TextEditingController controller;
  final Color color;
  final Color textPrimary;
  final Color textMuted;
  final Color secondarySurface;
  final Color border;

  const _AllocRow({
    required this.icon,
    required this.title,
    required this.controller,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
    required this.secondarySurface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixText: '\$',
                prefixStyle: TextStyle(
                  color: textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
