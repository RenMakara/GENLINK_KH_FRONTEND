import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../../domain/models/story_template_model.dart';

class StoryTemplatePickerSheet extends StatefulWidget {
  final StoryTemplateConfig? selectedTemplate;
  final ValueChanged<StoryTemplateConfig> onSelectTemplate;

  const StoryTemplatePickerSheet({
    super.key,
    this.selectedTemplate,
    required this.onSelectTemplate,
  });

  static Future<StoryTemplateConfig?> show(
    BuildContext context, {
    StoryTemplateConfig? currentTemplate,
    required ValueChanged<StoryTemplateConfig> onSelect,
  }) {
    return showModalBottomSheet<StoryTemplateConfig>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StoryTemplatePickerSheet(
        selectedTemplate: currentTemplate,
        onSelectTemplate: onSelect,
      ),
    );
  }

  @override
  State<StoryTemplatePickerSheet> createState() =>
      _StoryTemplatePickerSheetState();
}

class _StoryTemplatePickerSheetState extends State<StoryTemplatePickerSheet> {
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Single',
    'Two Photos',
    'Three Photos',
    'Four Photos',
    'Photo + Text',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = _selectedCategory == 'All'
        ? storyTemplatePresets
        : storyTemplatePresets
            .where((t) => t.category == _selectedCategory)
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2E), width: 1.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag Handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header Title Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Story Templates",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Choose aesthetic layout for your story",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Category Filter Chips ──
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSel = _selectedCategory == cat;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSel
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSel
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSel ? Colors.black : Colors.white70,
                        fontWeight:
                            isSel ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // ── Templates Grid ──
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.25,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredTemplates.length,
              itemBuilder: (context, i) {
                final tmpl = filteredTemplates[i];
                final isSel = widget.selectedTemplate?.id == tmpl.id;

                return GestureDetector(
                  onTap: () {
                    widget.onSelectTemplate(tmpl);
                    Navigator.pop(context, tmpl);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.communityAccent.withValues(alpha: 0.15)
                          : const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSel
                            ? AppColors.communityAccent
                            : Colors.white.withValues(alpha: 0.10),
                        width: isSel ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.communityAccent
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                tmpl.icon,
                                color: isSel ? Colors.white : Colors.white70,
                                size: 20,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.communityAccent.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tmpl.hasTextSlot
                                    ? "1 Photo + Text"
                                    : "${tmpl.slotCount} ${tmpl.slotCount == 1 ? 'Photo' : 'Photos'}",
                                style: TextStyle(
                                  color: isSel ? Colors.white : Colors.white60,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tmpl.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tmpl.hasTextSlot
                                  ? "1 Photo + Text • ${tmpl.description}"
                                  : "${tmpl.slotCount} ${tmpl.slotCount == 1 ? 'Photo' : 'Photos'} • ${tmpl.description}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
