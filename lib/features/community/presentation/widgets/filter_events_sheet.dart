import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../controllers/community_controller.dart';

class FilterEventsSheet extends StatefulWidget {
  const FilterEventsSheet({super.key});

  @override
  State<FilterEventsSheet> createState() => _FilterEventsSheetState();
}

class _FilterEventsSheetState extends State<FilterEventsSheet> {
  late String selectedDate;
  late Set<String> selectedCategories;
  late String selectedMode;
  late String selectedPrice;

  CommunityController? _controller;

  final List<String> dateOptions = [
    'All',
    'Today',
    'This Week',
    'This Month',
    'Upcoming',
  ];

  final List<String> modeOptions = [
    'All',
    'In person',
    'Online',
  ];

  final List<String> priceOptions = [
    'All',
    'Free',
    'Paid',
  ];

  final List<Map<String, dynamic>> categoryOptions = [
    {'name': 'Workshop', 'icon': Icons.tune},
    {'name': 'Seminar', 'icon': Icons.groups_outlined},
    {'name': 'Competition', 'icon': Icons.emoji_events_outlined},
    {'name': 'Hackathon', 'icon': Icons.terminal_outlined},
    {'name': 'Volunteer', 'icon': Icons.favorite_border},
    {'name': 'Career', 'icon': Icons.work_outline},
  ];

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CommunityController>()) {
      _controller = Get.find<CommunityController>();
      selectedDate = _controller!.selectedEventDate.value.isEmpty
          ? 'All'
          : _controller!.selectedEventDate.value;
      selectedCategories = Set<String>.from(_controller!.selectedEventCategories);
      selectedMode = _controller!.selectedEventMode.value.isEmpty
          ? 'All'
          : _controller!.selectedEventMode.value;
      selectedPrice = _controller!.selectedEventPrice.value.isEmpty
          ? 'All'
          : _controller!.selectedEventPrice.value;
    } else {
      selectedDate = 'All';
      selectedCategories = {};
      selectedMode = 'All';
      selectedPrice = 'All';
    }
  }

  void _reset() {
    setState(() {
      selectedDate = 'All';
      selectedCategories.clear();
      selectedMode = 'All';
      selectedPrice = 'All';
    });
    _controller?.resetEventFilter();
  }

  void _apply() {
    _controller?.applyEventFilter(
      date: selectedDate,
      categories: selectedCategories,
      mode: selectedMode,
      price: selectedPrice,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfacePrimary = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title Header & Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'community.filterEvents'.tr,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'community.reset'.tr,
                    style: const TextStyle(
                      color: AppColors.communityAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Format / Event Type (In Person vs Online)
                    _buildSectionHeader(
                      icon: Icons.place_outlined,
                      title: 'community.format'.tr.isNotEmpty &&
                              'community.format'.tr != 'community.format'
                          ? 'community.format'.tr
                          : 'Format',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 8),
                    _buildSingleSelectRow(
                      options: modeOptions,
                      selected: selectedMode,
                      onSelect: (val) => setState(() => selectedMode = val),
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      surfaceSecondary: surfaceSecondary,
                      borderSubtle: borderSubtle,
                    ),

                    const SizedBox(height: 18),

                    // 2. Date Range
                    _buildSectionHeader(
                      icon: Icons.calendar_today_outlined,
                      title: 'community.dateRange'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 8),
                    _buildSingleSelectWrap(
                      options: dateOptions,
                      selected: selectedDate,
                      onSelect: (val) => setState(() => selectedDate = val),
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      surfaceSecondary: surfaceSecondary,
                      borderSubtle: borderSubtle,
                    ),

                    const SizedBox(height: 18),

                    // 3. Category Section
                    _buildSectionHeader(
                      icon: Icons.grid_view_rounded,
                      title: 'community.category'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 8),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : surfaceSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black)
                                    : borderSubtle,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : item['icon'] as IconData,
                                  color: isSelected
                                      ? (isDark ? Colors.black : Colors.white)
                                      : textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    catName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? (isDark ? Colors.black : Colors.white)
                                          : textSecondary,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // 4. Price Section
                    _buildSectionHeader(
                      icon: Icons.monetization_on_outlined,
                      title: 'community.price'.tr.isNotEmpty &&
                              'community.price'.tr != 'community.price'
                          ? 'community.price'.tr
                          : 'Price',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 8),
                    _buildSingleSelectRow(
                      options: priceOptions,
                      selected: selectedPrice,
                      onSelect: (val) => setState(() => selectedPrice = val),
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      surfaceSecondary: surfaceSecondary,
                      borderSubtle: borderSubtle,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.communityAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'community.applyFilters'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      children: [
        Icon(icon, color: textMuted, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleSelectRow({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color surfaceSecondary,
    required Color borderSubtle,
  }) {
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : borderSubtle,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleSelectWrap({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color surfaceSecondary,
    required Color borderSubtle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : borderSubtle,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
