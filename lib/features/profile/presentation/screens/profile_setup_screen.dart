import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/borders/dashed_border.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_setup_controller.dart';

/// Three-step profile setup, shown once after registration.
///
/// Every step is optional: the account is already active, so "Skip for now"
/// goes straight to the app. Steps save as the user leaves them, so partial
/// progress survives a drop-out.
class ProfileSetupScreen extends GetView<ProfileSetupController> {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final step = controller.currentStep.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: _StepHeader(step: step),
              ),
              Expanded(
                child: switch (step) {
                  1 => const _StepOne(),
                  2 => const _StepTwo(),
                  _ => const _StepThree(),
                },
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Progress dashes on the left, "Step n of 3" on the right.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: List.generate(ProfileSetupController.totalSteps, (index) {
            final active = index + 1 == step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: AppSpacing.xs + 2),
              height: 5,
              width: active ? 26 : 7,
              decoration: BoxDecoration(
                color: active ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            );
          }),
        ),
        Text(
          'profileSetup.stepOf'.trParams({
            'step': '$step',
            'total': '${ProfileSetupController.totalSteps}',
          }),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Shared body frame: scrollable content, then Continue + Skip.
class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onContinue,
    required this.continueLabel,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<ProfileSetupController>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...children,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              Obx(
                () => AppButton(
                  label: continueLabel,
                  loading: controller.isSaving.value,
                  onPressed: onContinue,
                ),
              ),
              AppButton.text(
                label: 'onboarding.skipForNow'.tr,
                muted: true,
                onPressed: controller.finish,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 1 ──────────────────────────────────────────────────────────────

class _StepOne extends StatelessWidget {
  const _StepOne();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileSetupController>();

    return _StepBody(
      title: 'profileSetup.step1Title'.tr,
      subtitle: 'profileSetup.step1Subtitle'.tr,
      continueLabel: 'common.continue'.tr,
      onContinue: controller.submitStep1,
      children: [
        const _PhotoPicker(),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'profile.displayName'.tr,
          hint: 'auth.fullNameHint'.tr,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => controller.displayName.value = value,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'profileSetup.iAmA'.tr,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Obx(
          () => _RoleGrid(
            selected: controller.role.value,
            onSelected: (value) => controller.role.value = value,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'profileSetup.universityOptional'.tr,
          hint: 'profileSetup.universityHint'.tr,
          onChanged: (value) => controller.universityName.value = value,
        ),
        const SizedBox(height: AppSpacing.md),
        AppInput(
          label: 'profileSetup.locationOptional'.tr,
          hint: 'profileSetup.locationHint'.tr,
          onChanged: (value) => controller.location.value = value,
        ),
      ],
    );
  }
}

/// Two-column grid of role pills.
class _RoleGrid extends StatelessWidget {
  const _RoleGrid({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: ProfileSetupController.roles
              .map(
                (value) => SizedBox(
                  width: itemWidth,
                  child: _ChoicePill(
                    label: 'role.$value'.tr,
                    selected: selected == value,
                    onTap: () => onSelected(value),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? Colors.transparent : scheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular dashed photo slot with a "+" badge.
///
/// There is no upload endpoint — the backend stores an `avatarUrl` — so
/// this asks for a URL rather than opening a file picker it cannot honour.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = Get.find<ProfileSetupController>();

    return Obx(() {
      final url = controller.avatarUrl.value;
      return Row(
        children: [
          Stack(
            children: [
              DashedBorder(
                radius: 36,
                color: scheme.outline.withValues(alpha: 0.5),
                child: SizedBox(
                  height: 72,
                  width: 72,
                  child: url.isEmpty
                      ? Icon(
                          Icons.photo_camera_outlined,
                          size: 22,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        )
                      : ClipOval(child: AppAvatar(imageUrl: url, size: 72)),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                  ),
                  child: Icon(Icons.add, size: 14, color: scheme.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppButton.text(
                  label: 'profileSetup.uploadPhoto'.tr,
                  onPressed: () => _promptForUrl(context, controller),
                ),
                Text(
                  'profileSetup.photoHint'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Future<void> _promptForUrl(
    BuildContext context,
    ProfileSetupController controller,
  ) async {
    final draft = TextEditingController(text: controller.avatarUrl.value);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('profile.avatarUrl'.tr),
        content: TextField(
          controller: draft,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(draft.text.trim()),
            child: Text('common.done'.tr),
          ),
        ],
      ),
    );
    draft.dispose();
    if (result != null) controller.avatarUrl.value = result;
  }
}

// ── Step 2 ──────────────────────────────────────────────────────────────

class _StepTwo extends StatelessWidget {
  const _StepTwo();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileSetupController>();

    return _StepBody(
      title: 'profileSetup.step2Title'.tr,
      subtitle: 'profileSetup.step2Subtitle'.tr,
      continueLabel: 'common.continue'.tr,
      onContinue: controller.submitStep2,
      children: [
        AppInput(
          label: 'profileSetup.shortBio'.tr,
          hint: 'profileSetup.bioHint'.tr,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) => controller.bio.value = value,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'profileSetup.linksOptional'.tr,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppInput(
          label: '',
          hint: 'https://yourlink.com',
          keyboardType: TextInputType.url,
          onChanged: (value) => controller.links[0] = value,
        ),
        const SizedBox(height: AppSpacing.md),
        AppInput(
          label: '',
          hint: 'https://yourlink.com',
          keyboardType: TextInputType.url,
          onChanged: (value) => controller.links[1] = value,
        ),
      ],
    );
  }
}

// ── Step 3 ──────────────────────────────────────────────────────────────

class _StepThree extends StatelessWidget {
  const _StepThree();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<ProfileSetupController>();
    controller.loadCatalog();

    return Obx(
      () => _StepBody(
        title: 'profileSetup.step3Title'.tr,
        subtitle: 'profileSetup.step3Subtitle'
            .trParams({'count': '${ProfileSetupController.minInterests}'}),
        continueLabel: 'profileSetup.finish'.tr,
        onContinue:
            controller.hasEnoughInterests ? controller.submitStep3 : null,
        children: [
          if (controller.isLoadingCatalog.value)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: AppLoader(),
            )
          else if (controller.catalog.isEmpty)
            AppEmptyState(message: 'profile.emptyInterests'.tr)
          else
            Wrap(
              spacing: AppSpacing.sm + 2,
              runSpacing: AppSpacing.sm + 2,
              children: controller.catalog
                  .map(
                    (interest) => _InterestChip(
                      interest: interest,
                      selected: controller.selectedInterestIds
                          .contains(interest.interestId),
                      onTap: () =>
                          controller.toggleInterest(interest.interestId),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'profileSetup.selectedCount'
                .trParams({'count': '${controller.selectedInterestIds.length}'}),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.interest,
    required this.selected,
    required this.onTap,
  });

  final InterestEntity interest;
  final bool selected;
  final VoidCallback onTap;

  /// The dot colour keys off the interest's category, so related
  /// interests read as a group without needing a per-interest colour.
  static const _categoryColors = <String, Color>{
    'CAREER': AppColors.brandPrimary,
    'FINANCE': AppColors.financeAccent,
    'EDUCATION': AppColors.communityAccent,
    'LIFESTYLE': AppColors.productivityAccent,
    'ENTERTAINMENT': AppColors.growthAccent,
    'COMMUNITY': AppColors.accentPremium,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dot = _categoryColors[interest.category] ?? scheme.outline;

    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? Colors.transparent : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                // Already localized by the backend.
                interest.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
