import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _university = TextEditingController();
  final _location = TextEditingController();
  final _avatarUrl = TextEditingController();
  final _linkedInUrl = TextEditingController();
  final _websiteUrl = TextEditingController();

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
  }

  String _existingLink(String platform) {
    final match = _controller.socialLinks
        .firstWhereOrNull((link) => link.platform == platform);
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
    if (avatar != previousAvatar) await _controller.updateAvatar(avatar);

    await _saveSocialLink(_linkedIn, _linkedInUrl.text.trim());
    await _saveSocialLink(_website, _websiteUrl.text.trim());

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
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: AppBackButton(),
        ),
        leadingWidth: 58 + AppSpacing.md * 2,
        title: Text('profile.edit'.tr),
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

        return SingleChildScrollView(
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
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.required,
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  label: 'auth.username'.tr,
                  controller: _username,
                  prefixIcon: Icons.alternate_email,
                  validator: Validators.username,
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  label: 'profile.bio'.tr,
                  controller: _bio,
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  label: 'profile.universityWorkplace'.tr,
                  controller: _university,
                  prefixIcon: Icons.apartment_outlined,
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
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.link,
                  hint: 'https://linkedin.com/in/…',
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  label: 'profile.website'.tr,
                  controller: _websiteUrl,
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.public,
                  hint: 'https://…',
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'profile.saveChanges'.tr,
                  icon: Icons.check_circle_outline,
                  loading: _controller.isSaving.value,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Dashed drop-zone for the avatar.
///
/// There is no upload endpoint yet — the backend takes an `avatarUrl` —
/// so tapping opens a dialog to paste a URL rather than pretending to
/// open a file picker.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final url = controller.text.trim();

    return InkWell(
      onTap: () => _promptForUrl(context),
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
            if (url.isEmpty)
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
              'profile.updatePicture'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _promptForUrl(BuildContext context) async {
    final draft = TextEditingController(text: controller.text);
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
            onPressed: () =>
                Navigator.of(dialogContext).pop(draft.text.trim()),
            child: Text('common.done'.tr),
          ),
        ],
      ),
    );
    draft.dispose();
    if (result != null) {
      controller.text = result;
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
      .map((word) =>
          word.isEmpty ? word : word[0] + word.substring(1).toLowerCase())
      .join(' ');
}
