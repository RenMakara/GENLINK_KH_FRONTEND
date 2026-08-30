import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_detail_screen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  int selectedFilter = 0;

  final filters = [
    'finance.expense.all',
    'finance.expense.food',
    'finance.expense.transport',
    'finance.expense.study',
    'finance.expense.bills',
  ];

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
            // ── Header ───────────────────────────────────────────────
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
                    'finance.expense.history'.tr,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Search ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'finance.expense.searchHint'.tr,
                  hintStyle: TextStyle(color: textMuted, fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      Icons.search_rounded,
                      color: textMuted,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 1.2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Filters ──────────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = selectedFilter == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? primary : surface,
                        borderRadius: BorderRadius.circular(20),
                        border: selected ? null : Border.all(color: border),
                      ),
                      child: Text(
                        filters[index].tr,
                        style: TextStyle(
                          color: selected ? inverseText : textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                children: [
                  // ── Today ──────────────────────────────────────────
                  _DateHeader('finance.expense.todayDate'.tr, textMuted),

                  _HistoryCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'finance.expense.grabFood'.tr,
                    subtitle: '12:30 PM · ${'finance.expense.food'.tr}',
                    amount: '-\$8.50',
                    isPositive: false,
                    surface: surface,
                    secondarySurface: secondarySurface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExpenseDetailScreen(),
                        ),
                      );
                    },
                  ),

                  _HistoryCard(
                    icon: Icons.directions_bus_outlined,
                    title: 'finance.expense.busPass'.tr,
                    subtitle: '8:00 AM · ${'finance.expense.transport'.tr}',
                    amount: '-\$1.25',
                    isPositive: false,
                    surface: surface,
                    secondarySurface: secondarySurface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {},
                  ),

                  const SizedBox(height: 16),

                  // ── Yesterday ──────────────────────────────────────
                  _DateHeader('finance.expense.yesterdayDate'.tr, textMuted),

                  _HistoryCard(
                    icon: Icons.menu_book_outlined,
                    title: 'finance.expense.textbooks'.tr,
                    subtitle: 'finance.expense.study'.tr,
                    amount: '-\$45.00',
                    isPositive: false,
                    surface: surface,
                    secondarySurface: secondarySurface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {},
                  ),

                  _HistoryCard(
                    icon: Icons.lunch_dining_outlined,
                    title: 'finance.expense.lunchBox'.tr,
                    subtitle: 'finance.expense.food'.tr,
                    amount: '-\$4.20',
                    isPositive: false,
                    surface: surface,
                    secondarySurface: secondarySurface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {},
                  ),

                  const SizedBox(height: 16),

                  // ── Jun 26 ─────────────────────────────────────────
                  _DateHeader('finance.expense.jun26'.tr, textMuted),

                  _HistoryCard(
                    icon: Icons.account_balance_outlined,
                    title: 'finance.expense.abaTransfer'.tr,
                    subtitle: 'finance.expense.deposit'.tr,
                    amount: '+\$200.00',
                    isPositive: true,
                    surface: surface,
                    secondarySurface: secondarySurface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {},
                  ),

                  _HistoryCard(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'finance.expense.netflix'.tr,
                    subtitle: 'finance.expense.bills'.tr,
                    amount: '-\$15.99',
                    isPositive: false,
                    surface: surface,
                    secondarySurface: secondarySurface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DATE HEADER
// ═══════════════════════════════════════════════════════════════════════

class _DateHeader extends StatelessWidget {
  final String text;
  final Color color;

  const _DateHeader(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HISTORY CARD
// ═══════════════════════════════════════════════════════════════════════

class _HistoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isPositive;

  final Color surface;
  final Color secondarySurface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  final VoidCallback onTap;

  const _HistoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    required this.surface,
    required this.secondarySurface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: secondarySurface,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: textMuted),
              ),

              const SizedBox(width: 12),

              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                amount,
                style: TextStyle(
                  color: isPositive ? AppColors.financeAccent : textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
