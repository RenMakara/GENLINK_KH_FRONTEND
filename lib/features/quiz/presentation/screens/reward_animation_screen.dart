import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';

class RewardAnimationScreen extends StatefulWidget {
  const RewardAnimationScreen({super.key});

  @override
  State<RewardAnimationScreen> createState() => _RewardAnimationScreenState();
}

class _RewardAnimationScreenState extends State<RewardAnimationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _sparkleController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  final _random = Random();
  late final List<_SparklePoint> _sparklePoints;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: const Interval(0, 0.3)),
    );

    _scaleController.forward();

    _sparklePoints = List.generate(
      30,
      (_) => _SparklePoint(
        x: _random.nextDouble(),
        baseY: _random.nextDouble(),
        radius: _random.nextDouble() * 3 + 1,
        opacity: 0.15 + _random.nextDouble() * 0.25,
        phaseOffset: _random.nextDouble() * 2 * pi,
      ),
    );

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Get.offAndToNamed('/quiz/reward-claimed');
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizController>();
    final result = controller.quizResult.value;

    return Scaffold(
      backgroundColor: QuizThemeColors.darkOverlay,
      body: Stack(
        children: [
          _buildSparkles(),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _scaleAnim,
                builder: (context, child) => Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTrophy(),
                        const SizedBox(height: 28),
                        if (result != null) ...[
                          _buildRewardCard(
                            'quiz.xpValue'.trParams({
                              'xp': '${result.xpEarned}',
                            }),
                            Icons.star,
                            QuizThemeColors.primary,
                          ),
                          const SizedBox(height: 14),
                          _buildRewardCard(
                            'quiz.coinsValue'.trParams({
                              'coins': '${result.coinsEarned}',
                            }),
                            Icons.monetization_on,
                            QuizThemeColors.gold,
                          ),
                        ],
                        const SizedBox(height: 32),
                        Text(
                          'quiz.rewardsEarned'.tr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: QuizThemeColors.rewardForeground,
                          ),
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
    );
  }

  Widget _buildTrophy() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC107).withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.emoji_events,
        color: QuizThemeColors.rewardForeground,
        size: 56,
      ),
    );
  }

  Widget _buildRewardCard(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: QuizThemeColors.rewardForeground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: QuizThemeColors.rewardForeground.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkles() {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SparklePainter(
            time: _sparkleController.value,
            points: _sparklePoints,
          ),
        );
      },
    );
  }
}

class _SparklePoint {
  final double x;
  final double baseY;
  final double radius;
  final double opacity;
  final double phaseOffset;

  const _SparklePoint({
    required this.x,
    required this.baseY,
    required this.radius,
    required this.opacity,
    required this.phaseOffset,
  });
}

class _SparklePainter extends CustomPainter {
  final double time;
  final List<_SparklePoint> points;

  _SparklePainter({required this.time, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in points) {
      final x = p.x * size.width;
      final y = (p.baseY * size.height) + sin(time * 2 + p.phaseOffset) * 20;
      paint.color = QuizThemeColors.rewardForeground.withValues(
        alpha: p.opacity,
      );
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.time != time;
}
