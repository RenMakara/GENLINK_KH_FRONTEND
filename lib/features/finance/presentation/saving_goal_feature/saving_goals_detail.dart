import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_update.dart';

class GoalDetailScreen extends StatefulWidget {
  final String title;
  final double savedAmount;
  final double targetAmount;
  final String targetDate;
  final double progress;
  final Color color;

  const GoalDetailScreen({
    super.key,
    required this.title,
    required this.savedAmount,
    required this.targetAmount,
    required this.targetDate,
    required this.progress,
    required this.color,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

// ============================================================
// DEPOSIT HISTORY MODEL
// ============================================================

class DepositHistory {
  final String title;
  final DateTime date;
  final double amount;

  DepositHistory({
    required this.title,
    required this.date,
    required this.amount,
  });
}

// ============================================================
// GOAL DETAIL STATE
// ============================================================

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late double savedAmount;
  late double progress;

  final TextEditingController _depositController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  // ============================================================
  // DEMO DEPOSIT HISTORY
  // ============================================================

  final List<DepositHistory> _depositHistory = [
    DepositHistory(
      title: 'Monthly Deposit',
      date: DateTime(2026, 6, 1),
      amount: 250,
    ),
    DepositHistory(
      title: 'Monthly Deposit',
      date: DateTime(2026, 5, 1),
      amount: 250,
    ),
    DepositHistory(
      title: 'Bonus Savings',
      date: DateTime(2026, 4, 15),
      amount: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();

    savedAmount = widget.savedAmount;
    progress = widget.progress;
  }

  @override
  void dispose() {
    _depositController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // FORMAT AMOUNT
  // ============================================================

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }

    return amount.toStringAsFixed(2);
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ============================================================
  // DEPOSIT DIALOG
  // ============================================================

  void _showDepositDialog() {
    _depositController.clear();
    _noteController.clear();

    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // DRAG HANDLE
                  // ==================================================
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // TITLE
                  // ==================================================
                  Text(
                    'Deposit Money',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Add money to ${widget.title}',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // CURRENT BALANCE
                  // ==================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: secondarySurface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          color: widget.color,
                          size: 20,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Current Saved',
                            style: TextStyle(color: textMuted, fontSize: 13),
                          ),
                        ),

                        Text(
                          '\$${_formatAmount(savedAmount)}',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // NOTE
                  // ==================================================
                  Text(
                    'Note',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Monthly Deposit, Bonus Savings',
                      hintStyle: TextStyle(
                        color: textMuted.withValues(alpha: 0.45),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(
                        Icons.edit_note_rounded,
                        color: widget.color,
                      ),
                      filled: true,
                      fillColor: secondarySurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: widget.color, width: 1.4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // AMOUNT
                  // ==================================================
                  Text(
                    'Deposit Amount',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _depositController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(
                        color: widget.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: textMuted.withValues(alpha: 0.45),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: secondarySurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: widget.color, width: 1.4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // BUTTONS
                  // ==================================================
                  Row(
                    children: [
                      // =================================================
                      // CANCEL
                      // =================================================
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              side: BorderSide(color: border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // =================================================
                      // DEPOSIT
                      // =================================================
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final amount = double.tryParse(
                                _depositController.text.trim(),
                              );

                              final note = _noteController.text.trim();

                              // -----------------------------------------
                              // VALIDATE AMOUNT
                              // -----------------------------------------

                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid amount.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );

                                return;
                              }

                              // -----------------------------------------
                              // VALIDATE NOTE
                              // -----------------------------------------

                              if (note.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a note.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );

                                return;
                              }

                              // -----------------------------------------
                              // UPDATE
                              // -----------------------------------------

                              setState(() {
                                savedAmount += amount;

                                progress = (savedAmount / widget.targetAmount)
                                    .clamp(0.0, 1.0);

                                // Add new history
                                _depositHistory.insert(
                                  0,
                                  DepositHistory(
                                    title: note,
                                    date: DateTime.now(),
                                    amount: amount,
                                  ),
                                );
                              });

                              // Close sheet
                              Navigator.pop(sheetContext);

                              // -----------------------------------------
                              // SUCCESS
                              // -----------------------------------------

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '\$${_formatAmount(amount)} '
                                    'added as "$note".',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: textInverse,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text(
                              'Deposit',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
        child: Column(
          children: [
            // ======================================================
            // HEADER
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
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

                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateGoalScreen(
                            title: widget.title,
                            savedAmount: savedAmount,
                            targetAmount: widget.targetAmount,
                            targetDate: widget.targetDate,
                            color: widget.color,
                          ),
                        ),
                      );

                      if (result != null) {
                        debugPrint('Updated Goal: $result');
                      }
                    },
                    icon: Icon(Icons.edit_outlined, color: textMuted, size: 22),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // ======================================================
            // CONTENT
            // ======================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                child: Column(
                  children: [
                    // =================================================
                    // CIRCULAR PROGRESS
                    // =================================================
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              backgroundColor: secondarySurface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.color,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),

                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =================================================
                    // AMOUNT
                    // =================================================
                    Text(
                      '\$${_formatAmount(savedAmount)} '
                      'of \$${_formatAmount(widget.targetAmount)} '
                      '· Target: ${widget.targetDate}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textMuted, fontSize: 13),
                    ),

                    const SizedBox(height: 8),

                    // =================================================
                    // STATUS
                    // =================================================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        progress >= 1.0 ? 'Completed' : 'On track',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // LINEAR PROGRESS
                    // =================================================
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: secondarySurface,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =================================================
                    // HISTORY TITLE
                    // =================================================
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Deposit History',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =================================================
                    // HISTORY
                    // =================================================
                    if (_depositHistory.isEmpty)
                      _EmptyHistory(
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        surface: surface,
                        border: border,
                      )
                    else
                      ..._depositHistory.map(
                        (deposit) => _DepositRow(
                          title: deposit.title,
                          subtitle: _formatDate(deposit.date),
                          amount: '+\$${_formatAmount(deposit.amount)}',
                          surface: surface,
                          border: border,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          color: widget.color,
                        ),
                      ),

                    const SizedBox(height: 28),

                    // =================================================
                    // DEPOSIT BUTTON
                    // =================================================
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _showDepositDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: textInverse,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '+ Deposit Now',
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

// ============================================================
// DEPOSIT ROW
// ============================================================

class _DepositRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color color;

  const _DepositRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // ======================================================
            // ICON
            // ======================================================
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.arrow_downward_rounded, size: 20, color: color),
            ),

            const SizedBox(width: 12),

            // ======================================================
            // TITLE + DATE
            // ======================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

            // ======================================================
            // AMOUNT
            // ======================================================
            Text(
              amount,
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

// ============================================================
// EMPTY HISTORY
// ============================================================

class _EmptyHistory extends StatelessWidget {
  final Color textPrimary;
  final Color textMuted;
  final Color surface;
  final Color border;

  const _EmptyHistory({
    required this.textPrimary,
    required this.textMuted,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 34, color: textMuted),

          const SizedBox(height: 10),

          Text(
            'No deposits yet',
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Start saving by making your first deposit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
