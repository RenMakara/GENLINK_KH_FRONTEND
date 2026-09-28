import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/borders/dashed_border.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../../auth/presentation/widgets/animated_auth_background.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_setup_controller.dart';

class ProfileSetupScreen extends GetView<ProfileSetupController> {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackgroundShell(
        child: SafeArea(
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
      ),
    );
  }
}

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
                  loading: controller.isSaving.value ||
                      controller.isUploadingAvatar.value,
                  onPressed: controller.isUploadingAvatar.value
                      ? null
                      : onContinue,
                ),
              ),
              Obx(
                () => AppButton.text(
                  label: 'onboarding.skipForNow'.tr,
                  muted: true,
                  onPressed: controller.isUploadingAvatar.value
                      ? null
                      : controller.finish,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


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

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = Get.find<ProfileSetupController>();

    return Obx(() {
      final url = controller.avatarUrl.value;
      final bytes = controller.avatarBytes.value;
      final uploading = controller.isUploadingAvatar.value;
      final progress = controller.avatarUploadProgress.value;
      final hasAvatar =
          bytes != null || (url.isNotEmpty && url != 'local_preview');

      Widget avatarChild;
      if (uploading) {
        avatarChild = Stack(
          alignment: Alignment.center,
          children: [
            if (bytes != null)
              Opacity(
                opacity: 0.35,
                child: ClipOval(
                  child: Image.memory(
                    bytes,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (url.isNotEmpty && url != 'local_preview')
              Opacity(
                opacity: 0.35,
                child: ClipOval(child: AppAvatar(imageUrl: url, size: 72)),
              ),
            SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                value: progress != null && progress > 0 ? progress : null,
                strokeWidth: 2.5,
                color: scheme.primary,
              ),
            ),
          ],
        );
      } else if (bytes != null) {
        avatarChild = ClipOval(
          child: Image.memory(
            bytes,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        );
      } else if (url.isNotEmpty && url != 'local_preview') {
        avatarChild = ClipOval(child: AppAvatar(imageUrl: url, size: 72));
      } else {
        avatarChild = Icon(
          Icons.photo_camera_outlined,
          size: 22,
          color: scheme.onSurface.withValues(alpha: 0.5),
        );
      }

      return Row(
        children: [
          GestureDetector(
            onTap: uploading
                ? null
                : () => _showPhotoOptions(context, controller),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                DashedBorder(
                  radius: 36,
                  color: scheme.outline.withValues(alpha: 0.5),
                  child: SizedBox(
                    height: 72,
                    width: 72,
                    child: avatarChild,
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
                    child: Icon(
                      hasAvatar ? Icons.edit : Icons.add,
                      size: 14,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppButton.text(
                  label: uploading
                      ? (progress != null && progress > 0
                          ? '${'profileSetup.uploadingPhoto'.tr} ${(progress * 100).round()}%'
                          : 'profileSetup.uploadingPhoto'.tr)
                      : (hasAvatar
                          ? 'profileSetup.changePhoto'.tr
                          : 'profileSetup.uploadPhoto'.tr),
                  onPressed: uploading
                      ? null
                      : () => _showPhotoOptions(context, controller),
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

  Future<void> _showPhotoOptions(
    BuildContext context,
    ProfileSetupController controller,
  ) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasAvatar = controller.avatarBytes.value != null ||
        (controller.avatarUrl.value.isNotEmpty &&
            controller.avatarUrl.value != 'local_preview');

    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  hasAvatar
                      ? 'profileSetup.changePhoto'.tr
                      : 'profileSetup.uploadPhoto'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'profile.chooseFromGallery'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'profile.takePhoto'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
                if (hasAvatar)
                  ListTile(
                    leading: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: scheme.error,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'profileSetup.removePhoto'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop(null);
                      controller.removeAvatar();
                    },
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );

    if (source != null) {
      await controller.pickAndUploadAvatar(source: source);
    }
  }
}


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
        subtitle: 'profileSetup.step3Subtitle'.trParams({
          'count': '${ProfileSetupController.minInterests}',
        }),
        continueLabel: 'profileSetup.finish'.tr,
        onContinue: controller.hasEnoughInterests
            ? controller.submitStep3
            : null,
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
                      selected: controller.selectedInterestIds.contains(
                        interest.interestId,
                      ),
                      onTap: () =>
                          controller.toggleInterest(interest.interestId),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'profileSetup.selectedCount'.trParams({
              'count': '${controller.selectedInterestIds.length}',
            }),
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
