import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../../../chat/presentation/bindings/chat_binding.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../domain/models/story_model.dart';
import '../controllers/story_controller.dart';

class _CampusGroupItem {
  final String id;
  final String name;
  final int memberCount;
  final bool isDefault;

  const _CampusGroupItem({
    required this.id,
    required this.name,
    required this.memberCount,
    this.isDefault = false,
  });
}

void _showCompactReplyToast(BuildContext context, String recipientName, String recipientAvatar) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 14,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: _CompactReplyToastWidget(
              recipientName: recipientName,
              recipientAvatar: recipientAvatar,
              onDismiss: () {
                entry.remove();
              },
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
}

class _CompactReplyToastWidget extends StatefulWidget {
  final String recipientName;
  final String recipientAvatar;
  final VoidCallback onDismiss;

  const _CompactReplyToastWidget({
    required this.recipientName,
    required this.recipientAvatar,
    required this.onDismiss,
  });

  @override
  State<_CompactReplyToastWidget> createState() => _CompactReplyToastWidgetState();
}

class _CompactReplyToastWidgetState extends State<_CompactReplyToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.40),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();

    _dismissTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _animController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small Recipient Avatar
              CircleAvatar(
                radius: 11,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                backgroundImage: widget.recipientAvatar.isNotEmpty
                    ? (widget.recipientAvatar.startsWith('assets/')
                        ? AssetImage(widget.recipientAvatar) as ImageProvider
                        : NetworkImage(widget.recipientAvatar))
                    : null,
                child: widget.recipientAvatar.isEmpty
                    ? const Icon(Icons.person_rounded, color: Colors.white70, size: 12)
                    : null,
              ),
              const SizedBox(width: 8),

              // Text: "Reply sent to [Recipient Name]"
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Reply sent ",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "to ${widget.recipientName}",
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Small Green Checkmark Badge Icon
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _StoryViewerScreenState extends State<StoryViewerScreen> with TickerProviderStateMixin {
  late int _currentGroupIdx;
  int _currentStoryIdx = 0;

  late AnimationController _progressAnimController;
  bool _isPaused = false;
  bool _showHeartAnimation = false;
  bool _isClosing = false;

  final TextEditingController _replyController = TextEditingController();

  late AnimationController _likeBtnAnimController;
  late Animation<double> _likeBtnScaleAnim;

  late AnimationController _floatingHeartAnimController;
  late Animation<double> _floatingHeartScaleAnim;
  late Animation<double> _floatingHeartOpacityAnim;
  late Animation<Offset> _floatingHeartTranslateAnim;

  bool _isMorePressed = false;
  bool _isLikeDebouncing = false;

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

    _progressAnimController = AnimationController(vsync: this);
    _progressAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_isPaused && !_isClosing) {
        _nextStory();
      }
    });

    // Dedicated 335ms sequence animation for Like/Unlike icon button (Scale + Upward Translation + Rotation)
    _likeBtnAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    // Modern TikTok / IG Spring Scale Pop: 1.00 -> 0.80 -> 1.28 -> 1.00
    _likeBtnScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.00, end: 0.80).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.80, end: 1.28).chain(CurveTween(curve: const Cubic(0.175, 0.885, 0.32, 1.275))),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.28, end: 1.00).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
    ]).animate(_likeBtnAnimController);

    // Floating Canvas Feedback Heart Animation (Instagram / Facebook Style: Rises & Fades Out over 730ms)
    _floatingHeartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 730),
    );

    _floatingHeartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.4, end: 1.15).chain(CurveTween(curve: Curves.fastOutSlowIn)), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 65),
    ]).animate(_floatingHeartAnimController);

    _floatingHeartOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 75),
    ]).animate(_floatingHeartAnimController);

    _floatingHeartTranslateAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -36.0),
    ).animate(CurvedAnimation(
      parent: _floatingHeartAnimController,
      curve: Curves.easeOutCubic,
    ));

    if (_currentGroup == null || _currentGroup!.stories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeViewer());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isClosing) {
          _startStoryTimer();
        }
      });
    }
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    _replyController.dispose();
    _likeBtnAnimController.dispose();
    _floatingHeartAnimController.dispose();
    super.dispose();
  }

  void _markCurrentStoryViewed() {
    final story = _currentStory;
    if (story != null) {
      story.isViewed = true;
      if (Get.isRegistered<StoryController>()) {
        Get.find<StoryController>().markStoryAsViewed(story.id);
      }
    }
  }

  void _closeViewer() {
    if (_isClosing) return;
    _isClosing = true;
    _markCurrentStoryViewed();
    _progressAnimController.stop();
    Get.back();
  }

  Duration _calculateStoryDuration(StoryItemModel? story) {
    if (story == null) return const Duration(seconds: 6);
    if (story.layers.isNotEmpty) {
      final textLength = story.layers
          .where((l) => l.type == LayerType.text)
          .fold<int>(0, (sum, l) => sum + l.text.length);
      if (textLength > 60) return const Duration(seconds: 9);
      if (textLength > 20) return const Duration(seconds: 7);
      return const Duration(seconds: 6);
    }
    if (story.textContent != null && story.textContent!.trim().length > 60) {
      return const Duration(seconds: 9);
    }
    if (story.textContent != null && story.textContent!.trim().isNotEmpty) {
      return const Duration(seconds: 7);
    }
    if (story.mediaUrl != null && _isVideoFile(story.mediaUrl!)) {
      return const Duration(seconds: 10);
    }
    return const Duration(seconds: 6);
  }

  void _startStoryTimer() {
    _progressAnimController.stop();
    final story = _currentStory;
    _markCurrentStoryViewed();
    final duration = _calculateStoryDuration(story);
    _progressAnimController.duration = duration;
    _progressAnimController.reset();
    if (!_isPaused && !_isClosing) {
      _progressAnimController.forward();
    }
  }

  void _pauseStory() {
    setState(() => _isPaused = true);
    _progressAnimController.stop();
  }

  void _resumeStory() {
    setState(() => _isPaused = false);
    if (!_isClosing && mounted) {
      _progressAnimController.forward();
    }
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
    _progressAnimController.stop();
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
    _progressAnimController.stop();
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

  void _toggleLike(StoryItemModel story) {
    // Debounce: prevent rapid duplicate like/unlike requests
    if (_isLikeDebouncing) return;
    _isLikeDebouncing = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      _isLikeDebouncing = false;
    });

    // Always toggle local state first (optimistic UI)
    setState(() {
      story.isLiked = !story.isLiked;
      story.likesCount += story.isLiked ? 1 : -1;
    });

    // Sync with backend via controller (controller also toggles its internal
    // copy — harmless since it may be the same object reference)
    if (Get.isRegistered<StoryController>()) {
      // The controller's toggleLike finds the story by ID and toggles it.
      // If widget.groups shares object refs with controller.storyGroups,
      // the story was already toggled above, so the controller finds the
      // updated value and toggles it BACK — cancel that out by calling
      // the repository directly instead.
      final ctrl = Get.find<StoryController>();
      ctrl.syncLikeToBackend(story.id);
    }

    _likeBtnAnimController.forward(from: 0.0);
    if (story.isLiked) {
      setState(() => _showHeartAnimation = true);
      _floatingHeartAnimController.forward(from: 0.0).then((_) {
        if (mounted) setState(() => _showHeartAnimation = false);
      });
    }
  }

  void _triggerDoubleTapLike() {
    final story = _currentStory;
    if (story == null) return;
    _toggleLike(story);
  }

  Widget _buildStoryReplyThumbnail(StoryItemModel story) {
    const double thumbSize = 38.0;
    final mediaUrl = story.mediaUrl;
    final isVideo = mediaUrl != null && _isVideoFile(mediaUrl);

    // 1. Text Story Thumbnail (Gradient / Solid color + "Aa")
    if (mediaUrl == null || mediaUrl.trim().isEmpty) {
      Color bgStart = const Color(0xFF1E293B);
      Color bgEnd = const Color(0xFF0F172A);
      if (story.bgGradientStart != null && story.bgGradientEnd != null) {
        try {
          bgStart = Color(int.parse(story.bgGradientStart!));
          bgEnd = Color(int.parse(story.bgGradientEnd!));
        } catch (_) {}
      }
      return Container(
        width: thumbSize,
        height: thumbSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgEnd],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24, width: 1.0),
        ),
        child: const Center(
          child: Text(
            "Aa",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // 2. Video Story Thumbnail (Dark container + Play Icon overlay)
    if (isVideo) {
      return Container(
        width: thumbSize,
        height: thumbSize,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24, width: 1.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.movie_rounded, color: Colors.white38, size: 18),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 13),
            ),
          ],
        ),
      );
    }

    // 3. Image Story Thumbnail
    Widget imageContent;
    if (mediaUrl.startsWith('assets/')) {
      imageContent = Image.asset(mediaUrl, width: thumbSize, height: thumbSize, fit: BoxFit.cover);
    } else if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
      imageContent = Image.network(
        mediaUrl,
        width: thumbSize,
        height: thumbSize,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 16),
      );
    } else {
      final file = _resolveFile(mediaUrl);
      if (file.existsSync()) {
        imageContent = Image.file(file, width: thumbSize, height: thumbSize, fit: BoxFit.cover);
      } else {
        imageContent = Image.network(
          mediaUrl,
          width: thumbSize,
          height: thumbSize,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 16),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: thumbSize,
        height: thumbSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 1.0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: imageContent,
      ),
    );
  }

  void _openStoryReplySheet(StoryGroupModel group, StoryItemModel story) {
    _pauseStory();
    final replyTextController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Story Reference Preview Header Card (Smooth Fade-in Animation & Reduced Height)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                builder: (context, opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      // Real User Avatar / Fallback Placeholder
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        backgroundImage: group.userAvatar.isNotEmpty
                            ? (group.userAvatar.startsWith('assets/')
                                ? AssetImage(group.userAvatar) as ImageProvider
                                : NetworkImage(group.userAvatar))
                            : null,
                        child: group.userAvatar.isEmpty
                            ? const Icon(Icons.person_rounded, color: Colors.white70, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Replying to ${group.userName}'s Story",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              story.textContent != null && story.textContent!.trim().isNotEmpty
                                  ? story.textContent!.trim()
                                  : (story.mediaUrl != null && _isVideoFile(story.mediaUrl!)
                                      ? "Video Story"
                                      : "Photo Story"),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Informative Story Thumbnail Preview
                      _buildStoryReplyThumbnail(story),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Quick Emoji Reaction Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['❤️', '🔥', '😂', '😮', '😢', '👏'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendStoryReaction(group, story, emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Premium Production-Grade Story Reply Input (Focus Animation, Press Scale Compression, Paper Plane Icon)
              StatefulBuilder(
                builder: (context, setInputState) {
                  bool isSending = false;
                  bool isSuccess = false;
                  bool isPressed = false;
                  bool isFocused = false;
                  final FocusNode inputFocusNode = FocusNode();

                  return StatefulBuilder(
                    builder: (context, setInnerState) {
                      final hasText = replyTextController.text.trim().isNotEmpty;

                      return Focus(
                        onFocusChange: (focused) {
                          setInnerState(() => isFocused = focused);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          height: 50,
                          padding: const EdgeInsets.only(left: 18, right: 5),
                          decoration: BoxDecoration(
                            color: isFocused
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isFocused
                                  ? Colors.white38
                                  : Colors.white.withValues(alpha: 0.14),
                              width: isFocused ? 1.2 : 1.0,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: replyTextController,
                                  focusNode: inputFocusNode,
                                  autofocus: true,
                                  textAlignVertical: TextAlignVertical.center,
                                  cursorColor: Colors.white,
                                  cursorWidth: 2.0,
                                  cursorRadius: const Radius.circular(2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onChanged: (_) {
                                    setInnerState(() {});
                                  },
                                  onSubmitted: (text) async {
                                    if (text.trim().isNotEmpty && !isSending && !isSuccess) {
                                      setInnerState(() => isSending = true);
                                      await Future.delayed(const Duration(milliseconds: 160));
                                      if (context.mounted) {
                                        setInnerState(() {
                                          isSending = false;
                                          isSuccess = true;
                                        });
                                      }
                                      await Future.delayed(const Duration(milliseconds: 220));
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                        _sendStoryReplyMessage(group, story, text.trim());
                                      }
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    hintText: "Reply to story...",
                                    hintStyle: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Send Button (Size 34x34, Press Scale 0.93, Paper Plane Icon, Micro Interactions)
                              GestureDetector(
                                onTapDown: (_) {
                                  if (hasText && !isSending && !isSuccess) {
                                    setInnerState(() => isPressed = true);
                                  }
                                },
                                onTapUp: (_) {
                                  if (isPressed) {
                                    setInnerState(() => isPressed = false);
                                  }
                                },
                                onTapCancel: () {
                                  if (isPressed) {
                                    setInnerState(() => isPressed = false);
                                  }
                                },
                                onTap: (hasText && !isSending && !isSuccess)
                                    ? () async {
                                        final text = replyTextController.text.trim();
                                        if (text.isNotEmpty) {
                                          setInnerState(() => isSending = true);
                                          await Future.delayed(const Duration(milliseconds: 160));
                                          if (context.mounted) {
                                            setInnerState(() {
                                              isSending = false;
                                              isSuccess = true;
                                            });
                                          }
                                          await Future.delayed(const Duration(milliseconds: 220));
                                          if (ctx.mounted) {
                                            Navigator.pop(ctx);
                                            _sendStoryReplyMessage(group, story, text);
                                          }
                                        }
                                      }
                                    : null,
                                child: AnimatedScale(
                                  scale: isPressed ? 0.93 : 1.0,
                                  duration: const Duration(milliseconds: 120),
                                  curve: Curves.easeOut,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeInOut,
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isSuccess
                                          ? const Color(0xFF16A34A)
                                          : (hasText ? Colors.white : Colors.transparent),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 180),
                                        transitionBuilder: (child, anim) => ScaleTransition(
                                          scale: anim,
                                          child: FadeTransition(opacity: anim, child: child),
                                        ),
                                        child: isSending
                                            ? const SizedBox(
                                                key: ValueKey('loading'),
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.black,
                                                ),
                                              )
                                            : isSuccess
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    key: ValueKey('success'),
                                                    color: Colors.white,
                                                    size: 18,
                                                  )
                                                : Icon(
                                                    Icons.send_rounded,
                                                    key: ValueKey<bool>(hasText),
                                                    color: hasText ? Colors.black : Colors.white30,
                                                    size: 16,
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
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _resumeStory());
  }

  void _sendStoryReplyMessage(StoryGroupModel group, StoryItemModel story, String message) async {
    try {
      if (!Get.isRegistered<ChatController>()) {
        ChatBinding().dependencies();
      }

      final chatController = Get.find<ChatController>();

      // Call ChatController's sendStoryReply pipeline which calls ChatRepositoryImpl & ChatRemoteDataSource
      await chatController.sendStoryReply(
        userName: group.userName,
        userAvatar: group.userAvatar,
        message: message,
        mediaUrl: story.mediaUrl,
      );

      // Show Compact Floating Toast Notification & Resume Story Playback
      if (mounted) {
        _showCompactReplyToast(context, group.userName, group.userAvatar);
        _resumeStory();
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showDanger(
          context: context,
          title: "Failed to Send Reply",
          message: "Could not send message to ${group.userName}. Please try again.",
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _sendStoryReaction(StoryGroupModel group, StoryItemModel story, String emoji) {
    _triggerDoubleTapLike();
    AppNotificationBanner.showSuccess(
      context: context,
      title: "Reaction Sent",
      message: "Reacted $emoji to ${group.userName}'s story",
      icon: Icons.favorite_rounded,
    );
  }

  void _openCampusGroupSelectionSheet(StoryGroupModel group, StoryItemModel story) {
    _pauseStory();

    // Mock joined campus groups list
    final List<_CampusGroupItem> joinedGroups = [
      const _CampusGroupItem(
        id: 'cg_1',
        name: 'CADT Computer Science & Tech',
        memberCount: 1420,
        isDefault: true,
      ),
      const _CampusGroupItem(
        id: 'cg_2',
        name: 'Flutter & Mobile App Developers',
        memberCount: 890,
        isDefault: false,
      ),
      const _CampusGroupItem(
        id: 'cg_3',
        name: 'AI & Data Science Community',
        memberCount: 650,
        isDefault: false,
      ),
    ];

    _CampusGroupItem? selectedGroup;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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
                    const Text(
                      "Share to Campus Group",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                if (joinedGroups.isEmpty) ...[
                  // ── Edge Case: User has not joined any campus groups ──
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_outlined, color: Colors.white54, size: 42),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "You haven't joined any campus groups yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            AppNotificationBanner.showSuccess(
                              context: context,
                              title: "Browse Groups",
                              message: "Explore campus groups in the Community tab!",
                              icon: Icons.explore_rounded,
                            );
                          },
                          icon: const Icon(Icons.explore_rounded, size: 18),
                          label: const Text("Browse Groups", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const Text(
                    "Select a campus group to post story preview:",
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // ── Scrollable List of Joined Campus Groups ──
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.40),
                    child: SingleChildScrollView(
                      child: Column(
                        children: joinedGroups.map((g) {
                          final isSelected = selectedGroup?.id == g.id;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedGroup = g;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? Colors.white38 : Colors.white12,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Group Avatar
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.10),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                g.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.5,
                                                ),
                                              ),
                                            ),
                                            if (g.isDefault) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  "Default",
                                                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${g.memberCount} members",
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Selection Indicator
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected ? Colors.white : Colors.white38,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Share Story Action Button (Enabled only when group is selected) ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedGroup != null ? Colors.white : Colors.white24,
                        foregroundColor: selectedGroup != null ? Colors.black : Colors.white38,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        elevation: selectedGroup != null ? 2 : 0,
                      ),
                      onPressed: selectedGroup == null
                          ? null
                          : () async {
                              final targetGroup = selectedGroup!;
                              Navigator.pop(ctx);

                              // ── Confirmation Dialog ──
                              final bool? confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  title: const Text(
                                    "Share Story?",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Share this story to:",
                                        style: TextStyle(color: Colors.white54, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        targetGroup.name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx, false),
                                      child: const Text("Cancel", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      ),
                                      onPressed: () => Navigator.pop(dialogCtx, true),
                                      child: const Text("Share", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true && mounted) {
                                AppNotificationBanner.showSuccess(
                                  context: this.context,
                                  title: "✓ Story Shared",
                                  message: "Story shared successfully to ${targetGroup.name}!",
                                  icon: Icons.check_circle_rounded,
                                );
                              }
                            },
                      child: const Text(
                        "Share Story",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ).then((_) => _resumeStory());
  }

  void _openStoryShareSheet(StoryGroupModel group, StoryItemModel story) {
    _pauseStory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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

            const Text(
              "Share Story",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 1. Copy Story Link
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 20),
              ),
              title: const Text("Copy Story Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Copy direct link to share anywhere", style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: "https://genlink.app/story/${story.id}"));
                AppNotificationBanner.showSuccess(
                  context: context,
                  title: "Link Copied",
                  message: "Story link copied to clipboard!",
                  icon: Icons.copy_rounded,
                );
              },
            ),

            // 2. Share to Campus Group
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
              ),
              title: const Text("Share to Campus Group", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Select a group to post story preview", style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _openCampusGroupSelectionSheet(group, story);
              },
            ),
          ],
        ),
      ),
    ).then((_) => _resumeStory());
  }

  void _showViewersSheet() {
    final story = _currentStory;
    if (story == null) return;

    _pauseStory();
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
    ).then((_) => _resumeStory());
  }

  void _openReportStorySheet(StoryGroupModel group, StoryItemModel story) {
    _pauseStory();
    String selectedReason = 'Spam';
    final reasons = [
      'Spam',
      'Harassment or Bullying',
      'Hate Speech',
      'Violence',
      'False Information',
      'Nudity or Sexual Content',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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
                    const Text(
                      "Report Story",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  "Please select a reason for reporting this story.",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 14),

                ...reasons.map((r) {
                  final isSelected = selectedReason == r;
                  return InkWell(
                    onTap: () {
                      setModalState(() => selectedReason = r);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? Colors.white : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            r,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AppNotificationBanner.showSuccess(
                        context: context,
                        title: "Report Submitted",
                        message: "Thank you for keeping GenLink safe. We will review this story.",
                        icon: Icons.shield_rounded,
                      );
                    },
                    child: const Text("Submit Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) => _resumeStory());
  }

  void _openMuteConfirmationDialog(StoryGroupModel group) {
    _pauseStory();
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text("Mute ${group.userName}?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text("You will no longer see stories from ${group.userName}. You can unmute them anytime in settings.", style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("Mute", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        AppNotificationBanner.showSuccess(
          context: context,
          title: "Stories Muted",
          message: "Muted stories from ${group.userName}",
          icon: Icons.volume_off_rounded,
        );
      }
      _resumeStory();
    });
  }

  void _showMoreMenu() {
    final group = _currentGroup;
    final story = _currentStory;
    if (group == null || story == null) return;

    _pauseStory();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sheet Header Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      group.isOwner ? "Manage Your Story" : "Story Options",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),

              // Scrollable Options List
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: Column(
                    children: [
                      if (group.isOwner) ...[
                        // ── MY STORY OPTIONS ──
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.edit_outlined,
                          title: "Edit Story",
                          subtitle: "Modify story text, layers, or background",
                          onTap: () {
                            AppNotificationBanner.showInfo(
                              context: context,
                              title: "Edit Story",
                              message: "Story editor ready for modifications.",
                              icon: Icons.edit_rounded,
                            );
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.lock_outline_rounded,
                          title: "Story Privacy",
                          subtitle: "Who can see your story (Public)",
                          onTap: () {
                            AppNotificationBanner.showInfo(
                              context: context,
                              title: "Story Privacy",
                              message: "Story visibility set to Public.",
                              icon: Icons.lock_outline_rounded,
                            );
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.bar_chart_rounded,
                          title: "Story Insights",
                          subtitle: "See viewers, likes, and story analytics",
                          onTap: () {
                            _showViewersSheet();
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.download_rounded,
                          title: "Save to Device",
                          subtitle: "Save story photo/video to phone gallery",
                          onTap: () {
                            AppNotificationBanner.showSuccess(
                              context: context,
                              title: "Story Saved",
                              message: "Story media saved to your device gallery!",
                              icon: Icons.download_done_rounded,
                            );
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.delete_outline,
                          title: "Delete Story",
                          subtitle: "Permanently remove this story",
                          isDanger: true,
                          onTap: () async {
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
                      ] else ...[
                        // ── OTHER USER'S STORY OPTIONS ──
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.near_me_outlined,
                          title: "Share Story",
                          subtitle: "Share to Campus Group or friends",
                          onTap: () {
                            _openStoryShareSheet(group, story);
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.link_rounded,
                          title: "Copy Story Link",
                          subtitle: "Copy direct link to share anywhere",
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: "https://genlink.app/story/${story.id}"));
                            AppNotificationBanner.showSuccess(
                              context: context,
                              title: "Link Copied",
                              message: "Story link copied to clipboard!",
                              icon: Icons.copy_rounded,
                            );
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.flag_outlined,
                          title: "Report Story",
                          subtitle: "Report inappropriate content or spam",
                          onTap: () {
                            _openReportStorySheet(group, story);
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.volume_off_outlined,
                          title: "Mute Stories",
                          subtitle: "Stop seeing stories from this user",
                          onTap: () {
                            _openMuteConfirmationDialog(group);
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.block_rounded,
                          title: "Block User",
                          subtitle: "Block this user from contacting you",
                          isDanger: true,
                          onTap: () async {
                            final bool? confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                title: Text("Block ${group.userName}?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                                content: const Text("They won't be able to see your stories or posts.", style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
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
                                    child: const Text("Block", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true && mounted) {
                              _closeViewer();
                              AppNotificationBanner.showSuccess(
                                context: context,
                                title: "User Blocked",
                                message: "You will no longer see stories from ${group.userName}.",
                                icon: Icons.block_rounded,
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _resumeStory());
  }

  Widget _buildMenuOptionTile({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final titleColor = isDanger ? AppColors.danger : Colors.white;
    final iconColor = isDanger ? AppColors.danger : Colors.white;
    final iconBg = isDanger
        ? AppColors.danger.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11.5,
          ),
        ),
        onTap: () {
          Navigator.pop(ctx);
          onTap();
        },
      ),
    );
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

  Widget _buildUnifiedStoryPageContent(StoryItemModel story, StoryGroupModel group) {
    return Stack(
      children: [
        Positioned.fill(child: _buildMediaWidget(story, group)),
        ...story.layers.map((layer) => _buildViewerLayerWidget(layer)),
        if (story.layers.isEmpty && story.textContent != null && story.textContent!.trim().isNotEmpty)
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
      ],
    );
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

    Widget mediaWidget;

    final url = story.mediaUrl!;
    if (url.startsWith('assets/')) {
      mediaWidget = Image.asset(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => _buildErrorMediaPlaceholder(),
      );
    } else if (_isVideoFile(url)) {
      mediaWidget = Container(
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
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      mediaWidget = Image.network(
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
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorMediaPlaceholder(),
      );
    } else {
      final localFile = _resolveFile(url);
      if (localFile.existsSync() || url.startsWith('/') || url.contains(':\\')) {
        mediaWidget = Image.file(
          localFile,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => _buildErrorMediaPlaceholder(),
        );
      } else {
        mediaWidget = Image.network(
          url,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => _buildErrorMediaPlaceholder(),
        );
      }
    }

    return Transform.translate(
      offset: story.bgOffset,
      child: Transform.scale(
        scale: story.bgScale,
        child: RotatedBox(
          quarterTurns: (story.bgRotation / 90).round() % 4,
          child: SizedBox.expand(child: mediaWidget),
        ),
      ),
    );
  }

  TextStyle _getViewerLayerTextStyle(TextStyleType fontStyle, Color color, TextBgStyle bgStyle) {
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

  Widget _buildViewerLayerWidget(MovableStoryLayer layer) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCanvasWidth = screenWidth * 0.85;

    Widget content;

    switch (layer.type) {
      case LayerType.text:
        final hasBackground = layer.bgStyle != TextBgStyle.none;
        final baseStyle = _getViewerLayerTextStyle(layer.fontStyle, layer.color, layer.bgStyle);

        final textLuminance = layer.color.computeLuminance();
        final filledBgColor = textLuminance > 0.45
            ? Colors.black.withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.92);

        Widget textWidget;

        if (layer.fontStyle == TextStyleType.modern && !hasBackground) {
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
                style: baseStyle.copyWith(shadows: null),
              ),
            ],
          );
        } else {
          textWidget = Text(
            layer.text,
            softWrap: true,
            textAlign: layer.alignment,
            style: baseStyle,
          );
        }

        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth * 0.9),
          child: IntrinsicWidth(
            child: hasBackground
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: layer.bgStyle == TextBgStyle.filled
                          ? filledBgColor
                          : (layer.bgStyle == TextBgStyle.rounded
                              ? (textLuminance > 0.45
                                  ? Colors.black.withValues(alpha: 0.60)
                                  : Colors.white.withValues(alpha: 0.80))
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                      border: layer.bgStyle == TextBgStyle.outline
                          ? Border.all(color: layer.color.withValues(alpha: 0.85), width: 1.8)
                          : null,
                    ),
                    child: textWidget,
                  )
                : textWidget,
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
                  child: Text(
                    cleanLocation,
                    style: TextStyle(
                      color: textColor,
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
          imgWidget = Image.file(localFile, width: 180, fit: BoxFit.cover);
        } else if (layer.text.startsWith('assets/')) {
          imgWidget = Image.asset(layer.text, width: 180, fit: BoxFit.cover);
        } else {
          imgWidget = Image.network(layer.text, width: 180, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white54));
        }

        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        onDoubleTap: _triggerDoubleTapLike,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
            _closeViewer();
          }
        },
        child: Stack(
          children: [
            // Full Screen Story Content with Ultra-Comfortable 90ms Anchored Pure Crossfade (Instagram / WhatsApp Comfort Standard)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 90),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey("story_${story.id}"),
                  child: _buildUnifiedStoryPageContent(story, group),
                ),
              ),
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

            // Floating Heart Feedback (rises & fades)
            if (_showHeartAnimation)
              Center(
                child: AnimatedBuilder(
                  animation: _floatingHeartAnimController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: _floatingHeartTranslateAnim.value,
                      child: Transform.scale(
                        scale: _floatingHeartScaleAnim.value,
                        child: Opacity(
                          opacity: _floatingHeartOpacityAnim.value.clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 52,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
                      AnimatedBuilder(
                        animation: _progressAnimController,
                        builder: (ctx, child) {
                          return Row(
                            children: List.generate(group.stories.length, (idx) {
                              double barProgress = 0.0;
                              if (idx < _currentStoryIdx) {
                                barProgress = 1.0;
                              } else if (idx == _currentStoryIdx) {
                                barProgress = _progressAnimController.value;
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
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Clean Header Row (Avatar, User Name, Timestamp, Location, Menu, Close)
                      Row(
                        children: [
                          Hero(
                            tag: 'story_avatar_${group.userId}',
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage: group.userAvatar.startsWith('assets/')
                                  ? AssetImage(group.userAvatar) as ImageProvider
                                  : NetworkImage(group.userAvatar),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        group.userName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                    style: const TextStyle(
                                      color: AppColors.communityAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (group.isOwner) ...[
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
                              onPressed: _showMoreMenu,
                            ),
                            const SizedBox(width: 4),
                          ],
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

            // Floating Bottom Action Bar: Conditional Owner vs Viewer Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (group.isOwner) ...[
                        // ── Owner Actions: Viewers Pill Button ──
                        InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: _showViewersSheet,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "${story.viewersCount} Viewers",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // ── Viewer Actions: Ultra-Lightweight Comment Capsule ──
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(19),
                            onTap: () => _openStoryReplySheet(group, story),
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.white.withValues(alpha: 0.50),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'community.writeCommentHint'.tr.length > 15
                                          ? "Comment..."
                                          : 'community.writeCommentHint'.tr,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.45),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // ── Monochrome Like Button ──
                        Semantics(
                          label: story.isLiked ? 'Unlike story' : 'Like story',
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleLike(story),
                            child: ScaleTransition(
                              scale: _likeBtnScaleAnim,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: story.isLiked
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: story.isLiked
                                        ? Colors.white.withValues(alpha: 0.30)
                                        : Colors.white.withValues(alpha: 0.12),
                                    width: 0.6,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    story.isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // More Menu Button (38x38)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => setState(() => _isMorePressed = true),
                          onTapUp: (_) => setState(() => _isMorePressed = false),
                          onTapCancel: () => setState(() => _isMorePressed = false),
                          onTap: _showMoreMenu,
                          child: AnimatedScale(
                            scale: _isMorePressed ? 0.90 : 1.0,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOutCubic,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _isMorePressed
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 0.6,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.more_horiz_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
