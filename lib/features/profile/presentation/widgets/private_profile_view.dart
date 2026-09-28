import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';

// ============================================================================
// 1. SOFT 3D PRIVATE LOCK VECTOR ILLUSTRATION
// ============================================================================

/// Helper for drawing smooth 4-pointed golden sparkle.
void _drawGoldenSparkle(Canvas canvas, Offset center, double size, Color color) {
  final path = Path()
    ..moveTo(center.dx, center.dy - size)
    ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx + size, center.dy)
    ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx, center.dy + size)
    ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx - size, center.dy)
    ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx, center.dy - size)
    ..close();

  // Subtle outer warm glow
  canvas.drawCircle(
    center,
    size * 0.9,
    Paint()
      ..color = color.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );

  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.fill,
  );
  // White diamond center highlight
  canvas.drawCircle(center, size * 0.28, Paint()..color = Colors.white);
}

/// A delightful Modern Soft 3D Padlock illustration matching GenLink KH's
/// gamified 3D design language (soft claymorphic textures, glowing blue
/// shackle, floating pink user bubble, and golden sparkles).
class Soft3DPrivateLockWidget extends StatefulWidget {
  const Soft3DPrivateLockWidget({super.key, this.size = 210});

  final double size;

  @override
  State<Soft3DPrivateLockWidget> createState() =>
      _Soft3DPrivateLockWidgetState();
}

class _Soft3DPrivateLockWidgetState extends State<Soft3DPrivateLockWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _Soft3DPrivateLockPainter(isDark: isDark),
            ),
          ),
        );
      },
    );
  }
}

class _Soft3DPrivateLockPainter extends CustomPainter {
  const _Soft3DPrivateLockPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 1: Pastel Ambient Organic Blob in Background
    // ─────────────────────────────────────────────────────────────────────────
    final blobPath = Path()
      ..moveTo(w * 0.30, h * 0.22)
      ..cubicTo(w * 0.50, h * 0.16, w * 0.76, h * 0.18, w * 0.84, h * 0.32)
      ..cubicTo(w * 0.92, h * 0.44, w * 0.88, h * 0.64, w * 0.74, h * 0.70)
      ..cubicTo(w * 0.58, h * 0.76, w * 0.42, h * 0.68, w * 0.24, h * 0.62)
      ..cubicTo(w * 0.12, h * 0.56, w * 0.14, h * 0.38, w * 0.22, h * 0.28)
      ..close();

    final blobPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF1E3A8A).withValues(alpha: 0.22),
                const Color(0xFF3B82F6).withValues(alpha: 0.12),
              ]
            : [
                const Color(0xFFE0ECFF),
                const Color(0xFFEEF2FF),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(blobPath, blobPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 2: Floating Soft Blue Bubble (bottom-left)
    // ─────────────────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(w * 0.16, h * 0.44),
      w * 0.024,
      Paint()
        ..color = isDark
            ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
            : const Color(0xFF93C5FD).withValues(alpha: 0.70),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 3: Contact Surface Shadow beneath Lock
    // ─────────────────────────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.90),
        width: w * 0.58,
        height: h * 0.10,
      ),
      Paint()
        ..color = isDark
            ? Colors.black.withValues(alpha: 0.45)
            : const Color(0xFF2563EB).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 4: Lock Shackle (Glossy Cobalt U-Arc)
    // ─────────────────────────────────────────────────────────────────────────
    final shackleRadius = w * 0.155;
    final shackleCenterY = h * 0.39;
    final shackleStroke = w * 0.095;
    final bodyTop = h * 0.44;

    // Shackle path: loops over and enters body
    final shacklePath = Path()
      ..moveTo(cx - shackleRadius, bodyTop + h * 0.05)
      ..lineTo(cx - shackleRadius, shackleCenterY)
      ..arcToPoint(
        Offset(cx + shackleRadius, shackleCenterY),
        radius: Radius.circular(shackleRadius),
        clockwise: true,
      )
      ..lineTo(cx + shackleRadius, bodyTop + h * 0.05);

    // Shackle deep ambient shadow
    canvas.drawPath(
      shacklePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shackleStroke
        ..strokeCap = StrokeCap.round
        ..color = isDark
            ? Colors.black.withValues(alpha: 0.5)
            : const Color(0xFF1D4ED8).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Shackle vibrant blue body
    final shacklePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shackleStroke
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF60A5FA), // bright sky blue highlight
          Color(0xFF2563EB), // vibrant cobalt
          Color(0xFF1D4ED8), // deep rich royal blue
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(cx, shackleCenterY),
          radius: shackleRadius + shackleStroke,
        ),
      );
    canvas.drawPath(shacklePath, shacklePaint);

    // Shackle inner tubular glossy highlight
    final highlightPath = Path()
      ..moveTo(cx - shackleRadius * 0.96, shackleCenterY)
      ..arcToPoint(
        Offset(cx + shackleRadius * 0.30, shackleCenterY - shackleRadius * 0.88),
        radius: Radius.circular(shackleRadius),
        clockwise: true,
      );
    canvas.drawPath(
      highlightPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = shackleStroke * 0.24
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.65),
    );

    // Radiant blue accent ticks (top right of shackle, like in screenshot)
    final sparkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2563EB);

    // Spark 1 (near 1 o'clock)
    canvas.drawLine(
      Offset(cx + w * 0.08, h * 0.16),
      Offset(cx + w * 0.09, h * 0.12),
      sparkPaint,
    );
    // Spark 2 (near 2 o'clock)
    canvas.drawLine(
      Offset(cx + w * 0.23, h * 0.22),
      Offset(cx + w * 0.28, h * 0.19),
      sparkPaint,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 5: 3D Padlock Body (Rounded Porcelain Squircle)
    // ─────────────────────────────────────────────────────────────────────────
    final bodyW = w * 0.54;
    final bodyH = h * 0.43;
    final bodyCenterY = h * 0.63;
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, bodyCenterY),
      width: bodyW,
      height: bodyH,
    );
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(w * 0.12),
    );

    // Ambient body drop shadow
    canvas.drawRRect(
      bodyRRect.shift(Offset(0, h * 0.045)),
      Paint()
        ..color = isDark
            ? Colors.black.withValues(alpha: 0.55)
            : const Color(0xFF1E3A8A).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Body fill with soft claymorphic gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF334155),
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ]
            : const [
                Color(0xFFFFFFFF),
                Color(0xFFF8FAFC),
                Color(0xFFEFF6FF),
                Color(0xFFDBEAFE),
              ],
        stops: isDark ? const [0.0, 0.5, 1.0] : const [0.0, 0.35, 0.70, 1.0],
      ).createShader(bodyRect);
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Subtle 3D rim highlight border
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.25),
                const Color(0xFF64748B).withValues(alpha: 0.20),
              ]
            : [
                Colors.white,
                const Color(0xFFBFDBFE).withValues(alpha: 0.55),
              ],
      ).createShader(bodyRect);
    canvas.drawRRect(bodyRRect, rimPaint);

    // Top surface specular sheen
    final sheenRect = Rect.fromLTWH(
      bodyRect.left + bodyW * 0.08,
      bodyRect.top + 4,
      bodyW * 0.84,
      bodyH * 0.26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheenRect, Radius.circular(w * 0.08)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.12 : 0.70),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(sheenRect),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 6: Keyhole
    // ─────────────────────────────────────────────────────────────────────────
    final keyholeCenterY = bodyCenterY;
    final circleRadius = w * 0.038;

    final keyholePath = Path();
    // Top circle
    keyholePath.addOval(
      Rect.fromCircle(
        center: Offset(cx, keyholeCenterY - circleRadius * 0.3),
        radius: circleRadius,
      ),
    );
    // Lower trapezoid/stem with rounded bottom
    final stemTop = keyholeCenterY + circleRadius * 0.3;
    final stemBottom = keyholeCenterY + circleRadius * 2.1;
    final stemPath = Path()
      ..moveTo(cx - circleRadius * 0.52, stemTop)
      ..lineTo(cx + circleRadius * 0.52, stemTop)
      ..lineTo(cx + circleRadius * 0.82, stemBottom)
      ..arcToPoint(
        Offset(cx - circleRadius * 0.82, stemBottom),
        radius: Radius.circular(circleRadius * 0.82),
        clockwise: true,
      )
      ..close();
    keyholePath.addPath(stemPath, Offset.zero);

    final keyholeColor = isDark
        ? const Color(0xFF020617)
        : const Color(0xFF1E293B);

    canvas.drawPath(
      keyholePath,
      Paint()
        ..color = keyholeColor
        ..style = PaintingStyle.fill,
    );

    // Keyhole top-left inner depth shadow
    canvas.drawCircle(
      Offset(cx - 0.8, keyholeCenterY - circleRadius * 0.4),
      circleRadius * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withValues(alpha: 0.35),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 7: Floating Pink User Avatar Badge (Top-Left)
    // ─────────────────────────────────────────────────────────────────────────
    final avatarCenter = Offset(w * 0.28, h * 0.28);
    final avatarRadius = w * 0.092;

    // Soft drop shadow
    canvas.drawCircle(
      avatarCenter.translate(0, 4),
      avatarRadius,
      Paint()
        ..color = isDark
            ? Colors.black.withValues(alpha: 0.45)
            : const Color(0xFFFB7185).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Bubble Fill
    final bubblePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF831843), Color(0xFF9D174D)]
            : const [Color(0xFFFFF1F2), Color(0xFFFCE7F3)],
      ).createShader(Rect.fromCircle(center: avatarCenter, radius: avatarRadius));
    canvas.drawCircle(avatarCenter, avatarRadius, bubblePaint);

    // Bubble Border
    canvas.drawCircle(
      avatarCenter,
      avatarRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = isDark ? const Color(0xFFF472B6) : const Color(0xFFFDA4AF),
    );

    // User Outline Icon inside bubble
    final iconColor = isDark ? const Color(0xFFFCE7F3) : const Color(0xFFE11D48);
    final iconStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = iconColor;

    // Head circle
    canvas.drawCircle(
      Offset(avatarCenter.dx, avatarCenter.dy - avatarRadius * 0.24),
      avatarRadius * 0.26,
      iconStrokePaint,
    );

    // Shoulder arch
    final shoulderPath = Path()
      ..moveTo(
        avatarCenter.dx - avatarRadius * 0.46,
        avatarCenter.dy + avatarRadius * 0.50,
      )
      ..cubicTo(
        avatarCenter.dx - avatarRadius * 0.36,
        avatarCenter.dy + avatarRadius * 0.16,
        avatarCenter.dx + avatarRadius * 0.36,
        avatarCenter.dy + avatarRadius * 0.16,
        avatarCenter.dx + avatarRadius * 0.46,
        avatarCenter.dy + avatarRadius * 0.50,
      );
    canvas.drawPath(shoulderPath, iconStrokePaint);

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 8: Golden 4-Pointed Sparkle (Right Side)
    // ─────────────────────────────────────────────────────────────────────────
    _drawGoldenSparkle(
      canvas,
      Offset(w * 0.84, h * 0.42),
      w * 0.082,
      const Color(0xFFFBBF24),
    );
  }

  @override
  bool shouldRepaint(covariant _Soft3DPrivateLockPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ============================================================================
// 2. PRIVATE PROFILE VIEW
// ============================================================================

/// Redesigned private profile view matching the reference design:
/// - Centered soft 3D floating padlock illustration
/// - Bold, high-contrast headline: "This profile is private"
/// - Informative subtitle identifying the user by name
/// - Prominent vibrant blue "Got it" action button
class PrivateProfileView extends StatelessWidget {
  const PrivateProfileView({
    super.key,
    required this.displayName,
    this.isFriendsOnly = false,
    this.onGotIt,
  });

  /// The display name or handle of the user whose profile is private.
  final String displayName;

  /// True if this profile is visible to friends only.
  final bool isFriendsOnly;

  /// Optional override for the "Got it" button tap.
  final VoidCallback? onGotIt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    final targetName = displayName.trim().isNotEmpty
        ? displayName.trim()
        : 'profile.thisUser'.tr;

    final noticeText = isFriendsOnly
        ? 'profile.privateFriendsOnlyNotice'.trParams({'name': targetName})
        : 'profile.privateProfileNotice'.trParams({'name': targetName});

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D Soft Padlock Vector Illustration
              const Soft3DPrivateLockWidget(size: 210),

              const SizedBox(height: 32),

              // Headline: "This profile is private"
              Text(
                'profile.thisProfileIsPrivate'.tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.4,
                      color: semantic.primaryText,
                    ) ??
                    TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.4,
                      color: semantic.primaryText,
                    ),
              ),

              const SizedBox(height: 14),

              // Subtitle: "[Name] has chosen to keep their profile open..."
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  noticeText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15.5,
                        height: 1.45,
                        color: semantic.secondaryText,
                        fontWeight: FontWeight.w400,
                      ) ??
                      TextStyle(
                        fontSize: 15.5,
                        height: 1.45,
                        color: semantic.secondaryText,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ),

              const SizedBox(height: 32),

              // Action button: "Got it"
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3D2563EB),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: onGotIt ??
                        () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Get.back();
                          }
                        },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F6FEB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'profile.gotIt'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
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
}
