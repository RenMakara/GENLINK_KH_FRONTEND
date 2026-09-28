import 'dart:io';
import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/images/app_cached_image.dart';
import '../../domain/models/story_template_model.dart';

File _resolveMediaFile(String rawPath) {
  final clean = rawPath.replaceAll(RegExp(r'^file://'), '');
  return File(clean);
}

class StoryTemplatePickerSheet extends StatefulWidget {
  final StoryTemplateConfig? selectedTemplate;
  final List<String> initialMediaPaths;
  final ValueChanged<StoryTemplateConfig>? onSelectTemplate;

  const StoryTemplatePickerSheet({
    super.key,
    this.selectedTemplate,
    this.initialMediaPaths = const [],
    this.onSelectTemplate,
  });

  static Future<StoryTemplateConfig?> show(
    BuildContext context, {
    StoryTemplateConfig? currentTemplate,
    List<String>? initialMediaPaths,
    ValueChanged<StoryTemplateConfig>? onSelect,
  }) {
    return showModalBottomSheet<StoryTemplateConfig>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (ctx) => StoryTemplatePickerSheet(
        selectedTemplate: currentTemplate,
        initialMediaPaths: initialMediaPaths ?? const [],
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
    'Five Photos',
    'Six Photos',
    'Photo + Text',
  ];

  List<StoryTemplateConfig> _getFilteredTemplates() {
    return storyTemplatePresets.where((t) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Two Photos' || _selectedCategory == '2 Photos') {
        return t.category == 'Two Photos' || t.slotCount == 2;
      }
      if (_selectedCategory == 'Three Photos' || _selectedCategory == '3 Photos') {
        return t.category == 'Three Photos' || t.slotCount == 3;
      }
      if (_selectedCategory == 'Four Photos' || _selectedCategory == '4 Photos') {
        return t.category == 'Four Photos' || t.slotCount == 4;
      }
      if (_selectedCategory == 'Five Photos' || _selectedCategory == '5 Photos') {
        return t.category == 'Five Photos' || t.slotCount == 5;
      }
      if (_selectedCategory == 'Six Photos' || _selectedCategory == '6 Photos') {
        return t.category == 'Six Photos' || t.slotCount == 6;
      }
      if (_selectedCategory == 'Single' || _selectedCategory == '1 Photo') {
        return t.category == 'Single' || t.slotCount == 1;
      }
      if (_selectedCategory == 'Photo + Text') {
        return t.category == 'Photo + Text' || t.hasTextSlot;
      }
      return t.category == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final filteredTemplates = _getFilteredTemplates();

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.68,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF141416),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFF2A2A2E), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.dashboard_customize_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Story Templates",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
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
                        color: Colors.white.withValues(alpha: 0.08),
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
                    behavior: HitTestBehavior.opaque,
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

            const SizedBox(height: 12),

            Flexible(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filteredTemplates.length,
                itemBuilder: (context, i) {
                  final tmpl = filteredTemplates[i];
                  final isSel = widget.selectedTemplate?.id == tmpl.id;

                  return _TemplatePickerCard(
                    template: tmpl,
                    mediaPaths: widget.initialMediaPaths,
                    isSelected: isSel,
                    onTap: () {
                      widget.onSelectTemplate?.call(tmpl);
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, tmpl);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePickerCard extends StatelessWidget {
  final StoryTemplateConfig template;
  final List<String> mediaPaths;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplatePickerCard({
    required this.template,
    this.mediaPaths = const [],
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF222228)
              : const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              flex: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF0E0E10),
                  padding: const EdgeInsets.all(5),
                  child: Center(
                    child: _TemplateMiniaturePreview(
                      template: template,
                      mediaPaths: mediaPaths,
                      isSelected: isSelected,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            Expanded(
              flex: 28,
              child: Center(
                child: Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateMiniaturePreview extends StatelessWidget {
  final StoryTemplateConfig template;
  final List<String> mediaPaths;
  final bool isSelected;

  const _TemplateMiniaturePreview({
    required this.template,
    this.mediaPaths = const [],
    this.isSelected = false,
  });

  Widget _buildSlot(int slotIndex, {double radius = 4.0}) {
    final hasImage = slotIndex < mediaPaths.length &&
        mediaPaths[slotIndex].trim().isNotEmpty;
    final path = hasImage ? mediaPaths[slotIndex] : null;

    if (hasImage && path != null) {
      Widget img;
      if (path.startsWith('assets/')) {
        img = Image.asset(path, fit: BoxFit.cover);
      } else if (path.startsWith('http://') || path.startsWith('https://')) {
        img = AppCachedImage(imageUrl: path, fit: BoxFit.cover, memCacheWidth: 200);
      } else {
        img = Image.file(_resolveMediaFile(path), fit: BoxFit.cover);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox.expand(child: img),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: isSelected
              ? [
                  AppColors.communityAccent.withValues(alpha: 0.35),
                  AppColors.communityAccent.withValues(alpha: 0.15),
                ]
              : [
                  const Color(0xFF28282E),
                  const Color(0xFF1D1D22),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isSelected
              ? AppColors.communityAccent.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: isSelected
              ? AppColors.communityAccent.withValues(alpha: 0.8)
              : Colors.white24,
          size: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (template.layoutType) {
      case StoryTemplateLayoutType.singlePolaroid:
        return AspectRatio(
          aspectRatio: 0.78,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: _buildSlot(0, radius: 3),
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(
                  flex: 20,
                  child: Center(
                    child: Container(
                      height: 2,
                      width: 24,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case StoryTemplateLayoutType.singleCard:
        return AspectRatio(
          aspectRatio: 0.75,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.communityAccent
                    : Colors.white24,
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildSlot(0, radius: 7),
            ),
          ),
        );

      case StoryTemplateLayoutType.singleFramed:
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.communityAccent
                  : Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: _buildSlot(0, radius: 5),
          ),
        );

      case StoryTemplateLayoutType.splitVertical:
        return Column(
          children: [
            Expanded(child: _buildSlot(0, radius: 5)),
            const SizedBox(height: 3),
            Expanded(child: _buildSlot(1, radius: 5)),
          ],
        );

      case StoryTemplateLayoutType.splitHorizontal:
        return Row(
          children: [
            Expanded(child: _buildSlot(0, radius: 5)),
            const SizedBox(width: 3),
            Expanded(child: _buildSlot(1, radius: 5)),
          ],
        );

      case StoryTemplateLayoutType.twoDiptych:
        return Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: _buildSlot(0, radius: 6),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: _buildSlot(1, radius: 6),
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.threeHeroBottom:
        return Column(
          children: [
            Expanded(flex: 54, child: _buildSlot(0, radius: 5)),
            const SizedBox(height: 3),
            Expanded(
              flex: 46,
              child: Row(
                children: [
                  Expanded(child: _buildSlot(1, radius: 4)),
                  const SizedBox(width: 3),
                  Expanded(child: _buildSlot(2, radius: 4)),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.threeHeroLeft:
        return Row(
          children: [
            Expanded(flex: 50, child: _buildSlot(0, radius: 5)),
            const SizedBox(width: 3),
            Expanded(
              flex: 50,
              child: Column(
                children: [
                  Expanded(child: _buildSlot(1, radius: 4)),
                  const SizedBox(height: 3),
                  Expanded(child: _buildSlot(2, radius: 4)),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.threeColumns:
        return Row(
          children: [
            Expanded(child: _buildSlot(0, radius: 4)),
            const SizedBox(width: 3),
            Expanded(child: _buildSlot(1, radius: 4)),
            const SizedBox(width: 3),
            Expanded(child: _buildSlot(2, radius: 4)),
          ],
        );

      case StoryTemplateLayoutType.fourGrid:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildSlot(0, radius: 4)),
                  const SizedBox(width: 3),
                  Expanded(child: _buildSlot(1, radius: 4)),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildSlot(2, radius: 4)),
                  const SizedBox(width: 3),
                  Expanded(child: _buildSlot(3, radius: 4)),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.fourHeroStrip:
        return Column(
          children: [
            Expanded(flex: 65, child: _buildSlot(0, radius: 5)),
            const SizedBox(height: 3),
            Expanded(
              flex: 35,
              child: Row(
                children: [
                  Expanded(child: _buildSlot(1, radius: 3)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildSlot(2, radius: 3)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildSlot(3, radius: 3)),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.fiveHeroGrid:
        return Column(
          children: [
            Expanded(flex: 50, child: _buildSlot(0, radius: 4)),
            const SizedBox(height: 3),
            Expanded(
              flex: 50,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildSlot(1, radius: 2)),
                        const SizedBox(width: 2),
                        Expanded(child: _buildSlot(2, radius: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildSlot(3, radius: 2)),
                        const SizedBox(width: 2),
                        Expanded(child: _buildSlot(4, radius: 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.fiveHeroLeft:
        return Row(
          children: [
            Expanded(flex: 50, child: _buildSlot(0, radius: 4)),
            const SizedBox(width: 3),
            Expanded(
              flex: 50,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildSlot(1, radius: 2)),
                        const SizedBox(width: 2),
                        Expanded(child: _buildSlot(2, radius: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildSlot(3, radius: 2)),
                        const SizedBox(width: 2),
                        Expanded(child: _buildSlot(4, radius: 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.fiveSplit:
        return Column(
          children: [
            Expanded(
              flex: 50,
              child: Row(
                children: [
                  Expanded(child: _buildSlot(0, radius: 3)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildSlot(1, radius: 3)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              flex: 50,
              child: Row(
                children: [
                  Expanded(child: _buildSlot(2, radius: 2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildSlot(3, radius: 2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildSlot(4, radius: 2)),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.sixGrid:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildSlot(0, radius: 2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildSlot(1, radius: 2)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildSlot(2, radius: 2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildSlot(3, radius: 2)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildSlot(4, radius: 2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildSlot(5, radius: 2)),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.sixHeroGrid:
        return Column(
          children: [
            Expanded(
              flex: 44,
              child: Row(
                children: [
                  Expanded(child: _buildSlot(0, radius: 3)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildSlot(1, radius: 3)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              flex: 56,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildSlot(2, radius: 2)),
                        const SizedBox(width: 2),
                        Expanded(child: _buildSlot(3, radius: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildSlot(4, radius: 2)),
                        const SizedBox(width: 2),
                        Expanded(child: _buildSlot(5, radius: 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.sixMosaic:
        return Row(
          children: [
            Expanded(
              flex: 50,
              child: Column(
                children: [
                  Expanded(flex: 60, child: _buildSlot(0, radius: 3)),
                  const SizedBox(height: 2),
                  Expanded(flex: 40, child: _buildSlot(1, radius: 3)),
                ],
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: 50,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildSlot(2, radius: 2)),
                        const SizedBox(width: 2),
                        Expanded(child: _buildSlot(3, radius: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildSlot(4, radius: 2)),
                        const SizedBox(width: 2),
                        Expanded(child: _buildSlot(5, radius: 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.photoTextPolaroid:
        return AspectRatio(
          aspectRatio: 0.78,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 76,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: _buildSlot(0, radius: 3),
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(
                  flex: 24,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 2,
                          width: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1917).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(1),
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

      case StoryTemplateLayoutType.photoTextQuote:
        return Column(
          children: [
            Expanded(flex: 62, child: _buildSlot(0, radius: 5)),
            const SizedBox(height: 3),
            Expanded(
              flex: 38,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xF2161618),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.7,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: AppColors.communityAccent,
                      size: 11,
                    ),
                    SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.horizontal_rule_rounded,
                            color: Colors.white38, size: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case StoryTemplateLayoutType.photoTextMagazine:
        return Column(
          children: [
            Expanded(flex: 66, child: _buildSlot(0, radius: 5)),
            const SizedBox(height: 3),
            Expanded(
              flex: 34,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xF218181B),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.7,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.communityAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        "CAMPUS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 2,
                      width: 26,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}
