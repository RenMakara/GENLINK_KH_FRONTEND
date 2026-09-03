import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';

/// Habit Creation Screen for GenLink Productivity.
class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _titleController = TextEditingController();
  String _selectedFrequency = 'Every Day';
  String _selectedTimeOfDay = 'Morning';
  int _targetDays = 21;

  final _frequencies = ['Every Day', 'Weekdays', '3 Days / Week', 'Weekends'];
  final _timesOfDay = ['Morning', 'Afternoon', 'Evening', 'Anytime'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'New Habit',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isNotEmpty) {
                  Get.back(result: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.squircle),
                ),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Habit Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g., Read 15 mins, Exercise, Meditate',
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Frequency Selector
            Text(
              'Frequency',
              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _frequencies.map((freq) {
                final isSel = _selectedFrequency == freq;
                return ChoiceChip(
                  label: Text(freq),
                  selected: isSel,
                  onSelected: (_) => setState(() => _selectedFrequency = freq),
                  selectedColor: isDark ? Colors.white : Colors.black87,
                  backgroundColor: surfaceSecondary,
                  labelStyle: TextStyle(
                    color: isSel
                        ? (isDark ? Colors.black : Colors.white)
                        : textSecondary,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(color: border),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Time of Day
            Text(
              'Time of Day',
              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Row(
              children: _timesOfDay.map((tod) {
                final isSel = _selectedTimeOfDay == tod;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTimeOfDay = tod),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel
                              ? (isDark ? Colors.white : Colors.black87)
                              : surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          tod,
                          style: TextStyle(
                            color: isSel
                                ? (isDark ? Colors.black : Colors.white)
                                : textSecondary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Target Streak Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.growthAccent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: AppColors.growthAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Streak', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('$_targetDays days to form habit', style: TextStyle(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: _targetDays,
                    dropdownColor: surface,
                    underline: const SizedBox.shrink(),
                    items: [7, 14, 21, 30, 60, 100].map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text('$d days', style: TextStyle(color: textPrimary, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _targetDays = val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
