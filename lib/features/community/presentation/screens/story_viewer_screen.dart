import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../domain/models/story_model.dart';
import '../controllers/story_controller.dart';

class StoryViewerScreen extends StatefulWidget {
  final int initialGroupIndex;
  final List<StoryGroupModel> groups;

  const StoryViewerScreen({
    super.key,
    required this.initialGroupIndex,
    required this.groups,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late int _currentGroupIdx;
  int _currentStoryIdx = 0;

  Timer? _storyTimer;
  double _progress = 0.0;
  bool _isPaused = false;
  bool _showHeartAnimation = false;
  bool _isClosing = false;

  final TextEditingController _replyController = TextEditingController();

  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;

  StoryGroupModel? get _currentGroup {
    if (_currentGroupIdx < 0 || _currentGroupIdx >= widget.groups.length) return null;
    return widget.groups[_currentGroupIdx];
  }

  StoryItemModel? get _currentStory {
    final group = _currentGroup;
    if (group == null || _currentStoryIdx < 0 || _currentStoryIdx >= group.stories.length) return null;
    return group.stories[_currentStoryIdx];
  }

  @override
  void initState() {
    super.initState();
    _currentGroupIdx = widget.initialGroupIndex.clamp(0, widget.groups.isEmpty ? 0 : widget.groups.length - 1);

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.elasticOut),
    );

    if (_currentGroup == null || _currentGroup!.stories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeViewer());
    } else {
      _startStoryTimer();
    }
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _storyTimer = null;
    _replyController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _closeViewer() {
    if (_isClosing) return;
    _isClosing = true;
    _storyTimer?.cancel();
    _storyTimer = null;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _startStoryTimer() {
    _storyTimer?.cancel();
    _progress = 0.0;
    const interval = Duration(milliseconds: 50);
    const totalDurationMs = 5000;

    _storyTimer = Timer.periodic(interval, (timer) {
      if (_isPaused || _isClosing) return;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += interval.inMilliseconds / totalDurationMs;
        if (_progress >= 1.0) {
          _nextStory();
        }
      });
    });
  }

  int _findNextGroupWithStories() {
    for (int i = _currentGroupIdx + 1; i < widget.groups.length; i++) {
      if (widget.groups[i].stories.isNotEmpty) {
        return i;
      }
    }
    return -1;
  }

  int _findPreviousGroupWithStories() {
    for (int i = _currentGroupIdx - 1; i >= 0; i--) {
      if (widget.groups[i].stories.isNotEmpty) {
        return i;
      }
    }
    return -1;
  }

  void _nextStory() {
    _storyTimer?.cancel();
    final group = _currentGroup;
    if (group == null) {
      _closeViewer();
      return;
    }

    if (_currentStoryIdx < group.stories.length - 1) {
      setState(() {
        _currentStoryIdx++;
      });
      _startStoryTimer();
    } else {
      final nextGroupIdx = _findNextGroupWithStories();
      if (nextGroupIdx != -1) {
        setState(() {
          _currentGroupIdx = nextGroupIdx;
          _currentStoryIdx = 0;
        });
        _startStoryTimer();
      } else {
        _closeViewer();
      }
    }
  }

  void _previousStory() {
    _storyTimer?.cancel();
    final group = _currentGroup;
    if (group == null) {
      _closeViewer();
      return;
    }

    if (_currentStoryIdx > 0) {
      setState(() {
        _currentStoryIdx--;
      });
      _startStoryTimer();
    } else {
      final prevGroupIdx = _findPreviousGroupWithStories();
      if (prevGroupIdx != -1) {
        setState(() {
          _currentGroupIdx = prevGroupIdx;
          _currentStoryIdx = widget.groups[prevGroupIdx].stories.length - 1;
        });
        _startStoryTimer();
      } else {
        _closeViewer();
      }
    }
  }

  void _triggerDoubleTapLike() {
    final story = _currentStory;
    if (story == null) return;

    setState(() {
      _showHeartAnimation = true;
    });
    _heartAnimController.forward().then((_) => _heartAnimController.reverse());

    final controller = Get.find<StoryController>();
    controller.toggleLike(story.id);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  String _formatReplyHint(String userName) {
    if (userName.length > 14) {
      final truncated = '${userName.substring(0, 11)}...';
      return 'Reply to $truncated';
    }
    return 'Reply to $userName...';
  }

  void _sendReply(String userName) {
    if (_replyController.text.trim().isNotEmpty) {
      final text = _replyController.text.trim();
      _replyController.clear();
      AppNotificationBanner.showSuccess(
        context: context,
        title: "Reply Sent",
        message: "Delivered to $userName: \"$text\"",
      );
    }
  }

  void _showViewersSheet() {
    final story = _currentStory;
    if (story == null) return;

    _isPaused = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.darkSurfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Story Viewers (${story.viewersCount})",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (story.viewers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text("No viewers yet.", style: TextStyle(color: Colors.white38)),
                ),
              )
            else
              ...story.viewers.map(
                (v) => ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(v.userAvatar)),
                  title: Text(v.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(v.viewedTimeAgo, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    ).then((_) {
      _isPaused = false;
    });
  }

  void _showMoreMenu() {
    final group = _currentGroup;
    final story = _currentStory;
    if (group == null || story == null) return;

    _isPaused = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.darkSurfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (group.isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text("Delete Story", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      title: const Text("Delete Story?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                      content: const Text("This story will be permanently deleted.", style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text("Cancel", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    final controller = Get.find<StoryController>();
                    controller.deleteStory(story.id);
                    _closeViewer();
                    AppNotificationBanner.showSuccess(
                      context: context,
                      title: "✓ Story Deleted",
                      message: "Your story has been permanently deleted.",
                      icon: Icons.check_circle_rounded,
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.white),
              title: const Text("Report Story", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.volume_off_outlined, color: Colors.white),
              title: const Text("Mute Stories", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    ).then((_) {
      _isPaused = false;
    });
  }

  Widget _buildErrorMediaPlaceholder() {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 56),
            const SizedBox(height: 12),
            const Text(
              "Unable to load story media",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Tap to Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.communityAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
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

  Widget _buildMediaWidget(StoryItemModel story, StoryGroupModel group) {
    Color gStartColor = const Color(0xFF0F172A);
    Color gEndColor = const Color(0xFF1E293B);

    if (story.bgGradientStart != null && story.bgGradientEnd != null) {
      try {
        gStartColor = Color(int.parse(story.bgGradientStart!));
        gEndColor = Color(int.parse(story.bgGradientEnd!));
      } catch (_) {}
    }

    if (story.mediaUrl == null || story.mediaUrl!.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gStartColor, gEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    final url = story.mediaUrl!;
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => _buildErrorMediaPlaceholder(),
      );
    }

    if (_isVideoFile(url)) {
      return Container(
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
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 2),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.movie_rounded, color: Colors.white70, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Video Story",
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final localFile = _resolveFile(url);
    if (localFile.existsSync() || url.startsWith('/') || url.contains(':\\') || url.contains(':/')) {
      return Image.file(
        localFile,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => _buildErrorMediaPlaceholder(),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.black,
          child: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: AppColors.communityAccent,
                strokeWidth: 2.5,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorMediaPlaceholder(),
    );
  }

  TextStyle _getViewerLayerTextStyle(TextStyleType fontStyle, Color color, TextBgStyle bgStyle) {
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

  Widget _buildViewerLayerWidget(MovableStoryLayer layer) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCanvasWidth = screenWidth * 0.75;

    Widget content;

    switch (layer.type) {
      case LayerType.text:
        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: layer.bgStyle == TextBgStyle.none
                    ? Colors.transparent
                    : (layer.bgColor ?? Colors.black.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                layer.text,
                softWrap: true,
                textAlign: layer.alignment,
                style: _getViewerLayerTextStyle(layer.fontStyle, layer.color, layer.bgStyle),
              ),
            ),
          ),
        );
        break;

      case LayerType.sticker:
        final isCatSticker = layer.text.contains('Cat') || layer.text.contains('Kittens') || layer.text.contains('Hugging') || layer.text.startsWith('assets/');
        if (isCatSticker) {
          content = Container(
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
          );
        } else {
          content = Container(
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
          );
        }
        break;

      case LayerType.hashtag:
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.communityAccent.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            layer.text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        );
        break;

      case LayerType.mention:
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            layer.text,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        );
        break;

      case LayerType.location:
        content = Container(
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
              Text(layer.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        );
        break;

      case LayerType.music:
        content = Container(
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
              Text(layer.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
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

    return Positioned(
      left: layer.offset.dx,
      top: layer.offset.dy,
      child: Transform.scale(
        scale: layer.scale,
        child: Transform.rotate(
          angle: layer.rotation,
          child: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = _currentGroup;
    final story = _currentStory;

    if (group == null || story == null || group.stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => setState(() => _isPaused = true),
        onLongPressEnd: (_) => setState(() => _isPaused = false),
        onDoubleTap: _triggerDoubleTapLike,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
            _closeViewer();
          }
        },
        child: Stack(
          children: [
            // Full Screen Story Media (BoxFit.cover)
            Positioned.fill(
              child: _buildMediaWidget(story, group),
            ),

            // Top Gradient Overlay for Header Readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Gradient Overlay for Reply Bar Readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 180,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Faithful Story Canvas Layers Overlay
            ...story.layers.map((layer) => _buildViewerLayerWidget(layer)),

            // Fallback Story Text Overlay (if no canvas layers exist)
            if (story.layers.isEmpty && story.textContent != null)
              Positioned(
                left: 28,
                right: 28,
                bottom: 120,
                child: Text(
                  story.textContent!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 16)],
                  ),
                ),
              ),

            // Left/Right Touch Gesture Detection Zones
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previousStory,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _nextStory,
                    ),
                  ),
                ],
              ),
            ),

            // Heart Reaction Double-Tap Animation
            if (_showHeartAnimation)
              Center(
                child: ScaleTransition(
                  scale: _heartScaleAnimation,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.danger,
                    size: 110,
                  ),
                ),
              ),

            // Top Header: Segmented Progress Bar & Clean User Avatar Header Row
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Segmented Progress Bar
                      Row(
                        children: List.generate(group.stories.length, (idx) {
                          double barProgress = 0.0;
                          if (idx < _currentStoryIdx) {
                            barProgress = 1.0;
                          } else if (idx == _currentStoryIdx) {
                            barProgress = _progress;
                          }
                          return Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: barProgress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),

                      // Clean Header Row (Avatar, User Name, Timestamp, Location, Menu, Close)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: group.userAvatar.startsWith('assets/')
                                ? AssetImage(group.userAvatar) as ImageProvider
                                : NetworkImage(group.userAvatar),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    group.userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    story.timeAgo,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (story.location != null)
                                Text(
                                  story.location!,
                                  style: const TextStyle(color: AppColors.communityAccent, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
                            onPressed: _showMoreMenu,
                          ),
                          IconButton(
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            icon: const Icon(Icons.close, color: Colors.white, size: 24),
                            onPressed: _closeViewer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Floating Bottom Action Bar: Modern Responsive Reply Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!group.isOwner) ...[
                        // Pill-Shaped Reply Input Field (~68% width)
                        Expanded(
                          flex: 7,
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextField(
                                controller: _replyController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendReply(group.userName),
                                decoration: InputDecoration(
                                  hintText: _formatReplyHint(group.userName),
                                  hintStyle: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Owner Viewers Pill
                        InkWell(
                          onTap: _showViewersSheet,
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "${story.viewersCount} Viewers",
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],

                      const SizedBox(width: 14),

                      // Circular ❤️ Like Icon Button (External, Vertically Centered)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            final controller = Get.find<StoryController>();
                            controller.toggleLike(story.id);
                            setState(() {});
                          },
                          icon: Icon(
                            story.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: story.isLiked ? AppColors.danger : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Circular ✈️ Send/Share Icon Button (External, Vertically Centered)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (!group.isOwner && _replyController.text.trim().isNotEmpty) {
                              _sendReply(group.userName);
                            } else {
                              AppNotificationBanner.showSuccess(
                                context: context,
                                title: "Share Story",
                                message: "Story link copied to clipboard!",
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.near_me_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
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
