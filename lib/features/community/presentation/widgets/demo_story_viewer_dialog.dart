import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_stories_data.dart';

class DemoStoryViewerDialog extends StatefulWidget {
  final DemoStoryModel story;

  const DemoStoryViewerDialog({super.key, required this.story});

  static void show(BuildContext context, DemoStoryModel story) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, anim, secAnim) =>
            DemoStoryViewerDialog(story: story),
        transitionsBuilder: (context, anim, secAnim, child) {
          final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          );
          final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  @override
  State<DemoStoryViewerDialog> createState() => _DemoStoryViewerDialogState();
}

class _DemoStoryViewerDialogState extends State<DemoStoryViewerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isLiked = false;
  int _likeCount = 12;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _onToggleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 200) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: story.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: topPadding + 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          minHeight: 2.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.28),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          backgroundImage: story.author.avatarUrl.startsWith('assets/')
                              ? AssetImage(story.author.avatarUrl) as ImageProvider
                              : NetworkImage(story.author.avatarUrl),
                          onBackgroundImageError: (_, _) {},
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              story.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              '${story.timeAgo}${story.location != null ? ' · ${story.location}' : ''}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                              story.icon,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

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
                              story.tag!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          Text(
                            story.content,
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
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Send a message...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      GestureDetector(
                        onTap: _onToggleLike,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: _isLiked
                                    ? const Color(0xFFF43F5E)
                                    : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_likeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
}
