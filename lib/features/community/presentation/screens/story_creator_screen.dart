// ignore_for_file: unused_element
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/story_model.dart';
import '../controllers/story_controller.dart';
import '../controllers/story_gallery_controller.dart';
import '../widgets/story_template_canvas.dart';
import '../widgets/story_template_picker_sheet.dart';
import 'story_gallery_screen.dart';

class StoryTemplateModel {
  final String id;
  final String name;
  final String icon;
  final List<Color> backgroundColors;
  final Color textColor;
  final TextStyleType defaultFontStyle;
  final Color cardBorderColor;
  final Color cardBackgroundColor;
  final String? badgeLabel;
  final IconData? badgeIcon;
  final bool showQuotes;
  final bool showNotebookLines;
  final bool showDotGrid;
  final String? bgImageAssetPath;

  const StoryTemplateModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.backgroundColors,
    this.textColor = Colors.white,
    this.defaultFontStyle = TextStyleType.bold,
    this.cardBorderColor = Colors.transparent,
    this.cardBackgroundColor = Colors.transparent,
    this.badgeLabel,
    this.badgeIcon,
    this.showQuotes = false,
    this.showNotebookLines = false,
    this.showDotGrid = false,
    this.bgImageAssetPath,
  });
}

class _NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    final marginPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.3)
      ..strokeWidth = 1.5;

    canvas.drawLine(const Offset(48, 0), Offset(48, size.height), marginPaint);

    const double lineSpacing = 32.0;
    for (double y = 80; y < size.height - 100; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const double spacing = 28.0;
    for (double x = 20; x < size.width; x += spacing) {
      for (double y = 100; y < size.height - 120; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StoryCreatorScreen extends StatefulWidget {
  final StoryType type;
  final List<String>? mediaPaths;
  final StoryItemModel? existingStory;
  final String? templateId;

  const StoryCreatorScreen({
    super.key,
    required this.type,
    this.mediaPaths,
    this.existingStory,
    this.templateId,
  });

  @override
  State<StoryCreatorScreen> createState() => _StoryCreatorScreenState();
}

enum ActiveContextTool { none, font, effect, color, background }

enum StoryBgMode { none, solid, gradient }

class _StoryCreatorScreenState extends State<StoryCreatorScreen> {
  final List<MovableStoryLayer> _layers = [];

  // ── Template Story Mode State ──
  late StoryTemplateConfig _selectedTemplate;
  List<StoryTemplateSlot> _templateSlots = [];
  String? _templateCustomText;
  bool _isTemplateApplied = false;
  int? _selectedTemplateSlotIndex;

  static int _layerSequenceCounter = 0;

  String _generateUniqueLayerId([String prefix = 'layer']) {
    _layerSequenceCounter++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_layerSequenceCounter';
  }

  Offset _calculateInitialLayerOffset(int index, int totalCount) {
    if (totalCount <= 1 || index == 0) {
      return const Offset(0.5, 0.5);
    }
    final step = index % 6;
    final dx = (0.50 + (step * 0.035)).clamp(0.20, 0.80);
    final dy = (0.50 + (step * 0.035)).clamp(0.20, 0.80);
    return Offset(dx, dy);
  }

  File _resolveStoryMediaFile(String rawPath) {
    final clean = rawPath.replaceAll(RegExp(r'^file://'), '');
    return File(clean);
  }

  MovableStoryLayer? _selectedLayer;
  ActiveContextTool _activeContextTool = ActiveContextTool.none;
  bool _isPublishing = false;
  StorySettings _storySettings = const StorySettings(
    visibility: StoryPrivacy.friends,
    replyPermission: StoryReplyPermission.everyone,
    allowReactions: true,
  );
  String get _selectedVisibility => _storySettings.visibilityLabel;
  String get _replyPrivacy => _storySettings.replyPermissionLabel;
  bool get _allowReactions => _storySettings.allowReactions;

  String? _activeMediaPath;
  final TextEditingController _captionController = TextEditingController();
  double _imageRotation = 0.0;
  final TransformationController _transformationController =
      TransformationController();

  double _bgImageScale = 1.0;
  Offset _bgImageOffset = Offset.zero;
  double _bgBaseScale = 1.0;
  Offset _bgBaseFocalPoint = Offset.zero;
  Offset _bgBaseOffset = Offset.zero;

  void _rotateImage() {
    setState(() {
      _imageRotation = (_imageRotation + 90) % 360;
    });
  }

  // Full-Screen Immersive Text Editor State
  bool _isFullScreenTextEditing = false;
  bool get isEditingText => _isFullScreenTextEditing;
  MovableStoryLayer? _editingTextLayer;
  final TextEditingController _fullScreenTextController =
      TextEditingController();
  final FocusNode _fullScreenTextFocusNode = FocusNode();
  Color _activeTextColor = Colors.white;
  Color? _activeTextBgColor;
  TextStyleType _activeFontStyle = TextStyleType.classic;
  TextBgStyle _activeTextBgStyle = TextBgStyle.none;
  TextEffectType _activeTextEffect = TextEffectType.none;
  TextAlign _activeTextAlign = TextAlign.center;

  // Font size controlled by vertical slider (14–72pt)
  double _activeFontSize = 28.0;

  int _selectedTemplateIdx = 0;
  int _gradientIdx = 0;
  StoryBgMode _storyBgMode = StoryBgMode.gradient;
  Color? _selectedSolidBgColor;
  TextStyleType _fontStyle = TextStyleType.classic;

  static const List<Color> _curatedColors = [
    Colors.white,
    Colors.black,
    Color(0xFFFACC15), // Amber
    Color(0xFFF43F5E), // Rose
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFA855F7), // Violet
    Color(0xFF34D399), // Emerald Green
    Color(0xFFFB923C), // Vibrant Orange
    Color(0xFFE879F9), // Fuchsia Pink
    Color(0xFF4ADE80), // Mint Lime
    Color(0xFF64748B), // Soft Slate
  ];

  static const List<Color> _solidBgColors = [
    Colors.white,
    Colors.black,
    Color(0xFFA855F7), // Purple / Violet
    Color(0xFF34D399), // Emerald Green
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFF43F5E), // Pink / Rose
    Color(0xFFFACC15), // Yellow / Amber
    Color(0xFFFB923C), // Vibrant Orange
    Color(0xFFE879F9), // Fuchsia Pink
    Color(0xFF4ADE80), // Mint Lime
    Color(0xFF1E293B), // Slate Blue
    Color(0xFF4C1D95), // Deep Violet
    Color(0xFF064E3B), // Forest Green
    Color(0xFF312E81), // Midnight Indigo
  ];

  static const List<(TextStyleType, String)> _fontPresets = [
    (TextStyleType.classic, 'Classic'),
    (TextStyleType.elegant, 'Deco'),
    (TextStyleType.bold, 'Bubble'),
    (TextStyleType.modern, 'Modern'),
    (TextStyleType.minimal, 'Neon'),
    (TextStyleType.handwriting, 'Script'),
    (TextStyleType.coding, 'Code'),
  ];

  // Selected background category for filter tabs
  String _selectedBgCategory = 'Gradients';

  // Curated cute, aesthetic, and trending TikTok / Instagram backgrounds for text stories
  final List<
    ({
      String name,
      String category,
      String emoji,
      List<Color> colors,
      AlignmentGeometry begin,
      AlignmentGeometry end,
    })
  >
  _bgPresets = [
    // 🌸 PASTEL & CUTE
    (
      name: 'Barbie Dream',
      category: 'Pastel',
      emoji: '💖',
      colors: [Color(0xFFFF758C), Color(0xFFFF7EB3), Color(0xFFFFB199)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    (
      name: 'Sweet Peach',
      category: 'Pastel',
      emoji: '🍑',
      colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4), Color(0xFFFBC2EB)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    (
      name: 'Cotton Candy',
      category: 'Pastel',
      emoji: '🍬',
      colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB), Color(0xFFE2D1F9)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    (
      name: 'Baby Cloud',
      category: 'Pastel',
      emoji: '☁️',
      colors: [Color(0xFF89F7FE), Color(0xFF66A6FF), Color(0xFFE0C3FC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    (
      name: 'Butter Cream',
      category: 'Pastel',
      emoji: '🧈',
      colors: [Color(0xFFFFF1EB), Color(0xFFACE0F9), Color(0xFFFBE7C6)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),

    // 🔥 TIKTOK TRENDING
    (
      name: 'Golden Hour',
      category: 'Trending',
      emoji: '🌅',
      colors: [Color(0xFFFF512F), Color(0xFFF09819), Color(0xFFFF8E53)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    (
      name: 'Cyber Lilac',
      category: 'Trending',
      emoji: '💜',
      colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    (
      name: 'Matcha Sage',
      category: 'Trending',
      emoji: '🍵',
      colors: [Color(0xFF134E5E), Color(0xFF71B280), Color(0xFFC8E6C9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    (
      name: 'Sunset Glow',
      category: 'Trending',
      emoji: '🌇',
      colors: [Color(0xFFFF416C), Color(0xFFFF4B2B), Color(0xFFFF9A3E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    (
      name: 'Neon Mango',
      category: 'Trending',
      emoji: '🥭',
      colors: [Color(0xFFFF9966), Color(0xFFFF5E62), Color(0xFFFFD194)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    (
      name: 'Sky Azure',
      category: 'Trending',
      emoji: '🌊',
      colors: [Color(0xFF4FACFE), Color(0xFF00F2FE), Color(0xFF43E97B)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),

    // ✨ HOLOGRAPHIC & FAIRY
    (
      name: 'Aurora Fairy',
      category: 'Fairy',
      emoji: '✨',
      colors: [Color(0xFFFBC2EB), Color(0xFFA6C1EE), Color(0xFFC2E9FB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    (
      name: 'Y2K Dream',
      category: 'Fairy',
      emoji: '🦄',
      colors: [Color(0xFFDA8FFF), Color(0xFF8E54E9), Color(0xFF4776E6)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    (
      name: 'Mermaid Teal',
      category: 'Fairy',
      emoji: '🧜‍♀️',
      colors: [Color(0xFF43E97B), Color(0xFF38F9D7), Color(0xFF667EEA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    (
      name: 'Pearl Mist',
      category: 'Fairy',
      emoji: '🪩',
      colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC), Color(0xFFD9AFD9)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),

    // ☕ AESTHETIC & MOOD
    (
      name: 'Warm Mocha',
      category: 'Aesthetic',
      emoji: '☕',
      colors: [Color(0xFF2C1810), Color(0xFF4A2E2B), Color(0xFF8D6E63)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    (
      name: 'Velvet Cherry',
      category: 'Aesthetic',
      emoji: '🍒',
      colors: [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    (
      name: 'Deep Galaxy',
      category: 'Aesthetic',
      emoji: '🌌',
      colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    (
      name: 'Dark Emerald',
      category: 'Aesthetic',
      emoji: '🌲',
      colors: [Color(0xFF0B3024), Color(0xFF134E5E), Color(0xFF2A5298)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    (
      name: 'Cyber Noir',
      category: 'Aesthetic',
      emoji: '⚡',
      colors: [Color(0xFF1F1C2C), Color(0xFF928DAB), Color(0xFF24243E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),

    // 🖤 CLEAN & MINIMAL
    (
      name: 'Pure OLED',
      category: 'Minimal',
      emoji: '🖤',
      colors: [Color(0xFF000000), Color(0xFF121212), Color(0xFF1C1C1E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    (
      name: 'Studio Slate',
      category: 'Minimal',
      emoji: '🩶',
      colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF), Color(0xFF1E293B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    (
      name: 'Oat Vanilla',
      category: 'Minimal',
      emoji: '🥛',
      colors: [Color(0xFFFDFBFB), Color(0xFFEBEDEE), Color(0xFFE2D4C9)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    (
      name: 'Paper Beige',
      category: 'Minimal',
      emoji: '📜',
      colors: [Color(0xFFF7F4EB), Color(0xFFE8E0D2), Color(0xFFD7CCC8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  // Keep _gradients for backward compat with other screens
  List<List<Color>> get _gradients => _bgPresets.map((p) => p.colors).toList();

  static const List<StoryTemplateModel> _storyTemplates = [
    StoryTemplateModel(
      id: 'minimal',
      name: 'Minimal',
      icon: '✨',
      backgroundColors: [Color(0xFF000000), Color(0xFF111827)],
      textColor: Colors.white,
      defaultFontStyle: TextStyleType.bold,
      cardBorderColor: Colors.white24,
      showDotGrid: true,
    ),
    StoryTemplateModel(
      id: 'notebook',
      name: 'Notebook',
      icon: '📝',
      backgroundColors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      textColor: Color(0xFFF8FAFC),
      defaultFontStyle: TextStyleType.classic,
      showNotebookLines: true,
    ),
    StoryTemplateModel(
      id: 'sticky_note',
      name: 'Sticky Note',
      icon: '📌',
      backgroundColors: [Color(0xFF18181B), Color(0xFF09090B)],
      textColor: Color(0xFF1C1917),
      defaultFontStyle: TextStyleType.bold,
      cardBackgroundColor: Color(0xFFFEF08A),
      cardBorderColor: Color(0xFFFDE047),
    ),
    StoryTemplateModel(
      id: 'quote',
      name: 'Quote',
      icon: '💬',
      backgroundColors: [Color(0xFF090D16), Color(0xFF1E293B)],
      textColor: Colors.white,
      defaultFontStyle: TextStyleType.minimal,
    ),
    StoryTemplateModel(
      id: 'campus',
      name: 'Campus',
      icon: '🎓',
      backgroundColors: [Color(0xFF064E3B), Color(0xFF022C22)],
      textColor: Colors.white,
      defaultFontStyle: TextStyleType.bold,
      cardBorderColor: Color(0xFF10B981),
    ),
    StoryTemplateModel(
      id: 'career',
      name: 'Career',
      icon: '💼',
      backgroundColors: [Color(0xFF0F172A), Color(0xFF0284C7)],
      textColor: Colors.white,
      defaultFontStyle: TextStyleType.modern,
      cardBorderColor: Color(0xFF38BDF8),
    ),
    StoryTemplateModel(
      id: 'pastel',
      name: 'Pastel',
      icon: '🎨',
      backgroundColors: [Color(0xFF2A2038), Color(0xFF1E1E2E)],
      textColor: Color(0xFFF472B6),
      defaultFontStyle: TextStyleType.classic,
      cardBorderColor: Color(0xFFC084FC),
    ),
    StoryTemplateModel(
      id: 'dark',
      name: 'Dark',
      icon: '🌙',
      backgroundColors: [Color(0xFF000000), Color(0xFF050505)],
      textColor: Colors.white,
      defaultFontStyle: TextStyleType.minimal,
      cardBorderColor: Colors.white38,
    ),
    StoryTemplateModel(
      id: 'gradient',
      name: 'Gradient',
      icon: '🌈',
      backgroundColors: [Color(0xFF4C1D95), Color(0xFF1E1B4B)],
      textColor: Colors.white,
      defaultFontStyle: TextStyleType.bold,
      cardBackgroundColor: Colors.white10,
      cardBorderColor: Colors.white24,
    ),
    StoryTemplateModel(
      id: 'nature',
      name: 'Nature',
      icon: '🌿',
      backgroundColors: [Color(0xFF065F46), Color(0xFF064E3B)],
      textColor: Color(0xFFECFDF5),
      defaultFontStyle: TextStyleType.classic,
      cardBorderColor: Color(0xFF34D399),
    ),
    StoryTemplateModel(
      id: 'cute',
      name: 'Cute',
      icon: '🩷',
      backgroundColors: [Color(0xFF831843), Color(0xFF500724)],
      textColor: Color(0xFFF472B6),
      defaultFontStyle: TextStyleType.classic,
      cardBorderColor: Color(0xFFF472B6),
    ),
    StoryTemplateModel(
      id: 'happy',
      name: 'Happy',
      icon: '☀️',
      backgroundColors: [Color(0xFF78350F), Color(0xFF451A03)],
      textColor: Color(0xFFFDE047),
      defaultFontStyle: TextStyleType.bold,
      cardBorderColor: Color(0xFFFACC15),
    ),
    StoryTemplateModel(
      id: 'sad',
      name: 'Sad',
      icon: '🌧',
      backgroundColors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      textColor: Color(0xFF94A3B8),
      defaultFontStyle: TextStyleType.classic,
      cardBorderColor: Color(0xFF64748B),
    ),
    StoryTemplateModel(
      id: 'angry',
      name: 'Angry',
      icon: '😡',
      backgroundColors: [Color(0xFF450A0A), Color(0xFF180202)],
      textColor: Color(0xFFF87171),
      defaultFontStyle: TextStyleType.bold,
      cardBorderColor: Color(0xFFEF4444),
    ),
    StoryTemplateModel(
      id: 'tired',
      name: 'Tired',
      icon: '😴',
      backgroundColors: [Color(0xFF1E1B4B), Color(0xFF0F0E26)],
      textColor: Color(0xFFA5B4FC),
      defaultFontStyle: TextStyleType.minimal,
      cardBorderColor: Color(0xFF818CF8),
    ),
    StoryTemplateModel(
      id: 'fun',
      name: 'Fun',
      icon: '🎉',
      backgroundColors: [Color(0xFF581C87), Color(0xFF2E1065)],
      textColor: Color(0xFFE879F9),
      defaultFontStyle: TextStyleType.bold,
      cardBorderColor: Color(0xFFC084FC),
    ),
    StoryTemplateModel(
      id: 'coffee',
      name: 'Coffee',
      icon: '☕',
      backgroundColors: [Color(0xFF3F2E21), Color(0xFF1E140C)],
      textColor: Color(0xFFFDE68A),
      defaultFontStyle: TextStyleType.classic,
      cardBorderColor: Color(0xFFD97706),
      bgImageAssetPath: 'assets/images/templates/coffee_vibe_bg.jpg',
    ),
    StoryTemplateModel(
      id: 'ocean',
      name: 'Ocean',
      icon: '🌊',
      backgroundColors: [Color(0xFF0F172A), Color(0xFF0284C7)],
      textColor: Color(0xFFE0F2FE),
      defaultFontStyle: TextStyleType.bold,
      cardBorderColor: Color(0xFF38BDF8),
    ),
    StoryTemplateModel(
      id: 'motivation',
      name: 'Motivation',
      icon: '🚀',
      backgroundColors: [Color(0xFF7C2D12), Color(0xFF451A03)],
      textColor: Color(0xFFFDE047),
      defaultFontStyle: TextStyleType.bold,
      cardBorderColor: Color(0xFFF59E0B),
    ),
    StoryTemplateModel(
      id: 'love',
      name: 'Love',
      icon: '❤️',
      backgroundColors: [Color(0xFF701A75), Color(0xFF4A044E)],
      textColor: Color(0xFFF472B6),
      defaultFontStyle: TextStyleType.classic,
      cardBorderColor: Color(0xFFF472B6),
    ),
  ];

  // Exclusive GenLink Campus Stickers
  final Map<String, List<String>> _stickerCategories = {
    '🐱 Cute Cats': ['🐱 Playful Kittens', '🎩 Winter Cat', '😻 Hugging Cats'],
    '🎓 Campus': [
      '📚 Assignment Done',
      '💻 Coding',
      '☕ Coffee Break',
      '🎓 Graduation',
      '📝 Midterm Exam',
      '🚀 Hackathon 2026',
      '🏆 Dean\'s List',
      '🤝 Club Meeting',
      '📖 Main Library',
      '🔥 Internship',
      '💼 Career Fair',
      '🇰🇭 GenLink KH',
    ],
    '🔥 Trending': ['🔥', '🚀', '💯', '✨', '⚡', '🎉', '🌟', '💪', '🏆'],
    '💻 Dev & Tech': [
      '💻 Flutter',
      '☕ Java',
      '🚀 Docker',
      '⚡ SpringBoot',
      '🤖 AI Lab',
      '🌐 Cloud',
    ],
  };
  final List<String> _recentStickers = ['🔥', '🚀', '📚', '☕', '💯'];

  final List<String> _locationOptions = [
    'ACLEDA University of Business',
    'Main Library',
    'Phnom Penh, Cambodia',
    'CADT Innovation Lab',
    'RUPP Campus',
    'Campus Cafe',
  ];

  final List<String> _musicOptions = [
    '🎵 Lofi Campus Study Beats',
    '🎵 Khmer Acoustic Vibe',
    '🎵 Focus Coding Ambient',
    '🎵 Hackathon Energy Beats',
  ];

  final List<String> _mentionSuggestions = [
    '@SoknyEnat',
    '@RenMakara',
    '@HengChansela',
    '@AUBClass2026',
  ];

  @override
  void initState() {
    super.initState();

    // ── 1. Initialize Story Template Mode ──
    _isTemplateApplied = widget.type == StoryType.template || (widget.existingStory?.templateId != null);
    final targetTemplateId = widget.templateId ?? widget.existingStory?.templateId;
    if (targetTemplateId != null) {
      StoryTemplateConfig? matched;
      for (final t in storyTemplatePresets) {
        if (t.id == targetTemplateId) {
          matched = t;
          break;
        }
      }
      _selectedTemplate = matched ?? storyTemplatePresets.first;
    } else {
      _selectedTemplate = storyTemplatePresets.first;
    }

    if (widget.existingStory != null && widget.existingStory!.templateSlots.isNotEmpty) {
      _templateSlots = widget.existingStory!.templateSlots.map((s) => s.clone()).toList();
      _templateCustomText = widget.existingStory!.textContent;
    } else {
      _templateSlots = List.generate(
        _selectedTemplate.slotCount,
        (i) => StoryTemplateSlot(id: 'slot_$i'),
      );
      if (widget.mediaPaths != null && widget.mediaPaths!.isNotEmpty) {
        for (int i = 0; i < widget.mediaPaths!.length && i < _templateSlots.length; i++) {
          _templateSlots[i].mediaPath = widget.mediaPaths![i];
        }
      }
    }

    if (widget.existingStory != null) {
      final s = widget.existingStory!;
      _layers.addAll(s.layers.map((l) => l.clone(id: l.id)));
      _storySettings = s.settings;
      _activeMediaPath = s.mediaUrl;
      _bgImageScale = s.bgScale;
      _bgImageOffset = s.bgOffset;
      _imageRotation = s.bgRotation;

      if (s.bgGradientStart != null && s.bgGradientStart == s.bgGradientEnd) {
        _storyBgMode = StoryBgMode.solid;
        _selectedSolidBgColor = Color(int.parse(s.bgGradientStart!.replaceAll('0x', ''), radix: 16));
      } else if (s.bgGradientStart != null) {
        _storyBgMode = StoryBgMode.gradient;
        final startColor = Color(int.parse(s.bgGradientStart!.replaceAll('0x', ''), radix: 16));
        final presetIdx = _bgPresets.indexWhere((p) => p.colors.first.toARGB32() == startColor.toARGB32());
        if (presetIdx != -1) _gradientIdx = presetIdx;
      }
    } else {
      if (widget.type != StoryType.template && widget.mediaPaths != null && widget.mediaPaths!.isNotEmpty) {
        if (widget.mediaPaths!.length == 1) {
          _activeMediaPath = widget.mediaPaths!.first;
        } else {
          _activeMediaPath = null;
          for (int i = 0; i < widget.mediaPaths!.length; i++) {
            final path = widget.mediaPaths![i];
            final offset = _calculateInitialLayerOffset(i, widget.mediaPaths!.length);
            _layers.add(
              MovableStoryLayer(
                id: _generateUniqueLayerId('image'),
                type: LayerType.image,
                text: path,
                offset: offset,
                scale: 1.0,
                rotation: 0.0,
              ),
            );
          }
          if (_layers.isNotEmpty) {
            _selectedLayer = _layers.first;
          }
        }
      }
    }
    _fullScreenTextController.addListener(_onTextChanged);
    if (widget.type == StoryType.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openFloatingTextEditor();
        }
      });
    }
  }

  // ── Template Slot Operations ──
  Future<void> _pickPhotosForTemplate(StoryTemplateConfig template) async {
    try {
      final galleryCtrl = Get.isRegistered<StoryGalleryController>()
          ? Get.find<StoryGalleryController>()
          : Get.put(StoryGalleryController());
      galleryCtrl.configureForTemplate(
        template: template,
        requiredPhotos: template.slotCount,
        maxSelection: template.slotCount,
        isMultiSelect: template.slotCount > 1,
        clearSelection: true,
      );

      final result = await Get.to(
        () => StoryGalleryScreen(
          targetTemplate: template,
          requiredPhotos: template.slotCount,
        ),
        routeName: '/StoryGalleryScreen',
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );

      List<String> selectedPaths = [];
      if (result is List<String>) {
        selectedPaths = result;
      } else if (result is String && result.trim().isNotEmpty) {
        selectedPaths = [result];
      }

      if (selectedPaths.isNotEmpty && mounted) {
        setState(() {
          _isTemplateApplied = true;
          _selectedTemplate = template;
          _selectedTemplateSlotIndex = null;
          _templateSlots = List.generate(template.slotCount, (i) {
            final path = i < selectedPaths.length ? selectedPaths[i] : null;
            return StoryTemplateSlot(
              id: 'slot_$i',
              mediaPath: path,
              scale: 1.0,
              offset: Offset.zero,
              rotation: 0.0,
            );
          });
        });
      }
    } catch (e) {
      debugPrint('[StoryCreatorScreen] Error picking photos for template via Gallery: $e');
    }
  }

  Future<void> _onReplaceTemplateSlot(int slotIndex) async {
    try {
      final galleryCtrl = Get.isRegistered<StoryGalleryController>()
          ? Get.find<StoryGalleryController>()
          : Get.put(StoryGalleryController());
      galleryCtrl.configureForTemplate(
        template: _selectedTemplate,
        requiredPhotos: 1,
        maxSelection: 1,
        isMultiSelect: false,
        clearSelection: true,
      );

      final result = await Get.to(
        () => StoryGalleryScreen(
          targetTemplate: _selectedTemplate,
          replaceSlotIndex: slotIndex,
          requiredPhotos: 1,
        ),
        routeName: '/StoryGalleryScreen',
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      if (result != null && result is String && result.isNotEmpty && mounted) {
        setState(() {
          if (slotIndex < _templateSlots.length) {
            _templateSlots[slotIndex].mediaPath = result;
            _templateSlots[slotIndex].scale = 1.0;
            _templateSlots[slotIndex].offset = Offset.zero;
            _templateSlots[slotIndex].rotation = 0.0;
            _selectedTemplateSlotIndex = slotIndex;
          }
        });
        return;
      }
      if (result != null && result is List<String> && result.isNotEmpty && mounted) {
        setState(() {
          if (slotIndex < _templateSlots.length) {
            _templateSlots[slotIndex].mediaPath = result.first;
            _templateSlots[slotIndex].scale = 1.0;
            _templateSlots[slotIndex].offset = Offset.zero;
            _templateSlots[slotIndex].rotation = 0.0;
            _selectedTemplateSlotIndex = slotIndex;
          }
        });
      }
    } catch (e) {
      debugPrint('[StoryCreatorScreen] Slot replacement error: $e');
    }
  }

  Future<void> _onTapTemplateSlot(int slotIndex) async {
    // If slot already has image, select it to reveal contextual toolbar
    if (slotIndex < _templateSlots.length &&
        _templateSlots[slotIndex].mediaPath != null &&
        _templateSlots[slotIndex].mediaPath!.isNotEmpty) {
      setState(() {
        _selectedTemplateSlotIndex = slotIndex;
      });
      return;
    }

    // If slot is empty, open gallery in single-photo mode for this slot
    await _onReplaceTemplateSlot(slotIndex);
  }

  void _onUpdateTemplateSlot(
    int slotIndex,
    double scale,
    Offset offset,
    double rotation,
  ) {
    if (slotIndex < _templateSlots.length) {
      setState(() {
        _templateSlots[slotIndex].scale = scale;
        _templateSlots[slotIndex].offset = offset;
        _templateSlots[slotIndex].rotation = rotation;
      });
    }
  }

  void _onClearTemplateSlot(int slotIndex) {
    if (slotIndex < _templateSlots.length) {
      setState(() {
        _templateSlots[slotIndex].mediaPath = null;
        _templateSlots[slotIndex].scale = 1.0;
        _templateSlots[slotIndex].offset = Offset.zero;
        _templateSlots[slotIndex].rotation = 0.0;
        _selectedTemplateSlotIndex = null;
      });
    }
  }

  void _onSelectTemplate(StoryTemplateConfig newTemplate) {
    // Collect all available media: from template slots, image layers, active image, and initial mediaPaths
    final existingMedia = <String>[];
    for (final s in _templateSlots) {
      if (s.mediaPath != null && s.mediaPath!.trim().isNotEmpty) {
        if (!existingMedia.contains(s.mediaPath!.trim())) {
          existingMedia.add(s.mediaPath!.trim());
        }
      }
    }
    for (final l in _layers) {
      if (l.type == LayerType.image && l.text.trim().isNotEmpty) {
        if (!existingMedia.contains(l.text.trim())) {
          existingMedia.add(l.text.trim());
        }
      }
    }
    if (_activeMediaPath != null && _activeMediaPath!.trim().isNotEmpty) {
      if (!existingMedia.contains(_activeMediaPath!.trim())) {
        existingMedia.add(_activeMediaPath!.trim());
      }
    }
    if (widget.mediaPaths != null) {
      for (final p in widget.mediaPaths!) {
        if (p.trim().isNotEmpty && !existingMedia.contains(p.trim())) {
          existingMedia.add(p.trim());
        }
      }
    }

    // 1. Single Photo template: automatically use currently selected image with no extra picker
    if (newTemplate.slotCount == 1) {
      setState(() {
        _isTemplateApplied = true;
        _selectedTemplate = newTemplate;
        _selectedTemplateSlotIndex = null;
        final path = existingMedia.isNotEmpty ? existingMedia.first : _activeMediaPath;
        _templateSlots = [
          StoryTemplateSlot(
            id: 'slot_0',
            mediaPath: path,
          ),
        ];
        _layers.removeWhere((l) => l.type == LayerType.image);
        _selectedLayer = null;
      });
      return;
    }

    // 2. Multi-photo template: reuse all existing loaded photos immediately
    if (existingMedia.isNotEmpty) {
      setState(() {
        _isTemplateApplied = true;
        _selectedTemplate = newTemplate;
        _selectedTemplateSlotIndex = null;
        _templateSlots = List.generate(newTemplate.slotCount, (i) {
          final path = i < existingMedia.length ? existingMedia[i] : null;
          return StoryTemplateSlot(
            id: 'slot_$i',
            mediaPath: path,
          );
        });
        _layers.removeWhere((l) => l.type == LayerType.image);
        _selectedLayer = null;
      });
      return;
    }

    // 3. Multi-photo template without any photos: open Gallery in multi-select mode
    _pickPhotosForTemplate(newTemplate);
  }

  void _showTemplateReorderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(
              color: Color(0xFF18181A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFF2A2A2E), width: 1.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reorder Photos",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Drag items to reorder slot positions",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.check_rounded,
                        color: AppColors.communityAccent,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 110,
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _templateSlots.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final movedSlot = _templateSlots.removeAt(oldIndex);
                        _templateSlots.insert(newIndex, movedSlot);
                      });
                      setSheetState(() {});
                    },
                    itemBuilder: (context, index) {
                      final slot = _templateSlots[index];
                      final hasImage = slot.mediaPath != null &&
                          slot.mediaPath!.isNotEmpty;

                      return Container(
                        key: ValueKey('reorder_slot_${slot.id}_$index'),
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222226),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (hasImage)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: slot.mediaPath!.startsWith('assets/')
                                      ? Image.asset(slot.mediaPath!,
                                          fit: BoxFit.cover)
                                      : Image.file(
                                          _resolveStoryMediaFile(slot.mediaPath!),
                                          fit: BoxFit.cover),
                                ),
                              )
                            else
                              const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.white38,
                                  size: 24,
                                ),
                              ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(
                              bottom: 4,
                              right: 4,
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openTemplatePickerSheet() async {
    final currentPaths = <String>[];
    for (final s in _templateSlots) {
      if (s.mediaPath != null && s.mediaPath!.trim().isNotEmpty) {
        if (!currentPaths.contains(s.mediaPath!.trim())) {
          currentPaths.add(s.mediaPath!.trim());
        }
      }
    }
    for (final l in _layers) {
      if (l.type == LayerType.image && l.text.trim().isNotEmpty) {
        if (!currentPaths.contains(l.text.trim())) {
          currentPaths.add(l.text.trim());
        }
      }
    }
    if (_activeMediaPath != null && _activeMediaPath!.trim().isNotEmpty) {
      if (!currentPaths.contains(_activeMediaPath!.trim())) {
        currentPaths.add(_activeMediaPath!.trim());
      }
    }
    if (widget.mediaPaths != null) {
      for (final p in widget.mediaPaths!) {
        if (p.trim().isNotEmpty && !currentPaths.contains(p.trim())) {
          currentPaths.add(p.trim());
        }
      }
    }

    await StoryTemplatePickerSheet.show(
      context,
      currentTemplate: _isTemplateApplied ? _selectedTemplate : null,
      initialMediaPaths: currentPaths,
      onSelect: (selectedTmpl) {
        _onSelectTemplate(selectedTmpl);
      },
    );
  }

  void _editTemplateCaptionDialog([String? initial]) {
    final textCtrl = TextEditingController(
      text: initial ?? _templateCustomText ?? _selectedTemplate.defaultText ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Edit Caption",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.check_rounded,
                    color: AppColors.communityAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _templateCustomText = textCtrl.text.trim();
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Enter your text...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTextChanged() {
    if (mounted && _isFullScreenTextEditing) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _fullScreenTextController.removeListener(_onTextChanged);
    _captionController.dispose();
    _transformationController.dispose();
    _fullScreenTextController.dispose();
    _fullScreenTextFocusNode.dispose();
    super.dispose();
  }

  void _cycleGradient() {
    setState(() {
      _storyBgMode = StoryBgMode.gradient;
      _gradientIdx = (_gradientIdx + 1) % _bgPresets.length;
    });
  }

  // Immersive Full-Screen Text Editor — clean canvas and natural typing
  void _openFloatingTextEditor([MovableStoryLayer? existingLayer]) {
    setState(() {
      _editingTextLayer = existingLayer;
      _isFullScreenTextEditing = true;
      _activeContextTool = ActiveContextTool.none; // Clean canvas by default
      if (existingLayer != null) {
        _fullScreenTextController.text = existingLayer.text;
        _activeTextColor = existingLayer.color;
        _activeTextBgColor = existingLayer.bgColor;
        _activeFontStyle = existingLayer.fontStyle;
        _activeTextBgStyle = existingLayer.bgStyle;
        _activeTextEffect = existingLayer.effect;
        _activeTextAlign = existingLayer.alignment;
        _activeFontSize = existingLayer.fontSize;
        _activeTextScale = existingLayer.scale;
      } else {
        _fullScreenTextController.clear();
        _activeTextColor = Colors.white;
        _activeTextBgColor = null;
        _activeFontStyle = TextStyleType.classic; // Normal/Classic by default
        _activeTextBgStyle = TextBgStyle.none; // transparent by default
        _activeTextEffect = TextEffectType.none; // No shadow / flat by default
        _activeTextAlign = TextAlign.center;
        _activeFontSize = 28.0;
        _activeTextScale = 1.0;
      }
    });
    // Small delay so the overlay is built before requesting focus
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _fullScreenTextFocusNode.requestFocus();
    });
  }

  void _showStickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: _stickerCategories.keys.length,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add Campus Sticker",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  isScrollable: true,
                  indicatorColor: AppColors.communityAccent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: _stickerCategories.keys
                      .map((cat) => Tab(text: cat))
                      .toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: TabBarView(
                    children: _stickerCategories.values.map((stickers) {
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: stickers.length,
                        itemBuilder: (context, index) {
                          final st = stickers[index];
                          final isCatSticker =
                              st.contains('Cat') ||
                              st.contains('Kittens') ||
                              st.contains('Hugging');

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _layers.add(
                                  MovableStoryLayer(
                                    id: _generateUniqueLayerId('sticker'),
                                    type: LayerType.sticker,
                                    text: st,
                                    offset: const Offset(0.5, 0.5),
                                  ),
                                );
                              });
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurfaceSecondary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCatSticker
                                      ? Colors.white30
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (isCatSticker) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'assets/images/cat_stickers.png',
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      st,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHashtagSheet() {
    final inputCtrl = TextEditingController();
    String currentText = '';

    final suggestedTags = ['#CampusLinkKH', '#ACLEDAUniversity', '#StudyGroup'];
    final trendingTags = ['#Hackathon2026', '#Cybersecurity', '#FlutterDev'];
    final recentTags = ['#GenLinkLife', '#AUB2026'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            String formatTag(String raw) {
              var trimmed = raw.trim();
              if (trimmed.isEmpty) return '';
              if (!trimmed.startsWith('#')) return '#$trimmed';
              return trimmed;
            }

            final formattedLiveTag = formatTag(currentText);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Color(0xFF2F2F2F), width: 1),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Add Custom Hashtag",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Minimal Input Field
                      TextField(
                        controller: inputCtrl,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        onChanged: (val) {
                          setSheetState(() {
                            currentText = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Type a hashtag...",
                          hintStyle: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 15,
                          ),
                          prefixIcon: const Icon(
                            Icons.numbers_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1C1C1C),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2F2F2F),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),

                      // Live Preview Banner
                      if (formattedLiveTag.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text(
                              "Live Preview: ",
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                formattedLiveTag,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Section 1: Suggested
                      const Text(
                        "SUGGESTED",
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: suggestedTags.map((tag) {
                          final isSelected =
                              formattedLiveTag.toLowerCase() ==
                              tag.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              _addHashtagLayer(tag);
                              Navigator.pop(ctx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1C1C1C),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2F2F2F),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Section 2: Trending Today
                      const Text(
                        "TRENDING TODAY 🔥",
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: trendingTags.map((tag) {
                          final isSelected =
                              formattedLiveTag.toLowerCase() ==
                              tag.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              _addHashtagLayer(tag);
                              Navigator.pop(ctx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1C1C1C),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2F2F2F),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Section 3: Recent
                      const Text(
                        "RECENT",
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentTags.map((tag) {
                          final isSelected =
                              formattedLiveTag.toLowerCase() ==
                              tag.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              _addHashtagLayer(tag);
                              Navigator.pop(ctx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1C1C1C),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2F2F2F),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // White Pill-Shaped Primary Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final tag = formatTag(inputCtrl.text);
                            if (tag.isNotEmpty) {
                              _addHashtagLayer(tag);
                            }
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                          label: const Text(
                            "Add Hashtag",
                            style: TextStyle(
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
              ),
            );
          },
        );
      },
    );
  }

  void _addHashtagLayer(String tag) {
    setState(() {
      _layers.add(
        MovableStoryLayer(
          id: _generateUniqueLayerId('hashtag'),
          type: LayerType.hashtag,
          text: tag,
          offset: const Offset(0.5, 0.5),
        ),
      );
    });
  }

  void _showMentionSheet() {
    final inputCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Mention Classmate / User",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: inputCtrl,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: "e.g. @SoknyEnat",
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(
                    Icons.alternate_email_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Suggested Members:",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _mentionSuggestions.map((m) {
                  return ActionChip(
                    backgroundColor: AppColors.darkSurfaceSecondary,
                    label: Text(
                      m,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      _addMentionLayer(m);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    var val = inputCtrl.text.trim();
                    if (val.isNotEmpty) {
                      if (!val.startsWith('@')) val = '@$val';
                      _addMentionLayer(val);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Add Mention",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addMentionLayer(String mention) {
    final formatted = mention.startsWith('@') ? mention : '@$mention';

    setState(() {
      final newLayer = MovableStoryLayer(
        id: _generateUniqueLayerId('mention'),
        type: LayerType.mention,
        text: formatted,
        offset: const Offset(0.5, 0.5),
        scale: 1.0,
      );
      _layers.add(newLayer);
      _selectedLayer = newLayer;
    });
  }

  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Story Visibility & Privacy",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              {
                'title': 'Public',
                'sub': 'Visible to all CampusLink KH students',
                'icon': Icons.public,
              },
              {
                'title': 'Friends',
                'sub': 'Visible to classmates & followers only',
                'icon': Icons.people,
              },
              {
                'title': 'Specific Friends',
                'sub': 'Selected study members',
                'icon': Icons.group_add,
              },
              {
                'title': 'Only Me',
                'sub': 'Private draft story',
                'icon': Icons.lock,
              },
            ].map((opt) {
              final title = opt['title'] as String;
              return ListTile(
                leading: Icon(
                  opt['icon'] as IconData,
                  color: _selectedVisibility == title
                      ? AppColors.communityAccent
                      : Colors.white54,
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  opt['sub'] as String,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: _selectedVisibility == title
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.communityAccent,
                      )
                    : null,
                onTap: () {
                  setState(
                    () => _storySettings = _storySettings.copyWith(
                      visibility: StoryPrivacy.fromString(title),
                    ),
                  );
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhotoLayer() async {
    try {
      final picker = ImagePicker();
      final XFile? media = await picker.pickMedia(imageQuality: 95);
      if (media != null && mounted) {
        final currentImagesCount = _layers.where((l) => l.type == LayerType.image).length;
        final offset = _calculateInitialLayerOffset(currentImagesCount, currentImagesCount + 1);
        final newLayer = MovableStoryLayer(
          id: _generateUniqueLayerId('image'),
          type: LayerType.image,
          text: media.path,
          offset: offset,
          scale: 1.0,
          rotation: 0.0,
        );
        setState(() {
          _layers.add(newLayer);
          _selectedLayer = newLayer;
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showDanger(
          context: context,
          title: "Photo Selection Error",
          message: "Could not pick image: $e",
        );
      }
    }
  }

  Future<void> _replaceMedia() async {
    try {
      final picker = ImagePicker();
      final XFile? media = await picker.pickMedia(imageQuality: 95);
      if (media != null && mounted) {
        setState(() {
          _activeMediaPath = media.path;
          _transformationController.value = Matrix4.identity();
          _imageRotation = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showDanger(
          context: context,
          title: "Media Error",
          message: "Could not replace media: $e",
        );
      }
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Widget _buildErrorMediaPlaceholder() {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_rounded,
              color: AppColors.danger,
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              "Unable to load image.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _replaceMedia,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text("Choose Another Image"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isVideoFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.m4v') ||
        p.endsWith('.webm') ||
        p.endsWith('.avi') ||
        p.endsWith('.mkv') ||
        p.endsWith('.flv');
  }

  File _resolveFile(String rawPath) {
    final clean = rawPath.replaceAll(RegExp(r'^file://'), '');
    return File(clean);
  }

  bool _isVideoPlaying = true;

  Widget _buildVideoPreviewCanvas(File file) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                          ),
                          child: Icon(
                            _isVideoPlaying
                                ? Icons.movie_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  file.path.split(RegExp(r'[/\\]')).last,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isVideoPlaying = !_isVideoPlaying;
                      });
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isVideoPlaying ? 0.4 : 0.9,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isVideoPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Video Timeline Controls Overlay
        Positioned(
          bottom: 90,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(
                  _isVideoPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Text(
                  "00:05",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _isVideoPlaying ? 0.45 : 0.0,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "00:15",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleZoomDoubleTap() {
    setState(() {
      final currentScale = _transformationController.value.getMaxScaleOnAxis();
      if (currentScale > 1.05) {
        _transformationController.value = Matrix4.identity();
      } else {
        _transformationController.value = Matrix4.diagonal3Values(
          2.0,
          2.0,
          1.0,
        );
      }
    });
  }

  Widget _buildImageCanvas(File file) {
    final size = MediaQuery.of(context).size;

    Widget imgWidget;
    if (_activeMediaPath != null &&
        _activeMediaPath!.startsWith('assets/')) {
      imgWidget = Image.asset(
        _activeMediaPath!,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (ctx, err, stack) =>
            _buildErrorMediaPlaceholder(),
      );
    } else if (file.existsSync()) {
      imgWidget = Image.file(
        file,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (ctx, err, stack) =>
            _buildErrorMediaPlaceholder(),
      );
    } else if (_activeMediaPath != null &&
        (_activeMediaPath!.startsWith('http://') ||
            _activeMediaPath!.startsWith('https://'))) {
      imgWidget = Image.network(
        _activeMediaPath!,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (ctx, err, stack) =>
            _buildErrorMediaPlaceholder(),
      );
    } else {
      imgWidget = Image.file(
        file,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (ctx, err, stack) =>
            _buildErrorMediaPlaceholder(),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedLayer = null);
      },
      onDoubleTap: () {
        setState(() {
          if (_bgImageScale > 1.05) {
            _bgImageScale = 1.0;
            _bgImageOffset = Offset.zero;
          } else {
            _bgImageScale = 2.0;
          }
        });
      },
      onScaleStart: (details) {
        _bgBaseScale = _bgImageScale;
        _bgBaseOffset = _bgImageOffset;
        _bgBaseFocalPoint = details.focalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          // 1. Smooth Pinch-to-Zoom (0.1x to 4.0x)
          if (details.scale != 1.0) {
            _bgImageScale = (_bgBaseScale * details.scale).clamp(0.10, 4.0);
          }

          // 2. Smooth 360° Multi-Directional Pan (Left, Right, Up, Down)
          final delta = details.focalPoint - _bgBaseFocalPoint;
          final maxPanX = size.width * 0.85;
          final maxPanY = size.height * 0.85;

          final nextX = (_bgBaseOffset.dx + delta.dx).clamp(-maxPanX, maxPanX);
          final nextY = (_bgBaseOffset.dy + delta.dy).clamp(-maxPanY, maxPanY);

          _bgImageOffset = Offset(nextX, nextY);
        });
      },
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Transform.translate(
            offset: _bgImageOffset,
            child: Transform.scale(
              scale: _bgImageScale,
              child: RotatedBox(
                quarterTurns: (_imageRotation / 90).round() % 4,
                child: SizedBox.expand(child: imgWidget),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextStoryTemplateCanvas() {
    Widget canvasBg;

    if (_storyBgMode == StoryBgMode.none) {
      canvasBg = Container(
        key: const ValueKey('canvas_bg_none'),
        color: const Color(0xFF0B0B0E),
      );
    } else if (_storyBgMode == StoryBgMode.solid &&
        _selectedSolidBgColor != null) {
      canvasBg = Container(
        key: ValueKey('canvas_bg_solid_${_selectedSolidBgColor!.toARGB32()}'),
        color: _selectedSolidBgColor,
      );
    } else {
      final preset = _bgPresets[_gradientIdx.clamp(0, _bgPresets.length - 1)];
      canvasBg = Container(
        key: ValueKey('canvas_bg_gradient_$_gradientIdx'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: preset.colors,
            begin: preset.begin,
            end: preset.end,
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: canvasBg,
    );
  }

  Widget _buildUniqueTemplateThumbnail(StoryTemplateModel tpl) {
    switch (tpl.id) {
      case 'minimal':
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            Center(
              child: Container(width: 26, height: 1.5, color: Colors.white70),
            ),
          ],
        );

      case 'notebook':
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _NotebookLinesPainter()),
            ),
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1.2,
                color: const Color(0xFFEF4444).withValues(alpha: 0.60),
              ),
            ),
          ],
        );

      case 'sticky_note':
        return Center(
          child: Stack(
            children: [
              Container(
                width: 44,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF08A),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 12,
                right: 12,
                child: Container(height: 4, color: Colors.amber.shade300),
              ),
            ],
          ),
        );

      case 'quote':
        return Stack(
          children: [
            const Positioned(
              top: 4,
              left: 6,
              child: Text(
                "“",
                style: TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  height: 1.0,
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 2, color: Colors.white70, width: 26),
                  const SizedBox(height: 3),
                  Container(height: 2, color: Colors.white38, width: 16),
                ],
              ),
            ),
          ],
        );

      case 'campus':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF022C22)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );

      case 'career':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.business_center_rounded,
                  color: Color(0xFF93C5FD),
                  size: 16,
                ),
                const SizedBox(height: 4),
                Container(width: 24, height: 2, color: const Color(0xFF60A5FA)),
              ],
            ),
          ),
        );

      case 'pastel':
        return Stack(
          children: [
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF472B6).withValues(alpha: 0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -8,
              left: -8,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );

      case 'coffee':
        return Stack(
          children: [
            if (tpl.bgImageAssetPath != null)
              Positioned.fill(
                child: Image.asset(
                  tpl.bgImageAssetPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                ),
              ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.coffee_rounded,
                  color: Color(0xFFFDE68A),
                  size: 12,
                ),
              ),
            ),
          ],
        );

      case 'ocean':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0C4A6E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Icon(Icons.waves_rounded, color: Colors.white70, size: 20),
          ),
        );

      case 'dark':
        return Container(
          color: const Color(0xFF030712),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );

      case 'motivation':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "GO",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMiniTemplatePreview(StoryTemplateModel tpl, bool isSel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: isSel ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSel ? 1.0 : 0.65,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tpl.backgroundColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSel
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSel ? 2.0 : 1.0,
                    ),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: tpl.backgroundColors.first.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: _buildUniqueTemplateThumbnail(tpl),
                  ),
                ),

                // Small Top-Right Checkmark Badge for Selected Card
                if (isSel)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 9,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Smaller & Lighter Template Label
        Text(
          tpl.name,
          style: TextStyle(
            color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.50),
            fontSize: 10.5,
            fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryTemplateSelectorStrip() {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _storyTemplates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (ctx, idx) {
          final tpl = _storyTemplates[idx];
          final isSel = _selectedTemplateIdx == idx;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTemplateIdx = idx;
                _gradientIdx = idx % _gradients.length;
                if (tpl.textColor != Colors.white) {
                  _activeTextColor = tpl.textColor;
                }
              });
            },
            child: _buildMiniTemplatePreview(tpl, isSel),
          );
        },
      ),
    );
  }

  Widget _buildTemplateStoryCanvas() {
    Widget bgWidget;
    if (_storyBgMode == StoryBgMode.solid && _selectedSolidBgColor != null) {
      bgWidget = Container(
        key: ValueKey('solid_${_selectedSolidBgColor!.toARGB32()}'),
        color: _selectedSolidBgColor,
      );
    } else {
      final preset = _bgPresets[_gradientIdx.clamp(0, _bgPresets.length - 1)];
      bgWidget = Container(
        key: ValueKey('gradient_${preset.name}'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: preset.colors,
            begin: preset.begin,
            end: preset.end,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_selectedTemplateSlotIndex != null) {
          setState(() => _selectedTemplateSlotIndex = null);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: bgWidget,
            ),
          ),
          Positioned.fill(
            child: StoryTemplateCanvas(
              template: _selectedTemplate,
              slots: _templateSlots,
              isInteractive: true,
              selectedSlotIndex: _selectedTemplateSlotIndex,
              onSelectSlot: (idx) {
                setState(() => _selectedTemplateSlotIndex = idx);
              },
              onTapSlot: _onTapTemplateSlot,
              onReplaceSlot: _onReplaceTemplateSlot,
              onUpdateSlot: _onUpdateTemplateSlot,
              onClearSlot: _onClearTemplateSlot,
              onEditText: (text) => _editTemplateCaptionDialog(text),
              customText: _templateCustomText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCanvas() {
    if (widget.type == StoryType.template || _isTemplateApplied) {
      return _buildTemplateStoryCanvas();
    }

    if (_activeMediaPath == null ||
        _activeMediaPath!.isEmpty ||
        widget.type == StoryType.text) {
      return _buildTextStoryTemplateCanvas();
    }

    final isVideo = _isVideoFile(_activeMediaPath!);
    final file = _resolveFile(_activeMediaPath!);

    if (!file.existsSync() && !_activeMediaPath!.startsWith('assets/')) {
      return _buildErrorMediaPlaceholder();
    }

    if (isVideo) {
      return _buildVideoPreviewCanvas(file);
    }

    return _buildImageCanvas(file);
  }

  Future<void> _publishStory() async {
    if (_isPublishing) return;

    // 1. If user is currently typing in the full-screen text editor, commit the text into layers first
    if (_isFullScreenTextEditing) {
      _closeFullScreenTextEditor(save: true);
    }

    final String textFromInput = _fullScreenTextController.text.trim();
    final String caption = _captionController.text.trim();
    final hasTextLayer = _layers.any(
      (l) => l.type == LayerType.text && l.text.trim().isNotEmpty,
    );
    final hasOtherLayer = _layers.any((l) => l.type != LayerType.text);

    // 2. Validate non-empty story for text mode
    if (widget.type == StoryType.text &&
        !hasTextLayer &&
        !hasOtherLayer &&
        textFromInput.isEmpty &&
        caption.isEmpty) {
      AppNotificationBanner.showDanger(
        context: context,
        title: "Empty Story",
        message:
            "Please type some text or add stickers before publishing your story.",
        icon: Icons.edit_note_rounded,
      );
      return;
    }

    // Validate template story slots
    final isTemplateStory = widget.type == StoryType.template || _isTemplateApplied;
    final hasTemplateSlotImage = _templateSlots.any(
      (s) => s.mediaPath != null && s.mediaPath!.trim().isNotEmpty,
    );
    if (isTemplateStory) {
      if (_selectedTemplate.slotCount > 1) {
        final filledCount = _templateSlots
            .where((s) => s.mediaPath != null && s.mediaPath!.trim().isNotEmpty)
            .length;
        if (filledCount < _selectedTemplate.slotCount) {
          AppNotificationBanner.showDanger(
            context: context,
            title: "Incomplete Template",
            message:
                "Please select ${_selectedTemplate.slotCount} photos for this layout.",
            icon: Icons.dashboard_customize_rounded,
          );
          return;
        }
      } else if (!hasTemplateSlotImage &&
          !hasTextLayer &&
          !hasOtherLayer &&
          textFromInput.isEmpty &&
          caption.isEmpty &&
          (_templateCustomText == null || _templateCustomText!.trim().isEmpty)) {
        AppNotificationBanner.showDanger(
          context: context,
          title: "Empty Template",
          message: "Please add at least one photo to your template before publishing.",
          icon: Icons.dashboard_customize_rounded,
        );
        return;
      }
    }

    setState(() => _isPublishing = true);

    try {
      final controller = Get.isRegistered<StoryController>()
          ? Get.find<StoryController>()
          : Get.put(StoryController(), permanent: true);

      // Extract primary text content
      String? textContent;
      if (_templateCustomText != null && _templateCustomText!.isNotEmpty) {
        textContent = _templateCustomText;
      } else if (caption.isNotEmpty) {
        textContent = caption;
      } else if (hasTextLayer) {
        textContent = _layers.firstWhere((l) => l.type == LayerType.text).text;
      } else if (textFromInput.isNotEmpty) {
        textContent = textFromInput;
      }

      // Extract active canvas background colors for Text Story mode
      String startHex;
      String endHex;
      if (_storyBgMode == StoryBgMode.solid && _selectedSolidBgColor != null) {
        final hex =
            '0x${_selectedSolidBgColor!.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
        startHex = hex;
        endHex = hex;
      } else if (_storyBgMode == StoryBgMode.none) {
        startHex = '0xFF0B0B0E';
        endHex = '0xFF0B0B0E';
      } else {
        final preset = _bgPresets[_gradientIdx.clamp(0, _bgPresets.length - 1)];
        startHex =
            '0x${preset.colors.first.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
        endHex =
            '0x${preset.colors.last.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
      }

      bool success = false;
      final effectiveType = isTemplateStory
          ? StoryType.template
          : ((_activeMediaPath != null && _isVideoFile(_activeMediaPath!))
              ? StoryType.video
              : widget.type);
      final effectiveMediaUrl = isTemplateStory
          ? (_templateSlots.firstWhereOrNull((s) => s.mediaPath != null && s.mediaPath!.isNotEmpty)?.mediaPath ?? _activeMediaPath)
          : _activeMediaPath;

      if (widget.existingStory != null) {
        final newSettings = StorySettings(
          visibility: _selectedVisibility == 'Public' ? StoryPrivacy.public : (_selectedVisibility == 'Only Me' ? StoryPrivacy.onlyMe : StoryPrivacy.friends),
          replyPermission: widget.existingStory!.settings.replyPermission,
          allowReactions: widget.existingStory!.settings.allowReactions,
        );
        final updatedStory = StoryItemModel(
          id: widget.existingStory!.id,
          type: effectiveType,
          mediaUrl: effectiveMediaUrl,
          textContent: textContent,
          bgGradientStart: startHex,
          bgGradientEnd: endHex,
          location: widget.existingStory!.location,
          timeAgo: widget.existingStory!.timeAgo,
          createdAt: widget.existingStory!.createdAt,
          settings: newSettings,
          layers: List.from(_layers),
          viewers: List.from(widget.existingStory!.viewers),
          bgScale: _bgImageScale,
          bgOffset: _bgImageOffset,
          bgRotation: _imageRotation,
          templateId: isTemplateStory ? _selectedTemplate.id : null,
          templateSlots: isTemplateStory ? List.from(_templateSlots) : const [],
        );
        updatedStory.likesCount = widget.existingStory!.likesCount;
        updatedStory.isLiked = widget.existingStory!.isLiked;
        updatedStory.isViewed = widget.existingStory!.isViewed;
        updatedStory.viewersCount = widget.existingStory!.viewersCount;

        success = await controller.updateStory(widget.existingStory!.id, updatedStory);
      } else {
        success = await controller.publishStory(
          type: effectiveType,
          mediaUrl: effectiveMediaUrl,
          textContent: textContent,
          storySettings: _storySettings,
          visibility: _selectedVisibility,
          replyPrivacy: _replyPrivacy,
          allowReactions: _allowReactions,
          bgGradientStart: startHex,
          bgGradientEnd: endHex,
          layers: List.from(_layers),
          bgScale: _bgImageScale,
          bgOffset: _bgImageOffset,
          bgRotation: _imageRotation,
          templateId: isTemplateStory ? _selectedTemplate.id : null,
          templateSlots: isTemplateStory ? List.from(_templateSlots) : null,
        );
      }

      if (mounted) {
        if (success) {
          // 1. Show notification banner immediately
          AppNotificationBanner.showSuccess(
            context: context,
            title: "Story posted successfully!",
            message: "Your story is now live.",
            icon: Icons.check_circle_rounded,
            duration: const Duration(seconds: 3),
          );

          // 2. Clear gallery draft
          if (Get.isRegistered<StoryGalleryController>()) {
            try {
              Get.find<StoryGalleryController>().clearDraft();
            } catch (_) {}
          }

          // 3. Return to Community screen smoothly
          if (widget.existingStory != null) {
            Get.back(result: true);
          } else {
            const storyRouteNames = {
              '/StoryGalleryScreen',
              '/InAppCameraScreen',
              '/StoryCreatorScreen',
            };

            Get.until((route) {
              if (route.isFirst) return true;
              final name = route.settings.name;
              if (name != null && storyRouteNames.contains(name)) {
                return false;
              }
              return true;
            });
          }
        } else {
          setState(() => _isPublishing = false);
          AppNotificationBanner.showDanger(
            context: context,
            title: "Couldn't post story",
            message: "Please try again.",
            icon: Icons.error_outline_rounded,
          );
        }
      }
    } catch (e, stack) {
      debugPrint('[StoryCreator] Publish story error: $e\n$stack');
      if (mounted) {
        setState(() => _isPublishing = false);
        AppNotificationBanner.showDanger(
          context: context,
          title: "Couldn't post story",
          message: "Please try again.",
        );
      }
    } finally {
      if (mounted && _isPublishing) {
        setState(() => _isPublishing = false);
      }
    }
  }

  TextStyle _getLayerTextStyle(
    TextStyleType fontStyle,
    Color color,
    TextBgStyle bgStyle, {
    TextEffectType effect = TextEffectType.none,
  }) {
    FontWeight weight = FontWeight.w600;
    FontStyle style = FontStyle.normal;
    double letterSpacing = 0.2;
    double height = 1.25;
    List<Shadow>? textShadows;
    String? fontFamily;

    switch (fontStyle) {
      case TextStyleType.classic:
        weight = FontWeight.w600;
        letterSpacing = 0.2;
        break;
      case TextStyleType.elegant: // Deco
        style = FontStyle.italic;
        weight = FontWeight.w600;
        letterSpacing = 0.8;
        break;
      case TextStyleType.bold: // Bubble
        weight = FontWeight.w900;
        letterSpacing = -0.3;
        break;
      case TextStyleType.modern: // Modern
        weight = FontWeight.w800;
        letterSpacing = 0.8;
        break;
      case TextStyleType.minimal: // Minimal Clean
        weight = FontWeight.w700;
        letterSpacing = 1.2;
        break;
      case TextStyleType.handwriting: // Script
        weight = FontWeight.w500;
        style = FontStyle.italic;
        letterSpacing = 0.5;
        break;
      case TextStyleType.coding: // Code
        weight = FontWeight.w600;
        fontFamily = 'monospace';
        letterSpacing = -0.2;
        break;
      default:
        weight = FontWeight.w700;
        break;
    }

    // Explicit Text Effects system (Independent from Font Styles)
    switch (effect) {
      case TextEffectType.shadow:
        textShadows = [
          Shadow(
            blurRadius: 8.0,
            color: Colors.black.withValues(alpha: 0.85),
            offset: const Offset(0, 2),
          ),
          Shadow(
            blurRadius: 16.0,
            color: Colors.black.withValues(alpha: 0.50),
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case TextEffectType.glow:
        textShadows = [
          Shadow(
            blurRadius: 8.0,
            color: color.withValues(alpha: 0.95),
            offset: Offset.zero,
          ),
          Shadow(
            blurRadius: 20.0,
            color: color.withValues(alpha: 0.85),
            offset: Offset.zero,
          ),
          Shadow(blurRadius: 36.0, color: color, offset: Offset.zero),
        ];
        break;
      case TextEffectType.outline:
      case TextEffectType.none:
        textShadows = null; // Clean, flat, NO shadow by default
        break;
    }

    return TextStyle(
      color: color,
      fontSize: 28,
      fontWeight: weight,
      fontStyle: style,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
      height: height,
      shadows: textShadows,
    );
  }

  double _gestureBaseScale = 1.0;
  double _gestureBaseRotation = 0.0;
  double _activeTextScale = 1.0;
  bool _isInteractingLayer = false;
  bool _isHoveringDeleteZone = false;

  Widget _buildLayerWidget(MovableStoryLayer layer) {
    final isDeleting = _deletingLayerIds.contains(layer.id);
    final isEditingThisLayer =
        _isFullScreenTextEditing && layer == _editingTextLayer;

    if (_isFullScreenTextEditing && layer == _editingTextLayer) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxCanvasWidth = screenWidth * 0.85;

    Widget content;

    switch (layer.type) {
      case LayerType.image:
        final localFile = _resolveStoryMediaFile(layer.text);
        Widget imgWidget;
        if (localFile.existsSync()) {
          imgWidget = Image.file(
            localFile,
            width: 180,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) =>
                _buildErrorMediaPlaceholder(),
          );
        } else if (layer.text.startsWith('assets/')) {
          imgWidget = Image.asset(
            layer.text,
            width: 180,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) =>
                _buildErrorMediaPlaceholder(),
          );
        } else {
          imgWidget = Image.network(
            layer.text,
            width: 180,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) =>
                _buildErrorMediaPlaceholder(),
          );
        }

        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedLayer?.id == layer.id
                    ? Colors.white
                    : Colors.transparent,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imgWidget,
            ),
          ),
        );
        break;

      case LayerType.text:
        final hasBg = layer.bgStyle != TextBgStyle.none;
        final baseStyle = _getLayerTextStyle(
          layer.fontStyle,
          layer.color,
          layer.bgStyle,
          effect: layer.effect,
        ).copyWith(fontSize: layer.fontSize);

        Color? boxColor;
        BoxBorder? boxBorder;
        List<BoxShadow>? boxShadow;

        if (layer.bgStyle == TextBgStyle.filled) {
          boxColor = layer.bgColor ?? Colors.white;
          boxShadow = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ];
        } else if (layer.bgStyle == TextBgStyle.rounded) {
          boxColor = (layer.bgColor ?? Colors.black).withValues(alpha: 0.65);
          boxShadow = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];
        } else if (layer.bgStyle == TextBgStyle.outline) {
          boxColor = Colors.transparent;
          boxBorder = Border.all(
            color: layer.bgColor ?? layer.color,
            width: 2.0,
          );
        }

        final isSelected = _selectedLayer?.id == layer.id;
        final textLuminance = layer.color.computeLuminance();
        final textDisplayColor =
            (layer.bgStyle == TextBgStyle.filled &&
                layer.bgColor == null &&
                layer.color == Colors.white)
            ? Colors.black
            : layer.color;

        Widget textWidget;
        if (layer.effect == TextEffectType.outline) {
          final strokeColor = textLuminance > 0.5 ? Colors.black : Colors.white;
          textWidget = Stack(
            children: [
              Text(
                layer.text,
                softWrap: true,
                textAlign: layer.alignment,
                style: baseStyle.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3.5
                    ..color = strokeColor,
                  shadows: null,
                ),
              ),
              Text(
                layer.text,
                softWrap: true,
                textAlign: layer.alignment,
                style: baseStyle.copyWith(
                  color: textDisplayColor,
                  shadows: null,
                ),
              ),
            ],
          );
        } else {
          textWidget = Text(
            layer.text,
            softWrap: true,
            textAlign: layer.alignment,
            style: baseStyle.copyWith(color: textDisplayColor),
          );
        }

        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth * 0.92),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: hasBg
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(14),
              border: isSelected && !hasBg
                  ? Border.all(color: Colors.white30, width: 1.0)
                  : boxBorder,
              boxShadow: boxShadow,
            ),
            child: textWidget,
          ),
        );
        break;

      case LayerType.sticker:
        final isAssetSticker = layer.text.startsWith('assets/');
        if (isAssetSticker) {
          content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCanvasWidth),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                layer.text,
                width: 120,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) =>
                    Text(layer.text, style: const TextStyle(fontSize: 48)),
              ),
            ),
          );
        } else {
          content = Text(layer.text, style: const TextStyle(fontSize: 54));
        }
        break;

      case LayerType.hashtag:
        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.communityAccent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              layer.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
        break;

      case LayerType.mention:
        final cleanMention = layer.text.startsWith('@')
            ? layer.text
            : '@${layer.text}';
        final hasBg = layer.bgStyle != TextBgStyle.none;
        final textColor = layer.bgStyle == TextBgStyle.filled
            ? Colors.black
            : Colors.white;

        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: layer.bgStyle == TextBgStyle.filled
                  ? Colors.white
                  : (layer.bgStyle == TextBgStyle.rounded
                        ? Colors.black.withValues(alpha: 0.65)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: layer.bgStyle == TextBgStyle.outline
                  ? Border.all(color: Colors.white, width: 2.0)
                  : null,
              boxShadow: hasBg
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              cleanMention,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
        break;

      case LayerType.location:
        final cleanLocation = layer.text.replaceAll('📍', '').trim();
        final hasBg = layer.bgStyle != TextBgStyle.none;
        final textColor = layer.bgStyle == TextBgStyle.filled
            ? Colors.black
            : Colors.white;

        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: layer.bgStyle == TextBgStyle.filled
                  ? AppColors.communityAccent
                  : (layer.bgStyle == TextBgStyle.rounded
                        ? Colors.black.withValues(alpha: 0.65)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(20),
              border: layer.bgStyle == TextBgStyle.outline
                  ? Border.all(color: AppColors.communityAccent, width: 2.0)
                  : null,
              boxShadow: hasBg
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, color: textColor, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    child: Text(cleanLocation, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
        );
        break;

      case LayerType.music:
        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.communityAccent, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.communityAccent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    layer.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
    }

    final isTextStory = widget.type == StoryType.text;

    // For Text-Only stories: text layer is always centered on canvas and not draggable
    if (isTextStory && layer.type == LayerType.text) {
      return Positioned.fill(
        child: Align(
          alignment: Alignment.center,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            opacity: (isDeleting || isEditingThisLayer) ? 0.0 : 1.0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openFloatingTextEditor(layer),
              onDoubleTap: () => _openFloatingTextEditor(layer),
              child: content,
            ),
          ),
        ),
      );
    }

    final currentPos = layer.getCanvasOffset(Size(screenWidth, screenHeight));

    return Positioned(
      key: ValueKey(layer.id),
      left: currentPos.dx,
      top: currentPos.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: (isDeleting || isEditingThisLayer) ? 0.0 : 1.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          scale: isDeleting ? 0.9 : 1.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (layer.type == LayerType.text) {
                _openFloatingTextEditor(layer);
              } else {
                setState(() {
                  _selectedLayer = layer;

                  // Cycle color style variant on tap for Mention and Location tags
                  if (layer.type == LayerType.mention ||
                      layer.type == LayerType.location) {
                    if (layer.bgStyle == TextBgStyle.rounded) {
                      layer.bgStyle = TextBgStyle.filled;
                    } else if (layer.bgStyle == TextBgStyle.filled) {
                      layer.bgStyle = TextBgStyle.outline;
                    } else {
                      layer.bgStyle = TextBgStyle.rounded;
                    }
                  }
                });
              }
            },
            onDoubleTap: () {
              if (layer.type == LayerType.text) {
                _openFloatingTextEditor(layer);
              } else if (layer.type == LayerType.image) {
                setState(() {
                  layer.scale = 1.0;
                  layer.rotation = 0.0;
                });
              }
            },
            onScaleStart: (details) {
              _gestureBaseScale = layer.scale;
              _gestureBaseRotation = layer.rotation;
              setState(() {
                _selectedLayer = layer;
                _isInteractingLayer = true;
              });
            },
            onScaleUpdate: (details) {
              setState(() {
                _selectedLayer = layer;

                if (details.scale != 1.0) {
                  layer.scale = (_gestureBaseScale * details.scale).clamp(
                    0.4,
                    3.8,
                  );
                }

                if (details.rotation != 0.0) {
                  layer.rotation = _gestureBaseRotation + details.rotation;
                }

                final currentOffset =
                    layer.getCanvasOffset(Size(screenWidth, screenHeight));
                final nextX = currentOffset.dx + details.focalPointDelta.dx;
                final nextY = currentOffset.dy + details.focalPointDelta.dy;

                layer.setFromCanvasOffset(
                  Offset(nextX, nextY),
                  Size(screenWidth, screenHeight),
                );
                final currentY =
                    layer.getCanvasOffset(Size(screenWidth, screenHeight)).dy;
                _isHoveringDeleteZone = currentY > (screenHeight - 160.0);
              });
            },
            onScaleEnd: (details) {
              final currentY =
                  layer.getCanvasOffset(Size(screenWidth, screenHeight)).dy;
              final isOverDeleteArea = currentY > (screenHeight - 160.0);
              if (isOverDeleteArea) {
                _deleteLayerInstantly(layer);
              }
              setState(() {
                _isInteractingLayer = false;
                _isHoveringDeleteZone = false;
              });
            },
            child: Transform.scale(
              scale: layer.scale,
              child: Transform.rotate(angle: layer.rotation, child: content),
            ),
          ),
        ),
      ),
    ),
  );
  }

  void _showLocationSheet() {
    final searchController = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = _locationOptions
              .where((loc) => loc.toLowerCase().contains(query.toLowerCase()))
              .toList();
          final mediaQuery = MediaQuery.of(ctx);
          final maxHeight = mediaQuery.size.height * 0.75;

          return Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: Container(
              height: maxHeight,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfacePrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add Location Tag",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Rounded Search Bar
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) => setSheetState(() => query = val),
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white38,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.darkSurfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                "No locations found",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final loc = filtered[index];
                                final distances = [
                                  "250 m",
                                  "600 m",
                                  "1.2 km",
                                  "1.8 km",
                                  "2.5 km",
                                ];
                                final distanceStr =
                                    distances[index % distances.length];

                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      loc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      distanceStr,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        final newLayer = MovableStoryLayer(
                                          id: _generateUniqueLayerId('location'),
                                          type: LayerType.location,
                                          text: loc,
                                          offset: const Offset(0.5, 0.5),
                                        );
                                        _layers.add(newLayer);
                                        _selectedLayer = newLayer;
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMusicSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Background Music Track",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._musicOptions.map((track) {
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.communityAccent,
                  ),
                  title: Text(
                    track,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  onTap: () {
                    setState(() {
                      _layers.add(
                        MovableStoryLayer(
                          id: _generateUniqueLayerId('music'),
                          type: LayerType.music,
                          text: track,
                          offset: const Offset(0.5, 0.5),
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  int _activeTextToolbarTab = 0;

  Widget _buildTikTokInlineTextToolbar(MovableStoryLayer layer) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final primaryColors = [Colors.white, Colors.black, const Color(0xFF8E8E93)];

    final accentColors = [
      const Color(0xFFF43F5E),
      const Color(0xFFFB923C),
      const Color(0xFFFACC15),
      const Color(0xFF34D399),
      const Color(0xFF38BDF8),
      const Color(0xFFA855F7),
    ];

    final allColors = [...primaryColors, ...accentColors];

    final fontOptions = [
      TextStyleType.classic,
      TextStyleType.bold,
      TextStyleType.modern,
      TextStyleType.campus,
      TextStyleType.coding,
      TextStyleType.khmer,
      TextStyleType.handwriting,
    ];

    return Positioned(
      bottom: keyboardHeight > 0 ? keyboardHeight + 8 : 24,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xF2121212),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2F2F2F), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. Font Style (Aa)
                IconButton(
                  icon: Text(
                    "Aa",
                    style: TextStyle(
                      color: _activeTextToolbarTab == 0
                          ? Colors.white
                          : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () => setState(() => _activeTextToolbarTab = 0),
                ),

                // 2. Text Color (🎨)
                IconButton(
                  icon: Icon(
                    Icons.palette_outlined,
                    color: _activeTextToolbarTab == 1
                        ? Colors.white
                        : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _activeTextToolbarTab = 1),
                ),

                // 3. Background Style (⬛)
                IconButton(
                  icon: Icon(
                    Icons.subtitles_rounded,
                    color: _activeTextToolbarTab == 2
                        ? Colors.white
                        : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _activeTextToolbarTab = 2),
                ),

                // 4. Alignment Toggle (☰)
                IconButton(
                  icon: Icon(
                    layer.alignment == TextAlign.left
                        ? Icons.format_align_left_rounded
                        : (layer.alignment == TextAlign.right
                              ? Icons.format_align_right_rounded
                              : Icons.format_align_center_rounded),
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (layer.alignment == TextAlign.center) {
                        layer.alignment = TextAlign.left;
                      } else if (layer.alignment == TextAlign.left) {
                        layer.alignment = TextAlign.right;
                      } else {
                        layer.alignment = TextAlign.center;
                      }
                    });
                  },
                ),
              ],
            ),

            const Divider(color: Color(0xFF262626), height: 12),

            if (_activeTextToolbarTab == 0) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: fontOptions.map((fStyle) {
                    final isSelected = layer.fontStyle == fStyle;
                    final textStyle = _getLayerTextStyle(
                      fStyle,
                      isSelected ? Colors.black : Colors.white,
                      TextBgStyle.none,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => layer.fontStyle = fStyle),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2F2F2F),
                            ),
                          ),
                          child: Text(
                            fStyle.name.capitalizeFirst!,
                            style: textStyle.copyWith(
                              fontSize: 13,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else if (_activeTextToolbarTab == 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: allColors.map((c) {
                    final isSelected = layer.color == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => layer.color = c),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2F2F2F),
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: c == Colors.white
                                      ? Colors.black
                                      : Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else if (_activeTextToolbarTab == 2) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                        TextBgStyle.none,
                        TextBgStyle.rounded,
                        TextBgStyle.filled,
                        TextBgStyle.outline,
                      ].map((bg) {
                        final isSelected = layer.bgStyle == bg;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => layer.bgStyle = bg),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2F2F2F),
                                ),
                              ),
                              child: Text(
                                bg.name.capitalizeFirst!,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowObjectToolbar(MovableStoryLayer? layer) {
    if (layer == null) return false;
    // TEXT: No floating toolbar (handled via in-place / bottom text editor)
    if (layer.type == LayerType.text) return false;
    // STICKER & EMOJI: No floating toolbar
    if (layer.type == LayerType.sticker) return false;
    // IMAGE: No floating toolbar
    if (layer.type == LayerType.image) return false;
    return false;
  }

  Widget _buildObjectToolbar(MovableStoryLayer layer) {
    // Only render floating toolbar for STICKERS and IMAGES (never TEXT or EMOJIS)
    if (!_shouldShowObjectToolbar(layer)) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final currentPos = layer.getCanvasOffset(size);

    return Positioned(
      top: (currentPos.dy - 55).clamp(
        60.0,
        size.height - 220,
      ),
      left: (currentPos.dx - 10).clamp(
        16.0,
        size.width - 220,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xF21A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF262626), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (layer.type == LayerType.sticker) ...[
                TextButton.icon(
                  onPressed: () => _openEmojiPicker(layer),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    "Edit",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(height: 16, width: 1, color: Colors.white12),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  tooltip: "Duplicate",
                  onPressed: () {
                    final clone = layer.clone(
                      offset: Offset(
                        (layer.offset.dx + 0.04).clamp(0.0, 0.9),
                        (layer.offset.dy + 0.04).clamp(0.0, 0.9),
                      ),
                    );
                    setState(() {
                      _layers.add(clone);
                      _selectedLayer = clone;
                    });
                  },
                ),
                Container(height: 16, width: 1, color: Colors.white12),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    size: 16,
                  ),
                  tooltip: "Delete",
                  onPressed: () => _deleteLayerInstantly(layer),
                ),
              ] else if (layer.type == LayerType.image) ...[
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final picker = ImagePicker();
                      final XFile? media = await picker.pickMedia(
                        imageQuality: 95,
                      );
                      if (media != null && mounted) {
                        setState(() => layer.text = media.path);
                      }
                    } catch (_) {}
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    "Edit",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(height: 16, width: 1, color: Colors.white12),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  tooltip: "Duplicate",
                  onPressed: () {
                    final clone = layer.clone(
                      offset: Offset(
                        (layer.offset.dx + 0.04).clamp(0.0, 0.9),
                        (layer.offset.dy + 0.04).clamp(0.0, 0.9),
                      ),
                    );
                    setState(() {
                      _layers.add(clone);
                      _selectedLayer = clone;
                    });
                  },
                ),
                Container(height: 16, width: 1, color: Colors.white12),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    size: 16,
                  ),
                  tooltip: "Delete",
                  onPressed: () => _deleteLayerInstantly(layer),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  final Set<String> _deletingLayerIds = {};

  void _deleteLayerInstantly(MovableStoryLayer layer) {
    if (_deletingLayerIds.contains(layer.id)) return;

    setState(() {
      _deletingLayerIds.add(layer.id);
      if (_selectedLayer?.id == layer.id) {
        _selectedLayer = null;
      }
      _layers.removeWhere((l) => l.id == layer.id);
    });
  }

  Future<void> _showAddImagePicker() async {
    final currentImagesCount = _layers
        .where((l) => l.type == LayerType.image)
        .length;
    if (currentImagesCount >= 10) {
      AppNotificationBanner.showDanger(
        context: context,
        title: "Image Limit Reached",
        message: "You can add up to 10 image stickers per story.",
      );
      return;
    }

    try {
      final picker = ImagePicker();
      List<XFile> images = await picker.pickMultiImage(imageQuality: 95);

      if (images.isEmpty) {
        final XFile? singleMedia = await picker.pickMedia(imageQuality: 95);
        if (singleMedia != null) {
          images = [singleMedia];
        }
      }

      if (images.isNotEmpty && mounted) {
        final remainingSlots = 10 - currentImagesCount;
        final selectedImages = images.take(remainingSlots).toList();

        setState(() {
          for (int i = 0; i < selectedImages.length; i++) {
            final img = selectedImages[i];
            final layerIndex = currentImagesCount + i;
            final offset = _calculateInitialLayerOffset(
              layerIndex,
              currentImagesCount + selectedImages.length,
            );
            final newLayer = MovableStoryLayer(
              id: _generateUniqueLayerId('image'),
              type: LayerType.image,
              text: img.path,
              offset: offset,
              scale: 1.0,
              rotation: 0.0,
            );

            _layers.add(newLayer);
            _selectedLayer = newLayer;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showDanger(
          context: context,
          title: "Image Selection Error",
          message: "Could not add images: $e",
        );
      }
    }
  }

  Future<bool> _confirmDiscardDraft() async {
    final hasUnsavedChanges =
        _layers.isNotEmpty || _activeMediaPath != null || _gradientIdx != 0;
    if (!hasUnsavedChanges) {
      return true;
    }

    final bool? confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Discard Story",
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        final curve = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: Dialog(
              backgroundColor: const Color(0xFF141414),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF262626), width: 1.0),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (Left-aligned)
                      const Text(
                        "Discard Story?",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Description (Left-aligned)
                      const Text(
                        "You have unsaved changes. If you leave now, your story draft will be lost.",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Horizontal Equal-Width & Fixed Height Action Buttons (12px spacing)
                      Row(
                        children: [
                          // Safe Action: Keep Editing (Dark Surface + White Border)
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => Get.back(result: false),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFF242424),
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white24,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Keep Editing",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Destructive Action: Discard Draft (Filled Red Button)
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () => Get.back(result: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Discard Draft",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return confirmed ?? false;
  }

  void _showCustomizeTextSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Customize Story",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Background Gradients Row
              const Text(
                "Background Gradient",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_gradients.length, (idx) {
                    final isSel = idx == _gradientIdx;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _gradientIdx = idx);
                        setSheetState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: _gradients[idx]),
                          border: isSel
                              ? Border.all(color: Colors.white, width: 2.5)
                              : Border.all(color: Colors.white24),
                        ),
                        child: isSel
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // Font Style & Alignment Controls Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Font Style",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              if (_fontStyle == TextStyleType.bold) {
                                _fontStyle = TextStyleType.handwriting;
                              } else if (_fontStyle ==
                                  TextStyleType.handwriting) {
                                _fontStyle = TextStyleType.minimal;
                              } else {
                                _fontStyle = TextStyleType.bold;
                              }
                            });
                            setSheetState(() {});
                          },
                          icon: const Icon(
                            Icons.font_download_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _fontStyle.name.toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkSurfaceSecondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEmojiPicker([MovableStoryLayer? targetLayer]) {
    final searchController = TextEditingController();
    String query = '';
    String selectedCategory = 'Trending';

    final Map<String, List<String>> stickerCategories = {
      '🐱 Cute Cats': [
        'assets/stickers/cats/cat_waving.png',
        'assets/stickers/cats/cat_surprised.png',
        'assets/stickers/cats/cat_winking.png',
        'assets/stickers/cats/cat_begging.png',
        'assets/stickers/cats/cat_cool.png',
        'assets/stickers/cats/cat_crying.png',
      ],
      'Trending': [
        '🔥',
        '🚀',
        '💯',
        '✨',
        '⚡',
        '🎉',
        '🌟',
        '💪',
        '🏆',
        '👑',
        '🎯',
        '💥',
      ],
      'Emoji': [
        '😀',
        '😃',
        '😄',
        '😁',
        '😆',
        '😅',
        '😂',
        '🤣',
        '🥹',
        '😊',
        '😇',
        '🙂',
        '🙃',
        '😉',
        '😌',
        '😍',
        '🥰',
        '😘',
      ],
      'Student Life': [
        '📚',
        '💻',
        '☕',
        '📝',
        '🎓',
        '📖',
        '✍️',
        '🏫',
        '🎒',
        '🧠',
        '💡',
        '📊',
      ],
      'Celebration': [
        '🎉',
        '🥳',
        '🍾',
        '🎈',
        '🎊',
        '🎁',
        '🎂',
        '🥂',
        '🎇',
        '🎆',
        '✨',
        '🏆',
      ],
      'Funny': [
        '🤪',
        '😜',
        '👻',
        '🤡',
        '🤖',
        '👽',
        '💩',
        '🙈',
        '🙉',
        '🙊',
        '🐸',
        '🦄',
      ],
      'Love': [
        '❤️',
        '💖',
        '💗',
        '💓',
        '💞',
        '💕',
        '💘',
        '💌',
        '😍',
        '🥰',
        '🌹',
        '💐',
      ],
      'Campus': [
        '🎓',
        '🏛️',
        '🏫',
        '🤝',
        '📜',
        '📢',
        '💡',
        '🏆',
        '📖',
        '💻',
        '☕',
        '📝',
      ],
      'Khmer': [
        '🇰🇭',
        '🏛️',
        '🥭',
        '🌴',
        '🐘',
        '🌾',
        '🍜',
        '☕',
        '🥥',
        '🛵',
        '⛵',
        '🌅',
      ],
      'Custom': [
        '✨',
        '🌟',
        '🎨',
        '📸',
        '🎵',
        '🎬',
        '💎',
        '🌈',
        '🔥',
        '⚡',
        '🍀',
        '🌸',
      ],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (bCtx, setSheetState) {
          final mediaQuery = MediaQuery.of(bCtx);
          final maxHeight = mediaQuery.size.height * 0.75;

          List<String> displayStickers;
          if (query.trim().isNotEmpty) {
            displayStickers = stickerCategories.values
                .expand((element) => element)
                .where((stk) => stk.contains(query.trim()))
                .toSet()
                .toList();
          } else {
            displayStickers = stickerCategories[selectedCategory] ?? [];
          }

          return Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: Container(
              height: maxHeight,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Stickers & Emojis",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(bCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) => setSheetState(() => query = val),
                      decoration: InputDecoration(
                        hintText: "Search stickers & emojis...",
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white38,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: AppColors.darkSurfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 34,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: stickerCategories.keys.map((cat) {
                            final isSel =
                                selectedCategory == cat && query.isEmpty;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedCategory = cat;
                                    query = '';
                                    searchController.clear();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      color: isSel
                                          ? Colors.black
                                          : Colors.white70,
                                      fontSize: 12.5,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (query.isEmpty && _recentStickers.isNotEmpty) ...[
                      const Text(
                        "RECENTLY USED",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _recentStickers.length,
                          itemBuilder: (context, index) {
                            final stk = _recentStickers[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(bCtx);
                                if (targetLayer != null) {
                                  setState(() {
                                    targetLayer.text = stk;
                                    _selectedLayer = targetLayer;
                                  });
                                } else {
                                  _addStickerToCanvas(stk);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: stk.startsWith('assets/')
                                    ? Image.asset(
                                        stk,
                                        width: 34,
                                        height: 34,
                                        fit: BoxFit.contain,
                                      )
                                    : Text(
                                        stk,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Text(
                      query.isNotEmpty
                          ? "SEARCH RESULTS (${displayStickers.length})"
                          : selectedCategory.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: displayStickers.isEmpty
                          ? const Center(
                              child: Text(
                                "No stickers found",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.0,
                                  ),
                              itemCount: displayStickers.length,
                              itemBuilder: (context, index) {
                                final sticker = displayStickers[index];
                                final isAsset = sticker.startsWith('assets/');
                                return GestureDetector(
                                  onTap: () {
                                    if (!_recentStickers.contains(sticker)) {
                                      setState(
                                        () =>
                                            _recentStickers.insert(0, sticker),
                                      );
                                    }
                                    Navigator.pop(bCtx);
                                    if (targetLayer != null) {
                                      setState(() {
                                        targetLayer.text = sticker;
                                        _selectedLayer = targetLayer;
                                      });
                                    } else {
                                      _addStickerToCanvas(sticker);
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.all(isAsset ? 8 : 0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.07,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: isAsset
                                        ? Image.asset(
                                            sticker,
                                            fit: BoxFit.contain,
                                          )
                                        : Text(
                                            sticker,
                                            style: const TextStyle(
                                              fontSize: 32,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _addStickerToCanvas(String stickerText) {
    final newLayer = MovableStoryLayer(
      id: _generateUniqueLayerId('sticker'),
      type: LayerType.sticker,
      text: stickerText,
      offset: const Offset(0.5, 0.5),
      scale: 1.5,
    );
    setState(() {
      _layers.add(newLayer);
      _selectedLayer = newLayer;
    });
  }

  void _closeFullScreenTextEditor({bool save = true}) {
    _fullScreenTextFocusNode.unfocus();

    if (save) {
      final text = _fullScreenTextController.text.trim();
      if (text.isNotEmpty) {
        setState(() {
          if (_editingTextLayer != null) {
            // ONLY update text content and styles — PRESERVE existing offset, scale, rotation
            _editingTextLayer!.text = text;
            _editingTextLayer!.color = _activeTextColor;
            _editingTextLayer!.bgColor = _activeTextBgColor;
            _editingTextLayer!.fontStyle = _activeFontStyle;
            _editingTextLayer!.bgStyle = _activeTextBgStyle;
            _editingTextLayer!.effect = _activeTextEffect;
            _editingTextLayer!.alignment = _activeTextAlign;
            _editingTextLayer!.fontSize = _activeFontSize;
            _selectedLayer = _editingTextLayer;
          } else {
            final newLayer = MovableStoryLayer(
              id: _generateUniqueLayerId('text'),
              type: LayerType.text,
              text: text,
              color: _activeTextColor,
              bgColor: _activeTextBgColor,
              fontStyle: _activeFontStyle,
              bgStyle: _activeTextBgStyle,
              effect: _activeTextEffect,
              alignment: _activeTextAlign,
              fontSize: _activeFontSize,
              offset: const Offset(0.5, 0.5),
              scale: _activeTextScale,
            );
            _layers.add(newLayer);
            _selectedLayer = newLayer;
          }
        });
      }
    }

    setState(() {
      _isFullScreenTextEditing = false;
      _editingTextLayer = null;
      _activeContextTool = ActiveContextTool.none;
    });
  }

  Widget _buildFullScreenTextEditorOverlay() {
    if (!_isFullScreenTextEditing) return const SizedBox.shrink();

    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    final topPadding = mq.padding.top;
    final bottomPadding = mq.padding.bottom;
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;

    // Live text style
    final baseTextStyle = _getLayerTextStyle(
      _activeFontStyle,
      _activeTextColor,
      _activeTextBgStyle,
      effect: _activeTextEffect,
    ).copyWith(fontSize: _activeFontSize);

    Color? boxColor;
    BoxBorder? boxBorder;
    List<BoxShadow>? boxShadow;

    if (_activeTextBgStyle == TextBgStyle.filled) {
      boxColor = _activeTextBgColor ?? Colors.white;
      boxShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (_activeTextBgStyle == TextBgStyle.rounded) {
      boxColor = (_activeTextBgColor ?? Colors.black).withValues(alpha: 0.65);
      boxShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (_activeTextBgStyle == TextBgStyle.outline) {
      boxColor = Colors.transparent;
      boxBorder = Border.all(
        color: _activeTextBgColor ?? _activeTextColor,
        width: 2.0,
      );
    }

    final liveTextColor =
        (_activeTextBgStyle == TextBgStyle.filled &&
            _activeTextBgColor == null &&
            _activeTextColor == Colors.white)
        ? Colors.black
        : _activeTextColor;

    final cursorColor = liveTextColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    final isTextStory = widget.type == StoryType.text;
    final isEditingExistingImageText =
        _editingTextLayer != null && !isTextStory;

    final textInputField = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: screenWidth * 0.85 * 0.92),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: _activeTextBgStyle != TextBgStyle.none
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(14),
          border: boxBorder,
          boxShadow: boxShadow,
        ),
        child: IntrinsicWidth(
          child: TextField(
            controller: _fullScreenTextController,
            focusNode: _fullScreenTextFocusNode,
            autofocus: true,
            maxLines: null,
            maxLength: 300,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textAlign: _activeTextAlign,
            textCapitalization: TextCapitalization.sentences,
            style: baseTextStyle.copyWith(color: liveTextColor),
            cursorColor: cursorColor,
            cursorWidth: 2.5,
            cursorRadius: const Radius.circular(2),
            decoration: const InputDecoration(
              hintText: 'Start typing...',
              hintStyle: TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.w400,
                fontSize: 26,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
        ),
      ),
    );

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _isFullScreenTextEditing ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // ── Column layout: top bar → canvas input → contextual bar → bottom controls ──
              SafeArea(
                top: true,
                bottom: false,
                child: Column(
                  children: [
                    // ── TOP BAR (Clean Responsive Header) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // LEFT: Close / Back Button
                          Tooltip(
                            message: 'Close',
                            child: GestureDetector(
                              onTap: () =>
                                  _closeFullScreenTextEditor(save: true),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // RIGHT: [ @ ] [ Emoji ] [ Audio ] [ Done ]
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. @ Mention Button
                              Tooltip(
                                message: 'Mention',
                                child: GestureDetector(
                                  onTap: _showMentionSheet,
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.alternate_email_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 2. Emoji / Sticker Button
                              Tooltip(
                                message: 'Stickers',
                                child: GestureDetector(
                                  onTap: _openEmojiPicker,
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.sentiment_satisfied_alt_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 3. Audio / Music Button
                              Tooltip(
                                message: 'Music',
                                child: GestureDetector(
                                  onTap: _showMusicSheet,
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.graphic_eq_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // 4. Done Button
                              Tooltip(
                                message: 'Done',
                                child: GestureDetector(
                                  onTap: () =>
                                      _closeFullScreenTextEditor(save: true),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Done',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ── CANVAS AREA (Natural Text Editing) ──
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Tapping empty area closes secondary panel if open, otherwise closes editor
                          if (_activeContextTool != ActiveContextTool.none) {
                            setState(
                              () => _activeContextTool = ActiveContextTool.none,
                            );
                          } else {
                            _closeFullScreenTextEditor(save: true);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: isEditingExistingImageText
                            ? const SizedBox.expand()
                            : Center(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.08,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: screenWidth * 0.85 * 0.92,
                                    ),
                                    child: textInputField,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // ── CONTEXTUAL SECONDARY CONTROL BAR (Shown ONLY when an option is selected) ──
                    if (_activeContextTool != ActiveContextTool.none)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildContextualControlBar(),
                      ),

                    // ── PRIMARY TOOLBAR CAPSULE (Compact, simplified icons) ──
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: keyboardHeight > 0
                            ? (keyboardHeight + 8)
                            : (bottomPadding > 0 ? bottomPadding + 8 : 20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xF2161618),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 1. Color / Background Control
                              _buildPrimaryEditorToolBtn(
                                active:
                                    _activeContextTool == ActiveContextTool.color,
                                tooltip: 'Color',
                                child: ShaderMask(
                                  shaderCallback: (bounds) => const SweepGradient(
                                    colors: [
                                      Colors.red,
                                      Colors.orange,
                                      Colors.yellow,
                                      Colors.green,
                                      Colors.blue,
                                      Colors.purple,
                                      Colors.red,
                                    ],
                                  ).createShader(bounds),
                                  child: const Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                onTap: () => setState(() {
                                  _activeContextTool =
                                      _activeContextTool ==
                                          ActiveContextTool.color
                                      ? ActiveContextTool.none
                                      : ActiveContextTool.color;
                                }),
                              ),

                              // 2. Alignment Toggle (☰)
                              _buildPrimaryEditorToolBtn(
                                active: false,
                                tooltip: 'Alignment',
                                child: Icon(
                                  _activeTextAlign == TextAlign.center
                                      ? Icons.format_align_center_rounded
                                      : _activeTextAlign == TextAlign.left
                                      ? Icons.format_align_left_rounded
                                      : Icons.format_align_right_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                onTap: () => setState(() {
                                  if (_activeTextAlign == TextAlign.center) {
                                    _activeTextAlign = TextAlign.left;
                                  } else if (_activeTextAlign ==
                                      TextAlign.left) {
                                    _activeTextAlign = TextAlign.right;
                                  } else {
                                    _activeTextAlign = TextAlign.center;
                                  }
                                  if (_editingTextLayer != null) {
                                    _editingTextLayer!.alignment =
                                        _activeTextAlign;
                                  }
                                }),
                              ),

                              // 3. Font Family (Aa)
                              _buildPrimaryEditorToolBtn(
                                active:
                                    _activeContextTool == ActiveContextTool.font,
                                tooltip: 'Font',
                                child: const Text(
                                  'Aa',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () => setState(() {
                                  _activeContextTool =
                                      _activeContextTool ==
                                          ActiveContextTool.font
                                      ? ActiveContextTool.none
                                      : ActiveContextTool.font;
                                }),
                              ),

                              // 4. Text Effects (✨)
                              _buildPrimaryEditorToolBtn(
                                active:
                                    _activeContextTool ==
                                    ActiveContextTool.effect,
                                tooltip: 'Effects',
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                onTap: () => setState(() {
                                  _activeContextTool =
                                      _activeContextTool ==
                                          ActiveContextTool.effect
                                      ? ActiveContextTool.none
                                      : ActiveContextTool.effect;
                                }),
                              ),

                              // 5. Dedicated Canvas Background Control (if in Text story mode)
                              if (widget.type == StoryType.text)
                                _buildPrimaryEditorToolBtn(
                                  active:
                                      _activeContextTool ==
                                      ActiveContextTool.background,
                                  tooltip: 'Change background',
                                  child: _buildCurrentBgIndicatorWidget(),
                                  onTap: () => setState(() {
                                    _activeContextTool =
                                        _activeContextTool ==
                                            ActiveContextTool.background
                                        ? ActiveContextTool.none
                                        : ActiveContextTool.background;
                                  }),
                                ),

                              // 6. Text Box Background style toggle [Aa]
                              _buildPrimaryEditorToolBtn(
                                active: _activeTextBgStyle != TextBgStyle.none,
                                tooltip: 'Text Background',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _activeTextBgStyle != TextBgStyle.none
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white70,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    'A',
                                    style: TextStyle(
                                      color:
                                          _activeTextBgStyle != TextBgStyle.none
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () => setState(() {
                                  if (_activeTextBgStyle == TextBgStyle.none) {
                                    _activeTextBgStyle = TextBgStyle.rounded;
                                  } else if (_activeTextBgStyle ==
                                      TextBgStyle.rounded) {
                                    _activeTextBgStyle = TextBgStyle.filled;
                                  } else if (_activeTextBgStyle ==
                                      TextBgStyle.filled) {
                                    _activeTextBgStyle = TextBgStyle.outline;
                                  } else {
                                    _activeTextBgStyle = TextBgStyle.none;
                                  }
                                  if (_editingTextLayer != null) {
                                    _editingTextLayer!.bgStyle =
                                        _activeTextBgStyle;
                                  }
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── IN-PLACE TEXT EDITING (For existing text layers on image stories) ──
              if (isEditingExistingImageText)
                Positioned(
                  left: _editingTextLayer!
                      .getCanvasOffset(Size(screenWidth, screenHeight))
                      .dx,
                  top: _editingTextLayer!
                      .getCanvasOffset(Size(screenWidth, screenHeight))
                      .dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Transform.scale(
                      scale: _editingTextLayer!.scale,
                      child: Transform.rotate(
                        angle: _editingTextLayer!.rotation,
                        child: textInputField,
                      ),
                    ),
                  ),
                ),

              // ── LEFT SIDE: Vertical Font Size Slider ──
              Positioned(
                left: 0,
                top: topPadding + 60,
                height: (screenHeight -
                        (topPadding + 60) -
                        (keyboardHeight > 0
                            ? keyboardHeight + 80
                            : (bottomPadding > 0 ? bottomPadding + 90 : 100)))
                    .clamp(60.0, 320.0),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 18,
                        ),
                        trackHeight: 3,
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white30,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white24,
                      ),
                      child: Slider(
                        value: _activeFontSize.clamp(14.0, 72.0),
                        min: 14,
                        max: 72,
                        onChanged: (v) => setState(() {
                          _activeFontSize = v;
                          if (_editingTextLayer != null) {
                            _editingTextLayer!.fontSize = v;
                          }
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextualControlBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xF2161618),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title + Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _activeContextTool == ActiveContextTool.color
                    ? "Choose Color"
                    : _activeContextTool == ActiveContextTool.font
                    ? "Font Family"
                    : _activeContextTool == ActiveContextTool.effect
                    ? "Text Effects"
                    : "Background",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _activeContextTool = ActiveContextTool.none),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Contextual Body
          if (_activeContextTool == ActiveContextTool.color)
            _buildContextualColorPicker()
          else if (_activeContextTool == ActiveContextTool.font)
            _buildContextualFontPicker()
          else if (_activeContextTool == ActiveContextTool.effect)
            _buildContextualEffectsPicker()
          else if (_activeContextTool == ActiveContextTool.background)
            _buildContextualBackgroundSelector(),
        ],
      ),
    );
  }

  Widget _buildContextualColorPicker() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _curatedColors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _curatedColors[i];
          final isSel = _activeTextColor == c;
          final lum = c.computeLuminance();
          final checkColor = lum > 0.5 ? Colors.black : Colors.white;

          return GestureDetector(
            onTap: () => setState(() {
              _activeTextColor = c;
              if (_editingTextLayer != null) _editingTextLayer!.color = c;
              if (_selectedLayer != null &&
                  _selectedLayer!.type == LayerType.text) {
                _selectedLayer!.color = c;
              }
            }),
            child: AnimatedScale(
              scale: isSel ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel
                        ? (lum > 0.5 ? Colors.black : Colors.white)
                        : Colors.white.withValues(alpha: 0.25),
                    width: isSel ? 2.5 : 1.0,
                  ),
                ),
                child: isSel
                    ? Icon(Icons.check_rounded, size: 16, color: checkColor)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContextualFontPicker() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _fontPresets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (fStyle, label) = _fontPresets[i];
          final isSel = _activeFontStyle == fStyle;
          final previewStyle = _getLayerTextStyle(
            fStyle,
            isSel ? Colors.black : Colors.white,
            TextBgStyle.none,
            effect: TextEffectType.none,
          );

          return GestureDetector(
            onTap: () => setState(() {
              _activeFontStyle = fStyle;
              if (_editingTextLayer != null) {
                _editingTextLayer!.fontStyle = fStyle;
              }
              if (_selectedLayer != null &&
                  _selectedLayer!.type == LayerType.text) {
                _selectedLayer!.fontStyle = fStyle;
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSel
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSel
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: previewStyle.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSel ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContextualEffectsPicker() {
    final effectPresets = [
      (TextEffectType.none, 'None', 'Flat & Clean'),
      (TextEffectType.shadow, 'Shadow', 'Soft Shadow'),
      (TextEffectType.outline, 'Outline', 'Crisp Stroke'),
      (TextEffectType.glow, 'Glow', 'Vibrant Neon'),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: effectPresets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (eff, name, subtitle) = effectPresets[i];
          final isSel = _activeTextEffect == eff;
          final sampleStyle = _getLayerTextStyle(
            _activeFontStyle,
            isSel ? Colors.black : Colors.white,
            TextBgStyle.none,
            effect: eff,
          );

          return GestureDetector(
            onTap: () => setState(() {
              _activeTextEffect = eff;
              if (_editingTextLayer != null) _editingTextLayer!.effect = eff;
              if (_selectedLayer != null &&
                  _selectedLayer!.type == LayerType.text) {
                _selectedLayer!.effect = eff;
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 96,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isSel
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSel
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  width: isSel ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Aa',
                    style: sampleStyle.copyWith(
                      fontSize: 18,
                      color: isSel ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      if (isSel) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Colors.black,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentBgIndicatorWidget() {
    if (_storyBgMode == StoryBgMode.solid && _selectedSolidBgColor != null) {
      final lum = _selectedSolidBgColor!.computeLuminance();
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _selectedSolidBgColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: lum > 0.5 ? Colors.black54 : Colors.white,
            width: 1.5,
          ),
        ),
      );
    }

    final preset = _bgPresets[_gradientIdx.clamp(0, _bgPresets.length - 1)];
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: preset.colors,
          begin: preset.begin,
          end: preset.end,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }

  Widget _buildContextualBackgroundSelector() {
    final categories = [
      'Gradients',
      'Solid',
      'Pastel',
      'Trending',
      'Fairy',
      'Aesthetic',
      'Minimal',
    ];
    final categoryLabels = {
      'Gradients': '🌈 Gradients',
      'Solid': '🎨 Solid',
      'Pastel': '💖 Pastel',
      'Trending': '🔥 Trending',
      'Fairy': '✨ Fairy',
      'Aesthetic': '☕ Aesthetic',
      'Minimal': '🖤 Minimal',
    };

    Widget contentWidget;

    if (_selectedBgCategory == 'Solid') {
      contentWidget = SizedBox(
        height: 42,
        child: ListView.separated(
          key: const ValueKey('solid_bg_list'),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          itemCount: _solidBgColors.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final color = _solidBgColors[i];
            final isSel =
                _storyBgMode == StoryBgMode.solid &&
                _selectedSolidBgColor == color;
            final lum = color.computeLuminance();
            final checkColor = lum > 0.5 ? Colors.black : Colors.white;

            return GestureDetector(
              key: ValueKey('solid_item_${color.toARGB32()}'),
              onTap: () => setState(() {
                _storyBgMode = StoryBgMode.solid;
                _selectedSolidBgColor = color;
              }),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel
                        ? (lum > 0.5 ? Colors.black : Colors.white)
                        : Colors.white.withValues(alpha: 0.22),
                    width: isSel ? 2.2 : 1.0,
                  ),
                ),
                child: isSel
                    ? Icon(Icons.check_rounded, size: 16, color: checkColor)
                    : null,
              ),
            );
          },
        ),
      );
    } else {
      final filteredPresets =
          (_selectedBgCategory == 'Gradients' || _selectedBgCategory == 'All')
          ? _bgPresets
          : _bgPresets.where((p) => p.category == _selectedBgCategory).toList();

      contentWidget = SizedBox(
        height: 52,
        child: ListView.separated(
          key: ValueKey('gradient_bg_list_$_selectedBgCategory'),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          itemCount: filteredPresets.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final preset = filteredPresets[i];
            final actualIndex = _bgPresets.indexOf(preset);
            final isSel =
                _storyBgMode == StoryBgMode.gradient &&
                _gradientIdx == actualIndex;
            final isDark = preset.colors.first.computeLuminance() < 0.45;

            return GestureDetector(
              key: ValueKey('gradient_item_${preset.name}'),
              onTap: () => setState(() {
                _storyBgMode = StoryBgMode.gradient;
                _gradientIdx = actualIndex;
              }),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 66,
                height: 50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: preset.colors,
                    begin: preset.begin,
                    end: preset.end,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.18),
                    width: isSel ? 2.0 : 1.0,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              preset.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              preset.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 9.5,
                                shadows: isDark
                                    ? const [
                                        Shadow(
                                          blurRadius: 4,
                                          color: Colors.black54,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isSel)
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 10,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Filter Tabs
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final cat = categories[i];
              final isCatSel = _selectedBgCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedBgCategory = cat),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCatSel
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCatSel
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      categoryLabels[cat] ?? cat,
                      style: TextStyle(
                        color: isCatSel ? Colors.black : Colors.white70,
                        fontWeight: isCatSel
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Content Swatches (Solid / Gradients)
        contentWidget,
      ],
    );
  }

  Widget _buildStoryPrivacyBar() {
    IconData icon;
    String title;
    String subtitle;
    Color iconColor;

    if (_selectedVisibility == 'Public') {
      icon = Icons.public_rounded;
      title = 'Public';
      subtitle = 'Anyone in GenLink';
      iconColor = const Color(0xFF38BDF8);
    } else if (_selectedVisibility == 'Only Me') {
      icon = Icons.lock_rounded;
      title = 'Only Me';
      subtitle = 'Only you can see this story';
      iconColor = const Color(0xFFF43F5E);
    } else if (_selectedVisibility == 'Custom') {
      icon = Icons.settings_suggest_rounded;
      title = 'Custom';
      subtitle = 'Choose who can see your story';
      iconColor = const Color(0xFFA855F7);
    } else {
      icon = Icons.people_alt_rounded;
      title = 'Friends';
      subtitle = 'Only your friends';
      iconColor = const Color(0xFF34D399);
    }

    return GestureDetector(
      onTap: _openStoryPrivacySettings,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_right_rounded,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStoryPrivacySettings() {
    StoryPrivacy tempVisibility = _storySettings.visibility;
    StoryReplyPermission tempReplyPrivacy = _storySettings.replyPermission;
    bool tempAllowReactions = _storySettings.allowReactions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final mq = MediaQuery.of(ctx);
          final maxHeight = mq.size.height * 0.85;

          return Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF161618),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Colors.white12, width: 1.0),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 2. Header: [ ← ]  Story Settings  [ Done ]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back / Close Icon Button (Discards uncommitted changes)
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),

                      // Centered Title
                      const Text(
                        "Story Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),

                      // Done Button (Confirm & Save Settings)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _storySettings = StorySettings(
                              visibility: tempVisibility,
                              replyPermission: tempReplyPrivacy,
                              allowReactions: tempAllowReactions,
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            "Done",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Privacy Section ──
                          const Text(
                            "Who can see your story?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            "Your story will be visible for 24 hours.",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Option 1: Public
                          _buildPrivacyOptionTile(
                            icon: Icons.public_rounded,
                            iconColor: const Color(0xFF38BDF8),
                            title: "Public",
                            subtitle: "Anyone in GenLink",
                            isSelected: tempVisibility == StoryPrivacy.public,
                            onTap: () => setSheetState(
                              () => tempVisibility = StoryPrivacy.public,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Option 2: Friends
                          _buildPrivacyOptionTile(
                            icon: Icons.people_alt_rounded,
                            iconColor: const Color(0xFF34D399),
                            title: "Friends",
                            subtitle: "Only your friends",
                            isSelected: tempVisibility == StoryPrivacy.friends,
                            onTap: () => setSheetState(
                              () => tempVisibility = StoryPrivacy.friends,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Option 3: Only Me
                          _buildPrivacyOptionTile(
                            icon: Icons.lock_rounded,
                            iconColor: const Color(0xFFF43F5E),
                            title: "Only Me",
                            subtitle: "Only you can see your story",
                            isSelected: tempVisibility == StoryPrivacy.onlyMe,
                            onTap: () => setSheetState(
                              () => tempVisibility = StoryPrivacy.onlyMe,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Option 4: Custom (Coming Soon)
                          _buildPrivacyOptionTile(
                            icon: Icons.settings_suggest_rounded,
                            iconColor: const Color(0xFFA855F7),
                            title: "Custom",
                            subtitle: "Choose who can see your story",
                            badge: "Coming Soon",
                            isSelected: tempVisibility == StoryPrivacy.custom,
                            onTap: () {
                              AppNotificationBanner.showInfo(
                                context: context,
                                title: "Custom Audience",
                                message:
                                    "Custom friend list filtering is currently in development.",
                              );
                            },
                          ),

                          const SizedBox(height: 18),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 16),

                          // ── Story Interactions Section ──
                          const Text(
                            "Story Interactions",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Who can reply to your story?",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Segmented Control: [ Everyone ] [ Friends ] [ Off ]
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white10,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children:
                                  [
                                    StoryReplyPermission.everyone,
                                    StoryReplyPermission.friends,
                                    StoryReplyPermission.off,
                                  ].map((opt) {
                                    final isSel = tempReplyPrivacy == opt;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => setSheetState(
                                          () => tempReplyPrivacy = opt,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? Colors.white
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: isSel
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                      blurRadius: 6,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              opt.label,
                                              style: TextStyle(
                                                color: isSel
                                                    ? Colors.black
                                                    : Colors.white70,
                                                fontWeight: isSel
                                                    ? FontWeight.w800
                                                    : FontWeight.w500,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Allow Reactions Toggle Row ──
                          InkWell(
                            onTap: () => setSheetState(
                              () => tempAllowReactions = !tempAllowReactions,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Allow Reactions",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          "Let viewers like and react to this story",
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: tempAllowReactions,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: AppColors.communityAccent,
                                    onChanged: (val) => setSheetState(
                                      () => tempAllowReactions = val,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivacyOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white10,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white38,
                  width: 2.0,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Colors.black),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryEditorToolBtn({
    required Widget child,
    required VoidCallback onTap,
    required String tooltip,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  /// Small circular icon button for the editor tool row
  Widget _buildToolIcon({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  /// Circular icon button used in the text editor top bar.
  Widget _buildEditorIconBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.22),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  void _openLocationPicker() {
    _showLocationSheet();
  }

  void _showPlaceholderInfo(String title, String message) {
    AppNotificationBanner.showInfo(
      context: context,
      title: title,
      message: message,
    );
  }

  Widget _buildHorizontalToolItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? tooltip,
    Widget? customIconWidget,
    bool isPlaceholder = false,
  }) {
    return Tooltip(
      message: tooltip ?? label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPlaceholder
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.darkSurfaceSecondary.withValues(alpha: 0.90),
                  shape: BoxShape.circle,
                  border: isPlaceholder
                      ? Border.all(color: Colors.white12, width: 1.0)
                      : null,
                ),
                child: Center(
                  child:
                      customIconWidget ??
                      Icon(
                        icon,
                        color: isPlaceholder ? Colors.white38 : Colors.white,
                        size: 20,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "More Options",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 1. Rotate Image
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rotate_right_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                "Rotate Image",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                "Rotate image by 90 degrees",
                style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(bCtx);
                _rotateImage();
              },
            ),

            // 2. Remove Photo
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              title: const Text(
                "Remove Photo",
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                "Discard draft and return to home",
                style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(bCtx);
                final shouldPop = await _confirmDiscardDraft();
                if (shouldPop) {
                  Get.back();
                }
              },
            ),

            const SizedBox(height: 8),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(bCtx),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStyleAndColorCard() {
    const textColors = [
      Colors.white,
      Colors.black,
      Color(0xFFFACC15), // Amber
      Color(0xFFF43F5E), // Rose
      Color(0xFF38BDF8), // Sky
      Color(0xFFA855F7), // Violet
      Color(0xFF34D399), // Emerald
      Color(0xFFFB923C), // Orange
      Color(0xFFE879F9), // Fuchsia
      Color(0xFF4ADE80), // Green
    ];

    const fontPresets = [
      (TextStyleType.classic, 'Classic', FontWeight.w600, FontStyle.normal),
      (TextStyleType.elegant, 'Deco', FontWeight.w600, FontStyle.italic),
      (TextStyleType.bold, 'Bubble', FontWeight.w900, FontStyle.normal),
      (TextStyleType.modern, 'Outline', FontWeight.w800, FontStyle.normal),
      (TextStyleType.minimal, 'Neon', FontWeight.w700, FontStyle.normal),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xF2111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Font Presets Row ──
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: fontPresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (fStyle, label, fw, fi) = fontPresets[i];
                final isSel = _activeFontStyle == fStyle;
                return GestureDetector(
                  onTap: () => setState(() {
                    _activeFontStyle = fStyle;
                    if (_selectedLayer != null &&
                        _selectedLayer!.type == LayerType.text) {
                      _selectedLayer!.fontStyle = fStyle;
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSel
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: isSel
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSel
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.70),
                        fontSize: 12,
                        fontWeight: isSel ? fw : FontWeight.w400,
                        fontStyle: isSel ? fi : FontStyle.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ── Color Swatches Row ──
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: textColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final col = textColors[i];
                final isSel = _activeTextColor == col;
                final lum = col.computeLuminance();
                final checkColor = lum > 0.5 ? Colors.black : Colors.white;

                return GestureDetector(
                  onTap: () => setState(() {
                    _activeTextColor = col;
                    if (_selectedLayer != null &&
                        _selectedLayer!.type == LayerType.text) {
                      _selectedLayer!.color = col;
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: isSel ? 32 : 28,
                    height: isSel ? 32 : 28,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.25),
                        width: isSel ? 2.2 : 1.0,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: col.withValues(alpha: 0.55),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSel
                        ? Icon(Icons.check_rounded, size: 14, color: checkColor)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _confirmDiscardDraft();
          if (shouldPop) {
            Get.back();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. Primary Full-Screen Immersive Canvas (Media / Text)
            Positioned.fill(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (!_isInteractingLayer) {
                          setState(() {
                            _selectedLayer = null;
                            _activeContextTool = ActiveContextTool.none;
                          });
                        }
                      },
                      onDoubleTap: () {
                        if (widget.type == StoryType.text) {
                          _cycleGradient();
                        }
                      },
                      child: _buildMediaCanvas(),
                    ),
                  ),

                  // Movable Overlays (Text / Stickers)
                  ..._layers.map((layer) => _buildLayerWidget(layer)),

                  // Object action toolbar (Edit / Duplicate / Delete) — shows ONLY for STICKERS and IMAGES (never TEXT or EMOJI)
                  if (_selectedLayer != null &&
                      !_isFullScreenTextEditing &&
                      _shouldShowObjectToolbar(_selectedLayer))
                    _buildObjectToolbar(_selectedLayer!),

                  // Full-Screen Immersive Text Editor Overlay
                  _buildFullScreenTextEditorOverlay(),
                ],
              ),
            ),

            // 2. Top Header Overlay Bar (Floating gradient header)
            if (!_isFullScreenTextEditing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black87,
                        Colors.black45,
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Row 1: Header (Close X button)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () async {
                                  final shouldPop =
                                      await _confirmDiscardDraft();
                                  if (shouldPop) {
                                    Get.back();
                                  }
                                },
                              ),
                              if (widget.type == StoryType.template || _isTemplateApplied) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _openTemplatePickerSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _selectedTemplate.icon,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _selectedTemplate.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),

                              // RIGHT ACTION BUTTONS: [ @ ] [ Emoji ] [ Audio ] [ Done ]
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. @ Mention Button
                                  Tooltip(
                                    message: 'Mention',
                                    child: GestureDetector(
                                      onTap: _showMentionSheet,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.alternate_email_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 2. Emoji / Sticker Button
                                  Tooltip(
                                    message: 'Stickers',
                                    child: GestureDetector(
                                      onTap: _openEmojiPicker,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.sentiment_satisfied_alt_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 3. Audio / Music Button
                                  Tooltip(
                                    message: 'Music',
                                    child: GestureDetector(
                                      onTap: _showMusicSheet,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.graphic_eq_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 4. Done Button (Posts story directly from canvas)
                                  Tooltip(
                                    message: 'Done',
                                    child: GestureDetector(
                                      onTap: _isPublishing ? null : _publishStory,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: _isPublishing
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Colors.black,
                                                  ),
                                                ),
                                              )
                                            : const Text(
                                                'Done',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13.5,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Text editing controls removed from header; they are now exclusively in the bottom contextual toolbar.
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 2.5 Animated Floating Trash Delete Target (Active ONLY while dragging elements)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              bottom: _isInteractingLayer ? 125 : -80,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isInteractingLayer ? 1.0 : 0.0,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _isHoveringDeleteZone
                          ? AppColors.danger.withValues(alpha: 0.95)
                          : Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isHoveringDeleteZone
                            ? Colors.white
                            : Colors.white24,
                        width: _isHoveringDeleteZone ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isHoveringDeleteZone
                              ? AppColors.danger.withValues(alpha: 0.6)
                              : Colors.black45,
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: _isHoveringDeleteZone ? 22 : 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isHoveringDeleteZone
                              ? "Release to Delete"
                              : "Drag here to delete",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: _isHoveringDeleteZone ? 13.5 : 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Bottom Control Deck Overlay (Floating over canvas bottom)
            if (!_isFullScreenTextEditing)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                          Colors.black87,
                          Colors.black,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Contextual Control Panel (if active)
                            if (_activeContextTool !=
                                ActiveContextTool.none) ...[
                              _buildContextualControlBar(),
                              const SizedBox(height: 6),
                            ],

                            // Unified Glassmorphic Toolbar Capsule (Icon Buttons with 44px Touch Targets)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xF2161618),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    // 1. Template Layout Switcher
                                    _buildHorizontalToolItem(
                                      icon: Icons.dashboard_customize_outlined,
                                      label: "Template",
                                      tooltip: "Template",
                                      onTap: _openTemplatePickerSheet,
                                    ),

                                    // 2. Add Text Overlay
                                    _buildHorizontalToolItem(
                                      icon: Icons.title_rounded,
                                      label: "Text",
                                      tooltip: "Text",
                                      onTap: () => _openFloatingTextEditor(),
                                    ),

                                    // 3. Stickers & Emojis (Unified single action)
                                    _buildHorizontalToolItem(
                                      icon: Icons.sentiment_satisfied_alt_outlined,
                                      label: "Stickers",
                                      tooltip: "Stickers",
                                      onTap: _openEmojiPicker,
                                    ),

                                    // 4. Location Tag
                                    _buildHorizontalToolItem(
                                      icon: Icons.location_on_outlined,
                                      label: "Location",
                                      tooltip: "Location",
                                      onTap: _openLocationPicker,
                                    ),

                                    // 5. Mention Tag (@)
                                    _buildHorizontalToolItem(
                                      icon: Icons.alternate_email_rounded,
                                      label: "Mention",
                                      tooltip: "Mention",
                                      onTap: _showMentionSheet,
                                    ),

                                    // 6. Add Photo / Gallery (For Image / Video / Template Stories)
                                    if (widget.type != StoryType.text)
                                      _buildHorizontalToolItem(
                                        icon: Icons.photo_library_outlined,
                                        label: "Photo",
                                        tooltip: "Photo",
                                        onTap: (widget.type == StoryType.template || _isTemplateApplied)
                                            ? () {
                                                final firstEmptyIdx = _templateSlots.indexWhere((s) => s.mediaPath == null || s.mediaPath!.isEmpty);
                                                _onTapTemplateSlot(firstEmptyIdx != -1 ? firstEmptyIdx : 0);
                                              }
                                            : _showAddImagePicker,
                                      ),

                                    // 7. Music
                                    _buildHorizontalToolItem(
                                      icon: Icons.music_note_rounded,
                                      label: "Music",
                                      tooltip: "Music",
                                      onTap: _showMusicSheet,
                                    ),

                                    // 8. Dedicated Canvas Background Control (Text & Template Story Modes)
                                    if (widget.type == StoryType.text || widget.type == StoryType.template || _isTemplateApplied)
                                      _buildHorizontalToolItem(
                                        icon: Icons.palette_outlined,
                                        label: "Background",
                                        tooltip: "Background",
                                        customIconWidget:
                                            _buildCurrentBgIndicatorWidget(),
                                        onTap: () => setState(() {
                                          _activeContextTool =
                                              _activeContextTool ==
                                                  ActiveContextTool.background
                                              ? ActiveContextTool.none
                                              : ActiveContextTool.background;
                                        }),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 2. Story Privacy Indicator & Settings Entry Bar
                            _buildStoryPrivacyBar(),

                            // 3. Interactive Apple-Grade "Post Story" Call-To-Action Pill Button
                            _AnimatedPostStoryButton(
                              isPublishing: _isPublishing,
                              onPost: _publishStory,
                            ),
                          ],
                        ),
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
}

class _AnimatedPostStoryButton extends StatefulWidget {
  final bool isPublishing;
  final VoidCallback onPost;

  const _AnimatedPostStoryButton({
    required this.isPublishing,
    required this.onPost,
  });

  @override
  State<_AnimatedPostStoryButton> createState() =>
      _AnimatedPostStoryButtonState();
}

class _AnimatedPostStoryButtonState extends State<_AnimatedPostStoryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isPublishing ? null : widget.onPost,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Post Story",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
