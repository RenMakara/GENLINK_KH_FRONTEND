import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../../domain/models/story_template_model.dart';

File _resolveMediaFile(String rawPath) {
  final clean = rawPath.replaceAll(RegExp(r'^file://'), '');
  return File(clean);
}

class StoryTemplateCanvas extends StatelessWidget {
  final StoryTemplateConfig template;
  final List<StoryTemplateSlot> slots;
  final bool isInteractive;
  final int? selectedSlotIndex;
  final ValueChanged<int>? onSelectSlot;
  final ValueChanged<int>? onTapSlot;
  final void Function(int slotIndex, double scale, Offset offset, double rotation)?
      onUpdateSlot;
  final ValueChanged<int>? onClearSlot;
  final ValueChanged<int>? onReplaceSlot;
  final ValueChanged<String>? onEditText;
  final String? customText;

  const StoryTemplateCanvas({
    super.key,
    required this.template,
    required this.slots,
    this.isInteractive = false,
    this.selectedSlotIndex,
    this.onSelectSlot,
    this.onTapSlot,
    this.onUpdateSlot,
    this.onClearSlot,
    this.onReplaceSlot,
    this.onEditText,
    this.customText,
  });

  StoryTemplateSlot _getSlot(int index) {
    if (index < slots.length) {
      return slots[index];
    }
    return StoryTemplateSlot(id: 'slot_$index');
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final topSafe = (mediaQuery?.padding.top ?? 0.0) > 0
        ? (mediaQuery!.padding.top + 52.0)
        : 58.0;
    final bottomSafe = isInteractive
        ? ((mediaQuery?.padding.bottom ?? 0.0) > 0
            ? (mediaQuery!.padding.bottom + 155.0)
            : 160.0)
        : ((mediaQuery?.padding.bottom ?? 0.0) > 0
            ? (mediaQuery!.padding.bottom + 72.0)
            : 78.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final availableHeight =
            (height - topSafe - bottomSafe).clamp(200.0, height);

        return SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: EdgeInsets.only(
              top: topSafe,
              bottom: bottomSafe,
              left: 12,
              right: 12,
            ),
            child: _buildLayout(context, width - 24, availableHeight),
          ),
        );
      },
    );
  }

  Widget _buildSlotBox(int index) {
    return _TemplateSlotBox(
      slot: _getSlot(index),
      slotIndex: index,
      isInteractive: isInteractive,
      isSelected: selectedSlotIndex == index,
      onSelectSlot: onSelectSlot,
      onTapSlot: onTapSlot,
      onUpdateSlot: onUpdateSlot,
      onClearSlot: onClearSlot,
      onReplaceSlot: onReplaceSlot,
    );
  }

  Widget _buildLayout(BuildContext context, double width, double height) {
    switch (template.layoutType) {
      case StoryTemplateLayoutType.singlePolaroid:
        return _buildSinglePolaroid(context, width, height);

      case StoryTemplateLayoutType.singleCard:
        return _buildSingleCard(context, width, height);

      case StoryTemplateLayoutType.singleFramed:
        return _buildSingleFramed(context, width, height);

      case StoryTemplateLayoutType.splitVertical:
        return _buildSplitVertical(context, width, height);

      case StoryTemplateLayoutType.splitHorizontal:
        return _buildSplitHorizontal(context, width, height);

      case StoryTemplateLayoutType.twoDiptych:
        return _buildTwoDiptych(context, width, height);

      case StoryTemplateLayoutType.threeHeroBottom:
        return _buildThreeHeroBottom(context, width, height);

      case StoryTemplateLayoutType.threeHeroLeft:
        return _buildThreeHeroLeft(context, width, height);

      case StoryTemplateLayoutType.threeColumns:
        return _buildThreeColumns(context, width, height);

      case StoryTemplateLayoutType.fourGrid:
        return _buildFourGrid(context, width, height);

      case StoryTemplateLayoutType.fourHeroStrip:
        return _buildFourHeroStrip(context, width, height);

      case StoryTemplateLayoutType.fiveHeroGrid:
        return _buildFiveHeroGrid(context, width, height);

      case StoryTemplateLayoutType.fiveHeroLeft:
        return _buildFiveHeroLeft(context, width, height);

      case StoryTemplateLayoutType.fiveSplit:
        return _buildFiveSplit(context, width, height);

      case StoryTemplateLayoutType.sixGrid:
        return _buildSixGrid(context, width, height);

      case StoryTemplateLayoutType.sixHeroGrid:
        return _buildSixHeroGrid(context, width, height);

      case StoryTemplateLayoutType.sixMosaic:
        return _buildSixMosaic(context, width, height);

      case StoryTemplateLayoutType.photoTextPolaroid:
        return _buildPhotoTextPolaroid(context, width, height);

      case StoryTemplateLayoutType.photoTextQuote:
        return _buildPhotoTextQuote(context, width, height);

      case StoryTemplateLayoutType.photoTextMagazine:
        return _buildPhotoTextMagazine(context, width, height);
    }
  }


  Widget _buildSinglePolaroid(BuildContext context, double width, double height) {
    final cardWidth = (width * 0.86).clamp(240.0, 380.0);
    final cardHeight = (height * 0.80).clamp(320.0, 560.0);

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 82,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: const Color(0xFF1E1E22),
                  child: _buildSlotBox(0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 18,
              child: Center(
                child: Text(
                  customText ?? template.defaultText ?? "GenLink Moment ✨",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleCard(BuildContext context, double width, double height) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _buildSlotBox(0),
        ),
      ),
    );
  }

  Widget _buildSingleFramed(BuildContext context, double width, double height) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildSlotBox(0),
      ),
    );
  }


  Widget _buildSplitVertical(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildSlotBox(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitHorizontal(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildSlotBox(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoDiptych(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _buildSlotBox(0),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _buildSlotBox(1),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildThreeHeroBottom(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 46,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildSlotBox(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildSlotBox(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeHeroLeft(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            flex: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 50,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildSlotBox(1),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildSlotBox(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeColumns(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildSlotBox(1),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildSlotBox(2),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFourGrid(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildSlotBox(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildSlotBox(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildSlotBox(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildSlotBox(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourHeroStrip(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 66,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 34,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildSlotBox(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildSlotBox(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildSlotBox(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFiveHeroGrid(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 48,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildSlotBox(1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildSlotBox(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildSlotBox(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildSlotBox(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveHeroLeft(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            flex: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 50,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildSlotBox(1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildSlotBox(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildSlotBox(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildSlotBox(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveSplit(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 50,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildSlotBox(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildSlotBox(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 50,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(3),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSixGrid(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixHeroGrid(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 46,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildSlotBox(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildSlotBox(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 54,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSlotBox(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSlotBox(3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSlotBox(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSlotBox(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixMosaic(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            flex: 50,
            child: Column(
              children: [
                Expanded(
                  flex: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildSlotBox(0),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildSlotBox(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 50,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSlotBox(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSlotBox(3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSlotBox(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSlotBox(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPhotoTextPolaroid(
    BuildContext context,
    double width,
    double height,
  ) {
    final cardWidth = (width * 0.88).clamp(250.0, 390.0);
    final cardHeight = (height * 0.82).clamp(320.0, 580.0);

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 78,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: const Color(0xFF1E1E22),
                  child: _buildSlotBox(0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 22,
              child: GestureDetector(
                onTap: isInteractive
                    ? () => onEditText
                        ?.call(customText ?? template.defaultText ?? '')
                    : null,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Text(
                    customText ?? template.defaultText ?? "Today's highlight ✨",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1C1917),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTextQuote(
    BuildContext context,
    double width,
    double height,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          Expanded(
            flex: 62,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 38,
            child: GestureDetector(
              onTap: isInteractive
                  ? () => onEditText
                      ?.call(customText ?? template.defaultText ?? '')
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF2161618),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      color: AppColors.communityAccent,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customText ??
                          template.defaultText ??
                          '"Create your own sunshine." ☀️',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTextMagazine(
    BuildContext context,
    double width,
    double height,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Expanded(
            flex: 68,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _buildSlotBox(0),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 32,
            child: GestureDetector(
              onTap: isInteractive
                  ? () => onEditText
                      ?.call(customText ?? template.defaultText ?? '')
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF218181B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.communityAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "CAMPUS LIFE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customText ??
                          template.defaultText ??
                          "CAMPUS LIFE • ISSUE 01",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateSlotBox extends StatefulWidget {
  final StoryTemplateSlot slot;
  final int slotIndex;
  final bool isInteractive;
  final bool isSelected;
  final ValueChanged<int>? onSelectSlot;
  final ValueChanged<int>? onTapSlot;
  final void Function(int slotIndex, double scale, Offset offset, double rotation)?
      onUpdateSlot;
  final ValueChanged<int>? onClearSlot;
  final ValueChanged<int>? onReplaceSlot;

  const _TemplateSlotBox({
    required this.slot,
    required this.slotIndex,
    required this.isInteractive,
    this.isSelected = false,
    this.onSelectSlot,
    this.onTapSlot,
    this.onUpdateSlot,
    this.onClearSlot,
    this.onReplaceSlot,
  });

  @override
  State<_TemplateSlotBox> createState() => _TemplateSlotBoxState();
}

class _TemplateSlotBoxState extends State<_TemplateSlotBox> {
  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;
  Offset _baseFocalPoint = Offset.zero;

  Size? _naturalImageSize;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant _TemplateSlotBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot.mediaPath != widget.slot.mediaPath) {
      _resolveImageSize();
    }
  }

  ImageProvider _getImageProvider(String mediaPath) {
    if (mediaPath.startsWith('assets/')) {
      return AssetImage(mediaPath);
    } else if (mediaPath.startsWith('http://') ||
        mediaPath.startsWith('https://')) {
      return NetworkImage(mediaPath);
    } else {
      final file = _resolveMediaFile(mediaPath);
      if (file.existsSync() && file.lengthSync() > 0) {
        return FileImage(file);
      }
      return const AssetImage('assets/images/placeholder.png');
    }
  }

  void _resolveImageSize() {
    final mediaPath = widget.slot.mediaPath;
    if (mediaPath == null || mediaPath.trim().isEmpty) {
      _naturalImageSize = null;
      _cleanImageStream();
      return;
    }

    _cleanImageStream();
    try {
      final provider = _getImageProvider(mediaPath);
      final stream = provider.resolve(const ImageConfiguration());
      _imageStream = stream;
      _imageStreamListener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          final size = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          if (synchronousCall) {
            _naturalImageSize = size;
          } else if (mounted && _naturalImageSize != size) {
            setState(() {
              _naturalImageSize = size;
            });
          }
          // Clean up stream once size is resolved
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _cleanImageStream();
            }
          });
        },
        onError: (exception, stackTrace) {
          _cleanImageStream();
        },
      );
      stream.addListener(_imageStreamListener!);
    } catch (_) {
      _cleanImageStream();
    }
  }

  void _cleanImageStream() {
    final stream = _imageStream;
    final listener = _imageStreamListener;
    _imageStream = null;
    _imageStreamListener = null;
    if (stream != null && listener != null) {
      try {
        stream.removeListener(listener);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _cleanImageStream();
    super.dispose();
  }

  Widget _buildImageWidget(String mediaPath) {
    if (mediaPath.startsWith('assets/')) {
      return Image.asset(
        mediaPath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1E1E22),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 28),
          ),
        ),
      );
    } else if (mediaPath.startsWith('http://') ||
        mediaPath.startsWith('https://')) {
      return Image.network(
        mediaPath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1E1E22),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 28),
          ),
        ),
      );
    } else {
      final file = _resolveMediaFile(mediaPath);
      return Image.file(
        file,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1E1E22),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 28),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaPath = widget.slot.mediaPath;

    if (mediaPath == null || mediaPath.trim().isEmpty) {
      return GestureDetector(
        key: ValueKey('empty_slot_${widget.slotIndex}'),
        onTap: widget.isInteractive
            ? () => widget.onTapSlot?.call(widget.slotIndex)
            : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: const Color(0xFF141416),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                if (widget.isInteractive) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Tap to add photo",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth;
        final slotHeight = constraints.maxHeight;

        if (slotWidth <= 0 || slotHeight <= 0) {
          return const SizedBox.shrink();
        }

        final bool isSideways = ((widget.slot.rotation / 90).round() % 2 != 0);
        final double rawWidth =
            (_naturalImageSize != null && _naturalImageSize!.width > 0)
                ? _naturalImageSize!.width
                : slotWidth;
        final double rawHeight =
            (_naturalImageSize != null && _naturalImageSize!.height > 0)
                ? _naturalImageSize!.height
                : slotHeight;

        final double imgWidth = isSideways ? rawHeight : rawWidth;
        final double imgHeight = isSideways ? rawWidth : rawHeight;

        final double coverScale = math.max(
          slotWidth / imgWidth,
          slotHeight / imgHeight,
        );

        final double baseDisplayWidth = imgWidth * coverScale;
        final double baseDisplayHeight = imgHeight * coverScale;

        final double userScale = widget.slot.scale.clamp(1.0, 5.0);

        final double finalDisplayWidth = baseDisplayWidth * userScale;
        final double finalDisplayHeight = baseDisplayHeight * userScale;

        final double maxPanX =
            math.max(0.0, (finalDisplayWidth - slotWidth) / 2.0);
        final double maxPanY =
            math.max(0.0, (finalDisplayHeight - slotHeight) / 2.0);

        final double clampedOffsetX =
            widget.slot.offset.dx.clamp(-maxPanX, maxPanX);
        final double clampedOffsetY =
            widget.slot.offset.dy.clamp(-maxPanY, maxPanY);
        final Offset effectiveOffset = Offset(clampedOffsetX, clampedOffsetY);

        final double left =
            (slotWidth - finalDisplayWidth) / 2.0 + effectiveOffset.dx;
        final double top =
            (slotHeight - finalDisplayHeight) / 2.0 + effectiveOffset.dy;

        Widget imageContent = SizedBox(
          width: isSideways ? finalDisplayHeight : finalDisplayWidth,
          height: isSideways ? finalDisplayWidth : finalDisplayHeight,
          child: _buildImageWidget(mediaPath),
        );

        if (widget.slot.rotation != 0.0) {
          imageContent = RotatedBox(
            quarterTurns: (widget.slot.rotation / 90).round() % 4,
            child: imageContent,
          );
        }

        final Widget renderedSlotContent = Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: left,
              top: top,
              width: finalDisplayWidth,
              height: finalDisplayHeight,
              child: imageContent,
            ),
          ],
        );

        if (!widget.isInteractive) {
          return Container(
            color: Colors.black,
            child: ClipRect(
              child: renderedSlotContent,
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    widget.onSelectSlot?.call(widget.slotIndex);
                  },
                  onScaleStart: (details) {
                    _baseScale = widget.slot.scale.clamp(1.0, 5.0);
                    _baseOffset = widget.slot.offset;
                    _baseFocalPoint = details.focalPoint;
                    widget.onSelectSlot?.call(widget.slotIndex);
                  },
                  onScaleUpdate: (details) {
                    final newScale =
                        (_baseScale * details.scale).clamp(1.0, 5.0);
                    final delta = details.focalPoint - _baseFocalPoint;
                    final rawOffset = _baseOffset + delta;

                    final prospectiveDisplayWidth = baseDisplayWidth * newScale;
                    final prospectiveDisplayHeight =
                        baseDisplayHeight * newScale;
                    final prospectiveMaxX = math.max(
                        0.0, (prospectiveDisplayWidth - slotWidth) / 2.0);
                    final prospectiveMaxY = math.max(
                        0.0, (prospectiveDisplayHeight - slotHeight) / 2.0);

                    final clampedNewOffset = Offset(
                      rawOffset.dx.clamp(-prospectiveMaxX, prospectiveMaxX),
                      rawOffset.dy.clamp(-prospectiveMaxY, prospectiveMaxY),
                    );

                    widget.onUpdateSlot?.call(
                      widget.slotIndex,
                      newScale,
                      clampedNewOffset,
                      widget.slot.rotation,
                    );
                  },
                  onDoubleTap: () {
                    widget.onUpdateSlot?.call(
                      widget.slotIndex,
                      1.0,
                      Offset.zero,
                      0.0,
                    );
                  },
                  child: Container(
                    color: Colors.black,
                    child: renderedSlotContent,
                  ),
                ),
              ),
            ),

            if (widget.isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.communityAccent,
                        width: 2.2,
                      ),
                    ),
                  ),
                ),
              ),

            if (widget.isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xF018181A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (widget.onReplaceSlot != null) {
                            widget.onReplaceSlot!(widget.slotIndex);
                          } else {
                            widget.onTapSlot?.call(widget.slotIndex);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cached_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Replace",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 1,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      GestureDetector(
                        onTap: () {
                          final nextRot = (widget.slot.rotation + 90.0) % 360.0;
                          widget.onUpdateSlot?.call(
                            widget.slotIndex,
                            widget.slot.scale,
                            Offset.zero,
                            nextRot,
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          child: Icon(
                            Icons.rotate_90_degrees_cw_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 1,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      GestureDetector(
                        onTap: () => widget.onUpdateSlot?.call(
                          widget.slotIndex,
                          1.0,
                          Offset.zero,
                          0.0,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          child: Icon(
                            Icons.restart_alt_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 1,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      GestureDetector(
                        onTap: () => widget.onClearSlot?.call(widget.slotIndex),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
