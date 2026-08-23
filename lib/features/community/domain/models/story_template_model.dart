import 'package:flutter/material.dart';

/// Represents an individual media/image slot within a Story Template.
class StoryTemplateSlot {
  final String id;
  String? mediaPath;
  double scale;
  Offset offset;
  double rotation;
  String? text;

  StoryTemplateSlot({
    required this.id,
    this.mediaPath,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.rotation = 0.0,
    this.text,
  });

  StoryTemplateSlot clone() {
    return StoryTemplateSlot(
      id: id,
      mediaPath: mediaPath,
      scale: scale,
      offset: Offset(offset.dx, offset.dy),
      rotation: rotation,
      text: text,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaPath': mediaPath,
    'scale': scale,
    'offsetDx': offset.dx,
    'offsetDy': offset.dy,
    'rotation': rotation,
    'text': text,
  };

  factory StoryTemplateSlot.fromJson(Map<String, dynamic> json) =>
      StoryTemplateSlot(
        id: json['id'] as String? ?? 'slot',
        mediaPath: json['mediaPath'] as String?,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        offset: Offset(
          (json['offsetDx'] as num?)?.toDouble() ?? 0.0,
          (json['offsetDy'] as num?)?.toDouble() ?? 0.0,
        ),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        text: json['text'] as String?,
      );
}

/// Supported template layout arrangements.
enum StoryTemplateLayoutType {
  // Single Photo
  singlePolaroid,
  singleCard,
  singleFramed,

  // Two Photos
  splitVertical,
  splitHorizontal,
  twoDiptych,

  // Three Photos
  threeHeroBottom,
  threeHeroLeft,
  threeColumns,

  // Four Photos
  fourGrid,
  fourHeroStrip,

  // Photo + Text
  photoTextPolaroid,
  photoTextQuote,
  photoTextMagazine,
}

/// Configuration preset for a Story Template.
class StoryTemplateConfig {
  final String id;
  final String name;
  final String category; // 'Single', 'Two Photos', 'Three Photos', 'Four Photos', 'Photo + Text'
  final StoryTemplateLayoutType layoutType;
  final int slotCount;
  final IconData icon;
  final String description;
  final bool hasTextSlot;
  final String? defaultText;
  final List<Color>? defaultBgColors;

  const StoryTemplateConfig({
    required this.id,
    required this.name,
    required this.category,
    required this.layoutType,
    required this.slotCount,
    required this.icon,
    required this.description,
    this.hasTextSlot = false,
    this.defaultText,
    this.defaultBgColors,
  });
}

/// Curated library of GenLink Story Templates across all 5 requested categories.
const List<StoryTemplateConfig> storyTemplatePresets = [
  // ── 1. SINGLE PHOTO ──
  StoryTemplateConfig(
    id: 'single_polaroid',
    name: 'Polaroid Classic',
    category: 'Single',
    layoutType: StoryTemplateLayoutType.singlePolaroid,
    slotCount: 1,
    icon: Icons.filter_frames_rounded,
    description: 'Aesthetic vintage polaroid card with soft bottom margin',
    defaultBgColors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  ),
  StoryTemplateConfig(
    id: 'single_card',
    name: 'Minimal Card',
    category: 'Single',
    layoutType: StoryTemplateLayoutType.singleCard,
    slotCount: 1,
    icon: Icons.crop_portrait_rounded,
    description: 'Clean floating rounded card with elegant canvas padding',
    defaultBgColors: [Color(0xFF2C3E50), Color(0xFF000000)],
  ),
  StoryTemplateConfig(
    id: 'single_framed',
    name: 'Full Framed',
    category: 'Single',
    layoutType: StoryTemplateLayoutType.singleFramed,
    slotCount: 1,
    icon: Icons.aspect_ratio_rounded,
    description: 'Bold outline border frame with modern styling',
    defaultBgColors: [Color(0xFF374151), Color(0xFF111827)],
  ),

  // ── 2. TWO PHOTOS ──
  StoryTemplateConfig(
    id: 'two_split_v',
    name: 'Split Vertical',
    category: 'Two Photos',
    layoutType: StoryTemplateLayoutType.splitVertical,
    slotCount: 2,
    icon: Icons.table_rows_rounded,
    description: 'Top and bottom 50/50 split with clean divider',
    defaultBgColors: [Color(0xFF18181B), Color(0xFF09090B)],
  ),
  StoryTemplateConfig(
    id: 'two_split_h',
    name: 'Split Horizontal',
    category: 'Two Photos',
    layoutType: StoryTemplateLayoutType.splitHorizontal,
    slotCount: 2,
    icon: Icons.view_column_rounded,
    description: 'Side-by-side left and right dual photo split',
    defaultBgColors: [Color(0xFF1E1E24), Color(0xFF121214)],
  ),
  StoryTemplateConfig(
    id: 'two_diptych',
    name: 'Diptych Cards',
    category: 'Two Photos',
    layoutType: StoryTemplateLayoutType.twoDiptych,
    slotCount: 2,
    icon: Icons.view_agenda_rounded,
    description: 'Two floating aesthetic photo cards with subtle shadow',
    defaultBgColors: [Color(0xFF262626), Color(0xFF0A0A0A)],
  ),

  // ── 3. THREE PHOTOS ──
  StoryTemplateConfig(
    id: 'three_hero_bottom',
    name: '1 Top, 2 Bottom',
    category: 'Three Photos',
    layoutType: StoryTemplateLayoutType.threeHeroBottom,
    slotCount: 3,
    icon: Icons.vertical_split_rounded,
    description: 'Large top hero banner with two square photos below',
    defaultBgColors: [Color(0xFF1F2937), Color(0xFF111827)],
  ),
  StoryTemplateConfig(
    id: 'three_hero_left',
    name: '1 Left, 2 Right',
    category: 'Three Photos',
    layoutType: StoryTemplateLayoutType.threeHeroLeft,
    slotCount: 3,
    icon: Icons.view_sidebar_rounded,
    description: 'Tall hero on left with two stacked photos on right',
    defaultBgColors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  ),
  StoryTemplateConfig(
    id: 'three_columns',
    name: '3 Columns',
    category: 'Three Photos',
    layoutType: StoryTemplateLayoutType.threeColumns,
    slotCount: 3,
    icon: Icons.view_week_rounded,
    description: 'Three vertical photo strips side-by-side',
    defaultBgColors: [Color(0xFF27272A), Color(0xFF18181B)],
  ),

  // ── 4. FOUR PHOTOS ──
  StoryTemplateConfig(
    id: 'four_grid',
    name: '2x2 Grid',
    category: 'Four Photos',
    layoutType: StoryTemplateLayoutType.fourGrid,
    slotCount: 4,
    icon: Icons.grid_view_rounded,
    description: 'Classic four quadrant photo collage grid',
    defaultBgColors: [Color(0xFF18181B), Color(0xFF000000)],
  ),
  StoryTemplateConfig(
    id: 'four_hero_strip',
    name: '1 Hero + 3 Mini',
    category: 'Four Photos',
    layoutType: StoryTemplateLayoutType.fourHeroStrip,
    slotCount: 4,
    icon: Icons.featured_video_rounded,
    description: 'Large main photo with three thumbnail strips below',
    defaultBgColors: [Color(0xFF1F2937), Color(0xFF0F172A)],
  ),

  // ── 5. PHOTO + TEXT ──
  StoryTemplateConfig(
    id: 'photo_text_polaroid',
    name: 'Polaroid Note',
    category: 'Photo + Text',
    layoutType: StoryTemplateLayoutType.photoTextPolaroid,
    slotCount: 1,
    hasTextSlot: true,
    defaultText: "Today's highlight ✨",
    icon: Icons.note_alt_outlined,
    description: 'Polaroid photo frame with handwritten caption note below',
    defaultBgColors: [Color(0xFF334155), Color(0xFF1E293B)],
  ),
  StoryTemplateConfig(
    id: 'photo_text_quote',
    name: 'Quote Card',
    category: 'Photo + Text',
    layoutType: StoryTemplateLayoutType.photoTextQuote,
    slotCount: 1,
    hasTextSlot: true,
    defaultText: '"Create your own sunshine." ☀️',
    icon: Icons.format_quote_rounded,
    description: 'Top photo with stylish quote card and quote marks below',
    defaultBgColors: [Color(0xFF1E1E24), Color(0xFF0B0B0E)],
  ),
  StoryTemplateConfig(
    id: 'photo_text_magazine',
    name: 'Magazine Hero',
    category: 'Photo + Text',
    layoutType: StoryTemplateLayoutType.photoTextMagazine,
    slotCount: 1,
    hasTextSlot: true,
    defaultText: 'CAMPUS LIFE • ISSUE 01',
    icon: Icons.menu_book_rounded,
    description: 'Editorial magazine layout with hero card and story title',
    defaultBgColors: [Color(0xFF18181B), Color(0xFF000000)],
  ),
];
