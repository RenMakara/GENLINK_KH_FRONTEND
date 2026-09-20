import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/challenge_models.dart';
import '../controllers/challenge_controller.dart';

class ChallengeListScreen extends GetView<ChallengeController> {
  const ChallengeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: Center(child: AppBackButton()),
        ),
        title: Text(
          'challenge.title'.tr,
          style: TextStyle(color: colors.primaryText),
        ),
      ),
      body: Obx(() {
        final items = controller.challenges;
        if (controller.isLoading.value && items.isEmpty) {
          return _centeredMessage(
            colors,
            const CircularProgressIndicator(),
            'common.loading'.tr,
          );
        }
        if (controller.errorMessage.value != null && items.isEmpty) {
          return _errorState(colors);
        }

        return RefreshIndicator(
          onRefresh: controller.refreshChallenges,
          color: colors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Text(
                'challenge.subtitle'.tr,
                style: TextStyle(color: colors.secondaryText, height: 1.4),
              ),
              if (controller.errorMessage.value != null) ...[
                const SizedBox(height: AppSpacing.md),
                _messageBanner(
                  colors,
                  controller.errorMessage.value!,
                  AppColors.warning,
                  Icons.info_outline,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (items.isEmpty)
                _emptyState(colors)
              else
                ...items.map(
                  (challenge) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ChallengeCard(
                      challenge: challenge,
                      colors: colors,
                      onTap: () => Get.toNamed(
                        AppRoutes.challengeDetail,
                        arguments: challenge.challengeId,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _errorState(AppSemanticColors colors) {
    return _centeredMessage(
      colors,
      Icon(Icons.cloud_off_outlined, size: 48, color: colors.textMuted),
      controller.errorMessage.value ?? 'challenge.loadFailed'.tr,
      action: FilledButton(
        onPressed: controller.loadChallenges,
        child: Text('common.retry'.tr),
      ),
    );
  }

  Widget _emptyState(AppSemanticColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 52, color: colors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            'challenge.emptyTitle'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'challenge.emptyMessage'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _centeredMessage(
    AppSemanticColors colors,
    Widget icon,
    String message, {
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _messageBanner(
    AppSemanticColors colors,
    String message,
    Color accent,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.primaryText)),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.colors,
    required this.onTap,
  });

  final ChallengeModel challenge;
  final AppSemanticColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _challengeAccent(challenge.challengeType);
    final progress = (challenge.progress.clamp(0, 100) / 100).toDouble();
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ChallengeIcon(type: challenge.challengeType, color: accent),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      challenge.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colors.textMuted,
                  ),
                ],
              ),
              if (challenge.description.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  challenge.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.secondaryText, height: 1.35),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _StatusChip(
                    label: _statusLabel(challenge.status),
                    color: _statusColor(challenge.status, colors),
                  ),
                  _InfoChip(
                    icon: Icons.bolt_outlined,
                    label: '+${challenge.xpReward} XP',
                    color: accent,
                  ),
                ],
              ),
              if (challenge.deadline != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 15,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${'challenge.deadline'.tr}: ${_formatDeadline(challenge.deadline!)}',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (challenge.isJoined) ...[
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  color: accent,
                  backgroundColor: colors.backgroundSecondary,
                ),
                const SizedBox(height: 5),
                Text(
                  '${challenge.progress}% ${'challenge.progress'.tr}',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeIcon extends StatelessWidget {
  const _ChallengeIcon({required this.type, required this.color});

  final ChallengeType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(_challengeIcon(type), color: color),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

String _statusLabel(ChallengeStatus status) => switch (status) {
  ChallengeStatus.notStarted => 'challenge.statusNotStarted'.tr,
  ChallengeStatus.inProgress => 'challenge.statusInProgress'.tr,
  ChallengeStatus.completed => 'challenge.statusRewardAvailable'.tr,
  ChallengeStatus.claimed => 'challenge.statusClaimed'.tr,
  ChallengeStatus.unknown => 'challenge.statusUnknown'.tr,
};

Color _statusColor(ChallengeStatus status, AppSemanticColors colors) =>
    switch (status) {
      ChallengeStatus.notStarted => colors.textMuted,
      ChallengeStatus.inProgress => colors.primary,
      ChallengeStatus.completed => AppColors.warning,
      ChallengeStatus.claimed => AppColors.success,
      ChallengeStatus.unknown => colors.textMuted,
    };

IconData _challengeIcon(ChallengeType type) => switch (type) {
  ChallengeType.habit => Icons.repeat_rounded,
  ChallengeType.task => Icons.check_circle_outline_rounded,
  ChallengeType.finance => Icons.account_balance_wallet_outlined,
  ChallengeType.quiz => Icons.quiz_outlined,
  ChallengeType.event => Icons.event_outlined,
  ChallengeType.community => Icons.people_outline_rounded,
  ChallengeType.focus => Icons.timer_outlined,
  ChallengeType.unknown => Icons.flag_outlined,
};

Color _challengeAccent(ChallengeType type) => switch (type) {
  ChallengeType.habit => const Color(0xFFF97316),
  ChallengeType.task => const Color(0xFF3B82F6),
  ChallengeType.finance => const Color(0xFF4BAE73),
  ChallengeType.quiz => const Color(0xFFF2B84B),
  ChallengeType.event => const Color(0xFFEC4899),
  ChallengeType.community => const Color(0xFF5DADEC),
  ChallengeType.focus => const Color(0xFF06B6D4),
  ChallengeType.unknown => const Color(0xFF8B7CF6),
};

String _formatDeadline(DateTime deadline) {
  final local = deadline.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
