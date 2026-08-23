import 'dart:io';
import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import '../../domain/models/story_template_model.dart';

File _resolveMediaFile(String rawPath) {
  final clean = rawPath.replaceAll(RegExp(r'^file://'), '');
  return File(clean);
}

/// Unified Story Template Canvas Widget.
/// Renders responsive template slot layouts for Single Photo, Two Photos,
/// Three Photos, Four Photos, and Photo + Text arrangements.
class StoryTemplateCanvas extends StatelessWidget {
  final StoryTemplateConfig template;
  final List<StoryTemplateSlot> slots;
  final bool isInteractive;
  final ValueChanged<int>? onTapSlot;
  final void Function(int slotIndex, double scale, Offset offset, double rotation)?
      onUpdateSlot;
  final ValueChanged<int>? onClearSlot;
  final ValueChanged<String>? onEditText;
  final String? customText;

  const StoryTemplateCanvas({
    super.key,
    required this.template,
    required this.slots,
    this.isInteractive = false,
    this.onTapSlot,
    this.onUpdateSlot,
    this.onClearSlot,
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
        ? (mediaQuery!.padding.top + 58.0)
        : 64.0;
    final bottomSafe = (mediaQuery?.padding.bottom ?? 0.0) > 0
        ? (mediaQuery!.padding.bottom + 80.0)
        : 86.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final availableHeight = (height - topSafe - bottomSafe).clamp(240.0, height);

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

  Widget _buildLayout(BuildContext context, double width, double height) {
    switch (template.layoutType) {
      // ── 1. SINGLE PHOTO ──
      case StoryTemplateLayoutType.singlePolaroid:
        return _buildSinglePolaroid(context, width, height);

      case StoryTemplateLayoutType.singleCard:
        return _buildSingleCard(context, width, height);

      case StoryTemplateLayoutType.singleFramed:
        return _buildSingleFramed(context, width, height);

      // ── 2. TWO PHOTOS ──
      case StoryTemplateLayoutType.splitVertical:
        return _buildSplitVertical(context, width, height);

      case StoryTemplateLayoutType.splitHorizontal:
        return _buildSplitHorizontal(context, width, height);

      case StoryTemplateLayoutType.twoDiptych:
        return _buildTwoDiptych(context, width, height);

      // ── 3. THREE PHOTOS ──
      case StoryTemplateLayoutType.threeHeroBottom:
        return _buildThreeHeroBottom(context, width, height);

      case StoryTemplateLayoutType.threeHeroLeft:
        return _buildThreeHeroLeft(context, width, height);

      case StoryTemplateLayoutType.threeColumns:
        return _buildThreeColumns(context, width, height);

      // ── 4. FOUR PHOTOS ──
      case StoryTemplateLayoutType.fourGrid:
        return _buildFourGrid(context, width, height);

      case StoryTemplateLayoutType.fourHeroStrip:
        return _buildFourHeroStrip(context, width, height);

      // ── 5. PHOTO + TEXT ──
      case StoryTemplateLayoutType.photoTextPolaroid:
        return _buildPhotoTextPolaroid(context, width, height);

      case StoryTemplateLayoutType.photoTextQuote:
        return _buildPhotoTextQuote(context, width, height);

      case StoryTemplateLayoutType.photoTextMagazine:
        return _buildPhotoTextMagazine(context, width, height);
    }
  }

  // ─────────────────────────────────────────────
  // 1. SINGLE PHOTO LAYOUTS
  // ─────────────────────────────────────────────

  Widget _buildSinglePolaroid(BuildContext context, double width, double height) {
    final cardWidth = (width * 0.86).clamp(260.0, 380.0);
    final cardHeight = (height * 0.72).clamp(380.0, 560.0);

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
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
                  child: _TemplateSlotBox(
                    slot: _getSlot(0),
                    slotIndex: 0,
                    isInteractive: isInteractive,
                    onTapSlot: onTapSlot,
                    onUpdateSlot: onUpdateSlot,
                    onClearSlot: onClearSlot,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                    fontSize: 16,
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
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
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
          borderRadius: BorderRadius.circular(26),
          child: _TemplateSlotBox(
            slot: _getSlot(0),
            slotIndex: 0,
            isInteractive: isInteractive,
            onTapSlot: onTapSlot,
            onUpdateSlot: onUpdateSlot,
            onClearSlot: onClearSlot,
          ),
        ),
      ),
    );
  }

  Widget _buildSingleFramed(BuildContext context, double width, double height) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _TemplateSlotBox(
          slot: _getSlot(0),
          slotIndex: 0,
          isInteractive: isInteractive,
          onTapSlot: onTapSlot,
          onUpdateSlot: onUpdateSlot,
          onClearSlot: onClearSlot,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 2. TWO PHOTOS LAYOUTS
  // ─────────────────────────────────────────────

  Widget _buildSplitVertical(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _TemplateSlotBox(
                slot: _getSlot(0),
                slotIndex: 0,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _TemplateSlotBox(
                slot: _getSlot(1),
                slotIndex: 1,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitHorizontal(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _TemplateSlotBox(
                slot: _getSlot(0),
                slotIndex: 0,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _TemplateSlotBox(
                slot: _getSlot(1),
                slotIndex: 1,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoDiptych(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
                child: _TemplateSlotBox(
                  slot: _getSlot(0),
                  slotIndex: 0,
                  isInteractive: isInteractive,
                  onTapSlot: onTapSlot,
                  onUpdateSlot: onUpdateSlot,
                  onClearSlot: onClearSlot,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
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
                child: _TemplateSlotBox(
                  slot: _getSlot(1),
                  slotIndex: 1,
                  isInteractive: isInteractive,
                  onTapSlot: onTapSlot,
                  onUpdateSlot: onUpdateSlot,
                  onClearSlot: onClearSlot,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 3. THREE PHOTOS LAYOUTS
  // ─────────────────────────────────────────────

  Widget _buildThreeHeroBottom(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            flex: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _TemplateSlotBox(
                slot: _getSlot(0),
                slotIndex: 0,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
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
                    child: _TemplateSlotBox(
                      slot: _getSlot(1),
                      slotIndex: 1,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _TemplateSlotBox(
                      slot: _getSlot(2),
                      slotIndex: 2,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _TemplateSlotBox(
                slot: _getSlot(0),
                slotIndex: 0,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
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
                    child: _TemplateSlotBox(
                      slot: _getSlot(1),
                      slotIndex: 1,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _TemplateSlotBox(
                      slot: _getSlot(2),
                      slotIndex: 2,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _TemplateSlotBox(
                slot: _getSlot(0),
                slotIndex: 0,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _TemplateSlotBox(
                slot: _getSlot(1),
                slotIndex: 1,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _TemplateSlotBox(
                slot: _getSlot(2),
                slotIndex: 2,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 4. FOUR PHOTOS LAYOUTS
  // ─────────────────────────────────────────────

  Widget _buildFourGrid(BuildContext context, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _TemplateSlotBox(
                      slot: _getSlot(0),
                      slotIndex: 0,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _TemplateSlotBox(
                      slot: _getSlot(1),
                      slotIndex: 1,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
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
                    child: _TemplateSlotBox(
                      slot: _getSlot(2),
                      slotIndex: 2,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _TemplateSlotBox(
                      slot: _getSlot(3),
                      slotIndex: 3,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            flex: 68,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _TemplateSlotBox(
                slot: _getSlot(0),
                slotIndex: 0,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 32,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _TemplateSlotBox(
                      slot: _getSlot(1),
                      slotIndex: 1,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _TemplateSlotBox(
                      slot: _getSlot(2),
                      slotIndex: 2,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _TemplateSlotBox(
                      slot: _getSlot(3),
                      slotIndex: 3,
                      isInteractive: isInteractive,
                      onTapSlot: onTapSlot,
                      onUpdateSlot: onUpdateSlot,
                      onClearSlot: onClearSlot,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 5. PHOTO + TEXT LAYOUTS
  // ─────────────────────────────────────────────

  Widget _buildPhotoTextPolaroid(
    BuildContext context,
    double width,
    double height,
  ) {
    final cardWidth = (width * 0.88).clamp(270.0, 390.0);
    final cardHeight = (height * 0.74).clamp(380.0, 580.0);

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                  child: _TemplateSlotBox(
                    slot: _getSlot(0),
                    slotIndex: 0,
                    isInteractive: isInteractive,
                    onTapSlot: onTapSlot,
                    onUpdateSlot: onUpdateSlot,
                    onClearSlot: onClearSlot,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              flex: 22,
              child: GestureDetector(
                onTap: isInteractive
                    ? () => onEditText?.call(customText ?? template.defaultText ?? '')
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
                      fontSize: 16.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Expanded(
            flex: 62,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _TemplateSlotBox(
                slot: _getSlot(0),
                slotIndex: 0,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 38,
            child: GestureDetector(
              onTap: isInteractive
                  ? () => onEditText?.call(customText ?? template.defaultText ?? '')
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      customText ?? template.defaultText ?? '"Create your own sunshine." ☀️',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Expanded(
            flex: 68,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _TemplateSlotBox(
                slot: _getSlot(0),
                slotIndex: 0,
                isInteractive: isInteractive,
                onTapSlot: onTapSlot,
                onUpdateSlot: onUpdateSlot,
                onClearSlot: onClearSlot,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 32,
            child: GestureDetector(
              onTap: isInteractive
                  ? () => onEditText?.call(customText ?? template.defaultText ?? '')
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      customText ?? template.defaultText ?? "CAMPUS LIFE • ISSUE 01",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

/// Internal widget handling a single slot: empty state or interactive filled photo.
class _TemplateSlotBox extends StatefulWidget {
  final StoryTemplateSlot slot;
  final int slotIndex;
  final bool isInteractive;
  final ValueChanged<int>? onTapSlot;
  final void Function(int slotIndex, double scale, Offset offset, double rotation)?
      onUpdateSlot;
  final ValueChanged<int>? onClearSlot;

  const _TemplateSlotBox({
    required this.slot,
    required this.slotIndex,
    required this.isInteractive,
    this.onTapSlot,
    this.onUpdateSlot,
    this.onClearSlot,
  });

  @override
  State<_TemplateSlotBox> createState() => _TemplateSlotBoxState();
}

class _TemplateSlotBoxState extends State<_TemplateSlotBox> {
  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;
  Offset _baseFocalPoint = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final mediaPath = widget.slot.mediaPath;

    // ── EMPTY SLOT ──
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
                  width: 44,
                  height: 44,
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
                    size: 22,
                  ),
                ),
                if (widget.isInteractive) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Tap to add photo",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
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

    // ── FILLED SLOT (Interactive or View Mode) ──
    Widget imageWidget;
    if (mediaPath.startsWith('assets/')) {
      imageWidget = Image.asset(
        mediaPath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      );
    } else if (mediaPath.startsWith('http://') || mediaPath.startsWith('https://')) {
      imageWidget = Image.network(
        mediaPath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      );
    } else {
      final file = _resolveMediaFile(mediaPath);
      imageWidget = Image.file(
        file,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      );
    }

    Widget transformedImage = Transform.translate(
      offset: widget.slot.offset,
      child: Transform.scale(
        scale: widget.slot.scale,
        child: RotatedBox(
          quarterTurns: (widget.slot.rotation / 90).round() % 4,
          child: SizedBox.expand(child: imageWidget),
        ),
      ),
    );

    if (!widget.isInteractive) {
      return Container(
        color: Colors.black,
        child: ClipRect(
          child: SizedBox.expand(child: transformedImage),
        ),
      );
    }

    return Stack(
      children: [
        // Pan & Pinch Gesture Detector
        Positioned.fill(
          child: ClipRect(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                _baseScale = widget.slot.scale;
                _baseOffset = widget.slot.offset;
                _baseFocalPoint = details.focalPoint;
              },
              onScaleUpdate: (details) {
                final newScale = (_baseScale * details.scale).clamp(0.5, 4.0);
                final delta = details.focalPoint - _baseFocalPoint;
                final newOffset = _baseOffset + delta;
                widget.onUpdateSlot?.call(
                  widget.slotIndex,
                  newScale,
                  newOffset,
                  widget.slot.rotation,
                );
              },
              onDoubleTap: () {
                widget.onUpdateSlot?.call(widget.slotIndex, 1.0, Offset.zero, 0.0);
              },
              child: Container(
                color: Colors.black,
                child: SizedBox.expand(child: transformedImage),
              ),
            ),
          ),
        ),

        // Action Toolbar Pill (Replace, Reset & Delete)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Replace photo
                Tooltip(
                  message: "Replace photo",
                  child: GestureDetector(
                    onTap: () => widget.onTapSlot?.call(widget.slotIndex),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.cached_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                Container(height: 12, width: 1, color: Colors.white24),
                // Reset photo transform
                Tooltip(
                  message: "Reset position",
                  child: GestureDetector(
                    onTap: () => widget.onUpdateSlot?.call(
                      widget.slotIndex,
                      1.0,
                      Offset.zero,
                      0.0,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.restart_alt_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                Container(height: 12, width: 1, color: Colors.white24),
                // Remove photo
                Tooltip(
                  message: "Remove photo",
                  child: GestureDetector(
                    onTap: () => widget.onClearSlot?.call(widget.slotIndex),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
