import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../levelup/widget/grow_section_widget.dart';
import '../../domain/entities/productivity_entities.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import '../widgets/creation_form_components.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key, this.initialHabit});

  final ProductivityHabit? initialHabit;

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _titleController = TextEditingController();
  ProductivityController? _controller;
  String _category = 'PERSONAL';
  String? _frequency = 'DAILY';
  TimeOfDay? _reminderTime;
  bool _saving = false;

  static const _categories = [
    'PERSONAL',
    'HEALTH',
    'LEARNING',
    'WORK',
    'OTHER',
  ];
  // Custom scheduling stays hidden until the API has fields to configure it.
  static const _frequencies = ['DAILY', 'WEEKLY'];

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
    final habit = widget.initialHabit;
    if (habit != null) {
      _titleController.text = habit.title;
      _category = habit.category ?? _category;
      final frequency = habit.frequency?.toUpperCase();
      if (frequency == null || frequency.isEmpty || frequency == 'DAILY') {
        _frequency = 'DAILY';
      } else if (frequency == 'WEEKLY') {
        _frequency = 'WEEKLY';
      } else {
        _frequency = null;
      }
      final time = habit.reminderTime?.split(':');
      if (time != null && time.length >= 2) {
        final hour = int.tryParse(time[0]);
        final minute = int.tryParse(time[1]);
        if (hour != null &&
            minute != null &&
            hour >= 0 &&
            hour < 24 &&
            minute >= 0 &&
            minute < 60) {
          _reminderTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('habits.create.validationTitle'.tr);
      return;
    }
    if (_frequency == null) {
      _showMessage('habits.customUnavailable'.tr);
      return;
    }

    final controller = _controller;
    if (controller == null) {
      Get.back(result: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final initialHabit = widget.initialHabit;
      if (initialHabit == null) {
        await controller.createHabit(
          title: title,
          category: _category,
          frequency: _frequency,
          reminderTime: _formatTime(_reminderTime),
        );
      } else {
        await controller.updateHabit(
          habitId: initialHabit.habitId,
          title: title,
          category: _category,
          frequency: _frequency,
          reminderTime: _formatTime(_reminderTime),
        );
      }
      if (mounted) Get.back(result: true);
    } catch (error) {
      _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _categoryLabel(String item) {
    switch (item.toUpperCase()) {
      case 'PERSONAL':
        return 'habits.create.category.personal'.tr;
      case 'HEALTH':
        return 'habits.create.category.health'.tr;
      case 'LEARNING':
        return 'habits.create.category.learning'.tr;
      case 'WORK':
        return 'habits.create.category.work'.tr;
      case 'OTHER':
        return 'habits.create.category.other'.tr;
      default:
        return item;
    }
  }

  Widget _categoryIcon(String category, bool isSelected) {
    Color iconColor;
    Color bgColor;
    IconData iconData;

    switch (category.toUpperCase()) {
      case 'PERSONAL':
        iconColor = const Color(0xFF9333EA);
        bgColor = const Color(0xFFF3E8FF);
        iconData = Icons.person_rounded;
        break;
      case 'HEALTH':
        iconColor = const Color(0xFFE11D48);
        bgColor = const Color(0xFFFFE4E6);
        iconData = Icons.favorite_rounded;
        break;
      case 'LEARNING':
        iconColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFEF3C7);
        iconData = Icons.school_rounded;
        break;
      case 'WORK':
        iconColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFEFF6FF);
        iconData = Icons.work_rounded;
        break;
      case 'OTHER':
      default:
        iconColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        iconData = Icons.category_rounded;
        break;
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(iconData, color: iconColor, size: 19),
    );
  }

  String _frequencyLabel(String frequency) {
    switch (frequency) {
      case 'DAILY':
        return 'habits.create.frequency.daily'.tr;
      case 'WEEKLY':
        return 'habits.create.frequency.weekly'.tr;
      case 'CUSTOM':
      default:
        return 'habits.create.frequency.custom'.tr;
    }
  }

  Widget _frequencyIcon(String frequency, bool isSelected) {
    final color = isSelected
        ? const Color(0xFFEA580C)
        : const Color(0xFFF97316);
    switch (frequency) {
      case 'DAILY':
        return Icon(
          isSelected ? Icons.check_circle_rounded : Icons.today_rounded,
          color: color,
          size: 24,
        );
      case 'WEEKLY':
        return Icon(Icons.calendar_view_week_rounded, color: color, size: 24);
      case 'CUSTOM':
      default:
        return Icon(Icons.tune_rounded, color: color, size: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreationFormScaffold(
      header: CreationFormHeader(
        title:
            (widget.initialHabit == null
                    ? 'habits.create.title'
                    : 'habits.editTitle')
                .tr,
        subtitle: 'habits.create.subtitle'.tr,
        onSave: _save,
        isSaving: _saving,
      ),
      bottomBar: CreationPrimaryButton(
        label:
            (widget.initialHabit == null
                    ? 'habits.create.saveHabit'
                    : 'common.save')
                .tr,
        onPressed: _save,
        isLoading: _saving,
      ),
      children: [
        // Hero Card (Orange gradient with 3D Habits Icon)
        CreationHeroCard(
          illustration: const Soft3DHabitsIcon(size: 46),
          quote: 'habits.create.heroQuote'.tr,
          gradientColors: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          quoteColor: const Color(0xFFC2410C),
          sparkleColor: const Color(0xFFF97316),
        ),

        // Habit Name Field
        CreationTextField(
          controller: _titleController,
          label: 'habits.create.nameLabel'.tr,
          isRequired: true,
          hintText: 'habits.create.titleHint'.tr,
          autofocus: true,
          textInputAction: TextInputAction.done,
          accentColor: const Color(0xFFF97316),
          onSubmitted: (_) => _saving ? null : _save(),
          leadingIcon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFFF97316),
              size: 21,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Category Dropdown Card
        CreationDropdownCard(
          label: 'habits.create.category'.tr,
          sheetTitle: 'habits.create.selectCategory'.tr,
          value: _category,
          values: _categories,
          accentColor: const Color(0xFFF97316),
          leadingIcon: _categoryIcon(_category, false),
          itemLabelBuilder: _categoryLabel,
          itemIconBuilder: (item, isSelected) =>
              _categoryIcon(item, isSelected),
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Frequency Segmented Selection
        CreationSectionLabel(label: 'habits.create.frequency'.tr),
        Row(
          children: _frequencies
              .map((frequency) {
                final isSelected = _frequency == frequency;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SelectionOptionCard(
                      label: _frequencyLabel(frequency),
                      isSelected: isSelected,
                      accentColor: const Color(0xFFF97316),
                      icon: _frequencyIcon(frequency, isSelected),
                      onTap: () => setState(() => _frequency = frequency),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        if (_frequency == null) ...[
          const SizedBox(height: 8),
          Text(
            'habits.customUnavailable'.tr,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),

        // Reminder Picker Card
        CreationPickerCard(
          leadingIcon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFFF97316),
              size: 20,
            ),
          ),
          title: 'habits.create.reminderOptional'.tr,
          subtitle: _reminderTime == null
              ? 'habits.create.noReminder'.tr
              : _reminderTime!.format(context),
          onTap: _pickReminderTime,
          showTrailingArrow: true,
          onClear: _reminderTime != null
              ? () => setState(() => _reminderTime = null)
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Motivation Card
        CreationMotivationCard(
          title: 'habits.create.motivationTitle'.tr,
          subtitle: 'habits.create.motivationSubtitle'.tr,
          isGreen: false,
        ),
      ],
    );
  }
}

String? _formatTime(TimeOfDay? time) {
  if (time == null) return null;
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

String _errorText(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
