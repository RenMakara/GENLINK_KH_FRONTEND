import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

// ============================================================
// TASK DATA
// ============================================================

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

// ============================================================
// THEME COLORS
// ============================================================

class _TasksColors {
  final bool isDark;

  _TasksColors(this.isDark);

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

// ============================================================
// TOP NAVIGATION
// ============================================================

class TasksTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const TasksTopBar({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = _TasksColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Row(
      children: [
        // BACK BUTTON
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onBack ?? () => Navigator.of(context).pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 19,
              color: colors.textPrimary,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // TITLE
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // ADD TASK BUTTON
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // TODO: Navigate to create task screen
            debugPrint('Add task');
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, size: 21, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SEARCH
// ============================================================

class TasksSearchField extends StatelessWidget {
  final String hintText;

  const TasksSearchField({super.key, required this.hintText});

  @override
  Widget build(BuildContext context) {
    final colors = _TasksColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        style: TextStyle(color: colors.textPrimary, fontSize: 11),
        cursorColor: AppColors.brandPrimary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 10),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 17,
            color: colors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STATUS FILTERS
// ============================================================

class TasksStatusFilters extends StatefulWidget {
  final List<String> filters;

  const TasksStatusFilters({super.key, required this.filters});

  @override
  State<TasksStatusFilters> createState() => _TasksStatusFiltersState();
}

class _TasksStatusFiltersState extends State<TasksStatusFilters> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = _TasksColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < widget.filters.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  selectedIndex = i;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selectedIndex == i
                      ? colors.textPrimary
                      : colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: selectedIndex == i
                      ? null
                      : Border.all(color: colors.border),
                ),
                child: Text(
                  widget.filters[i],
                  style: TextStyle(
                    color: selectedIndex == i
                        ? colors.isDark
                              ? Colors.black
                              : Colors.white
                        : colors.textSecondary,
                    fontSize: 9,
                    fontWeight: selectedIndex == i
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (i != widget.filters.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// PRIORITY FILTERS
// ============================================================

class TasksPriorityFilters extends StatefulWidget {
  final List<String> filters;

  const TasksPriorityFilters({super.key, required this.filters});

  @override
  State<TasksPriorityFilters> createState() => _TasksPriorityFiltersState();
}

class _TasksPriorityFiltersState extends State<TasksPriorityFilters> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = _TasksColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < widget.filters.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  selectedIndex = i;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selectedIndex == i
                      ? colors.textPrimary
                      : colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.filters[i],
                  style: TextStyle(
                    color: selectedIndex == i
                        ? colors.isDark
                              ? Colors.black
                              : Colors.white
                        : colors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (i != widget.filters.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// TASK LIST
// ============================================================

class TasksList extends StatelessWidget {
  final List<TaskData> tasks;

  const TasksList({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final colors = _TasksColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.task_alt_rounded, size: 40, color: colors.textMuted),
            const SizedBox(height: 10),
            Text(
              'No tasks found',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? .12 : .04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < tasks.length; i++) ...[
            _TaskTile(task: tasks[i]),
            if (i != tasks.length - 1) Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// TASK TILE
// ============================================================

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
    final colors = _TasksColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    final priorityColor = _priorityColor(widget.task.priority);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          completed = !completed;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // CHECKBOX
            _TaskCheckbox(
              completed: completed,
              onTap: () {
                setState(() {
                  completed = !completed;
                });
              },
            ),

            const SizedBox(width: 10),

            // PRIORITY DOT
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 9),

            // TASK CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: completed ? colors.textMuted : colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.task.dueText,
                    style: TextStyle(color: colors.textMuted, fontSize: 8),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // PRIORITY LABEL
            _PriorityLabel(priority: widget.task.priority),
          ],
        ),
      ),
    );
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

// ============================================================
// PRIORITY LABEL
// ============================================================

class _PriorityLabel extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityLabel({required this.priority});

  @override
  Widget build(BuildContext context) {
    final colors = _TasksColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    String text;
    Color color;

    switch (priority) {
      case TaskPriority.high:
        text = 'HIGH';
        color = AppColors.financeAccent;
        break;

      case TaskPriority.medium:
        text = 'MEDIUM';
        color = AppColors.productivityAccent;
        break;

      case TaskPriority.low:
        text = 'LOW';
        color = AppColors.growthAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// CHECKBOX
// ============================================================

class _TaskCheckbox extends StatelessWidget {
  final bool completed;
  final VoidCallback onTap;

  const _TaskCheckbox({required this.completed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _TasksColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: completed ? colors.textPrimary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: completed ? colors.textPrimary : colors.textMuted,
            width: 1.2,
          ),
        ),
        child: completed
            ? Icon(
                Icons.check_rounded,
                size: 11,
                color: colors.isDark ? Colors.black : Colors.white,
              )
            : null,
      ),
    );
  }
}
