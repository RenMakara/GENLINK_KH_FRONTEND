import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/glass/glass_effect.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/surfaces/app_glass_surface.dart';
import '../controllers/language_select_controller.dart';

class LanguageSelectScreen extends GetView<LanguageSelectController> {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Obx(
              () => _PreferenceHeader(
                step: controller.currentStep.value,
                onBack: () {
                  controller.previous();
                },
              ),
            ),
            Expanded(
              child: PageView(
                controller: controller.preferencePageController,
                onPageChanged: controller.onStepChanged,
                physics: const ClampingScrollPhysics(),
                children: const [_LanguageStep(), _AppearanceStep()],
              ),
            ),
            Obx(
              () => SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: _PreferenceAction(
                    label: 'common.continue'.tr,
                    loading: controller.isSaving.value,
                    onPressed: () {
                      controller.next();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceHeader extends StatelessWidget {
  const _PreferenceHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppBackButton(onPressed: onBack),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _StepProgress(step: step),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(
              LanguageSelectController.totalSteps,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == LanguageSelectController.totalSteps - 1
                        ? 0
                        : AppSpacing.xs,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 5,
                    decoration: BoxDecoration(
                      color: index <= step
                          ? AppColors.brandPrimary
                          : semantic.borderSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          'onboarding.stepOf'.trParams({
            'step': '${step + 1}',
            'total': '${LanguageSelectController.totalSteps}',
          }),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: semantic.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return _StepScroll(
      children: [
        _PreferenceTitle(text: 'onboarding.chooseLanguage'.tr),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'onboarding.chooseLanguageHint'.tr,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: semantic.secondaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        GetX<LanguageSelectController>(
          builder: (controller) => Column(
            children: [
              _LanguageOption(
                flag: '🇰🇭',
                title: 'ភាសាខ្មែរ',
                subtitle: 'Khmer',
                selected:
                    controller.selected.value == LocalizationService.khmer,
                onTap: () {
                  controller.select(LocalizationService.khmer);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _LanguageOption(
                flag: '🇺🇸',
                title: 'English',
                subtitle: 'English',
                selected:
                    controller.selected.value == LocalizationService.english,
                onTap: () {
                  controller.select(LocalizationService.english);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _InfoCard(
          icon: Icons.translate_rounded,
          message: 'onboarding.bothLanguages'.tr,
        ),
      ],
    );
  }
}

class _AppearanceStep extends StatelessWidget {
  const _AppearanceStep();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return _StepScroll(
      children: [
        _PreferenceTitle(text: 'onboarding.chooseAppearance'.tr),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'onboarding.chooseAppearanceHint'.tr,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: semantic.secondaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        GetX<LanguageSelectController>(
          builder: (controller) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ThemeOption(
                  mode: ThemeMode.light,
                  label: 'settings.themeLight'.tr,
                  selected: controller.selectedTheme.value == ThemeMode.light,
                  onTap: () {
                    controller.selectTheme(ThemeMode.light);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ThemeOption(
                  mode: ThemeMode.dark,
                  label: 'settings.themeDark'.tr,
                  selected: controller.selectedTheme.value == ThemeMode.dark,
                  onTap: () {
                    controller.selectTheme(ThemeMode.dark);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ThemeOption(
                  mode: ThemeMode.system,
                  label: 'settings.themeSystem'.tr,
                  selected: controller.selectedTheme.value == ThemeMode.system,
                  onTap: () {
                    controller.selectTheme(ThemeMode.system);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _InfoCard(
          icon: Icons.tune_rounded,
          message: 'settings.appearanceHint'.tr,
        ),
      ],
    );
  }
}

class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _PreferenceTitle extends StatelessWidget {
  const _PreferenceTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);
    final splitAt = text.lastIndexOf(' ');
    final baseStyle = (theme.textTheme.displaySmall ?? const TextStyle())
        .copyWith(color: semantic.primaryText, fontWeight: FontWeight.w700);

    if (splitAt <= 0) {
      return Text(text, style: baseStyle);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${text.substring(0, splitAt)}\n', style: baseStyle),
          TextSpan(
            text: text.substring(splitAt + 1),
            style: baseStyle.copyWith(color: AppColors.brandPrimary),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      selected: selected,
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.brandPrimary.withValues(
                      alpha: isDark ? 0.16 : 0.08,
                    )
                  : semantic.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: selected
                    ? AppColors.brandPrimary
                    : semantic.borderSubtle,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: semantic.cardShadow,
            ),
            child: Row(
              children: [
                _FlagBadge(flag: flag),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: semantic.primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: semantic.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                _SelectionIndicator(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.flag});

  final String flag;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      height: 52,
      width: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: semantic.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: Text(flag, style: const TextStyle(fontSize: 27)),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.brandPrimary : semantic.surface,
        border: Border.all(
          color: selected ? AppColors.brandPrimary : semantic.borderStrong,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 17,
              color: AppColors.lightTextInverse,
            )
          : null,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: semantic.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: selected
                    ? AppColors.brandPrimary
                    : semantic.borderSubtle,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: semantic.cardShadow,
            ),
            child: Column(
              children: [
                _ThemePreview(mode: mode),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: semantic.primaryText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SelectionIndicator(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode == ThemeMode.system) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 112,
          child: Row(
            children: [
              Expanded(
                child: _ThemePreviewPane(
                  semantic: AppSemanticColors.light,
                  icon: Icons.light_mode_rounded,
                  isDark: false,
                ),
              ),
              Container(width: 1, color: context.semanticColors.borderSubtle),
              Expanded(
                child: _ThemePreviewPane(
                  semantic: AppSemanticColors.dark,
                  icon: Icons.dark_mode_rounded,
                  isDark: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: _ThemePreviewPane(
        semantic: AppSemanticColors.forBrightness(
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        ),
        icon: mode == ThemeMode.dark
            ? Icons.dark_mode_rounded
            : Icons.light_mode_rounded,
        isDark: mode == ThemeMode.dark,
      ),
    );
  }
}

class _ThemePreviewPane extends StatelessWidget {
  const _ThemePreviewPane({
    required this.semantic,
    required this.icon,
    required this.isDark,
  });

  final AppSemanticColors semantic;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: semantic.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon, size: 20, color: AppColors.brandPrimary)],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: semantic.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: semantic.borderSubtle),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    height: isDark ? 30 : 38,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(
                        alpha: isDark ? 0.35 : 0.16,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Container(
                    height: isDark ? 40 : 26,
                    decoration: BoxDecoration(
                      color: semantic.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: semantic.borderSubtle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final glass = GlassEffect(
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.72 : 0.84,
      blur: 10,
    );

    return AppGlassSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadius.xl,
      blurSigma: glass.blur,
      backgroundOpacity: glass.opacity,
      border: Border.all(
        color: semantic.borderSubtle,
        width: glass.borderWidth,
      ),
      boxShadow: const [],
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.brandPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: semantic.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceAction extends StatelessWidget {
  const _PreferenceAction({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: semantic.primary,
          disabledBackgroundColor: semantic.primary.withValues(alpha: 0.55),
          foregroundColor: semantic.textInverse,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: semantic.textInverse,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 22),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: semantic.textInverse,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
      ),
    );
  }
}
