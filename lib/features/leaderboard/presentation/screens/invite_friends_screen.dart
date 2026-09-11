import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/surfaces/app_surface.dart';

class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  static const _referralCode = 'GENLINK2024';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeaderIllustration(scheme),
            const SizedBox(height: 24),
            Text(
              'leaderboard.inviteTitle'.tr,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'leaderboard.inviteSubtitle'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _buildReferralCode(scheme),
            const SizedBox(height: 28),
            _buildSocialShare(scheme),
            const SizedBox(height: 32),
            _buildInviteButton(),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'quiz.maybeLater'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIllustration(ColorScheme scheme) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
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
          Icon(Icons.celebration, color: scheme.primary, size: 40),
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

  Widget _buildReferralCode(ColorScheme scheme) {
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xs),
      radius: AppRadius.squircle,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _referralCode,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
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
                backgroundColor: scheme.primary,
                colorText: scheme.onPrimary,
                duration: const Duration(seconds: 2),
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            icon: Icon(Icons.copy, color: scheme.primary, size: 22),
            tooltip: 'leaderboard.copyReferralCode'.tr,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSocialShare(ColorScheme scheme) {
    final platforms = [
      _PlatformIcon(Icons.chat, 'WhatsApp', const Color(0xFF25D366)),
      _PlatformIcon(Icons.send, 'Telegram', const Color(0xFF0088CC)),
      _PlatformIcon(Icons.facebook, 'Messenger', const Color(0xFF006AFF)),
      _PlatformIcon(Icons.more_horiz, 'leaderboard.more'.tr, scheme.primary),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'leaderboard.shareVia'.tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
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
                      color: scheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(p.icon, color: p.color, size: 28),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
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
    return AppButton(
      label: 'leaderboard.inviteViaLink'.tr,
      icon: Icons.link,
      height: 56,
      radius: AppRadius.pill,
      onPressed: () {},
    );
  }
}

class _PlatformIcon {
  final IconData icon;
  final String label;
  final Color color;

  const _PlatformIcon(this.icon, this.label, this.color);
}
