import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/notifications/app_notification_banner.dart';
import '../../../media/presentation/media_picker.dart';
import '../controllers/short_content_controller.dart';

class ShortContentCreateScreen extends StatefulWidget {
  const ShortContentCreateScreen({
    super.key,
    this.controller,
    this.mediaPicker,
  });

  final ShortContentController? controller;
  final MediaPicker? mediaPicker;

  @override
  State<ShortContentCreateScreen> createState() =>
      _ShortContentCreateScreenState();
}

class _ShortContentCreateScreenState extends State<ShortContentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  late final ShortContentController controller;
  late final MediaPicker mediaPicker;

  PickedMedia? _video;
  PickedMedia? _thumbnail;
  String? _videoError;
  VideoPlayerController? _videoPreviewController;
  bool _videoPreviewLoading = false;
  bool _videoPreviewError = false;
  int _videoPreviewGeneration = 0;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? Get.find<ShortContentController>();
    mediaPicker = widget.mediaPicker ?? Get.find<MediaPicker>();
    _titleController.addListener(_clearCreateError);
    _descriptionController.addListener(_clearCreateError);
    _categoryController.addListener(_clearCreateError);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _videoPreviewGeneration++;
    unawaited(_videoPreviewController?.dispose());
    super.dispose();
  }

  void _clearCreateError() {
    if (controller.createErrorMessage.value != null) {
      controller.clearCreateError();
    }
  }

  Future<void> _pickVideo() async {
    if (controller.isCreating.value) return;
    try {
      final selected = await mediaPicker.pickVideo();
      if (!mounted || selected == null) return;
      setState(() {
        _video = selected;
        _videoError = null;
      });
      unawaited(_loadVideoPreview(selected));
    } catch (error) {
      if (mounted) _showError(_messageForMediaError(error));
    }
  }

  Future<void> _pickThumbnail() async {
    if (controller.isCreating.value) return;
    try {
      final selected = await mediaPicker.pickImage();
      if (!mounted || selected == null) return;
      setState(() => _thumbnail = selected);
    } catch (error) {
      if (mounted) _showError(_messageForMediaError(error));
    }
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final video = _video;
    if (video == null) {
      setState(
        () => _videoError = _text(
          'shortContent.videoRequired',
          'Select a video before publishing.',
        ),
      );
      return;
    }

    final created = await controller.createShortContent(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _categoryController.text,
      video: video,
      thumbnail: _thumbnail,
    );
    if (!mounted || created == null) return;

    AppNotificationBanner.showSuccess(
      context: context,
      title: _text('shortContent.create', 'Create Short Content'),
      message: _text(
        'shortContent.publishSuccess',
        'Your short content was published.',
      ),
      icon: Icons.check_circle_outline,
    );
    Get.back(result: created);
  }

  void _showError(String message) {
    AppNotificationBanner.showDanger(
      context: context,
      title: _text('common.error', 'Error'),
      message: message,
    );
  }

  String _messageForMediaError(Object error) {
    if (error is AppError && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return _text(
      'shortContent.mediaSelectFailed',
      'Unable to select this media.',
    );
  }

  String _text(String key, String fallback) {
    final translated = key.tr;
    return translated == key ? fallback : translated;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        foregroundColor: colors.primaryText,
        title: Text(_text('shortContent.create', 'Create Short Content')),
      ),
      body: Obx(() {
        final isCreating = controller.isCreating.value;
        final error = controller.createErrorMessage.value;
        return Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    _text(
                      'shortContent.createSubtitle',
                      'Share a useful video with the GenLink community.',
                    ),
                    style: TextStyle(color: colors.secondaryText),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildVideoCard(colors),
                  if (_videoError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _InlineError(message: _videoError!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _buildThumbnailCard(colors),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTextField(
                    controller: _titleController,
                    label: _text('shortContent.titleField', 'Title'),
                    hint: _text(
                      'shortContent.titleHint',
                      'Give your video a clear title',
                    ),
                    colors: colors,
                    maxLength: 180,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _text(
                          'shortContent.titleRequired',
                          'Add a title before publishing.',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _descriptionController,
                    label: _text(
                      'shortContent.descriptionField',
                      'Description',
                    ),
                    hint: _text(
                      'shortContent.descriptionHint',
                      'Add context for viewers (optional)',
                    ),
                    colors: colors,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _categoryController,
                    label: _text('shortContent.categoryField', 'Category'),
                    hint: _text(
                      'shortContent.categoryHint',
                      'Education, focus, finance... (optional)',
                    ),
                    colors: colors,
                    maxLength: 80,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _InlineError(message: error),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: isCreating ? null : _publish,
                      icon: const Icon(Icons.publish_outlined),
                      label: Text(
                        _text('shortContent.publish', 'Publish'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isCreating)
              Positioned.fill(
                child: ColoredBox(
                  color: isDark ? Colors.black54 : Colors.black26,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(AppSpacing.lg),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Obx(() {
                          final progress = controller.uploadProgress.value;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _text(
                                  'shortContent.publishing',
                                  'Publishing...',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: 180,
                                child: LinearProgressIndicator(
                                  value: progress <= 0 ? null : progress,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text('${(progress * 100).round()}%'),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoCard(AppSemanticColors colors) {
    final video = _video;
    return _MediaCard(
      colors: colors,
      title: _text('shortContent.videoField', 'Video'),
      subtitle: _text(
        'shortContent.videoHint',
        'Choose a video up to 60 seconds.',
      ),
      child: video == null
          ? OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library_outlined),
              label: Text(_text('shortContent.selectVideo', 'Select video')),
            )
          : _buildVideoPreview(colors, video),
    );
  }

  Widget _buildVideoPreview(AppSemanticColors colors, PickedMedia video) {
    final preview = _videoPreviewController;
    final canRender =
        preview != null && preview.value.isInitialized && !_videoPreviewError;
    final aspectRatio = canRender && preview.value.aspectRatio > 0
        ? preview.value.aspectRatio
        : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (canRender)
                    VideoPlayer(preview)
                  else
                    ColoredBox(
                      color: Colors.black.withValues(alpha: 0.88),
                      child: Center(
                        child: _videoPreviewError
                            ? const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.white70,
                                size: 34,
                              )
                            : _videoPreviewLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white70,
                              )
                            : const Icon(
                                Icons.video_file_outlined,
                                color: Colors.white70,
                                size: 34,
                              ),
                      ),
                    ),
                  if (canRender)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleVideoPreview,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: preview.value.isPlaying ? 0 : 1,
                            duration: const Duration(milliseconds: 180),
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                color: Color(0x99000000),
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Icon(
                                  preview.value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    size: 17,
                    color: colors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _fileName(video.path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.secondaryText),
                    ),
                  ),
                  IconButton(
                    tooltip: _text('common.remove', 'Remove'),
                    onPressed: () => unawaited(_clearVideo()),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (_videoPreviewError)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Text(
                  _text(
                    'shortContent.videoPreviewError',
                    'Video selected, but preview is unavailable on this device.',
                  ),
                  style: TextStyle(color: colors.secondaryText, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailCard(AppSemanticColors colors) {
    final thumbnail = _thumbnail;
    return _MediaCard(
      colors: colors,
      title: _text('shortContent.thumbnailField', 'Thumbnail'),
      subtitle: _text(
        'shortContent.thumbnailOptional',
        'Optional. The video can be published without one.',
      ),
      child: thumbnail == null
          ? OutlinedButton.icon(
              onPressed: _pickThumbnail,
              icon: const Icon(Icons.image_outlined),
              label: Text(_text('shortContent.addThumbnail', 'Add thumbnail')),
            )
          : _buildThumbnailPreview(colors, thumbnail),
    );
  }

  Widget _buildThumbnailPreview(
    AppSemanticColors colors,
    PickedMedia thumbnail,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(
              thumbnail.bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: colors.surface,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                _fileName(thumbnail.path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
            IconButton(
              tooltip: _text('common.remove', 'Remove'),
              onPressed: () => setState(() => _thumbnail = null),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadVideoPreview(PickedMedia video) async {
    final token = ++_videoPreviewGeneration;
    final previous = _videoPreviewController;
    _videoPreviewController = null;
    if (mounted) {
      setState(() {
        _videoPreviewLoading = true;
        _videoPreviewError = false;
      });
    }
    await previous?.dispose();

    final path = video.path?.trim();
    if (path == null || path.isEmpty) {
      if (mounted && token == _videoPreviewGeneration) {
        setState(() {
          _videoPreviewLoading = false;
          _videoPreviewError = true;
        });
      }
      return;
    }

    VideoPlayerController? next;
    try {
      next = VideoPlayerController.file(File(path));
      await next.initialize();
      await next.setLooping(true);
      if (!mounted || token != _videoPreviewGeneration) {
        await next.dispose();
        return;
      }
      setState(() {
        _videoPreviewController = next;
        _videoPreviewLoading = false;
        _videoPreviewError = false;
      });
    } catch (error) {
      debugPrint('[ShortContentCreateScreen] Video preview failed: $error');
      await next?.dispose();
      if (mounted && token == _videoPreviewGeneration) {
        setState(() {
          _videoPreviewLoading = false;
          _videoPreviewError = true;
        });
      }
    }
  }

  Future<void> _toggleVideoPreview() async {
    final preview = _videoPreviewController;
    if (preview == null || !preview.value.isInitialized) return;
    try {
      if (preview.value.isPlaying) {
        await preview.pause();
      } else {
        await preview.play();
      }
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint(
        '[ShortContentCreateScreen] Video preview playback failed: $error',
      );
      if (mounted) setState(() => _videoPreviewError = true);
    }
  }

  Future<void> _clearVideo() async {
    _videoPreviewGeneration++;
    final previous = _videoPreviewController;
    if (mounted) {
      setState(() {
        _video = null;
        _videoPreviewController = null;
        _videoPreviewLoading = false;
        _videoPreviewError = false;
      });
    }
    await previous?.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required AppSemanticColors colors,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      textInputAction: maxLines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
      ),
    );
  }

  static String _fileName(String? path) {
    if (path == null || path.trim().isEmpty) return 'Selected media';
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final AppSemanticColors colors;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: TextStyle(color: colors.secondaryText)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.danger)),
    );
  }
}
