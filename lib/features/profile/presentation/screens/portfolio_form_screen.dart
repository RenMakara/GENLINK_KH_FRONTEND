import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:url_launcher/url_launcher.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../media/domain/entities/media_entity.dart';
import '../../../media/domain/media_upload_service.dart';
import '../../../media/presentation/media_picker.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';

/// Full-page dedicated screen for creating and editing portfolio projects.
class PortfolioFormScreen extends StatefulWidget {
  const PortfolioFormScreen({super.key, this.item});

  final PortfolioItemEntity? item;

  @override
  State<PortfolioFormScreen> createState() => _PortfolioFormScreenState();
}

class _PortfolioFormScreenState extends State<PortfolioFormScreen> {
  late final ProfileController _controller;
  PortfolioItemEntity? _item;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _linkController;
  late final TextEditingController _imageUrlController;

  String? _titleError;
  String? _linkError;
  String? _errorMessage;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  double? _uploadProgress;
  bool _showUrlInput = false;

  bool get isEditing => _item != null;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProfileController>();

    final routeArg = Get.arguments;
    _item = widget.item ??
        (routeArg is PortfolioItemEntity ? routeArg : null);

    _titleController = TextEditingController(text: _item?.title ?? '');
    _descriptionController =
        TextEditingController(text: _item?.description ?? '');
    _linkController = TextEditingController(text: _item?.link ?? '');
    _imageUrlController = TextEditingController(text: _item?.imageUrl ?? '');

    if (_item?.imageUrl != null && _item!.imageUrl!.isNotEmpty) {
      _showUrlInput = true;
    }

    _titleController.addListener(() {
      if (_titleError != null && _titleController.text.trim().isNotEmpty) {
        setState(() => _titleError = null);
      }
    });

    _imageUrlController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker =
        Get.isRegistered<MediaPicker>() ? Get.find<MediaPicker>() : null;
    if (picker == null) {
      setState(() => _showUrlInput = true);
      return;
    }

    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final uploadService = Get.isRegistered<MediaUploadService>()
        ? Get.find<MediaUploadService>()
        : null;

    if (uploadService == null) {
      setState(() => _showUrlInput = true);
      return;
    }

    setState(() {
      _isUploadingImage = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final media = await uploadService.upload(
        bytes: picked.bytes,
        contentType: picked.contentType,
        purpose: MediaPurpose.portfolio,
        width: picked.width,
        height: picked.height,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );
      if (mounted) {
        setState(() {
          _imageUrlController.text = media.url;
          _showUrlInput = false;
        });
      }
    } catch (e) {
      debugPrint('[PORTFOLIO-FORM] Image upload failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to upload image. You can paste an image URL instead.';
          _showUrlInput = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _uploadProgress = null;
        });
      }
    }
  }

  String _sanitizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  Future<void> _testLink() async {
    final raw = _linkController.text.trim();
    if (raw.isEmpty) return;
    final url = _sanitizeUrl(raw);
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppSnackbar.error('Could not open link. Please verify the URL format.');
    }
  }

  Future<void> _onSave() async {
    if (_isSaving || _isUploadingImage) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = 'portfolio.titleRequired'.tr;
      });
      return;
    }

    final rawLink = _linkController.text.trim();
    final sanitizedLink = rawLink.isNotEmpty ? _sanitizeUrl(rawLink) : null;
    if (sanitizedLink != null) {
      final uri = Uri.tryParse(sanitizedLink);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        setState(() {
          _linkError = 'Please enter a valid web URL';
        });
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _linkError = null;
    });

    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    try {
      final success = isEditing
          ? await _controller.updatePortfolioItem(
              portfolioId: _item!.portfolioId,
              title: title,
              description: description.isNotEmpty ? description : null,
              link: sanitizedLink,
              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            )
          : await _controller.addPortfolioItem(
              title: title,
              description: description.isNotEmpty ? description : null,
              link: sanitizedLink,
              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            );

      if (!mounted) return;

      if (success) {
        AppSnackbar.show('portfolio.saved'.tr);
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage =
              _controller.errorMessage.value ?? 'common.error'.tr;
        });
      }
    } catch (e) {
      debugPrint('[PORTFOLIO-FORM] Error saving portfolio: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currentImageUrl = _imageUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Center(
          child: AppBackButton(),
        ),
        leadingWidth: 74,
        title: Text(
          isEditing ? 'portfolio.edit'.tr : 'portfolio.add'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: _isSaving || _isUploadingImage ? null : _onSave,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Text(
                      'common.save'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: scheme.error.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 20, color: scheme.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Cover Image Section
              _buildCoverImageSection(theme, scheme, currentImageUrl),
              const SizedBox(height: AppSpacing.xl),

              // Title Field
              _buildTitleField(theme, scheme),
              const SizedBox(height: AppSpacing.lg),

              // Link Field
              _buildLinkField(theme, scheme),
              const SizedBox(height: AppSpacing.lg),

              // Description Field
              _buildDescriptionField(theme, scheme),
              const SizedBox(height: AppSpacing.xl),

              // Bottom Primary Button
              AppButton(
                label: isEditing
                    ? 'portfolio.updateProject'.tr
                    : 'portfolio.createProject'.tr,
                loading: _isSaving,
                onPressed: _isSaving || _isUploadingImage ? null : _onSave,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection(
    ThemeData theme,
    ColorScheme scheme,
    String imageUrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'portfolio.coverPhoto'.tr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (imageUrl.isNotEmpty && !_isUploadingImage)
              TextButton.icon(
                onPressed: () {
                  setState(() => _showUrlInput = !_showUrlInput);
                },
                icon: Icon(
                  _showUrlInput ? Icons.visibility_off_outlined : Icons.link,
                  size: 16,
                ),
                label: Text(_showUrlInput ? 'Hide URL' : 'Edit URL'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (imageUrl.isNotEmpty && !_isUploadingImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              size: 36,
                              color: scheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Failed to load image preview',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: Colors.white),
                          tooltip: 'Change image',
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: _pickAndUploadImage,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.white),
                          tooltip: 'Remove image',
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: () {
                            setState(() {
                              _imageUrlController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_isUploadingImage) ...[
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _uploadProgress,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Uploading image... ${((_uploadProgress ?? 0) * 100).toInt()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          InkWell(
            onTap: _pickAndUploadImage,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 26,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'portfolio.uploadPhoto'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'portfolio.tapToUpload'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (_showUrlInput || imageUrl.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              labelText: 'portfolio.imageUrl'.tr,
              hintText: 'https://images.unsplash.com/...',
              prefixIcon: const Icon(Icons.image_outlined, size: 20),
              suffixIcon: imageUrl.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _imageUrlController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleField(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: 'profile.portfolioTitle'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${_titleController.text.length}/160',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _titleController,
          maxLength: 160,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              null,
          decoration: InputDecoration(
            hintText: 'portfolio.titlePlaceholder'.tr,
            errorText: _titleError,
            prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.primary,
                width: 1.4,
              ),
            ),
          ),
          onChanged: (_) {
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildLinkField(ThemeData theme, ColorScheme scheme) {
    final hasLink = _linkController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'profile.portfolioLink'.tr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (hasLink)
              GestureDetector(
                onTap: _testLink,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Test Link',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.open_in_new, size: 14, color: scheme.primary),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _linkController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'portfolio.linkPlaceholder'.tr,
            errorText: _linkError,
            prefixIcon: const Icon(Icons.link_rounded, size: 20),
            suffixIcon: hasLink
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _linkController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.primary,
                width: 1.4,
              ),
            ),
          ),
          onChanged: (_) {
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'profile.portfolioDescription'.tr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            Text(
              '${_descriptionController.text.length}/2000',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _descriptionController,
          minLines: 4,
          maxLines: 8,
          maxLength: 2000,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              null,
          decoration: InputDecoration(
            hintText: 'portfolio.descPlaceholder'.tr,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.primary,
                width: 1.4,
              ),
            ),
          ),
          onChanged: (_) {
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}
