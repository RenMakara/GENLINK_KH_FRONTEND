import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/branding/app_logo.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 74,
        title: Text(
          'about.title'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          const _AboutHero(),
          const SizedBox(height: AppSpacing.md),
          _AboutSectionCard(
            icon: Icons.groups_rounded,
            accent: AppColors.success,
            title: 'about.whatTitle'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'about.whatBody'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.76),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _AudienceCallout(text: 'about.audience'.tr),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AboutSectionCard(
            icon: Icons.lightbulb_outline_rounded,
            accent: AppColors.growthAccent,
            title: 'about.whyTitle'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'about.whyBody'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.76),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 560 ? 3 : 2;
                    final gap = AppSpacing.sm + 4;
                    final tileWidth =
                        (constraints.maxWidth - (gap * (columns - 1))) /
                        columns;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        _AboutFeatureTile(
                          width: tileWidth,
                          icon: Icons.people_alt_outlined,
                          accent: AppColors.brandPrimary,
                          title: 'about.connect'.tr,
                          subtitle: 'about.connectHint'.tr,
                        ),
                        _AboutFeatureTile(
                          width: tileWidth,
                          icon: Icons.event_outlined,
                          accent: AppColors.productivityAccent,
                          title: 'about.discover'.tr,
                          subtitle: 'about.discoverHint'.tr,
                        ),
                        _AboutFeatureTile(
                          width: tileWidth,
                          icon: Icons.rocket_launch_outlined,
                          accent: AppColors.success,
                          title: 'about.grow'.tr,
                          subtitle: 'about.growHint'.tr,
                        ),
                        _AboutFeatureTile(
                          width: tileWidth,
                          icon: Icons.account_balance_wallet_outlined,
                          accent: AppColors.financeAccent,
                          title: 'about.manage'.tr,
                          subtitle: 'about.manageHint'.tr,
                        ),
                        _AboutFeatureTile(
                          width: tileWidth,
                          icon: Icons.sports_esports_outlined,
                          accent: AppColors.warning,
                          title: 'about.enjoy'.tr,
                          subtitle: 'about.enjoyHint'.tr,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _BuiltForCambodiaCard(),
          const SizedBox(height: AppSpacing.md),
          _AboutSectionCard(
            icon: Icons.track_changes_rounded,
            accent: AppColors.success,
            title: 'about.visionTitle'.tr,
            child: Text(
              'about.visionBody'.tr,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.78),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AboutValuesCard(),
          const SizedBox(height: AppSpacing.md),
          _LicenseCard(onTap: () => _showLicenses(context)),
          const SizedBox(height: AppSpacing.lg),
          _AboutFooter(),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'GenLink KH',
      applicationVersion: '1.0.0',
      applicationLegalese: 'settings.aboutLegalese'.tr,
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        constraints: const BoxConstraints(minHeight: 176),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF183C43),
                    scheme.surface,
                    const Color(0xFF1C3049),
                  ]
                : [
                    const Color(0xFFE5F6F1),
                    scheme.surface,
                    const Color(0xFFEAF1FF),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -26,
              bottom: -28,
              child: Icon(
                Icons.location_city_rounded,
                size: 164,
                color: AppColors.success.withValues(alpha: isDark ? 0.14 : 0.1),
              ),
            ),
            Positioned(
              right: 42,
              top: 18,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 26,
                color: AppColors.growthAccent.withValues(
                  alpha: isDark ? 0.8 : 0.65,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.success, Color(0xFF3FA9D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(child: AppLogoMark(size: 52)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              const TextSpan(text: 'GenLink'),
                              TextSpan(
                                text: ' KH',
                                style: TextStyle(color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'about.tagline'.tr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.68),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'about.khmerTagline'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutSectionCard extends StatelessWidget {
  const _AboutSectionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.025),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AboutIcon(icon: icon, accent: accent),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _AudienceCallout extends StatelessWidget {
  const _AudienceCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: isDark ? 0.17 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.diversity_3_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: isDark
                    ? const Color(0xFFBDEFE0)
                    : const Color(0xFF197A68),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutFeatureTile extends StatelessWidget {
  const _AboutFeatureTile({
    required this.width,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final double width;
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 122),
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.055),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AboutIcon(icon: icon, accent: accent, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.25,
                color: scheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuiltForCambodiaCard extends StatelessWidget {
  const _BuiltForCambodiaCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF193747), scheme.surface]
                : [const Color(0xFFE8F2FF), scheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -4,
              bottom: -22,
              child: Icon(
                Icons.account_balance_rounded,
                size: 112,
                color: AppColors.brandPrimary.withValues(
                  alpha: isDark ? 0.16 : 0.1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _AboutIcon(
                        icon: Icons.flag_rounded,
                        accent: AppColors.danger,
                      ),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Expanded(
                        child: Text(
                          'about.builtTitle'.tr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'about.builtBody'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.76),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutValuesCard extends StatelessWidget {
  const _AboutValuesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'about.valuesTitle'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 5 : 2;
              final gap = AppSpacing.sm;
              final itemWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: AppSpacing.md,
                children: [
                  _ValueItem(
                    width: itemWidth,
                    icon: Icons.link_rounded,
                    accent: AppColors.brandPrimary,
                    title: 'about.connection'.tr,
                    subtitle: 'about.connectionHint'.tr,
                  ),
                  _ValueItem(
                    width: itemWidth,
                    icon: Icons.eco_rounded,
                    accent: AppColors.success,
                    title: 'about.growth'.tr,
                    subtitle: 'about.growthHint'.tr,
                  ),
                  _ValueItem(
                    width: itemWidth,
                    icon: Icons.star_rounded,
                    accent: AppColors.growthAccent,
                    title: 'about.opportunity'.tr,
                    subtitle: 'about.opportunityHint'.tr,
                  ),
                  _ValueItem(
                    width: itemWidth,
                    icon: Icons.savings_outlined,
                    accent: AppColors.financeAccent,
                    title: 'about.financialAwareness'.tr,
                    subtitle: 'about.financialAwarenessHint'.tr,
                  ),
                  _ValueItem(
                    width: itemWidth,
                    icon: Icons.favorite_rounded,
                    accent: AppColors.productivityAccent,
                    title: 'about.localIdentity'.tr,
                    subtitle: 'about.localIdentityHint'.tr,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ValueItem extends StatelessWidget {
  const _ValueItem({
    required this.width,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final double width;
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          _AboutIcon(icon: icon, accent: accent, size: 40),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.2,
              color: scheme.onSurface.withValues(alpha: isDark ? 0.62 : 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              _AboutIcon(
                icon: Icons.article_outlined,
                accent: AppColors.brandPrimary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'about.licenses'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'about.licensesHint'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.58),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          'GenLink KH',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'about.tagline'.tr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'about.version'.tr,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.48),
          ),
        ),
      ],
    );
  }
}

class _AboutIcon extends StatelessWidget {
  const _AboutIcon({required this.icon, required this.accent, this.size = 42});

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: accent, size: size * 0.54),
    );
  }
}
