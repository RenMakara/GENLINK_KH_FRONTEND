import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../domain/entities/productivity_entities.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import '../screens/create_habit_screen.dart';
import '../widgets/creation_form_components.dart';
import '../widgets/productivity_illustrations.dart';
import '../widgets/productivity_list_components.dart';

class HabitHomeScreen extends StatefulWidget {
  const HabitHomeScreen({super.key});

  @override
  State<HabitHomeScreen> createState() => _HabitHomeScreenState();
}

class _HabitHomeScreenState extends State<HabitHomeScreen> {
  ProductivityController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
  }

  Future<void> _openCreate() async {
    await Get.to(() => const CreateHabitScreen());
    await _controller?.reload();
  }

  Future<void> _edit(ProductivityHabit habit) async {
    await Get.to(() => CreateHabitScreen(initialHabit: habit));
    await _controller?.reload();
  }

  Future<void> _toggle(
    ProductivityController controller,
    String id,
    bool value,
  ) async {
    try {
      await controller.toggleHabit(id, completed: value);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _delete(ProductivityController controller, String id) async {
    final shouldDelete = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: 'habits.deleteConfirmTitle'.tr,
      message: 'habits.deleteConfirmMessage'.tr,
      confirmLabel: 'common.delete'.tr,
      cancelLabel: 'common.cancel'.tr,
    );
    if (!shouldDelete) return;

    try {
      await controller.deleteHabit(id);
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
    if (controller == null) return const _UnavailableHabitView();

    final colors = ListThemeColors(context);
    return Obx(() {
      if (controller.isLoading.value && controller.habits.isEmpty) {
        return Scaffold(
          backgroundColor: colors.background,
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final completed = controller.habits
          .where((habit) => _isCheckedForCurrentPeriod(habit))
          .length;

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
                  title: 'habits.title'.tr,
                  subtitle: 'habits.subtitle'.tr,
                  onAdd: _openCreate,
                  addTooltip: 'habits.createHabit'.tr,
                ),

                // Hero Banner (Peach/Orange gradient with 3D Fire icon)
                ListHeroBanner(
                  illustration: const Soft3DFireWidget(size: 64),
                  title: 'habits.heroQuote'.tr,
                  subtitle: 'habits.heroSub'.tr,
                  gradientColors: const [Color(0xFFFFF1EB), Color(0xFFFFDDD0)],
                  titleColor: const Color(0xFF9A3412),
                  subtitleColor: const Color(0xFFC2410C),
                  shadowColor: const Color(0xFFEA580C),
                ),
                const SizedBox(height: 10),

                // Sleek Charcoal Streak Card with Golden Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _StreakCard(
                    completed: completed,
                    total: controller.habits.length,
                    habits: controller.habits,
                  ),
                ),

                // Section Header (Today's habits + Count)
                ListSectionHeader(
                  title: 'habits.todayHabits'.tr,
                  countText: '$completed/${controller.habits.length}',
                ),

                // Habit List Items
                if (controller.habits.isEmpty)
                  ListEncouragementCard(
                    illustration: const Soft3DSproutIcon(size: 64),
                    title: 'habits.greatStart'.tr,
                    subtitle: 'habits.greatStartSubtitle'.tr,
                    buttonLabel: 'habits.addHabit'.tr,
                    onAction: _openCreate,
                  )
                else ...[
                  ...controller.habits.map(
                    (habit) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: _HabitTile(
                        habit: habit,
                        busy: controller.isBusy(habit.habitId),
                        onChanged: (value) =>
                            _toggle(controller, habit.habitId, value),
                        onEdit: () => _edit(habit),
                        onDelete: () => _delete(controller, habit.habitId),
                      ),
                    ),
                  ),

                  // Bottom Encouragement Card
                  ListEncouragementCard(
                    illustration: const Soft3DSproutIcon(size: 64),
                    title: 'habits.greatStart'.tr,
                    subtitle: 'habits.greatStartSubtitle'.tr,
                    buttonLabel: 'habits.addHabit'.tr,
                    onAction: _openCreate,
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

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.completed,
    required this.total,
    required this.habits,
  });

  final int completed;
  final int total;
  final List<ProductivityHabit> habits;

  @override
  Widget build(BuildContext context) {
    final bestHabit = habits.isEmpty
        ? null
        : habits.reduce(
            (current, next) =>
                next.streakCount > current.streakCount ? next : current,
          );
    final bestStreak = bestHabit?.streakCount ?? 0;
    final streakLabel = bestHabit?.frequency?.toUpperCase() == 'WEEKLY'
        ? 'habits.weekStreakShort'
        : 'habits.dayStreakShort';
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF181A1F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Flame Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2A2118),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Streak Count & Completed Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      streakLabel.trParams({'count': '$bestStreak'}),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'habits.completedCount'.trParams({
                        'completed': '$completed',
                        'total': '$total',
                      }),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.50),
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Golden Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.busy,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductivityHabit habit;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = ListThemeColors(context);
    final isWeekly = habit.frequency?.toUpperCase() == 'WEEKLY';
    final checked = isWeekly ? habit.checkedInThisWeek : habit.checkedInToday;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
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
          // Circular Purple Check Toggle Button
          GestureDetector(
            key: ValueKey('habit_toggle_${habit.habitId}'),
            onTap: busy || (isWeekly && checked)
                ? null
                : () => onChanged(!checked),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? const Color(0xFF8B5CF6) : Colors.transparent,
                border: Border.all(
                  color: checked ? const Color(0xFF8B5CF6) : colors.border,
                  width: checked ? 1.5 : 2.0,
                ),
              ),
              alignment: Alignment.center,
              child: checked
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

          // Habit Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: checked ? colors.textMuted : colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: checked ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _habitSubtitle(habit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // Trailing 3-dots Menu
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert_rounded,
              color: colors.textMuted,
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('common.edit'.tr),
                  ],
                ),
              ),
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
    );
  }
}

bool _isCheckedForCurrentPeriod(ProductivityHabit habit) =>
    habit.frequency?.toUpperCase() == 'WEEKLY'
    ? habit.checkedInThisWeek
    : habit.checkedInToday;

class _UnavailableHabitView extends StatelessWidget {
  const _UnavailableHabitView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('habits.signInToManage'.tr)));
  }
}

String _habitSubtitle(ProductivityHabit habit) {
  final parts = <String>[];
  final category = habit.category;
  final frequency = habit.frequency;
  if (category != null && category.isNotEmpty) {
    parts.add(category.toUpperCase());
  }
  if (frequency != null && frequency.isNotEmpty) {
    parts.add(frequency.toUpperCase());
  }
  parts.add(
    (frequency?.toUpperCase() == 'WEEKLY'
            ? 'habits.weekStreakShort'
            : 'habits.dayStreakShort')
        .trParams({'count': '${habit.streakCount}'}),
  );
  final reminder = habit.reminderTime;
  if (reminder != null && reminder.isNotEmpty) {
    parts.add('habits.reminder'.trParams({'time': reminder}));
  }
  return parts.join(' · ');
}

String _errorText(Object error) =>
    error.toString().replaceFirst('AppError(', '').split('):').last.trim();
