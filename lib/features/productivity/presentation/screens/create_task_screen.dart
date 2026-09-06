import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';

/// Task / To-Do Creation Screen for GenLink Productivity.
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'Study';
  TimeOfDay? _dueTime;

  final _categories = ['Study', 'Project', 'Personal', 'Work', 'Health'];
  final _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
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
          'New Task',
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
            // Title Input
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
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Description Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border),
              ),
              child: TextField(
                controller: _descController,
                maxLines: 3,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add details or notes (optional)',
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Category Selector
            Text(
              'Category',
              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: isDark ? Colors.white : Colors.black87,
                      backgroundColor: surfaceSecondary,
                      labelStyle: TextStyle(
                        color: isSel
                            ? (isDark ? Colors.black : Colors.white)
                            : textSecondary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(color: border),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Priority Selector
            Text(
              'Priority',
              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Row(
              children: _priorities.map((pri) {
                final isSel = _selectedPriority == pri;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPriority = pri),
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
                          pri,
                          style: TextStyle(
                            color: isSel
                                ? (isDark ? Colors.black : Colors.white)
                                : textSecondary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Due Time Tile
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              tileColor: surfaceSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(color: border),
              ),
              leading: const Icon(Icons.access_time_rounded, color: AppColors.productivityAccent),
              title: Text('Due Time', style: TextStyle(color: textPrimary, fontSize: 14)),
              trailing: Text(
                _dueTime != null ? _dueTime!.format(context) : 'Set time',
                style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() => _dueTime = picked);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
