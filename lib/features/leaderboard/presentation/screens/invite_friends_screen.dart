import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../quiz/presentation/quiz_colors.dart';

class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  static const _referralCode = 'GENLINK2024';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: Center(child: AppBackButton()),
        ),
        leadingWidth: 74,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeaderIllustration(),
            const SizedBox(height: 24),
            Text(
              'leaderboard.inviteTitle'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: QuizColors.heading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'leaderboard.inviteSubtitle'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: QuizColors.body,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _buildReferralCode(),
            const SizedBox(height: 28),
            _buildSocialShare(),
            const SizedBox(height: 32),
            _buildInviteButton(),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'quiz.maybeLater'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: QuizColors.body,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIllustration() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: QuizColors.primaryLight,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: QuizColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _personIcon(const Color(0xFF3B82F6)),
              const SizedBox(width: 2),
              _personIcon(const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 8),
          const Icon(Icons.celebration, color: QuizColors.primary, size: 40),
        ],
      ),
    );
  }

  Widget _personIcon(Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, color: color, size: 28),
    );
  }

  Widget _buildReferralCode() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: QuizColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QuizColors.border),
        boxShadow: QuizColors.cardShadow,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _referralCode,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: QuizColors.heading,
                letterSpacing: 2,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: _referralCode));
              Get.snackbar(
                'leaderboard.copied'.tr,
                'leaderboard.referralCopied'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: QuizColors.primary,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            icon: const Icon(Icons.copy, color: QuizColors.primary, size: 22),
            tooltip: 'leaderboard.copyReferralCode'.tr,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSocialShare() {
    final platforms = [
      _PlatformIcon(Icons.chat, 'WhatsApp', const Color(0xFF25D366)),
      _PlatformIcon(Icons.send, 'Telegram', const Color(0xFF0088CC)),
      _PlatformIcon(Icons.facebook, 'Messenger', const Color(0xFF006AFF)),
      _PlatformIcon(
        Icons.more_horiz,
        'leaderboard.more'.tr,
        QuizColors.primary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'leaderboard.shareVia'.tr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: QuizColors.heading,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: platforms.map((p) {
            return Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: QuizColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: QuizColors.border),
                      boxShadow: QuizColors.cardShadow,
                    ),
                    child: Icon(p.icon, color: p.color, size: 28),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: QuizColors.body,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInviteButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: QuizColors.gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'leaderboard.inviteViaLink'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatformIcon {
  final IconData icon;
  final String label;
  final Color color;

  const _PlatformIcon(this.icon, this.label, this.color);
}
