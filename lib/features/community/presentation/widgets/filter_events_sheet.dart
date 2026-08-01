import 'package:flutter/material.dart';
import '../../../../design_system/colors/app_colors.dart';

class FilterEventsSheet extends StatefulWidget {
  const FilterEventsSheet({super.key});

  @override
  State<FilterEventsSheet> createState() => _FilterEventsSheetState();
}

class _FilterEventsSheetState extends State<FilterEventsSheet> {
  String selectedDate = 'Upcoming';
  final Set<String> selectedCategories = {'Workshop'};
  String selectedMode = 'All';
  String selectedPrice = 'All';

  final List<String> dateOptions = ['Today', 'This Week', 'This Month', 'Upcoming'];
  final List<Map<String, dynamic>> categoryOptions = [
    {'name': 'Workshop', 'icon': Icons.tune},
    {'name': 'Seminar', 'icon': Icons.groups_outlined},
    {'name': 'Competition', 'icon': Icons.emoji_events_outlined},
    {'name': 'Hackathon', 'icon': Icons.terminal_outlined},
    {'name': 'Volunteer', 'icon': Icons.favorite_border},
    {'name': 'Career', 'icon': Icons.work_outline},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfacePrimary = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final unselectedBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.lightBgSecondary;
    final unselectedBorder = isDark ? Colors.white10 : AppColors.lightBorderSubtle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter Events",
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedDate = 'Upcoming';
                      selectedCategories.clear();
                      selectedCategories.add('Workshop');
                      selectedMode = 'All';
                      selectedPrice = 'All';
                    });
                  },
                  child: const Text(
                    "Reset",
                    style: TextStyle(color: AppColors.communityAccent, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Date Section
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: textSecondary, size: 18),
                const SizedBox(width: 8),
                Text("Date", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: dateOptions.map((opt) {
                final isSelected = selectedDate == opt;
                return GestureDetector(
                  onTap: () => setState(() => selectedDate = opt),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                          : unselectedBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF8B5CF6) : unselectedBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? const Color(0xFF8B5CF6) : textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          opt,
                          style: TextStyle(
                            color: isSelected ? (isDark ? Colors.white : AppColors.lightTextPrimary) : textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 2. Category Section
            Row(
              children: [
                Icon(Icons.grid_view, color: textSecondary, size: 18),
                const SizedBox(width: 8),
                Text("Category", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: categoryOptions.length,
              itemBuilder: (context, i) {
                final item = categoryOptions[i];
                final catName = item['name'] as String;
                final isSelected = selectedCategories.contains(catName);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedCategories.remove(catName);
                      } else {
                        selectedCategories.add(catName);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                          : unselectedBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF8B5CF6) : unselectedBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : item['icon'] as IconData,
                          color: isSelected ? const Color(0xFF8B5CF6) : textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          catName,
                          style: TextStyle(
                            color: isSelected ? (isDark ? Colors.white : AppColors.lightTextPrimary) : textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 3. Mode Section
            Row(
              children: [
                Icon(Icons.tune, color: textSecondary, size: 18),
                const SizedBox(width: 8),
                Text("Mode", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: ['All', 'Online', 'Offline'].map((m) {
                final isSelected = selectedMode == m;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedMode = m),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                            : unselectedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF8B5CF6) : unselectedBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          m,
                          style: TextStyle(
                            color: isSelected ? (isDark ? Colors.white : AppColors.lightTextPrimary) : textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 4. Price Section
            Row(
              children: [
                Icon(Icons.sell_outlined, color: textSecondary, size: 18),
                const SizedBox(width: 8),
                Text("Price", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: ['All', 'Free', 'Paid'].map((p) {
                final isSelected = selectedPrice == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedPrice = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                            : unselectedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF8B5CF6) : unselectedBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          p,
                          style: TextStyle(
                            color: isSelected ? (isDark ? Colors.white : AppColors.lightTextPrimary) : textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.communityAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Apply Filters",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
