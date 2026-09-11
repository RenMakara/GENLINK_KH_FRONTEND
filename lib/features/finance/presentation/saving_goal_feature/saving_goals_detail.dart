import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
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
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    AppBackButton(),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        goal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
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
                        icon: Icon(Icons.edit_outlined, color: text),
                      ),
                    ),

                    Obx(
                      () => IconButton(
                        onPressed: controller.isDeleteSubmitting.value
                            ? null
                            : _delete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),

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
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 34),
                    children: [
                      if (loading && controller.selectedGoal.value == null)
                        const SizedBox(height: 80, child: AppLoader())
                      else if (detailError != null)
                        _ErrorBanner(message: detailError),

                      if (!scopeMatches)
                        _ErrorBanner(
                          message: 'finance.goal.currencyMismatch'.tr,
                        )
                      else ...[
                        _ProgressCard(
                          goal: goal,
                          surface: surface,
                          border: border,
                          text: text,
                          muted: muted,
                          primary: primary,
                        ),

                        const SizedBox(height: 14),

                        AppButton(
                          label: 'finance.goal.contribute'.tr,
                          icon: Icons.add_rounded,
                          onPressed:
                              goal.status == 'CANCELLED' ||
                                  controller.isContributionSubmitting.value
                              ? null
                              : () => _showContributionSheet(goal),
                          loading: controller.isContributionSubmitting.value,
                        ),
                      ],

                      const SizedBox(height: 24),

                      Text(
                        'finance.goal.depositHistory'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (scopeMatches)
                        _DepositHistory(
                          controller: controller,
                          savingGoalId: goal.savingGoalId,
                          surface: surface,
                          border: border,
                          text: text,
                          muted: muted,
                          currency: goal.currency,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
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
      builder: (_) => _ContributionSheet(controller: controller, goal: goal),
    );
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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Obx(() {
          final submitting = controller.isContributionSubmitting.value;
          final error = controller.mutationErrorMessage.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'finance.goal.contribute'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 10),
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
                  const SizedBox(width: 10),
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
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.goal,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
  });

  final FinanceSavingGoalEntity goal;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: TextStyle(
                    color: text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${goal.progressPercent}%',
                style: TextStyle(color: primary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: primary.withValues(alpha: 0.12),
              color: primary,
            ),
          ),
          const SizedBox(height: 14),
          _AmountLine(
            label: 'finance.goal.current'.tr,
            amount: goal.currentAmount,
            goal: goal,
            text: text,
            muted: muted,
          ),
          _AmountLine(
            label: 'finance.goal.targetAmount'.tr,
            amount: goal.targetAmount,
            goal: goal,
            text: text,
            muted: muted,
          ),
          _AmountLine(
            label: 'finance.goal.remaining'.tr,
            amount: goal.remainingAmount,
            goal: goal,
            text: text,
            muted: muted,
          ),
          if (goal.targetDate != null)
            _AmountLine(
              label: 'finance.goal.deadline'.tr,
              value: goal.targetDate!,
              text: text,
              muted: muted,
            ),
          _AmountLine(
            label: 'finance.goal.status'.tr,
            value: _statusLabel(goal.status),
            text: text,
            muted: muted,
          ),
          _AmountLine(
            label: 'finance.goal.currency'.tr,
            value: goal.currency.apiValue,
            text: text,
            muted: muted,
          ),
        ],
      ),
    );
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

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.text,
    required this.muted,
    this.amount,
    this.goal,
    this.value,
  });

  final String label;
  final double? amount;
  final FinanceSavingGoalEntity? goal;
  final String? value;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: muted)),
          ),
          Text(
            value ?? FinanceMoneyFormatter.format(amount ?? 0, goal!.currency),
            style: TextStyle(color: text, fontWeight: FontWeight.w700),
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
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_downward_rounded, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deposit.note?.isNotEmpty == true
                              ? deposit.note!
                              : 'finance.goal.contribute'.tr,
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          deposit.depositDate,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    FinanceMoneyFormatter.format(deposit.amount, currency),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
