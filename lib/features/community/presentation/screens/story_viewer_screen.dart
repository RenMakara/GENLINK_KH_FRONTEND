import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import 'package:genlink_frontend/features/profile/presentation/utils/profile_navigation.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/images/app_cached_image.dart';
import '../../../chat/presentation/bindings/chat_binding.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../../chat/presentation/screens/chat_detail_screen.dart';
import '../../../../shared/utils/current_user.dart';
import '../../domain/models/story_model.dart';
import '../../domain/repositories/story_repository.dart';
import '../../data/repositories/story_repository_impl.dart';
import '../controllers/story_controller.dart';
import '../widgets/story_template_canvas.dart';
import '../widgets/story_interactive_like_button.dart';
import '../widgets/demo_stories_data.dart';
import 'package:video_player/video_player.dart';
import '../widgets/story_video_player_widget.dart';

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

void _showCompactReplyToast(
  BuildContext context,
  String recipientName,
  String recipientAvatar,
) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
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
  State<_CompactReplyToastWidget> createState() =>
      _CompactReplyToastWidgetState();
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
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.40), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E1E)
                : AppColors.lightSurfacePrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : AppColors.lightBorderSubtle,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAvatar(imageUrl: widget.recipientAvatar, size: 22),
              const SizedBox(width: 8),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Reply sent ",
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "to ${widget.recipientName}",
                    style: TextStyle(
                      color: isDark
                          ? Colors.white60
                          : AppColors.lightTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 11,
                ),
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
  final int initialStoryIndex;

  const StoryViewerScreen({
    super.key,
    required this.initialGroupIndex,
    required this.groups,
    this.initialStoryIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late int _currentGroupIdx;
  int _currentStoryIdx = 0;

  final GlobalKey _storyContentKey = GlobalKey();

  late AnimationController _progressAnimController;
  VideoPlayerController? _activeVideoController;
  bool _isPaused = false;
  bool _isClosing = false;

  final TextEditingController _replyController = TextEditingController();

  bool _isMorePressed = false;
  DateTime? _lastLikeTapTime;
  Timer? _viewersRefreshTimer;

  StoryGroupModel? get _currentGroup {
    if (_currentGroupIdx < 0 || _currentGroupIdx >= widget.groups.length) {
      return null;
    }
    return widget.groups[_currentGroupIdx];
  }

  StoryItemModel? get _currentStory {
    final group = _currentGroup;
    if (group == null ||
        _currentStoryIdx < 0 ||
        _currentStoryIdx >= group.stories.length) {
      return null;
    }
    return group.stories[_currentStoryIdx];
  }

  bool get _isOwnStory {
    final group = _currentGroup;
    if (group == null) return false;
    final currentUserId = CurrentUser.id;
    if (currentUserId.isNotEmpty) {
      if (group.userId.isNotEmpty && group.userId == currentUserId) {
        return true;
      }
    }
    return group.isOwner;
  }

  Future<void> _loadViewersForCurrentStory() async {
    final story = _currentStory;
    if (story == null || !_isOwnStory) return;
    if (story.id.startsWith('demo_')) return;

    final storyRepo = Get.isRegistered<StoryRepository>()
        ? Get.find<StoryRepository>()
        : StoryRepositoryImpl();

    final viewerFuture = storyRepo.getStoryViewers(story.id);
    // The owner screen is often opened from an already-loaded story tray. Refresh
    // the story response as well so a reaction made by a friend is reflected in
    // the insights count without requiring the tray to be rebuilt first.
    final latestStoryFuture = storyRepo is StoryRepositoryImpl
        ? storyRepo.getStoryById(story.id)
        : Future<StoryItemModel?>.value(null);

    try {
      final results = await Future.wait<dynamic>([
        viewerFuture,
        latestStoryFuture,
      ]);
      final viewers = results[0] as List<StoryViewerModel>;
      final latestStory = results[1] as StoryItemModel?;
      if (mounted && _currentStory?.id == story.id) {
        final latestLikesCount = latestStory?.likesCount;
        final latestLiked = latestStory?.isLiked;
        if (story.viewersCount != viewers.length ||
            (latestLikesCount != null &&
                story.likesCount != latestLikesCount) ||
            (latestLiked != null && story.isLiked != latestLiked)) {
          setState(() {
            story.viewersCount = viewers.length;
            if (latestLikesCount != null) story.likesCount = latestLikesCount;
            if (latestLiked != null) story.isLiked = latestLiked;
          });
        }
      }
    } catch (e) {
      debugPrint('[StoryViewer] Error loading viewers: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _currentGroupIdx = widget.initialGroupIndex.clamp(
      0,
      widget.groups.isEmpty ? 0 : widget.groups.length - 1,
    );
    final initialGroup = _currentGroup;
    final maxStoryIdx =
        (initialGroup != null && initialGroup.stories.isNotEmpty)
        ? initialGroup.stories.length - 1
        : 0;
    _currentStoryIdx = widget.initialStoryIndex.clamp(0, maxStoryIdx);

    _progressAnimController = AnimationController(vsync: this);
    _progressAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          mounted &&
          !_isPaused &&
          !_isClosing) {
        _nextStory();
      }
    });

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
    _viewersRefreshTimer?.cancel();
    _progressAnimController.stop();
    _progressAnimController.dispose();
    _activeVideoController?.pause();
    _activeVideoController = null;
    _replyController.dispose();
    super.dispose();
  }

  void _markCurrentStoryViewed() {
    final story = _currentStory;
    if (story != null) {
      story.isViewed = true;
      if (story.id.startsWith('demo_')) {
        markDemoStoryViewed(story.id);
      } else if (Get.isRegistered<StoryController>()) {
        final ctrl = Get.find<StoryController>();
        ctrl.markStoryAsViewed(story.id);
        ctrl.markStoryViewed(story.id);
      }
    }
  }

  void _closeViewer() {
    if (_isClosing) return;
    _isClosing = true;
    _viewersRefreshTimer?.cancel();
    _markCurrentStoryViewed();
    _progressAnimController.stop();
    _activeVideoController?.pause();
    _activeVideoController = null;
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
    if (story.type == StoryType.video ||
        (story.mediaUrl != null && _isVideoFile(story.mediaUrl!))) {
      return const Duration(seconds: 10);
    }
    return const Duration(seconds: 6);
  }

  void _startStoryTimer() {
    _progressAnimController.stop();
    final story = _currentStory;
    _markCurrentStoryViewed();

    _viewersRefreshTimer?.cancel();
    if (_isOwnStory && story != null && !story.id.startsWith('demo_')) {
      _loadViewersForCurrentStory();
      _viewersRefreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted && !_isClosing && _isOwnStory) {
          _loadViewersForCurrentStory();
        }
      });
    }

    final isVideo =
        story != null &&
        (story.type == StoryType.video ||
            (story.mediaUrl != null && _isVideoFile(story.mediaUrl!)));

    if (isVideo) {
      _progressAnimController.reset();
      if (_activeVideoController != null &&
          _activeVideoController!.value.isInitialized) {
        final dur = _activeVideoController!.value.duration;
        _progressAnimController.duration = dur > Duration.zero
            ? dur
            : const Duration(seconds: 10);
        if (!_isPaused && !_isClosing) {
          _progressAnimController.forward();
        }
      }
    } else {
      final duration = _calculateStoryDuration(story);
      _progressAnimController.duration = duration;
      _progressAnimController.reset();
      if (!_isPaused && !_isClosing) {
        _progressAnimController.forward();
      }
    }
  }

  void _onVideoControllerInitialized(
    VideoPlayerController ctrl,
    StoryItemModel story,
  ) {
    if (!mounted || _isClosing) return;
    if (_currentStory?.id != story.id) return;

    _activeVideoController = ctrl;
    final dur = ctrl.value.duration;
    final storyDuration = (dur > Duration.zero)
        ? dur
        : const Duration(seconds: 10);
    _progressAnimController.duration = storyDuration;
    _progressAnimController.reset();
    if (!_isPaused && !_isClosing) {
      _progressAnimController.forward();
    }
    debugPrint(
      '[StoryViewerScreen] Video initialized for story ${story.id}: duration=${ctrl.value.duration}, size=${ctrl.value.size}',
    );
  }

  void _onVideoPlaybackError(String err, StoryItemModel story) {
    debugPrint(
      '[StoryViewerScreen] Video playback error for story ${story.id}: $err',
    );
    if (!mounted || _isClosing) return;
    if (_currentStory?.id != story.id) return;
    _progressAnimController.stop();
  }

  void _pauseStory() {
    setState(() => _isPaused = true);
    _progressAnimController.stop();
    _activeVideoController?.pause();
  }

  void _resumeStory() {
    setState(() => _isPaused = false);
    if (!_isClosing && mounted) {
      _activeVideoController?.play();
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
    _activeVideoController?.pause();
    _activeVideoController = null;
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
    _activeVideoController?.pause();
    _activeVideoController = null;
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

  Future<void> _toggleLike(StoryItemModel story) async {
    debugPrint(
      '[StoryViewer] Like button tapped | '
      'Story ID: ${story.id} | '
      'Story owner ID: ${_currentGroup?.userId} | '
      'Current user ID: ${CurrentUser.id} | '
      'Current liked state: ${story.isLiked}',
    );

    if (!story.allowReactions) {
      AppNotificationBanner.showInfo(
        context: context,
        title: "Reactions Disabled",
        message: "The author has disabled reactions for this story.",
      );
      return;
    }

    if (_isOwnStory) {
      debugPrint('[StoryViewer] Blocked reaction: User owns this story.');
      return;
    }

    final now = DateTime.now();
    if (_lastLikeTapTime != null &&
        now.difference(_lastLikeTapTime!).inMilliseconds < 120) {
      debugPrint('[StoryViewer] Ignored reaction: within 120ms jitter window.');
      return;
    }
    _lastLikeTapTime = now;

    final previousLiked = story.isLiked;
    final previousLikesCount = story.likesCount;
    final targetLiked = !story.isLiked;
    final targetLikesCount = story.likesCount + (targetLiked ? 1 : -1);

    debugPrint(
      '[StoryViewer] Reaction triggered immediately | '
      'Story ID: ${story.id} | '
      'Target liked state: $targetLiked',
    );

    story.isLiked = targetLiked;
    story.likesCount = targetLikesCount;
    if (mounted) setState(() {});

    debugPrint(
      '[StoryViewer] Reaction state updated | '
      'New liked state: ${story.isLiked} | '
      'New likes count: ${story.likesCount}',
    );

    final isDemo =
        story.id.startsWith('demo_') ||
        (_currentGroup?.userId.startsWith('demo_') ?? false);
    if (isDemo) {
      updateDemoStoryLike(story.id, targetLiked, targetLikesCount);
      return;
    }

    if (Get.isRegistered<StoryController>()) {
      final ctrl = Get.find<StoryController>();
      try {
        await ctrl.syncLikeToBackend(story.id, isLiked: story.isLiked);
        debugPrint(
          '[StoryViewer] API response status: SUCCESS for story: ${story.id}',
        );
      } catch (e) {
        debugPrint(
          '[StoryViewer] API response status: FAILED ($e). Rolling back liked state.',
        );
        if (mounted) {
          story.isLiked = previousLiked;
          story.likesCount = previousLikesCount;
          setState(() {});
          AppNotificationBanner.showDanger(
            context: context,
            title: "Error",
            message: "Failed to update like status.",
          );
        }
        return;
      }
    }
  }

  void _triggerDoubleTapLike() {
    final story = _currentStory;
    if (story == null || !story.allowReactions) return;

    if (_isOwnStory) return;

    if (!story.isLiked) {
      HapticFeedback.lightImpact();
      _toggleLike(story);
    }
  }

  Widget _buildStoryReplyThumbnail(StoryItemModel story, [bool isDark = true]) {
    const double thumbSize = 38.0;
    final mediaUrl = story.mediaUrl;
    final isVideo = mediaUrl != null && _isVideoFile(mediaUrl);
    final borderColor = isDark ? Colors.white24 : AppColors.lightBorderSubtle;

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
          border: Border.all(color: borderColor, width: 1.0),
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

    if (isVideo) {
      return Container(
        width: thumbSize,
        height: thumbSize,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.lightBgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.movie_rounded,
              color: isDark ? Colors.white38 : AppColors.lightTextMuted,
              size: 18,
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ],
        ),
      );
    }

    Widget imageContent;
    if (mediaUrl.startsWith('assets/')) {
      imageContent = Image.asset(
        mediaUrl,
        width: thumbSize,
        height: thumbSize,
        fit: BoxFit.cover,
      );
    } else if (mediaUrl.startsWith('http://') ||
        mediaUrl.startsWith('https://')) {
      imageContent = AppCachedImage(
        imageUrl: mediaUrl,
        width: thumbSize,
        height: thumbSize,
        fit: BoxFit.cover,
        memCacheWidth: (thumbSize * 2).round(),
        memCacheHeight: (thumbSize * 2).round(),
        errorWidget: Icon(
          Icons.image_not_supported_rounded,
          color: isDark ? Colors.white54 : AppColors.lightTextMuted,
          size: 16,
        ),
      );
    } else {
      final file = _resolveFile(mediaUrl);
      if (file.existsSync()) {
        imageContent = Image.file(
          file,
          width: thumbSize,
          height: thumbSize,
          fit: BoxFit.cover,
        );
      } else {
        imageContent = AppCachedImage(
          imageUrl: mediaUrl,
          width: thumbSize,
          height: thumbSize,
          fit: BoxFit.cover,
          memCacheWidth: (thumbSize * 2).round(),
          memCacheHeight: (thumbSize * 2).round(),
          errorWidget: Icon(
            Icons.image_not_supported_rounded,
            color: isDark ? Colors.white54 : AppColors.lightTextMuted,
            size: 16,
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: thumbSize,
        height: thumbSize,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: imageContent,
      ),
    );
  }

  void _openStoryReplySheet(StoryGroupModel group, StoryItemModel story) {
    if (story.storyReplyPermission == StoryReplyPermission.off) {
      AppNotificationBanner.showInfo(
        context: context,
        title: "Replies Off",
        message: "The author has disabled replies for this story.",
      );
      return;
    }

    final replyTextController = TextEditingController();
    final inputFocusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF141414)
                  : AppColors.lightSurfacePrimary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : AppColors.lightBorderSubtle,
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
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
                      color: isDark
                          ? Colors.white24
                          : AppColors.lightBorderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Reply preview card header (clean single-layer container without BackdropFilter ghosting)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.lightBgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppColors.lightBorderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        imageUrl: group.userAvatar,
                        name: group.userName,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Replying to ${group.userName}'s Story",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              story.textContent != null &&
                                      story.textContent!.trim().isNotEmpty
                                  ? story.textContent!.trim()
                                  : (story.mediaUrl != null &&
                                            _isVideoFile(story.mediaUrl!)
                                        ? "Video Story"
                                        : "Photo Story"),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.lightTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStoryReplyThumbnail(story, isDark),
                    ],
                  ),
                ),

                if (story.allowReactions) ...[
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['❤️', '🔥', '😂', '😮', '😢', '👏'].map((emoji) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _sendStoryReaction(group, story, emoji);
                        },
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),

                StatefulBuilder(
                  builder: (context, setInputState) {
                    bool isSending = false;
                    bool isSuccess = false;
                    bool isPressed = false;
                    bool isFocused = false;

                    return StatefulBuilder(
                      builder: (context, setInnerState) {
                        final hasText = replyTextController.text
                            .trim()
                            .isNotEmpty;

                        return Focus(
                          onFocusChange: (focused) {
                            setInnerState(() => isFocused = focused);
                            if (focused) {
                              _pauseStory();
                            } else {
                              _resumeStory();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            height: 50,
                            padding: const EdgeInsets.only(left: 18, right: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (isFocused
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.white.withValues(alpha: 0.07))
                                  : (isFocused
                                        ? AppColors.lightSurfacePrimary
                                        : AppColors.lightBgSecondary),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isDark
                                    ? (isFocused
                                          ? Colors.white60
                                          : Colors.white.withValues(
                                              alpha: 0.16,
                                            ))
                                    : (isFocused
                                          ? AppColors.lightTextPrimary
                                          : AppColors.lightBorderStrong),
                                width: isFocused ? 1.4 : 1.0,
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
                                    cursorColor: isDark
                                        ? Colors.white
                                        : AppColors.lightTextPrimary,
                                    cursorWidth: 2.0,
                                    cursorRadius: const Radius.circular(2),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightTextPrimary,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    onChanged: (_) {
                                      setInnerState(() {});
                                    },
                                    onSubmitted: (text) async {
                                      if (text.trim().isNotEmpty &&
                                          !isSending &&
                                          !isSuccess) {
                                        setInnerState(() => isSending = true);
                                        await Future.delayed(
                                          const Duration(milliseconds: 160),
                                        );
                                        if (context.mounted) {
                                          setInnerState(() {
                                            isSending = false;
                                            isSuccess = true;
                                          });
                                        }
                                        await Future.delayed(
                                          const Duration(milliseconds: 220),
                                        );
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          _sendStoryReplyMessage(
                                            group,
                                            story,
                                            text.trim(),
                                          );
                                        }
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Send a message...",
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.lightTextMuted,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      contentPadding: EdgeInsets.zero,
                                      isCollapsed: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

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
                                          final text = replyTextController.text
                                              .trim();
                                          if (text.isNotEmpty) {
                                            setInnerState(
                                              () => isSending = true,
                                            );
                                            await Future.delayed(
                                              const Duration(milliseconds: 160),
                                            );
                                            if (context.mounted) {
                                              setInnerState(() {
                                                isSending = false;
                                                isSuccess = true;
                                              });
                                            }
                                            await Future.delayed(
                                              const Duration(milliseconds: 220),
                                            );
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx);
                                              _sendStoryReplyMessage(
                                                group,
                                                story,
                                                text,
                                              );
                                            }
                                          }
                                        }
                                      : null,
                                  child: AnimatedScale(
                                    scale: isPressed ? 0.93 : 1.0,
                                    duration: const Duration(milliseconds: 120),
                                    curve: Curves.easeOut,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeInOut,
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: isSuccess
                                            ? const Color(0xFF16A34A)
                                            : (hasText
                                                  ? (isDark
                                                        ? Colors.white
                                                        : AppColors
                                                              .lightTextPrimary)
                                                  : Colors.transparent),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          transitionBuilder: (child, anim) =>
                                              ScaleTransition(
                                                scale: anim,
                                                child: FadeTransition(
                                                  opacity: anim,
                                                  child: child,
                                                ),
                                              ),
                                          child: isSending
                                              ? SizedBox(
                                                  key: const ValueKey(
                                                    'loading',
                                                  ),
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: isDark
                                                            ? Colors.black
                                                            : Colors.white,
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
                                                  color: hasText
                                                      ? (isDark
                                                            ? Colors.black
                                                            : Colors.white)
                                                      : (isDark
                                                            ? Colors.white30
                                                            : AppColors
                                                                  .lightTextMuted),
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
        );
      },
    ).then((_) {
      replyTextController.dispose();
      inputFocusNode.dispose();
      _resumeStory();
    });
  }

  void _sendStoryReplyMessage(
    StoryGroupModel group,
    StoryItemModel story,
    String message,
  ) async {
    _pauseStory();

    try {
      if (!Get.isRegistered<ChatController>()) {
        ChatBinding().dependencies();
      }

      final chatController = Get.find<ChatController>();

      await chatController.sendStoryReply(
        userName: group.userName,
        userAvatar: group.userAvatar,
        message: message,
        mediaUrl: story.mediaUrl,
        storyId: story.id,
        userId: group.userId,
      );

      if (mounted) {
        _showCompactReplyToast(context, group.userName, group.userAvatar);
        await Get.to(() => const ChatDetailScreen());
        if (mounted) {
          _resumeStory();
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showDanger(
          context: context,
          title: "Failed to Send Reply",
          message:
              "Could not send message to ${group.userName}. Please try again.",
          icon: Icons.error_outline_rounded,
        );
        _resumeStory();
      }
    }
  }

  void _sendStoryReaction(
    StoryGroupModel group,
    StoryItemModel story,
    String emoji,
  ) {
    if (!story.allowReactions) {
      AppNotificationBanner.showInfo(
        context: context,
        title: "Reactions Disabled",
        message: "The author has disabled reactions for this story.",
      );
      return;
    }

    _triggerDoubleTapLike();

    AppNotificationBanner.showSuccess(
      context: context,
      title: "Reaction Sent",
      message: "Reacted $emoji to ${group.userName}'s story",
      icon: Icons.favorite_rounded,
    );
  }

  void _openCampusGroupSelectionSheet(
    StoryGroupModel group,
    StoryItemModel story,
  ) {
    _pauseStory();

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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                if (joinedGroups.isEmpty) ...[
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
                          child: const Icon(
                            Icons.groups_outlined,
                            color: Colors.white54,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "You haven't joined any campus groups yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            AppNotificationBanner.showSuccess(
                              context: context,
                              title: "Browse Groups",
                              message:
                                  "Explore campus groups in the Community tab!",
                              icon: Icons.explore_rounded,
                            );
                          },
                          icon: const Icon(Icons.explore_rounded, size: 18),
                          label: const Text(
                            "Browse Groups",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.40,
                    ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white38
                                      : Colors.white12,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.10,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.groups_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  "Default",
                                                  style: TextStyle(
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
                                          "${g.memberCount} members",
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white38,
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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedGroup != null
                            ? Colors.white
                            : Colors.white24,
                        foregroundColor: selectedGroup != null
                            ? Colors.black
                            : Colors.white38,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: selectedGroup != null ? 2 : 0,
                      ),
                      onPressed: selectedGroup == null
                          ? null
                          : () async {
                              final targetGroup = selectedGroup!;
                              Navigator.pop(ctx);

                              final confirmed =
                                  await GenLinkConfirmDialog.showConfirm(
                                    context: context,
                                    title: "Share Story?",
                                    message:
                                        "Share this story to ${targetGroup.name}?",
                                    confirmLabel: "Share",
                                    cancelLabel: "Cancel",
                                    icon: Icons.share_rounded,
                                  );

                              if (confirmed == true && mounted) {
                                AppNotificationBanner.showSuccess(
                                  context: this.context,
                                  title: "✓ Story Shared",
                                  message:
                                      "Story shared successfully to ${targetGroup.name}!",
                                  icon: Icons.check_circle_rounded,
                                );
                              }
                            },
                      child: const Text(
                        "Share Story",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _StoryMenuActionTile(
              icon: Icons.link_rounded,
              title: "Copy Story Link",
              subtitle: "Copy direct link to share anywhere",
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(
                  ClipboardData(text: "https://genlink.app/story/${story.id}"),
                );
                AppNotificationBanner.showSuccess(
                  context: context,
                  title: "Link Copied",
                  message: "Story link copied to clipboard!",
                  icon: Icons.copy_rounded,
                );
              },
            ),

            _StoryMenuActionTile(
              icon: Icons.groups_rounded,
              title: "Share to Campus Group",
              subtitle: "Select a group to post story preview",
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

  Future<void> _saveStoryToDevice() async {
    _pauseStory();
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        if (mounted) {
          AppNotificationBanner.showDanger(
            context: context,
            title: "Permission Denied",
            message: "Cannot save story without photo access.",
          );
        }
        _resumeStory();
        return;
      }

      if (mounted) {
        AppNotificationBanner.showInfo(
          context: context,
          title: "Saving...",
          message: "Saving story to device...",
          icon: Icons.downloading_rounded,
        );
      }

      final RenderRepaintBoundary? boundary =
          _storyContentKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _resumeStory();
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        _resumeStory();
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();
      final title =
          "genlink_story_${DateTime.now().millisecondsSinceEpoch}.png";

      await PhotoManager.editor.saveImage(pngBytes, filename: title);

      if (mounted) {
        AppNotificationBanner.showSuccess(
          context: context,
          title: "Story saved to your device.",
          message: "",
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotificationBanner.showDanger(
          context: context,
          title: "Couldn't save story.",
          message: "Please try again.",
        );
      }
    } finally {
      _resumeStory();
    }
  }

  void _showViewersSheet() {
    final story = _currentStory;
    if (story == null) return;

    _pauseStory();
    final storyRepo = Get.isRegistered<StoryRepository>()
        ? Get.find<StoryRepository>()
        : StoryRepositoryImpl();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.darkSurfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: FutureBuilder<List<StoryViewerModel>>(
          future: storyRepo.getStoryViewers(story.id),
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            if (snapshot.hasData && snapshot.data != null) {
              final loadedViewers = snapshot.data!;
              if (story.viewersCount != loadedViewers.length) {
                story.viewersCount = loadedViewers.length;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              }
            }

            final viewers = snapshot.data ?? story.viewers;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Story Insights",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              "${isLoading ? '...' : viewers.length} Viewers",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              "  •  ",
                              style: TextStyle(color: Colors.white38),
                            ),
                            const Icon(
                              Icons.favorite_rounded,
                              color: AppColors.likedAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${story.likesCount} Reactions",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (viewers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        "No insights available yet.",
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  )
                else
                  ...viewers.map(
                    (v) => ListTile(
                      leading: AppAvatar(
                        imageUrl: v.userAvatar,
                        name: v.userName,
                        size: 36,
                      ),
                      title: Text(
                        v.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        v.viewedTimeAgo,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ).then((_) => _resumeStory());
  }

  void _showPrivacySheet() {
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
                const Text(
                  "Story Privacy",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPrivacyOption(
              ctx: ctx,
              title: "Public",
              subtitle: "Anyone on GenLink can see this",
              icon: Icons.public,
              isSelected:
                  story.settings.visibility == StoryPrivacy.public ||
                  story.visibility == 'Public' ||
                  story.visibility.toUpperCase() == 'PUBLIC',
              onTap: () {
                Get.find<StoryController>().updateStoryPrivacy(
                  story.id,
                  "Public",
                );
                Navigator.pop(ctx);
              },
            ),
            _buildPrivacyOption(
              ctx: ctx,
              title: "Friends",
              subtitle: "Only your friends can see this",
              icon: Icons.group,
              isSelected:
                  story.settings.visibility == StoryPrivacy.friends ||
                  story.visibility == 'Friends' ||
                  story.visibility.toUpperCase() == 'FRIENDS',
              onTap: () {
                Get.find<StoryController>().updateStoryPrivacy(
                  story.id,
                  "Friends",
                );
                Navigator.pop(ctx);
              },
            ),
            _buildPrivacyOption(
              ctx: ctx,
              title: "Only Me",
              subtitle: "Only you can see this",
              icon: Icons.lock,
              isSelected:
                  story.settings.visibility == StoryPrivacy.onlyMe ||
                  story.visibility == 'Only Me' ||
                  story.visibility.toUpperCase() == 'ONLY_ME',
              onTap: () {
                Get.find<StoryController>().updateStoryPrivacy(
                  story.id,
                  "Only Me",
                );
                Navigator.pop(ctx);
              },
            ),
            _buildPrivacyOption(
              ctx: ctx,
              title: "Custom",
              subtitle: "Coming Soon",
              icon: Icons.settings,
              isSelected: false,
              onTap: null,
            ),
          ],
        ),
      ),
    ).then((_) {
      _resumeStory();
      if (mounted) setState(() {});
    });
  }

  Widget _buildPrivacyOption({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      enabled: onTap != null,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.communityAccent : Colors.white54,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? AppColors.communityAccent
              : (onTap == null ? Colors.white38 : Colors.white),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.communityAccent)
          : null,
    );
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
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
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? Colors.white : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            r,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AppNotificationBanner.showSuccess(
                        context: context,
                        title: "Report Submitted",
                        message:
                            "Thank you for keeping GenLink safe. We will review this story.",
                        icon: Icons.shield_rounded,
                      );
                    },
                    child: const Text(
                      "Submit Report",
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
    ).then((_) => _resumeStory());
  }

  Future<void> _openMuteConfirmationDialog(StoryGroupModel group) async {
    _pauseStory();
    final confirmed = await GenLinkConfirmDialog.showWarning(
      context: context,
      title: "Mute ${group.userName}?",
      message:
          "You will no longer see stories from ${group.userName}. You can unmute them anytime in settings.",
      confirmLabel: "Mute",
      cancelLabel: "Cancel",
      icon: Icons.volume_off_rounded,
    );

    if (confirmed == true && mounted) {
      AppNotificationBanner.showSuccess(
        context: context,
        title: "Stories Muted",
        message: "Muted stories from ${group.userName}",
        icon: Icons.volume_off_rounded,
      );
    }
    _resumeStory();
  }

  Future<void> _openBlockConfirmationDialog(StoryGroupModel group) async {
    _pauseStory();
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: "Block ${group.userName}?",
      message: "They won't be able to see your stories or posts.",
      confirmLabel: "Block",
      cancelLabel: "Cancel",
      icon: Icons.block_rounded,
    );

    if (confirmed == true && mounted) {
      _closeViewer();
      AppNotificationBanner.showSuccess(
        context: context,
        title: "User Blocked",
        message: "You will no longer see stories from ${group.userName}.",
        icon: Icons.block_rounded,
      );
    } else {
      _resumeStory();
    }
  }

  Future<void> _showDeleteStoryDialog(StoryItemModel story) async {
    _pauseStory();
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: "Delete Story?",
      message: "Are you sure you want to permanently delete this story?",
      confirmLabel: "Delete",
      cancelLabel: "Cancel",
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true && mounted) {
      final controller = Get.isRegistered<StoryController>()
          ? Get.find<StoryController>()
          : null;
      final success = await controller?.deleteStory(story.id) ?? true;
      if (success) {
        _closeViewer();
        final bannerCtx = Get.context ?? Get.overlayContext ?? context;
        if (bannerCtx.mounted) {
          AppNotificationBanner.showSuccess(
            context: bannerCtx,
            title: "Story deleted successfully.",
            message: "",
            icon: Icons.check_circle_rounded,
          );
        }
      } else {
        final bannerCtx = Get.context ?? Get.overlayContext ?? context;
        if (bannerCtx.mounted) {
          AppNotificationBanner.showDanger(
            context: bannerCtx,
            title: "Couldn't delete story. Please try again.",
            message: "",
          );
        }
        _resumeStory();
      }
    } else {
      _resumeStory();
    }
  }

  Future<void> _showMoreMenu() async {
    final group = _currentGroup;
    final story = _currentStory;
    if (group == null || story == null) return;

    _pauseStory();
    final action = await showModalBottomSheet<String>(
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
              BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      _isOwnStory ? "Manage Your Story" : "Story Options",
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

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: Column(
                    children: [
                      if (_isOwnStory) ...[
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.lock_outline_rounded,
                          title: "Story Privacy",
                          subtitle: "Who can see your story",
                          onTap: () {
                            Navigator.pop(ctx, 'privacy');
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.download_rounded,
                          title: "Save to Device",
                          subtitle:
                              "Save story photo/video to your phone gallery",
                          onTap: () {
                            Navigator.pop(ctx, 'save');
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.delete_outline,
                          title: "Delete Story",
                          subtitle: "Permanently remove this story",
                          isDanger: true,
                          onTap: () {
                            Navigator.pop(ctx, 'delete');
                          },
                        ),
                      ] else ...[
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.near_me_outlined,
                          title: "Share Story",
                          subtitle: "Share to Campus Group or friends",
                          onTap: () {
                            Navigator.pop(ctx, 'share');
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.link_rounded,
                          title: "Copy Story Link",
                          subtitle: "Copy direct link to share anywhere",
                          onTap: () {
                            Navigator.pop(ctx, 'copy_link');
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.flag_outlined,
                          title: "Report Story",
                          subtitle: "Report inappropriate content or spam",
                          onTap: () {
                            Navigator.pop(ctx, 'report');
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.volume_off_outlined,
                          title: "Mute Stories",
                          subtitle: "Stop seeing stories from this user",
                          onTap: () {
                            Navigator.pop(ctx, 'mute');
                          },
                        ),
                        _buildMenuOptionTile(
                          ctx: ctx,
                          icon: Icons.block_rounded,
                          title: "Block User",
                          subtitle: "Block this user from contacting you",
                          isDanger: true,
                          onTap: () {
                            Navigator.pop(ctx, 'block');
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
    );

    if (action == 'privacy') {
      _showPrivacySheet();
    } else if (action == 'save') {
      _saveStoryToDevice();
    } else if (action == 'delete') {
      await _showDeleteStoryDialog(story);
    } else if (action == 'share') {
      _openStoryShareSheet(group, story);
    } else if (action == 'copy_link') {
      Clipboard.setData(
        ClipboardData(text: "https://genlink.app/story/${story.id}"),
      );
      final bannerCtx = Get.context ?? Get.overlayContext ?? context;
      if (bannerCtx.mounted) {
        AppNotificationBanner.showSuccess(
          context: bannerCtx,
          title: "Link Copied",
          message: "Story link copied to clipboard!",
          icon: Icons.copy_rounded,
        );
      }
      _resumeStory();
    } else if (action == 'report') {
      _openReportStorySheet(group, story);
    } else if (action == 'mute') {
      _openMuteConfirmationDialog(group);
    } else if (action == 'block') {
      _openBlockConfirmationDialog(group);
    } else {
      _resumeStory();
    }
  }

  Widget _buildMenuOptionTile({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return _StoryMenuActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      isDanger: isDanger,
    );
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
              color: Colors.white38,
              size: 56,
            ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isVideoFile(String path) {
    final p = path.split('?').first.toLowerCase();
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

  Widget _buildUnifiedStoryPageContent(
    StoryItemModel story,
    StoryGroupModel group,
  ) {
    final isTemplate =
        story.templateId != null || story.type == StoryType.template;
    StoryTemplateConfig? matchedTemplate;
    if (isTemplate) {
      final tid = story.templateId ?? 'single_polaroid';
      for (final t in storyTemplatePresets) {
        if (t.id == tid) {
          matchedTemplate = t;
          break;
        }
      }
      matchedTemplate ??= storyTemplatePresets.first;
    }

    final demoStory = getDemoStoryById(story.id);

    // For text stories, the text is already baked into the story PNG image
    // (rendered by _renderCanvasToPng at publish time). Suppress LayerType.text
    // overlays so the text does not appear twice.
    final bool textBakedInImage =
        story.type == StoryType.text &&
        story.mediaUrl != null &&
        story.mediaUrl!.isNotEmpty;

    return Stack(
      children: [
        Positioned.fill(child: _buildMediaWidget(story, group)),
        if (isTemplate && matchedTemplate != null)
          Positioned.fill(
            child: StoryTemplateCanvas(
              template: matchedTemplate,
              slots: story.templateSlots,
              isInteractive: false,
              customText: story.textContent,
            ),
          ),
        if (demoStory != null)
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (demoStory.icon != null) ...[
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          demoStory.icon,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (demoStory.tag != null && demoStory.tag!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          demoStory.tag!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      demoStory.storyContent,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          ...story.layers
              .where(
                (layer) =>
                    layer.type != LayerType.mention &&
                    !(textBakedInImage && layer.type == LayerType.text),
              )
              .map((layer) => _buildViewerLayerWidget(layer)),
          if (!isTemplate &&
              !textBakedInImage &&
              story.layers.isEmpty &&
              story.textContent != null &&
              story.textContent!.trim().isNotEmpty)
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

    final isTemplate =
        story.templateId != null || story.type == StoryType.template;

    if (isTemplate || story.mediaUrl == null || story.mediaUrl!.isEmpty) {
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
    if (story.type == StoryType.video || _isVideoFile(url)) {
      mediaWidget = StoryVideoPlayerWidget(
        key: ValueKey("story_video_${story.id}"),
        videoUrl: url,
        isPlaying: !_isPaused,
        isLooping: false,
        fit: BoxFit.contain,
        showControls: true,
        onTap: () {
          if (_isPaused) {
            _resumeStory();
          } else {
            _pauseStory();
          }
        },
        onControllerInitialized: (ctrl) =>
            _onVideoControllerInitialized(ctrl, story),
        onVideoEnd: () {
          if (mounted && !_isClosing && _currentStory?.id == story.id) {
            _nextStory();
          }
        },
        onError: (err) => _onVideoPlaybackError(err, story),
      );
    } else if (url.startsWith('assets/')) {
      mediaWidget = Image.asset(
        url,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorMediaPlaceholder(),
      );
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      mediaWidget = AppCachedImage(
        imageUrl: url,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        placeholder: Container(
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
        ),
        errorWidget: _buildErrorMediaPlaceholder(),
      );
    } else {
      final localFile = _resolveFile(url);
      if (localFile.existsSync() ||
          url.startsWith('/') ||
          url.contains(':\\')) {
        mediaWidget = Image.file(
          localFile,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorMediaPlaceholder(),
        );
      } else {
        mediaWidget = AppCachedImage(
          imageUrl: url,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorWidget: _buildErrorMediaPlaceholder(),
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

  TextStyle _getViewerLayerTextStyle(
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
      case TextStyleType.elegant:
        style = FontStyle.italic;
        weight = FontWeight.w600;
        letterSpacing = 0.8;
        break;
      case TextStyleType.bold:
        weight = FontWeight.w900;
        letterSpacing = -0.3;
        break;
      case TextStyleType.modern:
        weight = FontWeight.w800;
        letterSpacing = 0.8;
        break;
      case TextStyleType.minimal:
        weight = FontWeight.w700;
        letterSpacing = 1.2;
        break;
      case TextStyleType.handwriting:
        weight = FontWeight.w500;
        style = FontStyle.italic;
        letterSpacing = 0.5;
        break;
      case TextStyleType.coding:
        weight = FontWeight.w600;
        fontFamily = 'monospace';
        letterSpacing = -0.2;
        break;
      default:
        weight = FontWeight.w700;
        break;
    }

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
        textShadows = null;
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

  Widget _buildViewerLayerWidget(MovableStoryLayer layer) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final maxCanvasWidth = screenWidth * 0.85;

    Widget content;

    switch (layer.type) {
      case LayerType.text:
        final hasBackground = layer.bgStyle != TextBgStyle.none;
        final baseStyle = _getViewerLayerTextStyle(
          layer.fontStyle,
          layer.color,
          layer.bgStyle,
          effect: layer.effect,
        ).copyWith(fontSize: layer.fontSize);

        final textLuminance = layer.color.computeLuminance();
        final filledBgColor =
            layer.bgColor ??
            (textLuminance > 0.45
                ? Colors.black.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.92));

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
          constraints: BoxConstraints(maxWidth: maxCanvasWidth * 0.9),
          child: IntrinsicWidth(
            child: hasBackground
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: layer.bgStyle == TextBgStyle.filled
                          ? filledBgColor
                          : (layer.bgStyle == TextBgStyle.rounded
                                ? (layer.bgColor?.withValues(alpha: 0.65) ??
                                      (textLuminance > 0.45
                                          ? Colors.black.withValues(alpha: 0.60)
                                          : Colors.white.withValues(
                                              alpha: 0.80,
                                            )))
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                      border: layer.bgStyle == TextBgStyle.outline
                          ? Border.all(
                              color:
                                  layer.bgColor ??
                                  layer.color.withValues(alpha: 0.85),
                              width: 1.8,
                            )
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.communityAccent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.communityAccent.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              layer.text,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                letterSpacing: -0.1,
                height: 1.25,
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

        final targetUsername = cleanMention.replaceAll('@', '').trim();

        content = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            if (targetUsername.isNotEmpty) {
              _pauseStory();
              await ProfileNavigation.open(username: targetUsername);
              _resumeStory();
            }
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCanvasWidth),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
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
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
                child: Text(cleanMention),
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
            curve: Curves.easeInOut,
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

      case LayerType.image:
        final localFile = _resolveFile(layer.text);
        Widget imgWidget;
        if (localFile.existsSync()) {
          imgWidget = Image.file(localFile, width: 180, fit: BoxFit.contain);
        } else if (layer.text.startsWith('assets/')) {
          imgWidget = Image.asset(layer.text, width: 180, fit: BoxFit.contain);
        } else {
          imgWidget = AppCachedImage(
            imageUrl: layer.text,
            width: 180,
            fit: BoxFit.contain,
            memCacheWidth: 360,
            errorWidget: const Icon(Icons.broken_image, color: Colors.white54),
          );
        }

        content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCanvasWidth),
          child: imgWidget,
        );
        break;
    }

    final currentPos = layer.getCanvasOffset(Size(screenWidth, screenHeight));

    return Positioned(
      key: ValueKey(layer.id),
      left: currentPos.dx,
      top: currentPos.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.scale(
          scale: layer.scale,
          child: Transform.rotate(angle: layer.rotation, child: content),
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
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        onDoubleTap: _triggerDoubleTapLike,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 250) {
            _closeViewer();
          }
        },
        child: RepaintBoundary(
          key: _storyContentKey,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 90),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: KeyedSubtree(
                    key: ValueKey("story_${story.id}"),
                    child: RepaintBoundary(
                      child: _buildUnifiedStoryPageContent(story, group),
                    ),
                  ),
                ),
              ),

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

              ...story.layers
                  .where((l) => l.type == LayerType.mention)
                  .map((layer) => _buildViewerLayerWidget(layer)),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _progressAnimController,
                          builder: (ctx, child) {
                            return Row(
                              children: List.generate(group.stories.length, (
                                idx,
                              ) {
                                double barProgress = 0.0;
                                if (idx < _currentStoryIdx) {
                                  barProgress = 1.0;
                                } else if (idx == _currentStoryIdx) {
                                  barProgress = _progressAnimController.value;
                                }
                                return Expanded(
                                  child: Container(
                                    height: 3,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: barProgress.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
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

                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                _pauseStory();
                                await ProfileNavigation.open(
                                  username: group.userName.replaceAll('@', ''),
                                  userId: group.userId,
                                );
                                _resumeStory();
                              },
                              child: AppAvatar(
                                imageUrl: group.userAvatar,
                                name: group.userName,
                                size: 36,
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
                                          group.isOwner
                                              ? "Your Story"
                                              : group.userName,
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
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        (story.settings.visibility ==
                                                    StoryPrivacy.onlyMe ||
                                                story.visibility == 'Only Me' ||
                                                story.visibility
                                                        .toUpperCase() ==
                                                    'ONLY_ME')
                                            ? Icons.lock_rounded
                                            : ((story.settings.visibility ==
                                                          StoryPrivacy
                                                              .friends ||
                                                      story.visibility ==
                                                          'Friends' ||
                                                      story.visibility
                                                              .toUpperCase() ==
                                                          'FRIENDS')
                                                  ? Icons.people_alt_rounded
                                                  : Icons.public_rounded),
                                        size: 12,
                                        color: Colors.white60,
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
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                onPressed: _showMoreMenu,
                              ),
                              const SizedBox(width: 4),
                            ],
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: _closeViewer,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 14,
                      right: 14,
                      bottom: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_isOwnStory) ...[
                          InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: _showViewersSheet,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${story.viewersCount}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: Colors.white24,
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: AppColors.likedAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${story.likesCount}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          if (story.storyReplyPermission !=
                              StoryReplyPermission.off)
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(21),
                                onTap: () => _openStoryReplySheet(group, story),
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(21),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.50,
                                        ),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Send a message...",
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.65,
                                            ),
                                            fontSize: 13,
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
                            )
                          else
                            const Spacer(),

                          if (story.allowReactions && !_isOwnStory) ...[
                            const SizedBox(width: 8),

                            StoryInteractiveLikeButton(
                              key: ValueKey('story_like_${story.id}'),
                              isLiked: story.isLiked,
                              likesCount: story.likesCount,
                              showCount: story.id.startsWith('demo_'),
                              onTap: () => _toggleLike(story),
                            ),
                          ],

                          const SizedBox(width: 8),

                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (_) =>
                                setState(() => _isMorePressed = true),
                            onTapUp: (_) =>
                                setState(() => _isMorePressed = false),
                            onTapCancel: () =>
                                setState(() => _isMorePressed = false),
                            onTap: _showMoreMenu,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              alignment: Alignment.center,
                              color: Colors.transparent,
                              child: AnimatedScale(
                                scale: _isMorePressed ? 0.90 : 1.0,
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOutCubic,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: _isMorePressed
                                        ? Colors.white.withValues(alpha: 0.16)
                                        : Colors.black.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
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
      ),
    );
  }
}

class _StoryMenuActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _StoryMenuActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  State<_StoryMenuActionTile> createState() => _StoryMenuActionTileState();
}

class _StoryMenuActionTileState extends State<_StoryMenuActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final titleColor = widget.isDanger ? AppColors.danger : Colors.white;
    final iconColor = widget.isDanger ? AppColors.danger : Colors.white;
    final iconBg = widget.isDanger
        ? AppColors.danger.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              color: _isPressed
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPressed
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.04),
                width: 0.8,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) {
                  if (mounted) setState(() => _isPressed = true);
                },
                onPointerUp: (_) {
                  if (mounted) setState(() => _isPressed = false);
                },
                onPointerCancel: (_) {
                  if (mounted) setState(() => _isPressed = false);
                },
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  minVerticalPadding: 8,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(widget.icon, color: iconColor, size: 19),
                    ),
                  ),
                  title: Text(
                    widget.title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.1,
                    ),
                  ),
                  subtitle: Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 11.5,
                      height: 1.2,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onTap();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
