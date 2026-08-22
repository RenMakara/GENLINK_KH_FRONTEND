import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

// TASK DATA
enum TaskPriority { high, medium, low }

class TaskData {
  final String title;
  final String dueText;
  final TaskPriority priority;
  final bool completed;

  const TaskData({
    required this.title,
    required this.dueText,
    required this.priority,
    this.completed = false,
  });
}

// TASK THEME COLORS
class TaskThemeColors {
  final bool isDark;

  const TaskThemeColors(this.isDark);

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
}

// TOP BAR
class TasksTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onAdd;

  const TasksTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Row(
      children: [
        _TaskIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack ?? () => Navigator.of(context).pop(),
          backgroundColor: colors.surface,
          borderColor: colors.border,
          iconColor: colors.textPrimary,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        _TaskIconButton(
          icon: Icons.add_rounded,
          onTap: onAdd,
          backgroundColor: colors.textPrimary,
          iconColor: colors.isDark ? Colors.black : Colors.white,
          size: 42,
          iconSize: 23,
        ),
      ],
    );
  }
}

// ICON BUTTON
class _TaskIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color? borderColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  const _TaskIconButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    this.borderColor,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(13),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}

// SEARCH FIELD
class TasksSearchField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;
  final int activeFilterCount;

  const TasksSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onFilter,
    this.activeFilterCount = 0,
  });

  @override
  State<TasksSearchField> createState() => _TasksSearchFieldState();
}

class _TasksSearchFieldState extends State<TasksSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _hasText = _controller.text.isNotEmpty;
    _isFocused = _focusNode.hasFocus;
  }

  void _onTextChanged() {
    if (!mounted) return;

    final value = _controller.text.isNotEmpty;

    if (_hasText != value) {
      setState(() {
        _hasText = value;
      });
    }
  }

  void _onFocusChanged() {
    if (!mounted) return;

    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);

    if (widget.controller == null) {
      _controller.dispose();
    }

    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = TaskThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    final filterActive = widget.activeFilterCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _isFocused
              ? AppColors.brandPrimary.withValues(alpha: .65)
              : colors.border,
          width: _isFocused ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _isFocused
                  ? AppColors.brandPrimary.withValues(alpha: .10)
                  : colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: _isFocused ? AppColors.brandPrimary : colors.textMuted,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              maxLines: 1,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.brandPrimary,
              cursorWidth: 1.5,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                filled: false,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _hasText
                ? Material(
                    key: const ValueKey('clear'),
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _clearSearch,
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), width: 6),
          ),

          if (widget.onFilter != null) ...[
            Container(width: 1, height: 28, color: colors.border),

            const SizedBox(width: 5),

            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onFilter,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: filterActive
                        ? AppColors.brandPrimary.withValues(alpha: .12)
                        : colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: filterActive
                              ? AppColors.brandPrimary
                              : colors.textSecondary,
                        ),
                      ),

                      if (filterActive)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surfaceSecondary,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

// TASK HEADER
class TasksHeader extends StatelessWidget {
  final String title;
  final int count;
  final int activeFilterCount;
  final VoidCallback? onFilter;

  const TasksHeader({
    super.key,
    required this.title,
    required this.count,
    this.activeFilterCount = 0,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -.25,
          ),
        ),

        const SizedBox(width: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const Spacer(),

        if (activeFilterCount > 0 && onFilter != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFilter,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_rounded,
                      size: 12,
                      color: AppColors.brandPrimary,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      '$activeFilterCount ${'tasks.active'.tr}',
                      style: TextStyle(
                        color: AppColors.brandPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// TASK LIST
class TasksList extends StatelessWidget {
  final List<TaskData> tasks;
  final String emptyTitle;
  final String emptyMessage;

  const TasksList({
    super.key,
    required this.tasks,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    if (tasks.isEmpty) {
      return _EmptyTasksState(
        colors: colors,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            for (int i = 0; i < tasks.length; i++) ...[
              _TaskTile(task: tasks[i]),

              if (i != tasks.length - 1)
                Divider(height: 1, thickness: 1, color: colors.border),
            ],
          ],
        ),
      ),
    );
  }
}

// EMPTY STATE
class _EmptyTasksState extends StatelessWidget {
  final TaskThemeColors colors;
  final String title;
  final String message;

  const _EmptyTasksState({
    required this.colors,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt_rounded,
              size: 30,
              color: colors.textMuted,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// TASK TILE
class _TaskTile extends StatefulWidget {
  final TaskData task;

  const _TaskTile({required this.task});

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  late bool completed;

  @override
  void initState() {
    super.initState();
    completed = widget.task.completed;
  }

  @override
  Widget build(BuildContext context) {
    final colors = TaskThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    final priorityColor = _priorityColor(widget.task.priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleCompleted,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              _TaskCheckbox(completed: completed, onTap: _toggleCompleted),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            widget.task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: completed
                                  ? colors.textMuted
                                  : colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          completed
                              ? Icons.check_circle_outline_rounded
                              : Icons.schedule_rounded,
                          size: 12,
                          color: colors.textMuted,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            widget.task.dueText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              _PriorityLabel(priority: widget.task.priority),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleCompleted() {
    setState(() {
      completed = !completed;
    });
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.financeAccent;

      case TaskPriority.medium:
        return AppColors.productivityAccent;

      case TaskPriority.low:
        return AppColors.growthAccent;
    }
  }
}

// PRIORITY LABEL
class _PriorityLabel extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityLabel({required this.priority});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    switch (priority) {
      case TaskPriority.high:
        text = 'tasks.priority.high'.tr;
        color = AppColors.financeAccent;
        break;

      case TaskPriority.medium:
        text = 'tasks.priority.medium'.tr;
        color = AppColors.productivityAccent;
        break;

      case TaskPriority.low:
        text = 'tasks.priority.low'.tr;
        color = AppColors.growthAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

// CHECKBOX

class _TaskCheckbox extends StatelessWidget {
  final bool completed;
  final VoidCallback onTap;

  const _TaskCheckbox({required this.completed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = TaskThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 21,
        height: 21,
        decoration: BoxDecoration(
          color: completed ? colors.textPrimary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: completed ? colors.textPrimary : colors.textMuted,
            width: 1.3,
          ),
        ),
        child: completed
            ? Icon(
                Icons.check_rounded,
                size: 13,
                color: colors.isDark ? Colors.black : Colors.white,
              )
            : null,
      ),
    );
  }
}

// BOTTOM TIP
class TasksBottomTip extends StatelessWidget {
  final String text;

  const TasksBottomTip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = TaskThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, size: 12, color: colors.textMuted),

          const SizedBox(width: 5),

          Text(
            text,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// FILTER SHEET
class TasksFilterSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusTitle;
  final String priorityTitle;
  final String resetText;
  final String applyText;

  final List<String> statusOptions;
  final List<String> priorityOptions;

  final int selectedStatus;
  final int selectedPriority;

  final ValueChanged<int> onStatusChanged;
  final ValueChanged<int> onPriorityChanged;

  final VoidCallback onReset;
  final VoidCallback onApply;

  const TasksFilterSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusTitle,
    required this.priorityTitle,
    required this.resetText,
    required this.applyText,
    required this.statusOptions,
    required this.priorityOptions,
    required this.selectedStatus,
    required this.selectedPriority,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TaskThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HANDLE
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: .30),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // HEADER
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 21,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                if (selectedStatus != 0 || selectedPriority != 0)
                  TextButton(
                    onPressed: onReset,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      resetText,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 26),

            _FilterTitle(title: statusTitle, colors: colors),

            const SizedBox(height: 10),

            _FilterOptionGroup(
              options: statusOptions,
              selectedIndex: selectedStatus,
              colors: colors,
              onSelected: onStatusChanged,
            ),

            const SizedBox(height: 24),

            _FilterTitle(title: priorityTitle, colors: colors),

            const SizedBox(height: 10),

            _FilterOptionGroup(
              options: priorityOptions,
              selectedIndex: selectedPriority,
              colors: colors,
              onSelected: onPriorityChanged,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.textPrimary,
                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  applyText,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// FILTER TITLE
class _FilterTitle extends StatelessWidget {
  final String title;
  final TaskThemeColors colors;

  const _FilterTitle({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
      ),
    );
  }
}

// FILTER GROUP
class _FilterOptionGroup extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final TaskThemeColors colors;
  final ValueChanged<int> onSelected;

  const _FilterOptionGroup({
    required this.options,
    required this.selectedIndex,
    required this.colors,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (int i = 0; i < options.length; i++)
          _FilterOption(
            label: options[i],
            selected: selectedIndex == i,
            colors: colors,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}

// FILTER OPTION
class _FilterOption extends StatelessWidget {
  final String label;
  final bool selected;
  final TaskThemeColors colors;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.textPrimary : colors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? colors.textPrimary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? colors.isDark
                        ? Colors.black
                        : Colors.white
                  : colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
