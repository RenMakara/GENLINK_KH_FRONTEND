import 'package:flutter/material.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final motivationController = TextEditingController();
  String selectedGoalType = 'Personal';

  DateTime? selectedDeadline;

  bool communitySupport = false;

  final List<TextEditingController> milestoneControllers = [
    TextEditingController(text: 'Complete online course'),
    TextEditingController(text: 'Build first project'),
  ];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    motivationController.dispose();

    for (final controller in milestoneControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  const AppBackButton(),

                  const SizedBox(width: 12),

                  Text(
                    'New Goal',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal Type',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        for (final type in ['Personal', 'Career', 'Skill'])
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: type == 'Skill' ? 0 : 8,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedGoalType = type;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selectedGoalType == type
                                        ? textPrimary
                                        : secondarySurface,
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: selectedGoalType == type
                                          ? textPrimary
                                          : border,
                                    ),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      color: selectedGoalType == type
                                          ? inverseText
                                          : textSecondary,
                                      fontSize: 12,
                                      fontWeight: selectedGoalType == type
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Goal Title',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextField(
                      controller: titleController,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What do you want to achieve?',
                        hintStyle: TextStyle(
                          color: textMuted,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: textPrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Description',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: TextStyle(color: textPrimary, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Describe your goal...',
                        hintStyle: TextStyle(color: textMuted, fontSize: 12),
                        filled: true,
                        fillColor: secondarySurface,
                        contentPadding: const EdgeInsets.all(13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: textPrimary),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Deadline',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();

                        final selected = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline ?? now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 10),
                        );

                        if (selected != null && mounted) {
                          setState(() {
                            selectedDeadline = selected;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: secondarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 15,
                              color: textMuted,
                            ),

                            const SizedBox(width: 9),

                            Expanded(
                              child: Text(
                                selectedDeadline == null
                                    ? 'Select target date'
                                    : '${selectedDeadline!.day.toString().padLeft(2, '0')}/'
                                          '${selectedDeadline!.month.toString().padLeft(2, '0')}/'
                                          '${selectedDeadline!.year}',
                                style: TextStyle(
                                  color: selectedDeadline == null
                                      ? textMuted
                                      : textPrimary,
                                  fontSize: 12,
                                  fontWeight: selectedDeadline == null
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                ),
                              ),
                            ),

                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Text(
                          'Milestones',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const Spacer(),

                        Text(
                          '${milestoneControllers.length}',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          for (
                            int i = 0;
                            i < milestoneControllers.length;
                            i++
                          ) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                13,
                                10,
                                10,
                                10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.radio_button_unchecked_rounded,
                                    size: 17,
                                    color: textMuted,
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: TextField(
                                      controller: milestoneControllers[i],
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 12,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Milestone...',
                                        hintStyle: TextStyle(
                                          color: textMuted,
                                          fontSize: 12,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: milestoneControllers.length > 1
                                        ? () {
                                            final controller =
                                                milestoneControllers.removeAt(
                                                  i,
                                                );

                                            controller.dispose();

                                            setState(() {});
                                          }
                                        : null,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 17,
                                      color: milestoneControllers.length > 1
                                          ? textMuted
                                          : border,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (i < milestoneControllers.length - 1)
                              Divider(
                                height: 1,
                                thickness: 0.7,
                                indent: 13,
                                endIndent: 13,
                                color: border,
                              ),
                          ],

                          Divider(height: 1, thickness: 0.7, color: border),

                          InkWell(
                            onTap: () {
                              setState(() {
                                milestoneControllers.add(
                                  TextEditingController(),
                                );
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 17,
                                    color: textMuted,
                                  ),

                                  const SizedBox(width: 9),

                                  Text(
                                    'Add milestone',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Motivation Note',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextField(
                      controller: motivationController,
                      maxLines: 3,
                      style: TextStyle(color: textPrimary, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'What drives you toward this goal?',
                        hintStyle: TextStyle(color: textMuted, fontSize: 12),
                        filled: true,
                        fillColor: secondarySurface,
                        contentPadding: const EdgeInsets.all(13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: textPrimary),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: secondarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.people_outline_rounded,
                              size: 18,
                              color: textSecondary,
                            ),
                          ),

                          const SizedBox(width: 11),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Community Support',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  'Share with the GenLink community',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Switch(
                            value: communitySupport,
                            onChanged: (value) {
                              setState(() {
                                communitySupport = value;
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            activeThumbColor: textPrimary,
                            activeTrackColor: secondarySurface,
                            inactiveThumbColor: textMuted,
                            inactiveTrackColor: secondarySurface,
                            trackOutlineColor: WidgetStatePropertyAll(border),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a goal title'),
                              ),
                            );
                            return;
                          }

                          final newGoal = GoalModel(
                            category: selectedGoalType,
                            title: title,
                            progress: 0.0,
                            dueDate: selectedDeadline == null
                                ? 'No deadline'
                                : 'Due ${selectedDeadline!.day} '
                                      '${_monthName(selectedDeadline!.month)} '
                                      '${selectedDeadline!.year}',
                          );

                          Navigator.pop(context, newGoal);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: textPrimary,
                          foregroundColor: inverseText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Goal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

class GoalModel {
  final String category;
  final String title;
  final double progress;
  final String dueDate;

  GoalModel({
    required this.category,
    required this.title,
    required this.progress,
    required this.dueDate,
  });
}
