import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/profile_entity.dart';
import '../../../../design_system/widgets/images/app_cached_image.dart';
import '../controllers/profile_controller.dart';

class PortfolioScreen extends GetView<ProfileController> {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Center(
          child: AppBackButton(),
        ),
        leadingWidth: 74,
        title: Text(
          'profile.portfolio'.tr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'portfolio.add'.tr,
            onPressed: () =>
                Get.toNamed<void>(AppRoutes.profilePortfolioForm),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.portfolio.isEmpty) {
          return const AppLoader();
        }
        final items = controller.portfolio;
        if (items.isEmpty) {
          return AppEmptyState(
            message: 'profile.emptyPortfolio'.tr,
            icon: Icons.work_outline,
            action: AppButton.secondary(
              label: 'portfolio.add'.tr,
              expanded: false,
              onPressed: () =>
                  Get.toNamed<void>(AppRoutes.profilePortfolioForm),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => _PortfolioCard(
            item: items[index],
            onEdit: () => Get.toNamed<void>(
              AppRoutes.profilePortfolioForm,
              arguments: items[index],
            ),
            onDelete: () => _delete(items[index]),
          ),
        );
      }),
    );
  }

  Future<void> _delete(PortfolioItemEntity item) async {
    final confirmed = await AppDialog.confirm(
      title: 'portfolio.deleteConfirm'.trParams({'title': item.title}),
      confirmLabel: 'common.delete'.tr,
      destructive: true,
    );
    if (confirmed) {
      final success = await controller.deletePortfolioItem(item.portfolioId);
      if (success) {
        AppSnackbar.show('portfolio.deleted'.tr);
      }
    }
  }

  static Future<bool?> showEditDialog(
    BuildContext context,
    ProfileController controller, [
    PortfolioItemEntity? item,
  ]) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _PortfolioEditDialog(
        controller: controller,
        item: item,
      ),
    );
  }
}

class _PortfolioEditDialog extends StatefulWidget {
  const _PortfolioEditDialog({
    required this.controller,
    this.item,
  });

  final ProfileController controller;
  final PortfolioItemEntity? item;

  @override
  State<_PortfolioEditDialog> createState() => _PortfolioEditDialogState();
}

class _PortfolioEditDialogState extends State<_PortfolioEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _linkController;
  late final TextEditingController _imageUrlController;

  String? _titleError;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.item?.description ?? '');
    _linkController = TextEditingController(text: widget.item?.link ?? '');
    _imageUrlController =
        TextEditingController(text: widget.item?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = 'portfolio.titleRequired'.tr;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final success = widget.item == null
        ? await widget.controller.addPortfolioItem(
            title: title,
            description: _descriptionController.text.trim(),
            link: _linkController.text.trim(),
            imageUrl: _imageUrlController.text.trim(),
          )
        : await widget.controller.updatePortfolioItem(
            portfolioId: widget.item!.portfolioId,
            title: title,
            description: _descriptionController.text.trim(),
            link: _linkController.text.trim(),
            imageUrl: _imageUrlController.text.trim(),
          );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      AppSnackbar.show('portfolio.saved'.tr);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage =
            widget.controller.errorMessage.value ?? 'common.error'.tr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      title:
          Text(widget.item == null ? 'portfolio.add'.tr : 'portfolio.edit'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: scheme.error.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: scheme.error),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'profile.portfolioTitle'.tr,
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'profile.portfolioDescription'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _linkController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'profile.portfolioLink'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(hintText: 'portfolio.imageUrl'.tr),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _onSave,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('common.save'.tr),
        ),
      ],
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final PortfolioItemEntity item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            AspectRatio(
              aspectRatio: 2.2,
              child: AppCachedImage(
                imageUrl: item.imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 720,
                errorWidget: ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image_outlined, color: muted),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: theme.textTheme.titleMedium),
                      if ((item.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                      if ((item.link ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.link, size: 14, color: muted),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                item.link!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: muted),
                  onSelected: (action) =>
                      action == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('common.edit'.tr)),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('common.delete'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
