import 'package:flutter/material.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/productivity/presentation/habit_feature/widget/habit_home_widget.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // ============================================================
  // FORM STATE
  // ============================================================

  String _selectedCategory = 'Productivity';

  String _selectedFrequency = 'Daily';

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  bool _hasReminder = false;

  // ============================================================
  // CATEGORIES
  // ============================================================

  final List<String> _categories = [
    'Productivity',
    'Health',
    'Learning',
    'Personal',
    'Finance',
  ];

  // ============================================================
  // FREQUENCIES
  // ============================================================

  final List<String> _frequencies = ['Daily', 'Weekly', 'Custom'];

  // ============================================================
  // CUSTOM DAYS
  // ============================================================

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final Set<String> _selectedDays = {};

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // CREATE HABIT
  // ============================================================

  void _createHabit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Custom frequency must have at least one day.
    if (_selectedFrequency == 'Custom' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one day.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      return;
    }

    final habit = HabitData(
      title: _titleController.text.trim(),
      streak: 0,
      completed: false,
      completedDays: 0,
    );

    Navigator.pop(context, habit);
  }

  // ============================================================
  // PICK TIME
  // ============================================================

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = picked;
      _hasReminder = true;
    });
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(BuildContext context) {
    return _selectedTime.format(context);
  }

  // ============================================================
  // FREQUENCY ICON
  // ============================================================

  IconData _frequencyIcon(String frequency) {
    switch (frequency) {
      case 'Daily':
        return Icons.today_rounded;

      case 'Weekly':
        return Icons.date_range_rounded;

      case 'Custom':
        return Icons.tune_rounded;

      default:
        return Icons.calendar_today_rounded;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final horizontalPadding = width < 360
                ? 12.0
                : width < 400
                ? 14.0
                : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      36,
                    ),
                    children: [
                      // =================================================
                      // HEADER
                      // =================================================
                      _buildHeader(isDark: isDark),

                      const SizedBox(height: 20),

                      // =================================================
                      // INTRO
                      // =================================================
                      _buildIntro(isDark: isDark),

                      const SizedBox(height: 20),

                      // =================================================
                      // HABIT NAME
                      // =================================================
                      _buildLabel('Habit Name', isDark),

                      const SizedBox(height: 8),

                      _buildTextField(
                        controller: _titleController,
                        hintText: 'e.g. Morning meditation',
                        icon: Icons.check_circle_outline_rounded,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a habit name';
                          }

                          if (value.trim().length < 3) {
                            return 'Habit name is too short';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // =================================================
                      // CATEGORY
                      // =================================================
                      _buildLabel('Category', isDark),

                      const SizedBox(height: 8),

                      _buildCategorySelector(isDark: isDark),

                      const SizedBox(height: 20),

                      // =================================================
                      // FREQUENCY
                      // =================================================
                      _buildLabel('Frequency', isDark),

                      const SizedBox(height: 8),

                      _buildFrequencySelector(isDark: isDark),

                      const SizedBox(height: 20),

                      // =================================================
                      // REMINDER
                      // =================================================
                      _buildLabel('Reminder', isDark),

                      const SizedBox(height: 8),

                      _buildReminderCard(isDark: isDark),

                      const SizedBox(height: 20),

                      // =================================================
                      // NOTES
                      // =================================================
                      _buildLabel('Notes', isDark),

                      const SizedBox(height: 8),

                      _buildNotesField(isDark: isDark),

                      const SizedBox(height: 28),

                      // =================================================
                      // CREATE BUTTON
                      // =================================================
                      _buildCreateButton(isDark: isDark),

                      const SizedBox(height: 10),

                      // =================================================
                      // CANCEL BUTTON
                      // =================================================
                      _buildCancelButton(isDark: isDark),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({required bool isDark}) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const AppBackButton(),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            'Create Habit',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceSecondary
                : AppColors.lightSurfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorderSubtle
                  : AppColors.lightBorderSubtle,
            ),
          ),
          child: Icon(Icons.add_task_rounded, size: 20, color: textSecondary),
        ),
      ],
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.productivityAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.productivityAccent,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build a better routine',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Create a habit and stay consistent every day.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text, bool isDark) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Text(
      text,
      style: TextStyle(
        color: textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: TextInputAction.done,
      style: TextStyle(
        color: textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 19, color: AppColors.productivityAccent),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.productivityAccent,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY SELECTOR
  // ============================================================

  Widget _buildCategorySelector({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // CATEGORY HEADER
          // ========================================================
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.productivityAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  size: 17,
                  color: AppColors.productivityAccent,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  'Choose category',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                '1 selected',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ========================================================
          // HORIZONTAL CATEGORY LIST
          // ========================================================
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,

              // Smooth scrolling
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),

              itemCount: _categories.length,

              separatorBuilder: (_, _) {
                return const SizedBox(width: 8);
              },

              itemBuilder: (context, index) {
                final category = _categories[index];

                final selected = _selectedCategory == category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,

                    width: 125,
                    height: 52,

                    padding: const EdgeInsets.symmetric(horizontal: 11),

                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.productivityAccent.withValues(alpha: 0.10)
                          : secondarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.productivityAccent : border,
                        width: selected ? 1.2 : 1,
                      ),
                    ),

                    child: Row(
                      children: [
                        // ==================================================
                        // CHECKBOX [ ]
                        // ==================================================
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,

                          width: 19,
                          height: 19,

                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.productivityAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: selected
                                  ? AppColors.productivityAccent
                                  : textSecondary,
                              width: selected ? 1.2 : 1,
                            ),
                          ),

                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),

                        const SizedBox(width: 8),

                        // ==================================================
                        // CATEGORY NAME
                        // ==================================================
                        Expanded(
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected ? textPrimary : textSecondary,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ========================================================
          // SLIDE HINT
          // ========================================================
          Row(
            children: [
              Icon(Icons.swipe_rounded, size: 14, color: textSecondary),

              const SizedBox(width: 5),

              Text(
                'Swipe to see more categories',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FREQUENCY SELECTOR
  // ============================================================

  Widget _buildFrequencySelector({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // FREQUENCY TABS
        // ========================================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: secondarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              for (final frequency in _frequencies)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFrequency = frequency;

                        if (frequency != 'Custom') {
                          _selectedDays.clear();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _selectedFrequency == frequency
                            ? surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: _selectedFrequency == frequency
                            ? Border.all(color: border)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _frequencyIcon(frequency),
                            size: 15,
                            color: _selectedFrequency == frequency
                                ? AppColors.productivityAccent
                                : textSecondary,
                          ),

                          const SizedBox(width: 5),

                          Flexible(
                            child: Text(
                              frequency,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _selectedFrequency == frequency
                                    ? textPrimary
                                    : textSecondary,
                                fontSize: 12,
                                fontWeight: _selectedFrequency == frequency
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ========================================================
        // CUSTOM DAYS
        // ========================================================
        if (_selectedFrequency == 'Custom') ...[
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.productivityAccent.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 17,
                        color: AppColors.productivityAccent,
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        'Choose days',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    Text(
                      '${_selectedDays.length}/7',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ------------------------------------------------
                // DAY SELECTOR
                // ------------------------------------------------
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = _days[index];

                      final selected = _selectedDays.contains(day);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedDays.remove(day);
                            } else {
                              _selectedDays.add(day);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 54,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.productivityAccent.withValues(
                                    alpha: 0.10,
                                  )
                                : secondarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppColors.productivityAccent
                                  : border,
                              width: selected ? 1.2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // --------------------------------
                              // CHECK BOX [ ]
                              // --------------------------------
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.productivityAccent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.productivityAccent
                                        : textSecondary,
                                  ),
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),

                              const SizedBox(height: 4),

                              Text(
                                day,
                                style: TextStyle(
                                  color: selected ? textPrimary : textSecondary,
                                  fontSize: 10,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // ------------------------------------------------
                // SELECT ALL / CLEAR
                // ------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDays.addAll(_days);
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: AppColors.productivityAccent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Select all',
                              style: TextStyle(
                                color: AppColors.productivityAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDays.clear();
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10,
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
          ),
        ],
      ],
    );
  }

  // ============================================================
  // REMINDER CARD
  // ============================================================

  Widget _buildReminderCard({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: secondarySurface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: _hasReminder
                  ? AppColors.productivityAccent
                  : textSecondary,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily reminder',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _hasReminder
                      ? 'Reminder at ${_formatTime(context)}'
                      : 'Set a time to remind yourself',
                  style: TextStyle(color: textMuted, fontSize: 10),
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value: _hasReminder,
            activeTrackColor: AppColors.productivityAccent,
            onChanged: (value) async {
              if (!value) {
                setState(() {
                  _hasReminder = false;
                });
                return;
              }

              await _pickTime();
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTES FIELD
  // ============================================================

  Widget _buildNotesField({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return TextField(
      controller: _notesController,
      maxLines: 4,
      style: TextStyle(color: textPrimary, fontSize: 12, height: 1.4),
      decoration: InputDecoration(
        hintText: 'Add some notes about this habit...',
        hintStyle: TextStyle(color: textMuted, fontSize: 12),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.productivityAccent,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CREATE BUTTON
  // ============================================================

  Widget _buildCreateButton({required bool isDark}) {
    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _createHabit,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: inverseText,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_task_rounded, size: 18),
            SizedBox(width: 8),
            Text(
              'Create Habit',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CANCEL BUTTON
  // ============================================================

  Widget _buildCancelButton({required bool isDark}) {
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Cancel',
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
