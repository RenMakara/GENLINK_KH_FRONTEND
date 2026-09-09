import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_icon_container.dart';

class FindOpponentScreen extends GetView<QuizController> {
  const FindOpponentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizThemeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: QuizThemeColors.heading),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'quiz.findOpponent'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: QuizThemeColors.heading),
        ),
      ),
      body: Column(
        children: [
          const Spacer(flex: 2),
          _buildRadarAnimation(),
          const Spacer(),
          _buildStatusText(),
          const SizedBox(height: AppSpacing.xl),
          _buildCancelButton(),
          const SizedBox(height: AppSpacing.md),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: QuizThemeColors.gradient,
                boxShadow: [
                  BoxShadow(
                    color: QuizThemeColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                color: QuizThemeColors.onPrimary,
                size: 40,
              ),
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
        border: Border.all(color: QuizThemeColors.correct, width: 3),
      ),
      child: const Center(
        child: Icon(Icons.check, color: QuizThemeColors.correct, size: 28),
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
            color: QuizThemeColors.primary.withValues(alpha: 0.15 * opacity),
            width: 1.5,
          ),
          color: QuizThemeColors.primary.withValues(alpha: 0.04 * opacity),
        ),
      );
    });
  }

  Widget _buildStatusText() {
    return Obx(() {
      if (controller.opponentSearchProgress.value >= 1.0) {
        return Column(
          children: [
            Text(
              'quiz.opponentFound'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: QuizThemeColors.correct,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'quiz.preparingMatch'.tr,
              style: TextStyle(
                fontSize: 15,
                color: QuizThemeColors.body.withValues(alpha: 0.8),
              ),
            ),
          ],
        );
      }
      return Column(
        children: [
          Text(
            'quiz.findingOpponent'.tr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: QuizThemeColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'quiz.searchingPlayers'.tr,
            style: TextStyle(
              fontSize: 14,
              color: QuizThemeColors.body.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Obx(
                () => LinearProgressIndicator(
                  value: controller.opponentSearchProgress.value,
                  backgroundColor: QuizThemeColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    QuizThemeColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCancelButton() {
    return Obx(() {
      if (controller.opponentSearchProgress.value >= 1.0) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: OutlinedButton(
          onPressed: () {
            controller.cancelMatchmaking();
            Get.back();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: QuizThemeColors.body,
            side: BorderSide(color: QuizThemeColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: Text(
            'common.cancel'.tr,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }

  Widget _buildTipCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: QuizCustomCard(
        padding: const EdgeInsets.all(AppSpacing.sm + 6),
        child: Row(
          children: [
            QuizIconContainer(
              icon: Icons.lightbulb_outline,
              accentColor: QuizThemeColors.gold,
              size: 40,
              iconSize: 22,
              borderRadius: AppRadius.md,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'quiz.matchTip'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: QuizThemeColors.body,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
