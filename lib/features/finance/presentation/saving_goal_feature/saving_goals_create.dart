import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/saving_goal_controller.dart';

/// Create form for a backend saving goal. When [goal] is supplied the same
/// form is used for an update, keeping the edit contract identical to create.
class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key, this.goal});

  final FinanceSavingGoalEntity? goal;

  bool get isEditing => goal != null;

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  DateTime? _targetDate;

  SavingGoalController get controller => Get.find<SavingGoalController>();

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _amountController = TextEditingController(
      text: goal == null ? '' : _amountText(goal.targetAmount),
    );
    _targetDate = goal?.targetDate == null
        ? null
        : DateTime.tryParse(goal!.targetDate!);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      // targetDate is optional and the backend does not require it to be in
      // the future, so do not impose a client-only business rule here.
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    final date = _targetDate == null ? null : _dateText(_targetDate!);
    final success = widget.isEditing
        ? await controller.updateGoal(
            existing: widget.goal!,
            title: title,
            targetAmount: amount ?? double.nan,
            targetDate: date,
          )
        : await controller.createGoal(
            title: title,
            targetAmount: amount ?? double.nan,
            targetDate: date,
          );
    if (success && mounted) {
      Get.snackbar(
        'finance.goal.title'.tr,
        (widget.isEditing
                ? 'finance.goal.updatedSuccess'
                : 'finance.goal.savedSuccess')
            .tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final controller = this.controller;
    final formCurrency =
        widget.goal?.currency ?? controller.selectedCurrency.value;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        title: Text(
          (widget.isEditing ? 'finance.goal.edit' : 'finance.goal.create').tr,
        ),
      ),
      body: Obx(() {
        final submitting = widget.isEditing
            ? controller.isUpdateSubmitting.value
            : controller.isCreateSubmitting.value;
        final error = controller.mutationErrorMessage.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          children: [
            if (error != null) ...[
              _ErrorBanner(message: error),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _titleController,
              enabled: !submitting,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'finance.goal.name'.tr,
                hintText: 'finance.goal.nameHint'.tr,
                prefixIcon: const Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              enabled: !submitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'finance.goal.targetAmount'.tr,
                prefixText: formCurrency == FinanceCurrency.usd ? r'$ ' : '៛ ',
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: !submitting,
              leading: const Icon(Icons.event_outlined),
              title: Text('finance.goal.deadline'.tr),
              subtitle: Text(
                _targetDate == null ? '—' : _dateText(_targetDate!),
                style: TextStyle(color: muted),
              ),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            Text(
              '${'finance.goal.currency'.tr}: ${formCurrency.apiValue}',
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 28),
            AppButton(
              label:
                  (widget.isEditing ? 'finance.goal.edit' : 'finance.goal.save')
                      .tr,
              loading: submitting,
              onPressed: submitting ? null : _submit,
              icon: Icons.check_rounded,
            ),
          ],
        );
      }),
    );
  }

  String _dateText(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _amountText(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
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
