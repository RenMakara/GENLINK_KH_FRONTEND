import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';

class FindOpponentScreen extends GetView<QuizController> {
  const FindOpponentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: QuizColors.heading),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Find Opponent',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: QuizColors.heading),
        ),
      ),
      body: Column(
        children: [
          const Spacer(flex: 2),
          _buildRadarAnimation(),
          const Spacer(),
          _buildStatusText(),
          const SizedBox(height: 32),
          _buildCancelButton(),
          const SizedBox(height: 16),
          _buildTipCard(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRadarAnimation() {
    return Obx(() {
      return SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildPulsingCircle(180, 1.0),
            _buildPulsingCircle(144, 0.8),
            _buildPulsingCircle(108, 0.6),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: QuizColors.gradient,
                boxShadow: [
                  BoxShadow(color: Color(0x408B5CF6), blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            if (controller.opponentSearchProgress.value >= 1.0)
              _buildCheckingPulse(),
          ],
        ),
      );
    });
  }

  Widget _buildCheckingPulse() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QuizColors.correct, width: 3),
      ),
      child: const Center(
        child: Icon(Icons.check, color: QuizColors.correct, size: 28),
      ),
    );
  }

  Widget _buildPulsingCircle(double size, double opacity) {
    return Obx(() {
      final progress = controller.opponentSearchProgress.value;
      final scale = 0.8 + (sin(progress * pi * 4) * 0.1).abs();
      return AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        width: size * scale,
        height: size * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: QuizColors.primary.withOpacity(0.15 * opacity),
            width: 1.5,
          ),
          color: QuizColors.primary.withOpacity(0.04 * opacity),
        ),
      );
    });
  }

  Widget _buildStatusText() {
    return Obx(() {
      if (controller.opponentSearchProgress.value >= 1.0) {
        return Column(
          children: [
            const Text(
              'Opponent Found!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: QuizColors.correct),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparing match...',
              style: TextStyle(fontSize: 15, color: QuizColors.body.withOpacity(0.8)),
            ),
          ],
        );
      }
      return Column(
        children: [
          const Text(
            'Finding Opponent...',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: QuizColors.heading),
          ),
          const SizedBox(height: 8),
          Text(
            'Searching for players near your level',
            style: TextStyle(fontSize: 14, color: QuizColors.body.withOpacity(0.8)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Obx(() => LinearProgressIndicator(
                    value: controller.opponentSearchProgress.value,
                    backgroundColor: QuizColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(QuizColors.primary),
                    minHeight: 6,
                  )),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCancelButton() {
    return Obx(() {
      if (controller.opponentSearchProgress.value >= 1.0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: OutlinedButton(
          onPressed: () {
            controller.cancelMatchmaking();
            Get.back();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: QuizColors.body,
            side: const BorderSide(color: QuizColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      );
    });
  }

  Widget _buildTipCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: QuizCustomCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x40FFC107),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lightbulb_outline, color: QuizColors.gold, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Answer correctly to earn XP and climb the leaderboard!',
                style: TextStyle(fontSize: 13, color: QuizColors.body, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
