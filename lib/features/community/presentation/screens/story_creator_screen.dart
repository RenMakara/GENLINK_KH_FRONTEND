// ignore_for_file: unused_element
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/story_model.dart';
import '../controllers/story_controller.dart';
import 'in_app_camera_screen.dart';

class StoryCreatorScreen extends StatefulWidget {
  final StoryType type;
  final String? mediaPath;

  const StoryCreatorScreen({
    super.key,
    required this.type,
    this.mediaPath,
  });

  @override
  State<StoryCreatorScreen> createState() => _StoryCreatorScreenState();
}

class _StoryCreatorScreenState extends State<StoryCreatorScreen> {
  final List<MovableStoryLayer> _layers = [];

  MovableStoryLayer? _selectedLayer;
  bool _isPublishing = false;
  String _selectedVisibility = 'Public';

  String? _activeMediaPath;
  final TextEditingController _captionController = TextEditingController();
  double _imageRotation = 0.0;
  final TransformationController _transformationController = TransformationController();

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
  MovableStoryLayer? _editingTextLayer;
  final TextEditingController _fullScreenTextController = TextEditingController();
  final FocusNode _fullScreenTextFocusNode = FocusNode();
  Color _activeTextColor = Colors.white;
  TextStyleType _activeFontStyle = TextStyleType.bold;
  TextBgStyle _activeTextBgStyle = TextBgStyle.none;
  TextAlign _activeTextAlign = TextAlign.center;

  /// Responsive font size: scales with the narrowest screen dimension.
  double get _activeFontSize {
    final shortSide = MediaQuery.of(context).size.shortestSide;
    if (shortSide < 360) return 20.0;
    if (shortSide < 400) return 22.0;
    return 24.0;
  }

  int _gradientIdx = 0;
  TextAlign _textAlign = TextAlign.center;
  TextStyleType _fontStyle = TextStyleType.bold;
  final List<List<Color>> _gradients = [
    [const Color(0xFF000000), const Color(0xFF111827)],
    [const Color(0xFF0F172A), const Color(0xFF1E293B)],
    [const Color(0xFF312E81), const Color(0xFF1E1B4B)],
    [const Color(0xFF065F46), const Color(0xFF022C22)],
    [const Color(0xFF831843), const Color(0xFF500724)],
    [const Color(0xFF4C1D95), const Color(0xFF1E1B4B)],
  ];

  // Exclusive GenLink Campus Stickers
  final Map<String, List<String>> _stickerCategories = {
    '🐱 Cute Cats': [
      '🐱 Playful Kittens',
      '🎩 Winter Cat',
      '😻 Hugging Cats',
    ],
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
    '💻 Dev & Tech': ['💻 Flutter', '☕ Java', '🚀 Docker', '⚡ SpringBoot', '🤖 AI Lab', '🌐 Cloud'],
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
    '@ChhaengSok',
    '@AUBClass2026',
  ];

  @override
  void initState() {
    super.initState();
    _activeMediaPath = widget.mediaPath;

    if (widget.type == StoryType.text) {
      _layers.add(
        MovableStoryLayer(
          id: 'initial_text',
          type: LayerType.text,
          text: 'Share your moment...',
          offset: const Offset(60, 280),
          scale: 1.2,
          fontStyle: TextStyleType.bold,
          bgStyle: TextBgStyle.rounded,
        ),
      );
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _transformationController.dispose();
    _fullScreenTextController.dispose();
    _fullScreenTextFocusNode.dispose();
    super.dispose();
  }

  void _cycleGradient() {
    setState(() {
      _gradientIdx = (_gradientIdx + 1) % _gradients.length;
    });
  }

  // Immersive Full-Screen Text Editor — replaces old popup dialog
  void _openFloatingTextEditor([MovableStoryLayer? existingLayer]) {
    setState(() {
      _editingTextLayer = existingLayer;
      _isFullScreenTextEditing = true;
      if (existingLayer != null) {
        _fullScreenTextController.text = existingLayer.text;
        _activeTextColor = existingLayer.color;
        _activeFontStyle = existingLayer.fontStyle;
        _activeTextBgStyle = existingLayer.bgStyle;
        _activeTextAlign = existingLayer.alignment;
      } else {
        _fullScreenTextController.clear();
        _activeTextColor = Colors.white;
        _activeFontStyle = TextStyleType.bold;
        _activeTextBgStyle = TextBgStyle.none; // transparent by default
        _activeTextAlign = TextAlign.center;
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DefaultTabController(
          length: _stickerCategories.keys.length,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Add Campus Sticker", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TabBar(
                  isScrollable: true,
                  indicatorColor: AppColors.communityAccent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: _stickerCategories.keys.map((cat) => Tab(text: cat)).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: TabBarView(
                    children: _stickerCategories.values.map((stickers) {
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: stickers.length,
                        itemBuilder: (context, index) {
                          final st = stickers[index];
                          final isCatSticker = st.contains('Cat') || st.contains('Kittens') || st.contains('Hugging');

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _layers.add(
                                  MovableStoryLayer(
                                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                                    type: LayerType.sticker,
                                    text: st,
                                    offset: Offset(100, 200 + (_layers.length * 15)),
                                  ),
                                );
                              });
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurfaceSecondary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isCatSticker ? Colors.white30 : Colors.transparent),
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
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: Color(0xFF2F2F2F), width: 1)),
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
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Minimal Input Field
                      TextField(
                        controller: inputCtrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        onChanged: (val) {
                          setSheetState(() {
                            currentText = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Type a hashtag...",
                          hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
                          prefixIcon: const Icon(Icons.numbers_rounded, color: Colors.white, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF1C1C1C),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF2F2F2F)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white, width: 1.2),
                          ),
                        ),
                      ),

                      // Live Preview Banner
                      if (formattedLiveTag.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text("Live Preview: ", style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                formattedLiveTag,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Section 1: Suggested
                      const Text("SUGGESTED", style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: suggestedTags.map((tag) {
                          final isSelected = formattedLiveTag.toLowerCase() == tag.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              _addHashtagLayer(tag);
                              Navigator.pop(ctx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : const Color(0xFF1C1C1C),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2F2F2F)),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
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
                      const Text("TRENDING TODAY 🔥", style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: trendingTags.map((tag) {
                          final isSelected = formattedLiveTag.toLowerCase() == tag.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              _addHashtagLayer(tag);
                              Navigator.pop(ctx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : const Color(0xFF1C1C1C),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2F2F2F)),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
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
                      const Text("RECENT", style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentTags.map((tag) {
                          final isSelected = formattedLiveTag.toLowerCase() == tag.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              _addHashtagLayer(tag);
                              Navigator.pop(ctx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : const Color(0xFF1C1C1C),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2F2F2F)),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final tag = formatTag(inputCtrl.text);
                            if (tag.isNotEmpty) {
                              _addHashtagLayer(tag);
                            }
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                          label: const Text(
                            "Add Hashtag",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
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
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: LayerType.hashtag,
          text: tag,
          offset: Offset(100, 220 + (_layers.length * 15)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              const Text("Mention Classmate / User", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: inputCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "e.g. @SoknyEnat",
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.alternate_email_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Suggested Members:", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _mentionSuggestions.map((m) {
                  return ActionChip(
                    backgroundColor: AppColors.darkSurfaceSecondary,
                    label: Text(m, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () {
                    var val = inputCtrl.text.trim();
                    if (val.isNotEmpty) {
                      if (!val.startsWith('@')) val = '@$val';
                      _addMentionLayer(val);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text("Add Mention", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addMentionLayer(String mention) {
    final size = MediaQuery.of(context).size;
    final formatted = mention.startsWith('@') ? mention : '@$mention';

    setState(() {
      final newLayer = MovableStoryLayer(
        id: "mention_${DateTime.now().microsecondsSinceEpoch}",
        type: LayerType.mention,
        text: formatted,
        offset: Offset(size.width * 0.22, size.height * 0.28 + (_layers.length * 20)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Story Visibility & Privacy", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...[
              {'title': 'Public', 'sub': 'Visible to all CampusLink KH students', 'icon': Icons.public},
              {'title': 'Friends', 'sub': 'Visible to classmates & followers only', 'icon': Icons.people},
              {'title': 'Specific Friends', 'sub': 'Selected study members', 'icon': Icons.group_add},
              {'title': 'Only Me', 'sub': 'Private draft story', 'icon': Icons.lock},
            ].map((opt) {
              final title = opt['title'] as String;
              return ListTile(
                leading: Icon(opt['icon'] as IconData, color: _selectedVisibility == title ? AppColors.communityAccent : Colors.white54),
                title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(opt['sub'] as String, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: _selectedVisibility == title ? const Icon(Icons.check_circle_rounded, color: AppColors.communityAccent) : null,
                onTap: () {
                  setState(() => _selectedVisibility = title);
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
        final newLayer = MovableStoryLayer(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: LayerType.image,
          text: media.path,
          offset: Offset(60, 180 + (_layers.length * 25)),
          scale: 1.0,
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
            const Icon(Icons.broken_image_rounded, color: AppColors.danger, size: 56),
            const SizedBox(height: 12),
            const Text(
              "Unable to load image.",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                            _isVideoPlaying ? Icons.movie_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam_rounded, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  file.path.split(RegExp(r'[/\\]')).last,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                          _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
                  _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Text("00:05", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
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
                const Text("00:15", style: TextStyle(color: Colors.white38, fontSize: 12)),
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
        _transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
      }
    });
  }

  Widget _buildImageCanvas(File file) {
    final size = MediaQuery.of(context).size;

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
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (ctx, err, stack) => _buildErrorMediaPlaceholder(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCanvas() {
    if (_activeMediaPath == null || _activeMediaPath!.isEmpty) {
      final text = _captionController.text.trim().isNotEmpty
          ? _captionController.text.trim()
          : "Share your moment...";

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradients[_gradientIdx],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Text(
              text,
              textAlign: _textAlign,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: _fontStyle == TextStyleType.bold ? FontWeight.w900 : FontWeight.w600,
                fontStyle: _fontStyle == TextStyleType.handwriting ? FontStyle.italic : FontStyle.normal,
                height: 1.35,
                shadows: const [
                  Shadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
            ),
          ),
        ),
      );
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
    setState(() => _isPublishing = true);

    try {
      final controller = Get.find<StoryController>();
      final caption = _captionController.text.trim();
      final textContent = caption.isNotEmpty
          ? caption
          : (_layers.isNotEmpty ? _layers.first.text : "CampusLink Story");

      final success = await controller.publishStory(
        type: widget.type,
        mediaUrl: _activeMediaPath,
        textContent: textContent,
        visibility: _selectedVisibility,
        layers: List.from(_layers),
      );

      if (mounted) {
        setState(() => _isPublishing = false);
        if (success) {
          Get.until((route) => route.isFirst);
          AppNotificationBanner.showSuccess(
            context: context,
            title: "✓ Story Live",
            message: "Your story has been shared with $_selectedVisibility on CampusLink KH!",
            icon: Icons.auto_awesome_rounded,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        AppNotificationBanner.showDanger(
          context: context,
          title: "Upload Failed",
          message: "Could not publish story. Please try again.",
        );
      }
    }
  }

  TextStyle _getLayerTextStyle(TextStyleType fontStyle, Color color, TextBgStyle bgStyle) {
    FontWeight weight = FontWeight.w600;
    FontStyle style = FontStyle.normal;
    double letterSpacing = 0.2;
    double height = 1.25;
    List<Shadow>? textShadows;

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
      case TextStyleType.modern: // Outline
        weight = FontWeight.w800;
        letterSpacing = 0.6;
        break;
      case TextStyleType.minimal: // Neon
        weight = FontWeight.w700;
        letterSpacing = 1.2;
        textShadows = [
          Shadow(blurRadius: 8.0, color: color.withValues(alpha: 0.90), offset: Offset.zero),
          Shadow(blurRadius: 20.0, color: color.withValues(alpha: 0.80), offset: Offset.zero),
          Shadow(blurRadius: 36.0, color: color, offset: Offset.zero),
        ];
        break;
      default:
        weight = FontWeight.w700;
        break;
    }

    if (textShadows == null && bgStyle == TextBgStyle.none) {
      textShadows = [
        Shadow(blurRadius: 6.0, color: Colors.black.withValues(alpha: 0.75), offset: const Offset(0, 1)),
        Shadow(blurRadius: 14.0, color: Colors.black.withValues(alpha: 0.40), offset: const Offset(0, 2)),
      ];
    }

    return TextStyle(
      color: color,
      fontSize: 24,
      fontWeight: weight,
      fontStyle: style,
      letterSpacing: letterSpacing,
      height: height,
      shadows: textShadows,
    );
  }

  bool _isInteractingLayer = false;
  bool _isHoveringDeleteZone = false;

  Widget _buildLayerWidget(MovableStoryLayer layer) {
    if (_isFullScreenTextEditing && _editingTextLayer?.id == layer.id) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxCanvasWidth = screenWidth * 0.85;

    Widget content;

    switch (layer.type) {
      case LayerType.image:
        final file = File(layer.text);
        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedLayer?.id == layer.id ? Colors.white : Colors.transparent,
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
              child: Image.file(
                file,
                width: 180,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _buildErrorMediaPlaceholder(),
              ),
            ),
          ),
        );
        break;

      case LayerType.text:
        final hasBackground = layer.bgStyle != TextBgStyle.none;
        final baseStyle = _getLayerTextStyle(layer.fontStyle, layer.color, layer.bgStyle);

        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth * 0.88),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: hasBackground
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: hasBackground
                  ? (layer.bgStyle == TextBgStyle.filled
                      ? Colors.black.withValues(alpha: 0.78)
                      : (layer.bgStyle == TextBgStyle.rounded
                          ? Colors.black.withValues(alpha: 0.55)
                          : Colors.transparent))
                  : Colors.transparent,
              borderRadius: hasBackground ? BorderRadius.circular(10) : null,
              border: layer.bgStyle == TextBgStyle.outline
                  ? Border.all(color: layer.color.withValues(alpha: 0.85), width: 1.8)
                  : null,
            ),
            child: Text(
              layer.text,
              softWrap: true,
              textAlign: layer.alignment,
              style: baseStyle,
            ),
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
                errorBuilder: (ctx, err, st) => Text(
                  layer.text,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          );
        } else {
          content = Text(
            layer.text,
            style: const TextStyle(fontSize: 54),
          );
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        );
        break;

      case LayerType.mention:
        final cleanMention = layer.text.startsWith('@') ? layer.text : '@${layer.text}';
        final hasBg = layer.bgStyle != TextBgStyle.none;
        final textColor = layer.bgStyle == TextBgStyle.filled ? Colors.black : Colors.white;

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
        final textColor = layer.bgStyle == TextBgStyle.filled ? Colors.black : Colors.white;

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
                Icon(
                  Icons.location_on_rounded,
                  color: textColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    child: Text(
                      cleanLocation,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                const Icon(Icons.music_note_rounded, color: AppColors.communityAccent, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    layer.text,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
    }

    final isSelected = _selectedLayer?.id == layer.id;
    final isDeleting = _deletingLayerIds.contains(layer.id);

    return Positioned(
      left: layer.offset.dx,
      top: layer.offset.dy,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: isDeleting ? 0.0 : 1.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          scale: isDeleting ? 0.9 : 1.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_selectedLayer?.id == layer.id && layer.type == LayerType.text) {
                _openFloatingTextEditor(layer);
              } else {
                setState(() {
                  _selectedLayer = layer;

                  // Cycle color style variant on tap for Mention and Location tags
                  if (layer.type == LayerType.mention || layer.type == LayerType.location) {
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
            onPanStart: (details) {
              setState(() {
                _selectedLayer = layer;
                _isInteractingLayer = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _selectedLayer = layer;
                final maxX = screenWidth - 20.0;
                final maxY = screenHeight - 60.0;

                final nextX = (layer.offset.dx + details.delta.dx).clamp(-120.0, maxX);
                final nextY = (layer.offset.dy + details.delta.dy).clamp(10.0, maxY);

                layer.offset = Offset(nextX, nextY);
                _isHoveringDeleteZone = layer.offset.dy > (screenHeight - 160.0);
              });
            },
            onPanEnd: (details) {
              final isOverDeleteArea = layer.offset.dy > (screenHeight - 160.0);
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
              child: Transform.rotate(
                angle: layer.rotation,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Selection ring — subtle dashed outline, only when selected & idle (text type)
                    if (isSelected && layer.type == LayerType.text && !_isInteractingLayer)
                      Positioned(
                        top: -6,
                        left: -6,
                        right: -6,
                        bottom: -6,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
                                width: 1.2,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Interaction ring — solid white while dragging/scaling
                    if (isSelected && _isInteractingLayer)
                      Positioned(
                        top: -4,
                        left: -4,
                        right: -4,
                        bottom: -4,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: content,
                    ),
                  ],
                ),
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
          final filtered = _locationOptions.where((loc) => loc.toLowerCase().contains(query.toLowerCase())).toList();
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
                        const Text("Add Location Tag", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
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
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                        filled: true,
                        fillColor: AppColors.darkSurfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                "No locations found",
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final loc = filtered[index];
                                final distances = ["250 m", "600 m", "1.2 km", "1.8 km", "2.5 km"];
                                final distanceStr = distances[index % distances.length];

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                                  ),
                                  title: Text(
                                    loc,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    distanceStr,
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                  onTap: () {
                                    final size = MediaQuery.of(context).size;
                                    setState(() {
                                      final newLayer = MovableStoryLayer(
                                        id: "location_${DateTime.now().microsecondsSinceEpoch}",
                                        type: LayerType.location,
                                        text: loc,
                                        offset: Offset(size.width * 0.20, size.height * 0.32 + (_layers.length * 15)),
                                      );
                                      _layers.add(newLayer);
                                      _selectedLayer = newLayer;
                                    });
                                    Navigator.pop(ctx);
                                  },
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Background Music Track", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._musicOptions.map((track) {
              return ListTile(
                leading: const Icon(Icons.music_note_rounded, color: AppColors.communityAccent),
                title: Text(track, style: const TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  setState(() {
                    _layers.add(
                      MovableStoryLayer(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        type: LayerType.music,
                        text: track,
                        offset: Offset(80, 220 + (_layers.length * 15)),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                },
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

    final primaryColors = [
      Colors.white,
      Colors.black,
      const Color(0xFF8E8E93),
    ];

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
            BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 4)),
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
                      color: _activeTextToolbarTab == 0 ? Colors.white : Colors.white54,
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
                    color: _activeTextToolbarTab == 1 ? Colors.white : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _activeTextToolbarTab = 1),
                ),

                // 3. Background Style (⬛)
                IconButton(
                  icon: Icon(
                    Icons.subtitles_rounded,
                    color: _activeTextToolbarTab == 2 ? Colors.white : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _activeTextToolbarTab = 2),
                ),

                // 4. Alignment Toggle (☰)
                IconButton(
                  icon: Icon(
                    layer.alignment == TextAlign.left
                        ? Icons.format_align_left_rounded
                        : (layer.alignment == TextAlign.right ? Icons.format_align_right_rounded : Icons.format_align_center_rounded),
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
                    final textStyle = _getLayerTextStyle(fStyle, isSelected ? Colors.black : Colors.white, TextBgStyle.none);

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => layer.fontStyle = fStyle),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2F2F2F)),
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
                              color: isSelected ? Colors.white : const Color(0xFF2F2F2F),
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: isSelected ? Icon(Icons.check_rounded, color: c == Colors.white ? Colors.black : Colors.white, size: 16) : null,
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
                  children: [
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2F2F2F)),
                          ),
                          child: Text(
                            bg.name.capitalizeFirst!,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
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

  Widget _buildObjectToolbar(MovableStoryLayer layer) {
    return Positioned(
      top: (layer.offset.dy - 55).clamp(60.0, MediaQuery.of(context).size.height - 220),
      left: (layer.offset.dx - 10).clamp(16.0, MediaQuery.of(context).size.width - 220),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xF21A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF262626), width: 1),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Object Action (Style for text, Replace for image/sticker)
              if (layer.type == LayerType.text) ...[
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeTextToolbarTab = (_activeTextToolbarTab + 1) % 3;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.palette_outlined, color: Colors.white, size: 18),
                  label: const Text("Style", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                Container(height: 16, width: 1, color: Colors.white12),
              ] else if (layer.type == LayerType.image || layer.type == LayerType.sticker) ...[
                TextButton.icon(
                  onPressed: () async {
                    if (layer.type == LayerType.image) {
                      try {
                        final picker = ImagePicker();
                        final XFile? media = await picker.pickMedia(imageQuality: 95);
                        if (media != null && mounted) {
                          setState(() => layer.text = media.path);
                        }
                      } catch (_) {}
                    } else if (layer.type == LayerType.sticker) {
                      _showStickerSheet();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                  label: const Text("Replace", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                Container(height: 16, width: 1, color: Colors.white12),
              ],

              // 2. Immediate Delete Action
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                tooltip: "Delete",
                onPressed: () => _deleteLayerInstantly(layer),
              ),
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
    final currentImagesCount = _layers.where((l) => l.type == LayerType.image).length;
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
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 95);

      if (images.isNotEmpty && mounted) {
        final remainingSlots = 10 - currentImagesCount;
        final selectedImages = images.take(remainingSlots).toList();

        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        setState(() {
          int count = currentImagesCount;
          for (final img in selectedImages) {
            final col = count % 2;
            final row = count ~/ 2;

            final startX = (screenWidth * 0.15) + (col * 150.0);
            final startY = (screenHeight * 0.20) + (row * 150.0);

            final clampedX = startX.clamp(16.0, screenWidth - 160.0);
            final clampedY = startY.clamp(80.0, screenHeight - 200.0);

            final newLayer = MovableStoryLayer(
              id: DateTime.now().microsecondsSinceEpoch.toString() + count.toString(),
              type: LayerType.image,
              text: img.path,
              offset: Offset(clampedX, clampedY),
              scale: 1.0,
            );

            _layers.add(newLayer);
            _selectedLayer = newLayer;
            count++;
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
    final hasUnsavedChanges = _layers.isNotEmpty || _activeMediaPath != null || _gradientIdx != 0;
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
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
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
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                                  side: const BorderSide(color: Colors.white24, width: 1.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Background Gradients Row
              const Text("Background Gradient", style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                          border: isSel ? Border.all(color: Colors.white, width: 2.5) : Border.all(color: Colors.white24),
                        ),
                        child: isSel ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
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
                        const Text("Font Style", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              if (_fontStyle == TextStyleType.bold) {
                                _fontStyle = TextStyleType.handwriting;
                              } else if (_fontStyle == TextStyleType.handwriting) {
                                _fontStyle = TextStyleType.minimal;
                              } else {
                                _fontStyle = TextStyleType.bold;
                              }
                            });
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.font_download_outlined, size: 18),
                          label: Text(_fontStyle.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkSurfaceSecondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Alignment", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              if (_textAlign == TextAlign.center) {
                                _textAlign = TextAlign.left;
                              } else if (_textAlign == TextAlign.left) {
                                _textAlign = TextAlign.right;
                              } else {
                                _textAlign = TextAlign.center;
                              }
                            });
                            setSheetState(() {});
                          },
                          icon: Icon(
                            _textAlign == TextAlign.center
                                ? Icons.format_align_center_rounded
                                : (_textAlign == TextAlign.left ? Icons.format_align_left_rounded : Icons.format_align_right_rounded),
                            size: 18,
                          ),
                          label: Text(_textAlign.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkSurfaceSecondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _openEmojiPicker() {
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
      'Trending': ['🔥', '🚀', '💯', '✨', '⚡', '🎉', '🌟', '💪', '🏆', '👑', '🎯', '💥'],
      'Emoji': ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '🥹', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘'],
      'Student Life': ['📚', '💻', '☕', '📝', '🎓', '📖', '✍️', '🏫', '🎒', '🧠', '💡', '📊'],
      'Celebration': ['🎉', '🥳', '🍾', '🎈', '🎊', '🎁', '🎂', '🥂', '🎇', '🎆', '✨', '🏆'],
      'Funny': ['🤪', '😜', '👻', '🤡', '🤖', '👽', '💩', '🙈', '🙉', '🙊', '🐸', '🦄'],
      'Love': ['❤️', '💖', '💗', '💓', '💞', '💕', '💘', '💌', '😍', '🥰', '🌹', '💐'],
      'Campus': ['🎓', '🏛️', '🏫', '🤝', '📜', '📢', '💡', '🏆', '📖', '💻', '☕', '📝'],
      'Khmer': ['🇰🇭', '🏛️', '🥭', '🌴', '🐘', '🌾', '🍜', '☕', '🥥', '🛵', '⛵', '🌅'],
      'Custom': ['✨', '🌟', '🎨', '📸', '🎵', '🎬', '💎', '🌈', '🔥', '⚡', '🍀', '🌸'],
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
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
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
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                        filled: true,
                        fillColor: AppColors.darkSurfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            final isSel = selectedCategory == cat && query.isEmpty;
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
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      color: isSel ? Colors.black : Colors.white70,
                                      fontSize: 12.5,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
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
                        style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
                                _addStickerToCanvas(stk);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: stk.startsWith('assets/')
                                    ? Image.asset(stk, width: 34, height: 34, fit: BoxFit.contain)
                                    : Text(stk, style: const TextStyle(fontSize: 22)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Text(
                      query.isNotEmpty ? "SEARCH RESULTS (${displayStickers.length})" : selectedCategory.toUpperCase(),
                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: displayStickers.isEmpty
                          ? const Center(
                              child: Text(
                                "No stickers found",
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                      setState(() => _recentStickers.insert(0, sticker));
                                    }
                                    Navigator.pop(bCtx);
                                    _addStickerToCanvas(sticker);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.all(isAsset ? 8 : 0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: isAsset
                                        ? Image.asset(sticker, fit: BoxFit.contain)
                                        : Text(
                                            sticker,
                                            style: const TextStyle(fontSize: 32),
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
    final size = MediaQuery.of(context).size;
    final newLayer = MovableStoryLayer(
      id: "sticker_${DateTime.now().microsecondsSinceEpoch}",
      type: LayerType.sticker,
      text: stickerText,
      offset: Offset(size.width * 0.35, size.height * 0.35 + (_layers.length * 15)),
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
        final size = MediaQuery.of(context).size;
        setState(() {
          if (_editingTextLayer != null) {
            _editingTextLayer!.text = text;
            _editingTextLayer!.color = _activeTextColor;
            _editingTextLayer!.fontStyle = _activeFontStyle;
            _editingTextLayer!.bgStyle = _activeTextBgStyle;
            _editingTextLayer!.alignment = _activeTextAlign;
            _selectedLayer = _editingTextLayer;
          } else {
            // Place new text at true canvas center
            final newLayer = MovableStoryLayer(
              id: "text_${DateTime.now().microsecondsSinceEpoch}",
              type: LayerType.text,
              text: text,
              color: _activeTextColor,
              fontStyle: _activeFontStyle,
              bgStyle: _activeTextBgStyle,
              alignment: _activeTextAlign,
              offset: Offset(
                size.width * 0.5 - 80,
                size.height * 0.42,
              ),
              scale: 1.0,
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
    });
  }

  Widget _buildFullScreenTextEditorOverlay() {
    if (!_isFullScreenTextEditing) return const SizedBox.shrink();

    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    final screenWidth = mq.size.width;
    final isBoldActive = _activeFontStyle == TextStyleType.bold || _activeFontStyle == TextStyleType.campus;
    final hasBackground = _activeTextBgStyle != TextBgStyle.none;
    final fontSize = _activeFontSize;

    // --- Data ---
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
      (TextStyleType.classic,     'Classic',     FontWeight.w600, FontStyle.normal),
      (TextStyleType.elegant,     'Deco',        FontWeight.w600, FontStyle.italic),
      (TextStyleType.bold,        'Bubble',      FontWeight.w900, FontStyle.normal),
      (TextStyleType.modern,      'Outline',     FontWeight.w800, FontStyle.normal),
      (TextStyleType.minimal,     'Neon',        FontWeight.w700, FontStyle.normal),
    ];

    // Resolve text preview style (live update)
    final liveTextStyle = _getLayerTextStyle(
      _activeFontStyle,
      _activeTextColor,
      _activeTextBgStyle,
    ).copyWith(
      fontSize: fontSize,
      shadows: hasBackground ? null : [
        Shadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.80), offset: const Offset(0, 1)),
      ],
    );

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _isFullScreenTextEditing ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.black.withValues(alpha: 0.62),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ═══════════════════ TOP BAR ═══════════════════
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Cancel
                      _buildTextEditorPill(
                        label: 'Cancel',
                        onTap: () => _closeFullScreenTextEditor(save: false),
                        filled: false,
                      ),

                      const Spacer(),

                      // Align
                      _buildEditorIconBtn(
                        icon: _activeTextAlign == TextAlign.left
                            ? Icons.format_align_left_rounded
                            : _activeTextAlign == TextAlign.right
                                ? Icons.format_align_right_rounded
                                : Icons.format_align_center_rounded,
                        active: false,
                        tooltip: 'Alignment',
                        onTap: () => setState(() {
                          if (_activeTextAlign == TextAlign.center) {
                            _activeTextAlign = TextAlign.left;
                          } else if (_activeTextAlign == TextAlign.left) {
                            _activeTextAlign = TextAlign.right;
                          } else {
                            _activeTextAlign = TextAlign.center;
                          }
                        }),
                      ),

                      const SizedBox(width: 8),

                      // Bold
                      _buildEditorIconBtn(
                        icon: Icons.format_bold_rounded,
                        active: isBoldActive,
                        tooltip: 'Bold',
                        onTap: () => setState(() {
                          _activeFontStyle =
                              isBoldActive ? TextStyleType.classic : TextStyleType.bold;
                        }),
                      ),

                      const SizedBox(width: 8),

                      // Background
                      _buildEditorIconBtn(
                        icon: hasBackground
                            ? Icons.rectangle_rounded
                            : Icons.crop_free_rounded,
                        active: hasBackground,
                        tooltip: 'Background',
                        onTap: () => setState(() {
                          _activeTextBgStyle = hasBackground
                              ? TextBgStyle.none
                              : TextBgStyle.rounded;
                        }),
                      ),

                      const SizedBox(width: 10),

                      // Done
                      _buildTextEditorPill(
                        label: 'Done',
                        onTap: () => _closeFullScreenTextEditor(save: true),
                        filled: true,
                      ),
                    ],
                  ),
                ),

                // ═════════════════ TEXT INPUT AREA ═════════════════
                Expanded(
                  child: GestureDetector(
                    onTap: () => _fullScreenTextFocusNode.requestFocus(),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          padding: hasBackground
                              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                              : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: _activeTextBgStyle == TextBgStyle.rounded
                                ? Colors.black.withValues(alpha: 0.52)
                                : _activeTextBgStyle == TextBgStyle.filled
                                    ? Colors.black.withValues(alpha: 0.76)
                                    : Colors.transparent,
                            borderRadius: hasBackground
                                ? BorderRadius.circular(8)
                                : null,
                            border: _activeTextBgStyle == TextBgStyle.outline
                                ? Border.all(
                                    color: _activeTextColor.withValues(alpha: 0.85),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: TextField(
                            controller: _fullScreenTextController,
                            focusNode: _fullScreenTextFocusNode,
                            autofocus: true,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            textAlign: _activeTextAlign,
                            textCapitalization: TextCapitalization.sentences,
                            style: liveTextStyle,
                            cursorColor: _activeTextColor,
                            cursorWidth: 2.0,
                            cursorRadius: const Radius.circular(1),
                            decoration: InputDecoration(
                              hintText: 'Start typing...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.28),
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ═════════════════ BOTTOM TOOLBAR ═════════════════
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: keyboardHeight > 0 ? keyboardHeight + 10 : 24,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xF2111111),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Font row ──
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: fontPresets.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final (fStyle, label, fw, fi) = fontPresets[i];
                            final isSel = _activeFontStyle == fStyle;
                            return GestureDetector(
                              onTap: () => setState(() => _activeFontStyle = fStyle),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSel
                                      ? null
                                      : Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: isSel ? Colors.black : Colors.white.withValues(alpha: 0.65),
                                    fontSize: 12.5,
                                    fontWeight: isSel ? fw : FontWeight.w400,
                                    fontStyle: isSel ? fi : FontStyle.normal,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.12),
                                Colors.white.withValues(alpha: 0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Color row ──
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: textColors.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final col = textColors[i];
                            final isSel = _activeTextColor == col;
                            // Compute contrasting check icon color
                            final lum = col.computeLuminance();
                            final checkColor = lum > 0.5 ? Colors.black : Colors.white;

                            return GestureDetector(
                              onTap: () => setState(() => _activeTextColor = col),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                width: isSel ? 36 : 30,
                                height: isSel ? 36 : 30,
                                decoration: BoxDecoration(
                                  color: col,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.25),
                                    width: isSel ? 2.5 : 1.0,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: col.withValues(alpha: 0.60),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSel
                                    ? Icon(Icons.check_rounded, size: 15, color: checkColor)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pill-shaped button for Cancel / Done in the text editor top bar.
  Widget _buildTextEditorPill({
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
          border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.black : Colors.white.withValues(alpha: 0.80),
            fontWeight: filled ? FontWeight.bold : FontWeight.w500,
            fontSize: 13.5,
            letterSpacing: 0.1,
          ),
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
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.22),
            ),
            boxShadow: active
                ? [BoxShadow(color: Colors.white.withValues(alpha: 0.25), blurRadius: 8)]
                : null,
          ),
          child: Icon(icon, size: 18, color: active ? Colors.black : Colors.white),
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
    bool isPlaceholder = false,
  }) {
    return GestureDetector(
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
              child: Icon(
                icon,
                color: isPlaceholder ? Colors.white38 : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isPlaceholder ? Colors.white38 : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoSourceSheet() {
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
                "Photo Source",
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),

            // 1. Camera
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
              title: const Text("Camera", style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
              subtitle: const Text("Capture a new photo using camera", style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(bCtx);
                Get.to(() => const InAppCameraScreen(initialIsVideoMode: false));
              },
            ),

            // 2. Gallery
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
              ),
              title: const Text("Gallery", style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
              subtitle: const Text("Add photo layer from gallery", style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(bCtx);
                _addPhotoLayer();
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
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
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),

            // 1. Rotate Image
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rotate_right_rounded, color: Colors.white, size: 20),
              ),
              title: const Text("Rotate Image", style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
              subtitle: const Text("Rotate image by 90 degrees", style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(bCtx);
                _rotateImage();
              },
            ),

            // 2. Remove Photo
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
              ),
              title: const Text("Remove Photo", style: TextStyle(color: AppColors.danger, fontSize: 14.5, fontWeight: FontWeight.bold)),
              subtitle: const Text("Discard draft and return to home", style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
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
                        setState(() => _selectedLayer = null);
                      },
                      child: _buildMediaCanvas(),
                    ),
                  ),

                  // Movable Overlays (Text / Stickers)
                  ..._layers.map((layer) => _buildLayerWidget(layer)),

                  // Inline TikTok Text Formatting Bar for Selected Text Layer
                  if (_selectedLayer != null && _selectedLayer!.type == LayerType.text && !_isFullScreenTextEditing)
                    _buildTikTokInlineTextToolbar(_selectedLayer!),

                  // Full-Screen Immersive Text Editor Overlay
                  _buildFullScreenTextEditorOverlay(),
                ],
              ),
            ),

            // 2. Top Header Overlay Bar (Floating gradient header)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.black45, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                          onPressed: () async {
                            final shouldPop = await _confirmDiscardDraft();
                            if (shouldPop) {
                              Get.back();
                            }
                          },
                        ),

                        Text(
                          widget.type == StoryType.text ? "Create Story" : "Preview Story",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                          ),
                        ),

                        // Placeholder for symmetric centering
                        const SizedBox(width: 48, height: 48),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isHoveringDeleteZone
                          ? AppColors.danger.withValues(alpha: 0.95)
                          : Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isHoveringDeleteZone ? Colors.white : Colors.white24,
                        width: _isHoveringDeleteZone ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isHoveringDeleteZone ? AppColors.danger.withValues(alpha: 0.6) : Colors.black45,
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
                          _isHoveringDeleteZone ? "Release to Delete" : "Drag here to delete",
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black54, Colors.black87, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Horizontally Scrollable Tool Strip (Icon + Short Label)
                        SizedBox(
                          height: 70,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                // 1. Photo Source (Active)
                                if (widget.type != StoryType.text)
                                  _buildHorizontalToolItem(
                                    icon: Icons.photo_library_outlined,
                                    label: "Photo",
                                    onTap: _showPhotoSourceSheet,
                                  ),

                                // 2. Add Text Overlay (Active)
                                _buildHorizontalToolItem(
                                  icon: Icons.title_rounded,
                                  label: "Text",
                                  onTap: () => _openFloatingTextEditor(),
                                ),

                                // 3. Emoji Sticker (Active)
                                _buildHorizontalToolItem(
                                  icon: Icons.emoji_emotions_outlined,
                                  label: "Emoji",
                                  onTap: _openEmojiPicker,
                                ),

                                // 4. Location Tag (Active)
                                _buildHorizontalToolItem(
                                  icon: Icons.location_on_outlined,
                                  label: "Location",
                                  onTap: _openLocationPicker,
                                ),

                                // 5. Rotate Image (Active)
                                if (widget.type != StoryType.text)
                                  _buildHorizontalToolItem(
                                    icon: Icons.rotate_right_rounded,
                                    label: "Rotate",
                                    onTap: _rotateImage,
                                  ),

                                // 6. Style / Background (Text Story Mode)
                                if (widget.type == StoryType.text)
                                  _buildHorizontalToolItem(
                                    icon: Icons.palette_outlined,
                                    label: "Style",
                                    onTap: _showCustomizeTextSheet,
                                  ),

                                // 7. Mention Tag (@) (Active)
                                _buildHorizontalToolItem(
                                  icon: Icons.alternate_email_rounded,
                                  label: "Mention",
                                  onTap: _showMentionSheet,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Single Primary White "Post Story" Call-To-Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isPublishing ? null : _publishStory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              disabledBackgroundColor: Colors.white24,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 2,
                            ),
                            child: _isPublishing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    "Post Story",
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          ),
                        ),
                      ],
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
