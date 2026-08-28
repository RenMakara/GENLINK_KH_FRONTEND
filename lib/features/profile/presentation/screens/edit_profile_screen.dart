import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../../../core/utils/validators.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/borders/dashed_border.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/inputs/app_input.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  /// Backend WorkStatus enum — shown as "Role" in the design.
  static const _workStatuses = <String>[
    'STUDENT',
    'FRESH_GRADUATE',
    'YOUNG_PROFESSIONAL',
    'CREATOR',
    'FREELANCER',
    'ENTREPRENEUR',
    'OTHER',
  ];

  /// Platforms surfaced under "Social Presence". The backend supports more;
  /// these two match the design and cover the common cases.
  static const _linkedIn = 'LINKEDIN';
  static const _website = 'WEBSITE';
  static const _github = 'GITHUB';
  static const _telegram = 'TELEGRAM';

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _university = TextEditingController();
  final _location = TextEditingController();
  final _avatarUrl = TextEditingController();
  final _linkedInUrl = TextEditingController();
  final _websiteUrl = TextEditingController();
  final _githubUrl = TextEditingController();
  final _telegramUrl = TextEditingController();

  String? _workStatus;

  ProfileController get _controller => Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    final profile = _controller.profile.value;
    if (profile != null) {
      _fullName.text = profile.fullName;
      _username.text = profile.username;
      _bio.text = profile.bio ?? '';
      _university.text = profile.universityName ?? '';
      _location.text = profile.location ?? '';
      _avatarUrl.text = profile.avatarUrl ?? '';
      _workStatus = profile.workStatus;
    }
    _linkedInUrl.text = _existingLink(_linkedIn);
    _websiteUrl.text = _existingLink(_website);
    _githubUrl.text = _existingLink(_github);
    _telegramUrl.text = _existingLink(_telegram);
  }

  String _existingLink(String platform) {
    final match = _controller.socialLinks.firstWhereOrNull(
      (link) => link.platform == platform,
    );
    return match?.url ?? '';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _bio.dispose();
    _university.dispose();
    _location.dispose();
    _avatarUrl.dispose();
    _linkedInUrl.dispose();
    _websiteUrl.dispose();
    _githubUrl.dispose();
    _telegramUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final previousAvatar = _controller.profile.value?.avatarUrl ?? '';

    final saved = await _controller.updateProfile(
      fullName: _fullName.text.trim(),
      username: _username.text.trim(),
      bio: _bio.text.trim(),
      universityName: _university.text.trim(),
      workStatus: _workStatus,
      location: _location.text.trim(),
    );
    if (!saved) return;

    // Avatar has its own endpoint; only call it when it actually changed.
    final avatar = _avatarUrl.text.trim();
    if (avatar != previousAvatar && avatar.isNotEmpty) {
      await _controller.updateAvatar(avatar);
    }

    await _saveSocialLink(_linkedIn, _linkedInUrl.text.trim());
    await _saveSocialLink(_website, _websiteUrl.text.trim());
    await _saveSocialLink(_github, _githubUrl.text.trim());
    await _saveSocialLink(_telegram, _telegramUrl.text.trim());

    Get.back<void>();
  }

  /// Upsert when there is a URL, delete when the field was cleared.
  Future<void> _saveSocialLink(String platform, String url) async {
    final existing = _existingLink(platform);
    if (url == existing) return;
    if (url.isEmpty) {
      await _controller.deleteSocialLink(platform);
    } else {
      await _controller.upsertSocialLink(platform: platform, url: url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Center(
          child: AppBackButton(),
        ),
        leadingWidth: 74,
        title: Text(
          'profile.edit'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: AppAvatar(
                imageUrl: _controller.profile.value?.avatarUrl,
                name: _controller.profile.value?.fullName,
                size: 34,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.profile.value == null) return const AppLoader();

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AvatarPicker(
                        controller: _avatarUrl,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppInput(
                        label: 'profile.displayName'.tr,
                        controller: _fullName,
                        radius: AppRadius.lg,
                        textCapitalization: TextCapitalization.words,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppInput(
                        label: 'auth.username'.tr,
                        controller: _username,
                        radius: AppRadius.lg,
                        validator: Validators.username,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppInput(
                        label: 'profile.bio'.tr,
                        controller: _bio,
                        radius: AppRadius.lg,
                        maxLines: 4,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _RoleDropdown(
                              value: _workStatus,
                              options: _workStatuses,
                              onChanged: (value) =>
                                  setState(() => _workStatus = value),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppInput(
                              label: 'profile.location'.tr,
                              controller: _location,
                              radius: AppRadius.lg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppInput(
                        label: 'profile.universityWorkplace'.tr,
                        controller: _university,
                        radius: AppRadius.lg,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Text(
                          'profile.socialPresence'.tr,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppInput(
                        label: 'profile.linkedIn'.tr,
                        controller: _linkedInUrl,
                        radius: AppRadius.lg,
                        keyboardType: TextInputType.url,
                        hint: 'https://linkedin.com/in/…',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppInput(
                        label: 'profile.website'.tr,
                        controller: _websiteUrl,
                        radius: AppRadius.lg,
                        keyboardType: TextInputType.url,
                        hint: 'https://…',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_githubUrl.text.isNotEmpty) ...[
                        AppInput(
                          label: 'GitHub',
                          controller: _githubUrl,
                          radius: AppRadius.lg,
                          keyboardType: TextInputType.url,
                          hint: 'https://github.com/…',
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (_telegramUrl.text.isNotEmpty)
                        AppInput(
                          label: 'Telegram',
                          controller: _telegramUrl,
                          radius: AppRadius.lg,
                          keyboardType: TextInputType.url,
                          hint: 'https://t.me/…',
                        ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton(
                    label: 'profile.saveChanges'.tr,
                    loading: _controller.isSaving.value,
                    onPressed: _submit,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Dashed drop-zone for the avatar.
///
/// Tapping picks a photo from the gallery or camera, uploads it, and sets it
/// as the avatar in one step — the picture is chosen from the device, never
/// pasted as a URL. The upload progress replaces the icon while it runs.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.controller, required this.onChanged});

  /// Mirrors the avatar url so the parent form can tell whether it changed.
  final TextEditingController controller;
  final VoidCallback onChanged;

  ProfileController get _profile => Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(() {
      final url = _profile.profile.value?.avatarUrl ?? controller.text.trim();
      final progress = _profile.avatarUploadProgress.value;
      final uploading = progress != null;

      return InkWell(
        onTap: uploading ? null : () => _pickSource(context),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: DashedBorder(
          radius: AppRadius.xl,
          color: scheme.outline.withValues(alpha: 0.5),
          child: Container(
            height: 148,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (uploading)
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: CircularProgressIndicator(
                      // Determinate: a large photo on a slow connection
                      // deserves a real bar, not an endless spinner.
                      value: progress > 0 ? progress : null,
                      strokeWidth: 3,
                    ),
                  )
                else if (url.isEmpty)
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md + 4),
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 20,
                      color: scheme.onPrimary,
                    ),
                  )
                else
                  AppAvatar(imageUrl: url, size: 64),
                const SizedBox(height: AppSpacing.sm + 2),
                Text(
                  uploading
                      ? '${(progress * 100).round()}%'
                      : 'profile.updatePicture'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Gallery or camera, then upload. Cancelling at either step is silent —
  /// backing out of a picker is not an error.
  Future<void> _pickSource(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('profile.chooseFromGallery'.tr),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('profile.takePhoto'.tr),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final uploaded = await _profile.pickAndUploadAvatar(source: source);
    if (uploaded) {
      // Keep the form's copy in step so _submit does not re-send the avatar.
      controller.text = _profile.profile.value?.avatarUrl ?? '';
      onChanged();
    }
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('profile.role'.tr, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs + 2),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : null,
          isExpanded: true,
          hint: Text('common.optional'.tr),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(_label(option), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static String _label(String enumValue) => enumValue
      .split('_')
      .map(
        (word) =>
            word.isEmpty ? word : word[0] + word.substring(1).toLowerCase(),
      )
      .join(' ');
}
