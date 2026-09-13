import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import '../../domain/models/community_models.dart';
import 'event_details_screen.dart';

class EventSuccessScreen extends StatefulWidget {
  final EventModel event;

  const EventSuccessScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventSuccessScreen> createState() => _EventSuccessScreenState();
}

class _EventSuccessScreenState extends State<EventSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _iconScaleAnim;
  late final Animation<double> _checkmarkAnim;
  late final Animation<double> _particlesAnim;
  late final Animation<double> _titleFadeAnim;
  late final Animation<Offset> _titleSlideAnim;
  late final Animation<double> _descFadeAnim;
  late final Animation<double> _cardFadeAnim;
  late final Animation<Offset> _cardSlideAnim;
  late final Animation<double> _buttonsFadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _iconScaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.38, curve: Curves.easeOutBack),
      ),
    );

    _checkmarkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.48, curve: Curves.easeOutCubic),
      ),
    );

    _particlesAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.72, curve: Curves.easeOut),
      ),
    );

    _titleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.66, curve: Curves.easeOutQuad),
      ),
    );
    _titleSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.66, curve: Curves.easeOutQuad),
      ),
    );

    _descFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.76, curve: Curves.easeOutQuad),
      ),
    );

    _cardFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.88, curve: Curves.easeOutQuad),
      ),
    );
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.88, curve: Curves.easeOutQuad),
      ),
    );

    _buttonsFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.82, 1.00, curve: Curves.easeOutQuad),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onViewEvent(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          event: widget.event,
          heroTag: 'success-event-${widget.event.id}',
        ),
      ),
    );
  }

  void _onDone(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgPrimary = theme.scaffoldBackgroundColor;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardBg = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final titleLabel = 'community.registrationSuccessful'.tr.isNotEmpty &&
            'community.registrationSuccessful'.tr != 'community.registrationSuccessful'
        ? 'community.registrationSuccessful'.tr
        : 'Registration Successful!';

    final subLabel = 'community.youAreRegisteredFor'.tr.isNotEmpty &&
            'community.youAreRegisteredFor'.tr != 'community.youAreRegisteredFor'
        ? 'community.youAreRegisteredFor'.tr
        : ("You're registered for:");

    final primaryBtnLabel = 'community.viewEvent'.tr.isNotEmpty &&
            'community.viewEvent'.tr != 'community.viewEvent'
        ? 'community.viewEvent'.tr
        : 'View Event';

    final secondaryBtnLabel = 'community.done'.tr.isNotEmpty &&
            'community.done'.tr != 'community.done'
        ? 'community.done'.tr
        : 'Done';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onDone(context);
        }
      },
      child: Scaffold(
        backgroundColor: bgPrimary,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // Checkmark animation
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_particlesAnim.value > 0.0)
                                CustomPaint(
                                  size: const Size(120, 120),
                                  painter: _CelebrationParticlesPainter(
                                    progress: _particlesAnim.value,
                                    isDark: isDark,
                                  ),
                                ),

                              Transform.scale(
                                scale: _iconScaleAnim.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success.withValues(
                                      alpha: isDark ? 0.16 : 0.12,
                                    ),
                                  ),
                                ),
                              ),

                              Transform.scale(
                                scale: _iconScaleAnim.value,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.success.withValues(
                                          alpha: isDark ? 0.35 : 0.22,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CustomPaint(
                                    size: const Size(64, 64),
                                    painter: _CheckmarkPainter(
                                      progress: _checkmarkAnim.value,
                                      color: Colors.white,
                                      strokeWidth: 3.6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Registration Successful!
                        FadeTransition(
                          opacity: _titleFadeAnim,
                          child: SlideTransition(
                            position: _titleSlideAnim,
                            child: Text(
                              titleLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // You're registered for:
                        FadeTransition(
                          opacity: _descFadeAnim,
                          child: Text(
                            subLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Event Summary Card [Event Title, date/time, mode/location]
                        FadeTransition(
                          opacity: _cardFadeAnim,
                          child: SlideTransition(
                            position: _cardSlideAnim,
                            child: _buildEventSummaryCard(
                              context: context,
                              isDark: isDark,
                              cardBg: cardBg,
                              borderSubtle: borderSubtle,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              textMuted: textMuted,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Action Buttons
                        FadeTransition(
                          opacity: _buttonsFadeAnim,
                          child: Column(
                            children: [
                              // Primary: [ View Event ]
                              // Black filled in Light Mode, GenLink dark theme in Dark Mode
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => _onViewEvent(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? AppColors.darkPrimary
                                        : Colors.black,
                                    foregroundColor: isDark
                                        ? AppColors.darkTextInverse
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    primaryBtnLabel,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkTextInverse
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Secondary: [ Done ]
                              // Outlined / minimal black / white button (no yellow, no gradients)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () => _onDone(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        isDark ? Colors.white : Colors.black87,
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black.withValues(alpha: 0.22),
                                      width: 1.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                  ),
                                  child: Text(
                                    secondaryBtnLabel,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventSummaryCard({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final isOnline = widget.event.eventType.toLowerCase().contains('online');
    final onlineLabel = 'community.onlineEvent'.tr.isNotEmpty &&
            'community.onlineEvent'.tr != 'community.onlineEvent'
        ? 'community.onlineEvent'.tr
        : 'Online Event';
    final inPersonLabel = 'community.inPerson'.tr.isNotEmpty &&
            'community.inPerson'.tr != 'community.inPerson'
        ? 'community.inPerson'.tr
        : 'In person';

    final String locationDisplay = isOnline
        ? '🌐 $onlineLabel'
        : '📍 ${widget.event.location.isNotEmpty ? widget.event.location : inPersonLabel}';

    final String dateDisplay = widget.event.timeString.isNotEmpty
        ? '📅 ${widget.event.dateString} · ${widget.event.timeString}'
        : (widget.event.dateString.isNotEmpty ? '📅 ${widget.event.dateString}' : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderSubtle, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 64,
              height: 64,
              child: _buildThumbnail(isDark, textMuted),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                if (dateDisplay.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    dateDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  locationDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(bool isDark, Color textMuted) {
    if (widget.event.coverImageFile != null) {
      return Image.file(
        widget.event.coverImageFile!,
        fit: BoxFit.cover,
      );
    }
    if (widget.event.imageUrl.isNotEmpty) {
      return Image.network(
        widget.event.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _placeholderThumbnail(isDark, textMuted),
      );
    }
    return _placeholderThumbnail(isDark, textMuted);
  }

  Widget _placeholderThumbnail(bool isDark, Color textMuted) {
    return Container(
      color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary,
      child: Center(
        child: Icon(
          Icons.event_outlined,
          color: textMuted,
          size: 28,
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final p1 = Offset(cx - 12, cy + 1);
    final p2 = Offset(cx - 4, cy + 9);
    final p3 = Offset(cx + 12, cy - 8);

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    const split = 0.35;
    if (progress <= split) {
      final t = progress / split;
      final cur = Offset.lerp(p1, p2, t)!;
      path.lineTo(cur.dx, cur.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (progress - split) / (1.0 - split);
      final cur = Offset.lerp(p2, p3, t)!;
      path.lineTo(cur.dx, cur.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _CelebrationParticlesPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _CelebrationParticlesPainter({
    required this.progress,
    required this.isDark,
  });

  static const List<_ParticleConfig> _configs = [
    _ParticleConfig(angle: 0.0, baseRadius: 42, maxOffset: 16, size: 3.5, type: 0, colorIdx: 0),
    _ParticleConfig(angle: 0.52, baseRadius: 44, maxOffset: 20, size: 4.0, type: 1, colorIdx: 1),
    _ParticleConfig(angle: 1.05, baseRadius: 40, maxOffset: 15, size: 3.0, type: 0, colorIdx: 2),
    _ParticleConfig(angle: 1.57, baseRadius: 43, maxOffset: 18, size: 4.5, type: 1, colorIdx: 0),
    _ParticleConfig(angle: 2.09, baseRadius: 41, maxOffset: 16, size: 3.2, type: 0, colorIdx: 1),
    _ParticleConfig(angle: 2.62, baseRadius: 44, maxOffset: 22, size: 4.0, type: 1, colorIdx: 2),
    _ParticleConfig(angle: 3.14, baseRadius: 42, maxOffset: 15, size: 3.5, type: 0, colorIdx: 0),
    _ParticleConfig(angle: 3.67, baseRadius: 43, maxOffset: 20, size: 4.2, type: 1, colorIdx: 1),
    _ParticleConfig(angle: 4.19, baseRadius: 40, maxOffset: 17, size: 3.0, type: 0, colorIdx: 2),
    _ParticleConfig(angle: 4.71, baseRadius: 44, maxOffset: 21, size: 4.5, type: 1, colorIdx: 0),
    _ParticleConfig(angle: 5.24, baseRadius: 41, maxOffset: 16, size: 3.2, type: 0, colorIdx: 1),
    _ParticleConfig(angle: 5.76, baseRadius: 43, maxOffset: 18, size: 3.8, type: 1, colorIdx: 2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    final colors = [
      AppColors.success.withValues(alpha: alpha * 0.9),
      AppColors.communityAccent.withValues(alpha: alpha * 0.85),
      AppColors.accentPremium.withValues(alpha: alpha * 0.8),
    ];

    final paint = Paint()..style = PaintingStyle.fill;

    for (final cfg in _configs) {
      final currentDist = cfg.baseRadius + (cfg.maxOffset * progress);
      final px = cx + (currentDist * math.cos(cfg.angle));
      final py = cy + (currentDist * math.sin(cfg.angle));
      paint.color = colors[cfg.colorIdx];

      if (cfg.type == 0) {
        final r = cfg.size * (1.0 - (progress * 0.35));
        canvas.drawCircle(Offset(px, py), r, paint);
      } else {
        final s = cfg.size * (1.0 - (progress * 0.3));
        final starPath = Path()
          ..moveTo(px, py - s)
          ..quadraticBezierTo(px, py, px + s, py)
          ..quadraticBezierTo(px, py, px, py + s)
          ..quadraticBezierTo(px, py, px - s, py)
          ..quadraticBezierTo(px, py, px, py - s)
          ..close();
        canvas.drawPath(starPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

class _ParticleConfig {
  final double angle;
  final double baseRadius;
  final double maxOffset;
  final double size;
  final int type;
  final int colorIdx;

  const _ParticleConfig({
    required this.angle,
    required this.baseRadius,
    required this.maxOffset,
    required this.size,
    required this.type,
    required this.colorIdx,
  });
}
