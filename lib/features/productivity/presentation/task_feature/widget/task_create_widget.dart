import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';

// PRIORITY
enum TaskPriorityOption { high, medium, low }

// CATEGORY
enum TaskCategoryOption { study, work, personal, health, other }

// SUBTASK DATA
class CreateSubtaskData {
  final String title;
  final bool completed;

  const CreateSubtaskData({required this.title, this.completed = false});

  CreateSubtaskData copyWith({String? title, bool? completed}) {
    return CreateSubtaskData(
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

// COLORS
class CreateTaskColors {
  final bool isDark;

  const CreateTaskColors(this.isDark);

  Color get background =>
      isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

  Color get surfaceSecondary =>
      isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

  Color get borderStrong =>
      isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;

  Color get primary => isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

  Color get primarySoft =>
      isDark ? AppColors.darkPrimarySoft : AppColors.lightPrimarySoft;

  Color get inverse =>
      isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse;
}

// CREATE TASK LAYOUT
class CreateTaskLayout extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  final TaskPriorityOption priority;
  final TaskCategoryOption category;

  final DateTime? dueDate;
  final TimeOfDay? reminderTime;

  final List<CreateSubtaskData> subtasks;

  final VoidCallback onBack;

  final ValueChanged<TaskPriorityOption> onPriorityChanged;
  final ValueChanged<TaskCategoryOption> onCategoryChanged;

  final VoidCallback onDueDateTap;
  final VoidCallback onReminderTap;

  final ValueChanged<String> onSubtaskAdded;

  final void Function(int index, bool completed) onSubtaskChanged;

  final ValueChanged<int> onSubtaskDeleted;

  final VoidCallback onSave;

  const CreateTaskLayout({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priority,
    required this.category,
    required this.dueDate,
    required this.reminderTime,
    required this.subtasks,
    required this.onBack,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
    required this.onDueDateTap,
    required this.onReminderTap,
    required this.onSubtaskAdded,
    required this.onSubtaskChanged,
    required this.onSubtaskDeleted,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            CreateTaskTopBar(title: 'task.create.title'.tr, onBack: onBack),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    _SectionLabel(
                      text: 'task.create.taskTitle'.tr,
                      colors: colors,
                    ),

                    const SizedBox(height: 8),

                    CreateTaskTitleField(
                      controller: titleController,
                      hintText: 'task.create.taskTitleHint'.tr,
                    ),

                    const SizedBox(height: 18),

                    // DESCRIPTION
                    _SectionLabel(
                      text: 'task.create.description'.tr,
                      colors: colors,
                    ),

                    const SizedBox(height: 8),

                    CreateTaskDescriptionField(
                      controller: descriptionController,
                      hintText: 'task.create.descriptionHint'.tr,
                    ),

                    const SizedBox(height: 20),

                    // PRIORITY
                    _SectionLabel(
                      text: 'task.create.priority'.tr,
                      colors: colors,
                    ),

                    const SizedBox(height: 9),

                    CreatePrioritySelector(
                      selected: priority,
                      highText: 'task.create.priority.high'.tr,
                      mediumText: 'task.create.priority.medium'.tr,
                      lowText: 'task.create.priority.low'.tr,
                      onChanged: onPriorityChanged,
                    ),

                    const SizedBox(height: 20),

                    // CATEGORY
                    _SectionLabel(
                      text: 'task.create.category'.tr,
                      colors: colors,
                    ),

                    const SizedBox(height: 9),

                    CreateCategorySelector(
                      selected: category,
                      studyText: 'task.create.category.study'.tr,
                      workText: 'task.create.category.work'.tr,
                      personalText: 'task.create.category.personal'.tr,
                      healthText: 'task.create.category.health'.tr,
                      otherText: 'task.create.category.other'.tr,
                      onChanged: onCategoryChanged,
                    ),

                    const SizedBox(height: 20),

                    // DUE DATE
                    _SectionLabel(
                      text: 'task.create.dueDate'.tr,
                      colors: colors,
                    ),

                    const SizedBox(height: 9),

                    CreateTaskPickerField(
                      text: dueDate == null
                          ? 'task.create.selectDate'.tr
                          : _formatDate(dueDate!),
                      icon: Icons.calendar_month_rounded,
                      onTap: onDueDateTap,
                    ),

                    const SizedBox(height: 18),

                    // REMINDER
                    _SectionLabel(
                      text: 'task.create.reminder'.tr,
                      colors: colors,
                    ),

                    const SizedBox(height: 9),

                    CreateTaskPickerField(
                      text: reminderTime == null
                          ? 'task.create.setReminder'.tr
                          : reminderTime!.format(context),
                      icon: Icons.notifications_none_rounded,
                      onTap: onReminderTap,
                    ),

                    const SizedBox(height: 20),

                    // SUBTASKS
                    _SectionLabel(
                      text: 'task.create.subtasks'.tr,
                      colors: colors,
                    ),

                    const SizedBox(height: 9),

                    CreateSubtaskList(
                      subtasks: subtasks,
                      addHint: 'task.create.addSubtask'.tr,
                      onAdded: onSubtaskAdded,
                      onChanged: onSubtaskChanged,
                      onDeleted: onSubtaskDeleted,
                    ),

                    const SizedBox(height: 24),

                    // SAVE
                    CreateTaskSaveButton(
                      text: 'task.create.save'.tr,
                      onTap: onSave,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// TOP BAR
class CreateTaskTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const CreateTaskTopBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 19,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SECTION LABEL
class _SectionLabel extends StatelessWidget {
  final String text;
  final CreateTaskColors colors;

  const _SectionLabel({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .15,
      ),
    );
  }
}

// TITLE FIELD
class CreateTaskTitleField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const CreateTaskTitleField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return TextField(
      controller: controller,
      maxLines: 1,
      textInputAction: TextInputAction.next,
      cursorColor: colors.textPrimary,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),

        // Clean icon - NO background
        prefixIcon: Icon(
          Icons.title_rounded,
          size: 19,
          color: colors.textMuted,
        ),

        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 50,
        ),

        filled: true,
        fillColor: colors.surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.border),
        ),

        // Focus stays monochrome
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.borderStrong, width: 1.2),
        ),
      ),
    );
  }
}

// DESCRIPTION FIELD
class CreateTaskDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const CreateTaskDescriptionField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      cursorColor: colors.textPrimary,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),

        filled: true,
        fillColor: colors.surface,

        contentPadding: const EdgeInsets.all(14),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.borderStrong, width: 1.4),
        ),
      ),
    );
  }
}

// PRIORITY SELECTOR
class CreatePrioritySelector extends StatelessWidget {
  final TaskPriorityOption selected;

  final String highText;
  final String mediumText;
  final String lowText;

  final ValueChanged<TaskPriorityOption> onChanged;

  const CreatePrioritySelector({
    super.key,
    required this.selected,
    required this.highText,
    required this.mediumText,
    required this.lowText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PriorityOption(
            label: highText,
            color: AppColors.danger,
            selected: selected == TaskPriorityOption.high,
            onTap: () => onChanged(TaskPriorityOption.high),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _PriorityOption(
            label: mediumText,
            color: AppColors.warning,
            selected: selected == TaskPriorityOption.medium,
            onTap: () => onChanged(TaskPriorityOption.medium),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _PriorityOption(
            label: lowText,
            color: AppColors.success,
            selected: selected == TaskPriorityOption.low,
            onTap: () => onChanged(TaskPriorityOption.low),
          ),
        ),
      ],
    );
  }
}

// PRIORITY OPTION
class _PriorityOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOut,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? colors.textPrimary : colors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? color : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),

              const SizedBox(height: 6),

              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected ? colors.inverse : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CATEGORY SELECTOR
class CreateCategorySelector extends StatelessWidget {
  final TaskCategoryOption selected;

  final String studyText;
  final String workText;
  final String personalText;
  final String healthText;
  final String otherText;

  final ValueChanged<TaskCategoryOption> onChanged;

  const CreateCategorySelector({
    super.key,
    required this.selected,
    required this.studyText,
    required this.workText,
    required this.personalText,
    required this.healthText,
    required this.otherText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = <_CategoryItem>[
      _CategoryItem(type: TaskCategoryOption.study, label: studyText),
      _CategoryItem(type: TaskCategoryOption.work, label: workText),
      _CategoryItem(type: TaskCategoryOption.personal, label: personalText),
      _CategoryItem(type: TaskCategoryOption.health, label: healthText),
      _CategoryItem(type: TaskCategoryOption.other, label: otherText),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        // Nice mobile scrolling
        physics: const BouncingScrollPhysics(),

        // Prevent unwanted extra padding
        padding: EdgeInsets.zero,

        itemCount: categories.length,

        separatorBuilder: (_, _) {
          return const SizedBox(width: 8);
        },

        itemBuilder: (context, index) {
          final item = categories[index];

          return _CategoryChip(
            label: item.label,
            selected: selected == item.type,
            onTap: () {
              onChanged(item.type);
            },
          );
        },
      ),
    );
  }
}

// CATEGORY ITEM
class _CategoryItem {
  final TaskCategoryOption type;
  final String label;

  const _CategoryItem({required this.type, required this.label});
}

// CATEGORY CHIP
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,

          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),

          decoration: BoxDecoration(
            // Selected:
            // Light -> Black
            // Dark  -> White
            color: selected ? colors.textPrimary : colors.surfaceSecondary,

            borderRadius: BorderRadius.circular(24),

            border: Border.all(
              color: selected ? colors.textPrimary : colors.border,
            ),
          ),

          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // Selected:
                // Light -> White
                // Dark  -> Black
                color: selected ? colors.inverse : colors.textSecondary,

                fontSize: 11,

                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// PICKER FIELD
class CreateTaskPickerField extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const CreateTaskPickerField({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: colors.textSecondary),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// SUBTASK LIST
class CreateSubtaskList extends StatelessWidget {
  final List<CreateSubtaskData> subtasks;

  final String addHint;

  final ValueChanged<String> onAdded;

  final void Function(int index, bool completed) onChanged;

  final ValueChanged<int> onDeleted;

  const CreateSubtaskList({
    super.key,
    required this.subtasks,
    required this.addHint,
    required this.onAdded,
    required this.onChanged,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < subtasks.length; i++) ...[
            _SubtaskItem(
              subtask: subtasks[i],
              onChanged: (completed) {
                onChanged(i, completed);
              },
              onDelete: () {
                onDeleted(i);
              },
            ),

            if (i != subtasks.length - 1)
              Divider(height: 1, thickness: 1, color: colors.border),
          ],

          if (subtasks.isNotEmpty)
            Divider(height: 1, thickness: 1, color: colors.border),

          _AddSubtaskField(hintText: addHint, onAdded: onAdded),
        ],
      ),
    );
  }
}

// SUBTASK ITEM
class _SubtaskItem extends StatelessWidget {
  final CreateSubtaskData subtask;

  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  const _SubtaskItem({
    required this.subtask,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              onChanged(!subtask.completed);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: subtask.completed
                    ? colors.textPrimary
                    : Colors.transparent,
                border: Border.all(
                  color: subtask.completed
                      ? colors.textPrimary
                      : colors.textMuted,
                  width: 1.2,
                ),
              ),
              child: subtask.completed
                  ? Icon(Icons.check_rounded, size: 13, color: colors.inverse)
                  : null,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                color: subtask.completed
                    ? colors.textMuted
                    : colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                decoration: subtask.completed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ADD SUBTASK FIELD
class _AddSubtaskField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onAdded;

  const _AddSubtaskField({required this.hintText, required this.onAdded});

  @override
  State<_AddSubtaskField> createState() => _AddSubtaskFieldState();
}

class _AddSubtaskFieldState extends State<_AddSubtaskField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;

    if (_hasText == hasText) return;

    setState(() {
      _hasText = hasText;
    });
  }

  // CREATE SUBTASK
  void _submit() {
    final value = _controller.text.trim();

    // Nothing typed
    if (value.isEmpty) {
      _focusNode.requestFocus();
      return;
    }

    // SEND TO PARENT
    widget.onAdded(value);

    // CLEAR CURRENT INPUT
    _controller.clear();

    // KEEP INPUT FOCUSED
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          // PLUS ICON - SAME STYLE
          Icon(Icons.add_rounded, size: 18, color: colors.textMuted),

          const SizedBox(width: 10),

          // TEXT FIELD
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,

              // Don't use keyboard Enter to create
              textInputAction: TextInputAction.none,

              maxLines: 1,

              cursorColor: colors.textPrimary,

              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),

              decoration: InputDecoration(
                hintText: widget.hintText,

                hintStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),

                filled: false,
                fillColor: Colors.transparent,

                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,

                isDense: true,

                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // CREATE SUBTASK BUTTON
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _submit,
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 34,
                height: 34,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _hasText ? 1.0 : 0.35,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 17,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SAVE BUTTON
class CreateTaskSaveButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CreateTaskSaveButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CreateTaskColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,

          // Light = black
          // Dark  = white
          backgroundColor: colors.textPrimary,

          // Light = white
          // Dark  = black
          foregroundColor: colors.inverse,

          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 18, color: colors.inverse),

            const SizedBox(width: 7),

            Text(
              text,
              style: TextStyle(
                color: colors.inverse,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
