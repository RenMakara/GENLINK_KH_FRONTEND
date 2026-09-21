import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../domain/entities/productivity_entities.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import '../screens/create_task_screen.dart';
import '../widgets/productivity_illustrations.dart';
import '../widgets/productivity_list_components.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _searchController = TextEditingController();
  ProductivityController? _controller;
  String _search = '';
  ProductivityTaskFilter _filter = ProductivityTaskFilter.all;

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    await Get.to(() => const CreateTaskScreen());
    await _controller?.reload();
  }

  Future<void> _toggle(
    ProductivityController controller,
    ProductivityTask task,
  ) async {
    try {
      await controller.toggleTask(task.taskId, completed: !task.completed);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _delete(ProductivityController controller, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = ListThemeColors(dialogContext);
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'tasks.deleteConfirmTitle'.tr,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'tasks.deleteConfirmMessage'.tr,
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'common.cancel'.tr,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('common.delete'.tr),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await controller.deleteTask(taskId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const _UnavailableTaskView();

    final colors = ListThemeColors(context);
    return Obx(() {
      if (controller.isLoading.value && controller.tasks.isEmpty) {
        return Scaffold(
          backgroundColor: colors.background,
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final tasks = filterProductivityTasks(
        controller.tasks,
        filter: _filter,
        search: _search,
      );

      final filterLabels = {
        ProductivityTaskFilter.all: 'tasks.filter.all'.tr,
        ProductivityTaskFilter.today: 'tasks.filter.today'.tr,
        ProductivityTaskFilter.upcoming: 'tasks.filter.upcoming'.tr,
        ProductivityTaskFilter.overdue: 'tasks.overdue'.tr,
      };

      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.reload,
            color: AppColors.productivityAccent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 36),
              children: [
                // Top Header (Back, Title, Subtitle, + Button)
                ListScreenHeader(
                  title: 'tasks.title'.tr,
                  subtitle: 'tasks.subtitle'.tr,
                  onAdd: _createTask,
                  addTooltip: 'task.create.title'.tr,
                ),

                // Hero Banner (Blue gradient with 3D paper clipboard)
                ListHeroBanner(
                  illustration: const Soft3DClipboardWidget(size: 68),
                  title: 'tasks.heroQuote'.tr,
                  subtitle: 'tasks.heroSub'.tr,
                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  titleColor: Colors.white,
                  subtitleColor: Colors.white.withValues(alpha: 0.90),
                  shadowColor: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 10),

                // Search Bar & Filter Tune Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: colors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) =>
                                      setState(() => _search = value),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'tasks.searchHint'.tr,
                                    hintStyle: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 13.5,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (_search.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _search = '');
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: colors.textMuted,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Squircle Tune Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Cycle filter or toggle
                            setState(() {
                              final nextIndex =
                                  (_filter.index + 1) %
                                  ProductivityTaskFilter.values.length;
                              _filter = ProductivityTaskFilter.values[nextIndex];
                            });
                          },
                          icon: Icon(
                            Icons.tune_rounded,
                            color: colors.textPrimary,
                            size: 20,
                          ),
                          splashRadius: 22,
                          tooltip: 'tasks.filter.title'.tr,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Tabs (Horizontal Pill Carousel)
                PillFilterTabs<ProductivityTaskFilter>(
                  selected: _filter,
                  options: const [
                    ProductivityTaskFilter.all,
                    ProductivityTaskFilter.today,
                    ProductivityTaskFilter.upcoming,
                    ProductivityTaskFilter.overdue,
                  ],
                  labelBuilder: (filter) => filterLabels[filter] ?? '',
                  onChanged: (filter) => setState(() => _filter = filter),
                ),

                // Section Header (My Tasks + Count)
                ListSectionHeader(
                  title: 'tasks.myTasks'.tr,
                  countText: '${tasks.length}',
                ),

                // Task List Items
                if (tasks.isEmpty)
                  ListEncouragementCard(
                    illustration: const Soft3DClipboardWidget(size: 64),
                    title: 'tasks.allCaughtUp'.tr,
                    subtitle: 'tasks.allCaughtUpSubtitle'.tr,
                    buttonLabel: 'tasks.addTask'.tr,
                    onAction: _createTask,
                  )
                else ...[
                  ...tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: _TaskTile(
                        task: task,
                        busy: controller.isBusy(task.taskId),
                        onToggle: () => _toggle(controller, task),
                        onDelete: () => _delete(controller, task.taskId),
                      ),
                    ),
                  ),

                  // Bottom Encouragement Card
                  ListEncouragementCard(
                    illustration: const Soft3DClipboardWidget(size: 64),
                    title: 'tasks.allCaughtUp'.tr,
                    subtitle: 'tasks.allCaughtUpSubtitle'.tr,
                    buttonLabel: 'tasks.addTask'.tr,
                    onAction: _createTask,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

enum ProductivityTaskFilter { all, today, upcoming, overdue, completed }

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.busy,
    required this.onToggle,
    required this.onDelete,
  });

  final ProductivityTask task;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = ListThemeColors(context);

    // Priority pill color styling
    Color priorityBg;
    Color priorityFg;
    switch (task.priority?.toUpperCase()) {
      case 'HIGH':
        priorityBg = const Color(0xFFFEE2E2);
        priorityFg = const Color(0xFFDC2626);
        break;
      case 'LOW':
        priorityBg = const Color(0xFFDCFCE7);
        priorityFg = const Color(0xFF16A34A);
        break;
      case 'MEDIUM':
      default:
        priorityBg = const Color(0xFFEEF2FF);
        priorityFg = const Color(0xFF4F46E5);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.overdue
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : colors.border,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Check Toggle Button
          GestureDetector(
            key: ValueKey('task_toggle_${task.taskId}'),
            onTap: busy ? null : onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.completed
                    ? const Color(0xFF22C55E)
                    : Colors.transparent,
                border: Border.all(
                  color: task.completed
                      ? const Color(0xFF22C55E)
                      : colors.border,
                  width: task.completed ? 1.5 : 2.0,
                ),
              ),
              alignment: Alignment.center,
              child: task.completed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : (busy
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.textMuted,
                            ),
                          ),
                        )
                      : null),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: task.completed
                        ? colors.textMuted
                        : colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _taskSubtitle(task),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: task.overdue
                        ? const Color(0xFFEF4444)
                        : colors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // Trailing: Priority Badge + 3-dots Menu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.priority != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: priorityBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.priority!.toUpperCase(),
                    style: TextStyle(
                      color: priorityFg,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.textMuted,
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'common.delete'.tr,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnavailableTaskView extends StatelessWidget {
  const _UnavailableTaskView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('tasks.signInToManage'.tr)),
    );
  }
}

String _taskSubtitle(ProductivityTask task) {
  final category = task.category?.toUpperCase() ?? 'GENERAL';
  final due = task.dueDate;
  if (task.overdue) return '$category · OVERDUE';
  if (due == null) return category;
  final local = due.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$category · ${local.month}/${local.day} $hour:$minute $period';
}

String _errorText(Object error) =>
    error.toString().replaceFirst('AppError(', '').split('):').last.trim();

List<ProductivityTask> filterProductivityTasks(
  Iterable<ProductivityTask> tasks, {
  required ProductivityTaskFilter filter,
  String search = '',
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final tomorrow = today.add(const Duration(days: 1));
  final query = search.trim().toLowerCase();

  return tasks
      .where((task) {
        if (query.isNotEmpty &&
            !task.title.toLowerCase().contains(query) &&
            !(task.description ?? '').toLowerCase().contains(query)) {
          return false;
        }

        final due = task.dueDate?.toLocal();
        switch (filter) {
          case ProductivityTaskFilter.all:
            return true;
          case ProductivityTaskFilter.today:
            return !task.completed &&
                due != null &&
                !due.isBefore(today) &&
                due.isBefore(tomorrow);
          case ProductivityTaskFilter.upcoming:
            return !task.completed && due != null && !due.isBefore(tomorrow);
          case ProductivityTaskFilter.overdue:
            return !task.completed && task.overdue;
          case ProductivityTaskFilter.completed:
            return task.completed;
        }
      })
      .toList(growable: false);
}
