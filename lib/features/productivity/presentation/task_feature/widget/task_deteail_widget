import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/widget/task_home_widget.dart';

// ============================================================
// TASK DETAIL SUBTASK DATA
// ============================================================

class TaskDetailSubtaskData {
  final String title;
  final bool completed;

  const TaskDetailSubtaskData({
    required this.title,
    this.completed = false,
  });

  TaskDetailSubtaskData copyWith({
    String? title,
    bool? completed,
  }) {
    return TaskDetailSubtaskData(
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

// ============================================================
// COLORS
// Same design language as CreateTaskColors
// ============================================================

class TaskDetailColors {
  final bool isDark;

  const TaskDetailColors(this.isDark);

  Color get background =>
      isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

  Color get surfaceSecondary =>
      isDark
          ? AppColors.darkSurfaceSecondary
          : AppColors.lightSurfaceSecondary;

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

  Color get primary =>
      isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

  Color get primarySoft =>
      isDark ? AppColors.darkPrimarySoft : AppColors.lightPrimarySoft;

  Color get inverse =>
      isDark ? AppColors.darkTextInverse : AppColors.lightTextInverse;
}

// ============================================================
// TASK DETAIL LAYOUT
// ============================================================

class TaskDetailLayout extends StatelessWidget {
  final TaskData task;

  final String title;

  final String description;

  final String reminderText;

  final bool completed;

  final List<TaskDetailSubtaskData> subtasks;

  final VoidCallback onBack;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  final VoidCallback onCompletedChanged;

  final ValueChanged<String> onSubtaskAdded;

  final ValueChanged<int> onSubtaskChanged;

  final ValueChanged<int> onSubtaskDeleted;

  const TaskDetailLayout({
    super.key,
    required this.task,
    required this.title,
    required this.description,
    required this.reminderText,
    required this.completed,
    required this.subtasks,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    required this.onCompletedChanged,
    required this.onSubtaskAdded,
    required this.onSubtaskChanged,
    required this.onSubtaskDeleted,
  });

  // ============================================================
  // COMPLETED SUBTASKS
  // ============================================================

  int get completedSubtasks {
    return subtasks.where((item) => item.completed).length;
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  double get progress {
    if (subtasks.isEmpty) return 0;

    return completedSubtasks / subtasks.length;
  }

  // ============================================================
  // PRIORITY COLOR
  // ============================================================

  Color priorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return AppColors.danger;

      case TaskPriority.medium:
        return AppColors.warning;

      case TaskPriority.low:
        return AppColors.success;
    }
  }

  // ============================================================
  // PRIORITY TEXT
  // ============================================================

  String priorityText() {
    switch (task.priority) {
      case TaskPriority.high:
        return 'tasks.priority.high'.tr;

      case TaskPriority.medium:
        return 'tasks.priority.medium'.tr;

      case TaskPriority.low:
        return 'tasks.priority.low'.tr;
    }
  }

  // ============================================================
  // PRIORITY ICON
  // ============================================================

  IconData priorityIcon() {
    switch (task.priority) {
      case TaskPriority.high:
        return Icons.keyboard_double_arrow_up_rounded;

      case TaskPriority.medium:
        return Icons.remove_rounded;

      case TaskPriority.low:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Scaffold(
      backgroundColor: colors.background,

      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // TOP BAR
            // ======================================================

            TaskDetailTopBar(
              title: 'task.detail.title'.tr,
              onBack: onBack,
              onEdit: onEdit,
              onDelete: onDelete,
            ),

            // ======================================================
            // CONTENT
            // ======================================================

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  32,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TASK TITLE / STATUS
                    // ==================================================

                    TaskDetailHeroCard(
                      title: title,
                      completed: completed,
                      priorityText: priorityText(),
                      priorityColor: priorityColor(),
                      priorityIcon: priorityIcon(),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // TASK INFORMATION
                    // ==================================================

                    TaskDetailSectionLabel(
                      text: 'task.detail.taskInformation'.tr,
                    ),

                    const SizedBox(height: 9),

                    TaskDetailInfoCard(
                      dueText: task.dueText,
                      reminderText: reminderText,
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================

                    TaskDetailSectionLabel(
                      text: 'task.create.description'.tr,
                    ),

                    const SizedBox(height: 9),

                    TaskDetailDescriptionCard(
                      description: description,
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // SUBTASKS
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: TaskDetailSectionLabel(
                            text: 'task.create.subtasks'.tr,
                          ),
                        ),

                        TaskDetailCounter(
                          completed: completedSubtasks,
                          total: subtasks.length,
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    // ==================================================
                    // PROGRESS
                    // ==================================================

                    TaskDetailProgressCard(
                      progress: progress,
                      completed: completedSubtasks,
                      total: subtasks.length,
                    ),

                    const SizedBox(height: 9),

                    // ==================================================
                    // SUBTASK LIST
                    // ==================================================

                    TaskDetailSubtaskList(
                      subtasks: subtasks,
                      onChanged: onSubtaskChanged,
                      onDeleted: onSubtaskDeleted,
                    ),

                    const SizedBox(height: 9),

                    // ==================================================
                    // ADD SUBTASK
                    // ==================================================

                    TaskDetailAddSubtaskField(
                      hintText: 'task.create.addSubtask'.tr,
                      onAdded: onSubtaskAdded,
                    ),
                  ],
                ),
              ),
            ),

            // ========================================================
            // BOTTOM ACTION
            // ========================================================

            TaskDetailBottomAction(
              completed: completed,
              onTap: onCompletedChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================

class TaskDetailTopBar extends StatelessWidget {
  final String title;

  final VoidCallback onBack;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  const TaskDetailTopBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      height: 58,

      padding: const EdgeInsets.symmetric(horizontal: 12),

      decoration: BoxDecoration(
        color: colors.background,

        border: Border(
          bottom: BorderSide(
            color: colors.border,
          ),
        ),
      ),

      child: Row(
        children: [
          // BACK

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

                  border: Border.all(
                    color: colors.border,
                  ),
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

          // TITLE

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

          // EDIT

          TaskDetailTopButton(
            icon: Icons.edit_outlined,
            color: colors.textSecondary,
            onTap: onEdit,
          ),

          const SizedBox(width: 5),

          // DELETE

          TaskDetailTopButton(
            icon: Icons.delete_outline_rounded,
            color: AppColors.danger,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TOP BUTTON
// ============================================================

class TaskDetailTopButton extends StatelessWidget {
  final IconData icon;

  final Color color;

  final VoidCallback onTap;

  const TaskDetailTopButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(12),

        child: Ink(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: color.withValues(alpha: .06),

            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: colorsBorder(context),
            ),
          ),

          child: Icon(
            icon,
            size: 17,
            color: color,
          ),
        ),
      ),
    );
  }

  Color colorsBorder(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return colors.border;
  }
}

// ============================================================
// HERO CARD
// ============================================================

class TaskDetailHeroCard extends StatelessWidget {
  final String title;

  final bool completed;

  final String priorityText;

  final Color priorityColor;

  final IconData priorityIcon;

  const TaskDetailHeroCard({
    super.key,
    required this.title,
    required this.completed,
    required this.priorityText,
    required this.priorityColor,
    required this.priorityIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    final statusColor = completed
        ? AppColors.success
        : AppColors.warning;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: colors.surface,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: colors.border,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // TOP

          Row(
            children: [
              Container(
                width: 36,
                height: 36,

                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: .08),

                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(
                  priorityIcon,
                  size: 18,
                  color: priorityColor,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .08),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : Icons.timelapse_rounded,
                      size: 12,
                      color: statusColor,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      completed
                          ? 'task.detail.completed'.tr
                          : 'task.detail.inProgress'.tr,

                      style: TextStyle(
                        color: statusColor,

                        fontSize: 10,

                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // TITLE

          Text(
            title,

            maxLines: 4,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              color: colors.textPrimary,

              fontSize: 17,

              fontWeight: FontWeight.w800,

              height: 1.25,

              letterSpacing: -.25,
            ),
          ),

          const SizedBox(height: 12),

          // PRIORITY

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: .07),

              borderRadius: BorderRadius.circular(9),

              border: Border.all(
                color: priorityColor.withValues(alpha: .15),
              ),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                Icon(
                  priorityIcon,
                  size: 13,
                  color: priorityColor,
                ),

                const SizedBox(width: 5),

                Text(
                  priorityText,

                  style: TextStyle(
                    color: priorityColor,

                    fontSize: 10,

                    fontWeight: FontWeight.w700,
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

// ============================================================
// SECTION LABEL
// Same typography as CreateTaskLayout
// ============================================================

class TaskDetailSectionLabel extends StatelessWidget {
  final String text;

  const TaskDetailSectionLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

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

// ============================================================
// INFO CARD
// ============================================================

class TaskDetailInfoCard extends StatelessWidget {
  final String dueText;

  final String reminderText;

  const TaskDetailInfoCard({
    super.key,
    required this.dueText,
    required this.reminderText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: colors.surface,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: colors.border,
        ),
      ),

      child: Column(
        children: [
          TaskDetailInfoRow(
            icon: Icons.calendar_month_rounded,
            title: 'task.create.dueDate'.tr,
            value: dueText,
          ),

          Divider(
            height: 1,
            color: colors.border,
          ),

          TaskDetailInfoRow(
            icon: Icons.notifications_none_rounded,
            title: 'task.create.reminder'.tr,
            value: reminderText,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class TaskDetailInfoRow extends StatelessWidget {
  final IconData icon;

  final String title;

  final String value;

  const TaskDetailInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return SizedBox(
      height: 52,

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
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

              child: Icon(
                icon,
                size: 16,
                color: colors.textSecondary,
              ),
            ),

            const SizedBox(width: 11),

            Text(
              title,

              style: TextStyle(
                color: colors.textMuted,

                fontSize: 10,

                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Flexible(
              child: Text(
                value,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                textAlign: TextAlign.right,

                style: TextStyle(
                  color: colors.textSecondary,

                  fontSize: 11,

                  fontWeight: FontWeight.w700,
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
// DESCRIPTION CARD
// ============================================================

class TaskDetailDescriptionCard extends StatelessWidget {
  final String description;

  const TaskDetailDescriptionCard({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: colors.surface,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: colors.border,
        ),
      ),

      child: Text(
        description,

        style: TextStyle(
          color: colors.textSecondary,

          fontSize: 12,

          height: 1.5,

          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================================
// COUNTER
// ============================================================

class TaskDetailCounter extends StatelessWidget {
  final int completed;

  final int total;

  const TaskDetailCounter({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: colors.surfaceSecondary,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: colors.border,
        ),
      ),

      child: Text(
        '$completed/$total',

        style: TextStyle(
          color: colors.textSecondary,

          fontSize: 10,

          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// PROGRESS CARD
// ============================================================

class TaskDetailProgressCard extends StatelessWidget {
  final double progress;

  final int completed;

  final int total;

  const TaskDetailProgressCard({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: colors.surface,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: colors.border,
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Text(
                'task.detail.progress'.tr,

                style: TextStyle(
                  color: colors.textSecondary,

                  fontSize: 10,

                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                '${(progress * 100).round()}%',

                style: TextStyle(
                  color: colors.textPrimary,

                  fontSize: 11,

                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: progress,

              minHeight: 5,

              backgroundColor:
                  colors.textPrimary.withValues(alpha: .07),

              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Align(
            alignment: Alignment.centerLeft,

            child: Text(
              'task.detail.subtasksCompleted'.trParams({
                'completed': completed.toString(),
                'total': total.toString(),
              }),

              style: TextStyle(
                color: colors.textMuted,

                fontSize: 9,

                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUBTASK LIST
// ============================================================

class TaskDetailSubtaskList extends StatelessWidget {
  final List<TaskDetailSubtaskData> subtasks;

  final ValueChanged<int> onChanged;

  final ValueChanged<int> onDeleted;

  const TaskDetailSubtaskList({
    super.key,
    required this.subtasks,
    required this.onChanged,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: colors.surface,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: colors.border,
        ),
      ),

      clipBehavior: Clip.antiAlias,

      child: subtasks.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 28,
                horizontal: 16,
              ),

              child: Center(
                child: Text(
                  'task.detail.noSubtasks'.tr,

                  style: TextStyle(
                    color: colors.textMuted,

                    fontSize: 11,

                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < subtasks.length; i++) ...[
                  TaskDetailSubtaskItem(
                    subtask: subtasks[i],

                    onChanged: () {
                      onChanged(i);
                    },

                    onDelete: () {
                      onDeleted(i);
                    },
                  ),

                  if (i != subtasks.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.border,
                    ),
                ],
              ],
            ),
    );
  }
}

// ============================================================
// SUBTASK ITEM
// ============================================================

class TaskDetailSubtaskItem extends StatelessWidget {
  final TaskDetailSubtaskData subtask;

  final VoidCallback onChanged;

  final VoidCallback onDelete;

  const TaskDetailSubtaskItem({
    super.key,
    required this.subtask,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),

      child: Row(
        children: [
          // CHECKBOX

          GestureDetector(
            onTap: onChanged,

            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 160,
              ),

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
                  ? Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: colors.inverse,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 10),

          // TITLE

          Expanded(
            child: Text(
              subtask.title,

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                color: subtask.completed
                    ? colors.textMuted
                    : colors.textPrimary,

                fontSize: 11,

                fontWeight: FontWeight.w600,

                height: 1.3,

                decoration: subtask.completed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 5),

          // DELETE

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

// ============================================================
// ADD SUBTASK FIELD
// Similar to CreateTaskLayout
// ============================================================

class TaskDetailAddSubtaskField extends StatefulWidget {
  final String hintText;

  final ValueChanged<String> onAdded;

  const TaskDetailAddSubtaskField({
    super.key,
    required this.hintText,
    required this.onAdded,
  });

  @override
  State<TaskDetailAddSubtaskField> createState() =>
      _TaskDetailAddSubtaskFieldState();
}

class _TaskDetailAddSubtaskFieldState
    extends State<TaskDetailAddSubtaskField> {
  final TextEditingController _controller =
      TextEditingController();

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

  void _submit() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      _focusNode.requestFocus();
      return;
    }

    widget.onAdded(value);

    _controller.clear();

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
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: colors.surface,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: colors.border,
        ),
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),

      child: Row(
        children: [
          // PLUS

          Icon(
            Icons.add_rounded,

            size: 18,

            color: colors.textMuted,
          ),

          const SizedBox(width: 10),

          // TEXT FIELD

          Expanded(
            child: TextField(
              controller: _controller,

              focusNode: _focusNode,

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

                contentPadding: const EdgeInsets.symmetric(
                  vertical: 11,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ADD BUTTON

          Material(
            color: Colors.transparent,

            child: InkWell(
              onTap: _submit,

              borderRadius: BorderRadius.circular(9),

              child: SizedBox(
                width: 34,
                height: 34,

                child: AnimatedOpacity(
                  duration: const Duration(
                    milliseconds: 150,
                  ),

                  opacity: _hasText ? 1.0 : .35,

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

// ============================================================
// BOTTOM ACTION
// Same style as CreateTaskSaveButton
// ============================================================

class TaskDetailBottomAction extends StatelessWidget {
  final bool completed;

  final VoidCallback onTap;

  const TaskDetailBottomAction({
    super.key,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12,
      ),

      decoration: BoxDecoration(
        color: colors.background,

        border: Border(
          top: BorderSide(
            color: colors.border,
          ),
        ),
      ),

      child: SizedBox(
        width: double.infinity,

        height: 52,

        child: ElevatedButton(
          onPressed: onTap,

          style: ElevatedButton.styleFrom(
            elevation: 0,

            backgroundColor: completed
                ? AppColors.success
                : colors.textPrimary,

            foregroundColor: completed
                ? Colors.white
                : colors.inverse,

            shadowColor: Colors.transparent,

            surfaceTintColor: Colors.transparent,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(
                completed
                    ? Icons.undo_rounded
                    : Icons.check_rounded,

                size: 18,

                color: completed
                    ? Colors.white
                    : colors.inverse,
              ),

              const SizedBox(width: 7),

              Text(
                completed
                    ? 'task.detail.markIncomplete'.tr
                    : 'task.detail.markComplete'.tr,

                style: TextStyle(
                  color: completed
                      ? Colors.white
                      : colors.inverse,

                  fontSize: 12,

                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DELETE DIALOG
// ============================================================

class TaskDeleteDialog extends StatelessWidget {
  final VoidCallback onCancel;

  final VoidCallback onDelete;

  const TaskDeleteDialog({
    super.key,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskDetailColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return AlertDialog(
      backgroundColor: colors.surface,

      elevation: 10,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      titlePadding: const EdgeInsets.fromLTRB(
        22,
        22,
        22,
        8,
      ),

      contentPadding: const EdgeInsets.fromLTRB(
        22,
        4,
        22,
        8,
      ),

      actionsPadding: const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        14,
      ),

      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: AppColors.danger.withValues(
                alpha: .10,
              ),

              borderRadius: BorderRadius.circular(12),
            ),

            child: const Icon(
              Icons.delete_outline_rounded,

              color: AppColors.danger,

              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'task.detail.deleteTitle'.tr,

              style: TextStyle(
                color: colors.textPrimary,

                fontSize: 16,

                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),

      content: Text(
        'task.detail.deleteMessage'.tr,

        style: TextStyle(
          color: colors.textMuted,

          fontSize: 11,

          height: 1.45,
        ),
      ),

      actions: [
        TextButton(
          onPressed: onCancel,

          child: Text(
            'task.detail.cancel'.tr,

            style: TextStyle(
              color: colors.textSecondary,

              fontSize: 10,

              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        ElevatedButton(
          onPressed: onDelete,

          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,

            foregroundColor: Colors.white,

            elevation: 0,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          child: Text(
            'task.detail.delete'.tr,

            style: const TextStyle(
              fontSize: 10,

              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}