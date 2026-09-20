import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../domain/models/challenge_models.dart';
import '../controllers/challenge_controller.dart';

class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late final ChallengeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ChallengeController>();
    controller.loadDetail(widget.challengeId);
  }

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
          'challenge.detail'.tr,
          style: TextStyle(color: colors.primaryText),
        ),
      ),
      body: Obx(() => _buildBody(context, colors)),
    );
  }

  Widget _buildBody(BuildContext context, AppSemanticColors colors) {
    final challenge = controller.selectedChallenge.value;
    if (challenge == null && controller.isDetailLoading.value) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }
    if (challenge == null) {
      return _messageState(
        colors,
        Icons.flag_outlined,
        controller.detailErrorMessage.value ?? 'challenge.loadFailed'.tr,
        FilledButton(
          onPressed: () => controller.loadDetail(widget.challengeId),
          child: Text('common.retry'.tr),
        ),
      );
    }

    final progress = (challenge.progress.clamp(0, 100) / 100).toDouble();
    final accent = _challengeAccent(challenge.challengeType);
    return RefreshIndicator(
      onRefresh: () => controller.loadDetail(widget.challengeId),
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: colors.borderSubtle),
              boxShadow: colors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChallengeIcon(
                      type: challenge.challengeType,
                      color: accent,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: colors.primaryText,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                if (challenge.description.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    challenge.description,
                    style: TextStyle(color: colors.secondaryText, height: 1.5),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'challenge.progress'.tr,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  color: accent,
                  backgroundColor: colors.backgroundSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  '${challenge.progress}%',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                if (challenge.deadline != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 17,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${'challenge.deadline'.tr}: ${_formatDeadline(challenge.deadline!)}',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (controller.detailErrorMessage.value != null) ...[
            const SizedBox(height: AppSpacing.md),
            _messageBanner(
              colors,
              controller.detailErrorMessage.value!,
              AppColors.warning,
              Icons.info_outline,
            ),
          ],
          if (controller.actionErrorMessage.value != null) ...[
            const SizedBox(height: AppSpacing.md),
            _messageBanner(
              colors,
              controller.actionErrorMessage.value!,
              AppColors.danger,
              Icons.error_outline,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _buildAction(context, colors, challenge),
          if (challenge.status == ChallengeStatus.claimed) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'challenge.rewardEarned'.trParams({
                        'xp': '${challenge.xpReward}',
                      }),
                      style: TextStyle(color: colors.primaryText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    AppSemanticColors colors,
    ChallengeModel challenge,
  ) {
    final id = challenge.challengeId;
    switch (challenge.status) {
      case ChallengeStatus.notStarted:
        return AppButton(
          label: 'challenge.join'.tr,
          icon: Icons.play_arrow_rounded,
          loading: controller.isJoining(id),
          onPressed: controller.isJoining(id)
              ? null
              : () => controller.joinChallenge(id),
        );
      case ChallengeStatus.inProgress:
        return AppButton(
          label: 'challenge.complete'.tr,
          icon: Icons.check_rounded,
          loading: controller.isCompleting(id),
          onPressed: controller.isCompleting(id)
              ? null
              : () => controller.completeChallenge(id),
        );
      case ChallengeStatus.completed:
        return AppButton(
          label: 'challenge.claimReward'.tr,
          icon: Icons.redeem_outlined,
          loading: controller.isClaiming(id),
          onPressed: controller.isClaiming(id)
              ? null
              : () => controller.claimReward(id),
        );
      case ChallengeStatus.claimed:
        return AppButton.secondary(
          label: 'challenge.claimed'.tr,
          icon: Icons.check_circle_outline,
          onPressed: null,
        );
      case ChallengeStatus.unknown:
        return Text(
          'challenge.statusUnknown'.tr,
          style: TextStyle(color: colors.textMuted),
        );
    }
  }

  Widget _messageState(
    AppSemanticColors colors,
    IconData icon,
    String message,
    Widget action,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText),
            ),
            const SizedBox(height: AppSpacing.md),
            action,
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

class _ChallengeIcon extends StatelessWidget {
  const _ChallengeIcon({required this.type, required this.color});

  final ChallengeType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(_challengeIcon(type), color: color, size: 25),
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
