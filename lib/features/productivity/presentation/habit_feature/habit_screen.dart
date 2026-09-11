import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../domain/entities/productivity_entities.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import '../screens/create_habit_screen.dart';

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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text(
          'This will remove the habit and its future reminders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

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

    final colors = _HabitColors(context);
    return Obx(() {
      if (controller.isLoading.value && controller.habits.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final completed = controller.habits
          .where((habit) => habit.checkedInToday)
          .length;
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          foregroundColor: colors.textPrimary,
          elevation: 0,
          title: const Text('Habits'),
          actions: [
            IconButton(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Create habit',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: controller.reload,
          color: AppColors.productivityAccent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _StreakCard(
                completed: completed,
                total: controller.habits.length,
                habits: controller.habits,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Today's habits",
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$completed/${controller.habits.length}',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (controller.habits.isEmpty)
                _EmptyHabits(onCreate: _openCreate)
              else
                ...controller.habits.map(
                  (habit) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HabitTile(
                      habit: habit,
                      busy: controller.isBusy(habit.habitId),
                      onChanged: (value) =>
                          _toggle(controller, habit.habitId, value),
                      onDelete: () => _delete(controller, habit.habitId),
                    ),
                  ),
                ),
            ],
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
    final colors = _HabitColors(context);
    final bestStreak = habits.isEmpty
        ? 0
        : habits
              .map((habit) => habit.streakCount)
              .reduce((a, b) => a > b ? a : b);
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF171717) : Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFFB43B),
                ),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$bestStreak-day streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$completed of $total completed today',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .65),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: .17),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
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
    required this.onDelete,
  });

  final ProductivityHabit habit;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(context);
    final checked = habit.checkedInToday;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: ListTile(
        leading: Checkbox(
          value: checked,
          onChanged: busy ? null : (value) => onChanged(value ?? false),
          activeColor: AppColors.productivityAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            decoration: checked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          _habitSubtitle(habit),
          style: TextStyle(color: colors.textMuted, fontSize: 11),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.repeat_rounded, color: colors.textMuted, size: 30),
          const SizedBox(height: 8),
          Text(
            'No habits yet',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a small daily routine to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onCreate,
            child: const Text('Create habit'),
          ),
        ],
      ),
    );
  }
}

class _UnavailableHabitView extends StatelessWidget {
  const _UnavailableHabitView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Sign in to manage habits.')),
    );
  }
}

class _HabitColors {
  _HabitColors(BuildContext context)
    : isDark = Theme.of(context).brightness == Brightness.dark;

  final bool isDark;

  Color get background =>
      isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
}

String _habitSubtitle(ProductivityHabit habit) {
  final parts = <String>[];
  final category = habit.category;
  final frequency = habit.frequency;
  if (category != null && category.isNotEmpty) parts.add(category);
  if (frequency != null && frequency.isNotEmpty) parts.add(frequency);
  parts.add('${habit.streakCount} day streak');
  final reminder = habit.reminderTime;
  if (reminder != null && reminder.isNotEmpty) parts.add('Reminder $reminder');
  return parts.join(' · ');
}

String _errorText(Object error) =>
    error.toString().replaceFirst('AppError(', '').split('):').last.trim();
