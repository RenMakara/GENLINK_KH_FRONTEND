import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/saving_goal_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'saving_goals_update.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goal});

  final FinanceSavingGoalEntity goal;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  SavingGoalController get controller => Get.find<SavingGoalController>();

  @override
  void initState() {
    super.initState();
    controller.loadGoal(widget.goal.savingGoalId);
    controller.loadDeposits(widget.goal.savingGoalId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final goal = _effectiveGoal();
          final detailError = controller.detailErrorMessage.value;
          final loading = controller.isDetailLoading.value;
          final scopeMatches =
              goal.currency == controller.selectedCurrency.value;
          final category = _GoalCategoryInfo.fromTitle(goal.title);

          return Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        goal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Obx(
                      () => IconButton(
                        onPressed: controller.isUpdateSubmitting.value
                            ? null
                            : () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UpdateGoalScreen(
                                      goal: _effectiveGoal(),
                                    ),
                                  ),
                                );
                                await controller.loadGoal(
                                  widget.goal.savingGoalId,
                                );
                              },
                        icon: Icon(Icons.edit_outlined, color: textPrimary),
                        tooltip: 'common.edit'.tr,
                      ),
                    ),
                    Obx(
                      () => IconButton(
                        onPressed: controller.isDeleteSubmitting.value
                            ? null
                            : _delete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: theme.colorScheme.error,
                        tooltip: 'common.delete'.tr,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait<void>([
                      controller.loadGoal(widget.goal.savingGoalId),
                      controller.loadDeposits(widget.goal.savingGoalId),
                    ]);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (loading && controller.selectedGoal.value == null)
                        const SizedBox(height: 80, child: AppLoader())
                      else if (detailError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ErrorBanner(message: detailError),
                        ),

                      if (!scopeMatches)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ErrorBanner(
                            message: 'finance.goal.currencyMismatch'.tr,
                          ),
                        )
                      else ...[
                        // Goal Summary Card
                        _GoalSummaryCard(
                          goal: goal,
                          category: category,
                          surface: surface,
                          border: border,
                          text: textPrimary,
                          muted: muted,
                        ),
                        const SizedBox(height: 14),

                        // Progress Card
                        _ProgressCard(
                          goal: goal,
                          category: category,
                          surface: surface,
                          border: border,
                          text: textPrimary,
                          muted: muted,
                        ),
                        const SizedBox(height: 14),

                        // 3 Statistics Tiles Row
                        _StatisticsTilesRow(
                          goal: goal,
                          surface: surface,
                          border: border,
                          text: textPrimary,
                          muted: muted,
                        ),
                        const SizedBox(height: 22),

                        // Contribution History Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'finance.savingGoals.contributionHistory'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (controller.deposits.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${controller.deposits.length}',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Deposit History
                        _DepositHistory(
                          controller: controller,
                          savingGoalId: goal.savingGoalId,
                          surface: surface,
                          border: border,
                          text: textPrimary,
                          muted: muted,
                          currency: goal.currency,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      bottomNavigationBar: Obx(() {
        final goal = _effectiveGoal();
        final scopeMatches = goal.currency == controller.selectedCurrency.value;
        if (!scopeMatches) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: surface,
            border: Border(top: BorderSide(color: border)),
          ),
          child: AppButton(
            label: 'finance.savingGoals.addContribution'.tr,
            icon: Icons.add_rounded,
            onPressed: goal.status == 'CANCELLED' ||
                    controller.isContributionSubmitting.value
                ? null
                : () => _showContributionSheet(goal),
            loading: controller.isContributionSubmitting.value,
          ),
        );
      }),
    );
  }

  FinanceSavingGoalEntity _effectiveGoal() {
    final selected = controller.selectedGoal.value;
    return selected?.savingGoalId == widget.goal.savingGoalId
        ? selected!
        : widget.goal;
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('finance.goal.delete'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('finance.goal.deleteHint'.tr),
            const SizedBox(height: 10),
            Text(
              'finance.goal.deleteNoRefund'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('finance.goal.delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await controller.deleteGoal(widget.goal.savingGoalId);
    if (success && mounted) {
      Get.snackbar('finance.goal.title'.tr, 'finance.goal.deleteSuccess'.tr);
      Navigator.pop(context, true);
    }
  }

  Future<void> _showContributionSheet(FinanceSavingGoalEntity goal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContributionSheet(controller: controller, goal: goal),
    );
  }
}

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.goal,
    required this.category,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
  });

  final FinanceSavingGoalEntity goal;
  final _GoalCategoryInfo category;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'finance.savingGoals.defaultGoalDesc'.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.goal,
    required this.category,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
  });

  final FinanceSavingGoalEntity goal;
  final _GoalCategoryInfo category;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final progress = (goal.progressPercent / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current amount vs Target amount row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'finance.savingGoals.currentAmountLabel'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        FinanceMoneyFormatter.format(
                          goal.currentAmount,
                          goal.currency,
                        ),
                        style: TextStyle(
                          color: text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'finance.savingGoals.targetAmountLabel'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        FinanceMoneyFormatter.format(
                          goal.targetAmount,
                          goal.currency,
                        ),
                        style: TextStyle(
                          color: text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thick progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: category.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(category.color),
            ),
          ),
          const SizedBox(height: 12),

          // Percentage & Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.progressPercent}%',
                style: TextStyle(
                  color: category.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  '${FinanceMoneyFormatter.format(goal.remainingAmount, goal.currency)} ${'finance.savingGoals.remaining'.tr.toLowerCase()}',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticsTilesRow extends StatelessWidget {
  const _StatisticsTilesRow({
    required this.goal,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
  });

  final FinanceSavingGoalEntity goal;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Tile 1: Deadline
        Expanded(
          child: _StatTile(
            icon: Icons.calendar_today_rounded,
            iconColor: const Color(0xFF3B82F6),
            label: 'finance.savingGoals.deadline'.tr,
            value: _formatDate(goal.targetDate),
            surface: surface,
            border: border,
            text: text,
            muted: muted,
          ),
        ),
        const SizedBox(width: 8),

        // Tile 2: Remaining
        Expanded(
          child: _StatTile(
            icon: Icons.track_changes_rounded,
            iconColor: const Color(0xFFF59E0B),
            label: 'finance.savingGoals.remaining'.tr,
            value: FinanceMoneyFormatter.format(
              goal.remainingAmount,
              goal.currency,
            ),
            surface: surface,
            border: border,
            text: text,
            muted: muted,
          ),
        ),
        const SizedBox(width: 8),

        // Tile 3: Status
        Expanded(
          child: _StatTile(
            icon: Icons.trending_up_rounded,
            iconColor: goal.status == 'COMPLETED'
                ? const Color(0xFF10B981)
                : const Color(0xFF6366F1),
            label: 'finance.savingGoals.status'.tr,
            value: _statusLabel(goal.status),
            surface: surface,
            border: border,
            text: text,
            muted: muted,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return 'finance.savingGoals.noDeadline'.tr;
    }
    try {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
      }
    } catch (_) {}
    return rawDate;
  }

  String _statusLabel(String raw) {
    switch (raw) {
      case 'IN_PROGRESS':
        return 'finance.goal.inProgress'.tr;
      case 'COMPLETED':
        return 'finance.goal.completed'.tr;
      case 'CANCELLED':
        return 'finance.goal.cancelled'.tr;
      default:
        return raw;
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepositHistory extends StatelessWidget {
  const _DepositHistory({
    required this.controller,
    required this.savingGoalId,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.currency,
  });

  final SavingGoalController controller;
  final String savingGoalId;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final FinanceCurrency currency;

  @override
  Widget build(BuildContext context) {
    if (controller.isDepositsLoading.value && controller.deposits.isEmpty) {
      return const SizedBox(height: 90, child: AppLoader());
    }
    final error = controller.depositsErrorMessage.value;
    if (error != null && controller.deposits.isEmpty) {
      return AppEmptyState(
        message: error,
        icon: Icons.cloud_off_outlined,
        action: AppButton.secondary(
          label: 'common.retry'.tr,
          expanded: false,
          onPressed: () => controller.loadDeposits(savingGoalId),
        ),
      );
    }
    if (controller.deposits.isEmpty) {
      return AppEmptyState(
        message: 'finance.goal.noDeposits'.tr,
        icon: Icons.history,
      );
    }
    return Column(
      children: controller.deposits
          .map(
            (deposit) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deposit.note?.isNotEmpty == true
                              ? deposit.note!
                              : 'finance.goal.contribute'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(deposit.depositDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${FinanceMoneyFormatter.format(deposit.amount, currency)}',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDate(String rawDate) {
    try {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
      }
    } catch (_) {}
    return rawDate;
  }
}

class _ContributionSheet extends StatefulWidget {
  const _ContributionSheet({required this.controller, required this.goal});

  final SavingGoalController controller;
  final FinanceSavingGoalEntity goal;

  @override
  State<_ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends State<_ContributionSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  var _fromWallet = false;

  SavingGoalController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Obx(() {
            final submitting = controller.isContributionSubmitting.value;
            final error = controller.mutationErrorMessage.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'finance.goal.contribute'.tr,
                  style: TextStyle(
                    color: text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  enabled: !submitting,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'finance.goal.depositAmount'.tr,
                    prefixText: widget.goal.currency == FinanceCurrency.usd
                        ? r'$ '
                        : '៛ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  enabled: !submitting,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: 'finance.goal.depositNote'.tr,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _fromWallet,
                  onChanged: submitting
                      ? null
                      : (value) => setState(() => _fromWallet = value),
                  title: Text('finance.goal.fromWallet'.tr),
                  subtitle: Text('finance.goal.fromWalletHint'.tr),
                ),
                if (error != null) ...[
                  _ErrorBanner(message: error),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'common.cancel'.tr,
                        onPressed: submitting
                            ? null
                            : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'finance.goal.contribute'.tr,
                        loading: submitting,
                        onPressed: submitting
                            ? null
                            : () async {
                                final amount = double.tryParse(
                                  _amountController.text
                                      .replaceAll(',', '')
                                      .trim(),
                                );
                                final success = await controller.contribute(
                                  goal: widget.goal,
                                  amount: amount ?? double.nan,
                                  note: _noteController.text,
                                  fromWallet: _fromWallet,
                                );
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}

class _GoalCategoryInfo {
  final IconData icon;
  final Color color;

  const _GoalCategoryInfo(this.icon, this.color);

  static _GoalCategoryInfo fromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('laptop') ||
        lower.contains('macbook') ||
        lower.contains('computer') ||
        lower.contains('phone')) {
      return const _GoalCategoryInfo(
        Icons.laptop_mac_rounded,
        Color(0xFF2563EB),
      );
    }
    if (lower.contains('car') ||
        lower.contains('vehicle') ||
        lower.contains('bike') ||
        lower.contains('moto')) {
      return const _GoalCategoryInfo(
        Icons.directions_car_rounded,
        Color(0xFFEF4444),
      );
    }
    if (lower.contains('travel') ||
        lower.contains('trip') ||
        lower.contains('japan') ||
        lower.contains('flight') ||
        lower.contains('vacation')) {
      return const _GoalCategoryInfo(
        Icons.flight_rounded,
        Color(0xFF8B5CF6),
      );
    }
    if (lower.contains('emergency') ||
        lower.contains('fund') ||
        lower.contains('health') ||
        lower.contains('shield')) {
      return const _GoalCategoryInfo(
        Icons.shield_outlined,
        Color(0xFF10B981),
      );
    }
    return const _GoalCategoryInfo(
      Icons.savings_outlined,
      Color(0xFFF59E0B),
    );
  }
}
