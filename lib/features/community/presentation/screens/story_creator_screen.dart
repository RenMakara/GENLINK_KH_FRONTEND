// ignore_for_file: unused_element
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/story_model.dart';
import '../controllers/story_controller.dart';

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

  void _rotateImage() {
    setState(() {
      _imageRotation = (_imageRotation + 90) % 360;
    });
  }

  int _gradientIdx = 0;
  final List<List<Color>> _gradients = [
    [const Color(0xFF000000), const Color(0xFF111827)],
    [const Color(0xFF0F172A), const Color(0xFF1E293B)],
    [const Color(0xFF312E81), const Color(0xFF1E1B4B)],
    [const Color(0xFF065F46), const Color(0xFF022C22)],
    [const Color(0xFF831843), const Color(0xFF500724)],
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

  final List<String> _locationOptions = [
    '📍 ACLEDA University of Business',
    '📍 Main Library',
    '📍 Phnom Penh, Cambodia',
    '📍 CADT Innovation Lab',
    '📍 RUPP Campus',
    '📍 Campus Cafe',
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
    super.dispose();
  }

  void _cycleGradient() {
    setState(() {
      _gradientIdx = (_gradientIdx + 1) % _gradients.length;
    });
  }

  void _openFloatingTextEditor([MovableStoryLayer? existingLayer]) {
    final textController = TextEditingController(text: existingLayer?.text ?? '');

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dlgCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF262626)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 4,
                minLines: 1,
                textAlign: existingLayer?.alignment ?? TextAlign.center,
                onChanged: (val) {
                  if (existingLayer != null) {
                    setState(() {
                      existingLayer.text = val;
                    });
                  }
                },
                onSubmitted: (val) {
                  final textVal = val.trim();
                  if (textVal.isNotEmpty) {
                    if (existingLayer != null) {
                      setState(() => existingLayer.text = textVal);
                    } else {
                      final newLayer = MovableStoryLayer(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        type: LayerType.text,
                        text: textVal,
                        offset: Offset(80, 200 + (_layers.length * 20)),
                      );
                      setState(() {
                        _layers.add(newLayer);
                        _selectedLayer = newLayer;
                      });
                    }
                  }
                  Navigator.pop(dlgCtx);
                },
                decoration: const InputDecoration(
                  hintText: "Type story text...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 18),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                    onPressed: () {
                      final textVal = textController.text.trim();
                      if (textVal.isNotEmpty) {
                        if (existingLayer != null) {
                          setState(() => existingLayer.text = textVal);
                        } else {
                          final newLayer = MovableStoryLayer(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            type: LayerType.text,
                            text: textVal,
                            offset: Offset(80, 200 + (_layers.length * 20)),
                          );
                          setState(() {
                            _layers.add(newLayer);
                            _selectedLayer = newLayer;
                          });
                        }
                      }
                      Navigator.pop(dlgCtx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    setState(() {
      _layers.add(
        MovableStoryLayer(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: LayerType.mention,
          text: mention,
          offset: Offset(90, 240 + (_layers.length * 15)),
        ),
      );
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

  Future<void> _replaceMedia() async {
    try {
      final picker = ImagePicker();
      final XFile? media = await picker.pickMedia(imageQuality: 95);
      if (media != null && mounted) {
        setState(() {
          _activeMediaPath = media.path;
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

  Widget _buildImageCanvas(File file) {
    return GestureDetector(
      onDoubleTap: _resetZoom,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: RotatedBox(
          quarterTurns: (_imageRotation / 90).round() % 4,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            },
            errorBuilder: (ctx, err, stack) => _buildErrorMediaPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCanvas() {
    if (_activeMediaPath == null || _activeMediaPath!.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradients[_gradientIdx],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
          Navigator.pop(context);
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
    FontWeight weight = FontWeight.normal;
    FontStyle style = FontStyle.normal;

    switch (fontStyle) {
      case TextStyleType.bold:
        weight = FontWeight.w900;
        break;
      case TextStyleType.modern:
        weight = FontWeight.bold;
        break;
      case TextStyleType.handwriting:
        style = FontStyle.italic;
        break;
      case TextStyleType.serif:
        weight = FontWeight.w600;
        break;
      case TextStyleType.monospace:
        weight = FontWeight.w500;
        break;
      case TextStyleType.minimal:
        weight = FontWeight.w300;
        break;
      case TextStyleType.elegant:
        style = FontStyle.italic;
        weight = FontWeight.w500;
        break;
      case TextStyleType.campus:
        weight = FontWeight.w900;
        break;
      case TextStyleType.coding:
        weight = FontWeight.w600;
        break;
      case TextStyleType.khmer:
        weight = FontWeight.bold;
        break;
      case TextStyleType.classic:
        weight = FontWeight.w600;
        break;
    }

    return TextStyle(
      color: color,
      fontSize: 22,
      fontWeight: weight,
      fontStyle: style,
      shadows: bgStyle == TextBgStyle.none
          ? const [Shadow(blurRadius: 4.0, color: Colors.black54, offset: Offset(1, 1))]
          : null,
    );
  }

  double _gestureBaseScale = 1.0;
  double _gestureBaseRotation = 0.0;
  bool _isInteractingLayer = false;

  Widget _buildLayerWidget(MovableStoryLayer layer) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCanvasWidth = screenWidth * 0.85;

    Widget content;

    switch (layer.type) {
      case LayerType.text:
        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: layer.bgStyle == TextBgStyle.rounded || layer.bgStyle == TextBgStyle.filled
                    ? Colors.black.withValues(alpha: 0.6)
                    : (layer.bgStyle == TextBgStyle.highlight ? AppColors.communityAccent : Colors.transparent),
                borderRadius: BorderRadius.circular(layer.bgStyle == TextBgStyle.rounded ? 12 : 4),
                border: layer.bgStyle == TextBgStyle.outline ? Border.all(color: layer.color, width: 2) : null,
              ),
              child: Text(
                layer.text,
                softWrap: true,
                textAlign: layer.alignment,
                style: _getLayerTextStyle(layer.fontStyle, layer.color, layer.bgStyle),
              ),
            ),
          ),
        );
        break;

      case LayerType.sticker:
        final isCatSticker = layer.text.contains('Cat') || layer.text.contains('Kittens') || layer.text.contains('Hugging') || layer.text.startsWith('assets/');
        if (isCatSticker) {
          content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCanvasWidth),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/cat_stickers.png',
                  width: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => Text(
                    layer.text,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          );
        } else {
          content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCanvasWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkSurfacePrimary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                layer.text,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
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
        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              layer.text,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        );
        break;

      case LayerType.location:
        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 16),
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

      case LayerType.image:
        final localFile = _resolveFile(layer.text);
        Widget imgWidget;
        if (localFile.existsSync()) {
          imgWidget = Image.file(localFile, fit: BoxFit.cover);
        } else if (layer.text.startsWith('assets/')) {
          imgWidget = Image.asset(layer.text, fit: BoxFit.cover);
        } else {
          imgWidget = Image.network(layer.text, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white54));
        }

        content = Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imgWidget,
          ),
        );
        break;
    }

    final isSelected = _selectedLayer?.id == layer.id;
    final isDeleting = _deletingLayerIds.contains(layer.id);
    final screenHeight = MediaQuery.of(context).size.height;

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
            onTap: () {
              setState(() => _selectedLayer = layer);
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
            onScaleEnd: (details) {
              setState(() {
                _isInteractingLayer = false;
              });
            },
            onScaleUpdate: (details) {
              setState(() {
                _selectedLayer = layer;

                if (details.scale != 1.0) {
                  layer.scale = (_gestureBaseScale * details.scale).clamp(0.5, 3.5);
                }

                if (details.rotation != 0.0) {
                  layer.rotation = _gestureBaseRotation + details.rotation;
                }

                final maxX = (screenWidth * 0.88 - 40.0).clamp(40.0, screenWidth);
                final maxY = (screenHeight - 120.0).clamp(100.0, screenHeight);

                final nextX = (layer.offset.dx + details.focalPointDelta.dx).clamp(8.0, maxX);
                final nextY = (layer.offset.dy + details.focalPointDelta.dy).clamp(50.0, maxY);

                layer.offset = Offset(nextX, nextY);
              });
            },
            child: Transform.scale(
              scale: layer.scale,
              child: Transform.rotate(
                angle: layer.rotation,
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected && _isInteractingLayer
                        ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.0)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: content,
                  ),
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

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfacePrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Add Location Sticker", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Rounded Search Bar
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) => setSheetState(() => query = val),
                      decoration: InputDecoration(
                        hintText: "Search university, city or landmark...",
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                        filled: true,
                        fillColor: AppColors.darkSurfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text("SUGGESTED CAMPUS LOCATIONS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 8),

                    ...filtered.map((loc) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 18),
                        ),
                        title: Text(loc, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text("Verified Campus Pin", style: TextStyle(color: Colors.white38, fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _layers.add(
                              MovableStoryLayer(
                                id: DateTime.now().microsecondsSinceEpoch.toString(),
                                type: LayerType.location,
                                text: loc,
                                offset: Offset(80, 200 + (_layers.length * 15)),
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

    final deletedIndex = _layers.indexOf(layer);
    final deletedLayer = layer;

    setState(() {
      _deletingLayerIds.add(layer.id);
      if (_selectedLayer?.id == layer.id) {
        _selectedLayer = null;
      }
      _layers.removeWhere((l) => l.id == layer.id);
    });

    String labelText;
    switch (deletedLayer.type) {
      case LayerType.text:
        labelText = "Text removed";
        break;
      case LayerType.image:
        labelText = "Image removed";
        break;
      case LayerType.sticker:
        labelText = "Sticker removed";
        break;
      default:
        labelText = "Element removed";
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF1C1C1C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2F2F2F)),
        ),
        content: Text(
          labelText,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        action: SnackBarAction(
          label: "Undo",
          textColor: Colors.white,
          onPressed: () {
            if (mounted) {
              setState(() {
                if (deletedIndex >= 0 && deletedIndex <= _layers.length) {
                  _layers.insert(deletedIndex, deletedLayer);
                } else {
                  _layers.add(deletedLayer);
                }
                _deletingLayerIds.remove(deletedLayer.id);
                _selectedLayer = deletedLayer;
              });
            }
          },
        ),
      ),
    );
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

                      // Horizontal Equal-Width Action Buttons (14px spacing)
                      Row(
                        children: [
                          // Keep Editing (Primary White Button)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(dialogCtx, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Keep Editing",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Discard (Destructive Button)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogCtx, true),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF262626),
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Discard",
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _confirmDiscardDraft();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Fullscreen Canvas Viewport
            Positioned.fill(
              child: _buildMediaCanvas(),
            ),

            // Canvas Tap Handler (Deselects Layer)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _selectedLayer = null),
              ),
            ),

            // Gradient overlay for contrast
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Render Stack of Movable Canvas Layers
            ..._layers.map((layer) => _buildLayerWidget(layer)),

            // 3. Floating Quick Actions Toolbar for Selected Layer
            if (_selectedLayer != null) ...[
              _buildObjectToolbar(_selectedLayer!),
              if (_selectedLayer!.type == LayerType.text)
                _buildTikTokInlineTextToolbar(_selectedLayer!),
            ],

            // Top Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        onPressed: () async {
                          final shouldPop = await _confirmDiscardDraft();
                          if (shouldPop && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),

                      const Text(
                        "Preview Story",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      TextButton(
                        onPressed: _isPublishing ? null : _publishStory,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        child: Text(
                          "Post",
                          style: TextStyle(
                            color: _isPublishing ? Colors.white38 : AppColors.communityAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Preview & Edit Controls Overlay (Editing Pills + Caption Input + Action Bar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quick Editing Actions Toolbar (Change Photo, Rotate, Retake)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _replaceMedia,
                              icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 18),
                              label: const Text("Change Photo", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _rotateImage,
                              icon: const Icon(Icons.rotate_right_rounded, color: Colors.white, size: 18),
                              label: const Text("Rotate", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final shouldPop = await _confirmDiscardDraft();
                                if (shouldPop && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                              label: const Text("Retake", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Optional Caption Input Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceSecondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.darkBorderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, color: AppColors.darkTextMuted, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _captionController,
                                minLines: 1,
                                maxLines: 3,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: "Write something about your story...",
                                  hintStyle: TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Bottom Action Buttons (Retake & Post Story)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final shouldPop = await _confirmDiscardDraft();
                                if (shouldPop && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                "Retake",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isPublishing ? null : _publishStory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                disabledBackgroundColor: Colors.white24,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                    ],
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
